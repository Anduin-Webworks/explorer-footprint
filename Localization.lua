local _, ns = ...

local locales = {
    enUS = {
        ADDON_TITLE = "Explorer's Footprint",
        SETTING_SHOW_OVERLAY = "Show heatmap overlay",
        SETTING_SHOW_OVERLAY_TOOLTIP = "Display your account-wide outdoor movement heatmap on the World Map.",
        SETTING_OVERLAY_OPACITY = "Heatmap opacity",
        SETTING_OVERLAY_OPACITY_TOOLTIP = "Set overlay visibility. Dark purple shows few crossed cells; bright yellow shows many crossed cells.",
        SETTINGS_CATEGORY_DESCRIPTION = "Each sample is a crossed map cell from movement. Colors run from dark purple (few crossings) to bright yellow (many crossings).",
        SLASH_HELP_HEADER = "Explorer's Footprint commands:",
        SLASH_HELP_OPEN = "/footprint  Open settings (alias: /ef)",
        SLASH_HELP_HELP = "/footprint help   Show this help",
        SLASH_HELP_TOGGLE = "/footprint toggle  Toggle the heatmap",
        SLASH_HELP_STATUS = "/footprint status  Print map, cell, and sample totals",
        SLASH_HELP_DEBUG = "/footprint debug map  Print map diagnostics",
        SLASH_HELP_RESET = "/footprint reset   Ask for confirmation before clearing map data",
        TOGGLE_ON = "Explorer's Footprint heatmap enabled.",
        TOGGLE_OFF = "Explorer's Footprint heatmap disabled.",
        STATUS_FORMAT = "Explorer's Footprint: %d maps, %d cells, %d samples.",
        STATUS_NO_DATA = "Explorer's Footprint: no movement data has been recorded yet.",
        RESET_CONFIRM = "Clear all Explorer's Footprint map data? This cannot be undone.",
        RESET_ACCEPT = "Clear data",
        RESET_CANCEL = "Cancel",
        RESET_COMPLETE = "Explorer's Footprint map data was cleared.",
        VERSION_FORMAT = "Explorer's Footprint %s",
        DEBUG_MAP_HEADER = "Explorer's Footprint map diagnostics:",
        DEBUG_MAP_TARGET = "World Map target: %s",
        DEBUG_MAP_PLAYER = "Player map: %s%s",
        DEBUG_MAP_RESOLVED = "Resolved child map: %s",
        DEBUG_MAP_PARENT_CHAIN = "Target parent chain: %s",
        DEBUG_MAP_COUNTS = "Stored maps: %d; related maps: %d; related cells: %d",
        DEBUG_MAP_SOURCE = "Source %s: %d cells; projected %d; failed %d",
        DEBUG_MAP_RESULT = "Display cells: %d; maximum count: %d; coordinate bounds: %s",
        DEBUG_MAP_RENDER = "Renderer: %s; cells: %d; positive: %d; bucketed: %d; runs: %d; pin: %s; raw: %s (%s)",
        DEBUG_MAP_RENDER_NOT_REFRESHED = "not refreshed since load",
        DEBUG_MAP_NO_MAP = "Explorer's Footprint: no World Map target is available. Open the World Map first.",
        DEBUG_MAP_NO_POSITION = "unavailable position",
        DEBUG_MAP_NONE = "none",
    },
}

local locale = GetLocale and GetLocale() or "enUS"
ns.L = locales[locale] or {}
if ns.L ~= locales.enUS then
    setmetatable(ns.L, { __index = locales.enUS })
end
