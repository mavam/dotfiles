import { SettingsManager, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

const PATCH_MARKER = Symbol.for("dotfiles.session-model-settings.patched");
const PATCHED_METHODS = ["setDefaultModelAndProvider", "setDefaultThinkingLevel"] as const;

type PatchedSettingsManagerPrototype = typeof SettingsManager.prototype & {
  [PATCH_MARKER]?: true;
};

export default function (_pi: ExtensionAPI): void {
  const prototype = SettingsManager.prototype as PatchedSettingsManagerPrototype;
  const missingMethods = PATCHED_METHODS.filter(
    (method) => typeof prototype[method] !== "function",
  );

  if (missingMethods.length > 0) {
    throw new Error(
      `session-model-settings is incompatible with this Pi version: ` +
        `SettingsManager is missing ${missingMethods.join(", ")}`,
    );
  }

  // Extensions are re-evaluated by /reload, but SettingsManager is shared. Patch
  // its prototype only once per process so reloads do not stack overrides.
  if (prototype[PATCH_MARKER]) {
    return;
  }

  // Pi records model and thinking-level changes in the session before calling
  // these setters. Suppress only their settings.json writes so the active and
  // resumed session keep their choices while new sessions use tracked defaults.
  prototype.setDefaultModelAndProvider = () => {};
  prototype.setDefaultThinkingLevel = () => {};

  Object.defineProperty(prototype, PATCH_MARKER, {
    value: true,
    enumerable: false,
  });
}
