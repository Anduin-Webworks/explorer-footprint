local _, ns = ...

ns.Database = {}

local LEGACY_GRID_WIDTH = 64
local LEGACY_GRID_HEIGHT = 64
local MIGRATION_CELL_COUNT = 4

local function isFiniteNumber(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function migrateGridResolution(db)
    if type(db.maps) ~= "table" then
        return
    end

    local oldMaps = db.maps
    local widthScale = ns.Config.gridWidth / LEGACY_GRID_WIDTH
    local heightScale = ns.Config.gridHeight / LEGACY_GRID_HEIGHT
    local migratedMaps = {}

    -- Keep the complete pre-migration table alive while the new table is built.
    -- This is intentionally a SavedVariables backup, not a runtime-only copy.
    db.backup_v2 = oldMaps

    for mapID, mapData in pairs(oldMaps) do
        if type(mapData) == "table" then
            local migratedMap = {
                sampleCount = 0,
                maxCount = 0,
                cells = {},
            }

            if type(mapData.cells) == "table" then
                local sampleCount, maxCount = 0, 0
                for cellIndex, rawCount in pairs(mapData.cells) do
                    local numericIndex = tonumber(cellIndex)
                    local count = math.floor(tonumber(rawCount) or 0)
                    if numericIndex and numericIndex == math.floor(numericIndex)
                        and numericIndex >= 0
                        and numericIndex < LEGACY_GRID_WIDTH * LEGACY_GRID_HEIGHT
                        and count > 0 then

                        local oldCellY = math.floor(numericIndex / LEGACY_GRID_WIDTH)
                        local oldCellX = numericIndex - (oldCellY * LEGACY_GRID_WIDTH)
                        local blockX = math.floor(oldCellX * widthScale)
                        local blockY = math.floor(oldCellY * heightScale)
                        local centerX = blockX + math.floor((widthScale - 2) / 2)
                        local centerY = blockY + math.floor((heightScale - 2) / 2)
                        local baseCount = math.floor(count / MIGRATION_CELL_COUNT)
                        local remainder = count - (baseCount * MIGRATION_CELL_COUNT)

                        -- Spread counts across the center 2 x 2 cells. The
                        -- remainder is distributed one at a time so the
                        -- aggregate count is preserved exactly, including for
                        -- counts below four.
                        for offset = 0, MIGRATION_CELL_COUNT - 1 do
                            local offsetX = offset % 2
                            local offsetY = math.floor(offset / 2)
                            local share = baseCount + (offset < remainder and 1 or 0)
                            if share > 0 then
                                local newCellX = math.min(
                                    ns.Config.gridWidth - 1,
                                    centerX + offsetX
                                )
                                local newCellY = math.min(
                                    ns.Config.gridHeight - 1,
                                    centerY + offsetY
                                )
                                local newCellIndex = newCellY * ns.Config.gridWidth + newCellX
                                migratedMap.cells[newCellIndex] = share
                                if share > maxCount then
                                    maxCount = share
                                end
                            end
                        end

                        sampleCount = sampleCount + count
                    end
                end

                migratedMap.sampleCount = sampleCount
                migratedMap.maxCount = maxCount
            end

            -- Preserve a larger valid aggregate from legacy data if the
            -- source table was internally inconsistent. normalizeMap() will
            -- continue to validate it after the migration.
            local oldSampleCount = tonumber(mapData.sampleCount)
            if isFiniteNumber(oldSampleCount) and oldSampleCount >= migratedMap.sampleCount then
                migratedMap.sampleCount = math.floor(oldSampleCount)
            end

            migratedMaps[mapID] = migratedMap
        end
    end

    db.maps = migratedMaps
end

local function normalizeMap(mapData)
    if type(mapData) ~= "table" then
        return nil
    end

    if type(mapData.cells) ~= "table" then
        mapData.cells = {}
    end

    -- Retain maxCount as a cheap diagnostic and rescale summary. It does not
    -- participate in the absolute color scale.
    if not isFiniteNumber(mapData.maxCount) or mapData.maxCount < 0 then
        mapData.maxCount = 0
    end

    local computedSamples, computedMax = 0, 0
    for cellIndex, count in pairs(mapData.cells) do
        count = tonumber(count)
        if count and count > 0 then
            count = math.floor(count)
            mapData.cells[cellIndex] = count
            computedSamples = computedSamples + count
            if count > computedMax then
                computedMax = count
            end
        else
            mapData.cells[cellIndex] = nil
        end
    end

    if not isFiniteNumber(mapData.sampleCount) or mapData.sampleCount < computedSamples then
        mapData.sampleCount = computedSamples
    end

    if mapData.maxCount < computedMax then
        mapData.maxCount = computedMax
    end

    return mapData
end

function ns.Database:Initialize()
    local db = ExplorerFootprintDB
    if type(db) ~= "table" then
        db = {}
    end

    local schemaVersion = tonumber(db.schemaVersion) or 0
    if schemaVersion < 1 then
        db.maps = type(db.maps) == "table" and db.maps or {}
        db.settings = type(db.settings) == "table" and db.settings or {}
        db.schemaVersion = 1
    end

    if schemaVersion < 2 then
        db.schemaVersion = 2
    end

    if schemaVersion < 3 then
        migrateGridResolution(db)
        db.schemaVersion = 3
    end

    db.maps = type(db.maps) == "table" and db.maps or {}
    db.settings = type(db.settings) == "table" and db.settings or {}

    if type(db.settings.showOverlay) ~= "boolean" then
        db.settings.showOverlay = ns.Config.defaultShowOverlay
    end

    if type(db.settings.overlayOpacity) ~= "number"
        or db.settings.overlayOpacity < 0
        or db.settings.overlayOpacity > 100 then
        db.settings.overlayOpacity = ns.Config.defaultOverlayOpacity
    end

    for mapID, mapData in pairs(db.maps) do
        if normalizeMap(mapData) == nil then
            db.maps[mapID] = nil
        end
    end

    db.schemaVersion = ns.Config.schemaVersion
    ns.DB = db
    ns.MapRevisions = {}
    ExplorerFootprintDB = db
end

function ns.Database:GetMap(mapID, create)
    if not ns.DB or not mapID then
        return nil
    end

    local mapData = ns.DB.maps[mapID]
    if not mapData and create then
        mapData = {
            sampleCount = 0,
            maxCount = 0,
            cells = {},
        }
        ns.DB.maps[mapID] = mapData
    end

    return mapData
end

function ns.Database:ResetMaps()
    ns.DB.maps = {}
    ns.DB.backup_v2 = nil
    ns.MapRevisions = {}
    if ns.MapProjection then
        ns.MapProjection:ClearDisplayCache()
    end
end

function ns.Database:GetTotals()
    local mapCount, cellCount, sampleCount = 0, 0, 0

    for _, mapData in pairs(ns.DB.maps) do
        if type(mapData) == "table" then
            mapCount = mapCount + 1
            sampleCount = sampleCount + (tonumber(mapData.sampleCount) or 0)
            if type(mapData.cells) == "table" then
                for _, count in pairs(mapData.cells) do
                    if tonumber(count) and count > 0 then
                        cellCount = cellCount + 1
                    end
                end
            end
        end
    end

    return mapCount, cellCount, sampleCount
end
