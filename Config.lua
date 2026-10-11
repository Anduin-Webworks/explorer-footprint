local _, ns = ...

ns.Config = {
    schemaVersion = 1,

    samplingInterval = 2.0,
    movementThreshold = 0.002,

    gridWidth = 64,
    gridHeight = 64,
    maxCellCount = 1000000,

    renderRefreshInterval = 1.0,
    minVisibleIntensity = 0.0,
    minAlpha = 0.20,
    maxAlpha = 0.65,

    colorStops = {
        { position = 0.00, color = { 0.65, 0.05, 1.00 } }, -- purple
        { position = 0.25, color = { 0.05, 0.30, 1.00 } }, -- blue
        { position = 0.50, color = { 0.05, 0.85, 0.20 } }, -- green
        { position = 0.75, color = { 1.00, 0.90, 0.05 } }, -- yellow
        { position = 1.00, color = { 1.00, 0.05, 0.02 } }, -- red
    },

    defaultShowOverlay = true,
}
