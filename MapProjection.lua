local _, ns = ...

ns.MapProjection = {
    mapInfoCache = {},
    displayCache = {},
}

local function isValidCoordinate(x, y)
    return type(x) == "number" and type(y) == "number"
        and x >= 0 and x <= 1 and y >= 0 and y <= 1
end

local function getXY(position)
    if not position then
        return nil
    end

    if position.GetXY then
        return position:GetXY()
    end

    return position.x, position.y
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
    return self:IsDescendant(firstMapID, secondMapID)
        or self:IsDescendant(secondMapID, firstMapID)
end

function ns.MapProjection:ConvertPosition(sourceMapID, x, y, targetMapID)
    if sourceMapID == targetMapID then
        return x, y
    end

    if not isValidCoordinate(x, y) then
        return nil
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

    local targetX, targetY = getXY(targetPosition)
    if not isValidCoordinate(targetX, targetY) then
        return nil
    end

    return targetX, targetY
end

function ns.MapProjection:BuildDisplayCells(targetMapID)
    if not targetMapID then
        return {}, 0
    end

    local revision = ns.DataRevision or 0
    local cached = self.displayCache[targetMapID]
    if cached and cached.revision == revision then
        return cached.cells, cached.maxCount
    end

    local cells = {}
    local maxCount = 0
    local width, height = ns.Config.gridWidth, ns.Config.gridHeight

    for sourceMapID, mapData in pairs(ns.DB.maps) do
        local numericSourceMapID = tonumber(sourceMapID)
        if numericSourceMapID and type(mapData) == "table"
            and type(mapData.cells) == "table"
            and self:AreRelated(numericSourceMapID, targetMapID) then

            for cellIndex, count in pairs(mapData.cells) do
                count = tonumber(count) or 0
                if count > 0 then
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
                        local targetCellX = math.min(width - 1, math.floor(targetX * width))
                        local targetCellY = math.min(height - 1, math.floor(targetY * height))
                        local targetCellIndex = targetCellY * width + targetCellX
                        local targetCell = cells[targetCellIndex]
                        if not targetCell then
                            targetCell = {
                                count = 0,
                                x = (targetCellX + 0.5) / width,
                                y = (targetCellY + 0.5) / height,
                            }
                            cells[targetCellIndex] = targetCell
                        end

                        targetCell.count = targetCell.count + count
                        if targetCell.count > maxCount then
                            maxCount = targetCell.count
                        end
                    end
                end
            end
        end
    end

    cached = {
        revision = revision,
        cells = cells,
        maxCount = maxCount,
    }
    self.displayCache[targetMapID] = cached
    return cells, maxCount
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
        local numericSourceMapID = tonumber(sourceMapID)
        if numericSourceMapID and type(mapData) == "table" then
            diagnostics.storedMapCount = diagnostics.storedMapCount + 1

            if type(mapData.cells) == "table"
                and self:AreRelated(numericSourceMapID, targetMapID) then
                local sourceStats = {
                    mapID = numericSourceMapID,
                    name = (self:GetMapInfo(numericSourceMapID) or {}).name or "unknown",
                    cellCount = 0,
                    projectedCount = 0,
                    failedCount = 0,
                }

                diagnostics.relatedMapCount = diagnostics.relatedMapCount + 1
                for cellIndex, count in pairs(mapData.cells) do
                    count = tonumber(count) or 0
                    if count > 0 then
                        sourceStats.cellCount = sourceStats.cellCount + 1
                        diagnostics.relatedCellCount = diagnostics.relatedCellCount + 1

                        local width, height = ns.Config.gridWidth, ns.Config.gridHeight
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
                            sourceStats.projectedCount = sourceStats.projectedCount + 1
                        else
                            sourceStats.failedCount = sourceStats.failedCount + 1
                        end
                    end
                end

                diagnostics.sourceMaps[#diagnostics.sourceMaps + 1] = sourceStats
            end
        end
    end

    local displayCells, maxCount = self:BuildDisplayCells(targetMapID)
    diagnostics.displayCellCount = countEntries(displayCells)
    diagnostics.maxCount = maxCount
    diagnostics.minX, diagnostics.maxX = 1, 0
    diagnostics.minY, diagnostics.maxY = 1, 0

    for _, cellData in pairs(displayCells) do
        diagnostics.minX = math.min(diagnostics.minX, cellData.x)
        diagnostics.maxX = math.max(diagnostics.maxX, cellData.x)
        diagnostics.minY = math.min(diagnostics.minY, cellData.y)
        diagnostics.maxY = math.max(diagnostics.maxY, cellData.y)
    end

    if diagnostics.displayCellCount == 0 then
        diagnostics.minX, diagnostics.maxX = nil, nil
        diagnostics.minY, diagnostics.maxY = nil, nil
    end

    return diagnostics
end
