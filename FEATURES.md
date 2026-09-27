# Current functionality

This describes Bachy 0.1.0. “Implemented” means code exists; it does not imply every device, format and integration has been validated. The [verification report](docs/BACHY-VERIFICATION.md) distinguishes tested flows from stubs and unverified hardware.

| Area | Implemented | Requirements / boundaries |
|---|---|---|
| Browsing | List, grid, Miller columns, dual panes, tabs, history, path bar, sort, hidden toggle, directory favourites | Up to nine tabs; local filesystem paths are the primary model |
| Input | Keyboard presets, shortcut sheet, mouse selection, ranges, select-all, drag-and-drop paths | Default, Vim, Mac and Windows presets; cross-application drag behavior still needs broader testing |
| Search | Recursive fuzzy name/path search; current-list filtering | No content index, advanced date/type query or saved searches |
| File operations | Copy, move, rename, duplicate, new file/folder, Trash, restore, permanent delete, collision handling | See metadata, clipboard and folder-merge limitations before important transfers |
| Operation feedback | Progress, cancel, undo and redo for supported operations | One active operation per backend; no persistent queue or pause/resume |
| Opening | System-default application via GIO, Open With, copy path, external terminal action | MIME handlers must be installed; terminal needs xdg-terminal-exec |
| Preview | Quick Look, preview column, supported image/text/PDF/media/archive views, directory size | PDF preview needs optional `qt6-webengine`; playback needs optional `qt6-multimedia`. Missing support offers external opening. Other format coverage depends on Qt and installed tools |
| Images and archives | Image conversion; archive creation/extraction and archive-entry previews | ImageMagick, libarchive or 7zip depending on the action/format |
| Properties | Basic file information and permission-mode editing | Single local object; no bulk/recursive permission editor |
| Devices | Discovery, mount, unmount and eject; phone integration paths | GVFS and its relevant backends; physical hardware not comprehensively tested |
| Network | GIO/GVFS mount flows and saved network locations for supported protocols | SMB/SFTP/FTPS/WebDAV/NFS depend on installed backends and authentication support |
| Sharing | Optional Tailscale Taildrop, Dropbox and LocalSend actions | External services/CLIs and accounts required; no real peer transfer claimed as tested |
| Scripts | User executable scripts receive selected paths | Not compatible with Thunarx, Nautilus or KDE extension APIs |
| Desktop | Desktop entry/icon, folder MIME routing, FileManager1 service, file-chooser portal implementation | Portal and service installation/activation are separate from browsing |
| Appearance | Local light palette, adjustable text size/density, reduced-motion support, configurable colours | No Omarchy shell required; no automatic desktop-wide theme synchronization |
| Terminal interface | Rust TUI via --tui: navigation, selection, operations, external-editor bulk rename, previews/PDF/media and Taildrop | External editor/PDF/media/provider tools required for those features; GUI and TUI capabilities differ |
| Startup | Small boot QML, lazy components, viewport-scoped row work, shared source/package hybrid-GPU policy | GPU policy measured on one Intel/NVIDIA laptop only |

## Optional previews on main (package revision 0.1.0-3)

`qt6-webengine` (PDF) and `qt6-multimedia` (audio/video) are optional. The UI uses the installed monospace face without requiring `noto-fonts`. Both the preview column and Quick Look remain usable without it, with installation guidance and an Open externally action. Installing it enables the existing PDF viewer after restarting Bachy. The published v0.1.0 download still has the original mandatory dependency.

## Copy metadata on main (after 0.1.0)

Source builds now preserve modification time and `user.*` extended attributes on regular files and directories, including duplicate and cross-filesystem move. Access time is the value observed when each item opens; a background size scan can advance directory access time first. Modes still follow source permissions filtered by umask, with special bits stripped. Metadata errors report failure and keep a partial copy available for recovery; failed cross-filesystem moves retain their source. ACLs, ownership and symlink metadata are excluded. The published **v0.1.0 package does not contain this change**. [First code lesson and verification](docs/lessons/01-copy-metadata.md).

## Retained command-line helpers

The inherited `bachy shelf` commands still support path references, pins/order, transfer/archive helpers and saved piles. Removing the Omarchy bar installation did not remove this CLI. Its presence does not imply a working installed shelf bar.

## Desktop opening behavior

Bachy asks GIO to use the file type's default application. If it is not running, GIO launches it; if it reuses an existing window on another workspace, the compositor decides whether to follow activation. The Hyprland setup guide includes an opt-in setting to focus that destination. HTML and PDF are not hard-coded to a particular browser.

## What was removed from the Flea integration

Omarchy shared QML imports were replaced with local components. The Omarchy shelf/bar installation path and distribution updater are removed or disabled, and Bachy never writes compositor bindings automatically. State, cache, configuration, binary and desktop IDs use Bachy's own names. Historical upstream documentation can still mention Omarchy.
