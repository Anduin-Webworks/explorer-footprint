# Getting started

## Installation

1. Copy the addon directory into `World of Warcraft/_retail_/Interface/AddOns/ExplorerFootprint/`.
2. Start Retail and enable **Explorer's Footprint** in the AddOns list.
3. Log into a character and travel outdoors for a few minutes.
4. Open the World Map and view the map where you traveled.

The installed directory should be packaged as `ExplorerFootprint` and contain `ExplorerFootprint.toc`.

## Settings

Open **Game Menu → Options → AddOns → Explorer's Footprint** and use **Show heatmap overlay** to control rendering.

Each sample represents a crossed map cell from movement. Dark purple indicates fewer accumulated crossings, while bright yellow indicates more. The opacity slider changes visibility without changing the stored counts. Hiding the visualization does not erase or interrupt the account-wide footprint.

## Slash commands

```text
/footprint          Open settings
/ef                Open settings
/footprint help     Show available commands
/footprint toggle   Toggle the heatmap
/footprint status   Print map, cell, and sample totals
/footprint debug map  Print map diagnostics
/footprint reset    Ask for confirmation, then clear all map data
```

Reset is destructive and cannot be undone by the addon. It does not reset the display checkbox.

## What to expect

- The heatmap is sparse and appears only for maps with recorded cells.
- Stationary time is not repeatedly counted; same-map movement is rasterized across crossed cells.
- On the first launch after this grid upgrade, existing footprints are migrated to the 256 × 256 grid while preserving their aggregate counts.
- Instances and other areas where the position API returns no usable value are skipped.
- Data is saved locally in the account SavedVariables file and is not transmitted.
