# Getting started

## Installation

1. Copy the addon directory into `World of Warcraft/_retail_/Interface/AddOns/ExplorerFootprint/`.
2. Start Retail and enable **Explorer's Footprint** in the AddOns list.
3. Log into a character and travel outdoors for a few minutes.
4. Open the World Map and view the map where you traveled.

The installed directory should be packaged as `ExplorerFootprint` and contain `ExplorerFootprint.toc`.

## Settings

Open **Game Menu → Options → AddOns → Explorer's Footprint** and use **Show heatmap overlay** to control rendering.

This setting controls the map overlay. The initial implementation continues to collect movement data while the overlay is hidden so that hiding the visualization does not erase or interrupt the account-wide footprint.

## Slash commands

```text
/footprint          Open settings
/ef                Open settings
/footprint status   Print map, cell, and sample totals
/footprint reset    Ask for confirmation, then clear all map data
```

Reset is destructive and cannot be undone by the addon. It does not reset the display checkbox.

## What to expect

- The heatmap is sparse and appears only for maps with recorded cells.
- Stationary time is not repeatedly counted; samples are recorded on movement or map change.
- Instances and other areas where the position API returns no usable value are skipped.
- Data is saved locally in the account SavedVariables file and is not transmitted.
