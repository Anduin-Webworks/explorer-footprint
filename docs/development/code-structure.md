# Code structure

```text
.
├── ExplorerFootprint.toc
├── Core.lua
├── Config.lua
├── Localization.lua
├── Database.lua
├── Aggregator.lua
├── Sampler.lua
├── MapProjection.lua
├── MapProvider.lua
├── HeatmapRenderer.lua
├── Options.lua
├── Debug.lua
├── ExplorerFootprint.xml
├── README.md
├── CHANGELOG.md
├── docs/
└── LICENSE
```

## Load order

The TOC loads Lua modules in dependency order. `MapProvider.lua` creates the provider, `HeatmapRenderer.lua` creates the pin mixin, and `ExplorerFootprint.xml` is loaded last so its virtual frame can reference the mixin.

## Where to start

- Sampling bug: start with `Sampler.lua`, then inspect `Aggregator.lua`.
- Missing or corrupted data: inspect `Database.lua`.
- Wrong cell or color: inspect `MapProvider.lua` and `Config.lua`.
- Missing data on a parent or child map: inspect `MapProjection.lua` and the `C_Map` world-position APIs.
- Pins not appearing: inspect `MapProvider.lua`, `ExplorerFootprint.xml`, and the target Retail MapCanvas behavior.
- Setting not saved: inspect `Options.lua` and `Database.lua`.
- User-facing text: inspect `Localization.lua`.

## Namespace convention

Each Lua file receives the addon's private namespace through `local _, ns = ...`. Runtime modules are exposed as fields on `ns`; the only intentional global declarations are the SavedVariables table, slash-command registration, and the XML mixin name required by the UI loader.
