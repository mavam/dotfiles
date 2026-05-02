import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { getSupportedThinkingLevels } from "@mariozechner/pi-ai";

enum Direction {
  Backward = -1,
  Forward = 1,
}

// pi only has a built-in app.thinking.cycle action that moves forward.
// Use extension shortcuts to provide both directions, using the model's
// thinkingLevelMap metadata to skip unsupported levels.
function cycleThinkingLevel(pi: ExtensionAPI, ctx: ExtensionContext, direction: Direction): void {
  const levels = ctx.model ? getSupportedThinkingLevels(ctx.model) : ["off"];

  if (levels.length <= 1) {
    return;
  }

  const currentIndex = Math.max(0, levels.indexOf(pi.getThinkingLevel()));
  const nextLevel = levels[(currentIndex + direction + levels.length) % levels.length]!;

  pi.setThinkingLevel(nextLevel);
}

export default function (pi: ExtensionAPI) {
  pi.registerShortcut("ctrl+.", {
    description: "Cycle thinking level forward",
    handler: (ctx) => cycleThinkingLevel(pi, ctx, Direction.Forward),
  });

  pi.registerShortcut("ctrl+,", {
    description: "Cycle thinking level backward",
    handler: (ctx) => cycleThinkingLevel(pi, ctx, Direction.Backward),
  });
}
