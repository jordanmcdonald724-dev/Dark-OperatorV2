# Dark Operator — Quickshell Alpha

This is the first actual Dark Operator shell identity build.

It deliberately starts sparse:
- floating top Operator island
- five graphical Stations
- compact bottom-center floating application dock
- Dark Operator graphite/cyan visual language
- no permanent NET/VOL/BAT telemetry wall
- no fake hacker visuals
- 150 ms restrained hover/selection motion

## Install

```bash
chmod +x install.sh rollback.sh
./install.sh
```

The installer keeps the old Waybar/nwg configuration on disk. It only stops their running services after installing the Quickshell config. If Quickshell fails to stay active, the installer starts the old shell services again and prints the Quickshell log.

## Roll back

```bash
./rollback.sh
```

## Scope

This Alpha establishes shell identity and geometry. System flyouts, notifications, dynamic running-app state, auto-hide/fullscreen behavior, AI presence, and deeper shell functions are intentionally not populated yet.
