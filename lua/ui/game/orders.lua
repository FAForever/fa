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
local SetWeaponPriorities = import('/lua/keymap/misckeyactions.lua').SetWeaponPriorities
local updateHotkeys = import('/lua/keymap/misckeyactions.lua').updatePriData
local Dragger = import('/lua/maui/dragger.lua').Dragger
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local Combo = import('/lua/ui/controls/combo.lua').Combo
local Edit = import('/lua/maui/edit.lua').Edit

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

-------------------------------------------------------------------------
---------------------Weapon priorities-----------------------------------
-------------------------------------------------------------------------

local prioStateTextures = {
    Default = '/game/Weapon-priorities/default.dds',
    ACU = '/game/Weapon-priorities/ACU.dds',
    Power = '/game/Weapon-priorities/power.dds',
    PD = '/game/Weapon-priorities/PD.dds',
    Engies = '/game/Weapon-priorities/engies.dds',
    Shield = '/game/Weapon-priorities/shields.dds',
    EXP = '/game/Weapon-priorities/EXP.dds'
}
local categoryID ={[1] = 'AIR', [2] = 'ANTIAIR', [3] = 'ANTIMISSILE', [4] = 'ANTINAVY', [5] = 'ANTISUB',
    [6] = 'ARTILLERY', [7] = 'BATTLESHIP', [8] = 'BOMBER', [9] = 'CARRIER', [10] = 'COMMAND',[11] = 'CONSTRUCTION',
    [12] = 'COUNTERINTELLIGENCE',[13] = 'CRUISER',[14] = 'DEFENSE',[15] = 'DESTROYER',[16] = 'DIRECTFIRE',
    [17] = 'ECONOMIC',[18] = 'ENERGYPRODUCTION',[19] = 'ENERGYSTORAGE',[20] = 'ENGINEER',[21] = 'EXPERIMENTAL',
    [22] = 'FACTORY',[23] = 'FRIGATE',[24] = 'GROUNDATTACK',[25] = 'HOVER',[26] = 'INDIRECTFIRE', 
    [27] = 'INTELLIGENCE', [28] = 'LAND', [29] = 'MASSEXTRACTION',[30] = 'MASSPRODUCTION',[31] = 'MASSSTORAGE',
    [32] = 'MOBILE',[33] = 'MOBILESONAR',[34] = 'NAVAL',[35] = 'NUKE',[36] = 'NUKESUB',
    [37] = 'OMNI',[38] = 'RADAR',[39] = 'RECLAIMABLE',[40] = 'SCOUT',[41] = 'SHIELD',[42] = 'SNIPER',
    [43] = 'SONAR',[44] = 'STRATEGIC',[45] = 'STRUCTURE',[46] = 'SUBCOMMANDER',[47] = 'SUBMERSIBLE',
    [48] = 'TECH1',[49] = 'TECH2',[50] = 'TECH3',[51] = 'TRANSPORTATION'}

local updater
local main
local infoPanel

local mainData
local mainDataDefault = {
    category = {}, 
    sets = {ACU = {10}, Power = {18,45}, PD = {14,16,45}, Engies = {20, 39}, Shields = {41}, EXP = {21}}, 
    defaults = {ACU = true, Power = true, PD = true, Engies = true, Shields = true, EXP = true}, 
    buttonLayout = {[1] = "Default", [2] = "ACU", [3] = "Engies", [4] = "PD", [5] = "Power", [6] = "Shields", [7] = "EXP"},
    buttonLayoutExpand = {},
    hotkeys = {[1] = "ACU", [2] = "Engies", [3] = "PD", [4] = "Power", [5] = "Shields", [6] = "EXP"},
    defCheck = true, 
    }
    
mainData = Prefs.GetFromCurrentProfile("mainPriData") or mainDataDefault 

local showUnitCat = true
local showTable

local function SavePrefs()
    Prefs.SetToCurrentProfile("mainPriData", mainData)
    Prefs.SavePreferences()
    updateHotkeys()
end

local function ResetPri()
    mainData = table.deepcopy(mainDataDefault)
    Prefs.SetToCurrentProfile("mainPriData", mainData)
    Prefs.SavePreferences()
    updateHotkeys()
end

local function CreatePrioBorder(parent)
    local prioBorder = {}
    
    prioBorder.topleft = Bitmap(parent, UIUtil.UIFile('/game/ability_brd/chat_brd_ul.dds'))
    prioBorder.bottomleft = Bitmap(parent, UIUtil.UIFile('/game/ability_brd/chat_brd_ll.dds'))
    prioBorder.topright = Bitmap(parent, UIUtil.UIFile('/game/ability_brd/chat_brd_ur.dds'))
    prioBorder.bottomright = Bitmap(parent, UIUtil.UIFile('/game/ability_brd/chat_brd_lr.dds'))
    
    prioBorder.topmid = Bitmap(parent, UIUtil.UIFile('/game/ability_brd/chat_brd_horz_um.dds'))
    prioBorder.bottommid = Bitmap(parent, UIUtil.UIFile('/game/ability_brd/chat_brd_lm.dds'))
    
    prioBorder.midleft = Bitmap(parent, UIUtil.UIFile('/game/ability_brd/chat_brd_vert_l.dds'))
    prioBorder.midright = Bitmap(parent, UIUtil.UIFile('/game/ability_brd/chat_brd_vert_r.dds'))
    
    prioBorder.back = Bitmap(parent, UIUtil.UIFile('/game/ability_brd/chat_brd_m.dds'))
    
    
    local x = 56 --topleft relative coordinates
    local y = -18
    
    local width = 70
    local height = 155

    if mainData.expand then
        width = 140
    end
    
    
    
    --corners
    LayoutHelpers.AtLeftTopIn(prioBorder.topleft, parent, x, y)
    LayoutHelpers.AtLeftTopIn(prioBorder.bottomleft, prioBorder.topleft, 0, height)
    
    LayoutHelpers.AtLeftTopIn(prioBorder.topright, prioBorder.topleft, width, 0)
    LayoutHelpers.AtLeftTopIn(prioBorder.bottomright, prioBorder.topleft, width, height)
    
    
    --mid
    LayoutHelpers.AtLeftTopIn(prioBorder.topmid, prioBorder.topleft, 18, 0)
    prioBorder.topmid.Width:Set(width - 18)
    
    LayoutHelpers.AtLeftTopIn(prioBorder.bottommid, prioBorder.topleft, 18, height)
    prioBorder.bottommid.Width:Set(width - 18)
    
    LayoutHelpers.AtLeftTopIn(prioBorder.midleft, prioBorder.topleft, 0, 18)
    prioBorder.midleft.Height:Set(height - 18)
    
    LayoutHelpers.AtLeftTopIn(prioBorder.midright, prioBorder.topleft, width, 18)
    prioBorder.midright.Height:Set(height - 18)
 
    --background
    LayoutHelpers.AtLeftTopIn(prioBorder.back, prioBorder.topleft, 18 , 18)
    prioBorder.back.Width:Set(width - 18)
    prioBorder.back.Height:Set(height - 18)
    
    return prioBorder
end

local function CreatePrioButtons(parent)
    local buttons = {}
    local i = 1
    
    local function CreateButton(name, key, defaults)
        local btn = Checkbox(parent)
      
        btn.Width:Set(70)
        btn.Height:Set(20)
    
        btn:SetNewTextures(
        UIUtil.UIFile('/game/Weapon-priorities/Button1.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/Button1.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/Button2.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/Button2.dds')
        )
        if name then 
            btn.OnCheck = function(control, checked)
                SetWeaponPriorities(key, name, defaults)
            end
        
            LayoutHelpers.AtLeftTopIn(UIUtil.CreateText(parent, name, 14, UIUtil.bodyFont), btn, 10, 0)
            
        else -- empty button
            btn:DisableHitTest()
        end   
        
        return btn
    end
    
  
    while i < 8 do
        
        local name = mainData.buttonLayout[i]
        if i == 1 then 
            buttons[i] = CreateButton(name, 0)
            LayoutHelpers.AtLeftTopIn(buttons[i], parent, 65, 120)
        else
            buttons[i] = CreateButton(name, mainData.sets[name], mainData.defaults[name])
            LayoutHelpers.Above(buttons[i], buttons[i-1])
        end
        
        i = i + 1
    end
    
    local first
    
    if mainData.expand then
        while i < 15 do
        
            local name = mainData.buttonLayoutExpand[i]
            
            if not first then 
                buttons[i] = CreateButton(name, mainData.sets[name], mainData.defaults[name])
                LayoutHelpers.AtLeftTopIn(buttons[i], parent, 137, 120)
                first = true
            else
                buttons[i] = CreateButton(name, mainData.sets[name], mainData.defaults[name])
                LayoutHelpers.Above(buttons[i], buttons[i-1])
            end
            
            i = i + 1
        end
    end
    
    
    --info button
    buttons.info = Checkbox(parent)
    
    buttons.info.Width:Set(14)
    buttons.info.Height:Set(14)
    
    buttons.info:SetNewTextures(
        UIUtil.UIFile('/game/Weapon-priorities/Expand.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/Expand.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/Expand2.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/Expand2.dds')
        )
    buttons.info.OnCheck = function(control, checked)
        createPrioMain()
    end
    LayoutHelpers.AtLeftTopIn(buttons.info, parent.prioBorder.topright, 2, 4)

    return buttons
end

local function CreateFirestatePopup(parent, selected)
    local bg = Bitmap(parent, UIUtil.UIFile('/game/ability_brd/chat_brd_m.dds'))

    bg.border = CreateBorder(bg)
    bg.prioBorder = CreatePrioBorder(bg)
    bg:DisableHitTest(true)

    bg.prioButtons = CreatePrioButtons(bg)
    
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

function createPrioMain() --prio sets & settings
    if main then
        main:Destroy()
        main = nil
    end
    
    local function updateList()
        main.setList:DeleteAllItems()
        
        local i = 1
    
        for key, val in mainData.sets or {} do
            main.setList:AddItem(key)
            main.setList.table[i] = key
            i = i + 1
        end
    end

    local function updateInfo(name)
        if main.updateCategories then
            main.updateCategories:Destroy()
            main.updateCategories = nil
        end
        
        if main.updateDefaults then
            main.updateDefaults:Destroy()
            main.updateDefaults = nil
        end
        
        main.updateCategories = Bitmap(main, UIUtil.UIFile('/game/ability_brd/chat_brd_m.dds'))
        main.updateCategories.Width:Set(0)
        main.updateCategories.Height:Set(0)
        LayoutHelpers.AtLeftTopIn(main.updateCategories, main, 0, 20)
        
        local line = 0
        
        for key, val in mainData.sets[name] do
            if line == 0 then
                main.updateCategories[key] = UIUtil.CreateText(main.updateCategories, categoryID[val], 14, "Calibri")
                LayoutHelpers.AtLeftTopIn(main.updateCategories[key], main.infoCategories, 30, 20)
                main.updateCategories[key]:SetColor('B59F7B')
                line = line + 1
            else
                main.updateCategories[key] = UIUtil.CreateText(main.updateCategories, categoryID[val], 14, "Calibri")
                LayoutHelpers.AtLeftTopIn(main.updateCategories[key], main.infoCategories, 30 , 20 + (line * 20))
                main.updateCategories[key]:SetColor('B59F7B')
                line = line + 1
            end
        end
        
        if mainData.defaults[name] then
            main.updateDefaults = UIUtil.CreateText(main, "YES", 14, "Calibri")
            LayoutHelpers.AtLeftTopIn(main.updateDefaults, main.infoDefaults, 90, 0)
            main.updateDefaults:SetColor('11A02E')
        else
            main.updateDefaults = UIUtil.CreateText(main, "NO", 14, "Calibri")
            LayoutHelpers.AtLeftTopIn(main.updateDefaults, main.infoDefaults, 90, 0)
            main.updateDefaults:SetColor('B50A19')
        end    
    end        
    
    mainData.category = {}
    
    local width = 800
    local height = 350
    
    main = Bitmap(GetFrame(0))
    main:SetTexture(UIUtil.UIFile('/game/Weapon-priorities/infoBack.dds'))
    main.Depth:Set(10000)
    main.Width:Set(width)
    main.Height:Set(height)
    main:SetAlpha(0.6)
        
    LayoutHelpers.AtCenterIn(main, GetFrame(0), -200)
    
    main.back = Bitmap(main, UIUtil.UIFile('/game/Weapon-priorities/BackMain3.dds'))
    LayoutHelpers.AtLeftTopIn(main.back, main, 0, 0)
    main.back:DisableHitTest()
    
    main.HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' then
            local drag = Dragger()
            local offX = event.MouseX - self.Left()
            local offY = event.MouseY - self.Top()
            
            drag.OnMove = function(dragself, x, y)
                self.Left:Set(x - offX)
                self.Top:Set(y - offY)
                GetCursor():SetTexture(UIUtil.GetCursor('MOVE_WINDOW'))
            end

            drag.OnRelease = function(dragself)    
                GetCursor():Reset()
                drag:Destroy()
            end
            
            PostDragger(self:GetRootFrame(), event.KeyCode, drag)
        end
    end
    
    main.closeButton =  Button(main, 
        UIUtil.UIFile('/game/Weapon-priorities/close1.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/close1.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/close2.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/close2.dds'))
        
    LayoutHelpers.AtLeftTopIn(main.closeButton, main, width - 20, 5) 
        
    main.closeButton.OnClick = function(self, event)
        main:Destroy()
        main = nil
    end
    
    main.infoButton =  Button(main, 
        UIUtil.UIFile('/game/Weapon-priorities/UnitInfo.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/UnitInfo.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/UnitInfo2.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/UnitInfo2.dds'))
        
    LayoutHelpers.AtLeftTopIn(main.infoButton, main, width - 110, 5) 
    
    main.infoButton.OnClick = function(self, event)
        createPrioInfoPanel()
    end
    
    -- Dropdowns
    
    main.dropdown1 = Combo(main, 14, 10, nil, nil)
    main.dropdown1.Width:Set(200)
    LayoutHelpers.AtLeftTopIn(main.dropdown1, main, 550, 100)
    main.dropdown1.OnClick = function(self, index, text, skipUpdate)
        if index == 1 then
            mainData.category[1] = nil
        else    
            mainData.category[1] = index - 1
        end    
    end
    
    main.dropdown1:ClearItems()
    main.dropdown1.itemArray = {}
    main.dropdown1.itemArray[1] = "-"
    
    local index = 2
    
    for key, category in categoryID do
            main.dropdown1.itemArray[index] = category
            index = index + 1
    end   
    main.dropdown1:AddItems(main.dropdown1.itemArray, 1)
    
    
    main.dropdown2 = Combo(main, 14, 10, nil, nil)
    main.dropdown2.Width:Set(200)
    LayoutHelpers.AtLeftTopIn(main.dropdown2, main.dropdown1, 0, 30)
    main.dropdown2.OnClick = function(self, index, text, skipUpdate)
        if index == 1 then
            mainData.category[2] = nil
        else    
            mainData.category[2] = index - 1
        end    
    end

    main.dropdown2:AddItems(main.dropdown1.itemArray, 1)

    main.dropdown3 = Combo(main, 14, 10, nil, nil)
    main.dropdown3.Width:Set(200)
    LayoutHelpers.AtLeftTopIn(main.dropdown3, main.dropdown2, 0, 30)
    main.dropdown3.OnClick = function(self, index, text, skipUpdate)
        if index == 1 then
            mainData.category[3] = nil
        else    
            mainData.category[3] = index - 1
        end    
    end

    main.dropdown3:AddItems(main.dropdown1.itemArray, 1)
    
    
    main.dropdown4 = Combo(main, 14, 10, nil, nil)
    main.dropdown4.Width:Set(200)
    LayoutHelpers.AtLeftTopIn(main.dropdown4, main.dropdown3, 0, 30)
    main.dropdown4.OnClick = function(self, index, text, skipUpdate)
        if index == 1 then
            mainData.category[4] = nil
        else    
            mainData.category[4] = index - 1
        end    
    end

    main.dropdown4:AddItems(main.dropdown1.itemArray, 1)
    
    
    ---"Add" button
    main.savePrioSet = UIUtil.CreateButton(main,
        '/dialogs/toggle_btn/toggle-d_btn_up.dds',
        '/dialogs/toggle_btn/toggle-d_btn_down.dds',
        '/dialogs/toggle_btn/toggle-d_btn_over.dds',
        '/dialogs/toggle_btn/toggle-d_btn_dis.dds',
        'Add', 12)
    main.savePrioSet.label:SetFont(UIUtil.bodyFont, 12)
    LayoutHelpers.AtLeftTopIn(main.savePrioSet, main.dropdown4, 0, 70)
    main.savePrioSet.OnClick = function(self, modifiers)
        if main.nameDialog then return end
        
        main.nameDialog = Bitmap(main, UIUtil.SkinnableFile('/dialogs/dialog_02/panel_bmp.dds'), "Marker Name Dialog")
        LayoutHelpers.AtCenterIn(main.nameDialog, GetFrame(0))
        main.nameDialog.Depth:Set(GetFrame(0):GetTopmostDepth() + 10)

        main.nameDialog.label = UIUtil.CreateText(main.nameDialog, "Name your set  (6 letters and caps for good UI):", 16, UIUtil.buttonFont)
        LayoutHelpers.AtLeftTopIn(main.nameDialog.label, main.nameDialog, 35, 30)

        main.nameDialog.cancelButton = UIUtil.CreateButtonStd(main.nameDialog, '/widgets02/small', "<LOC _CANCEL>", 12)
        LayoutHelpers.AtLeftTopIn(main.nameDialog.cancelButton, main.nameDialog, 480, 110)
        
        main.nameDialog.cancelButton.OnClick = function(self, modifiers)
            main.nameDialog:Destroy()
            main.nameDialog = nil
        end

        main.nameDialog.nameEdit = Edit(main.nameDialog)
        LayoutHelpers.AtLeftTopIn(main.nameDialog.nameEdit, main.nameDialog, 35, 60)
        main.nameDialog.nameEdit.Width:Set(283)
        main.nameDialog.nameEdit.Height:Set(main.nameDialog.nameEdit:GetFontHeight())
        main.nameDialog.nameEdit:ShowBackground(false)
        main.nameDialog.nameEdit:AcquireFocus()
        UIUtil.SetupEditStd(main.nameDialog.nameEdit, UIUtil.fontColor, nil, nil, nil, UIUtil.bodyFont, 16, 30)

        main.nameDialog.okButton = UIUtil.CreateButtonStd(main.nameDialog, '/widgets02/small', "<LOC _OK>", 12)
        LayoutHelpers.AtLeftTopIn(main.nameDialog.okButton, main.nameDialog, 30, 110)
        
        main.nameDialog.okButton.OnClick = function(self, modifiers)
            local newName = main.nameDialog.nameEdit:GetText()
            local IDs = {}
            
            for key, val in mainData.category do
                table.insert(IDs, val)
            end  
            
            if IDs[1] then
                mainData.sets[newName] = IDs
                
                if mainData.defCheck == true then
                    mainData.defaults[newName] = true
                else
                    mainData.defaults[newName] = nil  
                end
                
                updateList()
                createPrioButtonSettings()
                SavePrefs()
            else
                print ("Please select at least 1 category")
            end
            main.nameDialog:Destroy()
            main.nameDialog = nil
        end

        main.nameDialog.nameEdit.OnEnterPressed = function(self, text)
            main.nameDialog.okButton.OnClick()
        end
        
    end
    
    ---Delete----
    main.deleteSet = UIUtil.CreateButton(main,
        '/dialogs/toggle_btn/toggle-d_btn_up.dds',
        '/dialogs/toggle_btn/toggle-d_btn_down.dds',
        '/dialogs/toggle_btn/toggle-d_btn_over.dds',
        '/dialogs/toggle_btn/toggle-d_btn_dis.dds',
        'Delete', 12)
    main.deleteSet.label:SetFont(UIUtil.bodyFont, 12)
    LayoutHelpers.AtLeftTopIn(main.deleteSet, main.savePrioSet, 120, 0)
    main.deleteSet.OnClick = function(self, modifiers)
        local SelcetedSet = main.setList:GetSelection()
        if SelcetedSet ~= -1 then
            local name = main.setList.table[SelcetedSet + 1]
            
            mainData.sets[name] = nil
            mainData.defaults[name] = nil
            
            for key, val in mainData.buttonLayout do
                if val == name then
                    mainData.buttonLayout[key] = nil
                end
            end 
            for key, val in mainData.buttonLayoutExpand do
                if val == name then
                    mainData.buttonLayoutExpand[key] = nil
                end
            end 
            
            updateList()
            SavePrefs()
            createPrioButtonSettings()
        else
            print("No set selected")
        end    
    end
    
    ---RESET----
    main.reset = UIUtil.CreateButton(main,
        '/dialogs/toggle_btn/toggle-d_btn_up.dds',
        '/dialogs/toggle_btn/toggle-d_btn_down.dds',
        '/dialogs/toggle_btn/toggle-d_btn_over.dds',
        '/dialogs/toggle_btn/toggle-d_btn_dis.dds',
        'Reset', 12)
    main.reset.label:SetFont(UIUtil.bodyFont, 12)
    LayoutHelpers.AtLeftTopIn(main.reset, main.savePrioSet, 120, 30)
    main.reset.OnClick = function(self, modifiers)
        if main.resetDialog then return end
        
        main.resetDialog = Bitmap(main, UIUtil.SkinnableFile('/dialogs/dialog_02/panel_bmp.dds'), "Marker Name Dialog")
        LayoutHelpers.AtCenterIn(main.resetDialog, GetFrame(0))
        main.resetDialog.Depth:Set(GetFrame(0):GetTopmostDepth() + 10)

        main.resetDialog.label = UIUtil.CreateText(main.resetDialog, "Reset all settings/presets/buttons to default?", 20, UIUtil.buttonFont)
        LayoutHelpers.AtLeftTopIn(main.resetDialog.label, main.resetDialog, 125, 45)

        main.resetDialog.cancelButton = UIUtil.CreateButtonStd(main.resetDialog, '/widgets02/small', "<LOC _CANCEL>", 12)
        LayoutHelpers.AtLeftTopIn(main.resetDialog.cancelButton, main.resetDialog, 480, 110)
        
        main.resetDialog.cancelButton.OnClick = function(self, modifiers)
            main.resetDialog:Destroy()
            main.resetDialog = nil
        end

        main.resetDialog.okButton = UIUtil.CreateButtonStd(main.resetDialog, '/widgets02/small', "<LOC _OK>", 12)
        LayoutHelpers.AtLeftTopIn(main.resetDialog.okButton, main.resetDialog, 30, 110)
        
        main.resetDialog.okButton.OnClick = function(self, modifiers)  
            main.resetDialog:Destroy()
            main.resetDialog = nil
            
            ResetPri()
            createPrioMain() 
        end       
    end

    -------List-----------
    main.setList = ItemList(main, "setList")
    main.setList:SetFont(UIUtil.bodyFont, 14)
    main.setList:SetColors(UIUtil.fontColor, "00000000", "FF000000",  UIUtil.highlightColor, "ffbcfffe")
    main.setList:ShowMouseoverItem(true)

    main.setList.Depth:Set(function() return main.Depth() + 10 end)

    main.setList.Width:Set(200)
    main.setList.Height:Set(200)
    LayoutHelpers.AtLeftTopIn(main.setList, main, 290, 110)
    
    main.setList:AcquireKeyboardFocus(true)
    
    UIUtil.CreateLobbyVertScrollbar(main.setList, 2, -1, -25)
    
    main.setList.table = {}
    local i = 1
    
    for key, val in mainData.sets or {} do
        main.setList:AddItem(key)
        main.setList.table[i] = key
        i = i + 1
    end
    
    main.setList.OnClick = function(self, index)
        main.setList:SetSelection(index)
        local name = main.setList.table[index + 1] 
        updateInfo(name)
    end
    
    ---Information & other text---
    
    main.infoTitle = UIUtil.CreateText(main, 'Info', 20, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(main.infoTitle, main, 80, 50)
    main.infoTitle:SetColor('ff99a3b0')

    main.infoCategories = UIUtil.CreateText(main, 'Categories:', 14, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(main.infoCategories, main, 30, 100)
    main.infoCategories:SetColor('ff99a3b0')
    
    main.infoDefaults = UIUtil.CreateText(main, 'Use defaults:', 14, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(main.infoDefaults, main.infoCategories, 0, 120)
    main.infoDefaults:SetColor('ff99a3b0')
    
    main.presets = UIUtil.CreateText(main, 'Presets', 20, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(main.presets, main, 350, 50)
    main.presets:SetColor('ff99a3b0')
    
    main.selectCat = UIUtil.CreateText(main, 'Categories', 20, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(main.selectCat, main, 600, 50)
    main.selectCat:SetColor('ff99a3b0')
    
    ---CheckBox----
    
    main.CheckBoxDef = UIUtil.CreateCheckbox(main, '/CHECKBOX/')
    main.CheckBoxDef.Height:Set(13)
    main.CheckBoxDef.Width:Set(13)
  
    if mainData.defCheck == true then
        main.CheckBoxDef:SetCheck(true, true)
    else
        main.CheckBoxDef:SetCheck(false, true)
    end
	
    main.CheckBoxDef.OnClick = function(self)
        if(main.CheckBoxDef:IsChecked()) then
            mainData.defCheck = nil
            main.CheckBoxDef:SetCheck(false, true)
        else
            mainData.defCheck = true
            main.CheckBoxDef:SetCheck(true, true)
        end
    end
    
    LayoutHelpers.AtLeftTopIn(main.CheckBoxDef, main.savePrioSet, 2, -25)
    
    main.CheckBoxDef.text = UIUtil.CreateText(main.CheckBoxDef, "Use default priorities", 14, UIUtil.bodyFont)
    
    LayoutHelpers.AtLeftTopIn(main.CheckBoxDef.text, main.CheckBoxDef, 20, -2)
    
    createPrioButtonSettings()
end

function createPrioButtonSettings()
    if main.buttons then
        main.buttons:Destroy()
        main.buttons = nil
    end
    
    if main.hotkeys then
        main.hotkeys:Destroy()
        main.hotkeys = nil
    end                   
    local width = 800
    local height = 250
    
    main.buttons = Bitmap(main, UIUtil.UIFile('/game/Weapon-priorities/infoBack.dds'))
    main.buttons.Width:Set(width)
    main.buttons.Height:Set(height)
    main.buttons:SetAlpha(0.6)
    
    LayoutHelpers.AtLeftTopIn(main.buttons, main, 0, 350)
    
    main.buttons.back = Bitmap(main.buttons, UIUtil.UIFile('/game/Weapon-priorities/buttonsBack2.dds'))
    LayoutHelpers.AtLeftTopIn(main.buttons.back, main.buttons, 0, 0)
    main.buttons.back:DisableHitTest()
    
    main.buttons.but = Checkbox(main.buttons)
    main.buttons.but:SetNewTextures(
        UIUtil.UIFile('/game/Weapon-priorities/ButOn.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/ButOn.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/ButOn.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/ButOn.dds')
        )
    LayoutHelpers.AtLeftTopIn(main.buttons.but, main.buttons, 290, 20)
                                           

    
    main.buttons.hot = Checkbox(main.buttons)
    main.buttons.hot:SetNewTextures(
        UIUtil.UIFile('/game/Weapon-priorities/HotOff.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/HotOff.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/HotOff2.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/HotOff2.dds')
        )
    LayoutHelpers.AtLeftTopIn(main.buttons.hot, main.buttons.but, 100, 4)
    main.buttons.hot.OnCheck = function(control, checked)
        createPrioHotkeys()
    end
    
    local i = 2
    
    while i < 8 do
        main.buttons[i] = Combo(main.buttons, 14, 10, nil, nil)
        main.buttons[i].Width:Set(130)
        LayoutHelpers.AtLeftTopIn(main.buttons[i], main.buttons, 200, 230 - i * 20)
        
        main.buttons[i].Number = i 
        
        main.buttons[i].OnClick = function(self, index, text, skipUpdate)
            if index == 1 then
                mainData.buttonLayout[self.Number] = nil
            else
                mainData.buttonLayout[self.Number] = main.buttons[2].itemArray[index]
            end    
            SavePrefs()
        end
        
        if i == 2 then
            local index = 2
            
            main.buttons[2]:ClearItems()
            main.buttons[2].itemArray = {}
            main.buttons[2].ID = {}
            main.buttons[2].itemArray[1] = "-"
            
            for name, set in mainData.sets do
                main.buttons[2].itemArray[index] = name
                main.buttons[2].ID[name] = index
                index = index + 1
            end 
            
            main.buttons[i]:AddItems(main.buttons[i].itemArray, 1)
            
            if mainData.buttonLayout[i] then
                main.buttons[i]:SetItem(main.buttons[2].ID[mainData.buttonLayout[i]])
            end 
        
        else          
            main.buttons[i]:AddItems(main.buttons[2].itemArray, 1)
            
            if mainData.buttonLayout[i] then
                main.buttons[i]:SetItem(main.buttons[2].ID[mainData.buttonLayout[i]])
            end 
        end    
         
        i = i + 1      
    end
    
    main.buttons.expand = UIUtil.CreateCheckbox(main.buttons, '/CHECKBOX/')
    main.buttons.expand.Height:Set(13)
    main.buttons.expand.Width:Set(13)
    LayoutHelpers.AtLeftTopIn(main.buttons.expand, main.buttons[2], 150, -120)

    if mainData.expand then
        main.buttons.expand:SetCheck(true, true)
    else
        main.buttons.expand:SetCheck(false, true)
    end
	
    main.buttons.expand.OnClick = function(self)
        if(main.buttons.expand:IsChecked()) then
            mainData.expand = nil
            main.buttons.expand:SetCheck(false, true)
        else
            mainData.expand = true
            main.buttons.expand:SetCheck(true, true)
        end
        SavePrefs()
        createPrioButtonSettings()
    end
    
    main.buttons.expandText = UIUtil.CreateText(main.buttons, "More buttons", 14, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(main.buttons.expandText, main.buttons.expand, 20, -2)
    
    if mainData.expand then
        while i < 15 do
            main.buttons[i] = Combo(main.buttons, 14, 10, nil, nil)
            main.buttons[i].Width:Set(130)
            LayoutHelpers.AtLeftTopIn(main.buttons[i], main.buttons[2], 150, 180 - i * 20)
            
            main.buttons[i].Number = i 
            
            main.buttons[i].OnClick = function(self, index, text, skipUpdate)
                if index == 1 then
                    mainData.buttonLayoutExpand[self.Number] = nil
                else
                    mainData.buttonLayoutExpand[self.Number] = main.buttons[2].itemArray[index]
                end    
                SavePrefs()
            end
                    
            main.buttons[i]:AddItems(main.buttons[2].itemArray, 1)
            
            if mainData.buttonLayoutExpand[i] then
                main.buttons[i]:SetItem(main.buttons[2].ID[mainData.buttonLayoutExpand[i]])
            end 
    
            i = i + 1      
        end    
    end
end

function createPrioHotkeys()

    if main.buttons then
        main.buttons:Destroy()
        main.buttons = nil
    end
    
    if main.hotkeys then
        main.hotkeys:Destroy()
        main.hotkeys = nil
    end
    
    local width = 800
    local height = 250
    
    main.hotkeys = Bitmap(main, UIUtil.UIFile('/game/Weapon-priorities/infoBack.dds'))
    main.hotkeys.Width:Set(width)
    main.hotkeys.Height:Set(height)
    main.hotkeys:SetAlpha(0.6)
    
    LayoutHelpers.AtLeftTopIn(main.hotkeys, main, 0, 350)
    
    main.hotkeys.back = Bitmap(main.hotkeys, UIUtil.UIFile('/game/Weapon-priorities/hotkeysBack.dds'))
    LayoutHelpers.AtLeftTopIn(main.hotkeys.back, main.hotkeys, 0, 0)
    main.hotkeys.back:DisableHitTest()

    
    main.hotkeys.but = Checkbox(main.hotkeys)
    main.hotkeys.but:SetNewTextures(
        UIUtil.UIFile('/game/Weapon-priorities/ButOff.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/ButOff.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/ButOff2.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/ButOff2.dds')
        )
    LayoutHelpers.AtLeftTopIn(main.hotkeys.but, main.hotkeys, 290, 23)
    main.hotkeys.but.OnCheck = function(control, checked)
        createPrioButtonSettings()
    end
    
    
    main.hotkeys.hot = Checkbox(main.hotkeys)
    main.hotkeys.hot:SetNewTextures(
        UIUtil.UIFile('/game/Weapon-priorities/HotOn.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/HotOn.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/HotOn.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/HotOn.dds')
        )
    LayoutHelpers.AtLeftTopIn(main.hotkeys.hot, main.hotkeys.but, 100, -2)
    
    
    local i = 2
    
    while i < 7 do
        main.hotkeys[i] = Combo(main.hotkeys, 14, 10, nil, nil)
        main.hotkeys[i].Width:Set(130)
        LayoutHelpers.AtLeftTopIn(main.hotkeys[i], main.hotkeys, 230, 40 + i * 25)
        
        main.hotkeys[i].Number = i - 1 
        
        main.hotkeys[i].OnClick = function(self, index, text, skipUpdate)
            if index == 1 then
                mainData.hotkeys[self.Number] = nil
            else
                mainData.hotkeys[self.Number] = main.hotkeys[2].itemArray[index]
            end    
            SavePrefs()
        end
        
        if i == 2 then
            local index = 2
            
            main.hotkeys[2]:ClearItems()
            main.hotkeys[2].itemArray = {}
            main.hotkeys[2].ID = {}
            main.hotkeys[2].itemArray[1] = "-"
            
            for name, set in mainData.sets do
                main.hotkeys[2].itemArray[index] = name
                main.hotkeys[2].ID[name] = index
                index = index + 1
            end 
            
            main.hotkeys[i]:AddItems(main.hotkeys[i].itemArray, 1)
            
            if mainData.hotkeys[i - 1] and main.hotkeys[2].ID[mainData.hotkeys[i - 1]] then
                main.hotkeys[i]:SetItem(main.hotkeys[2].ID[mainData.hotkeys[i - 1]])
            end 
        
        else          
            main.hotkeys[i]:AddItems(main.hotkeys[2].itemArray, 1)
            
            if mainData.hotkeys[i - 1] and main.hotkeys[2].ID[mainData.hotkeys[i - 1]] then
                main.hotkeys[i]:SetItem(main.hotkeys[2].ID[mainData.hotkeys[i - 1]])
            end 
        end

        main.hotkeys[i].text = UIUtil.CreateText(main.hotkeys[i], 'Custom'..(i - 1)..'     =', 14, UIUtil.bodyFont)
        LayoutHelpers.AtLeftTopIn(main.hotkeys[i].text, main.hotkeys[i], -100, 0)
        main.hotkeys[i].text:SetColor('E0C498')
        main.hotkeys[i].text:DisableHitTest()
         
        i = i + 1      
    end
    
    
    while i < 12 do
        main.hotkeys[i] = Combo(main.hotkeys, 14, 10, nil, nil)
        main.hotkeys[i].Width:Set(130)
        LayoutHelpers.AtLeftTopIn(main.hotkeys[i], main.hotkeys[2], 300, -175 + i * 25)
        
        main.hotkeys[i].Number = i - 1
        
        main.hotkeys[i].OnClick = function(self, index, text, skipUpdate)
            if index == 1 then
                mainData.hotkeys[self.Number] = nil
            else
                mainData.hotkeys[self.Number] = main.hotkeys[2].itemArray[index]
            end    
            SavePrefs()
        end
                
        main.hotkeys[i]:AddItems(main.hotkeys[2].itemArray, 1)
        
        if mainData.hotkeys[i - 1] and main.hotkeys[2].ID[mainData.hotkeys[i - 1]] then
            main.hotkeys[i]:SetItem(main.hotkeys[2].ID[mainData.hotkeys[i - 1]])
        end 
        
        if i < 11 then
            main.hotkeys[i].text = UIUtil.CreateText(main.hotkeys[i], 'Custom'..(i - 1)..'     =', 14, UIUtil.bodyFont)
        else
            main.hotkeys[i].text = UIUtil.CreateText(main.hotkeys[i], 'Custom'..(i - 1)..'   =', 14, UIUtil.bodyFont)
        end
        
        LayoutHelpers.AtLeftTopIn(main.hotkeys[i].text, main.hotkeys[i], -100, 0)
        main.hotkeys[i].text:SetColor('E0C498')
        main.hotkeys[i].text:DisableHitTest()
          
        i = i + 1      
    end
end

function createPrioInfoPanel() --shows unit categories & weapon priorities
   
    if infoPanel then
        infoPanel:Destroy()
        infoPanel = nil
    end
            
    local width = 400
    local height = 520
    
    infoPanel = Bitmap(GetFrame(0))
    infoPanel:SetTexture(UIUtil.UIFile('/game/Weapon-priorities/infoBack.dds'))
    infoPanel.Depth:Set(10000)
    infoPanel.Width:Set(width)
    infoPanel.Height:Set(height)
    infoPanel:SetAlpha(0.75)
        
    LayoutHelpers.AtLeftTopIn(infoPanel, GetFrame(0), 10, 100)
    
    infoPanel.HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' then
            local drag = Dragger()
            local offX = event.MouseX - self.Left()
            local offY = event.MouseY - self.Top()
            
            drag.OnMove = function(dragself, x, y)
                self.Left:Set(x - offX)
                self.Top:Set(y - offY)
                GetCursor():SetTexture(UIUtil.GetCursor('MOVE_WINDOW'))
            end

            drag.OnRelease = function(dragself)    
                GetCursor():Reset()
                drag:Destroy()
            end
            
            PostDragger(self:GetRootFrame(), event.KeyCode, drag)
        end
    end
    
    infoPanel.closeButton =  Button(infoPanel, 
        UIUtil.UIFile('/game/Weapon-priorities/close1.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/close1.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/close2.dds'),
        UIUtil.UIFile('/game/Weapon-priorities/close2.dds'))
        
    LayoutHelpers.AtLeftTopIn(infoPanel.closeButton, infoPanel, width - 20, 5) 
        
    infoPanel.closeButton.OnClick = function(self, event)
        infoPanel:Destroy()
        infoPanel = nil
    end
        
    infoPanel.Unit = UIUtil.CreateText(infoPanel, 'Unit', 20, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(infoPanel.Unit, infoPanel, 30, 5)
    infoPanel.Unit:SetColor('ff99a3b0')
 

    infoPanel.Weapon = UIUtil.CreateText(infoPanel, 'Weapon', 20, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(infoPanel.Weapon, infoPanel, 180, 5)
    infoPanel.Weapon:SetColor('ff99a3b0')   
        
    infoPanel.CheckBox = UIUtil.CreateCheckbox(infoPanel, '/CHECKBOX/')
    infoPanel.CheckBox.Height:Set(13)
    infoPanel.CheckBox.Width:Set(13)
  
    if showUnitCat == true then
        infoPanel.CheckBox:SetCheck(true, true)
    else
        infoPanel.CheckBox:SetCheck(false, true)
    end
	
    infoPanel.CheckBox.OnClick = function(self)
        if(infoPanel.CheckBox:IsChecked()) then
            showUnitCat = nil
            infoPanel.CheckBox:SetCheck(false, true)
        else
            showUnitCat = true
            infoPanel.CheckBox:SetCheck(true, true)
        end
    end
    
    LayoutHelpers.AtLeftTopIn(infoPanel.CheckBox, infoPanel.Unit, -15, 3)
            
    infoPanel.CheckBox2 = UIUtil.CreateCheckbox(infoPanel, '/CHECKBOX/')
    infoPanel.CheckBox2.Height:Set(13)
    infoPanel.CheckBox2.Width:Set(13)
  
    if showTable == true then
        infoPanel.CheckBox2:SetCheck(true, true)
    else
        infoPanel.CheckBox2:SetCheck(false, true)
    end
	
    infoPanel.CheckBox2.OnClick = function(self)
        if(infoPanel.CheckBox2:IsChecked()) then
            showTable = nil
            infoPanel.CheckBox2:SetCheck(false, true)
        else
            showTable = true
            infoPanel.CheckBox2:SetCheck(true, true)
        end
    end
    
    LayoutHelpers.AtLeftTopIn(infoPanel.CheckBox2, infoPanel.Weapon, 145, 0)
        
    infoPanel.CheckBoxText = UIUtil.CreateText(infoPanel, 'Table', 12, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(infoPanel.CheckBoxText, infoPanel.CheckBox2, 15, -2)
    infoPanel.CheckBoxText:SetColor('ff99a3b0') 
    
end

function updatePrioInfoPanel(unit)
    local unitBP = unit:GetBlueprint()
    
    local function CreateWepPriorities(key)
        local prioTbl = unitBP.Weapon[key].TargetPriorities
        local line = 0 
        
        if infoPanel.update.wepPrio then
            infoPanel.update.wepPrio:Destroy()        
            infoPanel.update.wepPrio = nil
        end    

        infoPanel.update.wepPrio = Bitmap(infoPanel.update, UIUtil.UIFile('/game/ability_brd/chat_brd_m.dds'))
        infoPanel.update.wepPrio.Width:Set(200)
        infoPanel.update.wepPrio.Height:Set(450)
        LayoutHelpers.AtLeftTopIn(infoPanel.update.wepPrio, infoPanel.update.dropdown, 0, 20)
        
        for key, val in prioTbl do
            if line == 0 then
                infoPanel.update.wepPrio[key] = UIUtil.CreateText(infoPanel.update.wepPrio, val, 14, "Calibri")
                LayoutHelpers.AtLeftTopIn(infoPanel.update.wepPrio[key], infoPanel.update.wepPrio, 10, 10)
                infoPanel.update.wepPrio[key]:SetColor('B59F7B')
                line = line + 1
            else
                infoPanel.update.wepPrio[key] = UIUtil.CreateText(infoPanel.update.wepPrio, val, 14, "Calibri")
                LayoutHelpers.AtLeftTopIn(infoPanel.update.wepPrio[key],  infoPanel.update.wepPrio, 10 , 10 + (line * 20))
                infoPanel.update.wepPrio[key]:SetColor('B59F7B')
                line = line + 1
            end
        end
    end
    
    
        
    if infoPanel.update then
        infoPanel.update:Destroy()        
        infoPanel.update = nil
    end
    
    infoPanel.update = Bitmap(infoPanel, UIUtil.UIFile('/game/ability_brd/chat_brd_m.dds'))
    infoPanel.update.Width:Set(0)
    infoPanel.update.Height:Set(0)
    LayoutHelpers.AtLeftTopIn(infoPanel.update, infoPanel, 0, 0)


    infoPanel.update.text = Bitmap(infoPanel.update, UIUtil.UIFile('/game/ability_brd/chat_brd_m.dds'))
    infoPanel.update.text.Width:Set(150)
    infoPanel.update.text.Height:Set(450)
    LayoutHelpers.AtLeftTopIn(infoPanel.update.text, infoPanel, 20, 60)
    
    infoPanel.update.text.BpID = UIUtil.CreateText(infoPanel.update.text, unitBP.BlueprintId, 14, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(infoPanel.update.text.BpID,infoPanel.Unit, 45, 5)
    infoPanel.update.text.BpID:SetColor('FFEEC9')
    
    local line = 0
    
    if showUnitCat then
        for key, val in unitBP.Categories do
            if line == 0 then
                infoPanel.update.text[key] = UIUtil.CreateText(infoPanel.update.text, unitBP.Categories[key], 12, "Calibri")
                LayoutHelpers.AtLeftTopIn(infoPanel.update.text[key], infoPanel.update.text, 5, 5)
                infoPanel.update.text[key]:SetColor('B59F7B')
                line = line + 1
            else
                infoPanel.update.text[key] = UIUtil.CreateText(infoPanel.update.text, unitBP.Categories[key], 12, "Calibri")
                LayoutHelpers.AtLeftTopIn(infoPanel.update.text[key], infoPanel.update.text, 5 , 5 + (line * 17))
                infoPanel.update.text[key]:SetColor('B59F7B')
                line = line + 1
            end   
        end
    end


    if unitBP.Weapon[1] and not showTable then
        local firstWep
        
        infoPanel.update.dropdown = Combo(infoPanel.update.text, 14, 10, nil, nil)
        infoPanel.update.dropdown.Width:Set(200)
        LayoutHelpers.AtLeftTopIn(infoPanel.update.dropdown, infoPanel, 180, 40)
        infoPanel.update.dropdown.OnClick = function(self, index, text, skipUpdate)
            CreateWepPriorities(self.keyMap[index])
        end
    
        infoPanel.update.dropdown:ClearItems()
        infoPanel.update.dropdown.itemArray = {}
        infoPanel.update.dropdown.keyMap = {}

        if unitBP.Weapon then
            local index = 1
            for key, weapon in unitBP.Weapon do
                local priorities = weapon.TargetPriorities
                if priorities then
                    if not firstWep then 
                        CreateWepPriorities(key)
                        firstWep = true
                    end
                    infoPanel.update.dropdown.itemArray[index] = weapon.Label
                    infoPanel.update.dropdown.keyMap[index] = key
                    index = index + 1
                end
            end   
        end
        infoPanel.update.dropdown:AddItems(infoPanel.update.dropdown.itemArray, 1)
        
    
    elseif unitBP.Weapon[1] and showTable then
    
        infoPanel.update.weaponPriorities = Bitmap(infoPanel.update, UIUtil.UIFile('/game/Weapon-priorities/infoBack.dds'))
        infoPanel.update.weaponPriorities.Width:Set(700)
        infoPanel.update.weaponPriorities.Height:Set(470)
        LayoutHelpers.AtLeftTopIn(infoPanel.update.weaponPriorities, infoPanel, 170, 50)
        infoPanel.update.weaponPriorities:SetAlpha(0.8)
    
        local tbl = unitBP.Weapon
        local deltaX = 0
        local deltaX2 = 0
        local column = 1
        
        for wepNum, weapon in unitBP.Weapon do
            local line = 0 
            local prioTb = unitBP.Weapon[wepNum].TargetPriorities
            
            
            if prioTb then
                infoPanel.update.weaponPriorities[wepNum] = UIUtil.CreateText(infoPanel.update.weaponPriorities, unitBP.Weapon[wepNum].Label, 14, "Calibri")
                infoPanel.update.weaponPriorities[wepNum]:SetColor('ff99a3b0')
                
                if column < 6 then
                    LayoutHelpers.AtLeftTopIn(infoPanel.update.weaponPriorities[wepNum], infoPanel.update.weaponPriorities, 10 + deltaX, 10)
                else
                    LayoutHelpers.AtLeftTopIn(infoPanel.update.weaponPriorities[wepNum], infoPanel.update.weaponPriorities, 10 + deltaX2, 220)
                    deltaX2 = deltaX2 + 140
                end
            
                for key, val in prioTb do
                    if line == 0 then
                        infoPanel.update.weaponPriorities[wepNum][key] = UIUtil.CreateText(infoPanel.update.weaponPriorities, val, 12, "Calibri")
                        LayoutHelpers.AtLeftTopIn(infoPanel.update.weaponPriorities[wepNum][key], infoPanel.update.weaponPriorities[wepNum], 0, 30)
                        infoPanel.update.weaponPriorities[wepNum][key]:SetColor('B59F7B')
                    else
                        infoPanel.update.weaponPriorities[wepNum][key] = UIUtil.CreateText(infoPanel.update.weaponPriorities, val, 12, "Calibri")
                        LayoutHelpers.AtLeftTopIn(infoPanel.update.weaponPriorities[wepNum][key], infoPanel.update.weaponPriorities[wepNum], 0, 30 + (15 * line))
                        infoPanel.update.weaponPriorities[wepNum][key]:SetColor('B59F7B')
                    end 
                    line = line + 1
                end
                column = column + 1
                deltaX = deltaX + 140
            end
        end
    end
end

function prioUpdate(control, unitList) 
    while true do
        if unitList[1] and not IsDestroyed(control) then
            local priority = UnitData[unitList[1]:GetEntityId()].WepPriority
            --For now it shows prio state only for the first unit in table. We can add loop here, which checks all selected units states
            --and add question mark if they are different(same as for fire modes), but it's all about performance so idk.
            
            if control.prioState then
                control.prioState:Destroy()
                control.prioState = nil
            end

            if not priority then
                control.prioState = Bitmap(control, UIUtil.UIFile(prioStateTextures.Default))
            elseif prioStateTextures[priority] then
                control.prioState = Bitmap(control, UIUtil.UIFile(prioStateTextures[priority]))
            else
                control.prioState = Bitmap(control, UIUtil.UIFile('/game/Weapon-priorities/smallBlack.dds'))
                control.prioState.text = UIUtil.CreateText(control.prioState, priority, 12, "Calibri")
                
                LayoutHelpers.AtLeftTopIn(control.prioState.text, control, 7, 1)
                control.prioState.text:SetColor('ffffff')
            end
            
            LayoutHelpers.AtRightTopIn(control.prioState, control, 2, 4)
            control.prioState:DisableHitTest()
            
            WaitSeconds(0.1)
        else 
            break
        end
    end
end

local function RetaliateInitFunction(control, unitList)
    KillThread(updater)
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
    
    if unitList[1] then --Launches prioUpdate thread if unit selected
        updater = ForkThread(prioUpdate, control, unitList)
        if infoPanel then
            updatePrioInfoPanel(unitList[1])
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
    if not currentSelection[1] or currentSelection[1]:IsDead() then return '' end
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
    if not currentSelection[1] or currentSelection[1]:IsDead() then return '' end
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
    if not unit or unit:IsDead() or unit:IsOverchargePaused() then return end
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
    if not unit or unit:IsDead() then return end
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
