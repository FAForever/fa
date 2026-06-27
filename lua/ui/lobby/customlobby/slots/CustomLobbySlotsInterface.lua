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

-- The slot subsystem's entry point: the "Players" header over the active *layout body*, plus the
-- shared drag coordinator. The composition root mounts this and fills its area with it.
--
-- One layout is alive at a time, picked by the AutoTeams mode: the one-column layout
-- ([onecolumn/CustomLobbyOneColumnSlots](onecolumn/CustomLobbyOneColumnSlots.lua)) for the non-team
-- modes, and the two-column team layout for the binary modes (left/right, top/bottom, even/odd).
-- (The two-column layout + the AutoTeams-driven swap land in the next step; for now it is always
-- one-column.)
--
-- This selector is the rows' **drag coordinator** (`UICustomLobbySlotCoordinator`) for *every*
-- layout, because it alone needs to hit-test across the rows and float the drag ghost — so the
-- layout bodies stay pure "build + place + reveal" and never duplicate the drag logic. Each body is
-- handed this selector as its rows' coordinator and exposes its `Rows` for the hit-test.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/models/customlobbylaunchmodel.lua")
local CustomLobbySessionModel = import("/lua/ui/lobby/customlobby/models/customlobbysessionmodel.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/models/customlobbylocalmodel.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbyRules = import("/lua/ui/lobby/customlobby/customlobbyrules.lua")
local CustomLobbyScenarioDerivedModel = import("/lua/ui/lobby/customlobby/models/derived/customlobbyscenarioderivedmodel.lua")
local CustomLobbySlotsDerivedModel = import("/lua/ui/lobby/customlobby/models/derived/customlobbyslotsderivedmodel.lua")
local CustomLobbyBalancePreview = import("/lua/ui/lobby/customlobby/customlobbybalancepreview.lua")
local CustomLobbyOneColumnSlots = import("/lua/ui/lobby/customlobby/slots/onecolumn/customlobbyonecolumnslots.lua")
local CustomLobbyTwoColumnSlots = import("/lua/ui/lobby/customlobby/slots/twocolumn/customlobbytwocolumnslots.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

local HeaderHeight = 24           -- the "Players" header + gap above the layout body

-- the header tool buttons (right of the "Players" label): small square icon buttons, the same
-- idle/hover/lit look as the config column's preview tools (drift-fine local copy — see CLAUDE.md).
-- The icon (ToolSize - 2*ToolIconInset = 18px) matches the config strip; these textures are full
-- title-bar button glyphs, so anything smaller renders the pin tiny.
local ToolSize = 22
local ToolGap = 4
local ToolIconInset = 2
local ToolIdle = 'ff141a20'
local ToolHover = 'ff1f262e'
local ToolActive = 'ff2c4a5e'        -- a lit toggle's background (pin on)

-- icon textures (skin-relative, resolved through UIFile). The pin uses the window pin-button glyphs
-- (unpinned vs pinned, same as window.lua's title-bar pin); balance the lobby auto-balance button
-- art; reopen the circular recall ("refresh") icon.
local PinIcon = '/game/menu-btns/pin_btn_up.dds'         -- unpinned (toggle off)
local PinnedIcon = '/game/menu-btns/pinned_btn_up.dds'   -- pinned (toggle on / the lock-notice glyph)
local BalanceIcon = '/BUTTON/autobalance/_btn_up.dds'
local ReopenIcon = '/game/recall-panel/icon-recall_bmp.dds'

--- A small square icon button for the header tool strip: a solid background that lights on hover,
--- plus an `Active` state (driven externally for the pin toggle) that lights it the "on" colour. A
--- toggle can pass a second `activeTexture` so the icon glyph swaps while active (the pin shows the
--- unpinned vs pinned art, like the window title-bar pin). Clicking calls `OnPress`; the owner decides
--- what that means (fire an intent, flip a synced flag, …). Mirrors the config column's `PreviewTool`.
---@class UICustomLobbySlotTool : Group
---@field Bg Bitmap
---@field Icon Bitmap
---@field IdleTexture FileName
---@field ActiveTexture FileName | nil
---@field Active boolean
---@field Enabled boolean
---@field Hovered boolean
---@field OnPress? fun()
local SlotTool = Class(Group) {

    ---@param self UICustomLobbySlotTool
    ---@param parent Control
    ---@param texture FileName            # the icon (idle / toggle-off)
    ---@param activeTexture? FileName     # glyph swapped in while Active (toggle-on); omit for plain actions
    __init = function(self, parent, texture, activeTexture)
        Group.__init(self, parent, "CustomLobbySlotTool")

        self.Active = false
        self.Enabled = true
        self.Hovered = false
        self.IdleTexture = texture
        self.ActiveTexture = activeTexture

        self.Bg = Bitmap(self)
        self.Bg:SetSolidColor(ToolIdle)

        self.Icon = UIUtil.CreateBitmap(self, texture)
        self.Icon:DisableHitTest()

        self.Bg.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' then
                if self.Enabled and self.OnPress then
                    self.OnPress()
                end
                return true
            elseif event.Type == 'MouseEnter' then
                self.Hovered = true
                self:ApplyVisual()
                return true
            elseif event.Type == 'MouseExit' then
                self.Hovered = false
                self:ApplyVisual()
                return true
            end
            return false
        end
    end,

    ---@param self UICustomLobbySlotTool
    __post_init = function(self)
        Layouter(self.Bg):Fill(self):End()
        Layouter(self.Icon):AtCenterIn(self):Width(ToolSize - 2 * ToolIconInset):Height(ToolSize - 2 * ToolIconInset):End()
        self:ApplyVisual()
    end,

    --- Repaints the background (idle / hover / lit-when-active) and, for a toggle with an
    --- `ActiveTexture`, swaps the icon glyph for the active/inactive state.
    ---@param self UICustomLobbySlotTool
    ApplyVisual = function(self)
        local bg = ToolIdle
        if self.Enabled then
            if self.Active then
                bg = ToolActive
            elseif self.Hovered then
                bg = ToolHover
            end
        end
        self.Bg:SetSolidColor(bg)
        -- a disabled action reads as greyed: dim its glyph and don't light on hover
        self.Icon:SetAlpha(self.Enabled and 1 or 0.3)
        if self.ActiveTexture then
            self.Icon:SetTexture(UIUtil.UIFile(self.Active and self.ActiveTexture or self.IdleTexture))
        end
    end,

    --- Sets the lit/active state (the pin toggle drives this from the synced model).
    ---@param self UICustomLobbySlotTool
    ---@param active boolean
    SetActive = function(self, active)
        self.Active = active
        self:ApplyVisual()
    end,

    --- Enables or disables the button: a disabled button ignores presses and reads greyed. The
    --- balance button drives this from the seated teams (auto-balance needs exactly two).
    ---@param self UICustomLobbySlotTool
    ---@param enabled boolean
    SetEnabled = function(self, enabled)
        self.Enabled = enabled and true or false
        self:ApplyVisual()
    end,
}

---@alias UICustomLobbySlotsBody UICustomLobbyOneColumnSlots | UICustomLobbyTwoColumnSlots

---@class UICustomLobbySlotsInterface : Group, UICustomLobbySlotCoordinator
---@field Trash TrashBag
---@field Header Text
---@field LockIcon Bitmap                         # lock glyph shown (with LockLabel) while seating is pinned
---@field LockLabel Text                          # "Locked" notice, visible to everyone while pinned
---@field Tools Group                            # host-only tool strip (right of the header)
---@field PinButton UICustomLobbySlotTool
---@field BalanceButton UICustomLobbySlotTool
---@field ReopenButton UICustomLobbySlotTool
---@field Body UICustomLobbySlotsBody | false   # the active layout body
---@field LayoutKind "one" | "two" | false      # which layout Body currently is
---@field Mounted boolean                        # true once __post_init has laid us out
---@field GameOptionsObserver LazyVar
---@field IsHostObserver LazyVar
---@field SlotsPinnedObserver LazyVar
---@field BalanceGateObserver LazyVar
---@field HighlightedSlot number | false         # slot currently shown as a drop target
---@field DragGhost Group | false                # floating label following the cursor mid-drag
local CustomLobbySlotsInterface = Class(Group) {

    ---@param self UICustomLobbySlotsInterface
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbySlotsInterface")

        self.Trash = TrashBag()
        self.HighlightedSlot = false
        self.DragGhost = false
        self.Mounted = false
        self.Body = false
        self.LayoutKind = false

        self.Header = UIUtil.CreateText(self, "Players", 14, UIUtil.titleFont)
        self.Header:SetColor('ff9aa0a8')
        self.Header:DisableHitTest()

        -- lock notice (right of the "Players" label): shown to everyone while seating is pinned, so a
        -- client can see seating is host-controlled before it clicks an open slot to no effect. The
        -- host also has the lit pin button; this reinforces the state for both.
        self.LockIcon = UIUtil.CreateBitmap(self, PinnedIcon)
        self.LockIcon:DisableHitTest()
        self.LockIcon:Hide()
        self.LockLabel = UIUtil.CreateText(self, "Locked", 12, UIUtil.bodyFont)
        self.LockLabel:SetColor('ffd9c97a')
        self.LockLabel:DisableHitTest()
        self.LockLabel:Hide()

        -- host-only tool strip, right-aligned in the header band: pin seating · auto-balance ·
        -- reopen closed slots. Grouped so a single Show/Hide gates them all on host status.
        self.Tools = Group(self, "CustomLobbySlotTools")

        self.PinButton = SlotTool(self.Tools, PinIcon, PinnedIcon)
        self.PinButton.OnPress = function()
            CustomLobbyController.RequestSetSlotsPinned(not CustomLobbySessionModel.GetSingleton().SlotsPinned())
        end
        Tooltip.AddControlTooltipManual(self.PinButton.Bg, "Pin slots",
            "Lock seating so only you (the host) can move players between slots.")

        self.BalanceButton = SlotTool(self.Tools, BalanceIcon)
        self.BalanceButton.OnPress = function()
            CustomLobbyBalancePreview.Open()
        end
        Tooltip.AddControlTooltipManual(self.BalanceButton.Bg, "Auto balance",
            "Preview a balanced two-team split before applying it. Locked players stay put.")

        self.ReopenButton = SlotTool(self.Tools, ReopenIcon)
        self.ReopenButton.OnPress = function()
            CustomLobbyController.RequestReopenClosedSlots()
        end
        Tooltip.AddControlTooltipManual(self.ReopenButton.Bg, "Reopen closed slots",
            "Close, then re-open every closed slot to refresh the lobby for everyone.")

        -- the tool strip is a host action set; hide it for clients
        self.IsHostObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbyLocalModel.GetSingleton().IsHost, function(isHostLazy)
                if isHostLazy() then
                    self.Tools:Show()
                else
                    self.Tools:Hide()
                end
            end))

        -- light the host's pin button and show the (everyone-visible) lock notice while seating is
        -- pinned (synced session state)
        self.SlotsPinnedObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbySessionModel.GetSingleton().SlotsPinned, function(pinnedLazy)
                local pinned = pinnedLazy()
                self.PinButton:SetActive(pinned)
                if pinned then
                    self.LockIcon:Show()
                    self.LockLabel:Show()
                else
                    self.LockIcon:Hide()
                    self.LockLabel:Hide()
                end
            end))

        -- gate the auto-balance button: it needs exactly two sides (see CanAutoBalance). The slots
        -- derived model re-fires on any seating / team / mode / map change, so one subscription covers
        -- every input the gate depends on.
        self.BalanceGateObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbySlotsDerivedModel.GetSlotsVar(), function(slotsLazy)
                slotsLazy()
                self:UpdateBalanceGate()
            end))

        -- the active layout body, picked by the AutoTeams mode (created now, laid out on mount)
        self:RebuildBody()

        -- a binary AutoTeams mode (left/right, top/bottom, even/odd) swaps in the two-column layout;
        -- everything else uses one column
        self.GameOptionsObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbyLaunchModel.GetSingleton().GameOptions, function(lazy)
                lazy()
                self:OnAutoTeamsChanged()
            end))
    end,

    ---@param self UICustomLobbySlotsInterface
    __post_init = function(self)
        Layouter(self.Header):AtLeftIn(self, 4):AtTopIn(self):End()

        -- the lock notice, just right of the "Players" label (hidden unless seating is pinned)
        Layouter(self.LockIcon):CenteredRightOf(self.Header, 8):Width(ToolSize):Height(ToolSize):End()
        Layouter(self.LockLabel):CenteredRightOf(self.LockIcon, 3):End()

        -- the tool strip: a fixed-width band pinned top-right, the three square buttons inside it
        -- laid out right-to-left (Pin · Balance · Reopen, reading left-to-right), centred on the header
        Layouter(self.Tools)
            :AtRightIn(self, 4)
            :AtVerticalCenterIn(self.Header)
            :Width(3 * ToolSize + 2 * ToolGap):Height(ToolSize)
            :End()
        local function placeTool(tool)
            return Layouter(tool):AtTopIn(self.Tools):Width(ToolSize):Height(ToolSize)
        end
        placeTool(self.ReopenButton):AtRightIn(self.Tools):End()
        placeTool(self.BalanceButton):LeftOf(self.ReopenButton, ToolGap):End()
        placeTool(self.PinButton):LeftOf(self.BalanceButton, ToolGap):End()

        self.Mounted = true
        self:LayoutBody()
    end,

    --- Re-evaluates whether auto-balance is offered and (en/dis)ables the button.
    ---@param self UICustomLobbySlotsInterface
    UpdateBalanceGate = function(self)
        self.BalanceButton:SetEnabled(self:CanAutoBalance())
    end,

    --- Auto-balance needs exactly two sides: a binary AutoTeams mode (with its map loaded, for the
    --- positional ones), or — in manual seating — at most two teams in use (no seated player on a
    --- third team, i.e. model Team >= 4). Mirrors the legacy gate.
    ---@param self UICustomLobbySlotsInterface
    ---@return boolean
    CanAutoBalance = function(self)
        local launch = CustomLobbyLaunchModel.GetSingleton()
        local mode = CustomLobbyRules.AutoTeamMode(launch.GameOptions())
        if mode then
            local _, resolved = CustomLobbyRules.BuildSideResolver(mode, CustomLobbyScenarioDerivedModel.GetScenario())
            return resolved
        end
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            local player = launch.Players[slot]()
            if player and player.Team and player.Team >= 4 then
                return false
            end
        end
        return true
    end,

    --- The layout kind the current AutoTeams mode calls for: "two" for a binary team mode, else "one".
    ---@param self UICustomLobbySlotsInterface
    ---@return "one" | "two"
    KindForMode = function(self)
        return CustomLobbyRules.AutoTeamMode(CustomLobbyLaunchModel.GetSingleton().GameOptions()) and "two" or "one"
    end,

    --- (Re)creates the layout body for the current mode, destroying the previous one. Lays it out
    --- immediately when already mounted (a live mode switch); otherwise __post_init lays it out.
    ---@param self UICustomLobbySlotsInterface
    RebuildBody = function(self)
        local kind = self:KindForMode()
        self.LayoutKind = kind
        if self.Body then
            self.Body:Destroy()
        end
        -- the selector is the rows' coordinator regardless of layout (passed as `self`)
        if kind == "two" then
            self.Body = CustomLobbyTwoColumnSlots.Create(self, self)
        else
            self.Body = CustomLobbyOneColumnSlots.Create(self, self)
        end
        if self.Mounted then
            self:LayoutBody()
        end
    end,

    --- Fills the area below the header with the active body.
    ---@param self UICustomLobbySlotsInterface
    LayoutBody = function(self)
        if not self.Body then
            return
        end
        Layouter(self.Body)
            :AtLeftIn(self):AtRightIn(self)
            :AnchorToBottom(self.Header, 4):AtBottomIn(self)
            :End()
    end,

    --- The mode changed: swap the layout body if the kind (one vs two column) flipped. A change
    --- within the same kind (e.g. lvsr→tvsb) is handled by the body's own re-layout.
    ---@param self UICustomLobbySlotsInterface
    OnAutoTeamsChanged = function(self)
        if self:KindForMode() ~= self.LayoutKind then
            self:RebuildBody()
        end
    end,

    --- The (scaled) height the slot area wants: the header plus the active layout's column block.
    --- Computed straight from the mode + model (not the live body) so it re-fires correctly on a mode
    --- swap regardless of observer order. The composition root binds the slot area's height to this.
    ---@param self UICustomLobbySlotsInterface
    ---@return number
    PreferredHeight = function(self)
        local count = CustomLobbySessionModel.GetSingleton().SlotCount()
        local body = self:KindForMode() == "two"
            and CustomLobbyTwoColumnSlots.HeightForCount(count)
            or CustomLobbyOneColumnSlots.HeightForCount(math.max(count, 1))
        return LayoutHelpers.ScaleNumber(HeaderHeight) + body
    end,

    ---------------------------------------------------------------------------
    --#region Slot drag coordination (UICustomLobbySlotCoordinator)
    --
    -- A drop resolves to the RequestSwapSlots intent, host-authoritative; the state here is purely
    -- visual. Rows belong to the active layout body, reached via `self.Body.Rows`.

    --- Only the host can drag, and only a slot that holds a player (you grab a token).
    ---@param self UICustomLobbySlotsInterface
    ---@param slot number
    ---@return boolean
    CanDrag = function(self, slot)
        if not CustomLobbyLocalModel.GetSingleton().IsHost() then
            return false
        end
        return CustomLobbyLaunchModel.GetSingleton().Players[slot]() ~= false
    end,

    --- The active slot whose row contains the screen point, or nil.
    ---@param self UICustomLobbySlotsInterface
    ---@param x number
    ---@param y number
    ---@return number | nil
    SlotIndexAt = function(self, x, y)
        local count = CustomLobbySessionModel.GetSingleton().SlotCount()
        for slot = 1, count do
            local row = self.Body.Rows[slot]
            if row and x >= row.Left() and x <= row.Right() and y >= row.Top() and y <= row.Bottom() then
                return slot
            end
        end
        return nil
    end,

    --- Mid-drag: follow the cursor with the ghost and highlight the row under it.
    ---@param self UICustomLobbySlotsInterface
    ---@param source number
    ---@param x number
    ---@param y number
    OnSlotDragMove = function(self, source, x, y)
        if not self.DragGhost then
            self.DragGhost = self:CreateDragGhost(source)
        end
        self.DragGhost.Left:Set(x + LayoutHelpers.ScaleNumber(12))
        self.DragGhost.Top:Set(y + LayoutHelpers.ScaleNumber(8))
        self:HighlightSlot(self:SlotIndexAt(x, y))
    end,

    --- Drop: swap the source slot with whatever row the cursor is over (a move if it's
    --- empty). Dropping outside any row is a no-op.
    ---@param self UICustomLobbySlotsInterface
    ---@param source number
    ---@param x number
    ---@param y number
    OnSlotDrop = function(self, source, x, y)
        local target = self:SlotIndexAt(x, y)
        if target and target ~= source then
            CustomLobbyController.RequestSwapSlots(source, target)
        end
    end,

    --- Clears the transient drag visuals.
    ---@param self UICustomLobbySlotsInterface
    OnSlotDragEnd = function(self)
        self:HighlightSlot(nil)
        if self.DragGhost then
            self.DragGhost:Destroy()
            self.DragGhost = false
        end
    end,

    --- Moves the drop-target highlight to `slot` (nil clears it).
    ---@param self UICustomLobbySlotsInterface
    ---@param slot number | nil
    HighlightSlot = function(self, slot)
        slot = slot or false
        if self.HighlightedSlot == slot then
            return
        end
        if self.HighlightedSlot and self.Body.Rows[self.HighlightedSlot] then
            self.Body.Rows[self.HighlightedSlot]:SetDropHighlight(false)
        end
        self.HighlightedSlot = slot
        if slot and self.Body.Rows[slot] then
            self.Body.Rows[slot]:SetDropHighlight(true)
        end
    end,

    --- Builds the floating drag label (the grabbed player's name) so it draws above the rows.
    --- Destroyed in OnSlotDragEnd.
    ---@param self UICustomLobbySlotsInterface
    ---@param source number
    ---@return Group
    CreateDragGhost = function(self, source)
        local player = CustomLobbyLaunchModel.GetSingleton().Players[source]()
        local name = (player and player.PlayerName) or ("Slot " .. tostring(source))

        local ghost = Group(self, "CustomLobbyDragGhost")
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

    --#endregion

    ---@param self UICustomLobbySlotsInterface
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@return UICustomLobbySlotsInterface
Create = function(parent)
    return CustomLobbySlotsInterface(parent)
end
