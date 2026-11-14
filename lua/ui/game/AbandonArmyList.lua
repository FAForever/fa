--******************************************************************************************************
--** A scrollable list of allied armies with a single selection, used to choose who receives an
--** abandoned army. Each row shows a radio button, the faction badge in the army color, the rating
--** and the name. The whole row is clickable. Excluded armies are listed last, greyed out, struck
--** through and can't be selected.
--******************************************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Layouter = LayoutHelpers.ReusedLayoutFor
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local ChatFactionBadge = import("/lua/ui/game/chat/ChatFactionBadge.lua").ChatFactionBadge
local Tooltip = import("/lua/ui/game/tooltip.lua")

local RowHeight = 26
local RowSpacing = 3

---@class AbandonArmyListEntry
---@field Army number
---@field Name string
---@field Rating? number    # nil when unknown
---@field Faction number    # 0-based faction index
---@field Color string      # army color
---@field Excluded? boolean # listed last and can't be selected
---@field Score? number

---@class AbandonArmyListRow : Bitmap
---@field Radio Checkbox
---@field Badge ChatFactionBadge
---@field Rating Text
---@field Name Text
---@field Strike Bitmap
---@field Entry? AbandonArmyListEntry

---@class AbandonArmyList : Group
---@field Entries AbandonArmyListEntry[]
---@field Selected? number
---@field TopIndex number          # index of the first visible entry, 0-based
---@field Rows AbandonArmyListRow[]
---@field Scrollbar Scrollbar
---@field ExcludedTitle string
---@field ExcludedText string
---@field OnSelect? fun(self: AbandonArmyList, army: number)
AbandonArmyList = ClassUI(Group) {

    ---@param self AbandonArmyList
    ---@param parent Control
    ---@param entries AbandonArmyListEntry[] # selectable entries first
    ---@param selected? number
    __init = function(self, parent, entries, selected)
        Group.__init(self, parent, "AbandonArmyList")
        self.Entries = entries
        self.Selected = selected
        self.TopIndex = 0
        self.Rows = {}
        self.ExcludedTitle = LOC("<LOC abandon_forwarded_title>Already passed on")
        self.ExcludedText = LOC("<LOC abandon_forwarded_text>This player already passed this army on, so it can't go back to them.")
        -- inside the list, on the right of the rows
        self.Scrollbar = UIUtil.CreateLobbyVertScrollbar(self, -20)
    end,

    --- Creates as many row controls as fit in the current height, then fills them. Call it after
    --- the list is laid out and whenever its height changes.
    ---@param self AbandonArmyList
    Refresh = function(self)
        local fit = math.max(1, math.floor((self.Height() + LayoutHelpers.ScaleNumber(RowSpacing)) / LayoutHelpers.ScaleNumber(RowHeight + RowSpacing)))
        local count = math.min(fit, table.getn(self.Entries))

        -- the scrollbar sits inside the list on the right when not all entries fit
        local scrolls = table.getn(self.Entries) > count
        local rightPadding = scrolls and 22 or 0

        while table.getn(self.Rows) < count do
            table.insert(self.Rows, self:CreateRow(table.getn(self.Rows)))
        end
        while table.getn(self.Rows) > count do
            table.remove(self.Rows):Destroy()
        end
        for _, row in self.Rows do
            Layouter(row):AtRightIn(self, rightPadding):End()
        end

        if scrolls then
            self.Scrollbar:Show()
        else
            self.Scrollbar:Hide()
        end

        self:ScrollSetTop(nil, self.TopIndex)
        self:CalcVisible()
    end,

    ---@param self AbandonArmyList
    ---@param index number # 0-based position from the top
    ---@return AbandonArmyListRow
    CreateRow = function(self, index)
        local row = Bitmap(self) --[[@as AbandonArmyListRow]]
        Layouter(row)
            :AtLeftIn(self)
            :AtTopIn(self, index * (RowHeight + RowSpacing))
            :Height(RowHeight)
            :End()

        -- the row takes the clicks: the radio button only shows the state
        row.Radio = UIUtil.CreateCheckboxStd(row, '/dialogs/check-box_btn/radio')
        Layouter(row.Radio):AtLeftIn(row, 4):AtVerticalCenterIn(row):DisableHitTest():End()

        row.Badge = ChatFactionBadge(row)
        Layouter(row.Badge):RightOf(row.Radio, 6):AtVerticalCenterIn(row):Width(18):Height(18):DisableHitTest():End()

        row.Rating = UIUtil.CreateText(row, "", 13, UIUtil.bodyFont)
        Layouter(row.Rating):AtVerticalCenterIn(row):DisableHitTest()
            :Right(function() return row.Badge.Right() + LayoutHelpers.ScaleNumber(44) end):End()

        row.Name = UIUtil.CreateText(row, "", 14, UIUtil.bodyFont)
        Layouter(row.Name):RightOf(row.Badge, 52):AtVerticalCenterIn(row):DisableHitTest():End()

        row.Strike = Bitmap(row)
        row.Strike:SetSolidColor("ff808080")
        Layouter(row.Strike):AtVerticalCenterIn(row.Name):Height(1)
            :Left(function() return row.Name.Left() end)
            :Right(function() return row.Name.Right() end)
            :Over(row.Name, 1):DisableHitTest():End()

        row.HandleEvent = function(control, event)
            local entry = control.Entry
            if not entry then
                return false
            end
            if event.Type == "WheelRotation" then
                self:ScrollLines(nil, event.WheelRotation > 0 and -1 or 1)
                return true
            elseif event.Type == "ButtonPress" and event.Modifiers.Left and not entry.Excluded then
                self:Select(entry.Army)
                return true
            elseif event.Type == "MouseEnter" and entry.Excluded then
                Tooltip.CreateMouseoverDisplay(control, { text = self.ExcludedTitle, body = self.ExcludedText }, nil, true)
            elseif event.Type == "MouseExit" then
                Tooltip.DestroyMouseoverDisplay()
            end
            return false
        end

        return row
    end,

    ---@param self AbandonArmyList
    ---@param army number
    Select = function(self, army)
        self.Selected = army
        self:CalcVisible()
        if self.OnSelect then
            self:OnSelect(army)
        end
    end,

    ---@param self AbandonArmyList
    ---@param entries AbandonArmyListEntry[]
    SetEntries = function(self, entries)
        self.Entries = entries
        local selectedIsValid = false
        for _, entry in entries do
            if entry.Army == self.Selected and not entry.Excluded then
                selectedIsValid = true
            end
        end
        if not selectedIsValid then
            self.Selected = entries[1] and not entries[1].Excluded and entries[1].Army or nil
        end
        self:Refresh()
    end,

    --- Fills the rows with the entries from `Top` on.
    ---@param self AbandonArmyList
    CalcVisible = function(self)
        for i, row in self.Rows do
            local entry = self.Entries[self.TopIndex + i]
            row.Entry = entry
            if not entry then
                row:Hide()
                continue
            end
            row:Show()

            local selected = entry.Army == self.Selected
            row.Radio:SetCheck(selected, true)
            row.Badge:SetFaction(entry.Faction)
            row.Badge:SetColor(entry.Color)
            row.Rating:SetText(entry.Rating and tostring(math.floor(entry.Rating + 0.5)) or "")
            row.Name:SetText(entry.Name)

            if entry.Excluded then
                row:SetSolidColor("33000000")
                row.Name:SetColor("ff808080")
                row.Rating:SetColor("ff808080")
                row.Radio:Disable()
                row.Strike:Show()
            else
                row:SetSolidColor(selected and "ff1d6f42" or "66000000")
                row.Name:SetColor(UIUtil.fontColor)
                row.Rating:SetColor(UIUtil.fontColor)
                row.Radio:Enable()
                row.Strike:Hide()
            end
        end
    end,

    --#region Scrollable interface, used by the scrollbar

    ---@param self AbandonArmyList
    GetScrollValues = function(self, axis)
        local count = table.getn(self.Entries)
        return 0, count, self.TopIndex, math.min(self.TopIndex + table.getn(self.Rows), count)
    end,

    ---@param self AbandonArmyList
    ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.TopIndex + math.floor(delta))
    end,

    ---@param self AbandonArmyList
    ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.TopIndex + math.floor(delta) * table.getn(self.Rows))
    end,

    ---@param self AbandonArmyList
    ScrollSetTop = function(self, axis, top)
        local maxTop = math.max(0, table.getn(self.Entries) - table.getn(self.Rows))
        top = math.max(0, math.min(maxTop, math.floor(top)))
        if top ~= self.TopIndex then
            self.TopIndex = top
            self:CalcVisible()
        end
    end,

    ---@param self AbandonArmyList
    IsScrollable = function(self, axis)
        return true
    end,

    --#endregion
}

--- Height of `count` rows.
---@param count number
---@return number
function HeightForRows(count)
    return LayoutHelpers.ScaleNumber(count * (RowHeight + RowSpacing) - RowSpacing)
end

--- Allies of the focus army that can receive an army, in the order the sim uses by default:
--- rating, then score.
---@param except? number # an army to leave out
---@return AbandonArmyListEntry[]
function GetAllies(except)
    local focus = GetFocusArmy()
    local ratings = SessionGetScenarioInfo().Options.Ratings or {}
    local score = import("/lua/ui/game/score.lua")
    local entries = {}
    for index, info in GetArmiesTable().armiesTable do
        if index ~= focus and index ~= except and not info.outOfGame and not info.civilian and IsAlly(focus, index) then
            table.insert(entries, {
                Army = index,
                Name = info.nickname,
                Rating = ratings[info.nickname],
                Faction = info.faction,
                Color = info.color,
                Score = score.GetArmyScore(index) or 0,
                -- AI and unrated players come after rated players, as in `SimUtils.SortBrainsByRating`
                SortRating = info.human and ratings[info.nickname] or -1000,
            })
        end
    end
    table.sort(entries, function(a, b)
        if a.SortRating ~= b.SortRating then
            return a.SortRating > b.SortRating
        end
        return a.Score > b.Score
    end)
    return entries
end
