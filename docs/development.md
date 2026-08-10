# Kofein — developer documentation

## Overview

Kofein is a SwiftPM package (no Xcode project) targeting macOS 26+, arm64
only. It has two targets:

- **`KofeinCore`** — all logic, fully unit-tested.
- **`Kofein`** — thin AppKit/SwiftUI executable; no unit tests, verified by
  building and running.

```
Sources/
  KofeinCore/
    CaffeinateOptions.swift    # option model + argv builder for caffeinate(8)
    TimeoutOption.swift        # session-timeout presets + localized duration labels
    Profile.swift              # named option combination
    ProfileStore.swift         # @Observable persistent store (JSON), invariants
    CaffeinateController.swift # start/stop state machine over ProcessRunning
    CaffeinateProcess.swift    # real /usr/bin/caffeinate child process
    LoginItemManaging.swift    # login-item protocol
    L10n.swift                 # string lookup + list of all keys
    Resources/
      en.lproj/Localizable.strings
      sl.lproj/Localizable.strings
  Kofein/
    main.swift                        # NSApplication bootstrap (accessory)
    AppDelegate.swift                 # wiring, profiles window, teardown
    StatusItemController.swift        # menubar icon, left/right click, menu
    ProfilesView.swift                # SwiftUI profile manager + editor
    ProfilesWindowController.swift    # NSWindow hosting ProfilesView
    SMAppServiceLoginItemManager.swift# SMAppService.mainApp wrapper
    Resources/                        # menubar icons (from domzilla/Caffeine, MIT)
Tests/KofeinCoreTests/               # Swift Testing suites
Assets/app-icon.png                  # app icon source (bundle.sh renders AppIcon.icns from it)
scripts/bundle.sh                    # assembles dist/Kofein.app
```

## Building and testing

```sh
make test    # swift test — run the unit test suite
make app     # release build + assemble dist/Kofein.app (ad-hoc signed)
make clean   # remove .build and dist
swift build  # debug build of both targets
```

Development follows TDD: write a failing test in `Tests/KofeinCoreTests`,
watch it fail, implement, watch it pass, commit.

Notes:

- `SMAppService` (Start at Login) only works when the app runs from the
  assembled `Kofein.app` bundle, not from the bare `swift build` executable.
- The status item behavior (left-click toggles, right-click opens the menu)
  is implemented by sending the button action on both mouse-up events and
  inspecting `NSApp.currentEvent`.
- `CaffeinateController` distinguishes stops it initiated from external
  process exits (e.g. `-t` timeout) by detaching the termination callback
  before terminating; external exits flip the state and notify the UI.
- The timeout (`-t`) is session state, not part of a profile:
  `CaffeinateOptions.arguments(timeoutSeconds:)` emits it only when
  `supportsTimeout` (no `-w`, no utility command — those runs are bounded
  by their process). `StatusItemController` holds the selected timeout and
  passes it to `activate`/`toggle`. Preset durations and their localized
  labels live in `TimeoutOption`; labels come from `DateComponentsFormatter`
  (correct plural forms per language), not from the string catalog.

## Localization

Strings live in classic `.strings` tables under
`Sources/KofeinCore/Resources/<lang>.lproj/Localizable.strings`.
(The design originally called for a String Catalog, but `swift build` copies
`.xcstrings` files verbatim instead of compiling them, so the classic format
is used.)

macOS resolves the user's account language against the available `lproj`
folders and falls back to English (`defaultLocalization` in `Package.swift`).
The user can override the language in the menubar menu: the choice is stored
in `UserDefaults` (`languageOverride`) and applied through
`L10n.languageOverride`, which routes lookups to that language's `lproj`.
`L10n.supportedLanguages` lists the shipped languages straight from the
bundle, so a new language shows up in the Language submenu automatically.

To add a language:

1. Copy `Sources/KofeinCore/Resources/en.lproj` to `<code>.lproj`
   (e.g. `de.lproj`) and translate every value.
2. Add the language code to the loop in
   `Tests/KofeinCoreTests/LocalizationTests.swift` — the test fails if any
   key from `L10n.allKeys` is missing in any listed language.
3. Run `make test`.

When adding a *string*, add its key to `L10n.allKeys` and a value to every
`Localizable.strings`; the same test enforces full coverage.

## Adding a new caffeinate option

1. Add a property to `CaffeinateOptions` and extend `arguments` — test-first
   in `CaffeinateOptionsTests.swift`.
2. Add `option.<name>.label` and `option.<name>.help` keys to `L10n.allKeys`
   and both `Localizable.strings` files.
3. Add a control for it in `ProfileEditor` (`ProfilesView.swift`).

## Storage

Profiles are persisted as pretty-printed JSON at
`~/Library/Application Support/Kofein/profiles.json`:

```json
{ "version": 1, "defaultProfileID": "…", "profiles": [ … ] }
```

`ProfileStore` guarantees at least one profile exists and that
`defaultProfileID` always points at a stored profile; a missing or corrupt
file is replaced by the seeded "Keep Awake" profile.

## Design documents

- Spec: `docs/superpowers/specs/2026-08-08-kofein-design.md`
- Implementation plan: `docs/superpowers/plans/2026-08-08-kofein.md`
