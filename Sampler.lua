local _, ns = ...

ns.Sampler = {
    running = false,
    ticker = nil,
    lastMapID = nil,
    lastX = nil,
    lastY = nil,
}

local function getPosition()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        return nil
    end

    local position = C_Map.GetPlayerMapPosition(mapID, "player")
    if not position then
        return nil
    end

    local x, y = ns.Utils.GetXY(position)
    if type(x) ~= "number" or type(y) ~= "number" then
        return nil
    end

    return mapID, x, y
end

function ns.Sampler:Sample()
    local mapID, x, y = getPosition()
    if not mapID then
        self.lastMapID, self.lastX, self.lastY = nil, nil, nil
        return false
    end

    -- Some Retail contexts return a broad parent map from
    -- GetBestMapForUnit. Prefer a child zone when the map API can resolve
    -- the current position inside one.
    local childInfo = C_Map.GetMapInfoAtPosition(mapID, x, y)
    if childInfo and childInfo.mapID and childInfo.mapID ~= mapID
        and ns.MapProjection:IsDescendant(childInfo.mapID, mapID) then
        local childX, childY = ns.MapProjection:ConvertPosition(mapID, x, y, childInfo.mapID)
        if childX and childY then
            mapID, x, y = childInfo.mapID, childX, childY
        end
    end

    local recorded
    if self.lastMapID == mapID and self.lastX ~= nil and self.lastY ~= nil then
        recorded = ns.Aggregator:RecordSegment(mapID, self.lastX, self.lastY, x, y)
    else
        recorded = ns.Aggregator:Record(mapID, x, y)
    end
    self.lastMapID, self.lastX, self.lastY = mapID, x, y
    return recorded or false
end

function ns.Sampler:Start()
    if self.running then
        return
    end

    self.running = true
    self.ticker = C_Timer.NewTicker(ns.Config.samplingInterval, function()
        if self.running then
            self:Sample()
        end
    end)
end

function ns.Sampler:Stop()
    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end
    self.running = false
end
