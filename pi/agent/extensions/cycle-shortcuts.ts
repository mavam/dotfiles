import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { getSupportedThinkingLevels } from "@earendil-works/pi-ai";
import type { ModelThinkingLevel } from "@earendil-works/pi-ai";

// Shortcuts for cycling reasoning effort (thinking level) in both directions:
//
//   ctrl+, / ctrl+.   reasoning effort
//
// Use pi's built-in ctrl+l model selector to switch models or providers.
//
// Punctuation keys have no legacy encoding and arrive as Kitty CSI-u sequences,
// which is why ctrl+,/. are safe.

enum Direction {
  Backward = -1,
  Forward = 1,
}

function step<T>(items: T[], currentIndex: number, direction: Direction): T {
  if (currentIndex < 0) {
    return items[0]!;
  }

  return items[(currentIndex + direction + items.length) % items.length]!;
}

export default function (pi: ExtensionAPI) {
  // pi only has a built-in app.thinking.cycle action that moves forward. Use
  // extension shortcuts to provide both directions, using the model's
  // thinkingLevelMap metadata to skip unsupported levels.
  function cycleEffort(ctx: ExtensionContext, direction: Direction): void {
    const levels: ModelThinkingLevel[] = ctx.model ? getSupportedThinkingLevels(ctx.model) : ["off"];

    if (levels.length <= 1) {
      return;
    }

    pi.setThinkingLevel(step(levels, levels.indexOf(pi.getThinkingLevel()), direction));
  }

  pi.registerShortcut("ctrl+,", {
    description: "Cycle reasoning effort backward",
    handler: (ctx) => cycleEffort(ctx, Direction.Backward),
  });

  pi.registerShortcut("ctrl+.", {
    description: "Cycle reasoning effort forward",
    handler: (ctx) => cycleEffort(ctx, Direction.Forward),
  });
}
