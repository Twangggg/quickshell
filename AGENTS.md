# Quickshell Desktop Panel

A Hyprland desktop panel built with Quickshell (QtQuick/QML).

## Project Type

NOT a traditional codebase - this is a desktop UI configuration. No build system, tests, or linters.

## Architecture

- **Framework**: Quickshell (QtQuick-based Wayland shell)
- **UI**: QML files (Main.qml, TopBar.qml, Lock.qml, etc.)
- **Backend**: Bash scripts in `watchers/` and subdirectories
- **Data flow**: QML calls `Quickshell.execDetached()` → shell scripts → write to `/tmp/` → QML reads

## Key Files

| Path | Purpose |
|------|---------|
| `Main.qml` | Main panel window, widget orchestration |
| `TopBar.qml` | Top bar UI (~88KB, most complex) |
| `Lock.qml` | Lockscreen |
| `ScreenshotOverlay.qml` | Screenshot UI |
| `watchers/*.sh` | Background data providers (battery, audio, network) |
| `workspaces.sh` | Workspace state via Hyprland IPC |
| `qs_colors.json` | Runtime colors (generated from template) |

## Color System

- Template: `colors.json.template` (matugen syntax)
- Generated: `qs_colors.json`
- To regenerate: run `matugen` or check `wallpaper/matugen_reload.sh`

## Important Patterns

- **Hyprland IPC**: `workspaces.sh` listens on `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock`
- **Zombie prevention**: `workspaces.sh` kills old instances on reload (lines 7-12)
- **Event debouncing**: Batch rapid events in 50ms window to prevent CPU spam
- **Widget toggle**: Uses `/tmp/qs_current_widget` file for state

## Development

No standard commands. Edit QML or shell files directly. Reload via:
- Quickshell IPC: `qs -p ~/.config/hypr/scripts/quickshell/TopBar.qml ipc call topbar forceReload`
- Or: modify files in `~/.config/hypr/scripts/quickshell/` and restart Quickshell

## Environment Variables

- `WALLPAPER_DIR` - wallpaper directory (default: `~/Pictures/Wallpapers`)
- `QS_SCREENSHOT_EDIT`, `QS_DESK_VOL`, `QS_MIC_VOL`, etc. - runtime state
