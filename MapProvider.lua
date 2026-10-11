local _, ns = ...

ns.MapProvider = CreateFromMixins(MapCanvasDataProviderMixin)

local PIN_TEMPLATE = "ExplorerFootprintHeatmapPinTemplate"

function ns.MapProvider:OnAdded(mapCanvas)
    MapCanvasDataProviderMixin.OnAdded(self, mapCanvas)
    if mapCanvas.RegisterDataProviderOnUpdate then
        mapCanvas:RegisterDataProviderOnUpdate(self)
    end
end

function ns.MapProvider:OnRemoved(mapCanvas)
    if mapCanvas.UnregisterDataProviderOnUpdate then
        mapCanvas:UnregisterDataProviderOnUpdate(self)
    end
    MapCanvasDataProviderMixin.OnRemoved(self, mapCanvas)
end

function ns.MapProvider:Register()
    if self.registered then
        return true
    end

    if not WorldMapFrame or not WorldMapFrame.AddDataProvider then
        if C_Timer and C_Timer.After then
            C_Timer.After(1, function()
                self:Register()
            end)
        end
        return false
    end

    WorldMapFrame:AddDataProvider(self)
    self.registered = true
    return true
end

function ns.MapProvider:RequestRefresh(immediate)
    self.dirty = true
    if immediate and self:GetMap() then
        self:RefreshAllData()
        self.dirty = false
        self.lastRefresh = GetTime()
    end
end

function ns.MapProvider:OnUpdate()
    if not self.dirty or not self:GetMap() then
        return
    end

    local now = GetTime()
    if self.lastRefresh and now - self.lastRefresh < ns.Config.renderRefreshInterval then
        return
    end

    self:RefreshAllData()
    self.dirty = false
    self.lastRefresh = now
end

function ns.MapProvider:RefreshAllData()
    local map = self:GetMap()
    if not map then
        return
    end

    map:RemoveAllPinsByTemplate(PIN_TEMPLATE)
    if not ns.DB or not ns.DB.settings.showOverlay then
        return
    end

    local mapID = map:GetMapID()
    local mapData = ns.Database:GetMap(mapID, false)
    if not mapData or not mapData.cells then
        return
    end

    local maxCount = tonumber(mapData.maxCount) or 0
    if maxCount <= 0 then
        return
    end

    local width, height = ns.Config.gridWidth, ns.Config.gridHeight
    local logMax = math.log(1 + maxCount)

    for cellIndex, count in pairs(mapData.cells) do
        count = tonumber(count) or 0
        if count > 0 then
            local intensity = math.log(1 + count) / logMax
            if intensity >= ns.Config.minVisibleIntensity then
                local cellY = math.floor(cellIndex / width)
                local cellX = cellIndex - (cellY * width)
                local red = ns.Config.lowColor[1] + (ns.Config.highColor[1] - ns.Config.lowColor[1]) * intensity
                local green = ns.Config.lowColor[2] + (ns.Config.highColor[2] - ns.Config.lowColor[2]) * intensity
                local blue = ns.Config.lowColor[3] + (ns.Config.highColor[3] - ns.Config.lowColor[3]) * intensity
                local alpha = ns.Config.minAlpha + (ns.Config.maxAlpha - ns.Config.minAlpha) * intensity

                map:AcquirePin(PIN_TEMPLATE, {
                    x = (cellX + 0.5) / width,
                    y = (cellY + 0.5) / height,
                    width = 1 / width,
                    height = 1 / height,
                    red = red,
                    green = green,
                    blue = blue,
                    alpha = alpha,
                    count = count,
                })
            end
        end
    end
end
