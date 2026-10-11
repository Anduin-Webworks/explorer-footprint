# Changelog

All notable changes to Explorer's Footprint are documented here.

The project follows [Semantic Versioning](https://semver.org/).

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
