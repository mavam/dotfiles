import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

type ThinkingLevel = "off" | "minimal" | "low" | "medium" | "high" | "xhigh";
type Direction = -1 | 1;

const LEVELS: readonly ThinkingLevel[] = ["off", "minimal", "low", "medium", "high", "xhigh"];

// pi only has a built-in app.thinking.cycle action that moves forward.
// Use extension shortcuts to provide a separate backward direction.
function wrapIndex(index: number): number {
  return (index + LEVELS.length) % LEVELS.length;
}

function cycleThinkingLevel(pi: ExtensionAPI, ctx: ExtensionContext, direction: Direction): void {
  const initialLevel = pi.getThinkingLevel();
  const startIndex = LEVELS.indexOf(initialLevel);
  const normalizedStartIndex = startIndex >= 0 ? startIndex : 0;

  for (let offset = 1; offset <= LEVELS.length; offset++) {
    const nextLevel = LEVELS[wrapIndex(normalizedStartIndex + direction * offset)];
    pi.setThinkingLevel(nextLevel);

    const actualLevel = pi.getThinkingLevel();
    if (actualLevel !== initialLevel) {
      ctx.ui.notify(`Thinking level: ${actualLevel}`, "info");
      return;
    }
  }

  ctx.ui.notify("Current model does not support thinking", "warning");
}

export default function (pi: ExtensionAPI) {
  pi.registerShortcut("ctrl+.", {
    description: "Cycle thinking level forward",
    handler: (ctx) => cycleThinkingLevel(pi, ctx, 1),
  });

  pi.registerShortcut("ctrl+,", {
    description: "Cycle thinking level backward",
    handler: (ctx) => cycleThinkingLevel(pi, ctx, -1),
  });
}
