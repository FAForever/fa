-----------------------------------------------------------------
-- File: lua/modules/ui/game/orders.lua
-- Author: Chris Blackwell
-- Summary: Unit orders UI
-- Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Grid = import('/lua/maui/grid.lua').Grid
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local GameCommon = import('/lua/ui/game/gamecommon.lua')
local Button = import('/lua/maui/button.lua').Button
local Tooltip = import('/lua/ui/game/tooltip.lua')
local TooltipInfo = import('/lua/ui/help/tooltips.lua')
local Prefs = import('/lua/user/prefs.lua')
local CM = import('/lua/ui/game/commandmode.lua')
local UIMain = import('/lua/ui/uimain.lua')
local Select = import('/lua/ui/game/selection.lua')
local EnhancementQueue = import('/lua/ui/notify/enhancementqueue.lua')

controls = import('/lua/ui/controls.lua').Get()

-- Positioning controls, don't belong to file
local layoutVar = false
local glowThread = false

-- These variables control the number of slots available for orders
-- Though they are fixed, the code is written so they could easily be made soft
local numSlots = 14
local firstAltSlot = 8
local vertRows = 3
local horzRows = 4
local vertCols = numSlots/vertRows
local horzCols = numSlots/horzRows
local lastOCTime = {}

local function CreateOrderGlow(parent)
    controls.orderGlow = Bitmap(parent, UIUtil.UIFile('/game/orders/glow-02_bmp.dds'))
    LayoutHelpers.AtCenterIn(controls.orderGlow, parent)
    controls.orderGlow:SetAlpha(0.0)
    controls.orderGlow:DisableHitTest()
    controls.orderGlow:SetNeedsFrameUpdate(true)
    local alpha = 0.0
    local incriment = true
    controls.orderGlow.OnFrame = function(self, deltaTime)
        if incriment then
            alpha = alpha + (deltaTime * 1.2)
        else
            alpha = alpha - (deltaTime * 1.2)
        end
        if alpha < 0 then
            alpha = 0.0
            incriment = true
        end
        if alpha > .4 then
            alpha = .4
            incriment = false
        end
        controls.orderGlow:SetAlpha(alpha)
    end
end

local hotkeyLabel_addLabel = import('/lua/keymap/hotkeylabelsUI.lua').addLabel
local orderKeys = {}

function setOrderKeys(orderKeys_)
    orderKeys = orderKeys_
end

local function CreateAutoBuildEffect(parent)
    local glow = Bitmap(parent, UIUtil.UIFile('/game/orders/glow-02_bmp.dds'))
    LayoutHelpers.AtCenterIn(glow, parent)
    glow:SetAlpha(0.0)
    glow:DisableHitTest()
    glow:SetNeedsFrameUpdate(true)
    glow.alpha = 0.0
    glow.incriment = true
    glow.OnFrame = function(self, deltaTime)
        if self.incriment then
            self.alpha = self.alpha + (deltaTime * .35)
        else
            self.alpha = self.alpha - (deltaTime * .35)
        end
        if self.alpha < 0 then
            self.alpha = 0.0
            self.incriment = true
        end
        if self.alpha > .4 then
            self.alpha = .4
            self.incriment = false
        end
        self:SetAlpha(self.alpha)
    end
    return glow
end

function CreateMouseoverDisplay(parent, ID)
    if controls.mouseoverDisplay then
        controls.mouseoverDisplay:Destroy()
        controls.mouseoverDisplay = false
    end

    if not Prefs.GetOption('tooltips') then return end

    local createDelay = Prefs.GetOption('tooltip_delay') or 0
    local text = TooltipInfo['Tooltips'][ID]['title'] or ID
    local desc = TooltipInfo['Tooltips'][ID]['description'] or ID

    if not text or not desc then
        return
    end

    controls.mouseoverDisplay = Tooltip.CreateExtendedToolTip(parent, text, desc)
    local Frame = GetFrame(0)
    controls.mouseoverDisplay.Bottom:Set(parent.Top)
    if (parent.Left() + (parent.Width() / 2)) - (controls.mouseoverDisplay.Width() / 2) < 0 then
        controls.mouseoverDisplay.Left:Set(4)
    elseif (parent.Right() - (parent.Width() / 2)) + (controls.mouseoverDisplay.Width() / 2) > Frame.Right() then
        controls.mouseoverDisplay.Right:Set(function() return Frame.Right() - 4 end)
    else
        LayoutHelpers.AtHorizontalCenterIn(controls.mouseoverDisplay, parent)
    end

    local alpha = 0.0
    controls.mouseoverDisplay:SetAlpha(alpha, true)
    local mdThread = ForkThread(function()
        WaitSeconds(createDelay)
        while alpha <= 1.0 do
            controls.mouseoverDisplay:SetAlpha(alpha, true)
            alpha = alpha + 0.1
            WaitSeconds(0.01)
        end
    end)

    controls.mouseoverDisplay.OnDestroy = function(self)
        KillThread(mdThread)
    end
end

local function CreateOrderButtonGrid()
    controls.orderButtonGrid = Grid(controls.bg, GameCommon.iconWidth, GameCommon.iconHeight)
    controls.orderButtonGrid:SetName("Orders Grid")
    controls.orderButtonGrid:DeleteAll()
end

-- Local logic data
local orderCheckboxMap = false
local currentSelection = false

-- Helper function to create order bitmaps
-- Note, your bitmaps must be in /game/orders/ and have the standard button naming convention
local function GetOrderBitmapNames(bitmapId)
    if bitmapId == nil then
        LOG("Error - nil bitmap passed to GetOrderBitmapNames")
        bitmapId = "basic-empty"    -- TODO do I really want to default it?
    end

    local button_prefix = "/game/orders/" .. bitmapId .. "_btn_"
    return UIUtil.SkinnableFile(button_prefix .. "up.dds", true)
        ,  UIUtil.SkinnableFile(button_prefix .. "up_sel.dds", true)
        ,  UIUtil.SkinnableFile(button_prefix .. "over.dds", true)
        ,  UIUtil.SkinnableFile(button_prefix .. "over_sel.dds", true)
        ,  UIUtil.SkinnableFile(button_prefix .. "dis.dds", true)
        ,  UIUtil.SkinnableFile(button_prefix .. "dis_sel.dds", true)
        , "UI_Action_MouseDown", "UI_Action_Rollover"   -- Sets click and rollover cues
end

-- Used by most orders, which start and stop a command mode, so they toggle on when pressed
-- and toggle off when done
local function StandardOrderBehavior(self, modifiers)
    -- If we're checked, end the current command mode, otherwise start it
    if self:IsChecked() then
        import('/lua/ui/game/commandmode.lua').EndCommandMode(true)
    else
        import('/lua/ui/game/commandmode.lua').StartCommandMode("order", {name=self._order})
    end
end

-- Used by orders that happen immediately and don't change the command mode (ie the stop button)
local function DockOrderBehavior(self, modifiers)
    if modifiers.Shift then
        IssueDockCommand(false)
    else
        IssueDockCommand(true)
    end
    self:SetCheck(false)
end

-- Used by orders that happen immediately and don't change the command mode (ie the stop button)
local function MomentaryOrderBehavior(self, modifiers)
    IssueCommand(GetUnitCommandFromCommandCap(self._order))
    self:SetCheck(false)
end

function Stop(units)
    local units = units or GetSelectedUnits()

    if units[1] then
        IssueUnitCommand(units, 'Stop')
    end
end

function ClearCommands(units)
    local cb = {Func = 'ClearCommands'}

    if units then
        EnhancementQueue.clearEnhancements(units)
        ForkThread(function() -- Wait a tick for the callback to do its job then refresh the UI to remove ghost enhancement orders
            WaitSeconds(0.1)
            import('/lua/ui/game/construction.lua').RefreshUI()
        end)

        local ids = {}
        for _, u in units do
            table.insert(ids, u:GetEntityId())
        end
        cb.Args = {ids=ids}
    end

    SimCallback(cb, true)
end

function SoftStop(units)
    local units = units or GetSelectedUnits()
    import('/lua/ui/game/construction.lua').ResetOrderQueues(units)
    ClearCommands(EntityCategoryFilterDown(categories.SILO, units))
    Stop(EntityCategoryFilterOut((categories.SHOWQUEUE * categories.STRUCTURE) + categories.FACTORY + categories.SILO, units))
end

function StopOrderBehavior(self, modifiers)
    local userKeyMap = Prefs.GetFromCurrentProfile("UserKeyMap")
    if userKeyMap['S'] == 'soft_stop' and not modifiers.Shift then
        SoftStop()
    else
        Stop()
    end
end

-- Used by things that build weapons, etc
local function BuildOrderBehavior(self, modifiers)
    if modifiers.Left then
        IssueCommand(GetUnitCommandFromCommandCap(self._order))
    elseif modifiers.Right then
        self:ToggleCheck()
        if self:IsChecked() then
            self._curHelpText = self._data.helpText .. "_auto"
            self.autoBuildEffect = CreateAutoBuildEffect(self)
        else
            self._curHelpText = self._data.helpText
            self.autoBuildEffect:Destroy()
        end
        if controls.mouseoverDisplay.text then
            controls.mouseoverDisplay.text:SetText(self._curHelpText)
        end
        SetAutoMode(currentSelection, self:IsChecked())
    end
end

local function BuildInitFunction(control, unitList)
    local isAutoMode = GetIsAutoMode(unitList)
    control:SetCheck(isAutoMode)
    if isAutoMode then
        control._curHelpText = control._data.helpText .. "_auto"
        control.autoBuildEffect = CreateAutoBuildEffect(control)
    else
        control._curHelpText = control._data.helpText
    end
end

-- Used by subs that can dive/surface
local function DiveOrderBehavior(self, modifiers)
    if modifiers.Left then
        local unitList = GetSelectedUnits()
        local submergedSUB = false
        local surfacedSUB = false
        -- Searching the unitlist for SUB's and memorizing submerged and surfaced state
        for i, v in unitList do
            if EntityCategoryContains(categories.SUBMERSIBLE, v) then
                local submergedSUBState = GetIsSubmerged({v})
                if submergedSUBState == 1 then
                    surfacedSUB = true
                elseif submergedSUBState == -1 then
                    submergedSUB = true
                end
                -- Bail out if we know, we have mixed SUBs
                if surfacedSUB and submergedSUB then
                    break
                end
            end
        end
        -- If we have selected submerged and surfaced SUB's, let all surfaced SUB's dive.
        if submergedSUB and surfacedSUB then
            local SurfacedSubs = {}
            for i, v in unitList do
                if GetIsSubmerged({v}) == 1 then
                    table.insert(SurfacedSubs, v)
                end
            end
            IssueUnitCommand(SurfacedSubs, GetUnitCommandFromCommandCap(self._order))
        else
            IssueCommand(GetUnitCommandFromCommandCap(self._order))
        end
        self:ToggleCheck()
    elseif modifiers.Right then
        if self._isAutoMode then
            self._curHelpText = self._data.helpText
            if self.autoBuildEffect then
                self.autoBuildEffect:Destroy()
            end
            self.autoModeIcon:SetAlpha(0)
            self._isAutoMode = false
        else
            self._curHelpText = self._data.helpText .. "_auto"
            if not self.autoBuildEffect then
                self.autoBuildEffect = CreateAutoBuildEffect(self)
            end
            self.autoModeIcon:SetAlpha(1)
            self._isAutoMode = true
        end
        if controls.mouseoverDisplay.text then
            controls.mouseoverDisplay.text:SetText(self._curHelpText)
        end
        SetAutoSurfaceMode(currentSelection, self._isAutoMode)
    end
end

local function DiveInitFunction(control, unitList)
    if not control.autoModeIcon then
        control.autoModeIcon = Bitmap(control, UIUtil.UIFile('/game/orders/autocast_bmp.dds'))
        LayoutHelpers.AtCenterIn(control.autoModeIcon, control)
        control.autoModeIcon:DisableHitTest()
        control.autoModeIcon:SetAlpha(0)
        control.autoModeIcon.OnHide = function(self, hidden)
            if not hidden and control:IsDisabled() then
                return true
            end
        end
    end

    if not control.mixedModeIcon then
        control.mixedModeIcon = Bitmap(control.autoModeIcon, UIUtil.UIFile('/game/orders-panel/question-mark_bmp.dds'))
        LayoutHelpers.AtRightTopIn(control.mixedModeIcon, control)
        control.mixedModeIcon:DisableHitTest()
        control.mixedModeIcon:SetAlpha(0)
        control.mixedModeIcon.OnHide = function(self, hidden)
            if not hidden and control:IsDisabled() then
                return true
            end
        end
    end

    control._isAutoMode = GetIsAutoSurfaceMode(unitList)

    if control._isAutoMode then
        control._curHelpText = control._data.helpText .. "_auto"
        control.autoBuildEffect = CreateAutoBuildEffect(control)
        control.autoModeIcon:SetAlpha(1)
    else
        control._curHelpText = control._data.helpText
    end

    local submergedState = GetIsSubmerged(unitList)

    if submergedState == -1 then
        control:SetCheck(true)
    elseif submergedState == 1 then
        control:SetCheck(false)
    else
        control:SetCheck(false)
        control.mixedModeIcon:SetAlpha(1)
    end
end

function ToggleDiveOrder()
    local diveCB = orderCheckboxMap["RULEUCC_Dive"]
    if diveCB then
        DiveOrderBehavior(diveCB, {Left = true})
    end
end

-- Pause button specific behvior
-- TODO pause button will be moved to construction manager
local function PauseOrderBehavior(self, modifiers)
    Checkbox.OnClick(self)
    SetPaused(currentSelection, self:IsChecked())
end

local function PauseInitFunction(control, unitList)
    control:SetCheck(GetIsPaused(unitList))
end

function TogglePauseState()
    local pauseState = GetIsPaused(currentSelection)
    SetPaused(currentSelection, not pauseState)
end

-- Some toggleable abilities need reverse semantics.
local function CheckReverseSemantics(scriptBit)
    if scriptBit == 0 then -- shields
        return true
    end

    return false
end

local function AttackMoveBehavior(self, modifiers)
    if self:IsChecked() then
        import('/lua/ui/game/commandmode.lua').EndCommandMode(true)
    else
        local modeData = {
            name="RULEUCC_Script",
            AbilityName='AttackMove',
            TaskName='AttackMove',
            cursor = 'ATTACK_MOVE',
        }
        import('/lua/ui/game/commandmode.lua').StartCommandMode("order", modeData)
    end
end

local function AbilityButtonBehavior(self, modifiers)
    if self:IsChecked() then
        CM.EndCommandMode(true)
    else
        local modeData = {
            name="RULEUCC_Script",
            AbilityName=self._script,
            TaskName=self._script,
            cursor = self._cursor,
        }
        CM.StartCommandMode("order", modeData)
    end
end

-- Generic script button specific behvior
local function ScriptButtonOrderBehavior(self, modifiers)
    local state = self:IsChecked()
    local mixed = false
    if self._mixedIcon then
        mixed = true
        self._mixedIcon:Destroy()
        self._mixedIcon = nil
    end

    -- Mixed shields get special behaviour: turn everything on, not off
    if mixed and self._data.extraInfo == 0 then
        ToggleScriptBit(currentSelection, self._data.extraInfo, false)
    else
        ToggleScriptBit(currentSelection, self._data.extraInfo, state)
    end

    if controls.mouseoverDisplay.text then
        controls.mouseoverDisplay.text:SetText(self._curHelpText)
    end

    Checkbox.OnClick(self)
end

local function ScriptButtonInitFunction(control, unitList)
    local result = nil
    local mixed = false
    for i, v in unitList do
        local thisUnitStatus = GetScriptBit({v}, control._data.extraInfo)
        if result == nil then
            result = thisUnitStatus
        else
            if thisUnitStatus ~= result then
                mixed = true
                result = true
                break
            end
        end
    end
    if mixed then
        control._mixedIcon = Bitmap(control, UIUtil.UIFile('/game/orders-panel/question-mark_bmp.dds'))
        LayoutHelpers.AtRightTopIn(control._mixedIcon, control, -2, 2)
    end
    control:SetCheck(result) -- Selected state
end

local function DroneBehavior(self, modifiers)
    if modifiers.Left then
        SelectUnits({self._unit})
    end

    if modifiers.Right then
        if self:IsChecked() then
            self._pod:ProcessInfo('SetAutoMode', 'false')
            self:SetCheck(false)
        else
            self._pod:ProcessInfo('SetAutoMode', 'true')
            self:SetCheck(true)
        end
    end
end

local function DroneInit(self, selection)
    self:SetCheck(self._pod:IsAutoMode())
end

-- Retaliate button specific behvior
local retaliateStateInfo = {
    [-1] = {bitmap = 'stand-ground',    helpText = "mode_mixed"},
    [0] = {bitmap = 'return-fire',     helpText = "mode_return_fire", id = 'ReturnFire'},
    [1] = {bitmap = 'hold-fire',       helpText = "mode_hold_fire", id = 'HoldFire'},
    [2] = {bitmap = 'stand-ground',    helpText = "mode_hold_ground", id = 'HoldGround'},
}

local function CreateBorder(parent)
    local border = {}

    border.tl = Bitmap(parent, UIUtil.UIFile('/game/ability_brd/chat_brd_ul.dds'))
    border.tm = Bitmap(parent, UIUtil.UIFile('/game/ability_brd/chat_brd_horz_um.dds'))
    border.tr = Bitmap(parent, UIUtil.UIFile('/game/ability_brd/chat_brd_ur.dds'))
    border.ml = Bitmap(parent, UIUtil.UIFile('/game/ability_brd/chat_brd_vert_l.dds'))
    border.mr = Bitmap(parent, UIUtil.UIFile('/game/ability_brd/chat_brd_vert_r.dds'))
    border.bl = Bitmap(parent, UIUtil.UIFile('/game/ability_brd/chat_brd_ll.dds'))
    border.bm = Bitmap(parent, UIUtil.UIFile('/game/ability_brd/chat_brd_lm.dds'))
    border.br = Bitmap(parent, UIUtil.UIFile('/game/ability_brd/chat_brd_lr.dds'))

    border.tl.Bottom:Set(parent.Top)
    border.tl.Right:Set(parent.Left)

    border.bl.Top:Set(parent.Bottom)
    border.bl.Right:Set(parent.Left)

    border.tr.Bottom:Set(parent.Top)
    border.tr.Left:Set(parent.Right)

    border.br.Top:Set(parent.Bottom)
    border.br.Left:Set(parent.Right)

    border.tm.Bottom:Set(parent.Top)
    border.tm.Left:Set(parent.Left)
    border.tm.Right:Set(parent.Right)

    border.bm.Top:Set(parent.Bottom)
    border.bm.Left:Set(parent.Left)
    border.bm.Right:Set(parent.Right)

    border.ml.Top:Set(parent.Top)
    border.ml.Bottom:Set(parent.Bottom)
    border.ml.Right:Set(parent.Left)

    border.mr.Top:Set(parent.Top)
    border.mr.Bottom:Set(parent.Bottom)
    border.mr.Left:Set(parent.Right)

    return border
end

local function CreateFirestatePopup(parent, selected)
    local bg = Bitmap(parent, UIUtil.UIFile('/game/ability_brd/chat_brd_m.dds'))

    bg.border = CreateBorder(bg)
    bg:DisableHitTest(true)

    local function CreateButton(index, info)
        local btn = Checkbox(bg, GetOrderBitmapNames(info.bitmap))
        btn.info = info
        btn.index = index
        btn.HandleEvent = function(control, event)
            if event.Type == 'MouseEnter' then
                CreateMouseoverDisplay(control, control.info.helpText, 1)
            elseif event.Type == 'MouseExit' then
                if controls.mouseoverDisplay then
                    controls.mouseoverDisplay:Destroy()
                    controls.mouseoverDisplay = false
                end
            end
            return Checkbox.HandleEvent(control, event)
        end
        btn.OnCheck = function(control, checked)
            parent:_OnFirestateSelection(control.index, control.info.id)
        end
        return btn
    end

    local i = 1
    bg.buttons = {}
    for index, state in retaliateStateInfo do
        if index ~= -1 then
            bg.buttons[i] = CreateButton(index, state)
            if i == 1 then
                LayoutHelpers.AtBottomIn(bg.buttons[i], bg)
                LayoutHelpers.AtLeftIn(bg.buttons[i], bg)
            else
                LayoutHelpers.Above(bg.buttons[i], bg.buttons[i-1])
            end
            i = i + 1
        end
    end

    bg.Height:Set(function() return table.getsize(bg.buttons) * bg.buttons[1].Height() end)
    bg.Width:Set(bg.buttons[1].Width)

    if UIUtil.currentLayout == 'left' then
        LayoutHelpers.RightOf(bg, parent, 40)
    else
        LayoutHelpers.Above(bg, parent, 20)
    end

    return bg
end

local function RetaliateOrderBehavior(self, modifiers)
    if not self._OnFirestateSelection then
        self._OnFirestateSelection = function(self, newState, id)
            self._toggleState = newState
            SetFireState(currentSelection, id)
            self:SetNewTextures(GetOrderBitmapNames(retaliateStateInfo[newState].bitmap))
            self._curHelpText = retaliateStateInfo[newState].helpText
            self._popup:Destroy()
            self._popup = nil
        end
    end
    if self._popup then
        self._popup:Destroy()
        self._popup = nil
    else
        self._popup = CreateFirestatePopup(self, self._toggleState)
        local function CollapsePopup(event)
            if (event.y < self._popup.Top() or event.y > self._popup.Bottom()) or (event.x < self._popup.Left() or event.x > self._popup.Right()) then
                self._popup:Destroy()
                self._popup = nil
            end
        end

        UIMain.AddOnMouseClickedFunc(CollapsePopup)

        self._popup.OnDestroy = function(self)
            UIMain.RemoveOnMouseClickedFunc(CollapsePopup)
            Checkbox.OnDestroy(self)
        end
    end
end

local function RetaliateInitFunction(control, unitList)
    control._toggleState = GetFireState(unitList)
    if not retaliateStateInfo[control._toggleState] then
        LOG("Error: orders.lua - invalid toggle state: ", tostring(self._toggleState))
    end
    control:SetNewTextures(GetOrderBitmapNames(retaliateStateInfo[control._toggleState].bitmap))
    control._curHelpText = retaliateStateInfo[control._toggleState].helpText
    if control._toggleState == -1 then
        if not control.mixedIcon then
            control.mixedIcon = Bitmap(control, UIUtil.UIFile('/game/orders-panel/question-mark_bmp.dds'))
        end
        LayoutHelpers.AtRightTopIn(control.mixedIcon, control, 3, 6)
        control.mixedIcon:DisableHitTest()
        control.mixedIcon:SetAlpha(0)
        control.mixedIcon.OnHide = function(self, hidden)
            if not hidden and control:IsDisabled() then
                return true
            end
        end
    end
    control.OnEnable = function(self)
        if self.mixedIcon then
            self.mixedIcon:SetAlpha(1)
        end
        Checkbox.OnEnable(self)
    end
    control.OnDisable = function(self)
        if self.mixedIcon then
            self.mixedIcon:SetAlpha(0)
        end
        Checkbox.OnDisable(self)
    end
end

function CycleRetaliateStateUp()
    local currentFireState = GetFireState(currentSelection)
    if currentFireState > 3 then
        currentFireState = 0
    end
    ToggleFireState(currentSelection, currentFireState)
end

local function pauseFunc()
    import('/lua/ui/game/construction.lua').EnablePauseToggle()
end

local function disPauseFunc()
    import('/lua/ui/game/construction.lua').DisablePauseToggle()
end

local function NukeBtnText(button)
    if not currentSelection[1] or currentSelection[1].Dead then return '' end
    if table.getsize(currentSelection) > 1 then
        button.buttonText:SetColor('fffff600')
        return '?'
    else
        local info = currentSelection[1]:GetMissileInfo()
        if info.nukeSiloStorageCount == 0 then
            button.buttonText:SetColor('ffff7f00')
        else
            button.buttonText:SetColor('ffffffff')
        end
        return string.format('%d/%d', info.nukeSiloStorageCount, info.nukeSiloMaxStorageCount)
    end
end

local function TacticalBtnText(button)
    if not currentSelection[1] or currentSelection[1].Dead then return '' end
    if table.getsize(currentSelection) > 1 then
        button.buttonText:SetColor('fffff600')
        return '?'
    else
        local info = currentSelection[1]:GetMissileInfo()
        if info.nukeSiloStorageCount == 0 then
            button.buttonText:SetColor('ffff7f00')
        else
            button.buttonText:SetColor('ffffffff')
        end
        return string.format('%d/%d', info.tacticalSiloStorageCount, info.tacticalSiloMaxStorageCount)
    end
end

function FindOCWeapon(bp)
    for index, weapon in bp.Weapon do
        if weapon.OverChargeWeapon then
            return weapon
        end
    end

    return
end

local function IsAutoOCMode(units)
    return UnitData[units[1]:GetEntityId()].AutoOvercharge == true
end

local function OverchargeInit(control, unitList)
    if not control.autoModeIcon then
        control.autoModeIcon = Bitmap(control, UIUtil.UIFile('/game/orders/autocast_green.dds'))
        LayoutHelpers.AtCenterIn(control.autoModeIcon, control)
        control.autoModeIcon:DisableHitTest()
        control.autoModeIcon:SetAlpha(0)
        control.autoModeIcon.OnHide = function(self, hidden)
            if not hidden and control:IsDisabled() then
                return true
            end
        end
    end

    if not control.mixedModeIcon then
        control.mixedModeIcon = Bitmap(control.autoModeIcon, UIUtil.UIFile('/game/orders-panel/question-mark_bmp.dds'))
        LayoutHelpers.AtRightTopIn(control.mixedModeIcon, control)
        control.mixedModeIcon:DisableHitTest()
        control.mixedModeIcon:SetAlpha(0)
        control.mixedModeIcon.OnHide = function(self, hidden)
            if not hidden and control:IsDisabled() then
                return true
            end
        end
    end

    control._isAutoMode = IsAutoOCMode(unitList)

    control._curHelpText = control._data.helpText
    if control._isAutoMode then
        control.autoModeIcon:SetAlpha(1)
    else
        control.autoModeIcon:SetAlpha(0)
    end

    -- Needs to override this to prevent call to self:DisableHitTest()
    control.Disable = function(self)
        self._isDisabled = true
        self:OnDisable()
    end
end

function OverchargeBehavior(self, modifiers)
    if modifiers.Left then
        EnterOverchargeMode()
    elseif modifiers.Right then
        self._curHelpText = self._data.helpText
        if self._isAutoMode then
            self.autoModeIcon:SetAlpha(0)
            self._isAutoMode = false
        else
            self.autoModeIcon:SetAlpha(1)
            self._isAutoMode = true
        end

        if controls.mouseoverDisplay.text then
            controls.mouseoverDisplay.text:SetText(self._curHelpText)
        end

        local cb = {Func = 'AutoOvercharge', Args = {auto = self._isAutoMode == true} }
        SimCallback(cb, true)
    end
end

function EnterOverchargeMode()
    local unit = currentSelection[1]
    if not unit or unit.Dead or unit:IsOverchargePaused() then return end
    local bp = unit:GetBlueprint()
    local weapon = FindOCWeapon(unit:GetBlueprint())
    if not weapon then return end

    local econData = GetEconomyTotals()
    if econData["stored"]["ENERGY"] >= weapon.EnergyRequired then
        ConExecute('StartCommandMode order RULEUCC_Overcharge')
    end
end

local function OverchargeFrame(self, deltaTime)
    local unit = currentSelection[1]
    if not unit or unit.Dead then return end
    local weapon = FindOCWeapon(unit:GetBlueprint())
    if not weapon then
        self:SetNeedsFrameUpdate(false)
        return
    end

    local econData = GetEconomyTotals()
    if econData["stored"]["ENERGY"] >= weapon.EnergyRequired and not unit:IsOverchargePaused() then
        if self:IsDisabled() then
            self:Enable()
            local armyTable = GetArmiesTable()
            local facStr = import('/lua/factions.lua').Factions[armyTable.armiesTable[armyTable.focusArmy].faction + 1].SoundPrefix
            local sound = Sound({Bank = 'XGG', Cue = 'Computer_Computer_Basic_Orders_01173'})
            if not lastOCTime[unit:GetArmy()] then
                lastOCTime[unit:GetArmy()] = GetGameTimeSeconds() - 2
            end
            if GetGameTimeSeconds() - lastOCTime[unit:GetArmy()] > 1 then
                PlayVoice(sound)
                lastOCTime[unit:GetArmy()] = GetGameTimeSeconds()
            end
        end
    else
        if not self:IsDisabled() then
            self:Disable()
        end
    end
end

-- Sets up an orderInfo for each order that comes in
-- preferredSlot is custom data that is used to determine what slot the order occupies
-- initialStateFunc is a function that gets called once the control is created and allows you to set the initial state of the button
--      the function should have this declaration: function(checkbox, unitList)
-- extraInfo is used for storing any extra information required in setting up the button
local defaultOrdersTable = {
    -- Common rules
    AttackMove = {                  helpText = "attack_move",       bitmapId = 'attack_move',           preferredSlot = 1,  behavior = AttackMoveBehavior},
    RULEUCC_Move = {                helpText = "move",              bitmapId = 'move',                  preferredSlot = 2,  behavior = StandardOrderBehavior},
    RULEUCC_Attack = {              helpText = "attack",            bitmapId = 'attack',                preferredSlot = 3,  behavior = StandardOrderBehavior},
    RULEUCC_Patrol = {              helpText = "patrol",            bitmapId = 'patrol',                preferredSlot = 4,  behavior = StandardOrderBehavior},
    RULEUCC_Stop = {                helpText = "stop",              bitmapId = 'stop',                  preferredSlot = 5,  behavior = StopOrderBehavior},
    RULEUCC_Guard = {               helpText = "assist",            bitmapId = 'guard',                 preferredSlot = 6,  behavior = StandardOrderBehavior},
    RULEUCC_RetaliateToggle = {     helpText = "mode",              bitmapId = 'stand-ground',          preferredSlot = 7,  behavior = RetaliateOrderBehavior,      initialStateFunc = RetaliateInitFunction},
    -- Unit specific rules
    RULEUCC_Overcharge = {          helpText = "overcharge",        bitmapId = 'overcharge',            preferredSlot = 8,  behavior = OverchargeBehavior,          initialStateFunc = OverchargeInit, onframe = OverchargeFrame},
    RULEUCC_SiloBuildTactical = {   helpText = "build_tactical",    bitmapId = 'silo-build-tactical',   preferredSlot = 9,  behavior = BuildOrderBehavior,          initialStateFunc = BuildInitFunction},
    RULEUCC_SiloBuildNuke = {       helpText = "build_nuke",        bitmapId = 'silo-build-nuke',       preferredSlot = 9,  behavior = BuildOrderBehavior,          initialStateFunc = BuildInitFunction},
    RULEUCC_Script = {              helpText = "special_action",    bitmapId = 'overcharge',            preferredSlot = 8,  behavior = StandardOrderBehavior},
    RULEUCC_Transport = {           helpText = "transport",         bitmapId = 'unload',                preferredSlot = 9,  behavior = StandardOrderBehavior},
    RULEUCC_Nuke = {                helpText = "fire_nuke",         bitmapId = 'launch-nuke',           preferredSlot = 10, behavior = StandardOrderBehavior, ButtonTextFunc = NukeBtnText},
    RULEUCC_Tactical = {            helpText = "fire_tactical",     bitmapId = 'launch-tactical',       preferredSlot = 10, behavior = StandardOrderBehavior, ButtonTextFunc = TacticalBtnText},
    RULEUCC_Teleport = {            helpText = "teleport",          bitmapId = 'teleport',              preferredSlot = 10, behavior = StandardOrderBehavior},
    RULEUCC_Ferry = {               helpText = "ferry",             bitmapId = 'ferry',                 preferredSlot = 10, behavior = StandardOrderBehavior},
    RULEUCC_Sacrifice = {           helpText = "sacrifice",         bitmapId = 'sacrifice',             preferredSlot = 10, behavior = StandardOrderBehavior},
    RULEUCC_Dive = {                helpText = "dive",              bitmapId = 'dive',                  preferredSlot = 11, behavior = DiveOrderBehavior,           initialStateFunc = DiveInitFunction},
    RULEUCC_Reclaim = {             helpText = "reclaim",           bitmapId = 'reclaim',               preferredSlot = 12, behavior = StandardOrderBehavior},
    RULEUCC_Capture = {             helpText = "capture",           bitmapId = 'convert',               preferredSlot = 13, behavior = StandardOrderBehavior},
    RULEUCC_Repair = {              helpText = "repair",            bitmapId = 'repair',                preferredSlot = 14, behavior = StandardOrderBehavior},
    RULEUCC_Dock = {                helpText = "dock",              bitmapId = 'dock',                  preferredSlot = 14, behavior = DockOrderBehavior},

    DroneL = {                      helpText = "drone",             bitmapId = 'unload02',              preferredSlot = 13, behavior = DroneBehavior,               initialStateFunc = DroneInit},
    DroneR = {                      helpText = "drone",             bitmapId = 'unload02',              preferredSlot = 13, behavior = DroneBehavior,               initialStateFunc = DroneInit},

    -- Unit toggle rules
    RULEUTC_ShieldToggle = {        helpText = "toggle_shield",     bitmapId = 'shield',                preferredSlot = 8,  behavior = ScriptButtonOrderBehavior,   initialStateFunc = ScriptButtonInitFunction, extraInfo = 0},
    RULEUTC_WeaponToggle = {        helpText = "toggle_weapon",     bitmapId = 'toggle-weapon',         preferredSlot = 8,  behavior = ScriptButtonOrderBehavior,   initialStateFunc = ScriptButtonInitFunction, extraInfo = 1},
    RULEUTC_JammingToggle = {       helpText = "toggle_jamming",    bitmapId = 'jamming',               preferredSlot = 9,  behavior = ScriptButtonOrderBehavior,   initialStateFunc = ScriptButtonInitFunction, extraInfo = 2},
    RULEUTC_IntelToggle = {         helpText = "toggle_intel",      bitmapId = 'intel',                 preferredSlot = 9,  behavior = ScriptButtonOrderBehavior,   initialStateFunc = ScriptButtonInitFunction, extraInfo = 3},
    RULEUTC_ProductionToggle = {    helpText = "toggle_production", bitmapId = 'production',            preferredSlot = 10, behavior = ScriptButtonOrderBehavior,   initialStateFunc = ScriptButtonInitFunction, extraInfo = 4},
    RULEUTC_StealthToggle = {       helpText = "toggle_stealth",    bitmapId = 'stealth',               preferredSlot = 10, behavior = ScriptButtonOrderBehavior,   initialStateFunc = ScriptButtonInitFunction, extraInfo = 5},
    RULEUTC_GenericToggle = {       helpText = "toggle_generic",    bitmapId = 'production',            preferredSlot = 11, behavior = ScriptButtonOrderBehavior,   initialStateFunc = ScriptButtonInitFunction, extraInfo = 6},
    RULEUTC_SpecialToggle = {       helpText = "toggle_special",    bitmapId = 'activate-weapon',       preferredSlot = 12, behavior = ScriptButtonOrderBehavior,   initialStateFunc = ScriptButtonInitFunction, extraInfo = 7},
    RULEUTC_CloakToggle = {         helpText = "toggle_cloak",      bitmapId = 'intel-counter',         preferredSlot = 12, behavior = ScriptButtonOrderBehavior,   initialStateFunc = ScriptButtonInitFunction, extraInfo = 8},
}

local standardOrdersTable = nil

local specialOrdersTable = {
    RULEUCC_Pause = {behavior = pauseFunc, notAvailableBehavior = disPauseFunc},
}

-- This is a used as a set
local commonOrders = {
    RULEUCC_Move = true,
    RULEUCC_Attack = true,
    RULEUCC_Patrol = true,
    RULEUCC_Stop = true,
    RULEUCC_Guard = true,
    RULEUCC_RetaliateToggle = true,
    AttackMove = true,
}

--[[
Add an order to a particular slot, destroys what's currently in the slot if anything
Returns checkbox if you need to add any data to the structure

The orderInfo format is:
{
    helpText = <string>,    --
    bitmapId = <string>,    -- the id used to construct the bitmap name (see GetOrderBitmapNames above)
    disabled = <bool>,      -- if true, button will start disabled
    behavior = <function>,  -- function(self, modifiers) this is the checkbox OnClick behavior
}

Since this is a table, if you need any more information, for instance, the command to be emmited from the OnClick
you can add it to the table and it will be ignored, so you're safe to put whatever info you need in to it. When the
OnClick callback is called, self._data will contain this info.
--]]
local function AddOrder(orderInfo, slot, batchMode)
    batchMode = batchMode or false

    local checkbox = Checkbox(controls.orderButtonGrid, GetOrderBitmapNames(orderInfo.bitmapId))

    -- Set the info in to the data member for retrieval
    checkbox._data = orderInfo

    -- Set up initial help text
    checkbox._curHelpText = orderInfo.helpText

    -- Set up click handler
    checkbox.OnClick = orderInfo.behavior

    if orderInfo.onframe then
        checkbox.EnableEffect = Bitmap(checkbox, UIUtil.UIFile('/game/orders/glow-02_bmp.dds'))
        LayoutHelpers.AtCenterIn(checkbox.EnableEffect, checkbox)
        checkbox.EnableEffect:DisableHitTest()
        checkbox.EnableEffect:SetAlpha(0)
        checkbox.EnableEffect.Incrimenting = false
        checkbox.EnableEffect.OnFrame = function(self, deltatime)
            local alpha
            if self.Incrimenting then
                alpha = self.Alpha + (deltatime * 2)
                if alpha > 1 then
                    alpha = 1
                    self.Incrimenting = false
                end
            else
                alpha = self.Alpha - (deltatime * 2)
                if alpha < 0 then
                    alpha = 0
                    self.Incrimenting = true
                end
            end
            self.Height:Set(function() return checkbox.Height() + (checkbox.Height() * alpha * .5) end)
            self.Width:Set(function() return checkbox.Height() + (checkbox.Height() * alpha * .5) end)
            self.Alpha = alpha
            self:SetAlpha(alpha * .45)
        end
        checkbox:SetNeedsFrameUpdate(true)
        checkbox.OnFrame = orderInfo.onframe
        checkbox.OnEnable = function(self)
            self.EnableEffect:SetNeedsFrameUpdate(true)
            self.EnableEffect.Incrimenting = false
            self.EnableEffect:SetAlpha(1)
            self.EnableEffect.Alpha = 1
            Checkbox.OnEnable(self)
        end
        checkbox.OnDisable = function(self)
            self.EnableEffect:SetNeedsFrameUpdate(false)
            self.EnableEffect:SetAlpha(0)
            Checkbox.OnDisable(self)
        end
    end

    if orderInfo.ButtonTextFunc then
        checkbox.buttonText = UIUtil.CreateText(checkbox, '', 18, UIUtil.bodyFont)
        checkbox.buttonText:SetText(orderInfo.ButtonTextFunc(checkbox))
        checkbox.buttonText:SetColor('ffffffff')
        checkbox.buttonText:SetDropShadow(true)
        if Prefs.GetFromCurrentProfile('options').show_hotkeylabels and orderKeys[orderInfo.helpText] then
            LayoutHelpers.AtTopIn(checkbox.buttonText, checkbox)
        else
            LayoutHelpers.AtBottomIn(checkbox.buttonText, checkbox)
        end
        LayoutHelpers.AtHorizontalCenterIn(checkbox.buttonText, checkbox)
        checkbox.buttonText:DisableHitTest()
        checkbox.buttonText:SetNeedsFrameUpdate(true)
        checkbox.buttonText.OnFrame = function(self, delta)
            self:SetText(orderInfo.ButtonTextFunc(checkbox))
        end
    end

    -- Set up tooltips
    checkbox.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            CreateMouseoverDisplay(self, self._curHelpText, 1)

            if not self:IsDisabled() then
                if controls.orderGlow then
                    controls.orderGlow:Destroy()
                    controls.orderGlow = false
                end
                glowThread = CreateOrderGlow(self)
            end
        elseif event.Type == 'MouseExit' then
            if controls.mouseoverDisplay then
                controls.mouseoverDisplay:Destroy()
                controls.mouseoverDisplay = false
            end
            if controls.orderGlow then
                controls.orderGlow:Destroy()
                controls.orderGlow = false
                KillThread(glowThread)
            end
        end
        Checkbox.HandleEvent(self, event)
    end

    -- Calculate row and column, remove old item, add new checkbox
    local cols, rows = controls.orderButtonGrid:GetDimensions()
    local row = math.ceil(slot / cols)
    local col = math.mod(slot - 1, cols) + 1
    controls.orderButtonGrid:DestroyItem(col, row, batchMode)
    controls.orderButtonGrid:SetItem(checkbox, col, row, batchMode)

    -- Handle Hotbuild labels
    if orderKeys[orderInfo.helpText] then
        hotkeyLabel_addLabel(checkbox, checkbox, orderKeys[orderInfo.helpText])
    end

    return checkbox
end

-- Creates the buttons for the common orders, and then disables them if they aren't in the order set
local function CreateCommonOrders(availableOrders, init)
    for key in commonOrders do
        local orderInfo = standardOrdersTable[key]

        local orderCheckbox = AddOrder(orderInfo, orderInfo.preferredSlot, true)
        orderCheckbox._order = key
        orderCheckbox._toggleState = 0

        if not init and orderInfo.initialStateFunc then
            orderInfo.initialStateFunc(orderCheckbox, currentSelection)
        end

        orderCheckbox:Disable()

        orderCheckboxMap[key] = orderCheckbox
    end

    for index, availOrder in availableOrders do
        if not standardOrdersTable[availOrder] then continue end -- Skip any orders we don't have in our table
        if commonOrders[availOrder] then
            local ck = orderCheckboxMap[availOrder]
            ck:Enable()
        end
    end

    local units = {}
    if currentSelection and table.getn(currentSelection) > 0 then
        for _, unit in currentSelection do
            if not IsDestroyed(unit) then
                table.insert(units, unit)
            end
        end
    end
    if units and table.getn(units) > 0 and EntityCategoryFilterDown(categories.MOBILE - categories.STRUCTURE, units) then
        for _, availOrder in availableOrders do
            if (availOrder == 'RULEUCC_RetaliateToggle' and table.getn(EntityCategoryFilterDown(categories.MOBILE, units)) > 0)
                    or table.getn(EntityCategoryFilterDown(categories.ENGINEER - categories.POD, units)) > 0 then
                orderCheckboxMap['AttackMove']:Enable()
                break
            end
        end
    end
end

function AddAbilityButtons(standardOrdersTable, availableOrders, units)
    -- Look for units in the selection that have special ability buttons
    -- If any are found, add the ability information to the standard order table
    if units and categories.ABILITYBUTTON and EntityCategoryFilterDown(categories.ABILITYBUTTON, units) then
        for index, unit in units do
            local tempBP = UnitData[unit:GetEntityId()]
            if tempBP.Abilities then
                for abilityIndex, ability in tempBP.Abilities do
                    if ability.Active ~= false then
                        table.insert(availableOrders, abilityIndex)
                        standardOrdersTable[abilityIndex] = table.merged(ability, import('/lua/abilitydefinition.lua').abilities[abilityIndex])
                        standardOrdersTable[abilityIndex].behavior = AbilityButtonBehavior
                    end
                end
            end
        end
    end
end

-- Creates the buttons for the alt orders, placing them as possible
local function CreateAltOrders(availableOrders, availableToggles, units)
    -- TODO? it would indeed be easier if the alt orders slot was in the blueprint, but for now try
    -- to determine where they go by using preferred slots
    AddAbilityButtons(standardOrdersTable, availableOrders, units)

    local assitingUnitList = {}
    local podUnits = {}
    if table.getn(units) > 0 and (EntityCategoryFilterDown(categories.PODSTAGINGPLATFORM, units) or EntityCategoryFilterDown(categories.POD, units)) then
        local PodStagingPlatforms = EntityCategoryFilterDown(categories.PODSTAGINGPLATFORM, units)
        local Pods = EntityCategoryFilterDown(categories.POD, units)
        local assistingUnits = {}
        if table.getn(PodStagingPlatforms) == 0 and table.getn(Pods) == 1 then
            assistingUnits[1] = Pods[1]:GetCreator()
            podUnits['DroneL'] = Pods[1]
            podUnits['DroneR'] = Pods[2]
        elseif table.getn(PodStagingPlatforms) == 1 then
            assistingUnits = GetAssistingUnitsList(PodStagingPlatforms)
            podUnits['DroneL'] = assistingUnits[1]
            podUnits['DroneR'] = assistingUnits[2]
        end
        if assistingUnits[1] then
            table.insert(availableOrders, 'DroneL')
            assitingUnitList['DroneL'] = assistingUnits[1]
        end
        if assistingUnits[2] then
            table.insert(availableOrders, 'DroneR')
            assitingUnitList['DroneR'] = assistingUnits[2]
        end
    end

    -- Determine what slots to put alt orders
    -- We first want a table of slots we want to fill, and what orders want to fill them
    local desiredSlot = {}
    local usedSpecials = {}
    for index, availOrder in availableOrders do
        if standardOrdersTable[availOrder] then
            local preferredSlot = standardOrdersTable[availOrder].preferredSlot
            if not desiredSlot[preferredSlot] then
                desiredSlot[preferredSlot] = {}
            end
            table.insert(desiredSlot[preferredSlot], availOrder)
        else
            if specialOrdersTable[availOrder] ~= nil then
                specialOrdersTable[availOrder].behavior()
                usedSpecials[availOrder] = true
            end
        end
    end

    for index, availToggle in availableToggles do
        if standardOrdersTable[availToggle] then
            local preferredSlot = standardOrdersTable[availToggle].preferredSlot
            if not desiredSlot[preferredSlot] then
                desiredSlot[preferredSlot] = {}
            end
            table.insert(desiredSlot[preferredSlot], availToggle)
        else
            if specialOrdersTable[availToggle] ~= nil then
                specialOrdersTable[availToggle].behavior()
                usedSpecials[availToggle] = true
            end
        end
    end

    for i, specialOrder in specialOrdersTable do
        if not usedSpecials[i] and specialOrder.notAvailableBehavior then
            specialOrder.notAvailableBehavior()
        end
    end

    -- Now go through that table and determine what doesn't fit and look for slots that are empty
    -- Since this is only alt orders, just deal with slots 7-12
    local orderInSlot = {}

    -- Go through first time and add all the first entries to their preferred slot
    for slot = firstAltSlot, numSlots do
        if desiredSlot[slot] then
            orderInSlot[slot] = desiredSlot[slot][1]
        end
    end

    -- Now put any additional entries wherever they will fit
    for slot = firstAltSlot, numSlots do
        if desiredSlot[slot] and table.getn(desiredSlot[slot]) > 1 then
            for index, item in desiredSlot[slot] do
                if index > 1 then
                    local foundFreeSlot = false
                    for newSlot = firstAltSlot, numSlots do
                        if not orderInSlot[newSlot] then
                            orderInSlot[newSlot] = item
                            foundFreeSlot = true
                            break
                        end
                    end
                    if not foundFreeSlot then
                        WARN("No free slot for order: " .. item)
                        -- Could break here, but don't, then you'll know how many extra orders you have
                    end
                end
            end
        end
    end

    -- Now map it the other direction so it's order to slot
    local slotForOrder = {}
    for slot, order in orderInSlot do
        slotForOrder[order] = slot
    end

    -- Create the alt order buttons
    for index, availOrder in availableOrders do
        if not standardOrdersTable[availOrder] then continue end -- Skip any orders we don't have in our table
        if not commonOrders[availOrder] then
            local orderInfo = standardOrdersTable[availOrder] or AbilityInformation[availOrder]
            local orderCheckbox = AddOrder(orderInfo, slotForOrder[availOrder], true)

            orderCheckbox._order = availOrder

            if standardOrdersTable[availOrder].script then
                orderCheckbox._script = standardOrdersTable[availOrder].script
            end

            if standardOrdersTable[availOrder].cursor then
                orderCheckbox._cursor = standardOrdersTable[availOrder].cursor
            end

            if assitingUnitList[availOrder] then
                orderCheckbox._unit = assitingUnitList[availOrder]
            end

            if podUnits[availOrder] then
                orderCheckbox._pod = podUnits[availOrder]
            end

            if orderInfo.initialStateFunc then
                orderInfo.initialStateFunc(orderCheckbox, currentSelection)
            end

            orderCheckboxMap[availOrder] = orderCheckbox
        end
    end

    for index, availToggle in availableToggles do
        if not standardOrdersTable[availToggle] then continue end -- Skip any orders we don't have in our table
        if not commonOrders[availToggle] then
            local orderInfo = standardOrdersTable[availToggle] or AbilityInformation[availToggle]
            local orderCheckbox = AddOrder(orderInfo, slotForOrder[availToggle], true)

            orderCheckbox._order = availToggle

            if standardOrdersTable[availToggle].script then
                orderCheckbox._script = standardOrdersTable[availToggle].script
            end

            if assitingUnitList[availToggle] then
                orderCheckbox._unit = assitingUnitList[availToggle]
            end

            if orderInfo.initialStateFunc then
                orderInfo.initialStateFunc(orderCheckbox, currentSelection)
            end

            orderCheckboxMap[availToggle] = orderCheckbox
        end
    end
end

-- Called by gamemain when new orders are available,
function SetAvailableOrders(availableOrders, availableToggles, newSelection)
    -- Save new selection
    currentSelection = newSelection
    -- Clear existing orders
    orderCheckboxMap = {}
    controls.orderButtonGrid:DestroyAllItems(true)

    -- Create our copy of orders table
    standardOrdersTable = table.deepcopy(defaultOrdersTable)

    -- Look in blueprints for any icon or tooltip overrides
    -- Note that if multiple overrides are found for the same order, then the default is used
    -- The syntax of the override in the blueprint is as follows (the overrides use same naming as in the default table above):
    -- In General table
    -- OrderOverrides = {
    --     RULEUTC_IntelToggle = {
    --         bitmapId = 'custom',
    --         helpText = 'toggle_custom',
    --     },
    --  },
    local orderDiffs
    for index, unit in newSelection do
        local overrideTable = unit:GetBlueprint().General.OrderOverrides
        if overrideTable then
            for orderKey, override in overrideTable do
                if orderDiffs == nil then
                    orderDiffs = {}
                end
                if orderDiffs[orderKey] ~= nil and (orderDiffs[orderKey].bitmapId ~= override.bitmapId or orderDiffs[orderKey].helpText ~= override.helpText) then
                    -- Found order diff already, so mark it false so it gets ignored when applying to table
                    orderDiffs[orderKey] = false
                else
                    orderDiffs[orderKey] = override
                end
            end
        end
    end

    -- Apply overrides
    if orderDiffs ~= nil then
        for orderKey, override in orderDiffs do
            if override and override ~= false then
                if override.bitmapId then
                    standardOrdersTable[orderKey].bitmapId = override.bitmapId
                end
                if override.helpText then
                    standardOrdersTable[orderKey].helpText = override.helpText
                end
            end
        end
    end

    CreateCommonOrders(availableOrders)

    local numValidOrders = 0
    for i, v in availableOrders do
        if standardOrdersTable[v] then
            numValidOrders = numValidOrders + 1
        end
    end

    for i, v in availableToggles do
        if standardOrdersTable[v] then
            numValidOrders = numValidOrders + 1
        end
    end

    if numValidOrders <= 12 then
        CreateAltOrders(availableOrders, availableToggles, currentSelection)
    end

    controls.orderButtonGrid:EndBatch()
    if table.getn(currentSelection) == 0 and controls.bg.Mini then
        controls.bg.Mini(true)
    elseif controls.bg.Mini then
        controls.bg.Mini(false)
    end
end

function CreateControls()
    if controls.mouseoverDisplay then
        controls.mouseoverDisplay:Destroy()
        controls.mouseoverDisplay = false
    end
    if not controls.bg then
        controls.bg = Bitmap(controls.controlClusterGroup)
    end
    if not controls.orderButtonGrid then
        CreateOrderButtonGrid()
    end
    if not controls.bracket then
        controls.bracket = Bitmap(controls.bg)
        controls.bracket:DisableHitTest()
    end
    if not controls.bracketMax then
        controls.bracketMax = Bitmap(controls.bg)
        controls.bracketMax:DisableHitTest()
    end
    if not controls.bracketMid then
        controls.bracketMid = Bitmap(controls.bg)
        controls.bracketMid:DisableHitTest()
    end
    local count = 0
    controls.bg:SetNeedsFrameUpdate(true)
    controls.bg.OnFrame = function(self, delta)
        count = count + 1
        if count > 4 then
            self:SetNeedsFrameUpdate(false)
        end
        self:Hide()
    end
end

function SetLayout(layout)
    layoutVar = layout

    -- Clear existing orders
    orderCheckboxMap = {}
    if controls and controls.orderButtonGrid then
        controls.orderButtonGrid:DeleteAndDestroyAll(true)
    end

    CreateControls()
    import(UIUtil.GetLayoutFilename('orders')).SetLayout()

    -- Created greyed out orders on setup
    CreateCommonOrders({}, true)
end

-- Called from gamemain to create control
function SetupOrdersControl(parent, mfd)
    controls.controlClusterGroup = parent
    controls.mfdControl = mfd

    -- Create our copy of orders table
    standardOrdersTable = table.deepcopy(defaultOrdersTable)

    SetLayout(UIUtil.currentLayout)

    -- Setup command mode behaviors
    import('/lua/ui/game/commandmode.lua').AddStartBehavior(
        function(commandMode, data)
            local orderCheckbox = orderCheckboxMap[data]
            if orderCheckbox then
                orderCheckbox:SetCheck(true)
            end
        end
)
    import('/lua/ui/game/commandmode.lua').AddEndBehavior(
        function(commandMode, data)
            local orderCheckbox = orderCheckboxMap[data]
            if orderCheckbox then
                orderCheckbox:SetCheck(false)
            end
        end
)

    return controls.bg
end

function Contract()
    controls.bg:Hide()
end

function Expand()
    if GetSelectedUnits() then
        controls.bg:Show()
    else
        controls.bg:Hide()
    end
end
