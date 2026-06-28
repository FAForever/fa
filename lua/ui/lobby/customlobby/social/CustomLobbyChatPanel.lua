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

-- The Chat tab of the lobby's bottom-left tabbed panel: a scrollable feed of chat lines (fed by
-- CustomLobbyChatModel) over an edit box. Built to the same shape as the Logs tab
-- (../social/CustomLobbyLogsPanel.lua): a `Grid` of fixed-height rows + a vertical scrollbar that
-- sticks to the newest line unless you've scrolled up. The grid is built in `Initialize` because its
-- cell width needs the panel's concrete (post-mount) width.
--
-- The edit box's Enter routes through CustomLobbyChatController.Send — which decides command-vs-chat,
-- echoes the line optimistically (Pending) and asks the host to broadcast it. The host's echo
-- reconciles the line to Confirmed (see CustomLobbyChatModel). A line's Status tints it: Pending dim,
-- Rejected greyed, system lines in a muted colour.
--
-- Long messages **wrap**: each entry's "Name: text" label is word-wrapped to the message-column width
-- (BuildLines + WrapLine, via /lua/maui/text.lua WrapText measured by a hidden font-matched text), and
-- each wrapped line becomes one fixed-height grid row — the time stamp rides only the entry's first line.
--
-- A bottom-left tab content component: created when its tab is selected and destroyed on switch (see
-- ../CustomLobbyTabs.lua), so it's the live panel for its whole lifetime — the model observer just
-- rebuilds it (Refresh is Ready-gated).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Edit = import("/lua/maui/edit.lua").Edit
local Grid = import("/lua/maui/grid.lua").Grid
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

-- flip to true to tint this panel's sections (the feed grid vs. the edit box) — see /lua/ui/CLAUDE.md § 7.1
local Debug = false

local CustomLobbyChatModel = import("/lua/ui/lobby/customlobby/social/customlobbychatmodel.lua")
local CustomLobbyChatController = import("/lua/ui/lobby/customlobby/social/customlobbychatcontroller.lua")

local WrapText = import("/lua/maui/text.lua").WrapText
local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

-- the standard scrollbar gutter (matches the Logs panel / ModSelect): the grid reserves these 32px on
-- its right by being that much narrower, and CreateVertScrollbarFor(grid) hangs the bar on grid.Right
-- (offset 0), so it lands in the strip. Reservation lives in the content width, NOT the scrollbar call.
local ScrollGap = 32
local RowHeight = 18
local Pad = 4
local EditHeight = 20
local EditGap = 6
local RowFont = 13

-- the input field: a bordered, filled box at the bottom so it's clear where to type
local FieldHeight = 24
local FieldInset = 5             -- horizontal text padding inside the field
local FieldColor = 'ff10151b'        -- field fill
local FieldBorderColor = 'ff2b333d'  -- field 1px border
local PromptColor = 'ff5a606a'       -- the dim "type a message" placeholder

-- the time column (a relative mm:ss stamp at the left of each row, like the Logs tab)
local TimeFont = 11
local TimeWidth = 30             -- fits "mm:ss"
local TimeGap = 4
local TimeColor = 'ff6a707a'
local TimeLeft = Pad
local NameLeft = TimeLeft + TimeWidth + TimeGap   -- the message text starts after the time column

-- line colours by status / kind
local ChatColor = 'ffc8ccd0'     -- a confirmed chat line
local PendingColor = 'ff7e848c'  -- our own line, awaiting the host's echo (dimmed)
local RejectedColor = 'ff8a5a52'  -- the host dropped it (greyed-red, sender only)
local SystemColor = 'ff8a909a'   -- a local system notice

--- `mm:ss` from a seconds offset (Lua 5.0 — no `%`, use `math.mod`). Mirrors the Logs tab.
---@param seconds number
---@return string
local function FormatClock(seconds)
    local whole = math.floor(seconds)
    return string.format("%02d:%02d", math.floor(whole / 60), math.mod(whole, 60))
end

--- The rendered label + colour for an entry, by kind and status. The label is wrapped to the message
--- column width (see WrapLines), so the whole "Name: text" string flows across as many rows as it needs.
---@param entry UICustomLobbyChatEntry
---@return string label
---@return string color
local function RenderEntry(entry)
    if entry.Kind == 'system' then
        return entry.Text, SystemColor
    end
    local label = (entry.SenderName or "?") .. ": " .. entry.Text
    if entry.Status == 'Pending' then
        return label, PendingColor
    elseif entry.Status == 'Rejected' then
        return label, RejectedColor
    end
    return label, ChatColor
end

---@class UICustomLobbyChatPanel : Group
---@field Trash TrashBag
---@field Ready boolean
---@field Grid Grid | false
---@field RowWidth number          # unscaled row width (recomputed each Refresh from the panel width)
---@field Scrollbar Scrollbar | false
---@field EditFrame Bitmap         # input-field border
---@field EditField Bitmap         # input-field fill (inset 1px inside the border)
---@field EditBox Edit
---@field Prompt Text              # dim "type a message" placeholder, shown while the box is empty
---@field Empty Text
---@field Measure Text             # hidden, font-matched text used only to measure widths for wrapping
---@field EntriesObserver LazyVar
---@diagnostic disable-next-line
local CustomLobbyChatPanel = ClassUI(Bitmap) {

    ---@param self UICustomLobbyChatPanel
    ---@param parent Control
    __init = function(self, parent)
        ---@diagnostic disable-next-line: param-type-mismatch
        Bitmap.__init(self, parent)
        self:SetSolidColor(Debug and '303080ff' or '00000000')
        self:DisableHitTest()

        self.Trash = TrashBag()
        self.Ready = false
        self.Grid = false
        self.Scrollbar = false

        self.Empty = UIUtil.CreateText(self, "No messages yet", 13, UIUtil.bodyFont)
        self.Empty:SetColor('ff5a606a')
        self.Empty:DisableHitTest()
        self.Empty:Hide()

        -- a hidden, font-matched text whose :GetStringAdvance measures wrap widths (same font/size as a
        -- row's message text, so the measurement matches what's rendered)
        self.Measure = UIUtil.CreateText(self, "", RowFont, UIUtil.bodyFont)
        self.Measure:DisableHitTest()
        self.Measure:Hide()

        -- a bordered, filled input field at the bottom so it's clear where to type. Created before the
        -- edit box (and prompt) so they render on top of it (sibling depth follows creation order).
        self.EditFrame = Bitmap(self)
        self.EditFrame:SetSolidColor(FieldBorderColor)
        self.EditFrame:DisableHitTest()
        self.EditField = Bitmap(self)
        self.EditField:SetSolidColor(FieldColor)
        self.EditField:DisableHitTest()

        self.EditBox = Edit(self)
        -- `SetupEditStd` reads the control's bounds before `__post_init` runs; seed placeholder values
        -- so it doesn't trip the default circular Left/Right/Width chain (see /lua/ui/CLAUDE.md § 1).
        Layouter(self.EditBox):Left(0):Top(0):Width(200):Height(EditHeight):End()
        UIUtil.SetupEditStd(self.EditBox,
            UIUtil.fontColor, nil, UIUtil.highlightColor,
            UIUtil.highlightColor, UIUtil.bodyFont, 14, 200)
        self.EditBox:ShowBackground(false)
        self.EditBox:SetText('')

        -- a dim placeholder shown while the box is empty (hidden as soon as there's text)
        self.Prompt = UIUtil.CreateText(self, "Type a message…", RowFont, UIUtil.bodyFont)
        self.Prompt:SetColor(PromptColor)
        self.Prompt:DisableHitTest()

        self.EditBox.OnEnterPressed = function(_, text)
            if text and text ~= '' then
                CustomLobbyChatController.Send(text)
            end
            self.EditBox:SetText('')
            self.Prompt:Show()
        end
        self.EditBox.OnTextChanged = function(_, newText)
            if newText and newText ~= '' then
                self.Prompt:Hide()
            else
                self.Prompt:Show()
            end
        end

        -- created/destroyed with its tab, so always the live panel while it exists — the observer just
        -- rebuilds (Refresh is Ready-gated until Initialize builds the grid)
        self.EntriesObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbyChatModel.GetSingleton().Entries, function(entriesLazy)
                entriesLazy()
                self:Refresh()
            end))
    end,

    ---@param self UICustomLobbyChatPanel
    __post_init = function(self, parent)
        Layouter(self):Fill(parent):End()
        -- the input field (border + inset fill) pinned to the bottom
        Layouter(self.EditFrame)
            :AtLeftIn(self, Pad):AtRightIn(self, Pad)
            :AtBottomIn(self, Pad):Height(FieldHeight)
            :End()
        Layouter(self.EditField)
            :AtLeftIn(self.EditFrame, 1):AtRightIn(self.EditFrame, 1)
            :AtTopIn(self.EditFrame, 1):AtBottomIn(self.EditFrame, 1)
            :End()

        -- The `__init` placeholder pinned Left/Top/Width/Height (so SetupEditStd could read bounds).
        -- Override every one here, and ResetWidth to drop the placeholder's concrete Width(200);
        -- AtVerticalCenterIn re-sets Top (off the placeholder's 0), centring the box in the field.
        Layouter(self.EditBox)
            :AtLeftIn(self.EditField, FieldInset):AtRightIn(self.EditField, FieldInset):ResetWidth()
            :Height(EditHeight):AtTopIn(self.EditField, Pad)
            :End()
        Layouter(self.Prompt):AtLeftIn(self.EditField, FieldInset):AtTopIn(self.EditField, Pad):End()

        Layouter(self.Empty):AtHorizontalCenterIn(self):AtTopIn(self, Pad):End()
        Layouter(self.Measure):AtLeftTopIn(self, 0):End()   -- hidden; only its font metrics are used
    end,

    --- Builds the scrollable grid (its cell width needs the panel's concrete width) + scrollbar, and
    --- does the first render. Three-phase init (/lua/ui/CLAUDE.md § 1).
    ---@param self UICustomLobbyChatPanel
    Initialize = function(self)
        self.Ready = true

        -- Chat is the default tab, so this can run during the initial mount before the panel's width
        -- has settled. So anchor the grid's edges **reactively** into the panel (left+right insets,
        -- reserving the scrollbar gutter) rather than baking a fixed width from a possibly-stale
        -- `self.Width()` — the scrollbar attaches to `grid.Right`, so a stale right edge throws the bar
        -- way off.
        --
        -- The Grid hides any item outside its visible window; the visible **column** count is
        -- `floor(gridWidth / itemWidth)`, so if itemWidth ever exceeds the grid's content width the count
        -- is 0 and EVERY row is hidden (rows present, nothing drawn). This is a single-column list, so the
        -- column stride is irrelevant — pass itemWidth = 1 to guarantee ≥ 1 visible column regardless of
        -- width/timing; the rows are sized from the real content width in Refresh.
        self.RowWidth = self:ComputeRowWidth()
        self.Grid = Grid(self, 1, RowHeight)
        Layouter(self.Grid)
            :AtLeftIn(self, Pad):AtRightIn(self, ScrollGap)
            :AtTopIn(self, Pad):AnchorToTop(self.EditFrame, EditGap)
            :End()
        self.Scrollbar = UIUtil.CreateVertScrollbarFor(self.Grid)
        self.Scrollbar:Hide()   -- shown by UpdateScrollbar only when the feed overflows
        -- let the wheel scroll the grid when the cursor is over the rows, not just over the scrollbar
        UIUtil.ForwardWheelToScroll(self.Grid, self.Grid)

        self:Refresh()
    end,

    --- The grid's content width (panel width minus the left pad and the scrollbar gutter), unscaled,
    --- for row sizing. Matches the grid's `:AtLeftIn(self, Pad):AtRightIn(self, ScrollGap)` insets so a
    --- row spans exactly the visible feed. Clamped so an early/unsettled read can't go negative.
    ---@param self UICustomLobbyChatPanel
    ---@return number
    ComputeRowWidth = function(self)
        local scale = LayoutHelpers.GetPixelScaleFactor()
        return math.max(32, math.floor(self.Width() / scale) - Pad - ScrollGap)
    end,

    --- Rebuilds the list from the current entries, keeping the view pinned to the newest line unless
    --- the user has scrolled up.
    ---@param self UICustomLobbyChatPanel
    Refresh = function(self)
        if not self.Ready or not self.Grid then
            return
        end

        -- the panel only exists while the Chat tab is open, so a render means the feed is being viewed:
        -- clear the unread count (the badge in CustomLobbyInterface reads TotalCount - SeenTotal)
        CustomLobbyChatModel.MarkSeen(CustomLobbyChatModel.GetSingleton())

        -- recompute the row width from the (now-settled) panel width so rows size correctly even if the
        -- first Initialize ran before the layout settled
        self.RowWidth = self:ComputeRowWidth()

        -- flatten entries into visual lines (one per wrapped line); a long message spans several rows
        local lines = self:BuildLines(CustomLobbyChatModel.GetSingleton().Entries())
        local total = table.getn(lines)

        -- Bottom-align the feed (chat grows upward from the input box). A Grid renders rows top-down, so
        -- a few lines would otherwise float at the top of the tall area, far from the edit box. Pin the
        -- grid's bottom to the edit box (done in Initialize) and float its top so the grid is only as
        -- tall as its rows — capped at the available height, beyond which it fills and scrolls.
        local rowsHeight = total * LayoutHelpers.ScaleNumber(RowHeight)
        local availableHeight = self.EditFrame.Top() - self.Top() - LayoutHelpers.ScaleNumber(Pad + EditGap)
        LayoutHelpers.SetHeight(self.Grid, math.max(0, math.min(rowsHeight, availableHeight)))

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
        for index, line in lines do
            self.Grid:SetItem(self:CreateRow(line), 1, index, true)
        end
        self.Grid:EndBatch()

        if stick then
            self.Grid:ScrollSetTop("Vert", total)
        end
        self:UpdateScrollbar()
    end,

    --- Flattens the entries into renderable lines: each entry's "Name: text" label is wrapped to the
    --- message-column width, yielding one descriptor per wrapped line. The time stamp rides the first
    --- line of each entry; continuation lines align under the message column with no stamp.
    ---@param self UICustomLobbyChatPanel
    ---@param entries UICustomLobbyChatEntry[]
    ---@return { Stamp: string | false, Text: string, Color: string }[]
    BuildLines = function(self, entries)
        local width = LayoutHelpers.ScaleNumber(self.RowWidth - NameLeft - Pad)
        local start = CustomLobbyChatModel.GetStartTime()
        local lines = {}
        for _, entry in entries do
            local label, color = RenderEntry(entry)
            local stamp = FormatClock(entry.Time - start)
            local wrapped = self:WrapLine(label, width)
            for i, text in wrapped do
                table.insert(lines, {
                    Stamp = (i == 1) and stamp or false,
                    Text = text,
                    Color = color,
                })
            end
        end
        return lines
    end,

    --- Wraps `label` to `width` (actual pixels) via the hidden measuring text. Never returns empty.
    ---@param self UICustomLobbyChatPanel
    ---@param label string
    ---@param width number
    ---@return string[]
    WrapLine = function(self, label, width)
        if width < 1 then
            return { label }
        end
        local measure = self.Measure
        local lines = WrapText(label, width, function(chunk) return measure:GetStringAdvance(chunk) end)
        if table.empty(lines) then
            lines = { label }
        end
        return lines
    end,

    --- Shows the scrollbar only when the list overflows.
    ---@param self UICustomLobbyChatPanel
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

    --- Builds one rendered row: the wrapped text in the message column, tinted by status/kind, with the
    --- mm:ss stamp at the left only on an entry's first line (continuation lines have no stamp). Private.
    ---@param self UICustomLobbyChatPanel
    ---@param line { Stamp: string | false, Text: string, Color: string }
    ---@return Group
    CreateRow = function(self, line)
        local row = Group(self.Grid, "CustomLobbyChatRow")
        LayoutHelpers.SetDimensions(row, self.RowWidth, RowHeight)

        if line.Stamp then
            local time = UIUtil.CreateText(row, line.Stamp, TimeFont, UIUtil.bodyFont)
            time:SetColor(TimeColor)
            time:DisableHitTest()
            Layouter(time):AtLeftIn(row, TimeLeft):AtVerticalCenterIn(row):End()
        end

        local text = UIUtil.CreateText(row, line.Text, RowFont, UIUtil.bodyFont)
        text:SetColor(line.Color)
        text:DisableHitTest()
        Layouter(text):AtLeftIn(row, NameLeft):AtRightIn(row, Pad):AtVerticalCenterIn(row):End()

        return row
    end,

    ---@param self UICustomLobbyChatPanel
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@return UICustomLobbyChatPanel
Create = function(parent)
    return CustomLobbyChatPanel(parent)
end
