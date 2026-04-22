
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local ObserverIcon = '/widgets/faction-icons-alpha_bmp/observer_ico.dds'

-------------------------------------------------------------------------------
-- A small badge showing a player's faction icon over their team colour, used
-- to identify players in the chat recipient picker and anywhere else in the
-- chat UI that wants to surface who a message is from or going to. Matches
-- the visual style used by the score panel (see `score.lua`). Consumers can
-- override the default 14x14 size via `LayoutHelpers.SetDimensions` or a
-- Layouter chain, and update the contents via `SetFaction` / `SetColor`.

---@class ChatFactionBadge : Group
---@field Color Bitmap  # team-colour tile behind the icon
---@field Icon  Bitmap  # faction icon on top of the colour tile
ChatFactionBadge = ClassUI(Group) {

    ---@param self ChatFactionBadge
    ---@param parent Control
    ---@param factionIndex? number   0-based faction index (UEF=0, Aeon=1, …); nil → observer icon
    ---@param color? string          ARGB hex string; defaults to white
    __init = function(self, parent, factionIndex, color)
        Group.__init(self, parent, "ChatFactionBadge")

        self.Color = Bitmap(self)
        self.Color:SetSolidColor(color or 'ffffffff')
        self.Color:DisableHitTest()

        self.Icon = Bitmap(self)
        self.Icon:DisableHitTest()
        self:SetFaction(factionIndex)

        -- Default square size; consumers can override via Layouter / SetDimensions.
        LayoutHelpers.SetDimensions(self, 14, 14)
    end,

    ---@param self ChatFactionBadge
    ---@param parent Control
    __post_init = function(self, parent)
        LayoutHelpers.FillParent(self.Color, self)
        LayoutHelpers.FillParent(self.Icon, self)

        -- Icon renders on top of the colour tile; the tile shows through the
        -- icon's transparent pixels.
        LayoutHelpers.DepthOverParent(self.Color, self, 1)
        LayoutHelpers.DepthOverParent(self.Icon, self, 2)
    end,

    --- Updates the faction icon. Pass `nil` to show the observer icon.
    ---@param self ChatFactionBadge
    ---@param factionIndex? number   0-based faction index
    SetFaction = function(self, factionIndex)
        if factionIndex then
            self.Icon:SetTexture(UIUtil.UIFile(UIUtil.GetFactionIcon(factionIndex)))
        else
            self.Icon:SetTexture(UIUtil.UIFile(ObserverIcon))
        end
    end,

    --- Updates the team colour tile.
    ---@param self ChatFactionBadge
    ---@param color string   ARGB hex, e.g. 'ffff4242'
    SetColor = function(self, color)
        self.Color:SetSolidColor(color or 'ffffffff')
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
