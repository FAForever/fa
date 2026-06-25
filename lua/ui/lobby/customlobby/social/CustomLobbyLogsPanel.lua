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
-- (every message it broadcasts / sends / receives), fed by `CustomLobbyLog`. A small **toolbar**
-- (a Copy icon-button that puts the whole log on the clipboard + a `Logs (N)` title) sits over a
-- **scrollable list** of rows.
--
-- Each row is laid out in columns, **fixed-width columns first then the flexible name** so the names
-- line up:  `time · kind · ⚠ · name`. A malformed / unauthorised message (its Validate or Accept
-- returned a reason) tints the name and fills the ⚠ slot with a warning icon whose tooltip is the
-- reason.
--
-- The list is a `Grid` (one column, a row Group per cell) + a vertical scrollbar — the same
-- scrollable-rows pattern the config column's option/mod panels use; the Grid hides off-window rows
-- so it scrolls without needing clip-to-bounds (MAUI has none). It sticks to the newest entry unless
-- you've scrolled up. The Grid is built in `Initialize` because its cell width needs the panel's
-- concrete (post-mount) width.
--
-- A bottom-left tab content component: created when its tab is selected and destroyed on switch (see
-- ../CustomLobbyTabs.lua), so it's the live panel for its whole lifetime — the model observer just
-- rebuilds it (Refresh is Ready-gated).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Grid = import("/lua/maui/grid.lua").Grid

local CustomLobbyLog = import("/lua/ui/lobby/customlobby/customlobbylog.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

local ToolbarHeight = 26          -- the Copy button + title band at the top
-- the standard scrollbar gutter (matches ModSelect): the grid reserves these 32px on its right by
-- being that much narrower, and CreateVertScrollbarFor(grid) hangs the bar on grid.Right (offset 0),
-- so it lands in the strip. Reservation lives in the content width, NOT the scrollbar call — never
-- also pass -32 to CreateVertScrollbarFor or it double-reserves and the bar overlaps the text.
local ScrollGap = 32
local RowHeight = 21
local Pad = 4
local ColGap = 3

-- the Copy icon-button (idle / hover background + a centred icon), mirroring the config column's
-- PreviewTool / the slot tool strip
local ButtonSize = 20
local ButtonIdle = 'ff141a20'
local ButtonHover = 'ff1f262e'
local ButtonIconInset = 4
local ButtonIconColor = 'ffc8ccd0'  -- TODO: temporary 1-colour placeholder until a copy/clipboard icon exists

-- font sizes per column (the message type is the one you read, so it's the largest)
local TimeFont = 12
local KindFont = 14
local NameFont = 14
local TitleFont = 14

-- fixed column widths (left → right); the name column is flexible and fills whatever is left
local TimeWidth = 30
local KindWidth = 16
local IconSize = 13
local NameMax = 40

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

-- plain-text kind label for the clipboard copy (glyphs don't paste usefully)
local KindText = {
    broadcast = "BROADCAST",
    send = "SEND",
    recv = "RECV",
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

--- One entry as a plain-text clipboard line: `mm:ss  RECV  Type  <- peer  [ERROR: reason]`.
---@param entry UICustomLobbyLogEntry
---@return string
local function EntryToText(entry)
    local line = FormatClock(entry.Time) .. "  " .. (KindText[entry.Kind] or "?") .. "  " .. entry.Type
    if entry.Peer then
        line = line .. (entry.Kind == 'recv' and "  <- " or "  -> ") .. tostring(entry.Peer)
    end
    if entry.Error then
        line = line .. "  [ERROR: " .. entry.Error .. "]"
    end
    return line
end

---@class UICustomLobbyLogsPanel : Group
---@field Trash TrashBag
---@field Ready boolean
---@field CopyButton Group         # icon-button (Bg + Icon); copies the log to the clipboard
---@field CopyBg Bitmap
---@field CopyIcon Bitmap
---@field Title Text
---@field Grid Grid | false
---@field RowWidth number          # unscaled cell width (set in Initialize from the panel width)
---@field Scrollbar Scrollbar | false
---@field Empty Text
---@field EntriesObserver LazyVar
local CustomLobbyLogsPanel = ClassUI(Group) {

    ---@param self UICustomLobbyLogsPanel
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyLogsPanel")

        self.Trash = TrashBag()
        self.Ready = false
        self.Grid = false
        self.Scrollbar = false

        --#region toolbar: Copy icon-button + title
        self.CopyButton = Group(self, "CustomLobbyLogCopy")
        self.CopyBg = Bitmap(self.CopyButton)
        self.CopyBg:SetSolidColor(ButtonIdle)
        self.CopyIcon = Bitmap(self.CopyButton)
        self.CopyIcon:SetSolidColor(ButtonIconColor)
        self.CopyIcon:DisableHitTest()
        self.CopyBg.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' then
                self:CopyAll()
                return true
            elseif event.Type == 'MouseEnter' then
                self.CopyBg:SetSolidColor(ButtonHover)
                return true
            elseif event.Type == 'MouseExit' then
                self.CopyBg:SetSolidColor(ButtonIdle)
                return true
            end
            return false
        end
        Tooltip.AddControlTooltipManual(self.CopyBg, "Copy log",
            "Copy the whole traffic log to the clipboard (handy when something looks wrong).")

        self.Title = UIUtil.CreateText(self, "Logs (0)", TitleFont, UIUtil.titleFont)
        self.Title:DisableHitTest()
        --#endregion

        self.Empty = UIUtil.CreateText(self, "No messages yet", 13, UIUtil.bodyFont)
        self.Empty:SetColor('ff5a606a')
        self.Empty:DisableHitTest()
        self.Empty:Hide()

        -- created/destroyed with its tab, so always the live panel while it exists — the observer
        -- just rebuilds (Refresh is Ready-gated until Initialize builds the grid)
        self.EntriesObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbyLog.GetSingleton().Entries, function(entriesLazy)
                entriesLazy()
                self:Refresh()
            end))
    end,

    ---@param self UICustomLobbyLogsPanel
    __post_init = function(self)
        Layouter(self.CopyButton):AtLeftIn(self, Pad):AtTopIn(self, Pad):Width(ButtonSize):Height(ButtonSize):End()
        Layouter(self.CopyBg):Fill(self.CopyButton):End()
        Layouter(self.CopyIcon)
            :AtCenterIn(self.CopyButton)
            :Width(ButtonSize - 2 * ButtonIconInset):Height(ButtonSize - 2 * ButtonIconInset)
            :End()
        Layouter(self.Title):AnchorToRight(self.CopyButton, 8):AtVerticalCenterIn(self.CopyButton):End()
        Layouter(self.Empty):AtHorizontalCenterIn(self):AtTopIn(self, ToolbarHeight + 8):End()
    end,

    --- Builds the scrollable grid (its cell width needs the panel's concrete width) + scrollbar, and
    --- does the first render. Three-phase init (/lua/ui/CLAUDE.md § 1).
    ---@param self UICustomLobbyLogsPanel
    Initialize = function(self)
        self.Ready = true

        -- Grid itemWidth is unscaled (Grid scales it); the panel width is concrete/scaled, so divide
        -- back out the ui scale. Reserve the scrollbar gap on the right.
        local scale = LayoutHelpers.GetPixelScaleFactor()
        self.RowWidth = math.floor(self.Width() / scale) - ScrollGap
        self.Grid = Grid(self, self.RowWidth, RowHeight)
        Layouter(self.Grid)
            :AtLeftIn(self, 0):Width(self.RowWidth)
            :AnchorToBottom(self.CopyButton, 6):AtBottomIn(self, Pad)
            :End()
        self.Scrollbar = UIUtil.CreateVertScrollbarFor(self.Grid)
        -- let the wheel scroll the grid when the cursor is over the rows, not just over the scrollbar
        UIUtil.ForwardWheelToScroll(self.Grid, self.Grid)

        self:Refresh()
    end,

    --- Rebuilds the list from the current entries, keeping the view pinned to the newest entry
    --- unless the user has scrolled up.
    ---@param self UICustomLobbyLogsPanel
    Refresh = function(self)
        if not self.Ready or not self.Grid then
            return
        end

        local entries = CustomLobbyLog.GetSingleton().Entries()
        local total = table.getn(entries)
        self.Title:SetText("Logs (" .. total .. ")")

        -- were we at (or near) the bottom before the rebuild? if so, stick to the bottom after
        local _, rangeMax, _, visibleMax = self.Grid:GetScrollValues("Vert")
        local stick = visibleMax >= rangeMax - 1

        self.Grid:DeleteAndDestroyAll(true)
        if total == 0 then
            self.Empty:Show()
            self.Grid:EndBatch()
            self:UpdateScrollbar()
            return
        end
        self.Empty:Hide()

        self.Grid:AppendCols(1, true)
        self.Grid:AppendRows(total, true)
        for index, entry in entries do
            self.Grid:SetItem(self:CreateRow(entry), 1, index, true)
        end
        self.Grid:EndBatch()

        if stick then
            self.Grid:ScrollSetTop("Vert", total)
        end
        self:UpdateScrollbar()
    end,

    --- Shows the scrollbar only when the list overflows.
    ---@param self UICustomLobbyLogsPanel
    UpdateScrollbar = function(self)
        if not self.Scrollbar then
            return
        end
        if self.Grid and self.Grid:IsScrollable("Vert") then
            self.Scrollbar:Show()
        else
            self.Scrollbar:Hide()
        end
    end,

    --- Copies the whole log to the clipboard as plain text (the engine's global `CopyToClipboard`).
    ---@param self UICustomLobbyLogsPanel
    CopyAll = function(self)
        local entries = CustomLobbyLog.GetSingleton().Entries()
        local lines = {}
        for index, entry in entries do
            lines[index] = EntryToText(entry)
        end
        CopyToClipboard(table.concat(lines, "\n"))
    end,

    --- Builds one log row: time · kind · (warn) · name. The warn icon only appears for a bad
    --- message; its column slot is still reserved (a fixed width before the flexible name) so names
    --- stay aligned. Private.
    ---@param self UICustomLobbyLogsPanel
    ---@param entry UICustomLobbyLogEntry
    ---@return Group
    CreateRow = function(self, entry)
        local row = Group(self.Grid, "CustomLobbyLogRow")
        LayoutHelpers.SetDimensions(row, self.RowWidth, RowHeight)

        local time = UIUtil.CreateText(row, FormatClock(entry.Time), TimeFont, UIUtil.bodyFont)
        time:SetColor(TimeColor)
        time:DisableHitTest()
        Layouter(time):AtLeftIn(row, TimeLeft):AtVerticalCenterIn(row):End()

        local kind = UIUtil.CreateText(row, KindGlyph[entry.Kind] or "·", KindFont, UIUtil.titleFont)
        kind:SetColor(entry.Kind == 'recv' and RecvColor or OutColor)
        kind:DisableHitTest()
        Layouter(kind):AtLeftIn(row, KindLeft):AtVerticalCenterIn(row):End()

        local label = entry.Type
        if entry.Peer then
            label = label .. (entry.Kind == 'recv' and "  ← " or "  → ") .. tostring(entry.Peer)
        end
        local name = UIUtil.CreateText(row, Truncate(label, NameMax), NameFont, UIUtil.bodyFont)
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
