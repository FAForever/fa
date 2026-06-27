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

-- The auto-balance **preview**: a host-only modal that proposes a two-team split (and its match
-- quality) BEFORE anything is re-seated, with Apply / Cancel — so the host commits a balance on
-- purpose (USER_STORIES § R). It is also where the host *tunes* the balance with a few clicks.
--
-- It owns a **working state** that nothing synced ever sees until Apply:
--   * `Arrangement` — the proposed seating (slot -> ownerId).
--   * `Locks`       — a working lock set (ownerId -> true), SEEDED from the lobby's real locks but
--                     kept preview-local: toggling one here is just a balancing constraint, never
--                     written back (Cancel discards everything; Apply commits only the seating).
--
-- The body renders as **mirror positions** (row k = the k-th seat on each side, who face off; the
-- right column is mirrored so the teams face each other). Each row shows both players + the rating gap.
-- Three gestures drive it:
--   * **Drag a row** onto another → swap those two positions' pairs (both players move together),
--     so the host arranges which pair spawns where ("D -> A").
--   * **Click a player, then another** → swap just those two (`ScoreArrangement` re-scores, no solve).
--   * **Click a player's lock** → pin / unpin them (the next Retry holds them in place).
-- **Retry** re-solves the unlocked players around the locked ones (`Rebalance`). Moved players are
-- gold, locked players blue. The summary reports per-team total + average, the quality before -> after,
-- the predicted win split and the rating gap.
--
-- Built to the preset dialog's shape (areas layout, three-phase init, Popup singleton).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Dragger = import("/lua/maui/dragger.lua").Dragger
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup

local CustomLobbySlotsDerivedModel = import("/lua/ui/lobby/customlobby/models/derived/customlobbyslotsderivedmodel.lua")
local CustomLobbyBalancer = import("/lua/ui/lobby/customlobby/customlobbybalancer.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

local Debug = false

local DialogWidth = 540
local DialogHeight = 452
local Pad = 12
local TitleHeight = 28
local HintHeight = 16
local HeaderHeight = 22
local StatusHeight = 24
local ActionHeight = 52
local RowHeight = 24
local MaxRows = 8           -- binary AutoTeams on a 16-spawn map is at most 8 per side
local LockSize = 12
local PosLabelWidth = 16
local ButtonGap = 8
local DragThreshold = 5     -- cursor travel (screen px) before a press becomes a drag, not a click

local LabelColor = 'ffc8ccd0'  -- a player that stays where it is
local MoveColor = 'ffe6c64f'   -- a player the balance moves (gold)
local LockColor = 'ff7fb2ff'   -- a host-locked player, pinned in place (blue)
local HeaderColor = 'ffd9c97a'
local MutedColor = 'ff8c9096'
local SelectColor = 'ffffffff' -- swap-selection + drop-target highlight (low alpha)

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

--- The current lobby snapshot the kernel reads (slots + teams aggregate).
---@return UICustomLobbySlot[] slots
---@return UICustomLobbyTeams teams
local function CurrentSnapshot()
    return CustomLobbySlotsDerivedModel.GetSlots(), CustomLobbySlotsDerivedModel.GetTeams()
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

--- The display colour for a player: blue = host-locked (pinned), gold = moved by the balance, grey =
--- unchanged. Locked wins (a locked player never moves, so it can't also read as a mover).
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
---@field Group         Group
---@field DropHighlight Bitmap          # full-row tint while it's a drag drop-target
---@field LeftSelect    Bitmap          # left half: swap-click / drag target + selection highlight
---@field RightSelect   Bitmap
---@field PosLabel      Text            # the position index (1..N)
---@field Left          Text
---@field Center        Text
---@field Right         Text
---@field LeftLock      Bitmap          # left player's lock toggle
---@field RightLock     Bitmap
---@field LeftOwner     UILobbyPeerId | nil   # who is on each half right now (set by Render)
---@field LeftSlot      number | nil
---@field RightOwner    UILobbyPeerId | nil
---@field RightSlot     number | nil

---@class UICustomLobbyBalancePreview : Group
---@field Trash TrashBag
---@field OnCloseCb fun()
---@field Result UICustomLobbyBalancePlan
---@field Arrangement table<number, UILobbyPeerId>        # working seating (slot -> ownerId)
---@field Locks table<UILobbyPeerId, boolean>             # working lock set (preview-local)
---@field SelectedSlot number | nil                       # first half clicked for a swap
---@field SelectedOwner UILobbyPeerId | nil
---@field DragGhost Group | false                         # floating pair label following the cursor mid-drag
---@field TitleArea Group
---@field HintArea Group
---@field HeaderArea Group
---@field RowsArea Group
---@field StatusArea Group
---@field ActionArea Group
---@field Title Text
---@field Hint Text
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
        self.SelectedSlot = nil
        self.SelectedOwner = nil
        self.DragGhost = false

        -- seed the working state from the lobby: a fresh solve honouring the lobby's existing locks
        -- (locks nil -> the kernel reads each seat's own Locked flag), then keep those locks local
        local slots, teams = CurrentSnapshot()
        local plan = CustomLobbyBalancer.BuildPlan(slots, teams)
        self.Result = plan
        self.Arrangement = plan.arrangement
        self.Locks = table.copy(plan.lockedOwners)

        self.TitleArea = CreateArea(self, "TitleArea", 'ffcc4040')
        self.HintArea = CreateArea(self, "HintArea", 'ff404040')
        self.HeaderArea = CreateArea(self, "HeaderArea", 'ff4060cc')
        self.RowsArea = CreateArea(self, "RowsArea", 'ff406060')
        self.StatusArea = CreateArea(self, "StatusArea", 'ffcc40cc')
        self.ActionArea = CreateArea(self, "ActionArea", 'ff808080')

        self.Title = UIUtil.CreateText(self.TitleArea, "Balance preview", 22, UIUtil.titleFont)
        self.Title:DisableHitTest()

        self.Hint = UIUtil.CreateText(self.HintArea,
            "Drag a row to move a pair  ·  click two players to swap  ·  click a lock to pin", 11, UIUtil.bodyFont)
        self.Hint:SetColor(MutedColor)
        self.Hint:DisableHitTest()

        local labels = self.Result.labels or { "Team 1", "Team 2" }
        self.HeaderA = UIUtil.CreateText(self.HeaderArea, labels[1], 14, UIUtil.titleFont)
        self.HeaderA:SetColor(HeaderColor)
        self.HeaderA:DisableHitTest()
        self.HeaderB = UIUtil.CreateText(self.HeaderArea, labels[2], 14, UIUtil.titleFont)
        self.HeaderB:SetColor(HeaderColor)
        self.HeaderB:DisableHitTest()

        -- a fixed pool of interactive position rows; Render shows/hides + fills them from the proposal
        self.Rows = {}
        for i = 1, MaxRows do
            self.Rows[i] = self:CreateRow(self.RowsArea, i)
        end

        self.Status = UIUtil.CreateText(self.StatusArea, "", 14, UIUtil.bodyFont)
        self.Status:SetColor(LabelColor)
        self.Status:DisableHitTest()

        self.ApplyButton = UIUtil.CreateButtonWithDropshadow(self.ActionArea, '/BUTTON/medium/', "Apply")
        self.ApplyButton.OnClick = function()
            self:ApplyAndClose()
        end

        -- re-roll: re-solve the unlocked players around the locked ones, for a different equally-good
        -- arrangement, without committing
        self.RetryButton = UIUtil.CreateButtonWithDropshadow(self.ActionArea, '/BUTTON/medium/', "Retry")
        self.RetryButton.OnClick = function()
            self:Reroll()
        end

        self.CancelButton = UIUtil.CreateButtonWithDropshadow(self.ActionArea, '/BUTTON/medium/', "<LOC _Cancel>Cancel")
        self.CancelButton.OnClick = function()
            self.OnCloseCb()
        end
    end,

    --- Builds one interactive position row: a drop-target tint, two clickable halves (swap-select /
    --- drag start + selection highlight), the position label, the two player texts + the centre gap,
    --- and a lock toggle per side. Handlers read the row's current owner/slot (set by Render), so the
    --- closures stay valid across re-renders.
    ---@param self UICustomLobbyBalancePreview
    ---@param parent Control
    ---@param index number
    ---@return UICustomLobbyBalanceRow
    CreateRow = function(self, parent, index)
        local row = {}
        row.Group = Group(parent, "BalanceRow" .. tostring(index))

        row.DropHighlight = Bitmap(row.Group)
        row.DropHighlight:SetSolidColor(SelectColor)
        row.DropHighlight:SetAlpha(0.0)
        row.DropHighlight:DisableHitTest()

        row.LeftSelect = Bitmap(row.Group)
        row.LeftSelect:SetSolidColor(SelectColor)
        row.LeftSelect:SetAlpha(0.0)
        row.LeftSelect.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' and not event.Modifiers.Right then
                self:BeginRowGesture(index, row.LeftSlot, row.LeftOwner, event)
                return true
            end
            return false
        end

        row.RightSelect = Bitmap(row.Group)
        row.RightSelect:SetSolidColor(SelectColor)
        row.RightSelect:SetAlpha(0.0)
        row.RightSelect.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' and not event.Modifiers.Right then
                self:BeginRowGesture(index, row.RightSlot, row.RightOwner, event)
                return true
            end
            return false
        end

        row.PosLabel = UIUtil.CreateText(row.Group, "", 11, UIUtil.bodyFont)
        row.PosLabel:SetColor(MutedColor)
        row.PosLabel:DisableHitTest()

        row.Left = UIUtil.CreateText(row.Group, "", 14, UIUtil.bodyFont)
        row.Left:DisableHitTest()
        row.Center = UIUtil.CreateText(row.Group, "", 12, UIUtil.bodyFont)
        row.Center:SetColor(MutedColor)
        row.Center:DisableHitTest()
        row.Right = UIUtil.CreateText(row.Group, "", 14, UIUtil.bodyFont)
        row.Right:DisableHitTest()

        row.LeftLock = Bitmap(row.Group)
        row.LeftLock:SetSolidColor(LockColor)
        row.LeftLock:SetAlpha(0.0)
        row.LeftLock.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' and not event.Modifiers.Right then
                self:OnLockToggled(row.LeftOwner)
                return true
            end
            return false
        end

        row.RightLock = Bitmap(row.Group)
        row.RightLock:SetSolidColor(LockColor)
        row.RightLock:SetAlpha(0.0)
        row.RightLock.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' and not event.Modifiers.Right then
                self:OnLockToggled(row.RightOwner)
                return true
            end
            return false
        end

        return row
    end,

    ---@param self UICustomLobbyBalancePreview
    __post_init = function(self)
        self.Width:Set(LayoutHelpers.ScaleNumber(DialogWidth))
        self.Height:Set(LayoutHelpers.ScaleNumber(DialogHeight))

        Layouter(self.TitleArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AtTopIn(self, Pad):Height(TitleHeight):End()
        Layouter(self.HintArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AnchorToBottom(self.TitleArea, 2):Height(HintHeight):End()
        Layouter(self.HeaderArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AnchorToBottom(self.HintArea, Pad):Height(HeaderHeight):End()
        Layouter(self.ActionArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AtBottomIn(self, Pad):Height(ActionHeight):End()
        Layouter(self.StatusArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AnchorToTop(self.ActionArea, Pad):Height(StatusHeight):End()
        Layouter(self.RowsArea)
            :AtLeftIn(self, Pad):AtRightIn(self, Pad)
            :AnchorToBottom(self.HeaderArea, Pad):AnchorToTop(self.StatusArea, Pad)
            :End()

        Layouter(self.Title):AtHorizontalCenterIn(self.TitleArea):AtVerticalCenterIn(self.TitleArea):End()
        Layouter(self.Hint):AtHorizontalCenterIn(self.HintArea):AtVerticalCenterIn(self.HintArea):End()

        Layouter(self.HeaderA):AtLeftIn(self.HeaderArea):AtVerticalCenterIn(self.HeaderArea):End()
        Layouter(self.HeaderB):AtRightIn(self.HeaderArea):AtVerticalCenterIn(self.HeaderArea):End()

        -- stack the position rows from the top of the rows area
        for i = 1, MaxRows do
            local row = self.Rows[i]
            Layouter(row.Group):AtLeftIn(self.RowsArea):AtRightIn(self.RowsArea):Height(RowHeight):End()
            if i == 1 then
                Layouter(row.Group):AtTopIn(self.RowsArea):End()
            else
                Layouter(row.Group):AnchorToBottom(self.Rows[i - 1].Group, 0):End()
            end

            Layouter(row.DropHighlight):Fill(row.Group):End()

            Layouter(row.PosLabel):AtLeftIn(row.Group):AtVerticalCenterIn(row.Group):Width(PosLabelWidth):End()
            Layouter(row.LeftLock):AnchorToRight(row.PosLabel, 2):AtVerticalCenterIn(row.Group)
                :Width(LockSize):Height(LockSize):Over(row.Group, 10):End()
            Layouter(row.RightLock):AtRightIn(row.Group):AtVerticalCenterIn(row.Group)
                :Width(LockSize):Height(LockSize):Over(row.Group, 10):End()

            Layouter(row.Center):AtHorizontalCenterIn(row.Group):AtVerticalCenterIn(row.Group):End()
            Layouter(row.Left):AnchorToRight(row.LeftLock, 6):AtVerticalCenterIn(row.Group):End()
            Layouter(row.Right):AnchorToLeft(row.RightLock, 6):AtVerticalCenterIn(row.Group):End()

            -- the swap-click / drag halves sit above the drop tint but below the texts (which ignore
            -- hits) and stop short of the centre gap; the lock bitmaps sit above them (Over)
            Layouter(row.LeftSelect):AtTopIn(row.Group):AtBottomIn(row.Group)
                :AtLeftIn(row.Group):AnchorToLeft(row.Center, 4):End()
            Layouter(row.RightSelect):AtTopIn(row.Group):AtBottomIn(row.Group)
                :AtRightIn(row.Group):AnchorToRight(row.Center, 4):End()
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

    ---------------------------------------------------------------------------
    --#region Interaction

    --- A press on a row half: it becomes a **drag** (move this whole pair to another position) once the
    --- cursor travels past the threshold, otherwise the release is a **click** (select this player for a
    --- swap). Mirrors the lobby slot rows' press-vs-drag handling.
    ---@param self UICustomLobbyBalancePreview
    ---@param rowIndex number
    ---@param slot number | nil
    ---@param ownerId UILobbyPeerId | nil
    ---@param event KeyEvent
    BeginRowGesture = function(self, rowIndex, slot, ownerId, event)
        local startX, startY = event.MouseX, event.MouseY
        local moved = false

        local drag = Dragger()
        drag.OnMove = function(dragSelf, x, y)
            if not moved and (math.abs(x - startX) > DragThreshold or math.abs(y - startY) > DragThreshold) then
                moved = true
            end
            if moved then
                -- float the pair ghost beside the cursor + highlight the row under it (lobby feel)
                if not self.DragGhost then
                    self.DragGhost = self:CreateDragGhost(rowIndex)
                end
                self.DragGhost.Left:Set(x + LayoutHelpers.ScaleNumber(12))
                self.DragGhost.Top:Set(y + LayoutHelpers.ScaleNumber(8))
                self:SetDropTarget(self:RowIndexAt(y), rowIndex)
            end
        end
        drag.OnRelease = function(dragSelf, x, y)
            if moved then
                local target = self:RowIndexAt(y)
                if target and target ~= rowIndex then
                    self:SwapPositions(rowIndex, target)
                end
            else
                self:OnPlayerClicked(slot, ownerId)
            end
            self:EndDrag()
            drag:Destroy()
        end
        drag.OnCancel = function(dragSelf)
            self:EndDrag()
            drag:Destroy()
        end
        PostDragger(self:GetRootFrame(), event.KeyCode, drag)
    end,

    --- Clears the transient drag visuals (drop highlight + floating ghost).
    ---@param self UICustomLobbyBalancePreview
    EndDrag = function(self)
        self:ClearDropHighlight()
        if self.DragGhost then
            self.DragGhost:Destroy()
            self.DragGhost = false
        end
    end,

    --- Builds the floating drag ghost for a position's pair (both names, the lobby's dark chip), drawn
    --- above the rows and offset from the cursor. Destroyed in EndDrag.
    ---@param self UICustomLobbyBalancePreview
    ---@param index number
    ---@return Group
    CreateDragGhost = function(self, index)
        local position = (self.Result.positions or {})[index]
        local a = position and position.a
        local b = position and position.b
        local name
        if a and b then
            name = a.name .. "   ·   " .. b.name
        elseif a then
            name = a.name
        elseif b then
            name = b.name
        else
            name = "Position " .. tostring(index)
        end

        local ghost = Group(self, "CustomLobbyBalanceDragGhost")
        ghost:DisableHitTest()

        local bg = Bitmap(ghost)
        bg:SetSolidColor('cc101418')
        bg:DisableHitTest()

        local label = UIUtil.CreateText(ghost, name, 14, UIUtil.bodyFont)
        label:DisableHitTest()

        Layouter(label):AtLeftTopIn(ghost, 6, 3):End()
        Layouter(bg):Fill(ghost):End()
        ghost.Width:Set(function() return label.Width() + LayoutHelpers.ScaleNumber(12) end)
        ghost.Height:Set(function() return label.Height() + LayoutHelpers.ScaleNumber(6) end)
        return ghost
    end,

    --- A player half was clicked: select it for a swap, deselect it if it was the selection, or — if
    --- another player is already selected — swap their seats and re-score. Empty halves and locked
    --- players are inert (a locked player is pinned; unlock it first to move it).
    ---@param self UICustomLobbyBalancePreview
    ---@param slot number | nil
    ---@param ownerId UILobbyPeerId | nil
    OnPlayerClicked = function(self, slot, ownerId)
        if not (slot and ownerId) or self.Locks[ownerId] then
            return
        end
        if self.SelectedSlot == slot then
            self.SelectedSlot = nil
            self.SelectedOwner = nil
            self:Render()
        elseif self.SelectedSlot then
            local arrangement = table.copy(self.Arrangement)
            local other = self.SelectedSlot
            arrangement[other], arrangement[slot] = arrangement[slot], arrangement[other]
            self.Arrangement = arrangement
            self.SelectedSlot = nil
            self.SelectedOwner = nil
            self:Rescore()
        else
            self.SelectedSlot = slot
            self.SelectedOwner = ownerId
            self:Render()
        end
    end,

    --- True if either player at position `index` is locked (so that whole row is pinned — it can't be
    --- the source or target of a pair drag; unlock first to move it).
    ---@param self UICustomLobbyBalancePreview
    ---@param index number
    ---@return boolean
    PositionLocked = function(self, index)
        local position = (self.Result.positions or {})[index]
        if not position then
            return false
        end
        return (position.a and position.a.locked or position.b and position.b.locked) and true or false
    end,

    --- Swaps two positions' pairs in the working arrangement: both players of position `i` move to
    --- position `j` and vice versa (sides preserved, so each pair stays together). Refuses if either
    --- row holds a locked player. Re-scores.
    ---@param self UICustomLobbyBalancePreview
    ---@param i number
    ---@param j number
    SwapPositions = function(self, i, j)
        local positions = self.Result.positions
        local pi, pj = positions[i], positions[j]
        if not (pi and pj) or self:PositionLocked(i) or self:PositionLocked(j) then
            return
        end
        local arrangement = table.copy(self.Arrangement)
        if pi.slotA and pj.slotA then
            arrangement[pi.slotA], arrangement[pj.slotA] = arrangement[pj.slotA], arrangement[pi.slotA]
        end
        if pi.slotB and pj.slotB then
            arrangement[pi.slotB], arrangement[pj.slotB] = arrangement[pj.slotB], arrangement[pi.slotB]
        end
        self.Arrangement = arrangement
        self.SelectedSlot = nil
        self.SelectedOwner = nil
        self:Rescore()
    end,

    --- A player's lock was clicked: toggle it in the working set and re-score. The player stays put;
    --- locking just pins them so the next Retry holds them in place (and recolours them blue). Clears
    --- any pending swap selection, since the pinning changed.
    ---@param self UICustomLobbyBalancePreview
    ---@param ownerId UILobbyPeerId | nil
    OnLockToggled = function(self, ownerId)
        if not ownerId then
            return
        end
        local locks = table.copy(self.Locks)
        locks[ownerId] = (not locks[ownerId]) or nil
        self.Locks = locks
        self.SelectedSlot = nil
        self.SelectedOwner = nil
        self:Rescore()
    end,

    --- Re-solves the unlocked players around the locked ones (Retry), adopting a fresh arrangement.
    ---@param self UICustomLobbyBalancePreview
    Reroll = function(self)
        local slots, teams = CurrentSnapshot()
        self:Adopt(CustomLobbyBalancer.Rebalance(slots, teams, self.Arrangement, self.Locks))
    end,

    --- Re-scores the current working arrangement in place (after a swap / drag / lock toggle) — no
    --- re-solve, so the hand-made arrangement is preserved; only the metrics and colours refresh.
    ---@param self UICustomLobbyBalancePreview
    Rescore = function(self)
        local slots, teams = CurrentSnapshot()
        self.Result = CustomLobbyBalancer.ScoreArrangement(slots, teams, self.Arrangement, self.Locks)
        if self.Ready then
            self:Render()
        end
    end,

    --- Adopts a freshly-solved plan as the new working state (clears the swap selection).
    ---@param self UICustomLobbyBalancePreview
    ---@param plan UICustomLobbyBalancePlan
    Adopt = function(self, plan)
        self.Result = plan
        self.Arrangement = plan.arrangement
        self.SelectedSlot = nil
        self.SelectedOwner = nil
        if self.Ready then
            self:Render()
        end
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Drag drop-target

    --- The visible row whose vertical bounds contain screen-y `y`, or nil.
    ---@param self UICustomLobbyBalancePreview
    ---@param y number
    ---@return number | nil
    RowIndexAt = function(self, y)
        local count = table.getn(self.Result.positions or {})
        for i = 1, math.min(count, MaxRows) do
            local group = self.Rows[i].Group
            if y >= group.Top() and y <= group.Bottom() then
                return i
            end
        end
        return nil
    end,

    --- Highlights `target` as the drop row during a drag — nothing if it's the source, invalid, or
    --- either the source or target row is locked (a pinned pair can't move).
    ---@param self UICustomLobbyBalancePreview
    ---@param target number | nil
    ---@param source number
    SetDropTarget = function(self, target, source)
        local droppable = target and target ~= source
            and not self:PositionLocked(source) and not self:PositionLocked(target)
        for i = 1, MaxRows do
            self.Rows[i].DropHighlight:SetAlpha((droppable and target == i) and 0.15 or 0.0)
        end
    end,

    ---@param self UICustomLobbyBalancePreview
    ClearDropHighlight = function(self)
        for i = 1, MaxRows do
            self.Rows[i].DropHighlight:SetAlpha(0.0)
        end
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Rendering

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

    --- Fills one position row from a `UICustomLobbyBalancePosition` (either player may be absent on an
    --- uneven split), and records its slots/owners for the click + drag handlers.
    ---@param self UICustomLobbyBalancePreview
    ---@param row UICustomLobbyBalanceRow
    ---@param position UICustomLobbyBalancePosition
    ---@param index number
    FillRow = function(self, row, position, index)
        row.Group:Show()
        row.PosLabel:SetText(tostring(index))
        local a, b = position.a, position.b
        self:FillHalf(row.Left, row.LeftLock, row.LeftSelect, a, position.slotA, false)
        self:FillHalf(row.Right, row.RightLock, row.RightSelect, b, position.slotB, true)
        row.LeftOwner = a and a.ownerId or nil
        row.LeftSlot = position.slotA
        row.RightOwner = b and b.ownerId or nil
        row.RightSlot = position.slotB

        -- the pair's rating gap, only when both players are rated
        if a and b and a.pl > 0 and b.pl > 0 then
            local gap = math.abs(a.pl - b.pl)
            row.Center:SetText("+" .. tostring(gap))
            row.Center:SetColor(GapColor(gap))
        else
            row.Center:SetText("")
        end
    end,

    --- Paints one half of a row (its text + lock dot + selection highlight) for a player, or clears it
    --- when the half is empty.
    ---@param self UICustomLobbyBalancePreview
    ---@param text Text
    ---@param lock Bitmap
    ---@param select Bitmap
    ---@param player UICustomLobbyBalancePlayer | nil
    ---@param slot number | nil
    ---@param mirror boolean
    FillHalf = function(self, text, lock, select, player, slot, mirror)
        if not player then
            text:SetText("")
            lock:SetAlpha(0.0)
            select:SetAlpha(0.0)
            return
        end
        text:SetText(FormatPlayer(player, mirror))
        text:SetColor(PlayerColor(player))
        -- the lock dot: solid blue when pinned, faint when not (a click toggles it)
        lock:SetSolidColor(player.locked and LockColor or SelectColor)
        lock:SetAlpha(player.locked and 1.0 or 0.25)
        -- highlight the half that is the pending swap selection
        select:SetAlpha(slot == self.SelectedSlot and 0.12 or 0.0)
    end,

    --- Paints the position rows + the summary line from the working plan, and enables Apply / Retry
    --- only when there is something to apply.
    ---@param self UICustomLobbyBalancePreview
    Render = function(self)
        local result = self.Result

        self.HeaderA:SetText(self:SideHeader(1))
        self.HeaderB:SetText(self:SideHeader(2))

        local positions = result.positions or {}
        local rowCount = table.getn(positions)
        for i = 1, MaxRows do
            local row = self.Rows[i]
            if i <= rowCount then
                self:FillRow(row, positions[i], i)
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

    --- The summary: the reason it can't balance, else "Quality before -> after · Win a/b · Gap g",
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

    --#endregion

    --- Commits the working arrangement (host-authoritative) and closes. Locks toggled here are NOT
    --- written back — they were only a balancing constraint for this session.
    ---@param self UICustomLobbyBalancePreview
    ApplyAndClose = function(self)
        if self.Result.feasible then
            CustomLobbyController.RequestApplyBalance(self.Arrangement)
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
