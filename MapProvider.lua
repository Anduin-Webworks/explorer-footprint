local _, ns = ...

ns.MapProvider = CreateFromMixins(MapCanvasDataProviderMixin)

local PIN_TEMPLATE = "ExplorerFootprintHeatmapPinTemplate"

local function getIntensity(count)
    local minimumCount = ns.Config.intensityMinCount
    local maximumCount = ns.Config.intensityMaxCount
    if count <= minimumCount then
        return 0
    elseif count >= maximumCount then
        return 1
    end

    local minimumLog = math.log(minimumCount)
    local maximumLog = math.log(maximumCount)
    local logRange = maximumLog - minimumLog
    if logRange <= 0 then
        return 0
    end

    return (math.log(count) - minimumLog) / logRange
end

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
    if WorldMapFrame:IsShown() then
        self:RefreshAllData()
    end
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

function ns.MapProvider:OnMapChanged()
    -- SetMapID signals OnMapChanged but does not guarantee a provider refresh.
    -- Rebuild only our pins for the newly selected map.
    self:RefreshAllData()
    self.dirty = false
    self.lastRefresh = GetTime()
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
    local cells = ns.MapProjection:BuildDisplayCells(mapID)
    if not next(cells) then
        return
    end

    local width, height = ns.Config.gridWidth, ns.Config.gridHeight

    local function getColor(intensity)
        local stops = ns.Config.colorStops
        for index = 1, #stops - 1 do
            local first, second = stops[index], stops[index + 1]
            if intensity <= second.position then
                local range = second.position - first.position
                local localIntensity = range > 0 and (intensity - first.position) / range or 0
                return
                    first.color[1] + (second.color[1] - first.color[1]) * localIntensity,
                    first.color[2] + (second.color[2] - first.color[2]) * localIntensity,
                    first.color[3] + (second.color[3] - first.color[3]) * localIntensity
            end
        end

        local last = stops[#stops].color
        return last[1], last[2], last[3]
    end

    for _, cellData in pairs(cells) do
        local count = cellData.count
        if count > 0 then
            -- Use an absolute logarithmic scale so a cell's color represents
            -- its accumulated sample count rather than the current map's
            -- most visited cell.
            local intensity = getIntensity(count)
            if intensity >= ns.Config.minVisibleIntensity then
                local red, green, blue = getColor(intensity)
                local alpha = ns.Config.minAlpha + (ns.Config.maxAlpha - ns.Config.minAlpha) * intensity

                map:AcquirePin(PIN_TEMPLATE, {
                    x = cellData.x,
                    y = cellData.y,
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
