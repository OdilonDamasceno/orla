<p align="center">
  <img src="docs/assets/orla-hero.png" alt="Orla visual concept with launcher, notifications, media controls, and a live score" width="100%">
</p>

<h1 align="center">Orla</h1>

<p align="center">
  A compact, configurable Wayland shell built with Quickshell and QML.
</p>

<p align="center">
  <a href="README.md">Português</a> · <strong>English</strong>
</p>

<p align="center">
  <img alt="NixOS" src="https://img.shields.io/badge/NixOS-ready-5277C3?logo=nixos&logoColor=white">
  <img alt="Wayland" src="https://img.shields.io/badge/Wayland-Hyprland-FFBC00?logo=wayland&logoColor=black">
  <img alt="Qt Quick" src="https://img.shields.io/badge/Qt_Quick-QML-41CD52?logo=qt&logoColor=white">
  <img alt="GPLv3 license" src="https://img.shields.io/badge/license-GPLv3-blue">
</p>

Orla brings together an app launcher, system controls, notifications, media, tray items, wallpapers, and a football Live Activity in a small, continuous interface. Its structure follows Material Design 3 semantic roles, while proportions, depth, and motion get an Apple-inspired finish.

> [!NOTE]
> The opening image is a visual direction concept. The image below is a real screenshot of the running interface.

## Real interface

<p align="center">
  <img src="docs/assets/orla-launcher.png" alt="The real Orla launcher open at the top of a Hyprland desktop" width="100%">
</p>

Orla creates one bar per monitor. The center island starts as a clock and expands in place for search or system controls, without resizing the native Wayland surface on every animation frame.

## Highlights

| Feature | What it provides |
| --- | --- |
| Expanding island | Clock, launcher, and system controls in one continuous surface. |
| Unified launcher | Searches applications, local files, and browser history. |
| Quick controls | Audio, microphone, networking, Bluetooth, and media through Quickshell services. |
| Notifications | Overlay, actions, inline replies, interaction-aware expiry, and session history. |
| Live Activity | Live score for a configurable team, with match time and optional badges. |
| Wallpapers | Search and application through `hyprpaper` on every monitor. |
| Integrated settings | Visual screen and JSON for colors, typography, motion, clock, launcher, notifications, and more. |
| Accessibility | Visible focus, keyboard navigation, accessible names, and reduced motion. |

## Run

You need a Wayland session running Hyprland. With flakes enabled:

```sh
nix run github:OdilonDamasceno/orla
```

From a local clone:

```sh
nix run .
```

The package includes Quickshell, Qt, the Sunghyun Sans font, `fd`, SQLite, and `xdg-open`. Live scores require the `golazo` command to be available in `PATH`; the rest of the shell continues to work without it.

## Install on NixOS

Add the project to your configuration inputs:

```nix
inputs.orla = {
  url = "github:OdilonDamasceno/orla";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Then add the package to your system:

```nix
outputs = inputs@{ nixpkgs, orla, ... }: {
  nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ({ pkgs, ... }: {
        environment.systemPackages = [
          orla.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
      })
    ];
  };
};
```

A basic Hyprland configuration can start the shell and expose both launchers:

```ini
exec-once = orla
bind = $mainMod, Space, exec, orla ipc call launcher toggle
bind = ALT, W, exec, orla ipc call wallpapers toggle
```

## Customize

Open the clock and choose **Settings** to edit preferences from the interface itself. Changes apply live and are persisted automatically. The screen can also be opened through IPC:

```sh
orla ipc call settings toggle
```

User configuration lives at `$XDG_CONFIG_HOME/orla/config.json`, or `~/.config/orla/config.json` by default. The file is optional: missing properties receive safe defaults, and changes to an existing file are reloaded automatically.

From a repository clone, copy the complete example:

```sh
mkdir -p ~/.config/orla
cp config.example.json ~/.config/orla/config.json
```

A minimal configuration may contain only the values you want to override:

```json
{
  "locale": "en_US",
  "appearance": {
    "primaryColor": "#D0BCFF",
    "islandColor": "#000000",
    "animationScale": 1.0
  },
  "bar": {
    "clockFormat": "ddd, MMM d · hh:mm"
  },
  "liveActivity": {
    "team": "Flamengo",
    "refreshIntervalSeconds": 60,
    "showBadges": true
  }
}
```

See every property and default in [`config.example.json`](config.example.json).

### Available groups

- `appearance`: semantic colors, font, and animation scale;
- `bar`: clock format and tray/Live Activity visibility;
- `liveActivity`: team, refresh interval, and badges;
- `launcher`: file search, history, limits, and wallpaper directory;
- `notifications`: timeout, history limit, and overlay position;
- `osd`: volume indicator duration;
- `accessibility`: reduced motion;
- `locale`: `pt_BR` or `en_US`.

The Live Activity interval is clamped to 15–600 seconds. Notification position accepts `top-left`, `top-right`, `bottom-left`, or `bottom-right`. Paths beginning with `~/` are expanded to the home directory.

Configuration and state remain separate: preferences live under `$XDG_CONFIG_HOME`, while application usage counts are stored at `$XDG_STATE_HOME/orla-launcher.json`.

## Use the launcher

The IPC endpoints can be called directly:

```sh
orla ipc call launcher toggle
orla ipc call launcher close
orla ipc call launcher isOpen
orla ipc call wallpapers toggle
orla ipc call wallpapers close
orla ipc call wallpapers isOpen
orla ipc call settings toggle
orla ipc call settings close
orla ipc call settings isOpen
```

Use the arrow keys to navigate, `Enter` to open, and `Escape` to close. Browser history search opens the configured database read-only; external results are handed to the system's default application.

## Develop

Enter the development environment and run the checkout directly:

```sh
nix develop
quickshell -n -p .
```

Before starting another instance, confirm that no shell is already running to avoid conflicting bars, notification servers, and shortcuts.

Check the QML files with:

```sh
bash scripts/check-qml.sh
```

Format the project with:

```sh
qmlformat -i shell.qml components/*.qml services/*.qml singletons/*.qml surfaces/*.qml widgets/*.qml
```

The project does not have an automated test suite yet. In addition to linting, validate the interface in a real session and inspect its logs:

```sh
quickshell log -p . -t 50 --no-color
```

## Structure

```text
shell.qml                  entry point, IPC, and per-monitor composition
components/                reusable visual primitives
services/                  headless search, scores, and lifecycle logic
singletons/Config.qml      preference loading and validation
singletons/Theme.qml       semantic tokens derived from configuration
singletons/I18n.qml        pt_BR and en_US translations
surfaces/                  visible Wayland surfaces
widgets/                   launcher, controls, media, and notifications
icons/                     local SVG icons
docs/assets/               documentation images
```

Read [`AGENTS.md`](AGENTS.md) before contributing. It documents the project's design decisions, QML conventions, and validation workflow.

## Project status

Orla is under active development and currently targets Hyprland. Some integrations depend on the host environment, including PipeWire, NetworkManager, Bluetooth, `hyprpaper`, and `golazo`. Missing services should degrade only the affected feature instead of preventing the shell from starting.

## License

Distributed under the [GNU General Public License v3.0](LICENSE).
