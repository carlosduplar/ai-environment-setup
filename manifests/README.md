# Manifests

Machine-readable inventories of every package this environment depends on.

| File | Package Manager | Command |
|------|----------------|---------|
| `npm-global.json` | npm | `npm install -g <package>` |
| `pip-packages.txt` | pip | `pip install <package>` |
| `winget.json` | winget | `winget import --import-file winget.json` |

## Updating manifests

When you install a new tool, add it to the appropriate manifest so the bootstrap scripts pick it up:

```powershell
# Snapshot current npm globals to see what's installed
npm list -g --depth=0

# Snapshot winget installed packages
winget export --output manifests/winget.json
```

## Important

The `winget.json` format follows the [winget import/export schema](https://aka.ms/winget-packages.schema.2.0.json).
You can export your current machine state with `winget export` and commit the result.
