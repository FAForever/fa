--******************************************************************************************************
--** Copyright (c) 2026 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

-- The Logs tab of the lobby's bottom-left tabbed panel: a live view of this peer's network traffic
-- (every message it broadcasts / sends / receives), fed by `CustomLobbyLog`. It is a **tail view** —
-- the most recent entries that fit the panel height, newest at the bottom — rebuilt as traffic
-- arrives. (No scroll-back; the store keeps the last `MaxEntries`, this shows the tail.)
--
-- Each row is laid out in columns, **fixed-width columns first then the flexible name** so the names
-- line up:  `time · kind · ⚠ · name`. A malformed / unauthorised message (its Validate or Accept
-- returned a reason) tints the name and fills the ⚠ slot with a warning icon whose tooltip is the
-- reason.
--
-- A bottom-left tab content component: created when its tab is selected and destroyed on switch (see
-- ../CustomLobbyTabs.lua), so it's the live panel for its whole lifetime — the model observer just
-- rebuilds it (Refresh is Ready-gated).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local Group = import("/lua/maui/group.lua").Group

local CustomLobbyLog = import("/lua/ui/lobby/customlobby/customlobbylog.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

local RowHeight = 17
local Pad = 4
local ColGap = 3

-- fixed column widths (left → right); the name column is flexible and fills whatever is left
local TimeWidth = 30
local KindWidth = 16
local IconSize = 13
local NameMax = 28

-- left edges of each column, accumulated so every row's name starts at the same x (aligned)
local TimeLeft = Pad
local KindLeft = TimeLeft + TimeWidth + ColGap
local WarnLeft = KindLeft + KindWidth + ColGap
local NameLeft = WarnLeft + IconSize + ColGap

local TimeColor = 'ff6a707a'
local OutColor = 'ff7aa6c8'       -- outgoing kind glyph (broadcast / send)
local RecvColor = 'ff8ac88a'      -- incoming kind glyph (recv)
local NameColor = 'ffc8ccd0'
local ErrorColor = 'ffd0824c'     -- name tint when the message was bad

local WarnIcon = '/MODS/mod_type_warning.dds'

-- the kind glyph (its own column, so the name aligns regardless of direction)
local KindGlyph = {
    broadcast = "»»",
    send = "»",
    recv = "«",
}

--- `mm:ss` from a seconds offset (Lua 5.0 — no `%`, use `math.mod`).
---@param seconds number
---@return string
local function FormatClock(seconds)
    local whole = math.floor(seconds)
    return string.format("%02d:%02d", math.floor(whole / 60), math.mod(whole, 60))
end

--- Truncates `text` to `maxChars`, appending "…" when it had to cut.
---@param text string
---@param maxChars number
---@return string
local function Truncate(text, maxChars)
    text = text or ""
    if string.len(text) > maxChars then
        return string.sub(text, 1, maxChars - 1) .. "…"
    end
    return text
end

---@class UICustomLobbyLogsPanel : Group
---@field Trash TrashBag
---@field Ready boolean
---@field Rows Group[]
---@field Empty Text
---@field EntriesObserver LazyVar
local CustomLobbyLogsPanel = ClassUI(Group) {

    ---@param self UICustomLobbyLogsPanel
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyLogsPanel")

        self.Trash = TrashBag()
        self.Ready = false
        self.Rows = {}

        self.Empty = UIUtil.CreateText(self, "No messages yet", 13, UIUtil.bodyFont)
        self.Empty:SetColor('ff5a606a')
        self.Empty:DisableHitTest()
        self.Empty:Hide()

        -- created/destroyed with its tab, so always the live panel while it exists — the observer
        -- just rebuilds (Refresh is Ready-gated until Initialize sizes the panel)
        self.EntriesObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbyLog.GetSingleton().Entries, function(entriesLazy)
                entriesLazy()
                self:Refresh()
            end))
    end,

    ---@param self UICustomLobbyLogsPanel
    __post_init = function(self)
        Layouter(self.Empty):AtHorizontalCenterIn(self):AtTopIn(self, 8):End()
    end,

    --- Does the first render once the panel has a concrete height (three-phase init).
    ---@param self UICustomLobbyLogsPanel
    Initialize = function(self)
        self.Ready = true
        self:Refresh()
    end,

    --- Rebuilds the tail: the most recent entries that fit the panel height, oldest-visible at the
    --- top, newest at the bottom.
    ---@param self UICustomLobbyLogsPanel
    Refresh = function(self)
        if not self.Ready then
            return
        end

        for _, row in self.Rows do
            row:Destroy()
        end
        self.Rows = {}

        local entries = CustomLobbyLog.GetSingleton().Entries()
        local total = table.getn(entries)
        if total == 0 then
            self.Empty:Show()
            return
        end
        self.Empty:Hide()

        local rowHeight = LayoutHelpers.ScaleNumber(RowHeight)
        local available = self.Height() - LayoutHelpers.ScaleNumber(2 * Pad)
        local capacity = math.max(1, math.floor(available / rowHeight))
        local first = math.max(1, total - capacity + 1)

        ---@type Group | false
        local previous = false
        for i = first, total do
            local row = self:CreateRow(entries[i])
            local builder = Layouter(row):AtLeftIn(self, Pad):AtRightIn(self, Pad):Height(RowHeight)
            if previous then
                builder:AnchorToBottom(previous)
            else
                builder:AtTopIn(self, Pad)
            end
            builder:End()
            previous = row
            table.insert(self.Rows, row)
        end
    end,

    --- Builds one log row: time · kind · (warn) · name. The warn icon only appears for a bad
    --- message; its column slot is still reserved (a fixed width before the flexible name) so names
    --- stay aligned. Private.
    ---@param self UICustomLobbyLogsPanel
    ---@param entry UICustomLobbyLogEntry
    ---@return Group
    CreateRow = function(self, entry)
        local row = Group(self, "CustomLobbyLogRow")

        local time = UIUtil.CreateText(row, FormatClock(entry.Time), 11, UIUtil.bodyFont)
        time:SetColor(TimeColor)
        time:DisableHitTest()
        Layouter(time):AtLeftIn(row, TimeLeft):AtVerticalCenterIn(row):End()

        local kind = UIUtil.CreateText(row, KindGlyph[entry.Kind] or "·", 12, UIUtil.titleFont)
        kind:SetColor(entry.Kind == 'recv' and RecvColor or OutColor)
        kind:DisableHitTest()
        Layouter(kind):AtLeftIn(row, KindLeft):AtVerticalCenterIn(row):End()

        local label = entry.Type
        if entry.Peer then
            label = label .. (entry.Kind == 'recv' and "  ← " or "  → ") .. tostring(entry.Peer)
        end
        local name = UIUtil.CreateText(row, Truncate(label, NameMax), 12, UIUtil.bodyFont)
        name:SetColor(entry.Error and ErrorColor or NameColor)
        name:DisableHitTest()
        Layouter(name):AtLeftIn(row, NameLeft):AtRightIn(row, Pad):AtVerticalCenterIn(row):End()

        if entry.Error then
            local warn = UIUtil.CreateBitmap(row, WarnIcon)
            warn:DisableHitTest()
            Layouter(warn):AtLeftIn(row, WarnLeft):AtVerticalCenterIn(row):Width(IconSize):Height(IconSize):End()
            -- a hit-test-enabled overlay so the tooltip (the failure reason) shows on hover
            local hover = Group(row, "CustomLobbyLogWarnHover")
            Layouter(hover):AtLeftIn(row, WarnLeft):AtVerticalCenterIn(row):Width(IconSize):Height(IconSize):End()
            Tooltip.AddControlTooltipManual(hover, "Invalid message", entry.Error)
        end

        return row
    end,

    ---@param self UICustomLobbyLogsPanel
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@return UICustomLobbyLogsPanel
Create = function(parent)
    return CustomLobbyLogsPanel(parent)
end
