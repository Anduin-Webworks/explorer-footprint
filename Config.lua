local _, ns = ...

ns.Config = {
    schemaVersion = 3,

    samplingInterval = 2.0,
    movementThreshold = 0.002,

    -- Each former 64 x 64 cell is split into a 4 x 4 block of smaller
    -- cells, giving the heatmap four times the resolution on each axis.
    gridWidth = 256,
    gridHeight = 256,
    maxCellCount = 1000000,

    renderRefreshInterval = 1.0,
    minVisibleIntensity = 0.0,
    minAlpha = 0.20,
    maxAlpha = 1.00,

    -- Absolute logarithmic intensity scale: 10, 100, 1,000, 10,000,
    -- and 100,000 samples align with the five configured color stops.
    intensityMinCount = 10,
    intensityMaxCount = 100000,

    colorStops = {
        { position = 0.00, color = { 0.65, 0.05, 1.00 } }, -- purple
        { position = 0.25, color = { 0.05, 0.30, 1.00 } }, -- blue
        { position = 0.50, color = { 0.05, 0.85, 0.20 } }, -- green
        { position = 0.75, color = { 1.00, 0.90, 0.05 } }, -- yellow
        { position = 1.00, color = { 1.00, 0.05, 0.02 } }, -- red
    },

    defaultShowOverlay = true,
    defaultOverlayOpacity = 55,
}
