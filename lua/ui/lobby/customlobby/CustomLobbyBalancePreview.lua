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

-- The auto-balance **preview**: a host-only modal that shows the proposed two-team split (and the
-- resulting match quality) BEFORE anything is re-seated, with Apply / Cancel — so the host commits a
-- balance on purpose (USER_STORIES § R: "an opti team preview"). It is a transient picker, owns no
-- synced state: it reads the current lobby snapshot, runs the pure CustomLobbyBalancer kernel, and on
-- Apply hands the proposed arrangement to the host-authoritative `RequestApplyBalance` intent.
--
-- The body is rendered as **rank-matched pair rows** (row k = the k-th strongest of each side, who
-- face off), so the host reads the proposal the way the game plays out: each row shows the two players
-- and the rating gap between them (colour-coded), with players that *move* from their current seat in
-- gold and host-*locked* players in blue. The summary reports per-team average + total, the match
-- quality "before -> after", the predicted win split, and the rating delta — enough to judge a balance
-- at a glance and re-roll (Retry) until it reads well.
--
-- Built to the preset dialog's shape (areas layout, three-phase init, Popup singleton).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup

local CustomLobbySlotsDerivedModel = import("/lua/ui/lobby/customlobby/models/derived/customlobbyslotsderivedmodel.lua")
local CustomLobbyBalancer = import("/lua/ui/lobby/customlobby/customlobbybalancer.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

local Debug = false

local DialogWidth = 540
local DialogHeight = 420
local Pad = 12
local TitleHeight = 30
local HeaderHeight = 22
local StatusHeight = 24
local ActionHeight = 52
local RowHeight = 22
local MaxRows = 8           -- binary AutoTeams on a 16-spawn map is at most 8 per side
local ButtonGap = 8

local LabelColor = 'ffc8ccd0'  -- a player that stays where it is
local MoveColor = 'ffe6c64f'   -- a player the balance moves (gold)
local LockColor = 'ff7fb2ff'   -- a host-locked player, pinned in place (blue)
local HeaderColor = 'ffd9c97a'
local MutedColor = 'ff8c9096'

local GapLowColor = 'ff66bb66'   -- a close pair
local GapMidColor = 'ffd9c97a'   -- a noticeable gap
local GapHighColor = 'ffcc6666'  -- a lopsided pair

--- Creates an invisible layout area (tinted while Debug is on).
---@param parent Control
---@param name string
---@param color string
---@return Group
local function CreateArea(parent, name, color)
    local area = Group(parent, name)
    local bg = Bitmap(area)
    bg:SetSolidColor(color)
    bg:SetAlpha(Debug and 0.18 or 0.0)
    bg:DisableHitTest()
    Layouter(bg):Fill(area):End()
    return area
end

--- Gathers the current lobby snapshot and runs the balancer. Reads the models (a transient picker
--- may); the kernel itself stays pure.
---@return UICustomLobbyBalancePlan
local function ComputeForCurrentLobby()
    -- the slots derived model already resolved every seat (player / side / locked / closed) and the
    -- team aggregate (mode / labels / resolved), so the balancer reads that snapshot directly
    return CustomLobbyBalancer.BuildPlan(
        CustomLobbySlotsDerivedModel.GetSlots(),
        CustomLobbySlotsDerivedModel.GetTeams())
end

--- "Name  ·  1850" for a player (rating omitted when unrated / AI). `mirror` reverses it to
--- "1850  ·  Name" so the right column faces the left — the name stays on the outer edge and the
--- rating reads inward toward the centre gap, exactly like the mirrored slot cards.
---@param player UICustomLobbyBalancePlayer
---@param mirror boolean
---@return string
local function FormatPlayer(player, mirror)
    if player.pl > 0 then
        if mirror then
            return tostring(player.pl) .. "  ·  " .. player.name
        end
        return player.name .. "  ·  " .. tostring(player.pl)
    end
    return player.name
end

--- The display colour for a player row: blue = host-locked (pinned), gold = moved by the balance,
--- grey = unchanged. Locked wins (a locked player never moves, so it can't also read as a mover).
---@param player UICustomLobbyBalancePlayer
---@return string
local function PlayerColor(player)
    if player.locked then
        return LockColor
    elseif player.moved then
        return MoveColor
    end
    return LabelColor
end

--- Colour for a pair's rating gap: green close, amber noticeable, red lopsided.
---@param gap number
---@return string
local function GapColor(gap)
    if gap < 100 then
        return GapLowColor
    elseif gap < 250 then
        return GapMidColor
    end
    return GapHighColor
end

---@class UICustomLobbyBalanceRow
---@field Group  Group
---@field Left   Text
---@field Center Text
---@field Right  Text

---@class UICustomLobbyBalancePreview : Group
---@field Trash TrashBag
---@field OnCloseCb fun()
---@field Result UICustomLobbyBalancePlan
---@field TitleArea Group
---@field HeaderArea Group
---@field RowsArea Group
---@field StatusArea Group
---@field ActionArea Group
---@field Title Text
---@field HeaderA Text
---@field HeaderB Text
---@field Rows UICustomLobbyBalanceRow[]
---@field Status Text
---@field ApplyButton Button
---@field RetryButton Button
---@field CancelButton Button
---@field Ready boolean
local CustomLobbyBalancePreview = ClassUI(Group) {

    ---@param self UICustomLobbyBalancePreview
    ---@param parent Control
    ---@param options { onClose: fun() }
    __init = function(self, parent, options)
        Group.__init(self, parent, "CustomLobbyBalancePreview")

        self.Trash = TrashBag()
        self.OnCloseCb = options.onClose
        self.Ready = false

        -- compute the proposal up front (pure read of the current snapshot; no layout involved)
        self.Result = ComputeForCurrentLobby()

        self.TitleArea = CreateArea(self, "TitleArea", 'ffcc4040')
        self.HeaderArea = CreateArea(self, "HeaderArea", 'ff4060cc')
        self.RowsArea = CreateArea(self, "RowsArea", 'ff406060')
        self.StatusArea = CreateArea(self, "StatusArea", 'ffcc40cc')
        self.ActionArea = CreateArea(self, "ActionArea", 'ff808080')

        self.Title = UIUtil.CreateText(self.TitleArea, "Balance preview", 22, UIUtil.titleFont)
        self.Title:DisableHitTest()

        local labels = self.Result.labels or { "Team 1", "Team 2" }
        self.HeaderA = UIUtil.CreateText(self.HeaderArea, labels[1], 14, UIUtil.titleFont)
        self.HeaderA:SetColor(HeaderColor)
        self.HeaderA:DisableHitTest()
        self.HeaderB = UIUtil.CreateText(self.HeaderArea, labels[2], 14, UIUtil.titleFont)
        self.HeaderB:SetColor(HeaderColor)
        self.HeaderB:DisableHitTest()

        -- a fixed pool of pair rows; Render shows/hides + fills them from the proposal
        self.Rows = {}
        for i = 1, MaxRows do
            local row = Group(self.RowsArea, "BalanceRow" .. i)
            local left = UIUtil.CreateText(row, "", 14, UIUtil.bodyFont)
            left:DisableHitTest()
            local center = UIUtil.CreateText(row, "", 12, UIUtil.bodyFont)
            center:SetColor(MutedColor)
            center:DisableHitTest()
            local right = UIUtil.CreateText(row, "", 14, UIUtil.bodyFont)
            right:DisableHitTest()
            self.Rows[i] = { Group = row, Left = left, Center = center, Right = right }
        end

        self.Status = UIUtil.CreateText(self.StatusArea, "", 14, UIUtil.bodyFont)
        self.Status:SetColor(LabelColor)
        self.Status:DisableHitTest()

        self.ApplyButton = UIUtil.CreateButtonWithDropshadow(self.ActionArea, '/BUTTON/medium/', "Apply")
        self.ApplyButton.OnClick = function()
            self:ApplyAndClose()
        end

        -- re-roll the proposal: the balance is randomised (tie-breaks, and the positional mirrored-pair
        -- seating), so Retry recomputes for a different equally-good arrangement without committing
        self.RetryButton = UIUtil.CreateButtonWithDropshadow(self.ActionArea, '/BUTTON/medium/', "Retry")
        self.RetryButton.OnClick = function()
            self:Retry()
        end

        self.CancelButton = UIUtil.CreateButtonWithDropshadow(self.ActionArea, '/BUTTON/medium/', "<LOC _Cancel>Cancel")
        self.CancelButton.OnClick = function()
            self.OnCloseCb()
        end
    end,

    ---@param self UICustomLobbyBalancePreview
    __post_init = function(self)
        self.Width:Set(LayoutHelpers.ScaleNumber(DialogWidth))
        self.Height:Set(LayoutHelpers.ScaleNumber(DialogHeight))

        Layouter(self.TitleArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AtTopIn(self, Pad):Height(TitleHeight):End()
        Layouter(self.HeaderArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AnchorToBottom(self.TitleArea, Pad):Height(HeaderHeight):End()
        Layouter(self.ActionArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AtBottomIn(self, Pad):Height(ActionHeight):End()
        Layouter(self.StatusArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AnchorToTop(self.ActionArea, Pad):Height(StatusHeight):End()
        Layouter(self.RowsArea)
            :AtLeftIn(self, Pad):AtRightIn(self, Pad)
            :AnchorToBottom(self.HeaderArea, Pad):AnchorToTop(self.StatusArea, Pad)
            :End()

        Layouter(self.Title):AtHorizontalCenterIn(self.TitleArea):AtVerticalCenterIn(self.TitleArea):End()

        Layouter(self.HeaderA):AtLeftIn(self.HeaderArea):AtVerticalCenterIn(self.HeaderArea):End()
        Layouter(self.HeaderB):AtRightIn(self.HeaderArea):AtVerticalCenterIn(self.HeaderArea):End()

        -- stack the pair rows from the top of the rows area
        for i = 1, MaxRows do
            local row = self.Rows[i]
            Layouter(row.Group):AtLeftIn(self.RowsArea):AtRightIn(self.RowsArea):Height(RowHeight):End()
            if i == 1 then
                Layouter(row.Group):AtTopIn(self.RowsArea):End()
            else
                Layouter(row.Group):AnchorToBottom(self.Rows[i - 1].Group, 0):End()
            end
            Layouter(row.Left):AtLeftIn(row.Group):AtVerticalCenterIn(row.Group):End()
            Layouter(row.Center):AtHorizontalCenterIn(row.Group):AtVerticalCenterIn(row.Group):End()
            Layouter(row.Right):AtRightIn(row.Group):AtVerticalCenterIn(row.Group):End()
        end

        Layouter(self.Status):AtLeftIn(self.StatusArea):AtVerticalCenterIn(self.StatusArea):End()

        Layouter(self.CancelButton):AtRightIn(self.ActionArea):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.ApplyButton):AnchorToLeft(self.CancelButton, ButtonGap):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.RetryButton):AnchorToLeft(self.ApplyButton, ButtonGap):AtVerticalCenterIn(self.ActionArea):End()
    end,

    --- Post-mount render (the opener calls this after Popup centres the dialog, so the rows read
    --- concrete geometry).
    ---@param self UICustomLobbyBalancePreview
    Initialize = function(self)
        self.Ready = true
        self:Render()
    end,

    --- The per-team header: "label   total (avg avg)", mirrored on the right side ("total (avg avg)
    --- label") so the team label stays on the outer edge of its column.
    ---@param self UICustomLobbyBalancePreview
    ---@param side 1 | 2
    ---@return string
    SideHeader = function(self, side)
        local result = self.Result
        local labels = result.labels or { "Team 1", "Team 2" }
        local count = table.getn(result.sides[side])
        local total = result.totals[side]
        local avg = count > 0 and math.floor(total / count + 0.5) or 0
        local stats = tostring(total) .. " (" .. tostring(avg) .. " avg)"
        if side == 2 then
            return stats .. "   " .. labels[side]
        end
        return labels[side] .. "   " .. stats
    end,

    --- Fills one pair row from the k-th players of each side (either may be absent on an uneven split).
    ---@param self UICustomLobbyBalancePreview
    ---@param row UICustomLobbyBalanceRow
    ---@param a UICustomLobbyBalancePlayer | nil
    ---@param b UICustomLobbyBalancePlayer | nil
    FillRow = function(self, row, a, b)
        row.Group:Show()
        if a then
            row.Left:SetText(FormatPlayer(a, false))
            row.Left:SetColor(PlayerColor(a))
        else
            row.Left:SetText("")
        end
        if b then
            row.Right:SetText(FormatPlayer(b, true))
            row.Right:SetColor(PlayerColor(b))
        else
            row.Right:SetText("")
        end
        -- the pair's rating gap, only when both players are rated
        if a and b and a.pl > 0 and b.pl > 0 then
            local gap = math.abs(a.pl - b.pl)
            row.Center:SetText("+" .. tostring(gap))
            row.Center:SetColor(GapColor(gap))
        else
            row.Center:SetText("")
        end
    end,

    --- Paints the pair rows + the summary line from the computed proposal, and enables Apply only when
    --- there is something to apply.
    ---@param self UICustomLobbyBalancePreview
    Render = function(self)
        local result = self.Result

        self.HeaderA:SetText(self:SideHeader(1))
        self.HeaderB:SetText(self:SideHeader(2))

        local rowCount = math.max(table.getn(result.sides[1]), table.getn(result.sides[2]))
        for i = 1, MaxRows do
            local row = self.Rows[i]
            if i <= rowCount then
                self:FillRow(row, result.sides[1][i], result.sides[2][i])
            else
                row.Group:Hide()
            end
        end

        self.Status:SetText(self:StatusLine())

        if result.feasible then
            self.ApplyButton:Enable()
            self.RetryButton:Enable()
        else
            self.ApplyButton:Disable()
            self.RetryButton:Disable()
        end
    end,

    --- The summary: the reason it can't balance, else "Quality before -> after · Win a/b · Δ delta",
    --- plus any odd one left out.
    ---@param self UICustomLobbyBalancePreview
    ---@return string
    StatusLine = function(self)
        local result = self.Result
        if result.reason then
            return result.reason
        end

        -- match quality, as "current -> proposed" when both are known
        local quality
        if result.quality and result.currentQuality then
            quality = "Quality " .. tostring(result.currentQuality) .. "% -> " .. tostring(result.quality) .. "%"
        elseif result.quality then
            quality = "Quality " .. tostring(result.quality) .. "%"
        else
            quality = "Quality n/a"
        end

        local status = quality
        if result.winChance then
            status = status .. "   ·   Win " .. tostring(result.winChance[1]) .. "% / " .. tostring(result.winChance[2]) .. "%"
        end
        status = status .. "   ·   Gap " .. tostring(math.abs(result.totals[1] - result.totals[2]))
        if result.unassigned then
            status = status .. "   ·   " .. result.unassigned.name .. " stays put (odd count)"
        end
        return status
    end,

    --- Re-rolls the proposal (the balance is randomised) and re-renders, without committing.
    ---@param self UICustomLobbyBalancePreview
    Retry = function(self)
        self.Result = ComputeForCurrentLobby()
        self:Render()
    end,

    --- Commits the proposed arrangement (host-authoritative) and closes.
    ---@param self UICustomLobbyBalancePreview
    ApplyAndClose = function(self)
        if self.Result.feasible then
            CustomLobbyController.RequestApplyBalance(CustomLobbyBalancer.ToArrangement(self.Result))
        end
        self.OnCloseCb()
    end,

    ---@param self UICustomLobbyBalancePreview
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

-------------------------------------------------------------------------------
--#region Singleton + open / close

---@type Popup | false
local Instance = false

--- Opens the balance preview over `parent` (host-only entry point — the slots header's balance button).
---@param parent? Control
function Open(parent)
    parent = parent or GetFrame(0)

    if Instance then
        Instance:Close()
    end

    local popup
    local content = CustomLobbyBalancePreview(parent, {
        onClose = function()
            if popup then
                popup:Close()
            end
        end,
    })

    popup = Popup(parent, content)
    local baseOnClosed = popup.OnClosed
    popup.OnClosed = function(self)
        baseOnClosed(self)
        Instance = false
    end
    Instance = popup

    -- Popup has mounted + centred the content; now it's safe to populate the rows
    content:Initialize()
end

--- Closes the dialog if open.
function Close()
    if Instance then
        Instance:Close()
        Instance = false
    end
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    Close()
end

--#endregion
