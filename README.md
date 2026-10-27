# PhantomOS

Personal Arch Linux desktop configuration built around Hyprland. The goal is a reproducible setup with two desktop modes and a Tokyo Night / Dracula inspired visual identity.

## Desktop modes

### Work

- Hyprland dynamic tiling, initially using the `dwindle` layout.
- Multiple workspaces per monitor with keyboard navigation.
- Compact top panel on each connected display; show workspaces and system status, but no running-window task list.
- `Super+Enter` opens a terminal, which joins the current tiling layout.
- Strict window corners and a restrained animation profile.

### Relax

- Floating windows with familiar move, resize, maximize and focus behavior.
- Left-side panel on the left display and right-side panel on the right display; show that monitor's open windows.
- One workspace per monitor.
- Softer corners and gentler animations.

### Switching

- `Super+Tab` is the primary mode toggle.
- The same action will be exposed as a panel button and from the PhantomOS application menu.
- A single mode controller will update the compositor state, panel layout, workspace policy and visual profile together.

## Initial architecture

- **Hyprland (Lua):** compositor, window layout, monitor configuration, key bindings, and window rules.
- **Quickshell (QML):** PhantomOS panels, Windows-inspired application menu, mode toggle, and a small quick-settings surface.
- **Native Linux tools:** file picker, notifications, network/audio controls, lock and power actions. PhantomOS UI will launch and theme established system components where possible instead of rebuilding their backend behavior.
- **Dotfiles and installer:** package manifest, configuration templates, backup-aware install script, and optional app bundles such as `micro`, VS Code, and Python.

The installer should support both one-monitor and two-monitor systems, discover connected outputs at runtime, and keep hardware-specific settings out of the shared defaults. Monitor names, resolutions and refresh rates will be confirmed on the target Arch installation.

## First milestone

1. Confirm the Arch base and NVIDIA driver setup.
2. Bring up a minimal Hyprland session and verify both monitors, refresh rates, sleep/wake, screenshots and common applications.
3. Add mode switching and workspace behavior.
4. Build the two panel layouts and app menu.
5. Package the known-good configuration into a repeatable, backup-aware installer.

## Design notes

This repository configures a personal desktop on Arch; it is not a new Linux distribution or a replacement for KDE System Settings. PhantomOS will provide a consistent branded shell for frequent actions and leave deeper device configuration to the native applications. The UI should remain usable with one display and should degrade gracefully when optional tools are absent.
