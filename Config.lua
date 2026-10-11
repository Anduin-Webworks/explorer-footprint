local _, ns = ...

ns.Config = {
    schemaVersion = 1,

    samplingInterval = 2.0,
    movementThreshold = 0.002,

    gridWidth = 64,
    gridHeight = 64,
    maxCellCount = 1000000,

    renderRefreshInterval = 1.0,
    minVisibleIntensity = 0.05,
    minAlpha = 0.08,
    maxAlpha = 0.65,

    lowColor = { 0.10, 0.65, 1.00 },
    highColor = { 1.00, 0.20, 0.08 },

    defaultShowOverlay = true,
}
