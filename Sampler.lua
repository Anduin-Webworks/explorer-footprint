local _, ns = ...

ns.Sampler = {
    running = false,
    elapsed = 0,
    lastMapID = nil,
    lastX = nil,
    lastY = nil,
}

local function getXY(position)
    if not position then
        return nil
    end

    if position.GetXY then
        return position:GetXY()
    end

    return position.x, position.y
end

local function getPosition()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        return nil
    end

    local position = C_Map.GetPlayerMapPosition(mapID, "player")
    if not position then
        return nil
    end

    local x, y = getXY(position)
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

    local shouldRecord = self.lastMapID ~= mapID
    if not shouldRecord and self.lastX and self.lastY then
        local dx, dy = x - self.lastX, y - self.lastY
        shouldRecord = (dx * dx + dy * dy) >= (ns.Config.movementThreshold * ns.Config.movementThreshold)
    end

    self.lastMapID, self.lastX, self.lastY = mapID, x, y
    if shouldRecord then
        return ns.Aggregator:Record(mapID, x, y)
    end

    return false
end

function ns.Sampler:Start()
    if self.running then
        return
    end

    self.running = true
    self.frame = CreateFrame("Frame")
    self.frame:SetScript("OnUpdate", function(_, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed < ns.Config.samplingInterval then
            return
        end

        self.elapsed = 0
        self:Sample()
    end)
end

function ns.Sampler:Stop()
    if self.frame then
        self.frame:SetScript("OnUpdate", nil)
    end
    self.running = false
end
