# Kofein — menubar GUI for `caffeinate` — Design

Date: 2026-08-08
Status: Approved for implementation (decisions made autonomously from the user's detailed brief; deviations noted inline)

## Purpose

Kofein is a macOS menubar app that wraps `/usr/bin/caffeinate`. It lets the user
toggle sleep-prevention with one click, manage named profiles of caffeinate
options, start the app at login, and is fully bilingual (English + Slovenian).

## Requirements (from the brief)

- Menubar-only app (no Dock icon), quit-able from the menu.
- Can add/remove itself from the current user's login items.
- i18n from the start: English + Slovenian; falls back to English when the
  account language has no translation; translation format must make adding
  languages easy.
- All `caffeinate` options configurable: `-d`, `-i`, `-m`, `-s`, `-u`,
  `-t <seconds>`, `-w <pid>`, and the optional utility command.
- Option combinations saved as user-named profiles; app ships a built-in
  profile ("Keep Awake": prevent sleep until turned off) marked default on
  first run; any profile can be made default.
- Every option has descriptive help text.
- Left-click on the icon toggles the default/active profile on/off
  (caffeinate running or not). Right-click opens a menu: choose active
  profile, manage profiles (create/delete/edit/set default), app settings
  (login item), Quit.
- macOS 26+, Apple Silicon only. TDD. README = end-user docs, `docs/` =
  developer docs. No Co-Authored-By lines in commits.

## Decisions made autonomously

- **"Prevents computer from sleeping"** for the built-in default profile is
  implemented as `-d -i` (display + idle sleep prevented) — matches what users
  of similar tools (Amphetamine, KeepingYouAwake) expect from "keep awake".
- **Selecting a profile in the menu** changes the *active* profile for this
  session (and restarts caffeinate with it if currently running). Making a
  profile *default* (persisted, used at every launch) is done in the Profiles
  window.
- **Utility command** is run via `/bin/sh -c "<command>"` so quoting works.
- **At least one profile must exist**; deleting the default profile promotes
  another profile to default. The built-in profile is re-seeded only when the
  store is empty.
- App starts with caffeinate **off**; state is not persisted across launches.
- Bundle identifier: `com.markosamastur.Kofein`.

## Architecture

Swift Package Manager project (no `.xcodeproj`), Swift 6, arm64,
`macOS 26` platform target. Two products:

- **`KofeinCore`** (library) — all logic, fully unit-tested with Swift Testing
  (`swift test`):
  - `CaffeinateOptions` — `Codable` value type: five Bool flags, optional
    timeout, optional wait-PID, optional utility command; builds the argv for
    `caffeinate`; validates (e.g. timeout must be > 0).
  - `Profile` — `id: UUID`, `name`, `options`.
  - `ProfileStore` — loads/saves a JSON document
    (`profiles` + `defaultProfileID`) at
    `~/Library/Application Support/Kofein/profiles.json` through an injected
    file URL; CRUD, `setDefault`, seeds the built-in profile when empty,
    enforces the ≥1-profile / always-a-default invariants.
  - `CaffeinateController` — start/stop/toggle/switch-profile state machine
    over a `ProcessRunning` protocol (real implementation spawns
    `/usr/bin/caffeinate`; tests use a fake). Detects self-termination
    (e.g. `-t` expiry, watched pid exit) and reports state changes via a
    callback.
  - `LoginItemManaging` protocol — `isEnabled`, `setEnabled(_:)`.
- **`Kofein`** (executable, AppKit + SwiftUI) — thin UI layer, not unit-tested:
  - `NSStatusItem` with `cup.and.saucer.fill` / `cup.and.saucer` SF Symbols
    for on/off. Button receives both `.leftMouseUp` (toggle) and
    `.rightMouseUp` (show `NSMenu`).
  - Menu: profile list with checkmark on the active profile → "Profiles…" →
    "Start at Login" (checkbox) → "Quit Kofein".
  - Profiles window (SwiftUI): list of profiles; editor with a toggle per
    flag, numeric timeout field, PID field, command field — each with a
    caption + tooltip help text; Add / Delete / Set as Default.
  - `SMAppServiceLoginItemManager` — `SMAppService.mainApp` register/unregister.
  - Terminates the child caffeinate on quit.

## i18n

- Single **String Catalog** (`Localizable.xcstrings`) in the app target's
  resources, `defaultLocalization = "en"`, with `en` and `sl` translations.
  Adding a language = adding a column in the one JSON catalog file.
- All user-visible strings go through `String(localized:)`. The OS picks the
  account's preferred language and falls back to English automatically.

## Packaging

`swift build` produces a bare executable; `Makefile` + `scripts/bundle.sh`
assemble `Kofein.app` (copies binary + resource bundle, writes `Info.plist`
with `LSUIElement = true`, `LSMinimumSystemVersion = 26.0`, ad-hoc codesign).
`SMAppService` requires a proper bundle, which this provides.

## Error handling

- Store I/O errors: fall back to in-memory defaults, surface an alert.
- caffeinate spawn failure: alert + icon stays "off".
- Invalid editor input (non-numeric timeout/pid): field-level validation,
  saving disabled until valid.

## Testing (TDD)

Swift Testing, red-green-refactor, on `KofeinCore`:
- argv building for every option and combination; sh -c wrapping of the command
- store: seed-on-empty, CRUD, default-reassignment on delete, ≥1-profile
  invariant, persistence round-trip
- controller: toggle transitions, restart-on-profile-switch, external
  termination handling, stop-on-quit
- login item manager: protocol contract via fake (SMAppService itself is not
  testable headlessly)

## Documentation

- `README.md` — end-user: what it is, install/build, usage (clicks, profiles,
  login item), option help texts, both languages noted.
- `docs/development.md` — dev: architecture map, build/test/bundle commands,
  how to add a translation, how to add a new caffeinate option.
