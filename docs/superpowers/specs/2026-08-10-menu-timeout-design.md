# Session timeout in the menu (removed from profiles) — Design

Date: 2026-08-10
Status: Approved for implementation (from the user's brief; details resolved
autonomously and noted below)

## Change

Timeout (`caffeinate -t`) is no longer part of a profile. It becomes a
session-level setting in the right-click menu that bounds how long the
currently selected profile runs.

Rationale: a profile that waits on a PID (`-w`) or runs a utility command
must not be cut short by a timeout and cannot outlive its process either —
combining them is nonsense. macOS itself ignores `-t` in those cases.

## Behavior

- **Timeout submenu** in the context menu (between the profile list and
  "Manage Profiles…"): Indefinitely (default), 5, 10, 15, 30 minutes,
  1, 2, 5 hours, and "Custom…" which opens a dialog accepting a number of
  minutes or hours. Checkmark on the current choice; a custom value is shown
  in the "Custom (…)…" title.
- The selection is session state (like the active profile): not persisted,
  resets to Indefinitely on launch.
- Changing the timeout while caffeinate runs restarts it with the new value;
  expiry simply ends the run (existing external-termination handling).
- **Incompatible profiles** (`waitForPID` set or a utility command set):
  the Timeout item is disabled and a disabled notice line under it explains
  that the selected profile is not compatible with a timeout. The core also
  refuses to emit `-t` for such profiles (single source of truth).

## Model

- `CaffeinateOptions`: `timeoutSeconds` property removed (old profile JSON
  decodes fine — unknown keys are ignored). New:
  - `var supportsTimeout: Bool` — false when `waitForPID != nil` or a
    non-blank `utilityCommand` is set.
  - `func arguments(timeoutSeconds: Int? = nil) -> [String]` — appends
    `-t <n>` only when supported and non-nil.
- `CaffeinateController.activate/toggle` gain `timeoutSeconds: Int? = nil`.
- New `TimeoutOption` (core): `presetSeconds = [300, 600, 900, 1800, 3600,
  7200, 18000]` and `label(seconds:locale:)` via `DateComponentsFormatter`,
  which localizes unit names and plural forms (incl. Slovenian dual) for
  free; `L10n.locale` exposes the override-aware locale.
- Profile editor loses the timeout field; its two catalog keys are removed.

## Docs

README: timeout row moves out of the profile option table into its own
section describing the menu; usage section gains the submenu. development.md
updated for the new core API.
