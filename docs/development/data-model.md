# Data model

## Persisted structure

`ExplorerFootprintDB` is declared as an account-wide SavedVariables table:

```lua
ExplorerFootprintDB = {
    schemaVersion = 3,
    settings = {
        showOverlay = true,
        overlayOpacity = 55,
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

`cellIndex` is a zero-based integer: `cellY * gridWidth + cellX`. The current grid is 256 × 256, configured in `Config.lua`. `maxCount` is retained as a per-map diagnostic and rescale summary; it does not normalize the absolute color scale.

## Lifecycle

1. WoW loads `ExplorerFootprintDB` before addon code.
2. `Database:Initialize()` creates missing tables, validates map records, applies defaults, and updates `schemaVersion`.
3. `Aggregator:Record()` records an endpoint, while `Aggregator:RecordSegment()` rasterizes consecutive same-map movement and advances only that source map's runtime display revision once per segment.
4. The database is written by WoW's normal SavedVariables lifecycle.
5. When a cell reaches the configured ceiling of `65,535`, counts for that map are halved and zero cells are removed.
6. `/footprint reset` replaces the maps table after confirmation.

Display caches are runtime-only. Each target-map cache tracks the revisions of the related source maps that contributed cells to it and stores `cells[cellIndex] = count`; coordinates are derived from the index when rendered. A normal sample recorded on the displayed source map updates its cached cell directly; map rescaling, cross-map changes, or a newly related source map cause the target cache to rebuild. The renderer quantizes counts into a 32-step lookup table and merges adjacent same-color cells into pooled texture runs on one full-canvas pin. Existing SavedVariables do not contain these revisions, caches, or runs.

The current sampling model counts rasterized crossed cells, not raw time-sample events. Same-cell samples are ignored, and segments longer than 40 cells on either axis record only their endpoint. Existing data remains loadable, but old time-sampled counts and new crossing-based counts should not be compared directly.

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

Schema version `3` migrates original 64 × 64 cell indexes into the current 256 × 256 grid. Each old count is distributed across the center 2 × 2 cells of its corresponding 4 × 4 block, with integer remainders assigned deterministically so aggregate counts are preserved. Before replacing `maps`, the migration stores the original table in `backup_v2`; `/footprint reset` clears both the active maps and that backup. The backup is intentionally temporary and should be retired by a later schema migration after the upgrade has had time to settle.
