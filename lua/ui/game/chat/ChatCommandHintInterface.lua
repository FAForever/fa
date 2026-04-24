
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Create = import("/lua/lazyvar.lua").Create

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local Registry = import("/lua/ui/game/chat/commands/ChatCommandRegistry.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

local RowFontSize = 12
local RowFontName = 'Arial'
local HorizontalPadding = 12
local VerticalPadding  = 2

--- Renders a command the same way `/help` does: name, params, aliases, description.
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
-- Command-hint popup. Shows commands whose name or aliases prefix-match the
-- user's input. Reuses a pool of row controls across refreshes — entries are
-- shown/hidden and re-positioned via a per-row `ordinal` LazyVar rather than
-- rebuilt from scratch.

---@class UIChatHintRow
---@field Text    Text
---@field BG      Bitmap
---@field Ordinal LazyVar<number>            # 0 = hidden, 1 = bottom row, growing upward
---@field Target  UIChatCommand | nil
---@field Hovered boolean
---@field Paint   fun()                       # re-applies BG solid-colour from Hovered + owner.Selected

---@class UIChatCommandHintInterface : Group
---@field Edit         Edit
---@field OnSelect?    fun(cmd: UIChatCommand)
---@field Rows         UIChatHintRow[]        # reusable pool, indexed by ordinal
---@field Background   Bitmap                 # solid backdrop covering the whole popup
---@field RowHeight    LazyVar<number>
---@field VisibleCount LazyVar<number>
---@field Selected     LazyVar<number>        # 0 = no selection, 1..VisibleCount = row ordinal
---@field LastText     string
---@field LTBG Bitmap
---@field RTBG Bitmap
---@field RBBG Bitmap
---@field RLBG Bitmap
---@field LBG  Bitmap
---@field RBG  Bitmap
---@field TBG  Bitmap
---@field BBG  Bitmap
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

        -- Solid backdrop so the tiny per-row highlight bitmaps (which only
        -- span Text.Top-1..Text.Bottom+1) don't leave visible gaps between
        -- rows. The row BGs now sit transparent on top of this for hover /
        -- selection highlighting.
        self.Background = Bitmap(self)
        self.Background:SetSolidColor('ff000000')
        self.Background:DisableHitTest()

        -- Sample the row height from a throwaway Text.
        ---@diagnostic disable-next-line: param-type-mismatch
        local probe = UIUtil.CreateText(self, '/sample', RowFontSize, RowFontName)
        ---@diagnostic disable-next-line: undefined-field
        self.RowHeight = Create(probe.Height() + VerticalPadding)
        probe:Destroy()

        -- Decorative borders (same skin as ChatListInterface).
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

        -- Repaint highlighted rows when the selection moves. We own `Selected`
        -- so binding its OnDirty directly is safe (see CLAUDE.md §LazyVar).
        self.Selected.OnDirty = function() self:RepaintRows() end
    end,

    ---@param self UIChatCommandHintInterface
    ---@param parent Control
    __post_init = function(self, parent)
        -- Width: fit the widest fully-formatted row (/name <params> (aka …) — desc)
        -- so the popup doesn't reflow horizontally as rows change.
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

        Layouter(self)
            :Width(textWidth + HorizontalPadding * 2)
            :End()

        ---@diagnostic disable: undefined-field
        self.Height:SetFunction(function()
            return self.VisibleCount() * self.RowHeight()
        end)

        -- Unified backdrop covers the entire popup. Rows are transparent by
        -- default and only paint when hovered or selected, so the backdrop
        -- fills the slivers between row highlight strips.
        self.Background.Left:SetFunction(function()   return self.Left() end)
        self.Background.Right:SetFunction(function()  return self.Right() end)
        self.Background.Top:SetFunction(function()    return self.Top() end)
        self.Background.Bottom:SetFunction(function() return self.Bottom() end)
        self.Background.Depth:SetFunction(function()  return self.Depth() end)

        -- Borders hug the outside of self on all eight sides.
        Layouter(self.LTBG):Right(self.Left):Bottom(self.Top):End()
        Layouter(self.RTBG):Left(self.Right):Bottom(self.Top):End()
        Layouter(self.RBBG):Left(self.Right):Top(self.Bottom):End()
        Layouter(self.RLBG):Right(self.Left):Top(self.Bottom):End()
        Layouter(self.LBG):Right(self.Left):Top(self.Top):Bottom(self.Bottom):End()
        Layouter(self.RBG):Left(self.Right):Top(self.Top):Bottom(self.Bottom):End()
        Layouter(self.TBG):Left(self.Left):Right(self.Right):Bottom(self.Top):End()
        Layouter(self.BBG):Left(self.Left):Right(self.Right):Top(self.Bottom):End()
        ---@diagnostic enable: undefined-field
    end,

    --- Builds a reusable row (text + highlight bitmap + hover handler).
    --- The row is laid out lazily by `LayoutRow` / `LayoutRowBackground`.
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

    --- Repaints every row to reflect the current `Selected` ordinal. Called
    --- from the Selected observer and whenever Refresh rebuilds the list.
    ---@param self UIChatCommandHintInterface
    RepaintRows = function(self)
        for _, row in pairs(self.Rows) do
            if row.Paint then row.Paint() end
        end
    end,

    --- Wraps `Selected` to the next visible dynamic row. No-op when there
    --- are no matches.
    ---@param self UIChatCommandHintInterface
    SelectNext = function(self)
        local n = self.VisibleCount()
        if n <= 0 then return end
        local cur = self.Selected()
        self.Selected:Set(cur >= n and 1 or cur + 1)
    end,

    --- Wraps `Selected` to the previous visible dynamic row. No-op when
    --- there are no matches.
    ---@param self UIChatCommandHintInterface
    SelectPrev = function(self)
        local n = self.VisibleCount()
        if n <= 0 then return end
        local cur = self.Selected()
        self.Selected:Set(cur <= 1 and n or cur - 1)
    end,

    --- Returns the currently-selected command, or nil when nothing matches.
    ---@param self UIChatCommandHintInterface
    ---@return UIChatCommand?
    GetSelected = function(self)
        local ord = self.Selected()
        if ord <= 0 then return nil end
        local row = self.Rows[ord]
        return row and row.Target or nil
    end,

    --- Lazily pulls a dynamic row out of the pool, creating it if needed and
    --- wiring its position binding to its own ordinal LazyVar.
    ---@param self UIChatCommandHintInterface
    ---@param idx number
    ---@return UIChatHintRow
    GetOrCreateRow = function(self, idx)
        local existing = self.Rows[idx]
        if existing then return existing end

        local row = self:BuildRow()
        self.Rows[idx] = row

        ---@diagnostic disable: undefined-field
        row.Text.Left:SetFunction(function() return self.Left() + HorizontalPadding end)
        row.Text.Bottom:SetFunction(function()
            local ord = row.Ordinal()
            if ord <= 0 then return self.Top() end
            return self.Bottom() - (ord - 1) * self.RowHeight()
        end)
        ---@diagnostic enable: undefined-field

        self:LayoutRowBackground(row)
        return row
    end,

    --- Binds the row's highlight bitmap to span the popup width at the row's
    --- vertical position, one depth below the text so clicks hit the bitmap.
    ---@param self UIChatCommandHintInterface
    ---@param row UIChatHintRow
    LayoutRowBackground = function(self, row)
        ---@diagnostic disable: undefined-field
        row.BG.Left:SetFunction(function()   return self.Left() end)
        row.BG.Right:SetFunction(function()  return self.Right() end)
        row.BG.Top:SetFunction(function()    return row.Text.Top() - 1 end)
        row.BG.Bottom:SetFunction(function() return row.Text.Bottom() + 1 end)
        row.BG.Depth:SetFunction(function()  return row.Text.Depth() - 1 end)
        ---@diagnostic enable: undefined-field
    end,

    --- Updates the popup to reflect the current edit-box text. Reuses existing
    --- rows: each matching command is assigned to the row at its ordinal, and
    --- rows beyond the match count are hidden (ordinal = 0).
    ---@param self UIChatCommandHintInterface
    ---@param text string
    Refresh = function(self, text)
        local matches = {}
        if text and string.sub(text, 1, 1) == '/' then
            local prefix = string.sub(text, 2)
            -- Only the first word is the command name.
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
            row.Text:Show()
            row.BG:Show()
            row.Ordinal:Set(i)
        end
        for i = table.getn(matches) + 1, table.getn(self.Rows) do
            local row = self.Rows[i]
            row.Target = nil
            row.Text:Hide()
            row.BG:Hide()
            row.Ordinal:Set(0)
        end

        self.VisibleCount:Set(table.getn(matches))

        -- Keep the previously-selected ordinal when possible; otherwise land
        -- on the first match (or clear the selection when nothing matches).
        local n = table.getn(matches)
        local cur = self.Selected()
        if n == 0 then
            self.Selected:Set(0)
        elseif cur < 1 or cur > n then
            self.Selected:Set(1)
        else
            -- Ordinal is unchanged but the target underneath probably isn't —
            -- force a repaint so colors match the new row assignments.
            self:RepaintRows()
        end
        ---@diagnostic enable: undefined-field
    end,

    --- Registers the callback invoked when the user clicks a hint row.
    ---@param self UIChatCommandHintInterface
    ---@param callback fun(cmd: UIChatCommand)
    SetOnSelect = function(self, callback)
        self.OnSelect = callback
    end,
}
