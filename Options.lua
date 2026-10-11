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

    Settings.RegisterAddOnCategory(category)
    self.category = category
    self.setting = setting
end

function ns.Options:Open()
    if self.category then
        Settings.OpenToCategory(self.category:GetID())
    end
end
