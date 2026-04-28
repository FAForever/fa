
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Create = import("/lua/lazyvar.lua").Create

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local Registry = import("/lua/ui/game/chat/commands/ChatCommandRegistry.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

local Debug = false

local RowFontSize = 12
local RowFontName = 'Arial'
local HorizontalPadding = 12
local VerticalPadding   = 2

local MaxVisibleRows = 6

--- Reserved unconditionally so the layout doesn't reflow when the
--- scrollbar shows / hides with the match count.
local ScrollbarWidth = 24

--- Renders a command the same way `/help` does.
---@param cmd UIChatCommand
---@return string
local function FormatCommand(cmd)
    local params = ''
    if cmd.Params then
        for _, p in ipairs(cmd.Params) do
            local fmt = p.Optional and ' [%s]' or ' <%s>'
            params = params .. string.format(fmt, p.Name)
        end
    end

    local aliases = ''
    if cmd.Aliases and table.getn(cmd.Aliases) > 0 then
        aliases = ' (aka /' .. table.concat(cmd.Aliases, ', /') .. ')'
    end

    return string.format("/%s%s%s — %s", cmd.Name, params, aliases, cmd.Description or '')
end

-------------------------------------------------------------------------------
-- Command-hint popup. Shows commands whose name or aliases prefix-match.
-- Reuses a pool of row controls across refreshes. Rows are
-- shown/hidden and re-positioned via a per-row `ordinal` LazyVar.

--- One pooled hint row; ordinal 0 means hidden, otherwise it's the row's position from the bottom.
---@class UIChatHintRow
---@field Text    Text
---@field BG      Bitmap
---@field Ordinal LazyVar<number>            # 0 = hidden, 1 = bottom row, growing upward
---@field Target  UIChatCommand | nil
---@field Hovered boolean
---@field Paint   fun()                       # re-applies BG solid-colour from Hovered + owner.Selected

--- Slash-command auto-suggest popup anchored above the edit box; reuses a row pool across refreshes.
---@class UIChatCommandHintInterface : Group
---@field Edit         Edit
---@field OnSelect?    fun(cmd: UIChatCommand)
---@field Rows         UIChatHintRow[]        # reusable pool, indexed by ordinal
---@field Background   Bitmap                 # solid backdrop covering the whole popup
---@field Scrollbar    Scrollbar              # vertical scrollbar shown when VisibleCount > MaxVisibleRows
---@field RowHeight    LazyVar<number>
---@field VisibleCount LazyVar<number>
---@field Selected     LazyVar<number>        # 0 = no selection, 1..VisibleCount = row ordinal
---@field ScrollBottom LazyVar<number>        # 1-based ordinal at the bottom visible slot
---@field LastText     string
---@field LTBG Bitmap
---@field RTBG Bitmap
---@field RBBG Bitmap
---@field RLBG Bitmap
---@field LBG  Bitmap
---@field RBG  Bitmap
---@field TBG  Bitmap
---@field BBG  Bitmap
---@field DebugBG? Bitmap                 # semi-transparent overlay shown when `Debug` is true
ChatCommandHintInterface = ClassUI(Group) {

    ---@param self UIChatCommandHintInterface
    ---@param parent Control
    ---@param edit Edit
    __init = function(self, parent, edit)
        Group.__init(self, parent, "ChatCommandHintInterface")
        self:DisableHitTest()
        LayoutHelpers.DepthOverParent(self, parent, 100)

        self.Edit = edit
        self.Rows = {}
        self.LastText = ''
        self.VisibleCount = Create(0)
        self.Selected = Create(0)
        self.Selected.OnDirty = function() self:RepaintRows() end
        self.ScrollBottom = Create(1)
        self.ScrollBottom.OnDirty = function() self:UpdateRowVisibility() end

        -- Backdrop fills the gaps between the per-row highlight strips
        -- (which only span Text.Top-1..Text.Bottom+1).
        self.Background = Bitmap(self)
        self.Background:SetSolidColor('ff000000')
        self.Background:DisableHitTest()

        -- `probe.Height()` is already in scaled pixels; the padding
        -- constant has to be scaled by hand to track UI scale.
        ---@diagnostic disable-next-line: param-type-mismatch
        local probe = UIUtil.CreateText(self, '/sample', RowFontSize, RowFontName)
        ---@diagnostic disable-next-line: undefined-field
        self.RowHeight = Create(probe.Height() + LayoutHelpers.ScaleNumber(VerticalPadding))
        probe:Destroy()

        self.LTBG = Bitmap(self, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ul.dds'))
        self.LTBG:DisableHitTest()
        self.RTBG = Bitmap(self, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ur.dds'))
        self.RTBG:DisableHitTest()
        self.RBBG = Bitmap(self, UIUtil.UIFile('/game/chat_brd/drop-box_brd_lr.dds'))
        self.RBBG:DisableHitTest()
        self.RLBG = Bitmap(self, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ll.dds'))
        self.RLBG:DisableHitTest()
        self.LBG = Bitmap(self, UIUtil.UIFile('/game/chat_brd/drop-box_brd_vert_l.dds'))
        self.LBG:DisableHitTest()
        self.RBG = Bitmap(self, UIUtil.UIFile('/game/chat_brd/drop-box_brd_vert_r.dds'))
        self.RBG:DisableHitTest()
        self.TBG = Bitmap(self, UIUtil.UIFile('/game/chat_brd/drop-box_brd_horz_um.dds'))
        self.TBG:DisableHitTest()
        self.BBG = Bitmap(self, UIUtil.UIFile('/game/chat_brd/drop-box_brd_lm.dds'))
        self.BBG:DisableHitTest()
    end,

    ---@param self UIChatCommandHintInterface
    ---@param parent Control
    __post_init = function(self, parent)
        -- Width fits the widest fully-formatted row so the popup doesn't
        -- reflow horizontally as rows change.
        local probeText = '/help'
        for _, cmd in ipairs(Registry.GetAll()) do
            local candidate = FormatCommand(cmd)
            if string.len(candidate) > string.len(probeText) then
                probeText = candidate
            end
        end
        ---@diagnostic disable-next-line: param-type-mismatch
        local probe = UIUtil.CreateText(self, probeText, RowFontSize, RowFontName)
        ---@diagnostic disable-next-line: undefined-field
        local textWidth = probe.Width()
        probe:Destroy()

        local extraScaled = LayoutHelpers.ScaleNumber(HorizontalPadding * 2 + ScrollbarWidth)
        Layouter(self)
            :Width(function() return textWidth + extraScaled end)
            :End()

        ---@diagnostic disable: undefined-field
        self.Height:SetFunction(function()
            local rows = math.min(self.VisibleCount(), MaxVisibleRows)
            return rows * self.RowHeight()
        end)

        self.Background.Left:SetFunction(function()   return self.Left() end)
        self.Background.Right:SetFunction(function()  return self.Right() end)
        self.Background.Top:SetFunction(function()    return self.Top() end)
        self.Background.Bottom:SetFunction(function() return self.Bottom() end)
        self.Background.Depth:SetFunction(function()  return self.Depth() end)

        Layouter(self.LTBG):Right(self.Left):Bottom(self.Top):End()
        Layouter(self.RTBG):Left(self.Right):Bottom(self.Top):End()
        Layouter(self.RBBG):Left(self.Right):Top(self.Bottom):End()
        Layouter(self.RLBG):Right(self.Left):Top(self.Bottom):End()
        Layouter(self.LBG):Right(self.Left):Top(self.Top):Bottom(self.Bottom):End()
        Layouter(self.RBG):Left(self.Right):Top(self.Top):Bottom(self.Bottom):End()
        Layouter(self.TBG):Left(self.Left):Right(self.Right):Bottom(self.Top):End()
        Layouter(self.BBG):Left(self.Left):Right(self.Right):Top(self.Bottom):End()
        ---@diagnostic enable: undefined-field

        -- Negative offset_right pulls the bar inside the popup bounds
        -- instead of overlapping the right border art.
        self.Scrollbar = UIUtil.CreateVertScrollbarFor(self, -ScrollbarWidth)

        local function syncScrollbarVisibility()
            if self.VisibleCount() > MaxVisibleRows then
                self.Scrollbar:Show()
            else
                self.Scrollbar:Hide()
            end
        end
        self.VisibleCount.OnDirty = function() syncScrollbarVisibility() end
        syncScrollbarVisibility()

        if Debug then
            self.DebugBG = Bitmap(self)
            self.DebugBG:SetSolidColor('4040ffff')
            self.DebugBG:DisableHitTest()
            Layouter(self.DebugBG):Fill(self):Over(self, 100):End()
        end
    end,

    --- Reusable row (text + highlight + hover handler). Layout deferred
    --- to `GetOrCreateRow` / `LayoutRowBackground`.
    ---@param self UIChatCommandHintInterface
    ---@return UIChatHintRow
    BuildRow = function(self)
        ---@type UIChatHintRow
        local row = {
            Ordinal = Create(0),
            Target  = nil,
        }
        ---@diagnostic disable-next-line: param-type-mismatch
        row.Text = UIUtil.CreateText(self, '', RowFontSize, RowFontName)
        row.Text:SetColor('ffffffff')
        row.Text:SetDropShadow(true)
        row.Text:DisableHitTest()

        row.BG = Bitmap(row.Text)
        row.BG:SetSolidColor('00000000')
        row.Hovered = false

        local owner = self
        local function paint()
            if row.Hovered or (row.Ordinal() > 0 and owner.Selected() == row.Ordinal()) then
                row.BG:SetSolidColor('ff666666')
            else
                row.BG:SetSolidColor('00000000')
            end
        end
        row.Paint = paint

        row.BG.HandleEvent = function(_, event)
            if event.Type == 'MouseEnter' then
                row.Hovered = true
                paint()
            elseif event.Type == 'MouseExit' then
                row.Hovered = false
                paint()
            elseif event.Type == 'ButtonPress' then
                if row.Target and owner.OnSelect then
                    owner.OnSelect(row.Target)
                end
            end
        end

        return row
    end,

    --- Re-runs each row's paint to sync hover and selection highlights.
    ---@param self UIChatCommandHintInterface
    RepaintRows = function(self)
        for _, row in pairs(self.Rows) do
            if row.Paint then row.Paint() end
        end
    end,

    --- Shows or hides each row based on the current scroll window.
    ---@param self UIChatCommandHintInterface
    UpdateRowVisibility = function(self)
        local scrollBottom = self.ScrollBottom()
        for ord, row in pairs(self.Rows) do
            local inWindow = row.Ordinal() > 0
                and ord >= scrollBottom
                and ord < scrollBottom + MaxVisibleRows
            if inWindow then
                row.Text:Show()
                row.BG:Show()
            else
                row.Text:Hide()
                row.BG:Hide()
            end
        end
    end,

    --- Scrolls the visible window so `ordinal` is on screen.
    ---@param self UIChatCommandHintInterface
    ---@param ordinal number
    EnsureOrdinalVisible = function(self, ordinal)
        if ordinal <= 0 then return end
        local scrollBottom = self.ScrollBottom()
        if ordinal < scrollBottom then
            self.ScrollBottom:Set(ordinal)
        elseif ordinal >= scrollBottom + MaxVisibleRows then
            self.ScrollBottom:Set(ordinal - MaxVisibleRows + 1)
        end
    end,

    -------------------------------------------------------------------------
    -- Scrollable interface for the MAUI `Scrollbar`. The scrollbar thinks
    -- top-down but our ordinals grow bottom-up; convert at the boundary
    -- so the thumb tracks visually.
    --   topdown_top = n - ScrollBottom - MaxVisibleRows + 2
    --   ScrollBottom = n - topdown_top - MaxVisibleRows + 2  (inverse)
    -------------------------------------------------------------------------

    --- Scrollbar contract: returns `(min, max, top, bottom)` in top-down coordinates.
    ---@param self UIChatCommandHintInterface
    ---@param axis string
    GetScrollValues = function(self, axis)
        local n = self.VisibleCount()
        if n <= 0 then return 1, 1, 1, 1 end
        local top = n - self.ScrollBottom() - MaxVisibleRows + 2
        if top < 1 then top = 1 end
        return 1, n, top, math.min(top + MaxVisibleRows - 1, n)
    end,

    --- Scrolls by a line count.
    ---@param self UIChatCommandHintInterface
    ---@param axis string
    ---@param delta number
    ScrollLines = function(self, axis, delta)
        local _, _, top, _ = self:GetScrollValues(axis)
        self:ScrollSetTop(axis, top + math.floor(delta))
    end,

    --- Scrolls by full visible-window pages.
    ---@param self UIChatCommandHintInterface
    ---@param axis string
    ---@param delta number
    ScrollPages = function(self, axis, delta)
        local _, _, top, _ = self:GetScrollValues(axis)
        self:ScrollSetTop(axis, top + math.floor(delta) * MaxVisibleRows)
    end,

    --- Jumps to an absolute top-down position; flips it back to bottom-up `ScrollBottom`.
    ---@param self UIChatCommandHintInterface
    ---@param axis string
    ---@param top number   # in scrollbar (top-down) coordinates
    ScrollSetTop = function(self, axis, top)
        local n = self.VisibleCount()
        if n <= 0 then return end
        local maxTop = math.max(1, n - MaxVisibleRows + 1)
        top = math.max(1, math.min(maxTop, math.floor(top or 1)))
        local newScrollBottom = n - top - MaxVisibleRows + 2
        newScrollBottom = math.max(1, math.min(maxTop, newScrollBottom))
        if newScrollBottom ~= self.ScrollBottom() then
            self.ScrollBottom:Set(newScrollBottom)
        end
    end,

    --- Whether there are more matches than fit in the visible window.
    ---@param self UIChatCommandHintInterface
    ---@param axis string
    IsScrollable = function(self, axis)
        return self.VisibleCount() > MaxVisibleRows
    end,

    --- Wheel scroll handler.
    ---@param self UIChatCommandHintInterface
    ---@param rotation number
    OnMouseWheel = function(self, rotation)
        self:ScrollLines(nil, -math.floor(rotation / 100))
    end,

    --- Advances the selection one row down (wraps to the top).
    ---@param self UIChatCommandHintInterface
    SelectNext = function(self)
        local n = self.VisibleCount()
        if n <= 0 then return end
        local cur = self.Selected()
        local next = cur >= n and 1 or cur + 1
        self.Selected:Set(next)
        self:EnsureOrdinalVisible(next)
    end,

    --- Moves the selection one row up (wraps to the bottom).
    ---@param self UIChatCommandHintInterface
    SelectPrev = function(self)
        local n = self.VisibleCount()
        if n <= 0 then return end
        local cur = self.Selected()
        local prev = cur <= 1 and n or cur - 1
        self.Selected:Set(prev)
        self:EnsureOrdinalVisible(prev)
    end,

    --- Returns the currently highlighted command, or nil if none.
    ---@param self UIChatCommandHintInterface
    ---@return UIChatCommand?
    GetSelected = function(self)
        local ord = self.Selected()
        if ord <= 0 then return nil end
        local row = self.Rows[ord]
        return row and row.Target or nil
    end,

    --- Returns the row at `idx`, building one on demand the first time.
    ---@param self UIChatCommandHintInterface
    ---@param idx number
    ---@return UIChatHintRow
    GetOrCreateRow = function(self, idx)
        local existing = self.Rows[idx]
        if existing then return existing end

        local row = self:BuildRow()
        self.Rows[idx] = row

        ---@diagnostic disable: undefined-field
        local horizontalPaddingScaled = LayoutHelpers.ScaleNumber(HorizontalPadding)
        row.Text.Left:SetFunction(function() return self.Left() + horizontalPaddingScaled end)
        row.Text.Bottom:SetFunction(function()
            local ord = row.Ordinal()
            if ord <= 0 then return self.Top() end
            -- slot 1 = bottom visible row, MaxVisibleRows = top.
            local slot = ord - self.ScrollBottom() + 1
            if slot < 1 or slot > MaxVisibleRows then return self.Top() end
            return self.Bottom() - (slot - 1) * self.RowHeight()
        end)
        ---@diagnostic enable: undefined-field

        self:LayoutRowBackground(row)
        return row
    end,

    --- Spans popup width at the row's vertical position; one depth below
    --- the text so clicks hit the bitmap.
    ---@param self UIChatCommandHintInterface
    ---@param row UIChatHintRow
    LayoutRowBackground = function(self, row)
        ---@diagnostic disable: undefined-field
        local onePixelScaled = LayoutHelpers.ScaleNumber(1)
        row.BG.Left:SetFunction(function()   return self.Left() end)
        row.BG.Right:SetFunction(function()  return self.Right() end)
        row.BG.Top:SetFunction(function()    return row.Text.Top() - onePixelScaled end)
        row.BG.Bottom:SetFunction(function() return row.Text.Bottom() + onePixelScaled end)
        row.BG.Depth:SetFunction(function()  return row.Text.Depth() - 1 end)
        ---@diagnostic enable: undefined-field
    end,

    --- Reuses existing rows: each match is assigned to the row at its
    --- ordinal, rows beyond the match count get ordinal = 0 (hidden).
    ---@param self UIChatCommandHintInterface
    ---@param text string
    Refresh = function(self, text)
        local matches = {}
        if text and string.sub(text, 1, 1) == '/' then
            local prefix = string.sub(text, 2)
            local space = string.find(prefix, '%s')
            if space then prefix = string.sub(prefix, 1, space - 1) end

            for _, cmd in ipairs(Registry.FindMatching(prefix)) do
                table.insert(matches, cmd)
            end
        end

        ---@diagnostic disable: undefined-field
        for i, cmd in ipairs(matches) do
            local row = self:GetOrCreateRow(i)
            row.Target = cmd
            row.Text:SetText(FormatCommand(cmd))
            row.Ordinal:Set(i)
        end
        for i = table.getn(matches) + 1, table.getn(self.Rows) do
            local row = self.Rows[i]
            row.Target = nil
            row.Ordinal:Set(0)
        end

        self.VisibleCount:Set(table.getn(matches))

        -- Reset scroll to bottom on every match-set change.
        self.ScrollBottom:Set(1)

        -- Keep the previously-selected ordinal when possible.
        local n = table.getn(matches)
        local cur = self.Selected()
        if n == 0 then
            self.Selected:Set(0)
        elseif cur < 1 or cur > n then
            self.Selected:Set(1)
        else
            -- Ordinal unchanged but the target underneath isn't.
            -- Repaint so colours match the new row assignments.
            self:RepaintRows()
        end

        self:UpdateRowVisibility()
        ---@diagnostic enable: undefined-field
    end,

    --- Registers a callback to fire when a row is committed (Tab or click).
    ---@param self UIChatCommandHintInterface
    ---@param callback fun(cmd: UIChatCommand)
    SetOnSelect = function(self, callback)
        self.OnSelect = callback
    end,
}
