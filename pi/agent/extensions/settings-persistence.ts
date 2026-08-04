import { SettingsManager, VERSION } from "@earendil-works/pi-coding-agent";

const PATCH_MARKER = Symbol.for("dotfiles.settings-persistence.patched-v1");
const OVERRIDDEN_METHODS = [
  "getLastChangelogVersion",
  "setLastChangelogVersion",
  "setDefaultModelAndProvider",
  "setDefaultThinkingLevel",
] as const;

type SettingsManagerPrototype = typeof SettingsManager.prototype & {
  [PATCH_MARKER]?: true;
};

export default function applySettingsPersistencePolicy(): void {
  const prototype = SettingsManager.prototype as SettingsManagerPrototype;
  const missingMethods = OVERRIDDEN_METHODS.filter(
    (method) => typeof prototype[method] !== "function",
  );

  if (missingMethods.length > 0) {
    throw new Error(
      `settings-persistence is incompatible with this Pi version: ` +
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

  // Pi otherwise writes its current version to settings.json after an upgrade.
  // Report the runtime version as already seen and suppress the generated write;
  // the full changelog remains available through /changelog.
  prototype.getLastChangelogVersion = () => VERSION;
  prototype.setLastChangelogVersion = () => {};

  Object.defineProperty(prototype, PATCH_MARKER, {
    value: true,
    enumerable: false,
  });
}
