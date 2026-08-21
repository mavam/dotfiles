import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { getSupportedThinkingLevels } from "@earendil-works/pi-ai";
import type { Api, Model, ModelThinkingLevel } from "@earendil-works/pi-ai";

// Shortcuts that cycle the three axes of model selection independently:
//
//   ctrl+p   provider
//   ctrl+m   model within the current provider
//   ctrl+,/. reasoning effort (thinking level)
//
// pi's built-in app.model.cycleForward/Backward walk the flat list of scoped
// models, which mixes providers and models. Disable those in keybindings.json
// so these shortcuts take over.

enum Direction {
  Backward = -1,
  Forward = 1,
}

/** Model chosen last for a given provider, so returning to it feels sticky. */
type ProviderMemory = Map<string, string>;

function modelKey(model: Model<Api>): string {
  return `${model.provider}/${model.id}`;
}

/**
 * Selectable models in configured order: the session's scoped models
 * (`enabledModels`) when scoping applies, otherwise everything with auth.
 */
function selectableModels(ctx: ExtensionContext): Model<Api>[] {
  const available = ctx.modelRegistry.getAvailable();

  if (ctx.scopedModels.length === 0) {
    return available;
  }

  const availableKeys = new Set(available.map(modelKey));

  return ctx.scopedModels.map((scoped) => scoped.model).filter((model) => availableKeys.has(modelKey(model)));
}

function providersOf(models: Model<Api>[]): string[] {
  return [...new Set(models.map((model) => model.provider))];
}

function step<T>(items: T[], currentIndex: number, direction: Direction): T {
  if (currentIndex < 0) {
    return items[0]!;
  }

  return items[(currentIndex + direction + items.length) % items.length]!;
}

async function switchModel(pi: ExtensionAPI, ctx: ExtensionContext, model: Model<Api>): Promise<void> {
  if (ctx.model && modelKey(ctx.model) === modelKey(model)) {
    return;
  }

  // The footer reflects the new selection, so only failures need a message.
  if (!(await pi.setModel(model))) {
    ctx.ui.notify(`No credentials for ${modelKey(model)}`, "error");
  }
}

async function cycleProvider(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  direction: Direction,
  memory: ProviderMemory,
): Promise<void> {
  const models = selectableModels(ctx);
  const providers = providersOf(models);

  if (providers.length <= 1) {
    return;
  }

  if (ctx.model) {
    memory.set(ctx.model.provider, ctx.model.id);
  }

  const provider = step(providers, ctx.model ? providers.indexOf(ctx.model.provider) : -1, direction);
  const candidates = models.filter((model) => model.provider === provider);
  const remembered = memory.get(provider);

  await switchModel(pi, ctx, candidates.find((model) => model.id === remembered) ?? candidates[0]!);
}

async function cycleModel(pi: ExtensionAPI, ctx: ExtensionContext, direction: Direction): Promise<void> {
  const models = selectableModels(ctx);

  if (!ctx.model) {
    if (models.length > 0) {
      await switchModel(pi, ctx, models[0]!);
    }
    return;
  }

  const provider = ctx.model.provider;
  const candidates = models.filter((model) => model.provider === provider);

  if (candidates.length <= 1) {
    return;
  }

  const next = step(
    candidates,
    candidates.findIndex((model) => modelKey(model) === modelKey(ctx.model!)),
    direction,
  );

  await switchModel(pi, ctx, next);
}

// pi only has a built-in app.thinking.cycle action that moves forward. Use
// extension shortcuts to provide both directions, using the model's
// thinkingLevelMap metadata to skip unsupported levels.
function cycleEffort(pi: ExtensionAPI, ctx: ExtensionContext, direction: Direction): void {
  const levels: ModelThinkingLevel[] = ctx.model ? getSupportedThinkingLevels(ctx.model) : ["off"];

  if (levels.length <= 1) {
    return;
  }

  pi.setThinkingLevel(step(levels, levels.indexOf(pi.getThinkingLevel()), direction));
}

export default function (pi: ExtensionAPI) {
  // Reset per process; /reload re-evaluates this module and clears the memory.
  const memory: ProviderMemory = new Map();

  pi.registerShortcut("ctrl+p", {
    description: "Cycle provider forward",
    handler: (ctx) => cycleProvider(pi, ctx, Direction.Forward, memory),
  });

  pi.registerShortcut("shift+ctrl+p", {
    description: "Cycle provider backward",
    handler: (ctx) => cycleProvider(pi, ctx, Direction.Backward, memory),
  });

  pi.registerShortcut("ctrl+m", {
    description: "Cycle model within provider forward",
    handler: (ctx) => cycleModel(pi, ctx, Direction.Forward),
  });

  pi.registerShortcut("shift+ctrl+m", {
    description: "Cycle model within provider backward",
    handler: (ctx) => cycleModel(pi, ctx, Direction.Backward),
  });

  pi.registerShortcut("ctrl+.", {
    description: "Cycle reasoning effort forward",
    handler: (ctx) => cycleEffort(pi, ctx, Direction.Forward),
  });

  pi.registerShortcut("ctrl+,", {
    description: "Cycle reasoning effort backward",
    handler: (ctx) => cycleEffort(pi, ctx, Direction.Backward),
  });
}
