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

const FEEDBACK_QUERY = [
  "query($owner: String!, $name: String!, $number: Int!) {",
  "  viewer { login }",
  "  repository(owner: $owner, name: $name) {",
  "    pullRequest(number: $number) {",
  "      state",
  "      url",
  "      comments(last: 100) {",
  "        nodes { id body createdAt updatedAt url author { login } }",
  "      }",
  "      reviews(last: 100) {",
  "        nodes { id body submittedAt updatedAt url state author { login } }",
  "      }",
  "      reviewThreads(last: 100) {",
  "        nodes {",
  "          id isResolved path line originalLine",
  "          comments(last: 100) {",
  "            nodes {",
  "              id body createdAt updatedAt url path line originalLine diffHunk",
  "              author { login }",
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
  path?: string;
  line?: number;
  diffHunk?: string;
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

interface GraphQlComment {
  id?: unknown;
  body?: unknown;
  createdAt?: unknown;
  submittedAt?: unknown;
  updatedAt?: unknown;
  url?: unknown;
  path?: unknown;
  line?: unknown;
  originalLine?: unknown;
  diffHunk?: unknown;
  author?: GraphQlAuthor | null;
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

function parseComment(
  comment: GraphQlComment,
  kind: FeedbackKind,
  fallbackLocation?: { path?: string; line?: number },
): ReviewFeedback | undefined {
  const id = cleanText(comment.id);
  const body = cleanText(comment.body);
  const url = cleanText(comment.url);
  if (!id || !body || !url) return undefined;

  const path = cleanText(comment.path) || fallbackLocation?.path;
  const line =
    numberFrom(comment.line) ??
    numberFrom(comment.originalLine) ??
    fallbackLocation?.line;
  const diffHunk = cleanText(comment.diffHunk);

  return {
    id,
    kind,
    author: loginFrom(comment.author),
    body,
    url,
    createdAt: timestampFrom(comment),
    ...(path ? { path } : {}),
    ...(line !== undefined ? { line } : {}),
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
      line: numberFrom(thread.line) ?? numberFrom(thread.originalLine),
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

function formatModelMessage(target: PullRequestTarget, feedback: ReviewFeedback[]): string {
  return feedback
    .map((item) => {
      const location = formatLocation(item);
      const metadata = [
        `${target.owner}/${target.name}#${target.number}`,
        `@${item.author}`,
        location,
      ].filter(Boolean);
      const diff = item.diffHunk ? `\n\nDiff context:\n${item.diffHunk}` : "";
      return `${metadata.join(" · ")} ${item.url}\n\n${item.body}${diff}`;
    })
    .join("\n\n---\n\n");
}

function hyperlink(url: string, text: string): string {
  if (!/^https?:\/\/[^\s\u001b\u0007]+$/.test(url)) return text;
  return `\u001b]8;;${url}\u0007${text}\u001b]8;;\u0007`;
}

function quoteMarkdown(body: string): string {
  return body.split("\n").map((line) => `> ${line}`).join("\n");
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

export default function (pi: ExtensionAPI) {
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

      details.feedback.forEach((item, index) => {
        if (index > 0) box.addChild(new Spacer(1));

        const separator = theme.fg("dim", " · ");
        const location = formatLocation(item);
        let header = theme.fg(
          "muted",
          `${details.target.owner}/${details.target.name}#${details.target.number}`,
        );
        header += separator + theme.fg("accent", `@${item.author}`);
        if (location) header += separator + theme.fg("text", location);
        header += ` ${hyperlink(item.url, theme.fg("accent", "↗"))}`;

        box.addChild(new Text(header, 0, 0));
        box.addChild(new Spacer(1));
        box.addChild(
          new Markdown(quoteMarkdown(item.body), 0, 0, markdownTheme, {
            color: (text) => theme.fg("customMessageText", text),
          }),
        );
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
