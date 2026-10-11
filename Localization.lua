local _, ns = ...

local locales = {
    enUS = {
        ADDON_TITLE = "Explorer's Footprint",
        SETTING_SHOW_OVERLAY = "Show heatmap overlay",
        SETTING_SHOW_OVERLAY_TOOLTIP = "Display your account-wide outdoor movement heatmap on the World Map.",
        SETTINGS_CATEGORY_DESCRIPTION = "Explorer's Footprint records outdoor movement locally and displays it as a World Map heatmap.",
        SLASH_HELP = "Usage: /footprint, /footprint status, /footprint debug map, or /footprint reset",
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
        DEBUG_MAP_NO_MAP = "Explorer's Footprint: no World Map target is available. Open the World Map first.",
        DEBUG_MAP_NO_POSITION = "unavailable position",
        DEBUG_MAP_NONE = "none",
    },
}

local locale = GetLocale and GetLocale() or "enUS"
ns.L = locales[locale] or locales.enUS
