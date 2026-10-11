local _, ns = ...

-- Create the mixin at file scope so the XML template is ready before the
-- provider acquires its first pin.
ExplorerFootprintMapPinMixin = CreateFromMixins(MapCanvasPinMixin)

function ExplorerFootprintMapPinMixin:OnLoad()
    self.Texture = self:CreateTexture(nil, "ARTWORK")
    self.Texture:SetAllPoints()
    self:EnableMouse(false)
end

function ExplorerFootprintMapPinMixin:OnAcquired(data)
    self.data = data

    self:UpdateSize()

    self.Texture:SetColorTexture(data.red, data.green, data.blue, data.alpha)
    self:SetPosition(data.x, data.y)
end

function ExplorerFootprintMapPinMixin:UpdateSize()
    local map = self:GetMap()
    if map and self.data then
        self:SetSize(
            math.max(1, map:DenormalizeHorizontalSize(self.data.width)),
            math.max(1, map:DenormalizeVerticalSize(self.data.height))
        )
    end
end

function ExplorerFootprintMapPinMixin:OnCanvasSizeChanged()
    self:UpdateSize()
end

function ExplorerFootprintMapPinMixin:OnCanvasScaleChanged()
    self:UpdateSize()
end

ns.HeatmapRenderer = {}

function ns.HeatmapRenderer:Refresh()
    if ns.MapProvider then
        ns.MapProvider:RequestRefresh(true)
    end
end
