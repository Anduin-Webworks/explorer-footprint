local addonName, ns = ...

ns.ADDON_NAME = addonName
ns.DISPLAY_NAME = "Explorer's Footprint"
ns.VERSION = "0.1.1"
ns.initialized = false

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        ns:Initialize()
    end
end)

function ns:Initialize()
    if self.initialized then
        return
    end

    self.Database:Initialize()
    self.Options:Initialize()
    self.MapProvider:Register()
    self.Sampler:Start()
    self.Debug:Initialize()

    self.initialized = true
end
