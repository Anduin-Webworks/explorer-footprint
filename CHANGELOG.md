# Changelog

All notable changes to Explorer's Footprint are documented here.

The project follows [Semantic Versioning](https://semver.org/).

## [0.2.3] - 2026-10-10

### Changed

- Replaced the map-relative intensity scale with an absolute logarithmic scale.
- Set purple, blue, green, yellow, and red anchors at 10, 100, 1,000, 10,000, and 100,000 samples.

## [0.2.2] - 2026-10-10

### Fixed

- Assigned heatmap pins to Blizzard's registered area-POI frame level so zone-map detail layers do not hide parts of the overlay.

## [0.2.1] - 2026-10-10

### Added

- Added `/footprint debug map` diagnostics for current map IDs, parent relationships, projection success/failure counts, and rendered coordinate bounds.

## [0.2.0] - 2026-10-10

### Added

- Render source-map samples on related parent and child World Map views.
- Convert source cell positions through world coordinates when building a target-map overlay.
- Aggregate projected source cells that land in the same target cell.
- Prefer storing new samples under a resolvable child zone when the position API returns a broad parent map.

### Changed

- Keep source-map data unchanged and derive hierarchical overlays at render time.

## [0.1.1] - 2026-10-10

### Fixed

- Removed the invalid `MapCanvasPinTemplate` inheritance that caused the World Map pin warning.
- Refresh heatmap pins when Blizzard changes the selected World Map ID.
- Refresh the provider when it is registered while the World Map is already open.

### Changed

- Replaced the blue-to-red scale with a purple-to-blue-to-green-to-yellow-to-red gradient.
- Treat the first recorded visit as 0% intensity and the most visited cell on that map as 100%.
- Keep positive first-visit cells visible instead of filtering them by intensity.

## [0.1.0] - 2026-10-10

### Added

- Initial Retail-only addon structure.
- Account-wide sparse map-cell database with schema versioning.
- Throttled outdoor player-position sampling.
- World Map heatmap using Blizzard's MapCanvas data-provider and pin APIs.
- Retail Settings checkbox for toggling the overlay.
- English localization table prepared for additional locales.
- Slash commands for settings, status, and confirmed data reset.
- User and developer documentation.
