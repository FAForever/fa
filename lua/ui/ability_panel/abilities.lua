local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Grid = import('/lua/maui/grid.lua').Grid
local GameCommon = import('/lua/ui/game/gamecommon.lua')
local Button = import('/lua/maui/button.lua').Button
local Tooltip = import('/lua/ui/game/tooltip.lua')
local TooltipInfo = import('/lua/ui/help/tooltips.lua')
local Prefs = import('/lua/user/prefs.lua')
local Keymapping = import('/lua/keymap/defaultKeyMap.lua').defaultKeyMap
local CM = import('/lua/ui/game/commandmode.lua')
local UIMain = import('/lua/ui/uimain.lua')


local oldCheckbox = import('/lua/maui/checkbox.lua').Checkbox
local Checkbox = Class( oldCheckbox ) {

    HandleEvent = function(self, event)
        if event.Type == 'ButtonDClick' and self.OnDoubleClick then
            self:OnDoubleClick(event.Modifiers)
            if self.mClickCue != "NO_SOUND" then
                if self.mClickCue then
                    local sound = Sound({Cue = self.mClickCue, Bank = "Interface",})
                    PlaySound(sound)
                end
            end
            eventHandled = true
        else
            oldCheckbox.HandleEvent(self, event)
        end
    end,
}

controls = {
    mouseoverDisplay = false,
    orderButtonGrid = false,
    bg = false,
    orderGlow = false,
    NewButtonGlows = false,
    parent = false,
}

# positioning controls, don't belong to file
local layoutVar = false
local glowThread = {}
local NewGlowThread = {}
savedParent = false
Panel_State = 'closed'

# these variables control the number of slots available for orders
# though they are fixed, the code is written so they could easily be made soft
local numSlots = 5
local firstAltSlot = 1
local vertRows = 5
local horzRows = 1
local vertCols = numSlots/vertRows
local horzCols = numSlots/horzRows

local orderCheckboxMap = false
local FlashTime = 5
local SpecialAbilities = import('/lua/abilitydefinition.lua').abilities
local availableOrders = {}
local defaultOrdersTable = {}
local ButtonParams = {}

-- called from gamemain to create control
function SetupOrdersControl(parent)
    controls.parent = parent
	savedParent = parent

    -- create our copy of orders table
    standardOrdersTable = table.deepcopy(defaultOrdersTable)

    SetLayout(UIUtil.currentLayout)

    -- setup command mode behaviors
    import('/lua/ui/game/commandmode.lua').AddStartBehavior(
        function(commandMode, data)
			--LOG('DATA ADDStart ' .. repr(data))
            local orderCheckbox = orderCheckboxMap[data]
            if orderCheckbox then
                orderCheckbox:SetCheck(true)
            end
        end
    )
	
	local oldSelection = GetSelectedUnits()
	
    import('/lua/ui/game/commandmode.lua').AddEndBehavior(
        function(commandMode, data)
            local orderCheckbox = orderCheckboxMap[data]
            if orderCheckbox then
                orderCheckbox:SetCheck(false)
            end
        end
    )    
end

function SetLayout(layout)
    layoutVar = layout

    -- clear existing orders
    orderCheckboxMap = {}
    if controls and controls.orderButtonGrid then
        controls.orderButtonGrid:DeleteAndDestroyAll(true)
    end

    CreateControls()
    import('/lua/ui/ability_panel/layout/abilities_mini.lua').SetLayout()
	
	--trigger this, just incase an order is added from the ui or sim on game start
	SetAvailableOrders()
end

function CreateControls()
	--clear any mouse displays we have
    if controls.mouseoverDisplay then
        controls.mouseoverDisplay:Destroy()
        controls.mouseoverDisplay = false
    end
	
	controls.collapseArrow = Checkbox(savedParent)
    Tooltip.AddCheckboxTooltip(controls.collapseArrow, 'mfd_collapse')
	controls.collapseArrow.OnCheck = function(self, checked)
        ToggleAbilityPanel()
    end
	
    if not controls.bg then
        controls.bg = Group(savedParent)
    end
	    
    controls.bg.panel = Bitmap(controls.bg)
    controls.bg.leftBrace = Bitmap(controls.bg)
    controls.bg.leftGlow = Bitmap(controls.bg)
    controls.bg.rightGlowTop = Bitmap(controls.bg)
    controls.bg.rightGlowMiddle = Bitmap(controls.bg)
    controls.bg.rightGlowBottom = Bitmap(controls.bg)
   	
    --if not controls.orderButtonGrid then
        CreateOrderButtonGrid()
    --end
end

--button grid
function CreateOrderButtonGrid()
    controls.orderButtonGrid = Grid(controls.bg, GameCommon.iconWidth, GameCommon.iconHeight)
    controls.orderButtonGrid:SetName("Orders Grid")
	controls.orderButtonGrid:DeleteAll()
end

-- Add Reinforcement
function AddReinforcements(list)
	
	local List = list.List
	LOG(repr(List))
	local delay = List.delay
	AbilityName = "CallReinforcement"
	table.insert(availableOrders, "CallReinforcement")
	defaultOrdersTable[AbilityName] = {bitmapId="deploy", enabled=false, helpText="deploy", preferredSlot=2, script="Recall", ExtraInfo={CoolDownTime = delay}}
	defaultOrdersTable[AbilityName].behavior = AbilityButtonBehavior
	defaultOrdersTable[AbilityName].behaviordoubleclick = AbilityButtonBehaviorDoubleClick
	ButtonParams[AbilityName] = { CoolDownTime = true, CurrCoolDownTime = delay, CoolDownEnabled = false, CoolDownTimerValue = delay }
    LOG(repr(ButtonParams[AbilityName]))
	SetAvailableOrders()
	DisableButtonStartCoolDown(AbilityName)
	
end

--add an ability
function AddSpecialAbility(data)
	local AbilityName = data.AbilityName
	local ability = SpecialAbilities[AbilityName] or false
	LOG(repr(ability))
	local AddAbility = true
	
	for k,v in availableOrders do
		if v == AbilityName then 
			AddAbility = false
		end
	end
		
	if AddAbility and ability then
		table.insert(availableOrders, AbilityName)
		defaultOrdersTable[AbilityName] = ability
        defaultOrdersTable[AbilityName].behavior = AbilityButtonBehavior
        defaultOrdersTable[AbilityName].behaviordoubleclick = AbilityButtonBehaviorDoubleClick
        LOG("adding ability")
        LOG(AbilityName)
		ButtonParams[AbilityName] = { Enabled = true, CoolDownTime = false, CurrCoolDownTime = false, CoolDownEnabled = false, CoolDownTimerValue = 0 }
		SetAvailableOrders()
	end	
end

--remove an ability
function RemoveSpecialAbility(data)
	local AbilityName = data.AbilityName
	local ability = SpecialAbilities[AbilityName] or false
	local RemoveAbility = false
	local id = false
	
	for k,v in availableOrders do
		if v == AbilityName then 
			RemoveAbility = true
			id = k
		end
	end
	
	if RemoveAbility then 
		table.remove(availableOrders, id)
		defaultOrdersTable[AbilityName] = nil
		ButtonParams[AbilityName] = nil
		SetAvailableOrders()
	end
end

--enable an ability button on ability panel
function EnableSpecialAbility(data)
	local AbilityName = data.AbilityName
	if orderCheckboxMap[AbilityName] then 
		orderCheckboxMap[AbilityName]:Enable()
        LOG("enable")
		ButtonParams[AbilityName].Enabled = true
		ForkThread(newOrderGlow, orderCheckboxMap[AbilityName])
	end
end

--disable an ability button on ability panel
function DisableSpecialAbility(data)
	local AbilityName = data.AbilityName
	if orderCheckboxMap[AbilityName] then 
		orderCheckboxMap[AbilityName]:Disable()
		ButtonParams[AbilityName].Enabled = false
		
		if glowThread[AbilityName] then 
			KillThread(glowThread[AbilityName])
		end
		
		if controls.NewButtonGlows[AbilityName] then 
			controls.NewButtonGlows[AbilityName]:SetNeedsFrameUpdate(false)
			controls.NewButtonGlows[AbilityName]:Destroy()
			controls.NewButtonGlows[AbilityName] = false
		end
	
		NewGlowThread[AbilityName] = false
	end
end

--set available orders on the abilities panel
function SetAvailableOrders()

    -- clear existing buttons
	KillTimers()
    orderCheckboxMap = {}
	if controls.orderButtonGrid then 
		controls.orderButtonGrid:DestroyAllItems(true)
	end

    -- create our copy of orders table
    standardOrdersTable = table.deepcopy(defaultOrdersTable)
	
    --count our buttons
    local numValidOrders = 0
    for i, v in availableOrders do
        if standardOrdersTable[v] then
            numValidOrders = numValidOrders + 1
        end
    end
	    
    if numValidOrders != 0 and numValidOrders <= numSlots then
        CreateAltOrders()
    end
    
	if controls.orderButtonGrid then 
		controls.orderButtonGrid:EndBatch()
	end
	
end

--creates the buttons for the alt orders, placing them as possible
--THIS IS IMPORTANT TO REMEMBER -- IF 2 ORDERS ARE SENT IN THE SAME GAME TICK THEY WILL BE PLACED ON THE PANEL AS POSSIBLE
--THIS MEANS IF 2 BUTTONS ARE SENT TO THE PANEL AND THEY BOTH HAVE THE SAME SLOT NUMBER THEY WILL BE PLACED IN SLOTS 1 AND 2
--IF THE 2 BUTTONS ARE SENT IN DIFFERENT GAME TICKS AND THEY BOTH WANT TO GO INTO THE SAME SLOT THEN THE BUTTON IN THE SLOT IS REPLACED BY BUTTON 2.
function CreateAltOrders()
		    
    -- determine what slots to put abilities into
    -- we first want a table of slots we want to fill, and what orders want to fill them
    local desiredSlot = {}
    for index, availOrder in availableOrders do
        if standardOrdersTable[availOrder] then 
            local preferredSlot = standardOrdersTable[availOrder].preferredSlot
            if not desiredSlot[preferredSlot] then
                desiredSlot[preferredSlot] = {}
            end
            table.insert(desiredSlot[preferredSlot], availOrder)
        end
    end

    -- now go through that table and determine what doesn't fit and look for slots that are empty
    -- since this is only alt orders, just deal with slots 7-12
    local orderInSlot = {}
    
    # go through first time and add all the first entries to their preferred slot
    for slot = firstAltSlot, numSlots do
        if desiredSlot[slot] then
            orderInSlot[slot] = desiredSlot[slot][1]
        end
    end

    -- now put any additional entries wherever they will fit
    for slot = firstAltSlot,numSlots do
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
                        # could break here, but don't, then you'll know how many extra orders you have
                    end
                end
            end
        end
    end

    -- now map it the other direction so it's order to slot
    local slotForOrder = {}
    for slot, order in orderInSlot do
        slotForOrder[order] = slot
    end
    
    -- create the alt order buttons
    for index, availOrder in availableOrders do
        if not standardOrdersTable[availOrder] then continue end   # skip any orders we don't have in our table

		local orderInfo = standardOrdersTable[availOrder] or AbilityInformation[availOrder]
		local orderCheckbox = AddOrder(orderInfo, slotForOrder[availOrder], true)
		orderCheckbox._order = availOrder
            
		if standardOrdersTable[availOrder].script then
			orderCheckbox._script = standardOrdersTable[availOrder].script
		end
 
		orderCheckboxMap[availOrder] = orderCheckbox
    end
end

--this function adds the order to the slot AND sets up all the events and effects for the button.
function AddOrder(orderInfo, slot, batchMode)
    batchMode = batchMode or false
    
    local checkbox = Checkbox(controls.orderButtonGrid, GetOrderBitmapNames(orderInfo.bitmapId))
	local button = orderInfo.script
	
    -- set the info in to the data member for retrieval
    checkbox._data = orderInfo
    
    -- set up initial help text
    checkbox._curHelpText = orderInfo.helpText

    -- set up click handler
    checkbox.OnClick = orderInfo.behavior
    checkbox.OnDoubleClick = orderInfo.behaviordoubleclick
    
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
            self.Height:Set(function() return checkbox.Height() + (checkbox.Height() * alpha*.5) end)
            self.Width:Set(function() return checkbox.Height() + (checkbox.Height() * alpha*.5) end)
            self.Alpha = alpha
            self:SetAlpha(alpha*.45)
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
	LOG("this order ...")
    LOG(repr(orderInfo))
    LOG(repr(orderInfo.ExtraInfo))
	if orderInfo.ExtraInfo.CoolDownTime then 
        LOG("yeps")
		checkbox.buttonText = UIUtil.CreateText(checkbox, '', 18, UIUtil.bodyFont)
		checkbox.buttonText:SetColor('ffffffff')
        checkbox.buttonText:SetDropShadow(true)
        LayoutHelpers.AtBottomIn(checkbox.buttonText, checkbox)
        LayoutHelpers.AtHorizontalCenterIn(checkbox.buttonText, checkbox)
        checkbox.buttonText:DisableHitTest()
		ButtonParams[button].CoolDownTime = orderInfo.ExtraInfo.CoolDownTime
		--checkbox.buttonText:SetHidden(true)
	end
	
	if ButtonParams[button].CoolDownEnabled then 
		StartCoolDownTimer(button)
	end
	
    LOG("this button..")
    LOG(repr(ButtonParams[button]))
	if not ButtonParams[button].Enabled then 
        LOG("this is not enabled")
		checkbox:Disable()
	end
    
	--ok if the button fires a counted projectile weapon (silo).. we can use this to update the number of projectiles
	--you will have to add the function to the orderinfo.ButtonTextFunc in this file.
    if orderInfo.ButtonTextFunc then
        checkbox.buttonText = UIUtil.CreateText(checkbox, '', 18, UIUtil.bodyFont)
        checkbox.buttonText:SetText(orderInfo.ButtonTextFunc(checkbox))
        checkbox.buttonText:SetColor('ffffffff')
        checkbox.buttonText:SetDropShadow(true)
        LayoutHelpers.AtBottomIn(checkbox.buttonText, checkbox)
        LayoutHelpers.AtHorizontalCenterIn(checkbox.buttonText, checkbox)
        checkbox.buttonText:DisableHitTest()
        checkbox.buttonText:SetNeedsFrameUpdate(true)
        checkbox.buttonText.OnFrame = function(self, delta)
            self:SetText(orderInfo.ButtonTextFunc(checkbox))
        end
    end

    -- set up tooltips
    checkbox.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            if controls.orderGlow[button] then
                controls.orderGlow[button]:Destroy()
                controls.orderGlow[button] = false
            end                
            CreateMouseoverDisplay(self, self._curHelpText, 1)
            glowThread[button] = CreateOrderGlow(self)
        elseif event.Type == 'MouseExit' then
            if controls.mouseoverDisplay then
                controls.mouseoverDisplay:Destroy()
                controls.mouseoverDisplay = false
            end
            if controls.orderGlow[button] then
                controls.orderGlow[button]:Destroy()
                controls.orderGlow[button] = false
                KillThread(glowThread[button])
            end
        end
        Checkbox.HandleEvent(self, event)
    end

    -- calculate row and column, remove old item, add new checkbox
    local cols, rows = controls.orderButtonGrid:GetDimensions()
    local row = math.ceil(slot / cols)
    local col = math.mod(slot - 1, cols) + 1
    controls.orderButtonGrid:DestroyItem(col, row, batchMode)
    controls.orderButtonGrid:SetItem(checkbox, col, row, batchMode)
	
	if ButtonParams[button].Enabled then 
		ForkThread(newOrderGlow, checkbox)
	end
	
    return checkbox
end

--mouse over glow
function CreateOrderGlow(parent)

	local button = parent._data.script
	if controls.NewButtonGlows[button] then 
		controls.NewButtonGlows[button]:Destroy()
		controls.NewButtonGlows[button] = false
	end
	
    controls.orderGlow[button] = Bitmap(parent, UIUtil.UIFile('/game/orders/glow-02_bmp.dds'))
    LayoutHelpers.AtCenterIn(controls.orderGlow[button], parent)
    controls.orderGlow[button]:SetAlpha(0.0)
    controls.orderGlow[button]:DisableHitTest()
    controls.orderGlow[button]:SetNeedsFrameUpdate(true)
    local alpha = 0.0
    local incriment = true
    controls.orderGlow[button].OnFrame = function(self, deltaTime)
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
        if controls.orderGlow[button] and controls.orderGlow[button].SetAlpha then
            controls.orderGlow[button]:SetAlpha(alpha)
        end
    end     
end

--when a new button is added OR enabled make it glow for a while..
function CreateNewAbilityGlow(parent)
	local button = parent._data.script
	if button then
    controls.NewButtonGlows[button] = Bitmap(parent, UIUtil.UIFile('/game/orders/glow-02_bmp.dds'))
    LayoutHelpers.AtCenterIn(controls.NewButtonGlows[button], parent)
    controls.NewButtonGlows[button]:SetAlpha(0.0)
    controls.NewButtonGlows[button]:DisableHitTest()
    controls.NewButtonGlows[button]:SetNeedsFrameUpdate(true)
    local alpha = 0.0
    local incriment = true
	local StartTime = GetGameTimeSeconds()
    controls.NewButtonGlows[button].OnFrame = function(self, deltaTime)
		if button and controls.orderGlow[button] then
			if (GetGameTimeSeconds() - StartTime) > FlashTime then 
				controls.NewButtonGlows[button]:SetNeedsFrameUpdate(false)
			end
			
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
			
			if controls.orderGlow[button].SetAlpha then
				controls.NewButtonGlows[button]:SetAlpha(alpha)
			end
		end
    end   
	end
end

--when a new button is added to our panel, make it flash for a few seconds.. 
function newOrderGlow(parent)
	local button = parent._data.script
	NewGlowThread[button] = CreateNewAbilityGlow(parent)
	WaitSeconds(FlashTime)
	
	if controls.NewButtonGlows[button] then 
		controls.NewButtonGlows[button]:Destroy()
		controls.NewButtonGlows[button] = false
	end
	
	--KillThread(NewGlowThread[button])
	NewGlowThread[button] = false
end

--mouse over text we can use the loc system or just plain text.
--obviously the loc system is better.. if you use the loc system make sure you add the loc entries to the loc table.
function CreateMouseoverDisplay(parent, ID)
    if controls.mouseoverDisplay then
        controls.mouseoverDisplay:Destroy()
        controls.mouseoverDisplay = false
    end
    
    if not Prefs.GetOption('tooltips') then return end
    
    local createDelay = Prefs.GetOption('tooltip_delay') or 0
    
    local text = TooltipInfo['Tooltips'][ID]['title'] or ID
    local desc = TooltipInfo['Tooltips'][ID]['description'] or ID
    
    if TooltipInfo['Tooltips'][ID]['keyID'] and TooltipInfo['Tooltips'][ID]['keyID'] != "" then
        for i, v in Keymapping do
            if v == TooltipInfo['Tooltips'][ID]['keyID'] then
                local properkeyname = import('/lua/ui/dialogs/keybindings.lua').formatkeyname(i)
                text = LOCF("%s (%s)", text, properkeyname)
                break
            end
        end
    end
    
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

-- helper function to create order bitmaps
-- note, your bitmaps must be in /game/orders/ and have the standard button naming convention
function GetOrderBitmapNames(bitmapId)
    if bitmapId == nil then
        LOG("Error - nil bitmap passed to GetOrderBitmapNames")
        bitmapId = "basic-empty"    # TODO do I really want to default it?
    end
    
    local button_prefix = "/game/orders/" .. bitmapId .. "_btn_"
    return UIUtil.SkinnableFile(button_prefix .. "up.dds")
        ,  UIUtil.SkinnableFile(button_prefix .. "up_sel.dds")
        ,  UIUtil.SkinnableFile(button_prefix .. "over.dds")
        ,  UIUtil.SkinnableFile(button_prefix .. "over_sel.dds")
        ,  UIUtil.SkinnableFile(button_prefix .. "dis.dds")
        ,  UIUtil.SkinnableFile(button_prefix .. "dis_sel.dds")
        , "UI_Action_MouseDown", "UI_Action_Rollover"   # sets click and rollover cues
end


# ability button behaviour
function AbilityButtonBehavior(self, modifiers)
    if self:IsChecked() then
        CM.EndCommandMode(true)

    else
		if self._data.callBack then
			SimCallback({Func = self._data.callBack, Args = { From=GetFocusArmy()}})
		else
        # anything in the modeData is passed to userscriptcommand.lua from commandmode.lua
			local modeData = {
				name = 'RULEUCC_Script',
				AbilityName = self._data.abilityname,
				TaskName = self._script,
				cursor = self._data.cursor,
				OrderIcon = self._data.OrderIcon,
				MouseDecal = self._data.MouseDecal,
				Usage = self._data.usage,
				SelectedUnits = GetSelectedUnits(),
			}
			CM.StartCommandMode("order", modeData)
		end
    end
end

function AbilityButtonBehaviorDoubleClick(self, modifiers)

    if self:IsChecked() then
        CM.EndCommandMode(true)
    else
		if self._data.callBack then
			SimCallback({Func = self._data.callBack, Args = { From=GetFocusArmy()}})
		else
        # anything in the modeData is passed to userscriptcommand.lua from commandmode.lua
        local modeData = {
            name = 'RULEUCC_Script',
            AbilityName = self._data.abilityname,
            TaskName = self._script,
            cursor = self._data.cursor,
            OrderIcon = self._data.OrderIcon,
            MouseDecal = self._data.MouseDecal,
            Usage = self._data.usage,
            SelectedUnits = GetSelectedUnits(),
			}
			CM.StartCommandMode("order", modeData)
		end
	end
end


--adds the timer text to the button.. 
function StartCoolDownTimer(buttonName)
	local button = false
    if orderCheckboxMap[buttonName] then 
		button = orderCheckboxMap[buttonName]
	
		ButtonParams[buttonName].CoolDownEnabled = true
		local Timer = ButtonParams[buttonName].CoolDownTimerValue or 0
		local CountDown = ButtonParams[buttonName].CoolDownTime or button._data.ExtraInfo.CoolDownTime
		local curTime = ButtonParams[buttonName].CurrCoolDownTime or button._data.ExtraInfo.CoolDownTime
		local startTime = GetGameTimeSeconds()
	
		button.buttonText:SetNeedsFrameUpdate(true)
	
		UpdateTime = function(self)
			self:SetText(curTime)
			ButtonParams[buttonName].CurrCoolDownTime = curTime
		end
	
		button.buttonText.OnFrame = function(self, delta)
			Timer = Timer + delta
			ButtonParams[buttonName].CoolDownTimerValue = Timer
			if curTime <= 0 then
				EnableButtonStopCoolDown(buttonName)
			end
            
			if GetGameTimeSeconds() - startTime > 1 then
				curTime = curTime - 1
				startTime = GetGameTimeSeconds()
				UpdateTime(self)
			end	
		end
	end
end

--needs work.. the timer does not restart once its done.. 
--stop and destroy the cooldown timer.
function StopCoolDownTimer(buttonName)
	local button = false
    if orderCheckboxMap[buttonName] then 
		button = orderCheckboxMap[buttonName]
		ButtonParams[buttonName].CoolDownEnabled = false
		ButtonParams[buttonName].CurrCoolDownTime = button._data.ExtraInfo.CoolDownTime
		ButtonParams[buttonName].CoolDownTimerValue = 0
		
		--stop the frame here and set the text to nil
		button.buttonText:SetNeedsFrameUpdate(false)
		button.buttonText:SetText('')
	end
end

--enable the ability button and kill the cooldown timer
function EnableButtonStopCoolDown(buttonName)
	local data = {}
	data.AbilityName = buttonName
	EnableSpecialAbility(data)
	StopCoolDownTimer(buttonName)
end

--disable the button and start the cooldown timer
function DisableButtonStartCoolDown(buttonName)
	local data = {}
	data.AbilityName = buttonName
	DisableSpecialAbility(data)
	StartCoolDownTimer(buttonName)
end

--kill button timers. (cooldowns)
function KillTimers()
	for k,v in ButtonParams do
		if ButtonParams[k].CoolDownEnabled then 
			local button = orderCheckboxMap[k]
			button.buttonText:SetNeedsFrameUpdate(false)
		end
	end
end

--restart buttons that have timers on them (cooldowns)
function RestartTimers()
	for k,v in ButtonParams do
		if ButtonParams[k].CoolDownEnabled then 
			StartCoolDownTimer(k)
		end
	end
end

--controls when the user clicks the toggle to show the ability panel.
function ToggleAbilityPanel(state)
    if import('/lua/ui/game/gamemain.lua').gameUIHidden then
        return
    end
    if UIUtil.GetAnimationPrefs() then
        if state or controls.bg:IsHidden() then
            PlaySound(Sound({Cue = "UI_Score_Window_Open", Bank = "Interface"}))
            controls.bg:Show()
            controls.bg:SetNeedsFrameUpdate(true)
            controls.bg.OnFrame = function(self, delta)
                local newLeft = self.Left() + (1000*delta)
                if newLeft > savedParent.Left()+15 then
                    newLeft = savedParent.Left()+15
                    self:SetNeedsFrameUpdate(false)
                end
                self.Left:Set(newLeft)
            end
            controls.collapseArrow:SetCheck(false, true)
        else
            PlaySound(Sound({Cue = "UI_Score_Window_Close", Bank = "Interface"}))
            controls.bg:SetNeedsFrameUpdate(true)
            controls.bg.OnFrame = function(self, delta)
                local newLeft = self.Left() - (1000*delta)
                if newLeft < savedParent.Left()-self.Width() - 10 then
                    newLeft = savedParent.Left()-self.Width() - 10
                    self:SetNeedsFrameUpdate(false)
                    self:Hide()
                end
                self.Left:Set(newLeft)
            end
            controls.collapseArrow:SetCheck(true, true)
        end
    else
        if state or GUI.bg:IsHidden() then
            controls.bg:Show()
            controls.collapseArrow:SetCheck(false, true)
        else
            controls.bg:Hide()
            controls.collapseArrow:SetCheck(true, true)
        end
    end
end

--open the abilities panel directly
function Open_Panel()
	controls.bg:Show()
	controls.bg:SetNeedsFrameUpdate(true)
	controls.bg.OnFrame = function(self, delta)
		local newLeft = self.Left() + (1000*delta)
		if newLeft > savedParent.Left()+15 then
			newLeft = savedParent.Left()+15
			self:SetNeedsFrameUpdate(false)
		end
		self.Left:Set(newLeft)
	end
	controls.collapseArrow:SetCheck(false, true)
	Panel_State = 'open'
end

--close the abilities panel directly
function Close_Panel()
	controls.bg:Show()
	controls.bg:SetNeedsFrameUpdate(true)
	controls.bg.OnFrame = function(self, delta)
		local newLeft = self.Left() - (1000*delta)
		if newLeft < savedParent.Left()-self.Width() - 10 then
			newLeft = savedParent.Left()-self.Width() - 10
			self:SetNeedsFrameUpdate(false)
			self:Hide()
		end
		self.Left:Set(newLeft)
	end
	
    controls.collapseArrow:SetCheck(true, true)
	Panel_State = 'closed'
end

--helper function to open the panel 
function ShowAll()
	ForkThread(ShowAllThread)
end

function ShowAllThread()
	Open_Panel()
	WaitSeconds(0.2)
	controls.collapseArrow:Show()
end

--helper function to hide the panel.
function HideAll()
	ForkThread(HideAllThread)
end

function HideAllThread()
	Close_Panel()
	WaitSeconds(0.2)
	controls.collapseArrow:SetHidden(true)
end

--not used.
function InitialAnimation()
    controls.bg:Show()
    controls.bg.Left:Set(savedParent.Left()-controls.bg.Width())
    controls.bg:SetNeedsFrameUpdate(true)
    controls.bg.OnFrame = function(self, delta)
        local newLeft = self.Left() + (1000*delta)
        if newLeft > savedParent.Left()+15 then
            newLeft = savedParent.Left()+15
            self:SetNeedsFrameUpdate(false)
        end
        self.Left:Set(newLeft)
    end
    controls.collapseArrow:Show()
    controls.collapseArrow:SetCheck(false, true)
	Panel_State = 'open'
end
