# ADR 0001: Use the World Map MapCanvas data-provider model

## Status

Accepted for version `0.1.0` and corrected in `0.1.1` after first in-game testing.

## Context

The addon needs to place many visual cells on Blizzard's World Map while responding to map changes, map visibility, resizing, panning, and zooming. Directly replacing Blizzard map frames would create a larger compatibility surface.

## Decision

Use `MapCanvasDataProviderMixin`, register one provider with `WorldMapFrame:AddDataProvider`, and create owned pins through `AcquirePin` with a dedicated virtual XML template.

## Consequences

Positive:

- Blizzard owns the map lifecycle and invokes provider refresh hooks.
- Pins use normalized coordinates and follow the map canvas.
- The addon can remove only its own pins by template.
- The architecture matches current live Blizzard UI source patterns.

Trade-offs:

- The XML template and mixin load order must remain correct.
- Pin sizing depends on the current canvas size and needs in-game verification across zoom levels.
- The implementation must track Retail MapCanvas changes.

## Verification

The current implementation is statically aligned with live MapCanvas provider and pin patterns. The first test found that `MapCanvasPinTemplate` is not an available inherited template in the target client, so the addon now defines a standalone frame template with the `MapCanvasPinMixin`-derived pin mixin. Exact visual alignment, frame layering, and taint behavior still require testing in the target Retail client.
