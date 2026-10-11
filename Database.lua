local _, ns = ...

ns.Database = {}

local function isFiniteNumber(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function normalizeMap(mapData)
    if type(mapData) ~= "table" then
        return nil
    end

    if type(mapData.cells) ~= "table" then
        mapData.cells = {}
    end

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

    db.maps = type(db.maps) == "table" and db.maps or {}
    db.settings = type(db.settings) == "table" and db.settings or {}

    if type(db.settings.showOverlay) ~= "boolean" then
        db.settings.showOverlay = ns.Config.defaultShowOverlay
    end

    for mapID, mapData in pairs(db.maps) do
        if normalizeMap(mapData) == nil then
            db.maps[mapID] = nil
        end
    end

    db.schemaVersion = ns.Config.schemaVersion
    ns.DB = db
    ns.DataRevision = 0
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

    return normalizeMap(mapData)
end

function ns.Database:ResetMaps()
    ns.DB.maps = {}
    ns.DataRevision = (ns.DataRevision or 0) + 1
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
