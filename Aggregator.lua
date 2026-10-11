local _, ns = ...

ns.Aggregator = {}

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    elseif value > maximum then
        return maximum
    end
    return value
end

local function rescaleMap(mapData)
    local sampleCount, maxCount = 0, 0

    for cellIndex, count in pairs(mapData.cells) do
        local scaled = math.floor((tonumber(count) or 0) / 2)
        if scaled > 0 then
            mapData.cells[cellIndex] = scaled
            sampleCount = sampleCount + scaled
            if scaled > maxCount then
                maxCount = scaled
            end
        else
            mapData.cells[cellIndex] = nil
        end
    end

    mapData.sampleCount = sampleCount
    mapData.maxCount = maxCount
end

function ns.Aggregator:Record(mapID, x, y)
    if type(mapID) ~= "number" or type(x) ~= "number" or type(y) ~= "number" then
        return false
    end

    if x < 0 or x > 1 or y < 0 or y > 1 then
        return false
    end

    local width, height = ns.Config.gridWidth, ns.Config.gridHeight
    local cellX = clamp(math.floor(x * width), 0, width - 1)
    local cellY = clamp(math.floor(y * height), 0, height - 1)
    local cellIndex = cellY * width + cellX
    local mapData = ns.Database:GetMap(mapID, true)
    local count = (tonumber(mapData.cells[cellIndex]) or 0) + 1

    mapData.cells[cellIndex] = count
    mapData.sampleCount = (tonumber(mapData.sampleCount) or 0) + 1
    if count > (tonumber(mapData.maxCount) or 0) then
        mapData.maxCount = count
    end

    if count >= ns.Config.maxCellCount then
        rescaleMap(mapData)
    end

    ns.DataRevision = (ns.DataRevision or 0) + 1

    if ns.MapProvider then
        ns.MapProvider:RequestRefresh(false)
    end

    return true, cellX, cellY
end

function ns.Aggregator:RescaleMap(mapID)
    local mapData = ns.Database:GetMap(mapID, false)
    if mapData then
        rescaleMap(mapData)
    end
end
