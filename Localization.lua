local _, ns = ...

local locales = {
    enUS = {
        ADDON_TITLE = "Explorer's Footprint",
        SETTING_SHOW_OVERLAY = "Show heatmap overlay",
        SETTING_SHOW_OVERLAY_TOOLTIP = "Display your account-wide outdoor movement heatmap on the World Map.",
        SETTINGS_CATEGORY_DESCRIPTION = "Explorer's Footprint records outdoor movement locally and displays it as a World Map heatmap.",
        SLASH_HELP = "Usage: /footprint, /footprint status, or /footprint reset",
        STATUS_FORMAT = "Explorer's Footprint: %d maps, %d cells, %d samples.",
        STATUS_NO_DATA = "Explorer's Footprint: no movement data has been recorded yet.",
        RESET_CONFIRM = "Clear all Explorer's Footprint map data? This cannot be undone.",
        RESET_ACCEPT = "Clear data",
        RESET_CANCEL = "Cancel",
        RESET_COMPLETE = "Explorer's Footprint map data was cleared.",
        VERSION_FORMAT = "Explorer's Footprint %s",
    },
}

local locale = GetLocale and GetLocale() or "enUS"
ns.L = locales[locale] or locales.enUS
