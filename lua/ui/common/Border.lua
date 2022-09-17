
local NinePatch = import('/lua/ui/controls/ninepatch.lua').NinePatch
local SkinnableFile = import("/lua/ui/uiutil.lua").SkinnableFile

---@alias UIBorderTypes
--- | "/game/panel/panel"                           # Works, uses #ac000000 as background color
--- | "/game/filter-ping-list-panel/panel"          # Works, uses #ac000000 as background color
--- | "/scx_menu/lan-game-lobby/frame/"             
--- | "/scx_menu/lan-game-lobby/dialog/background/" # Works, uses #ff0d1016 as background color
--- | "/game/chat_brd/chat"                         # Works, but has clear chat related elements embedded

--- These appear broken when using a ninepatch
--- | "/campaign/campaign-select-border/back"       # Missing elements, elements all over the place
--- | "/dialogs/score-aeon/back"                    # Missing elements, elements all over the place
--- | "/game/avatar-factory-panel/factory-panel"    # Missing elements, elements do not align
--- | "/game/options-panel/options"                 # Missing elements, elements can look stretched
--- | "/game/mini-map-brd/mini-map"                 # Elements do not align
--- | "/game/mini-map-glow-brd/mini-map-glow"       # Elements do not align
--- | "/game/chat_brd05/chat"                       # Elements do not align
--- | "/game/generic_brd/generic"                   # Missing elements
--- | "/game/mini-map-brd01/mini-map"               # Elements do not align
--- | "/widgets/generic03_brd/generic"              # Missing elements

---@class UIBorder
UIBorder = ClassSimple {

    ---@param self Control
    ---@param path UIBorderTypes
    __init = function(self, path)

        path = path or "/game/filter-ping-list-panel/panel"
        
        -- attempt at supporting both the old and new convention
        local newConvention = path:sub(-1) == '/'

        self.Border = NinePatch(self,
            nil, -- SkinnableFile(path .. (newConvention and nil or "_brd_m.dds")),
            SkinnableFile(path .. (newConvention and 'topLeft.dds' or "_brd_ul.dds")),
            SkinnableFile(path .. (newConvention and 'topRight.dds' or "_brd_ur.dds")),
            SkinnableFile(path .. (newConvention and 'bottomLeft.dds' or "_brd_ll.dds")),
            SkinnableFile(path .. (newConvention and 'bottomRight.dds' or "_brd_lr.dds")),
            SkinnableFile(path .. (newConvention and 'left.dds' or "_brd_vert_l.dds")),
            SkinnableFile(path .. (newConvention and 'right.dds' or "_brd_vert_r.dds")),
            SkinnableFile(path .. (newConvention and 'top.dds' or "_brd_horz_um.dds")),
            SkinnableFile(path .. (newConvention and 'bottom.dds' or "_brd_lm.dds"))
        )

        self.Border:Surround(self, (newConvention and 62 or 0), (newConvention and 62 or 0))
        self.Border.Depth:Set(function() return self.Depth() + 2 end)
    end,
}