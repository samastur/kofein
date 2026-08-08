# Kofein

Kofein is a tiny macOS menubar app that keeps your Mac awake. It is a GUI
wrapper around the system `caffeinate` utility: one click prevents your Mac
(and optionally its display) from going to sleep, another click lets it sleep
again.

## Requirements

- macOS 26 or newer
- Apple Silicon (arm64)

## Install

Build from source (requires Xcode 26 command line tools):

```sh
make app
```

Then move `dist/Kofein.app` to `/Applications` and launch it. A cup icon
appears in the menu bar; there is no Dock icon.

## Usage

- **Left-click** the cup icon to toggle keeping the Mac awake on or off.
  A filled cup means caffeinate is running; an outlined cup means your Mac
  is free to sleep.
- **Right-click** the icon to open the menu:
  - **Profiles** — pick which profile the left-click toggle uses. If
    caffeinate is already running, it restarts with the chosen profile.
  - **Manage Profiles…** — create, edit, delete profiles and choose the
    default one.
  - **Start at Login** — add or remove Kofein from your login items.
    (This works when Kofein runs from a proper `Kofein.app` bundle, e.g.
    from `/Applications`.)
  - **Quit Kofein** — quits the app and stops caffeinate.

## Profiles

A profile is a named combination of caffeinate options. Kofein ships with a
built-in **Keep Awake** profile (prevents display and system sleep until you
turn it off), which is the default after installation. You can create any
number of profiles and mark any of them as the default; the default profile
is what the left-click toggle uses after the app starts.

Available options (each is explained in the app as well):

| Option | caffeinate flag | What it does |
| --- | --- | --- |
| Prevent display sleep | `-d` | Keeps the display from going to sleep while the profile is active. |
| Prevent idle system sleep | `-i` | Keeps the system from idle sleeping; the display may still turn off. |
| Prevent disk idle sleep | `-m` | Keeps the disk from idle sleeping. |
| Prevent system sleep on AC power | `-s` | Prevents system sleep, but only while the Mac runs on AC power. |
| Declare user is active | `-u` | Tells the system the user is active and turns the display on if it is off. Without a timeout this lasts only 5 seconds. |
| Timeout (seconds) | `-t` | Turns caffeinate off automatically after the given number of seconds. Leave empty to keep it on until you turn it off. Ignored when a command is set. |
| Wait for process (PID) | `-w` | Keeps the assertions until the process with the given PID exits. Ignored when a command is set. |
| Run command | *utility* | Runs a shell command (via `/bin/sh -c`) and keeps the assertions while it is running. |

Profiles are stored in
`~/Library/Application Support/Kofein/profiles.json`.

## Languages

Kofein speaks **English** and **Slovenian**. It follows the language set for
your macOS account and falls back to English for languages it does not have.

## Development

See [docs/development.md](docs/development.md).

## License

See [LICENSE](LICENSE).
