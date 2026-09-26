# Known limitations

Bachy 0.1.0 is experimental. This is a source audit and targeted comparison with Thunar 4.20, Nautilus 50 and Dolphin 26.08, not an exhaustive certification of every extension. **The highest-priority gaps are cross-window file clipboard support, metadata-preserving copy, and recursive folder merge.** Keep another file manager available for workflows Bachy cannot yet handle reliably.

## Missing or reduced capabilities

| Area | Bachy gap or limitation |
|---|---|
| System file clipboard | Cut/copy stores file selections inside one window. It shares between that window's panes, but not separate Bachy windows or Thunar/Nautilus/Dolphin. Copy-path text and drag-and-drop are separate features and do work through different mechanisms. |
| Copy fidelity | The published v0.1.0 package loses modification time and user extended attributes. Post-0.1.0 main preserves modification time and `user.*` attributes on regular files/directories, subject to destination filesystem support. Access time is captured at item open, possibly after a background size scan. Source mode is still filtered by umask (e.g. 0664 → 0644); special bits, ownership, ACLs, security/system attributes and symlink metadata are excluded. See the [metadata lesson](docs/lessons/01-copy-metadata.md). |
| Folder collisions | No recursive folder merge. The choices are skip, keep both, replace or cancel. Replacement puts the old object in Trash rather than merging directory contents. |
| Batch rename | Single-item rename only; no bulk preview, numbering, template naming, find/replace, case conversion or date/metadata renaming. |
| Multi-item commands | Dedicated Duplicate and Properties actions require one selected item. Ordinary multi-file copy is supported. |
| Templates | No creation from documents in the user's Templates directory; only blank files and folders. |
| Link creation | Existing symlinks are handled, but there is no Create Link/Paste Link or link-drag workflow. |
| Selection | No select-by-wildcard or invert-selection command. Range selection, select-all and fuzzy filtering exist. |
| Search | Recursive fuzzy filename/path search, without indexed file contents, date/type/size query filters or saved searches. |
| Recent files | No main-browser Recent location. Recent entries exist in the separate file chooser implementation. |
| Stars and annotations | Directory favourites exist; no Nautilus starred files, Thunar emblems/per-file highlighting, or Dolphin tags, ratings and comments. |
| Properties | Basic single-item information; no combined multi-item properties, editable extended metadata pages, or full access/creation-time, image EXIF and media-codec property pages. Previews do expose some image/media metadata and directory size. |
| Permissions | Basic mode editing on one owned local object. No recursive/bulk permission application, group/owner editor, ACL editor or special-bit controls. |
| Transfers | One active operation per backend; additional operations are refused rather than queued. No pause/resume or copy-verification option like Thunar's checksum setting. Progress, cancellation, undo and redo exist. |
| Tabs | Hard limit of nine. No full tab-session restoration, detachable/reorderable tabs or reopen-closed-tab command. Last folder and split-pane paths are remembered. |
| Views | No Thunar compact-list mode or folder-tree sidebar, and no expandable folder rows as in Nautilus/Dolphin. Bachy's Miller columns and dual panes are different existing navigation modes. |
| Columns and captions | A limited fixed set/order of list columns and captions; no broad metadata-column selection and rearrangement matching Thunar/Dolphin. |
| Per-folder preferences | No persistent view/zoom/sort configuration keyed to each folder; global settings and live-tab state exist. |
| Controls and shortcuts | No customizable toolbar or graphical per-action shortcut editor. Four keymap presets exist; deeper changes require source configuration. |
| Extensions and actions | No Thunarx, Nautilus-extension or KDE service-menu/plugin compatibility; no equivalent custom-action editor with filename/type/selection conditions. Executable user scripts receiving selected paths are supported. |
| Virtual filesystems | Network support works through mounted local/FUSE paths, rather than general GIO/KIO virtual-location browsing. No administrative `admin://` browsing or built-in online-account setup. |
| Desktop reveal integration | FileManager1 accepts local file URIs, does not implement ShowItemProperties, and selects only the first requested item per folder when several are passed. |
| Bookmark migration | Local favourites are Bachy's own; existing local GTK/KDE bookmarks are not automatically imported. Network GTK bookmarks are shared separately. |
| Archives | Create/extract and entry previews exist; no archive-as-folder browsing/editing, selective extraction interface, or password/compression-level interface. Dolphin's KIO archive browsing is a relevant difference. |
| Devices | No ISO-mount workflow, disk-format controls, LUKS-unlock interface or configurable removable-media automation. Basic mount/unmount/eject exists; some comparison capabilities require optional components. |
| Terminal | External-terminal action only, without Dolphin's embedded terminal panel. The external action requires the `xdg-terminal-exec` helper. |
| Hidden names | Dotfiles can be toggled; backup names ending in `~` are not treated as hidden as they are in Thunar. Per-directory `.hidden` lists are not interpreted. |
| Filename fidelity | Non-UTF-8 names are converted lossily; their display and subsequent operations cannot be relied on to preserve the original byte name. |
| Language and desktop theme | UI strings are English without translation catalogs. The port uses its own local palette rather than automatically following GNOME/KDE appearance changes. |

## Dependencies and unverified behavior

The system must provide the MIME handlers, GVFS protocol/device backends, authentication helpers, archive tools and preview codecs required by each action. A working local browser does not prove those integrations are configured. The source runtime bundle used during development is not distributed here.

Accessibility roles exist, but AT-SPI/Orca parity is unverified. Real remote/device workflows, all thumbnail formats, cross-application drag-and-drop and complete portal integration still need broader coverage. The inherited full integration runner is not green. Native GUI startup and selected opening/routing flows have been checked on one CachyOS/Hyprland laptop.

The source launcher's Intel/NVIDIA policy is not yet shared by the packaged binary. The abstract fugue emblem is integrated into the README, packaged vector icon and in-app marks.

## Comparison references

- [Thunar operations](https://docs.xfce.org/xfce/thunar/working-with-files-and-folders), [preferences](https://docs.xfce.org/xfce/thunar/preferences), [bulk rename](https://docs.xfce.org/xfce/thunar/bulk-renamer/start).
- [Nautilus search](https://help.gnome.org/gnome-help/files-search.html), [properties](https://help.gnome.org/gnome-help/nautilus-file-properties-basic.html), [permissions](https://help.gnome.org/gnome-help/nautilus-file-properties-permissions.html).
- [Dolphin panels](https://docs.kde.org/stable_kf6/en/dolphin/dolphin/panels.html), [views](https://docs.kde.org/stable_kf6/en/dolphin/dolphin/dolphin-view.html).

See [FEATURES.md](FEATURES.md) for implemented functionality and [ROADMAP.md](ROADMAP.md) for planned work.
