import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext, SessionEntry, Theme } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

type ThinkingLevel = "off" | "minimal" | "low" | "medium" | "high" | "xhigh";

const THINKING_SYMBOLS: Record<ThinkingLevel, string> = {
  off: "",
  minimal: "✧",
  low: "✦",
  medium: "◆",
  high: "❖",
  xhigh: "✹",
};

const GIT_REFRESH_MS = 5000;

interface UsageSnapshot {
  input: number;
  cacheRead: number;
  cacheWrite: number;
  cost: number;
}

interface GitCounts {
  staged: number;
  modified: number;
  untracked: number;
  ahead: number;
  behind: number;
}

interface GitInfo {
  repository: string;
  branch: string;
  commit: string;
  added: number;
  removed: number;
  counts: GitCounts;
}

const EMPTY_GIT_INFO: GitInfo = {
  repository: "",
  branch: "",
  commit: "",
  added: 0,
  removed: 0,
  counts: {
    staged: 0,
    modified: 0,
    untracked: 0,
    ahead: 0,
    behind: 0,
  },
};

function toNumber(value: unknown): number {
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
}

function normalizePath(path: string): string {
  const home = process.env.HOME || process.env.USERPROFILE || "";
  if (!home) return path;
  if (path === home) return "~";
  if (path.startsWith(`${home}/`) || path.startsWith(`${home}\\`)) {
    return `~${path.slice(home.length)}`;
  }
  return path;
}

function normalizeModel(model: string): string {
  const trimmed = model.trim();
  if (!trimmed) return "Claude";
  return trimmed.replace(/^Claude\s+/i, "") || "Claude";
}

function normalizeThinkingLevel(level: string): ThinkingLevel {
  switch (level) {
    case "off":
    case "minimal":
    case "low":
    case "medium":
    case "high":
    case "xhigh":
      return level;
    default:
      return "off";
  }
}

function renderThinkingLevel(level: string, theme: Theme): string {
  const normalized = normalizeThinkingLevel(level);
  const symbol = THINKING_SYMBOLS[normalized];
  if (!symbol) return "";
  return theme.getThinkingBorderColor(normalized)(symbol);
}

function parseGitHubRemote(url: string): string {
  const match = url.match(/github\.com[:/](.+\/.+?)(?:\.git)?$/);
  return match?.[1] ?? "";
}

function parseNumstat(output: string): { added: number; removed: number } {
  let added = 0;
  let removed = 0;

  for (const line of output.split(/\r?\n/)) {
    if (!line.trim()) continue;
    const parts = line.split("\t");
    if (parts.length < 2) continue;
    const a = parts[0] || "";
    const b = parts[1] || "";
    if (a === "-" || b === "-") continue;
    added += toNumber(a);
    removed += toNumber(b);
  }

  return { added, removed };
}

function formatElapsed(ms: number): string {
  const safeMs = Math.max(0, Math.floor(ms));
  const h = Math.floor(safeMs / 3_600_000);
  const m = Math.floor((safeMs % 3_600_000) / 60_000);
  return `${h}h${m}m`;
}

function getUsageData(entries: SessionEntry[]): {
  latest: UsageSnapshot | undefined;
  totalCost: number;
  durationMs: number;
} {
  let latest: UsageSnapshot | undefined;
  let totalCost = 0;

  for (const entry of entries) {
    if (entry.type !== "message") continue;

    const message = entry.message as Partial<AssistantMessage>;
    if (message.role !== "assistant" || !message.usage) continue;

    const usage = message.usage;
    latest = {
      input: Math.max(0, toNumber(usage.input)),
      cacheRead: Math.max(0, toNumber(usage.cacheRead)),
      cacheWrite: Math.max(0, toNumber(usage.cacheWrite)),
      cost: Math.max(0, toNumber(usage.cost?.total)),
    };
    totalCost += latest.cost;
  }

  const startAt = entries[0]?.timestamp ? Date.parse(entries[0].timestamp) : Date.now();
  const durationMs = Number.isFinite(startAt) ? Math.max(0, Date.now() - startAt) : 0;

  return { latest, totalCost, durationMs };
}

function buildBricks(
  cells: number,
  totalTokens: number,
  inputTokens: number,
  cacheTokens: number,
  theme: Theme,
): string {
  const n = Math.max(0, Math.floor(cells));
  if (n === 0) return "";

  const total = Math.max(1, totalTokens);
  const t1 = Math.floor((n * 60) / 100);
  const t2 = Math.floor((n * 85) / 100);

  let cached = Math.floor((cacheTokens * n) / total);
  let fresh = Math.floor((inputTokens * n) / total);

  if (cacheTokens > 0 && cached === 0) cached = 1;
  if (inputTokens > 0 && fresh === 0) fresh = 1;

  cached = Math.min(n, cached);
  fresh = Math.min(Math.max(0, n - cached), fresh);

  const zoneColor = (i: number) => (i < t1 ? "success" : i < t2 ? "warning" : "error");

  let out = "";

  for (let i = 0; i < cached; i++) {
    out += theme.fg(zoneColor(i), "■");
  }

  for (let i = cached; i < cached + fresh; i++) {
    out += theme.fg(zoneColor(i), "■");
  }

  for (let i = cached + fresh; i < n; i++) {
    out += theme.fg(zoneColor(i), "□");
  }

  return out;
}

function buildGitStatus(counts: GitCounts, theme: Theme): string {
  const parts: string[] = [];

  if (counts.staged > 0) {
    parts.push(`${theme.fg("success", "●")}${theme.fg("dim", `${counts.staged}`)}`);
  }
  if (counts.modified > 0) {
    parts.push(`${theme.fg("warning", "●")}${theme.fg("dim", `${counts.modified}`)}`);
  }
  if (counts.untracked > 0) {
    parts.push(`${theme.fg("accent", "○")}${theme.fg("dim", `${counts.untracked}`)}`);
  }
  if (counts.ahead > 0) {
    parts.push(`${theme.fg("accent", "↑")}${theme.fg("dim", `${counts.ahead}`)}`);
  }
  if (counts.behind > 0) {
    parts.push(`${theme.fg("accent", "↓")}${theme.fg("dim", `${counts.behind}`)}`);
  }

  return parts.join(" ");
}

async function exec(
  pi: ExtensionAPI,
  command: string,
  args: string[],
  cwd: string,
): Promise<string> {
  try {
    const result = await pi.exec(command, args, { cwd, timeout: 2000 });
    if (result.code !== 0) return "";
    // Keep leading whitespace (git porcelain uses it), only drop trailing newlines.
    return result.stdout.replace(/[\r\n]+$/, "");
  } catch {
    return "";
  }
}

async function collectGitInfo(pi: ExtensionAPI, cwd: string): Promise<GitInfo> {
  const gitDir = await exec(pi, "git", ["rev-parse", "--git-dir"], cwd);
  if (!gitDir) return { ...EMPTY_GIT_INFO };

  const [branch, commit, remoteUrl, porcelain] = await Promise.all([
    exec(pi, "git", ["branch", "--show-current"], cwd),
    exec(pi, "git", ["rev-parse", "--short", "HEAD"], cwd),
    exec(pi, "git", ["config", "--get", "remote.origin.url"], cwd),
    exec(pi, "git", ["status", "--porcelain"], cwd),
  ]);

  let staged = 0;
  let modified = 0;
  let untracked = 0;

  for (const line of porcelain.split(/\r?\n/)) {
    if (!line) continue;
    const x = line[0] || " ";
    const y = line[1] || " ";

    if (x === "?") {
      untracked += 1;
      continue;
    }
    if (x !== " ") staged += 1;
    if (y !== " " && y !== "?") modified += 1;
  }

  let ahead = 0;
  let behind = 0;
  const upstream = await exec(pi, "git", ["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"], cwd);
  if (upstream) {
    const [aheadStr, behindStr] = await Promise.all([
      exec(pi, "git", ["rev-list", "--count", `${upstream}..HEAD`], cwd),
      exec(pi, "git", ["rev-list", "--count", `HEAD..${upstream}`], cwd),
    ]);
    ahead = Math.max(0, Math.floor(toNumber(aheadStr)));
    behind = Math.max(0, Math.floor(toNumber(behindStr)));
  }

  let added = 0;
  let removed = 0;

  const headDiff = await exec(pi, "git", ["diff", "--numstat", "HEAD"], cwd);
  if (headDiff) {
    const stats = parseNumstat(headDiff);
    added = stats.added;
    removed = stats.removed;
  } else {
    const [stagedDiff, unstagedDiff] = await Promise.all([
      exec(pi, "git", ["diff", "--numstat", "--cached"], cwd),
      exec(pi, "git", ["diff", "--numstat"], cwd),
    ]);
    const s1 = parseNumstat(stagedDiff);
    const s2 = parseNumstat(unstagedDiff);
    added = s1.added + s2.added;
    removed = s1.removed + s2.removed;
  }

  return {
    repository: parseGitHubRemote(remoteUrl),
    branch,
    commit,
    added,
    removed,
    counts: {
      staged,
      modified,
      untracked,
      ahead,
      behind,
    },
  };
}

function renderFooterLines(
  width: number,
  ctx: ExtensionContext,
  git: GitInfo,
  thinkingLevel: string,
  theme: Theme,
): string[] {
  if (width <= 0) return ["", ""];

  const entries = ctx.sessionManager.getBranch();
  const { latest, totalCost, durationMs } = getUsageData(entries);

  const contextUsage = ctx.getContextUsage();
  const totalTokens = Math.max(
    1,
    Math.floor(toNumber(contextUsage?.contextWindow ?? ctx.model?.contextWindow ?? 200_000)),
  );

  const contextTokens = Math.max(0, Math.floor(toNumber(contextUsage?.tokens)));
  const usedRaw = toNumber(contextUsage?.percent);
  const usedPct = Math.max(
    0,
    Math.min(
      100,
      Math.round(
        Number.isFinite(usedRaw) && usedRaw > 0 ? usedRaw : (contextTokens * 100) / Math.max(1, totalTokens),
      ),
    ),
  );

  let inputTokens = latest ? latest.input : contextTokens;
  let cacheTokens = latest ? latest.cacheRead + latest.cacheWrite : 0;

  const minUsedTokens = Math.max(0, contextTokens);
  if (inputTokens + cacheTokens < minUsedTokens) {
    inputTokens += minUsedTokens - (inputTokens + cacheTokens);
  }

  const pctColor = usedPct >= 85 ? "error" : usedPct >= 60 ? "warning" : "success";

  const model = normalizeModel(ctx.model?.name || ctx.model?.id || "Claude");
  const thinking = renderThinkingLevel(thinkingLevel, theme);
  const left = thinking ? `${theme.fg("text", model)} ${thinking}` : theme.fg("text", model);

  const usedK = Math.floor(Math.max(contextTokens, inputTokens + cacheTokens) / 1000);
  const totalK = Math.max(1, Math.floor(totalTokens / 1000));

  const rightParts = [theme.fg(pctColor, `${usedPct}%`)];
  if (width >= 50) {
    rightParts.push(theme.fg("dim", `${usedK}k/${totalK}k`));
  }
  if (width >= 55) {
    rightParts.push(theme.fg("muted", formatElapsed(durationMs)));
  }
  if (width >= 60 && totalCost > 0) {
    rightParts.push(theme.fg("warning", `$${totalCost.toFixed(2)}`));
  }
  const right = rightParts.join(" ");

  const maxBar = Math.max(0, Math.floor(width * 0.6));
  const minBar = width >= 100 ? 12 : width >= 70 ? 8 : 4;
  const availableForBar = width - visibleWidth(left) - visibleWidth(right) - 2;
  const barCells = Math.max(0, Math.min(maxBar, availableForBar));
  const bricks = buildBricks(barCells >= minBar ? barCells : 0, totalTokens, inputTokens, cacheTokens, theme);

  const line1Parts = [left];
  if (bricks) line1Parts.push(bricks);
  if (right) line1Parts.push(right);
  const line1 = line1Parts.join(" ");

  const location = theme.fg("dim", git.repository || normalizePath(ctx.cwd));
  let line2 = `${location} `;

  if (git.branch) line2 += theme.fg("syntaxPunctuation", git.branch);
  if (git.commit) line2 += ` ${theme.fg("syntaxComment", git.commit)}`;

  if (git.added > 0 || git.removed > 0) {
    line2 += ` ${theme.fg("success", `+${git.added}`)}/${theme.fg("error", `-${git.removed}`)}`;
  }

  const gitStatus = buildGitStatus(git.counts, theme);
  if (gitStatus) line2 += ` ${gitStatus}`;

  return [
    truncateToWidth(line1, width, theme.fg("dim", "...")),
    truncateToWidth(line2.trimEnd(), width, theme.fg("dim", "...")),
  ];
}

export default function (pi: ExtensionAPI) {
  const installFooter = (ctx: ExtensionContext) => {
    if (!ctx.hasUI) return;

    ctx.ui.setFooter((tui, theme, footerData) => {
      let currentGit: GitInfo = { ...EMPTY_GIT_INFO };
      let refreshing = false;
      let refreshQueued = false;
      let disposed = false;

      const refreshGit = async () => {
        if (disposed) return;
        if (refreshing) {
          refreshQueued = true;
          return;
        }

        refreshing = true;
        try {
          do {
            refreshQueued = false;
            const git = await collectGitInfo(pi, ctx.cwd);
            if (disposed) return;
            currentGit = git;
            tui.requestRender();
          } while (!disposed && refreshQueued);
        } finally {
          refreshing = false;
        }
      };

      const onBranchChange = footerData.onBranchChange(() => {
        void refreshGit();
      });

      const interval = setInterval(() => {
        void refreshGit();
      }, GIT_REFRESH_MS);

      void refreshGit();

      return {
        invalidate() {},
        dispose() {
          disposed = true;
          onBranchChange();
          clearInterval(interval);
        },
        render(width: number): string[] {
          return renderFooterLines(width, ctx, currentGit, pi.getThinkingLevel(), theme);
        },
      };
    });
  };

  pi.on("session_start", async (_event, ctx) => {
    installFooter(ctx);
  });

  pi.on("session_switch", async (_event, ctx) => {
    installFooter(ctx);
  });
}
