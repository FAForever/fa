

local Control = import("/lua/maui/control.lua").Control

---@class MapPreview : moho.ui_map_preview_methods, Control, InternalObject
MapPreview = ClassUI(moho.ui_map_preview_methods, Control) {
    ---@param self MapPreview
    ---@param parent Control
    __init = function(self, parent)
        InternalCreateMapPreview(self, parent)
    end,
}
