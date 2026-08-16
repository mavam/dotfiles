import type {
  ExtensionAPI,
  ExtensionCommandContext,
} from "@earendil-works/pi-coding-agent";
import { getMarkdownTheme } from "@earendil-works/pi-coding-agent";
import { Box, Markdown, Spacer, Text } from "@earendil-works/pi-tui";

const POLL_INTERVAL_MS = 30_000;
const GITHUB_TIMEOUT_MS = 10_000;
const FEEDBACK_CHANNEL = "pr-watch:feedback";
const FEEDBACK_PROTOCOL = 1;
const MESSAGE_TYPE = "pr-review-feedback";
const WATCH_WIDGET = "pr-watch:status";
const CODEX_REVIEW_AUTHOR = "chatgpt-codex-connector";

let markdownFromHtml: ((html: string) => string) | undefined;

async function loadHtmlConverter(): Promise<void> {
  try {
    const [{ default: TurndownService }, { gfm }] = await Promise.all([
      import("turndown"),
      import("turndown-plugin-gfm"),
    ]);
    const turndown = new TurndownService({
      bulletListMarker: "-",
      codeBlockStyle: "fenced",
    });
    turndown.use(gfm);
    turndown.addRule("github-priority-badge", {
      filter: (node) => {
        const image = node.nodeName === "A" ? node.firstChild : undefined;
        return (
          image?.nodeName === "IMG" &&
          /^P\d+ Badge$/i.test(image.getAttribute?.("alt") ?? "")
        );
      },
      replacement: (_content, node) =>
        node.firstChild?.getAttribute?.("alt") ?? "",
    });
    markdownFromHtml = (html) => turndown.turndown(html);
  } catch {
    // GitHub's source Markdown remains usable without optional npm packages.
  }
}

const FEEDBACK_QUERY = [
  "query($owner: String!, $name: String!, $number: Int!) {",
  "  viewer { login }",
  "  repository(owner: $owner, name: $name) {",
  "    pullRequest(number: $number) {",
  "      state",
  "      url",
  "      comments(last: 100) {",
  "        nodes { id body bodyHTML createdAt updatedAt url author { login } }",
  "      }",
  "      reviews(last: 100) {",
  "        nodes {",
  "          id body bodyHTML submittedAt updatedAt url state author { login }",
  "          commit { oid }",
  "        }",
  "      }",
  "      reviewThreads(last: 100) {",
  "        nodes {",
  "          id isResolved path line originalLine",
  "          comments(last: 100) {",
  "            nodes {",
  "              id body bodyHTML createdAt updatedAt url path line originalLine diffHunk",
  "              author { login }",
  "              pullRequestReview { commit { oid } }",
  "            }",
  "          }",
  "        }",
  "      }",
  "    }",
  "  }",
  "}",
].join(" ");

type FeedbackKind = "conversation" | "review" | "inline";

interface PullRequestTarget {
  host: string;
  owner: string;
  name: string;
  number: number;
  url: string;
}

interface ReviewFeedback {
  id: string;
  kind: FeedbackKind;
  author: string;
  body: string;
  url: string;
  createdAt: string;
  priority?: string;
  title?: string;
  reviewedCommit?: string;
  path?: string;
  line?: number;
  diffLine?: number;
  diffHunk?: string;
}

interface ReviewContent {
  body: string;
  priority?: string;
  title?: string;
}

interface FeedbackSnapshot {
  state: string;
  viewerLogin: string;
  feedback: ReviewFeedback[];
  openFeedback: ReviewFeedback[];
}

interface FeedbackEvent {
  protocol: typeof FEEDBACK_PROTOCOL;
  source: "pr-watch";
  target: PullRequestTarget;
  feedback: ReviewFeedback[];
}

interface ActiveWatcher {
  generation: number;
  target: PullRequestTarget;
  seen: Set<string>;
  timer?: ReturnType<typeof setTimeout>;
}

interface GraphQlAuthor {
  login?: unknown;
}

interface GraphQlCommit {
  oid?: unknown;
}

interface GraphQlComment {
  id?: unknown;
  body?: unknown;
  bodyHTML?: unknown;
  createdAt?: unknown;
  submittedAt?: unknown;
  updatedAt?: unknown;
  url?: unknown;
  path?: unknown;
  line?: unknown;
  originalLine?: unknown;
  diffHunk?: unknown;
  author?: GraphQlAuthor | null;
  commit?: GraphQlCommit | null;
  pullRequestReview?: { commit?: GraphQlCommit | null } | null;
}

interface GraphQlThread {
  isResolved?: unknown;
  path?: unknown;
  line?: unknown;
  originalLine?: unknown;
  comments?: { nodes?: Array<GraphQlComment | null> | null } | null;
}

interface GraphQlResponse {
  data?: {
    viewer?: { login?: unknown } | null;
    repository?: {
      pullRequest?: {
        state?: unknown;
        url?: unknown;
        comments?: { nodes?: Array<GraphQlComment | null> | null } | null;
        reviews?: { nodes?: Array<GraphQlComment | null> | null } | null;
        reviewThreads?: { nodes?: Array<GraphQlThread | null> | null } | null;
      } | null;
    } | null;
  };
}

function cleanText(value: unknown): string {
  if (typeof value !== "string") return "";
  return value
    .replace(/\r\n?/g, "\n")
    .replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/g, "")
    .trim();
}

function numberFrom(value: unknown): number | undefined {
  return typeof value === "number" && Number.isFinite(value)
    ? Math.floor(value)
    : undefined;
}

function loginFrom(author: GraphQlAuthor | null | undefined): string {
  return cleanText(author?.login) || "ghost";
}

function timestampFrom(comment: GraphQlComment): string {
  return (
    cleanText(comment.createdAt) ||
    cleanText(comment.submittedAt) ||
    cleanText(comment.updatedAt)
  );
}

function normalizeReviewMarkdown(markdown: string): ReviewContent {
  const withoutFooter = markdown
    .replace(
      /(?:^|\n{2,})Useful\?\s+React with\s+👍\s*\/\s*👎\.?\s*$/u,
      "",
    )
    .trim();
  const heading = /^\*\*(P\d+) Badge\s+([^\n]+)\*\*(?:\n{2,}|$)/u.exec(
    withoutFooter,
  );
  if (!heading) return { body: withoutFooter };

  return {
    body: withoutFooter.slice(heading[0].length).trim(),
    priority: heading[1]?.toUpperCase(),
    title: heading[2]?.trim(),
  };
}

function contentFrom(comment: GraphQlComment): ReviewContent {
  const html = cleanText(comment.bodyHTML);
  if (html && markdownFromHtml) {
    try {
      return normalizeReviewMarkdown(cleanText(markdownFromHtml(html)));
    } catch {
      // Fall back to GitHub's source Markdown if conversion unexpectedly fails.
    }
  }
  return normalizeReviewMarkdown(cleanText(comment.body));
}

function stripCodexReviewBoilerplate(markdown: string): string {
  if (!/^###\s+💡\s+Codex Review(?:\n|$)/u.test(markdown)) return markdown;

  const withoutIntro = markdown
    .replace(/^###\s+💡\s+Codex Review\s*/u, "")
    .replace(
      /^Here are some automated review suggestions for this pull request\.\s*/u,
      "",
    )
    .replace(/^\*\*Reviewed commit:\*\*\s+`?[0-9a-f]{7,40}`?\s*/iu, "");
  const aboutIndex = withoutIntro.search(
    /(?:^|\n+)ℹ️\s+About Codex in GitHub[ \t]*(?:\n|$)/iu,
  );
  return (aboutIndex < 0 ? withoutIntro : withoutIntro.slice(0, aboutIndex)).trim();
}

function reviewedCommitFrom(comment: GraphQlComment): string {
  return cleanText(comment.pullRequestReview?.commit?.oid) || cleanText(comment.commit?.oid);
}

function parseComment(
  comment: GraphQlComment,
  kind: FeedbackKind,
  fallbackLocation?: { path?: string; line?: number; originalLine?: number },
): ReviewFeedback | undefined {
  const id = cleanText(comment.id);
  const author = loginFrom(comment.author);
  const parsedContent = contentFrom(comment);
  const content =
    kind === "review" && author === CODEX_REVIEW_AUTHOR
      ? { ...parsedContent, body: stripCodexReviewBoilerplate(parsedContent.body) }
      : parsedContent;
  const url = cleanText(comment.url);
  if (!id || (!content.body && !content.title) || !url) return undefined;

  const path = cleanText(comment.path) || fallbackLocation?.path;
  const diffLine = numberFrom(comment.line) ?? fallbackLocation?.line;
  const line =
    diffLine ??
    numberFrom(comment.originalLine) ??
    fallbackLocation?.originalLine;
  const diffHunk = cleanText(comment.diffHunk);
  const reviewedCommit = reviewedCommitFrom(comment);

  return {
    id,
    kind,
    author,
    body: content.body,
    url,
    createdAt: timestampFrom(comment),
    ...(content.priority ? { priority: content.priority } : {}),
    ...(content.title ? { title: content.title } : {}),
    ...(reviewedCommit ? { reviewedCommit } : {}),
    ...(path ? { path } : {}),
    ...(line !== undefined ? { line } : {}),
    ...(diffLine !== undefined ? { diffLine } : {}),
    ...(diffHunk ? { diffHunk } : {}),
  };
}

function parseSnapshot(response: GraphQlResponse): FeedbackSnapshot | undefined {
  const pullRequest = response.data?.repository?.pullRequest;
  if (!pullRequest) return undefined;

  const feedback: ReviewFeedback[] = [];
  const openFeedback: ReviewFeedback[] = [];

  for (const comment of pullRequest.comments?.nodes ?? []) {
    if (!comment) continue;
    const parsed = parseComment(comment, "conversation");
    if (parsed) feedback.push(parsed);
  }

  for (const review of pullRequest.reviews?.nodes ?? []) {
    if (!review) continue;
    const parsed = parseComment(review, "review");
    if (parsed) feedback.push(parsed);
  }

  for (const thread of pullRequest.reviewThreads?.nodes ?? []) {
    if (!thread) continue;
    const fallbackLocation = {
      path: cleanText(thread.path) || undefined,
      line: numberFrom(thread.line),
      originalLine: numberFrom(thread.originalLine),
    };
    for (const comment of thread.comments?.nodes ?? []) {
      if (!comment) continue;
      const parsed = parseComment(comment, "inline", fallbackLocation);
      if (parsed) {
        feedback.push(parsed);
        if (thread.isResolved === false) openFeedback.push(parsed);
      }
    }
  }

  const compareFeedback = (left: ReviewFeedback, right: ReviewFeedback) =>
    left.createdAt.localeCompare(right.createdAt) || left.id.localeCompare(right.id);
  feedback.sort(compareFeedback);
  openFeedback.sort(compareFeedback);

  return {
    state: cleanText(pullRequest.state).toUpperCase(),
    viewerLogin: cleanText(response.data?.viewer?.login),
    feedback,
    openFeedback,
  };
}

function parsePullRequestUrl(url: string): PullRequestTarget | undefined {
  try {
    const parsed = new URL(url);
    const match = parsed.pathname.match(/^\/([^/]+)\/([^/]+)\/pull\/(\d+)\/?$/);
    if (!match) return undefined;
    const [, owner, name, numberText] = match;
    const number = Number.parseInt(numberText!, 10);
    if (!owner || !name || !Number.isFinite(number)) return undefined;
    return {
      host: parsed.hostname,
      owner,
      name,
      number,
      url,
    };
  } catch {
    return undefined;
  }
}

async function resolveCurrentPullRequest(
  pi: ExtensionAPI,
  ctx: ExtensionCommandContext,
): Promise<PullRequestTarget> {
  const result = await pi.exec(
    "gh",
    ["pr", "view", "--json", "number,url,state"],
    { cwd: ctx.cwd, timeout: GITHUB_TIMEOUT_MS },
  );
  if (result.code !== 0) {
    throw new Error(cleanText(result.stderr) || "No pull request found for the current branch");
  }

  let parsed: { url?: unknown; state?: unknown };
  try {
    parsed = JSON.parse(result.stdout) as { url?: unknown; state?: unknown };
  } catch {
    throw new Error("GitHub returned an invalid pull request response");
  }

  const state = cleanText(parsed.state).toUpperCase();
  if (state !== "OPEN") throw new Error(`The current pull request is ${state.toLowerCase()}`);

  const target = parsePullRequestUrl(cleanText(parsed.url));
  if (!target) throw new Error("GitHub returned an invalid pull request URL");
  return target;
}

async function fetchSnapshot(
  pi: ExtensionAPI,
  cwd: string,
  target: PullRequestTarget,
): Promise<FeedbackSnapshot | undefined> {
  const result = await pi.exec(
    "gh",
    [
      "api",
      "graphql",
      "--hostname",
      target.host,
      "-f",
      `query=${FEEDBACK_QUERY}`,
      "-F",
      `owner=${target.owner}`,
      "-F",
      `name=${target.name}`,
      "-F",
      `number=${target.number}`,
    ],
    { cwd, timeout: GITHUB_TIMEOUT_MS },
  );
  if (result.code !== 0 || !result.stdout.trim()) return undefined;

  try {
    return parseSnapshot(JSON.parse(result.stdout) as GraphQlResponse);
  } catch {
    return undefined;
  }
}

function formatLocation(feedback: ReviewFeedback): string {
  if (!feedback.path) return "";
  return feedback.line === undefined
    ? feedback.path
    : `${feedback.path}:${feedback.line}`;
}

function formatWatchStatus(target: PullRequestTarget): string {
  return `Watching ${target.owner}/${target.name}#${target.number}`;
}

function shortCommit(commit: string): string {
  return commit.slice(0, 10);
}

function sharedValue(values: Array<string | undefined>): string | undefined {
  if (values.length === 0 || values.some((value) => !value)) return undefined;
  const first = values[0];
  return values.every((value) => value === first) ? first : undefined;
}

function formatFindingCount(count: number): string {
  return count === 1 ? "1 finding" : `${count} findings`;
}

function formatDiffContext(feedback: ReviewFeedback): string {
  if (!feedback.diffHunk || feedback.diffLine === undefined) return "";

  const lines = feedback.diffHunk.split("\n");
  let newLine = 0;
  let hunkHeader = -1;
  let target = -1;
  for (const [index, line] of lines.entries()) {
    const header = /^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@/.exec(line);
    if (header) {
      newLine = Number.parseInt(header[1]!, 10);
      hunkHeader = index;
      continue;
    }
    if (hunkHeader < 0 || line.startsWith("\\")) continue;

    const hasNewLine = line[0] !== "-";
    if (hasNewLine && newLine === feedback.diffLine) {
      target = index;
      break;
    }
    if (hasNewLine) newLine += 1;
  }
  if (target < 0) return "";

  const start = Math.max(hunkHeader + 1, target - 4);
  const end = Math.min(lines.length, target + 5);
  return `\n\nDiff context:\n${[lines[hunkHeader], ...lines.slice(start, end)].join("\n")}`;
}

function formatModelMessage(target: PullRequestTarget, feedback: ReviewFeedback[]): string {
  const sharedAuthor = sharedValue(feedback.map((item) => item.author));
  const sharedCommit = sharedValue(feedback.map((item) => item.reviewedCommit));
  const header = [
    `${target.owner}/${target.name}#${target.number}`,
    sharedCommit ? `commit ${shortCommit(sharedCommit)}` : "",
    formatFindingCount(feedback.length),
    sharedAuthor ? `@${sharedAuthor}` : "",
  ].filter(Boolean);

  const findings = feedback.map((item) => {
    const finding = [
      item.priority ? `[${item.priority}]` : "",
      formatLocation(item),
    ].filter(Boolean).join(" ");
    const metadata = [
      sharedAuthor ? "" : `@${item.author}`,
      sharedCommit || !item.reviewedCommit
        ? ""
        : `commit ${shortCommit(item.reviewedCommit)}`,
      finding,
    ].filter(Boolean).join(" · ");
    const title = item.title ? [metadata, item.title].filter(Boolean).join(" — ") : metadata;
    const heading = [title, item.url].filter(Boolean).join(" ");
    const review = [heading, item.body].filter(Boolean).join("\n\n");
    return `${review}${formatDiffContext(item)}`;
  });

  return `${header.join(" · ")} ${target.url}\n\n${findings.join("\n\n---\n\n")}`;
}

function hyperlink(url: string, text: string): string {
  if (!/^https?:\/\/[^\s\u001b\u0007]+$/.test(url)) return text;
  return `\u001b]8;;${url}\u0007${text}\u001b]8;;\u0007`;
}

function isFeedbackEvent(value: unknown): value is FeedbackEvent {
  if (typeof value !== "object" || value === null) return false;
  const event = value as Partial<FeedbackEvent>;
  return (
    event.protocol === FEEDBACK_PROTOCOL &&
    event.source === "pr-watch" &&
    typeof event.target === "object" &&
    event.target !== null &&
    Array.isArray(event.feedback)
  );
}

export default async function (pi: ExtensionAPI) {
  await loadHtmlConverter();

  let watcher: ActiveWatcher | undefined;
  let generation = 0;
  let sessionActive = false;
  let sessionCwd = process.cwd();
  let renderWatchStatus: (active?: ActiveWatcher) => void = () => {};

  const stopWatcher = (): boolean => {
    generation += 1;
    if (!watcher) return false;
    if (watcher.timer) clearTimeout(watcher.timer);
    watcher = undefined;
    renderWatchStatus();
    return true;
  };

  const schedulePoll = (expectedGeneration: number): void => {
    if (!watcher || watcher.generation !== expectedGeneration || !sessionActive) return;
    watcher.timer = setTimeout(() => {
      void poll(expectedGeneration);
    }, POLL_INTERVAL_MS);
  };

  const poll = async (expectedGeneration: number): Promise<void> => {
    const active = watcher;
    if (!active || active.generation !== expectedGeneration || !sessionActive) return;

    const snapshot = await fetchSnapshot(pi, sessionCwd, active.target);
    const current = watcher;
    if (!current || current.generation !== expectedGeneration || !sessionActive) return;

    if (!snapshot) {
      schedulePoll(expectedGeneration);
      return;
    }
    if (snapshot.state && snapshot.state !== "OPEN") {
      stopWatcher();
      return;
    }

    const fresh = snapshot.feedback.filter((item) => !current.seen.has(item.id));
    for (const item of snapshot.feedback) current.seen.add(item.id);

    const external = fresh.filter(
      (item) => !snapshot.viewerLogin || item.author !== snapshot.viewerLogin,
    );
    if (external.length > 0) {
      const event: FeedbackEvent = {
        protocol: FEEDBACK_PROTOCOL,
        source: "pr-watch",
        target: current.target,
        feedback: external,
      };
      pi.events.emit(FEEDBACK_CHANNEL, event);
    }

    schedulePoll(expectedGeneration);
  };

  const stopFeedbackListener = pi.events.on(FEEDBACK_CHANNEL, (raw) => {
    if (!sessionActive || !isFeedbackEvent(raw) || raw.feedback.length === 0) return;
    pi.sendMessage(
      {
        customType: MESSAGE_TYPE,
        content: formatModelMessage(raw.target, raw.feedback),
        display: true,
        details: raw,
      },
      { deliverAs: "steer", triggerTurn: true },
    );
  });

  pi.registerMessageRenderer<FeedbackEvent>(
    MESSAGE_TYPE,
    (message, { outputPad }, theme) => {
      const details = message.details;
      if (!details || !isFeedbackEvent(details)) return undefined;

      const box = new Box(outputPad, 1, (text) => theme.bg("customMessageBg", text));
      const markdownTheme = {
        ...getMarkdownTheme(),
        quote: (text: string) => theme.fg("customMessageText", text),
        quoteBorder: (text: string) => theme.fg("dim", text),
      };

      const separator = theme.fg("dim", " · ");
      const sharedAuthor = sharedValue(details.feedback.map((item) => item.author));
      const sharedCommit = sharedValue(
        details.feedback.map((item) => item.reviewedCommit),
      );
      const targetLabel = `${details.target.owner}/${details.target.name}#${details.target.number}`;
      let targetHeader = theme.fg("muted", targetLabel);
      if (sharedCommit) {
        targetHeader += separator + theme.fg("dim", `commit ${shortCommit(sharedCommit)}`);
      }
      targetHeader += separator + theme.fg(
        "dim",
        formatFindingCount(details.feedback.length),
      );
      if (sharedAuthor) {
        targetHeader += separator + theme.fg("accent", `@${sharedAuthor}`);
      }
      targetHeader += ` ${hyperlink(
        details.target.url,
        theme.fg("accent", "↗"),
      )}`;
      box.addChild(new Text(targetHeader, 0, 0));

      details.feedback.forEach((item) => {
        box.addChild(new Spacer(1));

        const location = formatLocation(item);
        let itemHeader = sharedAuthor ? "" : theme.fg("accent", `@${item.author}`);
        if (!sharedCommit && item.reviewedCommit) {
          if (itemHeader) itemHeader += separator;
          itemHeader += theme.fg("dim", `commit ${shortCommit(item.reviewedCommit)}`);
        }
        if (location) {
          if (itemHeader) itemHeader += separator;
          itemHeader += theme.fg("text", location);
        }
        if (itemHeader) itemHeader += " ";
        itemHeader += hyperlink(item.url, theme.fg("accent", "↗"));
        box.addChild(new Text(itemHeader, 0, 0));

        if (item.title) {
          box.addChild(new Spacer(1));
          let title = "";
          if (item.priority) {
            const label = `[${item.priority}]`;
            if (item.priority === "P0" || item.priority === "P1") {
              title = theme.fg("error", theme.bold(label));
            } else if (item.priority === "P2") {
              title = theme.fg("warning", theme.bold(label));
            } else {
              title = theme.fg("muted", theme.bold(label));
            }
            title += " ";
          }
          title += theme.fg("customMessageText", theme.bold(item.title));
          box.addChild(new Text(title, 0, 0));
        }

        if (item.body) {
          box.addChild(new Spacer(1));
          box.addChild(
            new Markdown(item.body, 0, 0, markdownTheme, {
              color: (text) => theme.fg("customMessageText", text),
            }),
          );
        }
      });

      return box;
    },
  );

  pi.registerCommand("pr", {
    description: "Watch the current pull request for review feedback",
    getArgumentCompletions: (prefix) => {
      const options = [
        { value: "watch", label: "watch", description: "Watch for new feedback" },
        { value: "watch backfill", label: "watch backfill", description: "Load open feedback and watch" },
        { value: "unwatch", label: "unwatch", description: "Stop watching" },
      ];
      const matches = options.filter((option) => option.value.startsWith(prefix));
      return matches.length > 0 ? matches : null;
    },
    handler: async (args, ctx) => {
      const words = args.trim().split(/\s+/).filter(Boolean);
      const action = words[0];

      if (!action) {
        if (watcher) {
          renderWatchStatus(watcher);
        } else {
          ctx.ui.notify("Usage: /pr watch [backfill] | /pr unwatch", "info");
        }
        return;
      }

      if (action === "unwatch" && words.length === 1) {
        const stopped = stopWatcher();
        ctx.ui.notify(stopped ? "Stopped watching the pull request" : "No pull request is being watched", "info");
        return;
      }

      if (
        action !== "watch" ||
        words.length > 2 ||
        (words.length === 2 && words[1] !== "backfill")
      ) {
        ctx.ui.notify("Usage: /pr watch [backfill] | /pr unwatch", "warning");
        return;
      }

      const backfill = words[1] === "backfill";

      try {
        const target = await resolveCurrentPullRequest(pi, ctx);
        const snapshot = await fetchSnapshot(pi, ctx.cwd, target);
        if (!snapshot) throw new Error("Failed to read pull request feedback from GitHub");

        if (
          !watcher ||
          watcher.target.host !== target.host ||
          watcher.target.owner !== target.owner ||
          watcher.target.name !== target.name ||
          watcher.target.number !== target.number
        ) {
          stopWatcher();
          const watcherGeneration = ++generation;
          watcher = {
            generation: watcherGeneration,
            target,
            seen: new Set(snapshot.feedback.map((item) => item.id)),
          };
          sessionCwd = ctx.cwd;
          schedulePoll(watcherGeneration);
        } else {
          for (const item of snapshot.feedback) watcher.seen.add(item.id);
        }

        if (backfill && snapshot.openFeedback.length > 0) {
          pi.events.emit(FEEDBACK_CHANNEL, {
            protocol: FEEDBACK_PROTOCOL,
            source: "pr-watch",
            target,
            feedback: snapshot.openFeedback,
          } satisfies FeedbackEvent);
        }

        renderWatchStatus(watcher);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        ctx.ui.notify(`Cannot watch pull request: ${message}`, "error");
      }
    },
  });

  pi.on("session_start", (_event, ctx) => {
    sessionActive = true;
    sessionCwd = ctx.cwd;
    renderWatchStatus = (active) => {
      if (!active) {
        ctx.ui.setWidget(WATCH_WIDGET, undefined);
        return;
      }
      ctx.ui.setWidget(WATCH_WIDGET, (_tui, theme) =>
        new Text(theme.fg("dim", formatWatchStatus(active.target)), 1, 0),
      );
    };
  });

  pi.on("session_shutdown", () => {
    sessionActive = false;
    stopWatcher();
    renderWatchStatus = () => {};
    stopFeedbackListener();
  });
}
