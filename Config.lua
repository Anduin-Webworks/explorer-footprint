local _, ns = ...

local viridisColorStops = {
    { position = 0.00, color = { 0.267, 0.005, 0.329 } }, -- dark purple
    { position = 0.25, color = { 0.230, 0.322, 0.546 } }, -- blue
    { position = 0.50, color = { 0.128, 0.567, 0.551 } }, -- teal
    { position = 0.75, color = { 0.369, 0.789, 0.383 } }, -- green
    { position = 1.00, color = { 0.993, 0.906, 0.144 } }, -- bright yellow
}

local rainbowColorStops = {
    { position = 0.00, color = { 0.65, 0.05, 1.00 } }, -- purple
    { position = 0.25, color = { 0.05, 0.30, 1.00 } }, -- blue
    { position = 0.50, color = { 0.05, 0.85, 0.20 } }, -- green
    { position = 0.75, color = { 1.00, 0.90, 0.05 } }, -- yellow
    { position = 1.00, color = { 1.00, 0.05, 0.02 } }, -- red
}

ns.Config = {
    schemaVersion = 3,

    samplingInterval = 1.0,
    maxSegmentCells = 40,

    gridWidth = 256,
    gridHeight = 256,
    maxCellCount = 65535,

    -- Persisted cells always use the full-resolution grid. The renderer may
    -- aggregate those cells for smaller map types so dense city maps remain
    -- readable without changing SavedVariables.
    renderGridByMapType = {
        default = 256,
        zone = 128,
        dungeon = 128,
        micro = 64,
    },

    renderRefreshInterval = 1.0,
    minAlpha = 0.45,
    maxAlpha = 1.00,

    -- Absolute logarithmic intensity scale: 1, 4, 16, 64, and 256
    -- samples align with the five configured color stops.
    intensityMinCount = 1,
    intensityMaxCount = 256,

    colorStopPresets = {
        viridis = viridisColorStops,
        rainbow = rainbowColorStops,
    },
    colorStops = viridisColorStops,

    defaultShowOverlay = true,
    defaultOverlayOpacity = 55,
}
