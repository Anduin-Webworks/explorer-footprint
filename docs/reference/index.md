# Reference

## Settings

| Setting | Type | Default | Storage | Effect |
| --- | --- | --- | --- | --- |
| Show heatmap overlay | Boolean | `true` | `ExplorerFootprintDB.settings.showOverlay` | Shows or hides the owned World Map heatmap layer. |
| Heatmap opacity | Number (0–100) | `55` | `ExplorerFootprintDB.settings.overlayOpacity` | Controls the strength of the rectangle-cell overlay over the World Map. |

Sampling and renderer values are currently developer configuration in `Config.lua`, not registered user settings. The current grid is 256 × 256, sampling runs every 1 second, the maximum segment distance is 40 cells per axis, the current absolute logarithmic anchors are 1, 4, 16, 64, and 256 samples, the minimum heatmap alpha is 0.45, and the per-cell rescale ceiling is 65,535. The per-map `maxCount` summary is retained for diagnostics and rescaling, but does not affect color normalization. The default color preset is viridis-style; the former rainbow stops remain available under `Config.colorStopPresets.rainbow`. Existing 64 × 64 data is migrated once at schema version 3, with the original maps retained temporarily in `ExplorerFootprintDB.backup_v2`.

## Slash commands

| Command | Effect |
| --- | --- |
| `/footprint` | Opens the addon Settings page. |
| `/ef` | Alias for `/footprint`. |
| `/footprint help` | Prints the available slash commands. |
| `/footprint toggle` | Toggles the heatmap display. |
| `/footprint status` | Prints map, non-zero-cell, and aggregate sample totals. |
| `/footprint debug map` | Refreshes the provider, then prints current map IDs, parent chain, source-map projection results, renderer state, and rendered coordinate bounds. The renderer should report numeric raw display-cell data and one or more texture runs when cells are present. |
| `/footprint reset` | Opens a confirmation dialog, then clears all map data. |

## Retail API boundary

The implementation uses:

- `C_Map.GetBestMapForUnit("player")` to identify the current map.
- `C_Map.GetPlayerMapPosition(mapID, "player")` to obtain normalized coordinates.
- `C_Map.GetMapInfoAtPosition` to prefer a resolvable child zone when sampling from a broad map.
- `C_Map.GetWorldPosFromMapPos` and `C_Map.GetMapPosFromWorldPos` to project source cells into a selected related map.
- `C_Map.GetMapInfo` to follow parent-map relationships.
- `MapCanvasDataProviderMixin` and `WorldMapFrame:AddDataProvider` for map integration.
- `MapCanvasPinMixin`, `AcquirePin`, and `CreateTexturePool` for the full-canvas heatmap layer.
- `Settings.RegisterVerticalLayoutCategory`, `Settings.RegisterAddOnSetting`, and `Settings.CreateCheckbox` for the settings page.

The map-position API may return `nil` in restricted content. The addon treats that as a skipped sample. API behavior, template names, and the TOC interface number must be checked against the target Retail build before release.

## Files that define public behavior

- Addon metadata and load order: [`ExplorerFootprint.toc`](../../ExplorerFootprint.toc)
- User-facing quick start: [`README.md`](../../README.md)
- Version history: [`CHANGELOG.md`](../../CHANGELOG.md)
- Runtime defaults: [`Config.lua`](../../Config.lua)
- Persisted data: [`Database.lua`](../../Database.lua)
