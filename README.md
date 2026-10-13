# moddedEnd4

My current **end4 (illogical-impulse) + Hyprland** desktop setup.

This repo mirrors the relevant parts of `~/.config` so it can be dropped back in
place on a fresh machine.

## Contents

| Path | What it is |
| --- | --- |
| `quickshell/ii/` | Quickshell shell (end4 / illogical-impulse QML source, scripts, assets) |
| `hypr/` | Hyprland config (`hyprland.lua` + modules), Hyprlock, Hypridle and scripts |
| `illogical-impulse/config.json` | Saved shell settings (bar/widget layout, AI + other user prefs) |

## Restoring

Back up your existing config first, then:

```bash
cp -r quickshell/ii          ~/.config/quickshell/ii
cp -r hypr                   ~/.config/hypr
cp    illogical-impulse/config.json ~/.config/illogical-impulse/config.json
```

Then reload Hyprland / restart Quickshell.

## Notes

- Symlinks inside `quickshell/ii/assets/icons/` are relative and preserved as-is.
- No API keys or secrets are stored here; the shell reads those at runtime.
