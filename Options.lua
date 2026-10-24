local _, ns = ...

ns.Options = {}

function ns.Options:Initialize()
    if self.category then
        return
    end

    local category = Settings.RegisterVerticalLayoutCategory(ns.L.ADDON_TITLE)
    local variable = "ExplorerFootprint_ShowOverlay"
    local setting = Settings.RegisterAddOnSetting(
        category,
        variable,
        "showOverlay",
        ns.DB.settings,
        type(ns.Config.defaultShowOverlay),
        ns.L.SETTING_SHOW_OVERLAY,
        ns.Config.defaultShowOverlay
    )

    setting:SetValueChangedCallback(function(_, value)
        ns.DB.settings.showOverlay = value == true
        ns.MapProvider:RequestRefresh(true)
    end)

    local initializer = Settings.CreateCheckbox(category, setting, ns.L.SETTING_SHOW_OVERLAY_TOOLTIP)
    if initializer and initializer.AddSearchTags then
        initializer:AddSearchTags("map", "heatmap", "movement", "exploration")
    end

    local opacitySetting = Settings.RegisterAddOnSetting(
        category,
        "ExplorerFootprint_OverlayOpacity",
        "overlayOpacity",
        ns.DB.settings,
        type(ns.Config.defaultOverlayOpacity),
        ns.L.SETTING_OVERLAY_OPACITY,
        ns.Config.defaultOverlayOpacity
    )

    opacitySetting:SetValueChangedCallback(function(_, value)
        ns.DB.settings.overlayOpacity = math.max(
            0,
            math.min(100, tonumber(value) or ns.Config.defaultOverlayOpacity)
        )
        ns.MapProvider:RequestRefresh(true)
    end)

    local opacityOptions = Settings.CreateSliderOptions(0, 100, 5)
    if opacityOptions.SetLabelFormatter and MinimalSliderWithSteppersMixin then
        opacityOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
    end
    Settings.CreateSlider(
        category,
        opacitySetting,
        opacityOptions,
        ns.L.SETTING_OVERLAY_OPACITY_TOOLTIP
    )

    Settings.RegisterAddOnCategory(category)
    self.category = category
    self.setting = setting
    self.opacitySetting = opacitySetting
end

function ns.Options:Open()
    if self.category then
        Settings.OpenToCategory(self.category:GetID())
    end
end
