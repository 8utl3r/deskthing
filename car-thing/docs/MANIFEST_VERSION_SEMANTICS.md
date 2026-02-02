# DeskThing Manifest Version Semantics

## Version Components (Don't Conflate!)

| Component | What it is | Example |
|-----------|------------|---------|
| **Our app version** | Deskthing Dashboard's own version | 0.4.9 |
| **DeskThing Server** | The host app (DeskThing Desktop) on Mac | 0.11.17 |
| **DeskThing Client** | The client on the Car Thing device (hosts our webapp) | 0.0.0* |
| **requiredVersions.server** | Min DeskThing SERVER version our app needs | ">=0.11.0" |
| **requiredVersions.client** | Min DeskThing CLIENT version our app needs | ">=0.0.0" |

\* Car Thing may report 0.0.0 if firmware doesn't expose client version.

## requiredVersions Semantics

- **requiredVersions.server**: "Our app requires DeskThing Server >= X"
  - Use `>=0.11.0` so 0.11.17 satisfies. Exact "0.11.0" fails (0.11.17 !== 0.11.0).
- **requiredVersions.client**: "Our app requires DeskThing Client >= X"
  - Car Thing reports 0.0.0. Use `>=0.0.0` to accept any client version.

## Deprecated Fields

- `compatible_server` / `compatible_client` (number[]): Deprecated in @deskthing/types.
- `version_code`: Deprecated but still used by DeskThing for updates.

## Correct Manifest Values

```json
"requiredVersions": { "server": ">=0.11.0", "client": ">=0.0.0" }
```
