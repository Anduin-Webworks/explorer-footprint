local _, ns = ...

ns.MapProjection = {
    mapInfoCache = {},
    relatedCache = {},
    transforms = {},
    displayCache = {},
}

local IDENTITY_TRANSFORM = { 0, 1, 0, 0, 0, 1 }
local TRANSFORM_TOLERANCE = 0.0001

local function isValidCoordinate(x, y)
    return type(x) == "number" and type(y) == "number"
        and x >= 0 and x <= 1 and y >= 0 and y <= 1
end

function ns.MapProjection:GetMapInfo(mapID)
    if not mapID then
        return nil
    end

    if self.mapInfoCache[mapID] == nil then
        self.mapInfoCache[mapID] = C_Map.GetMapInfo(mapID) or false
    end

    local info = self.mapInfoCache[mapID]
    return info ~= false and info or nil
end

function ns.MapProjection:IsDescendant(mapID, ancestorMapID)
    if mapID == ancestorMapID then
        return true
    end

    local visited = {}
    local currentMapID = mapID
    while currentMapID and currentMapID ~= 0 and not visited[currentMapID] do
        visited[currentMapID] = true
        local info = self:GetMapInfo(currentMapID)
        if not info then
            return false
        end

        currentMapID = info.parentMapID
        if currentMapID == ancestorMapID then
            return true
        end
    end

    return false
end

function ns.MapProjection:AreRelated(firstMapID, secondMapID)
    if not firstMapID or not secondMapID then
        return false
    end

    local firstCache = self.relatedCache[firstMapID]
    if not firstCache then
        firstCache = {}
        self.relatedCache[firstMapID] = firstCache
    end

    if firstCache[secondMapID] ~= nil then
        return firstCache[secondMapID]
    end

    local related = self:IsDescendant(firstMapID, secondMapID)
        or self:IsDescendant(secondMapID, firstMapID)
    firstCache[secondMapID] = related

    local secondCache = self.relatedCache[secondMapID]
    if not secondCache then
        secondCache = {}
        self.relatedCache[secondMapID] = secondCache
    end
    secondCache[firstMapID] = related

    return related
end

function ns.MapProjection:ConvertRaw(sourceMapID, x, y, targetMapID)
    if sourceMapID == targetMapID then
        return x, y
    end

    local continentID, worldPosition = C_Map.GetWorldPosFromMapPos(sourceMapID, { x = x, y = y })
    if not continentID or not worldPosition then
        return nil
    end

    local resolvedMapID, targetPosition = C_Map.GetMapPosFromWorldPos(
        continentID,
        worldPosition,
        targetMapID
    )
    if not targetPosition then
        return nil
    end

    if resolvedMapID and resolvedMapID ~= targetMapID then
        return nil
    end

    return ns.Utils.GetXY(targetPosition)
end

local function approximatelyEqual(first, second)
    return math.abs(first - second) <= TRANSFORM_TOLERANCE
end

local function buildTransform(
    firstX,
    firstY,
    secondX,
    secondY,
    thirdX,
    thirdY,
    firstSourceX,
    firstSourceY,
    secondSourceX,
    thirdSourceY
)
    local sourceXRange = secondSourceX - firstSourceX
    local sourceYRange = thirdSourceY - firstSourceY
    local scaleX = (secondX - firstX) / sourceXRange
    local scaleY = (thirdX - firstX) / sourceYRange
    local offsetX = firstX - (scaleX * firstSourceX) - (scaleY * firstSourceY)
    local scaleXForY = (secondY - firstY) / sourceXRange
    local scaleYForY = (thirdY - firstY) / sourceYRange
    local offsetY = firstY - (scaleXForY * firstSourceX) - (scaleYForY * firstSourceY)

    return {
        offsetX,
        scaleX,
        scaleY,
        offsetY,
        scaleXForY,
        scaleYForY,
    }
end

local function applyTransform(transform, x, y)
    return
        transform[1] + transform[2] * x + transform[3] * y,
        transform[4] + transform[5] * x + transform[6] * y
end

function ns.MapProjection:GetTransform(sourceMapID, targetMapID)
    if sourceMapID == targetMapID then
        return IDENTITY_TRANSFORM
    end

    local sourceCache = self.transforms[sourceMapID]
    if not sourceCache then
        sourceCache = {}
        self.transforms[sourceMapID] = sourceCache
    end

    local cached = sourceCache[targetMapID]
    if cached ~= nil then
        return cached or nil
    end

    local probeSets = {
        {
            firstX = 0,
            firstY = 0,
            secondX = 1,
            secondY = 0,
            thirdX = 0,
            thirdY = 1,
            extraX = 0.5,
            extraY = 0.5,
        },
        {
            firstX = 0.25,
            firstY = 0.25,
            secondX = 0.75,
            secondY = 0.25,
            thirdX = 0.25,
            thirdY = 0.75,
            extraX = 0.75,
            extraY = 0.75,
        },
    }

    for _, probes in ipairs(probeSets) do
        local firstX, firstY = self:ConvertRaw(
            sourceMapID,
            probes.firstX,
            probes.firstY,
            targetMapID
        )
        local secondX, secondY = self:ConvertRaw(
            sourceMapID,
            probes.secondX,
            probes.secondY,
            targetMapID
        )
        local thirdX, thirdY = self:ConvertRaw(
            sourceMapID,
            probes.thirdX,
            probes.thirdY,
            targetMapID
        )

        if firstX and firstY and secondX and secondY and thirdX and thirdY then
            local transform = buildTransform(
                firstX,
                firstY,
                secondX,
                secondY,
                thirdX,
                thirdY,
                probes.firstX,
                probes.firstY,
                probes.secondX,
                probes.thirdY
            )
            local actualX, actualY = self:ConvertRaw(
                sourceMapID,
                probes.extraX,
                probes.extraY,
                targetMapID
            )
            local expectedX, expectedY = applyTransform(
                transform,
                probes.extraX,
                probes.extraY
            )

            if actualX and actualY
                and approximatelyEqual(actualX, expectedX)
                and approximatelyEqual(actualY, expectedY) then
                sourceCache[targetMapID] = transform
                return transform
            end
        end
    end

    sourceCache[targetMapID] = false
    return nil
end

function ns.MapProjection:ConvertPosition(sourceMapID, x, y, targetMapID)
    if sourceMapID == targetMapID then
        return x, y
    end

    if not isValidCoordinate(x, y) then
        return nil
    end

    local transform = self:GetTransform(sourceMapID, targetMapID)
    if transform then
        local targetX, targetY = applyTransform(transform, x, y)
        if isValidCoordinate(targetX, targetY) then
            return targetX, targetY
        end
    end

    local targetX, targetY = self:ConvertRaw(sourceMapID, x, y, targetMapID)
    if not isValidCoordinate(targetX, targetY) then
        return nil
    end

    return targetX, targetY
end

local function getMapRevision(mapID)
    return (ns.MapRevisions and ns.MapRevisions[mapID]) or 0
end

local function getUIMapType(name, fallback)
    return Enum and Enum.UIMapType and Enum.UIMapType[name] or fallback
end

function ns.MapProjection:GetRenderGrid(targetMapID)
    local info = self:GetMapInfo(targetMapID)
    local mapType = info and info.mapType
    local renderGrid = ns.Config.renderGridByMapType
    local size = renderGrid.default

    if mapType == getUIMapType("Micro", 5) then
        size = renderGrid.micro
    elseif mapType == getUIMapType("Zone", 3) then
        size = renderGrid.zone
    elseif mapType == getUIMapType("Dungeon", 4) then
        size = renderGrid.dungeon
    end

    return size, size
end

function ns.MapProjection:IsDisplayCacheCurrent(targetMapID, cached)
    if not cached or type(cached.sourceRevisions) ~= "table"
        or not ns.DB or type(ns.DB.maps) ~= "table" then
        return false
    end

    local currentSources = {}
    for sourceMapID, mapData in pairs(ns.DB.maps) do
        local numericSourceMapID = tonumber(sourceMapID)
        if numericSourceMapID and type(mapData) == "table"
            and self:AreRelated(numericSourceMapID, targetMapID) then
            currentSources[numericSourceMapID] = true
            if cached.sourceRevisions[numericSourceMapID] ~= getMapRevision(numericSourceMapID) then
                return false
            end
        end
    end

    for sourceMapID in pairs(cached.sourceRevisions) do
        if not currentSources[sourceMapID] then
            return false
        end
    end

    return true
end

function ns.MapProjection:IncrementSourceCells(sourceMapID, cellDeltas, revision)
    local cached = self.displayCache[sourceMapID]
    if not cached or not self:IsDisplayCacheCurrent(sourceMapID, cached) then
        return false
    end

    local sourceStats = cached.sourceStats and cached.sourceStats[sourceMapID]
    local sourceMapData = ns.DB and ns.DB.maps and (
        ns.DB.maps[sourceMapID] or ns.DB.maps[tostring(sourceMapID)]
    )
    for cellIndex, delta in pairs(cellDeltas) do
        local count = (tonumber(cached.cells[cellIndex]) or 0) + delta
        cached.cells[cellIndex] = count
        if count > cached.maxCount then
            cached.maxCount = count
        end

        if sourceStats and sourceMapData and sourceMapData.cells
            and tonumber(sourceMapData.cells[cellIndex]) == delta then
            sourceStats.cellCount = sourceStats.cellCount + 1
            sourceStats.projectedCount = sourceStats.projectedCount + 1
        end
    end
    cached.runs = nil
    cached.buildState = nil
    cached.renderCells = nil
    cached.renderMaxCount = nil
    cached.renderGridWidth = nil
    cached.renderGridHeight = nil
    cached.renderRuns = nil
    cached.renderBuildState = nil
    cached.sourceRevisions[sourceMapID] = revision
    return true
end

function ns.MapProjection:IncrementSourceCell(sourceMapID, cellIndex, delta, revision)
    return self:IncrementSourceCells(sourceMapID, { [cellIndex] = delta }, revision)
end

function ns.MapProjection:ClearDisplayCache()
    self.displayCache = {}
end

function ns.MapProjection:BuildDisplayCells(targetMapID)
    if not targetMapID then
        return {}, 0
    end

    local cached = self.displayCache[targetMapID]
    if cached and self:IsDisplayCacheCurrent(targetMapID, cached) then
        return cached.cells, cached.maxCount, cached
    end

    local cells = {}
    local maxCount = 0
    local width, height = ns.Config.gridWidth, ns.Config.gridHeight
    local sourceRevisions = {}
    local sourceStats = {}

    for sourceMapID, mapData in pairs(ns.DB.maps) do
        local numericSourceMapID = tonumber(sourceMapID)
        if numericSourceMapID and type(mapData) == "table"
            and type(mapData.cells) == "table"
            and self:AreRelated(numericSourceMapID, targetMapID) then
            sourceRevisions[numericSourceMapID] = getMapRevision(numericSourceMapID)
            local stats = {
                mapID = numericSourceMapID,
                name = (self:GetMapInfo(numericSourceMapID) or {}).name or "unknown",
                cellCount = 0,
                projectedCount = 0,
                failedCount = 0,
            }
            sourceStats[numericSourceMapID] = stats

            for cellIndex, count in pairs(mapData.cells) do
                count = tonumber(count) or 0
                if count > 0 then
                    stats.cellCount = stats.cellCount + 1
                    local cellY = math.floor(cellIndex / width)
                    local cellX = cellIndex - (cellY * width)
                    local sourceX = (cellX + 0.5) / width
                    local sourceY = (cellY + 0.5) / height
                    local targetX, targetY = self:ConvertPosition(
                        numericSourceMapID,
                        sourceX,
                        sourceY,
                        targetMapID
                    )

                    if targetX and targetY then
                        stats.projectedCount = stats.projectedCount + 1
                        local targetCellX = math.min(width - 1, math.floor(targetX * width))
                        local targetCellY = math.min(height - 1, math.floor(targetY * height))
                        local targetCellIndex = targetCellY * width + targetCellX
                        local targetCount = (tonumber(cells[targetCellIndex]) or 0) + count
                        cells[targetCellIndex] = targetCount
                        if targetCount > maxCount then
                            maxCount = targetCount
                        end
                    else
                        stats.failedCount = stats.failedCount + 1
                    end
                end
            end
        end
    end

    cached = {
        sourceRevisions = sourceRevisions,
        cells = cells,
        maxCount = maxCount,
        sourceStats = sourceStats,
        runs = nil,
    }
    self.displayCache[targetMapID] = cached
    return cells, maxCount, cached
end

function ns.MapProjection:BuildRenderCells(targetMapID)
    local cells, _, cached = self:BuildDisplayCells(targetMapID)
    local width, height = self:GetRenderGrid(targetMapID)

    if cached.renderCells
        and cached.renderGridWidth == width
        and cached.renderGridHeight == height then
        return cached.renderCells, cached.renderMaxCount, cached, width, height
    end

    if width == ns.Config.gridWidth and height == ns.Config.gridHeight then
        cached.renderCells = cells
        cached.renderMaxCount = cached.maxCount
    else
        local renderCells = {}
        local renderMaxCount = 0

        for cellIndex, count in pairs(cells) do
            local sourceY = math.floor(cellIndex / ns.Config.gridWidth)
            local sourceX = cellIndex - (sourceY * ns.Config.gridWidth)
            local renderX = math.min(
                width - 1,
                math.floor(sourceX * width / ns.Config.gridWidth)
            )
            local renderY = math.min(
                height - 1,
                math.floor(sourceY * height / ns.Config.gridHeight)
            )
            local renderIndex = renderY * width + renderX
            local renderCount = (tonumber(renderCells[renderIndex]) or 0) + count
            renderCells[renderIndex] = renderCount
            if renderCount > renderMaxCount then
                renderMaxCount = renderCount
            end
        end

        cached.renderCells = renderCells
        cached.renderMaxCount = renderMaxCount
    end

    cached.renderGridWidth = width
    cached.renderGridHeight = height
    cached.renderRuns = nil
    cached.renderBuildState = nil
    return cached.renderCells, cached.renderMaxCount, cached, width, height
end

local function countEntries(values)
    local count = 0
    for _ in pairs(values) do
        count = count + 1
    end
    return count
end

function ns.MapProjection:GetDisplayDiagnostics(targetMapID)
    local diagnostics = {
        storedMapCount = 0,
        relatedMapCount = 0,
        relatedCellCount = 0,
        sourceMaps = {},
    }

    if not targetMapID or not ns.DB or type(ns.DB.maps) ~= "table" then
        return diagnostics
    end

    for sourceMapID, mapData in pairs(ns.DB.maps) do
        if tonumber(sourceMapID) and type(mapData) == "table" then
            diagnostics.storedMapCount = diagnostics.storedMapCount + 1
        end
    end

    local displayCells, maxCount, cached, width, height = self:BuildRenderCells(targetMapID)
    for _, sourceStats in pairs(cached.sourceStats or {}) do
        diagnostics.relatedMapCount = diagnostics.relatedMapCount + 1
        diagnostics.relatedCellCount = diagnostics.relatedCellCount + sourceStats.cellCount
        diagnostics.sourceMaps[#diagnostics.sourceMaps + 1] = sourceStats
    end

    diagnostics.displayCellCount = countEntries(displayCells)
    diagnostics.maxCount = maxCount
    diagnostics.minX, diagnostics.maxX = 1, 0
    diagnostics.minY, diagnostics.maxY = 1, 0

    for cellIndex in pairs(displayCells) do
        local cellY = math.floor(cellIndex / width)
        local cellX = cellIndex - (cellY * width)
        local cellCenterX = (cellX + 0.5) / width
        local cellCenterY = (cellY + 0.5) / height
        diagnostics.minX = math.min(diagnostics.minX, cellCenterX)
        diagnostics.maxX = math.max(diagnostics.maxX, cellCenterX)
        diagnostics.minY = math.min(diagnostics.minY, cellCenterY)
        diagnostics.maxY = math.max(diagnostics.maxY, cellCenterY)
    end

    if diagnostics.displayCellCount == 0 then
        diagnostics.minX, diagnostics.maxX = nil, nil
        diagnostics.minY, diagnostics.maxY = nil, nil
    end

    return diagnostics
end
