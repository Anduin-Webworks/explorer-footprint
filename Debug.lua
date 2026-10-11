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

local function formatMap(mapID)
    if not mapID then
        return ns.L.DEBUG_MAP_NONE
    end

    local mapInfo = ns.MapProjection:GetMapInfo(mapID)
    local mapName = mapInfo and mapInfo.name or "unknown"
    return ("%d (%s)"):format(mapID, mapName)
end

local function printParentChain(mapID)
    local chain = {}
    local visited = {}
    local currentMapID = mapID

    while currentMapID and currentMapID ~= 0 and not visited[currentMapID] do
        visited[currentMapID] = true
        chain[#chain + 1] = formatMap(currentMapID)
        local mapInfo = ns.MapProjection:GetMapInfo(currentMapID)
        currentMapID = mapInfo and mapInfo.parentMapID or nil
    end

    if #chain == 0 then
        return ns.L.DEBUG_MAP_NONE
    end

    return table.concat(chain, " -> ")
end

local function getXY(position)
    if not position then
        return nil
    end

    if position.GetXY then
        return position:GetXY()
    end

    return position.x, position.y
end

local function printMapDiagnostics()
    local map = ns.MapProvider:GetMap()
    local targetMapID = map and map:GetMapID()
    if not targetMapID then
        print(ns.L.DEBUG_MAP_NO_MAP)
        return
    end

    print(ns.L.DEBUG_MAP_HEADER)
    print(ns.L.DEBUG_MAP_TARGET:format(formatMap(targetMapID)))
    print(ns.L.DEBUG_MAP_PARENT_CHAIN:format(printParentChain(targetMapID)))

    local playerMapID = C_Map.GetBestMapForUnit("player")
    local position = playerMapID and C_Map.GetPlayerMapPosition(playerMapID, "player")
    local x, y = getXY(position)
    local positionText = x and y and (" (x=%.4f, y=%.4f)"):format(x, y) or (" (" .. ns.L.DEBUG_MAP_NO_POSITION .. ")")
    print(ns.L.DEBUG_MAP_PLAYER:format(formatMap(playerMapID), positionText))

    local childInfo
    if playerMapID and x and y and C_Map.GetMapInfoAtPosition then
        childInfo = C_Map.GetMapInfoAtPosition(playerMapID, x, y)
    end
    print(ns.L.DEBUG_MAP_RESOLVED:format(formatMap(childInfo and childInfo.mapID)))

    local diagnostics = ns.MapProjection:GetDisplayDiagnostics(targetMapID)
    print(ns.L.DEBUG_MAP_COUNTS:format(
        diagnostics.storedMapCount,
        diagnostics.relatedMapCount,
        diagnostics.relatedCellCount
    ))

    table.sort(diagnostics.sourceMaps, function(first, second)
        return first.mapID < second.mapID
    end)
    for _, sourceStats in ipairs(diagnostics.sourceMaps) do
        print(ns.L.DEBUG_MAP_SOURCE:format(
            formatMap(sourceStats.mapID),
            sourceStats.cellCount,
            sourceStats.projectedCount,
            sourceStats.failedCount
        ))
    end

    local bounds = ns.L.DEBUG_MAP_NONE
    if diagnostics.minX then
        bounds = ("x=%.4f..%.4f, y=%.4f..%.4f"):format(
            diagnostics.minX,
            diagnostics.maxX,
            diagnostics.minY,
            diagnostics.maxY
        )
    end
    print(ns.L.DEBUG_MAP_RESULT:format(
        diagnostics.displayCellCount or 0,
        diagnostics.maxCount or 0,
        bounds
    ))
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
        elseif command == "debug map" then
            printMapDiagnostics()
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
