# Reference

## Settings

| Setting | Type | Default | Storage | Effect |
| --- | --- | --- | --- | --- |
| Show heatmap overlay | Boolean | `true` | `ExplorerFootprintDB.settings.showOverlay` | Shows or hides owned World Map heatmap pins. |

Sampling and renderer values are currently developer configuration in `Config.lua`, not registered user settings.

## Slash commands

| Command | Effect |
| --- | --- |
| `/footprint` | Opens the addon Settings page. |
| `/ef` | Alias for `/footprint`. |
| `/footprint status` | Prints map, non-zero-cell, and aggregate sample totals. |
| `/footprint reset` | Opens a confirmation dialog, then clears all map data. |

## Retail API boundary

The implementation uses:

- `C_Map.GetBestMapForUnit("player")` to identify the current map.
- `C_Map.GetPlayerMapPosition(mapID, "player")` to obtain normalized coordinates.
- `MapCanvasDataProviderMixin` and `WorldMapFrame:AddDataProvider` for map integration.
- `MapCanvasPinMixin` and `AcquirePin` for heatmap cells.
- `Settings.RegisterVerticalLayoutCategory`, `Settings.RegisterAddOnSetting`, and `Settings.CreateCheckbox` for the settings page.

The map-position API may return `nil` in restricted content. The addon treats that as a skipped sample. API behavior, template names, and the TOC interface number must be checked against the target Retail build before release.

## Files that define public behavior

- Addon metadata and load order: [`ExplorerFootprint.toc`](../../ExplorerFootprint.toc)
- User-facing quick start: [`README.md`](../../README.md)
- Version history: [`CHANGELOG.md`](../../CHANGELOG.md)
- Runtime defaults: [`Config.lua`](../../Config.lua)
- Persisted data: [`Database.lua`](../../Database.lua)
