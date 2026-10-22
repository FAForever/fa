
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local Factions = import("/lua/factions.lua").Factions

local ChatConfigModel = import("/lua/ui/game/chat/config/ChatConfigModel.lua")
local ChatUtils = import("/lua/ui/game/chat/ChatUtils.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

--- Fallback body-text colour for entries without a `BodyColor` or a
--- resolvable `ColorKey`. Matches the legacy hardcoded body colour.
local DefaultBodyColor = 'ffc2f6ff'

local Debug = false

-- Faction icons with the observer icon appended as a tail for non-player
-- senders.
local FactionIcons = {}
for _, data in Factions do
    table.insert(FactionIcons, data.Icon)
end
table.insert(FactionIcons, '/widgets/faction-icons-alpha_bmp/observer_ico.dds')

local CamIconTexture = '/game/camera-btn/pinned_btn_up.dds'

--- Body-text colour for `entry`. Priority: `BodyColor` override, then
--- `ColorKey` palette lookup, then `DefaultBodyColor`.
---@param entry UIChatEntry
---@return string
local function ResolveBodyColor(entry)
    if entry.BodyColor then return entry.BodyColor end
    if entry.ColorKey then
        local idx = ChatConfigModel.GetOptions()[entry.ColorKey]
        if idx and ChatUtils.ColorPalette[idx] then
            return ChatUtils.ColorPalette[idx]
        end
    end
    return DefaultBodyColor
end

-------------------------------------------------------------------------------
-- A single chat row: team-coloured faction icon, sender name and message text.

--- One row of the chat-line pool: faction badge, clickable name, clickable text. Pooled and reused.
---@class UIChatLineInterface : Group
---@field TeamColor   Bitmap
---@field FactionIcon Bitmap
---@field Name        Text
---@field CamIcon     Bitmap                # camera-link affordance, hidden unless entry.Camera is set
---@field Text        Text
---@field Entry       UIChatEntry | nil
---@field DebugBG?    Bitmap                # semi-transparent overlay shown when `Debug` is true
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
        -- Continuation lines set Name to '' so the hit rect collapses
        -- with it. No need to gate dispatch on row role.
        self.Name.HandleEvent = function(_, event)
            if event.Type == 'ButtonPress' and self.Entry then
                self:OnNameClicked(self.Entry, event)
            end
        end

        -- Camera-link icon. Hidden via transparent SolidColor + disabled
        -- hit-test rather than `Hide()`. The window's `Show()` cascade
        -- would otherwise undo `Hide()` (same reason FactionIcon does
        -- it).
        self.CamIcon = Bitmap(self)
        self.CamIcon:SetSolidColor('00000000')
        self.CamIcon:DisableHitTest()
        self.CamIcon.HandleEvent = function(_, event)
            if event.Type == 'ButtonPress' and self.Entry then
                self:OnCameraClicked(self.Entry, event)
            end
        end

        self.Text = UIUtil.CreateText(self, '', 14, 'Arial')
        self.Text:SetColor('ffc2f6ff')
        self.Text:SetDropShadow(true)
        self.Text:SetClipToWidth(true)
        self.Text.HandleEvent = function(_, event)
            if event.Type == 'ButtonPress' and self.Entry then
                self:OnBodyClicked(self.Entry, event)
            end
        end
    end,

    ---@param self UIChatLineInterface
    ---@param parent Control
    __post_init = function(self, parent)
        -- Raw constants in SetFunction bodies don't auto-scale (only
        -- Layouter `:Height(number)` does), so pre-scale once.
        local twoPxScaled = LayoutHelpers.ScaleNumber(2)

        -- Derive row height from the name font so pool sizing scales
        -- automatically with `ChatOptions.font_size`.
        Layouter(self)
            :Height(function() return self.Name.Height() + twoPxScaled end)
            :End()

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

        -- 20x16 footprint matches the `pinned_btn_up.dds` art.
        Layouter(self.CamIcon)
            :RightOf(self.Name, 4)
            :AtVerticalCenterIn(self.TeamColor)
            :Width(20)
            :Height(16)
            :Over(self, 10)
            :End()

        -- SetHeader rebinds Text.Left when the entry's camera state changes.
        Layouter(self.Text)
            :Left(function() return self.Name.Right() + twoPxScaled end)
            :Right(self.Right)
            :AtVerticalCenterIn(self.TeamColor)
            :Over(self, 10)
            :End()

        if Debug then
            self.DebugBG = Bitmap(self)
            self.DebugBG:SetSolidColor('404040ff')
            self.DebugBG:DisableHitTest()
            Layouter(self.DebugBG):Fill(self):Over(self, 100):End()
        end
    end,

    --- Populates the row as the FIRST wrapped line of an entry.
    ---@param self UIChatLineInterface
    ---@param entry UIChatEntry
    ---@param wrappedText string    # the first wrapped chunk of `entry.Text`
    SetHeader = function(self, entry, wrappedText)
        self.Entry = entry
        self.Name:SetText(entry.Name or '')
        self.Text:SetText(wrappedText or entry.Text or '')
        self.Text:SetColor(ResolveBodyColor(entry))
        self.TeamColor:SetSolidColor(entry.Color or '00000000')

        -- Grey our own outgoing names. Re-applied every SetHeader because
        -- pool slots get reused across entries from different armies.
        if entry.ArmyID == GetFocusArmy() then
            self.Name:Disable()
        else
            self.Name:Enable()
        end

        local iconIndex = entry.Faction or table.getn(FactionIcons)
        self.FactionIcon:SetTexture(UIUtil.UIFile(FactionIcons[iconIndex]))

        -- SolidColor swap rather than Show/Hide so the window's Show()
        -- cascade can't reveal stale icons. Re-applying `RightOf`
        -- replaces the previous Left binding. Shown for both `Camera`
        -- snapshots and `Location` hints.
        if entry.Camera or entry.Location then
            self.CamIcon:SetTexture(UIUtil.UIFile(CamIconTexture))
            self.CamIcon:EnableHitTest()
            LayoutHelpers.RightOf(self.Text, self.CamIcon, 4)
        else
            self.CamIcon:SetSolidColor('00000000')
            self.CamIcon:DisableHitTest()
            LayoutHelpers.RightOf(self.Text, self.Name, 2)
        end
    end,

    --- Populates the row as a CONTINUATION of a wrapped entry.
    ---@param self UIChatLineInterface
    ---@param entry UIChatEntry
    ---@param wrappedText string
    SetContinuation = function(self, entry, wrappedText)
        -- Name and team-colour stay empty. Text anchors to `Name.Right
        -- + 2`, which with an empty name resolves to the row's left edge.
        -- Tracks the entry so body clicks on wrapped lines still dispatch
        -- against the right message.
        self.Entry = entry
        self.Name:SetText('')
        self.Text:SetText(wrappedText or '')
        self.Text:SetColor(ResolveBodyColor(entry))
        self.TeamColor:SetSolidColor('00000000')
        self.FactionIcon:SetSolidColor('00000000')
        self.CamIcon:SetSolidColor('00000000')
        self.CamIcon:DisableHitTest()
        LayoutHelpers.RightOf(self.Text, self.Name, 2)
    end,

    --- Resets the row to its empty state, ready for the next pool reuse.
    ---@param self UIChatLineInterface
    Clear = function(self)
        self.Entry = nil
        self.Name:SetText('')
        self.Text:SetText('')
        self.TeamColor:SetSolidColor('00000000')
        self.FactionIcon:SetSolidColor('00000000')
        self.CamIcon:SetSolidColor('00000000')
        self.CamIcon:DisableHitTest()
        LayoutHelpers.RightOf(self.Text, self.Name, 2)
    end,

    --- Overridable; default no-op. Fires when the sender's name is clicked.
    ---@param self UIChatLineInterface
    ---@param entry UIChatEntry
    ---@param event KeyEvent
    OnNameClicked = function(self, entry, event) end,

    --- Overridable; default no-op. Fires when the body text is clicked.
    --- Both header and continuation rows fire (they share the entry).
    ---@param self UIChatLineInterface
    ---@param entry UIChatEntry
    ---@param event KeyEvent
    OnBodyClicked = function(self, entry, event) end,

    --- Overridable; default no-op. Only header rows show the icon.
    ---@param self UIChatLineInterface
    ---@param entry UIChatEntry
    ---@param event KeyEvent
    OnCameraClicked = function(self, entry, event) end,

    --- Updates the name and body fonts. Row height tracks the name font.
    ---@param self UIChatLineInterface
    ---@param size number   # point size
    SetFontSize = function(self, size)
        self.Name:SetFont('Arial Bold', size)
        self.Text:SetFont('Arial', size)
    end,
}
