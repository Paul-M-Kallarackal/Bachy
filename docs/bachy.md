# Installation and desktop setup

## CachyOS / Arch Linux package

```sh
sudo pacman -S --needed git base-devel rust
git clone https://github.com/Paul-M-Kallarackal/Bachy.git
cd Bachy
makepkg -si
bachy --gui
```

Review `PKGBUILD` before building. Dependencies must be available from your configured repositories or installed separately. In particular, the GUI requires Quickshell >= 0.3.1 and Qt 6; network/device features need the corresponding GVFS backends. The recipe runs core Rust, JavaScript and keymap checks. It does not change defaults or compositor bindings merely by being installed.

There is no bundled `.runtime/` directory in Git. `./run-bachy` prefers system Quickshell and can also use a locally prepared ignored runtime during development; the repository does not download one automatically. For a source build, run `cargo build --release --locked` first. Rebuild after Rust changes: the convenience launcher's missing-binary check is not a build freshness check.

## Default file manager and dialogs

To choose only the default folder handler:

```sh
xdg-mime default local.bachy.FileManager.desktop inode/directory
xdg-mime query default inode/directory
```

To additionally claim “Show in folder” routing and the chooser when its backend is installed:

```sh
bachy --default
```

The broader command writes per-user routing. The package installs a portal backend, so `--default` can affect Open/Save dialogs as well as folders; a source-only install without the backend skips that step. A chooser can also be selected with `bachy --picker`. Portal compatibility is still experimental.

Release Bachy's routing with `bachy --default off`, then explicitly choose the previous folder handler if needed, for example:

```sh
xdg-mime default org.kde.dolphin.desktop inode/directory
```

Use the desktop ID of your actual preferred manager. Do not assume removal of Bachy will automatically reconstruct every prior manual association. Other file managers can stay installed.

Files themselves use the default handler for their MIME type via GIO. HTML/PDF opening is not tied to Brave or another browser: your associations decide. A missing browser/viewer must be installed and configured; Bachy does not install it while opening a file.

## Hyprland 0.55+ Lua configuration

Replace your existing file-manager keybinding or its command variable, rather than creating a duplicate chord:

```lua
hl.bind("SUPER + E", hl.dsp.exec_cmd("bachy --gui"))
```

If your desktop uses UWSM, its existing launch convention can be retained with `uwsm app -- bachy --gui`. For a source checkout, use the absolute path to its `run-bachy` launcher; keep the checkout in place.

To open Bachy centered above the current tiled windows:

```lua
hl.window_rule({
    match = { class = "^(local\\.bachy\\.FileManager)$" },
    float = true,
    center = true,
    size = { "max(monitor_w, monitor_h)*0.50", "min(monitor_w, monitor_h)*0.55" },
})
```

The chooser has a separate ID: `local.bachy.FileManager.picker`. Configure its window independently if using the portal.

If an existing browser opens a file on another workspace without bringing it into view, Hyprland may be suppressing activation. To let requesting applications bring themselves forward:

```lua
hl.config({ misc = { focus_on_activate = true } })
```

This is a global activation preference, not a Bachy-only switch. Alternatively use `focus_on_activate = true` in a window rule for your chosen application's class. New applications and existing application windows may behave differently; the destination must request activation.

Reload with `hyprctl reload` and inspect `hyprctl configerrors`. Bachy does not edit these files itself.

For older Hyprland versions using hyprlang, the shortcut equivalent is:

```ini
bind = SUPER, E, exec, bachy --gui
```

Use the window-rule syntax documented for that installed version; do not paste Lua rules into an old `.conf` file. See the [official Hyprland documentation](https://wiki.hypr.land/Configuring/).

## GPU behavior

On Intel-driven displays, `run-bachy` and the packaged `bachy` launcher select Intel before the foreground Vulkan probe, then runs a bounded NVIDIA readiness check in the background after 500 ms. A subsequent window uses NVIDIA only when its session check succeeded and the GPU is awake. If it sleeps, the next window uses Intel again and retries the background check. This does not migrate an existing window between GPUs.

The policy respects explicit `QSG_RHI_BACKEND`, `VK_DRIVER_FILES`, `VK_ICD_FILENAMES` and PRIME selection variables. Mixed-vendor connected displays follow the original renderer-selection path. Readiness, cooldown and logs live under `$XDG_RUNTIME_DIR/bachy-gpu-<session>/`. The internal `--probe-vulkan` command tests enumeration, not every possible presentation scenario; actual rendering was separately checked on one Intel/RTX 5070 laptop.

Source revision 0.1.0-3 installs the shared launcher policy. The original v0.1.0 release asset predates it. The Rust implementation lives at `/usr/lib/bachy/bachy`; `/usr/bin/bachy` is the public launcher, and backend helpers use the implementation directly.

## Appearance and data

The default is a local light palette with the system monospace font (Noto Sans Mono on the development machine). Display settings support text-size overrides. `BACHY_FONT` and `BACHY_FONT_SIZE` set base typography; `BACHY_REDUCED_MOTION=1` disables interface animation.

Copy `packaging/colors.toml` to `${XDG_CONFIG_HOME:-$HOME/.config}/bachy/theme/colors.toml` to customize colours. Existing palette files reload when edited. The application can start without a configuration file. Configuration, state and cache use Bachy's XDG directories, separate from Flea. `BACHY_UI` and `BACHY_BIN` override the development UI/backend paths.

## Optional integrations

GVFS handles network/device access. Taildrop requires Tailscale running and permission to send. Dropbox actions require the corresponding service/CLI. Archive, media, image conversion and thumbnail support depend on their relevant tools. A command being available in the UI does not prove an endpoint or dependency is configured; see [FEATURES.md](../FEATURES.md) and [LIMITATIONS.md](../LIMITATIONS.md).
