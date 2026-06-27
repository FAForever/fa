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
-- Slice 1: each row is a single, truncated line ("Name: text"). Multi-line wrapping is a later
-- refinement (the in-game chat's ChatLinesInterface is the reference if/when we want it).
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
local Debug = true

local CustomLobbyChatModel = import("/lua/ui/lobby/customlobby/social/customlobbychatmodel.lua")
local CustomLobbyChatController = import("/lua/ui/lobby/customlobby/social/customlobbychatcontroller.lua")

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
local NameMax = 90               -- truncate the rendered line so it can't bleed past the row (no clip in MAUI)

-- line colours by status / kind
local ChatColor = 'ffc8ccd0'     -- a confirmed chat line
local PendingColor = 'ff7e848c'  -- our own line, awaiting the host's echo (dimmed)
local RejectedColor = 'ff8a5a52'  -- the host dropped it (greyed-red, sender only)
local SystemColor = 'ff8a909a'   -- a local system notice

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

--- The rendered one-line label + colour for an entry, by kind and status.
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
---@field EditBox Edit
---@field Empty Text
---@field EntriesObserver LazyVar
---@field DebugPanel? Bitmap
---@field DebugEdit? Bitmap
---@field DebugGrid? Bitmap
local CustomLobbyChatPanel = ClassUI(Group) {

    ---@param self UICustomLobbyChatPanel
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyChatPanel")

        self.Trash = TrashBag()
        self.Ready = false
        self.Grid = false
        self.Scrollbar = false

        self.Empty = UIUtil.CreateText(self, "No messages yet", 13, UIUtil.bodyFont)
        self.Empty:SetColor('ff5a606a')
        self.Empty:DisableHitTest()
        self.Empty:Hide()

        self.EditBox = Edit(self)
        -- `SetupEditStd` reads the control's bounds before `__post_init` runs; seed placeholder values
        -- so it doesn't trip the default circular Left/Right/Width chain (see /lua/ui/CLAUDE.md § 1).
        Layouter(self.EditBox):Left(0):Top(0):Width(200):Height(EditHeight):End()
        UIUtil.SetupEditStd(self.EditBox,
            UIUtil.fontColor, nil, "ffffffff",
            UIUtil.highlightColor, UIUtil.bodyFont, 14, 200)
        self.EditBox:ShowBackground(false)
        self.EditBox:SetText('')
        self.EditBox.OnEnterPressed = function(_, text)
            if text and text ~= '' then
                CustomLobbyChatController.Send(text)
            end
            self.EditBox:SetText('')
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
    __post_init = function(self)
        -- The `__init` placeholder pinned Left/Top/Width/Height (so SetupEditStd could read bounds).
        -- Override every one here, and ResetWidth/ResetTop to drop the placeholder's concrete Width(200)
        -- and Top(0) — otherwise Top stays 0 (frame top) and the grid, whose bottom anchors to the edit
        -- box's top, gets dragged up out of the panel.
        Layouter(self.EditBox)
            :AtLeftIn(self, Pad):AtRightIn(self, Pad):ResetWidth()
            :AtBottomIn(self, Pad):Height(EditHeight):ResetTop()
            :End()
        Layouter(self.Empty):AtHorizontalCenterIn(self):AtTopIn(self, Pad):End()

        if Debug then
            -- whole panel (drawn under the grid tint added in Initialize) + the edit box region
            self.DebugPanel = Bitmap(self)
            self.DebugPanel:SetSolidColor('303080ff')   -- blue: the panel bounds
            self.DebugPanel:DisableHitTest()
            Layouter(self.DebugPanel):Fill(self):Over(self, 90):End()

            self.DebugEdit = Bitmap(self)
            self.DebugEdit:SetSolidColor('4080ff80')     -- green: the edit-box region
            self.DebugEdit:DisableHitTest()
            Layouter(self.DebugEdit):Fill(self.EditBox):Over(self, 110):End()
        end
    end,

    --- Builds the scrollable grid (its cell width needs the panel's concrete width) + scrollbar, and
    --- does the first render. Three-phase init (/lua/ui/CLAUDE.md § 1).
    ---@param self UICustomLobbyChatPanel
    Initialize = function(self)
        self.Ready = true

        -- Chat is the default tab, so this can run during the initial mount before the panel's width
        -- has settled. So anchor the grid's right edge **reactively** into the panel (reserving the
        -- scrollbar gutter) rather than baking a fixed width from a possibly-stale `self.Width()` — the
        -- scrollbar attaches to `grid.Right`, so a stale right edge throws the bar way off. The itemWidth
        -- ctor arg only drives horizontal column count (we have one column); vertical scrolling keys off
        -- itemHeight, so a best-effort width is fine and the row widths are recomputed in Refresh.
        self.RowWidth = self:ComputeRowWidth()
        self.Grid = Grid(self, self.RowWidth, RowHeight)
        Layouter(self.Grid)
            :AtLeftIn(self, Pad):AtRightIn(self, ScrollGap)
            :AtTopIn(self, Pad):AnchorToTop(self.EditBox, EditGap)
            :End()
        self.Scrollbar = UIUtil.CreateVertScrollbarFor(self.Grid)
        self.Scrollbar:Hide()   -- shown by UpdateScrollbar only when the feed overflows
        -- let the wheel scroll the grid when the cursor is over the rows, not just over the scrollbar
        UIUtil.ForwardWheelToScroll(self.Grid, self.Grid)

        if Debug then
            -- the feed/grid region (its right edge shows where the scrollbar gutter is reserved)
            self.DebugGrid = Bitmap(self)
            self.DebugGrid:SetSolidColor('40ff8040')     -- orange: the grid region
            self.DebugGrid:DisableHitTest()
            Layouter(self.DebugGrid):Fill(self.Grid):Over(self, 100):End()
        end

        self:Refresh()
    end,

    --- The current content width (panel width minus the scrollbar gutter), unscaled for row sizing.
    --- Clamped to a sane minimum so an early/unsettled read can't produce a negative width.
    ---@param self UICustomLobbyChatPanel
    ---@return number
    ComputeRowWidth = function(self)
        local scale = LayoutHelpers.GetPixelScaleFactor()
        return math.max(32, math.floor(self.Width() / scale) - ScrollGap)
    end,

    --- Rebuilds the list from the current entries, keeping the view pinned to the newest line unless
    --- the user has scrolled up.
    ---@param self UICustomLobbyChatPanel
    Refresh = function(self)
        if not self.Ready or not self.Grid then
            return
        end

        local entries = CustomLobbyChatModel.GetSingleton().Entries()
        local total = table.getn(entries)

        -- recompute the row width from the (now-settled) panel width so rows size correctly even if the
        -- first Initialize ran before the layout settled
        self.RowWidth = self:ComputeRowWidth()

        -- Bottom-align the feed (chat grows upward from the input box). A Grid renders rows top-down, so
        -- a few lines would otherwise float at the top of the tall area, far from the edit box. Pin the
        -- grid's bottom to the edit box (done in Initialize) and float its top so the grid is only as
        -- tall as its rows — capped at the available height, beyond which it fills and scrolls.
        local rowsHeight = total * LayoutHelpers.ScaleNumber(RowHeight)
        self.Grid.Top:Set(function()
            local availableTop = self.Top() + LayoutHelpers.ScaleNumber(Pad)
            return math.max(availableTop, self.Grid.Bottom() - rowsHeight)
        end)

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

    --- Builds one chat row: a single truncated line, tinted by status/kind. Private.
    ---@param self UICustomLobbyChatPanel
    ---@param entry UICustomLobbyChatEntry
    ---@return Group
    CreateRow = function(self, entry)
        local row = Group(self.Grid, "CustomLobbyChatRow")
        LayoutHelpers.SetDimensions(row, self.RowWidth, RowHeight)

        local label, color = RenderEntry(entry)
        local line = UIUtil.CreateText(row, Truncate(label, NameMax), RowFont, UIUtil.bodyFont)
        line:SetColor(color)
        line:DisableHitTest()
        Layouter(line):AtLeftIn(row, Pad):AtRightIn(row, Pad):AtVerticalCenterIn(row):End()

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
