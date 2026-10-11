# Explorer's Footprint

Explorer's Footprint is a World of Warcraft Retail addon that records outdoor player movement as sparse map-cell counts and displays the result as an account-wide heatmap on the World Map.

## Status

Version `0.2.3` adds an absolute logarithmic intensity scale from 10 to 100,000 samples. It also includes the zone-map rendering fix from `0.2.2` and map-projection diagnostics from `0.2.1`. It is usable as a development build, but in-game validation against the target Retail client is still required before a public release.

## Features

- Account-wide SavedVariables shared by all characters.
- Throttled outdoor position sampling using Retail map APIs.
- Sparse 64 × 64 cell aggregation per map.
- Heatmap rendering through Blizzard's World Map data-provider system.
- A minimal Retail Settings checkbox to show or hide the overlay.
- English strings organized for future localization.
- No third-party dependencies and no data transmission.

## Installation

Copy the addon directory into:

```text
World of Warcraft/_retail_/Interface/AddOns/ExplorerFootprint/
```

The directory must contain `ExplorerFootprint.toc` and the Lua/XML files listed by it. The current repository folder is named `explorer-footprint`; packaging may rename the installed folder to `ExplorerFootprint`.

## Use

Open **Game Menu → Options → AddOns → Explorer's Footprint** and enable or disable **Show heatmap overlay**. The overlay appears when the World Map is open and the selected map contains recorded data.

The slash commands are:

```text
/footprint       Open the settings page
/footprint status   Print database and sampler status
/footprint debug map   Print current map and projection diagnostics
/footprint reset    Ask for confirmation before clearing all map data
```

## Development

Read the [documentation index](docs/index.md) before changing the addon. The most useful starting points are:

- [Architecture](docs/development/architecture.md)
- [Code structure](docs/development/code-structure.md)
- [Data model](docs/development/data-model.md)
- [Getting started](docs/development/getting-started.md)
- [Reference](docs/reference/index.md)

## Compatibility

The addon targets World of Warcraft Retail only. The interface numbers in `ExplorerFootprint.toc` must be updated when the supported Retail client build changes. APIs related to map positions can return `nil` in restricted content; the addon skips those samples rather than forcing a value.

## License

See [LICENSE](LICENSE).
