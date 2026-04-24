
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

local CamIconTexture = '/game/camera-btn/pinned_btn_up.dds'

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
---@field CamIcon     Bitmap                # camera-link affordance, hidden unless entry.Camera is set
---@field Text        Text
---@field Entry       UIChatEntry | nil
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
        -- Empty-name continuation lines have zero width here, so the hit
        -- rect collapses with them — no need to gate dispatch on row role.
        self.Name.HandleEvent = function(_, event)
            if event.Type == 'ButtonPress' and self.Entry then
                self:OnNameClicked(self.Entry)
            end
        end

        -- Camera-link icon. Kept "invisible" when unused by clearing to a
        -- transparent solid colour and disabling hit-test — calling `Hide()`
        -- here would be undone when the window's `Show()` cascades to
        -- descendants (same reason `FactionIcon` cycles via SolidColor).
        self.CamIcon = Bitmap(self)
        self.CamIcon:SetSolidColor('00000000')
        self.CamIcon:DisableHitTest()
        self.CamIcon.HandleEvent = function(_, event)
            if event.Type == 'ButtonPress' and self.Entry then
                self:OnCameraClicked(self.Entry)
            end
        end

        self.Text = UIUtil.CreateText(self, '', 14, 'Arial')
        self.Text:SetColor('ffc2f6ff')
        self.Text:SetDropShadow(true)
        self.Text:SetClipToWidth(true)
        self.Text.HandleEvent = function(_, event)
            if event.Type == 'ButtonPress' and self.Entry then
                self:OnBodyClicked(self.Entry)
            end
        end
    end,

    ---@param self UIChatLineInterface
    ---@param parent Control
    __post_init = function(self, parent)
        -- Derive the row's height from the name font so pool sizing and
        -- scroll positions scale automatically with `ChatOptions.font_size`.
        Layouter(self)
            :Height(function() return self.Name.Height() + 2 end)
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

        -- Cam icon sits between the name and text on header rows. Fixed
        -- 20x16 footprint matching the legacy `pinned_btn_up.dds` art.
        Layouter(self.CamIcon)
            :RightOf(self.Name, 4)
            :AtVerticalCenterIn(self.TeamColor)
            :Width(20)
            :Height(16)
            :Over(self, 10)
            :End()

        -- Text Left jumps over the icon when present; SetHeader rebinds this
        -- when the entry's camera state changes.
        Layouter(self.Text)
            :Left(function() return self.Name.Right() + 2 end)
            :Right(self.Right)
            :AtVerticalCenterIn(self.TeamColor)
            :Over(self, 10)
            :End()
    end,

    --- Populates the row as the FIRST wrapped line of an entry: shows the
    --- team-colour square, faction icon, the name prefix, and the first
    --- wrapped chunk of message text.
    ---@param self UIChatLineInterface
    ---@param entry UIChatEntry
    ---@param wrappedText string    # the first wrapped chunk of `entry.Text`
    SetHeader = function(self, entry, wrappedText)
        self.Entry = entry
        self.Name:SetText(entry.Name or '')
        self.Text:SetText(wrappedText or entry.Text or '')
        self.TeamColor:SetSolidColor(entry.Color or '00000000')

        local iconIndex = entry.Faction or table.getn(FactionIcons)
        self.FactionIcon:SetTexture(UIUtil.UIFile(FactionIcons[iconIndex]))

        -- Camera affordance: switch between textured (hit-testable) and
        -- transparent SolidColor (inert) rather than Show/Hide, so the
        -- window-wide `Show()` cascade can't reveal stale icons. Re-applying
        -- `RightOf` replaces the previous Left binding (no leak).
        if entry.Camera then
            self.CamIcon:SetTexture(UIUtil.UIFile(CamIconTexture))
            self.CamIcon:EnableHitTest()
            LayoutHelpers.RightOf(self.Text, self.CamIcon, 4)
        else
            self.CamIcon:SetSolidColor('00000000')
            self.CamIcon:DisableHitTest()
            LayoutHelpers.RightOf(self.Text, self.Name, 2)
        end
    end,

    --- Populates the row as a CONTINUATION of a wrapped entry: the name slot
    --- and team-colour square stay empty, only the wrapped text is shown.
    --- The text control remains anchored to `Name.Right + 2`; with an empty
    --- name that resolves to the left of the row, so continuation lines
    --- naturally line up under the first wrapped chunk.
    ---
    --- The entry is still tracked so body clicks on wrapped lines dispatch
    --- against the same message the header belongs to.
    ---@param self UIChatLineInterface
    ---@param entry UIChatEntry
    ---@param wrappedText string
    SetContinuation = function(self, entry, wrappedText)
        self.Entry = entry
        self.Name:SetText('')
        self.Text:SetText(wrappedText or '')
        self.TeamColor:SetSolidColor('00000000')
        self.FactionIcon:SetSolidColor('00000000')
        self.CamIcon:SetSolidColor('00000000')
        self.CamIcon:DisableHitTest()
        LayoutHelpers.RightOf(self.Text, self.Name, 2)
    end,

    --- Clears all content so the row can stand empty.
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

    --- Overridable: fires on a click on the sender name. Continuation
    --- lines have an empty name control so the hit rect collapses — this
    --- only runs on header rows in practice. Default is a no-op; replace
    --- the field on an instance to subscribe.
    ---@param self UIChatLineInterface
    ---@param entry UIChatEntry
    OnNameClicked = function(self, entry) end,

    --- Overridable: fires on a click on the message body. Runs for both
    --- header and continuation rows — they share the same entry — so a
    --- click anywhere on a wrapped message resolves to the right sender.
    --- Default is a no-op; replace the field on an instance to subscribe.
    ---@param self UIChatLineInterface
    ---@param entry UIChatEntry
    OnBodyClicked = function(self, entry) end,

    --- Overridable: fires on a click on the camera icon. Only header rows
    --- show the icon (continuation rows hide it), so this only runs there.
    --- Default is a no-op; replace the field on an instance to subscribe.
    ---@param self UIChatLineInterface
    ---@param entry UIChatEntry
    OnCameraClicked = function(self, entry) end,

    --- Updates the font size for both name and body text. The row's `Height`
    --- LazyVar is derived from `Name.Height`, so the row resizes automatically.
    ---@param self UIChatLineInterface
    ---@param size number   # point size
    SetFontSize = function(self, size)
        self.Name:SetFont('Arial Bold', size)
        self.Text:SetFont('Arial', size)
    end,
}
