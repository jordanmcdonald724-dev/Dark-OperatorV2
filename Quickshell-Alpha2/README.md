# Dark Operator — Quickshell Alpha 2

This is a NEW generation. It does not patch or overwrite Quickshell Alpha 1.

Changes:
- separate config name: `dark-operator-alpha2`
- separate service: `dark-operator-quickshell-alpha2.service`
- explicit `ExclusionMode.Ignore`
- explicit Wayland `WlrLayer.Top`
- no exclusive zone
- shell remains above normal windows
- true fullscreen windows should cover the shell
- Alpha 1 remains on disk and can be restored

Install from the laptop after this folder has been uploaded to the repo:

```bash
cd /home/jordan/Dark-OperatorV2
git fetch origin
git reset --hard origin/main
cd Quickshell-Alpha2
chmod +x install.sh rollback.sh
./install.sh
```

Rollback:

```bash
./rollback.sh
```
