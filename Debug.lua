local _, ns = ...

ns.Debug = {}

local function printStatus()
    local mapCount, cellCount, sampleCount = ns.Database:GetTotals()
    if mapCount == 0 then
        print(ns.L.STATUS_NO_DATA)
        return
    end

    print(ns.L.STATUS_FORMAT:format(mapCount, cellCount, sampleCount))
end

local function showResetDialog()
    StaticPopup_Show("EXPLORER_FOOTPRINT_CONFIRM_RESET")
end

function ns.Debug:Initialize()
    if self.initialized then
        return
    end

    StaticPopupDialogs["EXPLORER_FOOTPRINT_CONFIRM_RESET"] = {
        text = ns.L.RESET_CONFIRM,
        button1 = ns.L.RESET_ACCEPT,
        button2 = ns.L.RESET_CANCEL,
        OnAccept = function()
            ns.Database:ResetMaps()
            ns.MapProvider:RequestRefresh(true)
            print(ns.L.RESET_COMPLETE)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    SLASH_EXPLORERSFOOTPRINT1 = "/footprint"
    SLASH_EXPLORERSFOOTPRINT2 = "/ef"
    SlashCmdList.EXPLORERSFOOTPRINT = function(message)
        local command = (message or ""):lower():match("^%s*(.-)%s*$")
        if command == "status" then
            printStatus()
        elseif command == "reset" then
            showResetDialog()
        elseif command == "" then
            ns.Options:Open()
        else
            print(ns.L.SLASH_HELP)
        end
    end

    self.initialized = true
end
