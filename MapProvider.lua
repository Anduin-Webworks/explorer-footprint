local _, ns = ...

ns.MapProvider = CreateFromMixins(MapCanvasDataProviderMixin)

-- The template now represents one full-canvas heatmap layer rather than an
-- individual cell pin.
local PIN_TEMPLATE = "ExplorerFootprintHeatmapPinTemplate"

local function getOverlayOpacity()
    local value = ns.DB and ns.DB.settings and ns.DB.settings.overlayOpacity
        or ns.Config.defaultOverlayOpacity
    return math.max(0, math.min(100, tonumber(value) or ns.Config.defaultOverlayOpacity)) / 100
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
    self.layerPin = nil
    self.lastRenderState = nil
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
    -- Rebuild only our single layer pin for the newly selected map.
    self:RefreshAllData()
    self.dirty = false
    self.lastRefresh = GetTime()
end

function ns.MapProvider:RemoveAllData()
    local map = self:GetMap()
    if map then
        map:RemoveAllPinsByTemplate(PIN_TEMPLATE)
    end
    self.layerPin = nil
end

function ns.MapProvider:SetOverlayOpacity()
    if self.layerPin then
        self.layerPin:SetAlpha(getOverlayOpacity())
    end
end

function ns.MapProvider:RefreshAllData()
    local map = self:GetMap()
    if not map then
        self.lastRenderState = {
            reason = "no-map",
            cellCount = 0,
            runCount = 0,
            pin = false,
        }
        return
    end

    self:RemoveAllData()
    if not ns.DB or not ns.DB.settings.showOverlay then
        self.lastRenderState = {
            reason = "hidden",
            mapID = map:GetMapID(),
            cellCount = 0,
            runCount = 0,
            pin = false,
        }
        return
    end

    local mapID = map:GetMapID()
    local cells, _, displayCache = ns.MapProjection:BuildDisplayCells(mapID)
    local cellCount = 0
    for _ in pairs(cells) do
        cellCount = cellCount + 1
    end
    if not next(cells) then
        self.lastRenderState = {
            reason = "no-cells",
            mapID = mapID,
            cellCount = cellCount,
            runCount = 0,
            pin = false,
        }
        return
    end

    local runs = displayCache.runs
    local buildState = displayCache.buildState
    if not runs then
        runs = ns.HeatmapRenderer:BuildRuns(cells)
        displayCache.runs = runs
        buildState = ns.HeatmapRenderer.lastBuildState or {}
        displayCache.buildState = buildState
    end
    buildState = buildState or {}
    if #runs == 0 then
        self.lastRenderState = {
            reason = "no-runs",
            mapID = mapID,
            cellCount = cellCount,
            positiveCellCount = buildState.positiveCellCount or 0,
            bucketedCellCount = buildState.bucketedCellCount or 0,
            firstRawType = buildState.firstRawType or "none",
            firstRawValue = buildState.firstRawValue or "none",
            runCount = 0,
            pin = false,
        }
        return
    end

    self.layerPin = map:AcquirePin(PIN_TEMPLATE, {
        runs = runs,
        opacity = getOverlayOpacity(),
    })
    self.lastRenderState = {
        reason = "pin-acquired",
        mapID = mapID,
        cellCount = cellCount,
        positiveCellCount = buildState.positiveCellCount or 0,
        bucketedCellCount = buildState.bucketedCellCount or 0,
        firstRawType = buildState.firstRawType or "none",
        firstRawValue = buildState.firstRawValue or "none",
        runCount = #runs,
        pin = self.layerPin ~= nil,
    }
end
