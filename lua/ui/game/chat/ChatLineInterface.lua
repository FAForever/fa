
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local Factions = import("/lua/factions.lua").Factions

local Layouter = LayoutHelpers.ReusedLayoutFor

-- Collect faction icons up-front; append an observer icon as the final entry
-- so non-player senders can be represented too.
local FactionIcons = {}
for _, data in Factions do
    table.insert(FactionIcons, data.Icon)
end
table.insert(FactionIcons, '/widgets/faction-icons-alpha_bmp/observer_ico.dds')

-------------------------------------------------------------------------------
-- A single chat row: team-coloured faction icon, sender name and message text.
--
-- The semi-transparent "feed mode" background (shown when the window chrome
-- is hidden) will be added back together with the feed-mode implementation —
-- having it here while `line:Show()` cascades to children caused it to double
-- up over the chat-window background.

---@class UIChatLineInterface : Group
---@field TeamColor   Bitmap
---@field FactionIcon Bitmap
---@field Name        Text
---@field Text        Text
ChatLineInterface = ClassUI(Group) {

    ---@param self UIChatLineInterface
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "ChatLineInterface")

        self.TeamColor = Bitmap(self)
        self.TeamColor:SetSolidColor('00000000')

        self.FactionIcon = Bitmap(self.TeamColor)
        self.FactionIcon:SetSolidColor('00000000')

        self.Name = UIUtil.CreateText(self, '', 14, 'Arial Bold')
        self.Name:SetColor('ffffffff')
        self.Name:SetDropShadow(true)
        self.Name:DisableHitTest()

        self.Text = UIUtil.CreateText(self, '', 14, 'Arial')
        self.Text:SetColor('ffc2f6ff')
        self.Text:SetDropShadow(true)
        self.Text:SetClipToWidth(true)
        self.Text:DisableHitTest()
    end,

    ---@param self UIChatLineInterface
    ---@param parent Control
    __post_init = function(self, parent)
        Layouter(self.TeamColor)
            :AtLeftTopIn(self)
            :Width(self.Height)
            :Height(self.Height)
            :End()

        Layouter(self.FactionIcon)
            :Fill(self.TeamColor)
            :End()

        Layouter(self.Name)
            :CenteredRightOf(self.TeamColor, 4)
            :Over(self, 10)
            :End()

        Layouter(self.Text)
            :Left(function() return self.Name.Right() + 2 end)
            :Right(self.Right)
            :AtVerticalCenterIn(self.TeamColor)
            :Over(self, 10)
            :End()
    end,

    --- Populates the line from a history entry.
    ---@param self UIChatLineInterface
    ---@param entry UIChatEntry
    SetEntry = function(self, entry)
        self.Name:SetText(entry.name or '')
        self.Text:SetText(entry.text or '')
        self.TeamColor:SetSolidColor(entry.color or '00000000')

        local iconIndex = entry.faction or table.getn(FactionIcons)
        self.FactionIcon:SetTexture(UIUtil.UIFile(FactionIcons[iconIndex]))
    end,

    --- Clears all content so the row can stand empty.
    ---@param self UIChatLineInterface
    Clear = function(self)
        self.Name:SetText('')
        self.Text:SetText('')
        self.TeamColor:SetSolidColor('00000000')
        self.FactionIcon:SetSolidColor('00000000')
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
