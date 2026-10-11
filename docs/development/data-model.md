# Data model

## Persisted structure

`ExplorerFootprintDB` is declared as an account-wide SavedVariables table:

```lua
ExplorerFootprintDB = {
    schemaVersion = 1,
    settings = {
        showOverlay = true,
    },
    maps = {
        [uiMapID] = {
            sampleCount = 0,
            maxCount = 0,
            cells = {
                [cellIndex] = count,
            },
        },
    },
}
```

`cellIndex` is a zero-based integer: `cellY * gridWidth + cellX`. The current grid is 64 × 64, configured in `Config.lua`.

## Lifecycle

1. WoW loads `ExplorerFootprintDB` before addon code.
2. `Database:Initialize()` creates missing tables, validates map records, applies defaults, and updates `schemaVersion`.
3. `Aggregator:Record()` increments a map's cell and summary counters.
4. The database is written by WoW's normal SavedVariables lifecycle.
5. When a cell reaches the configured ceiling, counts for that map are halved and zero cells are removed.
6. `/footprint reset` replaces the maps table after confirmation.

## Hierarchical rendering

Samples remain stored under the most specific map the sampler can resolve. If `GetBestMapForUnit` returns a broad parent and `GetMapInfoAtPosition` identifies a child zone, the sample is converted and stored under that child. The renderer does not persist duplicate parent-map or child-map records. When a map is displayed, related source maps are projected into the selected map using Retail world-coordinate conversion APIs and aggregated into temporary display cells.

This means a sample recorded in a zone can appear on its continent map, and an existing sample recorded on a continent can appear on a related zone map when the conversion API can resolve the position. Parent-to-child projection uses the center of each stored grid cell, so older broad-map data is best-effort at the configured grid resolution; new samples prefer a resolvable child zone. Projection failures are skipped without changing the stored source data.

## Data intentionally not stored

- Raw coordinates.
- Per-sample timestamps.
- Frame objects or rendered colors.
- Character-specific ownership.
- Network or external-service data.

## Migration policy

Migrations are monotonic and must preserve existing data whenever possible. A future schema change belongs in `Database.lua`, with a new changelog entry and a focused migration test or in-game verification case.

The current repository contains only schema version `1`; later migrations are **Not applicable yet**.
