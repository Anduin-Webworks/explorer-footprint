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

local function addToCell(mapData, cellX, cellY, width)
    local cellIndex = cellY * width + cellX
    local count = (tonumber(mapData.cells[cellIndex]) or 0) + 1
    mapData.cells[cellIndex] = count
    mapData.sampleCount = (tonumber(mapData.sampleCount) or 0) + 1
    if count > (tonumber(mapData.maxCount) or 0) then
        mapData.maxCount = count
    end
    return cellIndex, count
end

local function commitMapUpdate(mapID, mapData, cellDeltas, needsRescale)
    if needsRescale then
        rescaleMap(mapData)
    end

    ns.MapRevisions = ns.MapRevisions or {}
    local revision = (ns.MapRevisions[mapID] or 0) + 1
    if not needsRescale and ns.MapProjection then
        ns.MapProjection:IncrementSourceCells(mapID, cellDeltas, revision)
    end
    ns.MapRevisions[mapID] = revision

    if ns.MapProvider then
        ns.MapProvider:RequestRefresh(false)
    end
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
    local mapData = ns.Database:GetMap(mapID, true)
    local cellIndex, count = addToCell(mapData, cellX, cellY, width)
    local cellDeltas = { [cellIndex] = 1 }
    commitMapUpdate(mapID, mapData, cellDeltas, count >= ns.Config.maxCellCount)

    return true, cellX, cellY
end

function ns.Aggregator:RecordSegment(mapID, x0, y0, x1, y1)
    if type(mapID) ~= "number"
        or type(x0) ~= "number"
        or type(y0) ~= "number"
        or type(x1) ~= "number"
        or type(y1) ~= "number" then
        return false
    end

    if x0 < 0 or x0 > 1 or y0 < 0 or y0 > 1
        or x1 < 0 or x1 > 1 or y1 < 0 or y1 > 1 then
        return false
    end

    local width, height = ns.Config.gridWidth, ns.Config.gridHeight
    local cx0 = clamp(math.floor(x0 * width), 0, width - 1)
    local cy0 = clamp(math.floor(y0 * height), 0, height - 1)
    local cx1 = clamp(math.floor(x1 * width), 0, width - 1)
    local cy1 = clamp(math.floor(y1 * height), 0, height - 1)

    if cx0 == cx1 and cy0 == cy1 then
        return false
    end

    local dx = math.abs(cx1 - cx0)
    local stepY = -math.abs(cy1 - cy0)
    if dx > ns.Config.maxSegmentCells or -stepY > ns.Config.maxSegmentCells then
        return self:Record(mapID, x1, y1)
    end

    local sx = cx0 < cx1 and 1 or -1
    local sy = cy0 < cy1 and 1 or -1
    local err = dx + stepY
    local mapData = ns.Database:GetMap(mapID, true)
    local cellDeltas = {}
    local needsRescale = false

    while true do
        local cellIndex, count = addToCell(mapData, cx0, cy0, width)
        cellDeltas[cellIndex] = (cellDeltas[cellIndex] or 0) + 1
        if count >= ns.Config.maxCellCount then
            needsRescale = true
        end

        if cx0 == cx1 and cy0 == cy1 then
            break
        end

        local twiceError = 2 * err
        if twiceError >= stepY then
            err = err + stepY
            cx0 = cx0 + sx
        end
        if twiceError <= dx then
            err = err + dx
            cy0 = cy0 + sy
        end
    end

    commitMapUpdate(mapID, mapData, cellDeltas, needsRescale)
    return true, cx1, cy1
end

function ns.Aggregator:RescaleMap(mapID)
    local mapData = ns.Database:GetMap(mapID, false)
    if mapData then
        rescaleMap(mapData)
        ns.MapRevisions = ns.MapRevisions or {}
        ns.MapRevisions[mapID] = ((ns.MapRevisions[mapID] or 0) + 1)
        if ns.MapProvider then
            ns.MapProvider:RequestRefresh(false)
        end
    end
end
