import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
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

const THINKING_LABELS: Record<ThinkingLevel, string> = {
  off: "",
  minimal: "min",
  low: "low",
  medium: "med",
  high: "hgh",
  xhigh: "xhi",
};

const STATUSLINE_SYMBOLS = {
  model: "",
  path: "",
  branch: "",
  commit: "#",
  contextUsed: "■",
  contextFree: "□",
  contextReserved: "▣",
  contextCapacityMarker: "",
  contextUsageMarker: "",
  gitAhead: "",
  gitBehind: "",
  gitDiverged: "",
  diffAdded: "↗",
  diffRemoved: "↘",
  currency: "$",
} as const;

const GIT_REFRESH_MS = 5000;

interface CompactionSettingsSnapshot {
  enabled: boolean;
  reserveTokens: number;
  keepRecentTokens: number;
}

const DEFAULT_COMPACTION_SETTINGS: CompactionSettingsSnapshot = {
  enabled: true,
  reserveTokens: 16_384,
  keepRecentTokens: 20_000,
};

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

function coerceCompactionSettings(
  value: unknown,
  fallback: CompactionSettingsSnapshot = DEFAULT_COMPACTION_SETTINGS,
): CompactionSettingsSnapshot {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return { ...fallback };
  }

  const settings = value as Record<string, unknown>;
  const reserveRaw = Number(settings.reserveTokens);
  const keepRecentRaw = Number(settings.keepRecentTokens);

  return {
    enabled: typeof settings.enabled === "boolean" ? settings.enabled : fallback.enabled,
    reserveTokens: Number.isFinite(reserveRaw) ? Math.max(0, Math.floor(reserveRaw)) : fallback.reserveTokens,
    keepRecentTokens: Number.isFinite(keepRecentRaw)
      ? Math.max(0, Math.floor(keepRecentRaw))
      : fallback.keepRecentTokens,
  };
}

function readJsonObject(filePath: string): Record<string, unknown> | undefined {
  try {
    if (!existsSync(filePath)) return undefined;
    const content = readFileSync(filePath, "utf8");
    const parsed = JSON.parse(content);
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return undefined;
    return parsed as Record<string, unknown>;
  } catch {
    return undefined;
  }
}

function expandHome(pathValue: string): string {
  if (pathValue === "~") return homedir();
  if (pathValue.startsWith("~/") || pathValue.startsWith("~\\")) {
    return join(homedir(), pathValue.slice(2));
  }
  return pathValue;
}

function loadCompactionSettings(cwd: string): CompactionSettingsSnapshot {
  const agentDir = process.env.PI_CODING_AGENT_DIR
    ? expandHome(process.env.PI_CODING_AGENT_DIR)
    : join(homedir(), ".pi", "agent");

  const globalSettings = readJsonObject(join(agentDir, "settings.json"));
  const projectSettings = readJsonObject(join(cwd, ".pi", "settings.json"));

  let resolved = { ...DEFAULT_COMPACTION_SETTINGS };
  if (globalSettings?.compaction !== undefined) {
    resolved = coerceCompactionSettings(globalSettings.compaction, resolved);
  }
  if (projectSettings?.compaction !== undefined) {
    resolved = coerceCompactionSettings(projectSettings.compaction, resolved);
  }

  return resolved;
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
  const label = THINKING_LABELS[normalized];
  if (!symbol || !label) return "";
  return `${theme.getThinkingBorderColor(normalized)(symbol)}${theme.fg("dim", label)}`;
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

function getUsageData(entries: SessionEntry[]): {
  latest: UsageSnapshot | undefined;
  totalCost: number;
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

  return { latest, totalCost };
}

function buildBricks(
  cells: number,
  totalTokens: number,
  usedTokens: number,
  settings: CompactionSettingsSnapshot,
  theme: Theme,
): string {
  const n = Math.max(0, Math.floor(cells));
  if (n === 0) return "";

  const total = Math.max(1, Math.floor(totalTokens));
  const clampedUsedTokens = Math.max(0, Math.min(total, Math.floor(usedTokens)));

  const reserveTokens = settings.enabled ? Math.max(0, Math.floor(settings.reserveTokens)) : 0;
  const safeTokens = Math.max(0, Math.min(total, total - reserveTokens));

  let safeCells = Math.floor((safeTokens * n) / total);
  safeCells = Math.max(0, Math.min(n, safeCells));

  // Keep at least one reserved-tail cell visible when reserveTokens > 0 and the bar has room.
  if (settings.enabled && reserveTokens > 0 && n > 1 && safeCells >= n) {
    safeCells = n - 1;
  }

  let usedCells = Math.floor((clampedUsedTokens * n) / total);
  if (clampedUsedTokens > 0 && usedCells === 0) usedCells = 1;
  usedCells = Math.max(0, Math.min(n, usedCells));

  let out = "";

  for (let i = 0; i < usedCells; i++) {
    out += theme.fg("dim", STATUSLINE_SYMBOLS.contextUsed);
  }

  for (let i = usedCells; i < safeCells; i++) {
    out += theme.fg("dim", STATUSLINE_SYMBOLS.contextFree);
  }

  for (let i = Math.max(usedCells, safeCells); i < n; i++) {
    out += theme.fg("dim", STATUSLINE_SYMBOLS.contextReserved);
  }

  return out;
}

function buildGitStatus(counts: GitCounts, theme: Theme): string {
  if (counts.ahead > 0 && counts.behind > 0) {
    return `${theme.fg("accent", STATUSLINE_SYMBOLS.gitDiverged)}${theme.fg("dim", `${counts.ahead}/${counts.behind}`)}`;
  }
  if (counts.ahead > 0) {
    return `${theme.fg("accent", STATUSLINE_SYMBOLS.gitAhead)}${theme.fg("dim", `${counts.ahead}`)}`;
  }
  if (counts.behind > 0) {
    return `${theme.fg("warning", STATUSLINE_SYMBOLS.gitBehind)}${theme.fg("dim", `${counts.behind}`)}`;
  }
  return "";
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
  compactionSettings: CompactionSettingsSnapshot,
): string[] {
  if (width <= 0) return ["", ""];

  const entries = ctx.sessionManager.getBranch();
  const { latest, totalCost } = getUsageData(entries);

  const contextUsage = ctx.getContextUsage();
  const totalTokens = Math.max(
    1,
    Math.floor(toNumber(contextUsage?.contextWindow ?? ctx.model?.contextWindow ?? 200_000)),
  );

  const contextTokensRaw = contextUsage?.tokens;
  const contextTokensKnown = typeof contextTokensRaw === "number" && Number.isFinite(contextTokensRaw);
  const contextTokens = contextTokensKnown ? Math.max(0, Math.floor(contextTokensRaw)) : 0;

  const usedRaw = Number(contextUsage?.percent);
  const hasUsedPercent = Number.isFinite(usedRaw) && usedRaw >= 0;
  const usedPct = Math.max(
    0,
    Math.min(100, Math.round(hasUsedPercent ? usedRaw : (contextTokens * 100) / Math.max(1, totalTokens))),
  );

  let inputTokens = latest ? latest.input : contextTokens;
  let cacheTokens = latest ? latest.cacheRead + latest.cacheWrite : 0;

  const minUsedTokens = Math.max(0, contextTokens);
  if (inputTokens + cacheTokens < minUsedTokens) {
    inputTokens += minUsedTokens - (inputTokens + cacheTokens);
  }

  const usageFromLatest = Math.max(0, Math.floor(inputTokens + cacheTokens));
  const usageFromPercent = hasUsedPercent ? Math.floor((usedPct * totalTokens) / 100) : 0;
  const usedTokensForBar = contextTokensKnown ? contextTokens : Math.max(usageFromPercent, usageFromLatest);

  const reserveTokens = compactionSettings.enabled ? Math.max(0, compactionSettings.reserveTokens) : 0;
  const compactAtTokens = Math.max(0, totalTokens - reserveTokens);

  const model = normalizeModel(ctx.model?.name || ctx.model?.id || "Claude");
  const thinking = renderThinkingLevel(thinkingLevel, theme);
  const modelBase = `${theme.fg("accent", STATUSLINE_SYMBOLS.model)}${theme.fg("text", model)}`;
  const modelSegment = thinking ? `${modelBase} ${thinking}` : modelBase;

  const usedK = Math.floor(usedTokensForBar / 1000);
  const totalK = Math.max(1, Math.floor(totalTokens / 1000));

  const totalWindowWidget = `${theme.fg("accent", STATUSLINE_SYMBOLS.contextCapacityMarker)}${theme.fg("dim", `${totalK}k`)}`;
  const left = `${modelSegment} ${totalWindowWidget}`;

  const usedWidget = `${theme.fg("accent", STATUSLINE_SYMBOLS.contextUsageMarker)}${theme.fg("dim", `${usedK}k`)}`;

  const rightParts: string[] = [];
  if (width >= 40) {
    rightParts.push(usedWidget);
  }
  if (width >= 60 && totalCost > 0) {
    rightParts.push(
      `${theme.fg("warning", STATUSLINE_SYMBOLS.currency)}${theme.fg("dim", totalCost.toFixed(2))}`,
    );
  }
  const right = rightParts.join(" ");

  const maxBar = Math.max(0, Math.floor(width * 0.6));
  const minBar = width >= 100 ? 12 : width >= 70 ? 8 : 4;
  const availableForBar = width - visibleWidth(left) - visibleWidth(right) - 2;
  const barCells = Math.max(0, Math.min(maxBar, availableForBar));
  const bricks = buildBricks(barCells >= minBar ? barCells : 0, totalTokens, usedTokensForBar, compactionSettings, theme);

  const line1Parts = [left];
  if (bricks) line1Parts.push(bricks);
  if (right) line1Parts.push(right);
  const line1 = line1Parts.join(" ");

  const locationText = git.repository || normalizePath(ctx.cwd);
  const location = `${theme.fg("accent", STATUSLINE_SYMBOLS.path)}${theme.fg("dim", locationText)}`;
  let line2 = location;

  if (git.branch) {
    line2 += ` ${theme.fg("accent", STATUSLINE_SYMBOLS.branch)}${theme.fg("dim", git.branch)}`;
  }
  if (git.commit) {
    line2 += ` ${theme.fg("accent", STATUSLINE_SYMBOLS.commit)}${theme.fg("dim", git.commit)}`;
  }

  const diffParts: string[] = [];
  if (git.added > 0) {
    diffParts.push(`${theme.fg("success", STATUSLINE_SYMBOLS.diffAdded)}${theme.fg("dim", `${git.added}`)}`);
  }
  if (git.removed > 0) {
    diffParts.push(`${theme.fg("error", STATUSLINE_SYMBOLS.diffRemoved)}${theme.fg("dim", `${git.removed}`)}`);
  }
  if (diffParts.length > 0) {
    line2 += ` ${diffParts.join(" ")}`;
  }

  const gitStatus = buildGitStatus(git.counts, theme);
  if (gitStatus) line2 += ` ${gitStatus}`;

  return [
    truncateToWidth(line1, width, theme.fg("dim", "...")),
    truncateToWidth(line2.trimEnd(), width, theme.fg("dim", "...")),
  ];
}

export default function (pi: ExtensionAPI) {
  let compactionSettings: CompactionSettingsSnapshot = { ...DEFAULT_COMPACTION_SETTINGS };

  const installFooter = (ctx: ExtensionContext) => {
    if (!ctx.hasUI) return;

    compactionSettings = loadCompactionSettings(ctx.cwd);

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
            compactionSettings = loadCompactionSettings(ctx.cwd);
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
          return renderFooterLines(width, ctx, currentGit, pi.getThinkingLevel(), theme, compactionSettings);
        },
      };
    });
  };

  pi.on("session_before_compact", async (event) => {
    compactionSettings = coerceCompactionSettings(event.preparation.settings, compactionSettings);
  });

  pi.on("session_start", async (_event, ctx) => {
    installFooter(ctx);
  });

  pi.on("session_switch", async (_event, ctx) => {
    installFooter(ctx);
  });
}
