import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { getSupportedThinkingLevels } from "@earendil-works/pi-ai";
import type { Api, Model, ModelThinkingLevel } from "@earendil-works/pi-ai";

// Shortcuts that cycle the three axes of model selection independently. Each
// axis owns an adjacent key pair, left key backward and right key forward:
//
//   ctrl+p / ctrl+\   provider
//   ctrl+; / ctrl+'   model within the current provider
//   ctrl+, / ctrl+.   reasoning effort (thinking level)
//
// pi's built-in app.model.cycleForward/Backward walk the flat list of scoped
// models, which mixes providers and models. Disable those in keybindings.json
// so these shortcuts take over.
//
// Avoid ctrl+letters that ASCII already claims: ctrl+m is carriage return,
// ctrl+i tab, ctrl+j newline, ctrl+h backspace, ctrl+[ escape. pi matches those
// control characters even under the Kitty protocol, so such a shortcut eats the
// real key. Punctuation keys have no legacy encoding and arrive as Kitty CSI-u
// sequences, which is why ctrl+; and ctrl+,/. are safe.

enum Direction {
  Backward = -1,
  Forward = 1,
}

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

function createCycler(pi: ExtensionAPI) {
  // Model chosen last for a given provider, so returning to it feels sticky.
  const lastModelPerProvider = new Map<string, string>();

  // pi snapshots ctx.model when the key is pressed and dispatches handlers
  // without awaiting them, while applying a model awaits an auth check that can
  // reach the network. A burst of keystrokes would therefore all step from the
  // same stale model, making the selection stall or jump around. Track what we
  // asked for and apply switches one after another so every press advances
  // exactly one step.
  let requested: Model<Api> | undefined;
  let inFlight = 0;
  let queue: Promise<unknown> = Promise.resolve();

  // The requested model outranks the snapshot only while switches are pending;
  // afterwards the session is authoritative and reflects /model and restores.
  const selected = (ctx: ExtensionContext): Model<Api> | undefined =>
    inFlight > 0 ? requested : ctx.model;

  function select(ctx: ExtensionContext, model: Model<Api>): void {
    const current = selected(ctx);

    if (current && modelKey(current) === modelKey(model)) {
      return;
    }

    requested = model;
    inFlight += 1;
    queue = queue
      .then(async () => {
        // The footer reflects the new selection, so only failures need a message.
        if (!(await pi.setModel(model))) {
          ctx.ui.notify(`No credentials for ${modelKey(model)}`, "error");
        }
      })
      .catch((error: unknown) => {
        ctx.ui.notify(error instanceof Error ? error.message : String(error), "error");
      })
      .finally(() => {
        inFlight -= 1;
      });
  }

  function cycleProvider(ctx: ExtensionContext, direction: Direction): void {
    const models = selectableModels(ctx);
    const providers = providersOf(models);

    if (providers.length <= 1) {
      return;
    }

    const current = selected(ctx);

    if (current) {
      lastModelPerProvider.set(current.provider, current.id);
    }

    const provider = step(providers, current ? providers.indexOf(current.provider) : -1, direction);
    const candidates = models.filter((model) => model.provider === provider);
    const remembered = lastModelPerProvider.get(provider);

    select(ctx, candidates.find((model) => model.id === remembered) ?? candidates[0]!);
  }

  function cycleModel(ctx: ExtensionContext, direction: Direction): void {
    const models = selectableModels(ctx);
    const current = selected(ctx);

    if (!current) {
      if (models.length > 0) {
        select(ctx, models[0]!);
      }
      return;
    }

    const candidates = models.filter((model) => model.provider === current.provider);

    if (candidates.length <= 1) {
      return;
    }

    const index = candidates.findIndex((model) => modelKey(model) === modelKey(current));

    select(ctx, step(candidates, index, direction));
  }

  // pi only has a built-in app.thinking.cycle action that moves forward. Use
  // extension shortcuts to provide both directions, using the model's
  // thinkingLevelMap metadata to skip unsupported levels.
  function cycleEffort(ctx: ExtensionContext, direction: Direction): void {
    const model = selected(ctx);
    const levels: ModelThinkingLevel[] = model ? getSupportedThinkingLevels(model) : ["off"];

    if (levels.length <= 1) {
      return;
    }

    pi.setThinkingLevel(step(levels, levels.indexOf(pi.getThinkingLevel()), direction));
  }

  return { cycleProvider, cycleModel, cycleEffort };
}

export default function (pi: ExtensionAPI) {
  // Reset per process; /reload re-evaluates this module and starts fresh.
  const cycle = createCycler(pi);

  pi.registerShortcut("ctrl+p", {
    description: "Cycle provider backward",
    handler: (ctx) => cycle.cycleProvider(ctx, Direction.Backward),
  });

  pi.registerShortcut("ctrl+\\", {
    description: "Cycle provider forward",
    handler: (ctx) => cycle.cycleProvider(ctx, Direction.Forward),
  });

  pi.registerShortcut("ctrl+;", {
    description: "Cycle model backward",
    handler: (ctx) => cycle.cycleModel(ctx, Direction.Backward),
  });

  pi.registerShortcut("ctrl+'", {
    description: "Cycle model forward",
    handler: (ctx) => cycle.cycleModel(ctx, Direction.Forward),
  });

  pi.registerShortcut("ctrl+,", {
    description: "Cycle reasoning effort backward",
    handler: (ctx) => cycle.cycleEffort(ctx, Direction.Backward),
  });

  pi.registerShortcut("ctrl+.", {
    description: "Cycle reasoning effort forward",
    handler: (ctx) => cycle.cycleEffort(ctx, Direction.Forward),
  });
}
