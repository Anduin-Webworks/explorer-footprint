# Heatmap concept

Explorer's Footprint turns movement into a density visualization. It samples the player's normalized map position, assigns the sample to a cell in a fixed grid, and increments that cell's count.

It does not store a route. Two visits to the same cell increase its density; the original timestamps and exact path are not retained.

## Data flow

```mermaid
flowchart LR
    A[Retail map APIs] --> B[Sampler]
    B --> C[Coordinate validation]
    C --> D[Sparse cell aggregator]
    D --> E[Account-wide SavedVariables]
    E --> F[MapCanvas data provider]
    F --> G[World Map heatmap pins]
```

## Intensity

Cells use a logarithmic intensity scale. This keeps a highly traveled cell from making every lower-count cell invisible. The renderer interpolates from a cool low-density color to a warm high-density color and caps alpha using centralized configuration.

## Boundaries

The Retail API can return no map or no position, especially in restricted content. The sampler skips those intervals. The addon does not attempt to infer positions from another API or force a map transition.
