--*****************************************************************************
--* File: lua/modules/ui/dialogs/options.lua
--* Author: Chris Blackwell
--* Summary: Manages the options dialog
--*
--* Copyright 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Button = import("/lua/maui/button.lua").Button
local MenuCommon = import("/lua/ui/menus/menucommon.lua")
local Group = import("/lua/maui/group.lua").Group
local Grid = import("/lua/maui/grid.lua").Grid
local Slider = import("/lua/maui/slider.lua").Slider
local Combo = import("/lua/ui/controls/combo.lua").Combo
local IntegerSlider = import("/lua/maui/slider.lua").IntegerSlider
local OptionsLogic = import("/lua/options/optionslogic.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

-- this will hold the working set of options, which won't be valid until applied
local currentOptionsSet = nil
local currentTabButton = nil
local currentTabBitmap = nil

-- contains a map of current option controls keyed by their option keys
local optionKeyToControlMap = nil

-- this table is keyed with the different types of controls that can be created
-- each key's value is the function that actually creates the type
-- the signature of the function is: fucntion(parent, optionItemData) and should return it's base control
-- note that each control should create a change function that allows the control to have its value changed
-- not that each control should create a SetCustomData(newCustomData, newDefault) function that will initialize the control with new custom data
local controlTypeCreate = {

    header = function(parent, optionItemData)
        local group = Group(parent)
        LayoutHelpers.SetDimensions(group, 10, 10)
        return group
    end,

    toggle = function(parent, optionItemData)
        local combo = Combo(parent, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
        LayoutHelpers.SetWidth(combo, 250)

        combo.SetCustomData = function(newCustomData, newDefault)
            local itemArray = {}
            local default = 1
            local matchedCurrentValue = false
            combo:ClearItems()
            combo.keyMap = {}
            for index, val in newCustomData.states do
                if currentOptionsSet[optionItemData.key] == val.key then
                    default = index
                    matchedCurrentValue = true
                end
                itemArray[index] = val.text
                combo.keyMap[index] = val.key
            end
            combo.Key = newDefault
            combo:AddItems(itemArray, default)
            if table.getsize(itemArray) == 1 then
                combo:Disable()
            else
                combo:Enable()
            end
            -- if we didn't find a match for our current value, we need to set the value to default
            if not matchedCurrentValue then
                currentOptionsSet[optionItemData.key] = newDefault
            end
        end

        combo.SetCustomData(optionItemData.custom, optionItemData.default)

        combo.OnClick = function(self, index, text, skipUpdate)
            self.Key = index
            currentOptionsSet[optionItemData.key] = combo.keyMap[index]
            if optionItemData.update and not skipUpdate then
                optionItemData.update(self,combo.keyMap[index])
            end
        end

        combo.OnDestroy = function(self)
            optionItemData.control = nil
            optionItemData.change = nil
        end

        optionItemData.control = combo
        optionItemData.change = function(control, value, skipUpdate)
            -- find key in control
            for index, key in control.keyMap do
                if key == value then
                    -- don't do anything if we're already set to this key
                    if control:GetItem() ~= index then
                        control:SetItem(index)
                        control:OnClick(index, nil, skipUpdate)
                        return
                    end
                end
            end
        end

        return combo
    end,

    button = function(parent, optionItemData)
        local bg = Bitmap(parent, UIUtil.SkinnableFile('/dialogs/options-02/content-btn-line_bmp.dds'))
        bg._button = UIUtil.CreateButtonStd(bg, '/dialogs/standard-small_btn/standard-small', optionItemData.custom.text, 12, 2, 0, "UI_Opt_Mini_Button_Click", "UI_Opt_Mini_Button_Over")
        LayoutHelpers.AtCenterIn(bg._button, bg)
        bg._button.OnClick = function(self, modifiers)
            if optionItemData.update then
                optionItemData.update(self, 0)
            end
        end
        optionItemData.control = bg
        optionItemData.change = function(control, value)
            if optionItemData.update then
                optionItemData.update(control, value)
            end
        end
        bg.OnDestroy = function(self)
            optionItemData.control = nil
            optionItemData.change = nil
        end

        bg.SetCustomData = function(newCustomData, newDefault)
            bg._button.label:SetText(newCustomData)
        end

        return bg
    end,

    slider = function(parent, optionItemData)
        local sliderGroup = Group(parent)
        sliderGroup.Width:Set(parent.Width)
        sliderGroup.Height:Set(parent.Height)

        sliderGroup._slider = false
        if optionItemData.custom.inc == 0 then
            sliderGroup._slider = Slider(sliderGroup, false, optionItemData.custom.min, optionItemData.custom.max, UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'), UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'), UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'), UIUtil.SkinnableFile('/slider02/slider-back_bmp.dds'))
        else
            sliderGroup._slider = IntegerSlider(sliderGroup, false, optionItemData.custom.min, optionItemData.custom.max, optionItemData.custom.inc, UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'), UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'), UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'), UIUtil.SkinnableFile('/dialogs/options-02/slider-back_bmp.dds'))
        end

        LayoutHelpers.AtLeftTopIn(sliderGroup._slider, sliderGroup)

        sliderGroup._value = UIUtil.CreateText(sliderGroup, "", 12)
        LayoutHelpers.RightOf(sliderGroup._value, sliderGroup._slider)

        sliderGroup._slider.OnValueChanged = function(self, newValue)
            sliderGroup._value:SetText(math.floor(tostring(newValue)))
        end

        sliderGroup._slider.OnValueSet = function(self, newValue)
            if optionItemData.update then
                optionItemData.update(self, newValue)
            end
            currentOptionsSet[optionItemData.key] = newValue
        end

        sliderGroup._slider.OnBeginChange = function(self)
            if optionItemData.beginChange then
                optionItemData.beginChange(self)
            end
        end

        sliderGroup._slider.OnEndChange = function(self)
            if optionItemData.endChange then
                optionItemData.endChange(self)
            end
        end

        sliderGroup._slider.OnScrub = function(self,value)
            if optionItemData.update then
                optionItemData.update(self,value)
            end
        end

        optionItemData.control = sliderGroup._slider
        optionItemData.change = function(control, value, skipUpdate)
            if not skipUpdate then
                control:SetValue(value)
            end
        end

        sliderGroup.OnDestroy = function(self)
            optionItemData.control = nil
            optionItemData.change = nil
        end

        -- set initial value
        if currentOptionsSet[optionItemData.key] then 
            sliderGroup._slider:SetValue(currentOptionsSet[optionItemData.key])
        else
            sliderGroup._slider:SetValue(optionItemData.default)
        end

        sliderGroup.SetCustomData = function(newCustomData, newDefault)
            -- this isn't really correct as it should check the indent, and recreate the control if needed
            -- and set the indent (which isn't exposed in slider, doh!) but this isn't really used
            -- at this point, so it's not worth putting work in to
            sliderGroup._slider:SetStartValue(newCustomData.min)
            sliderGroup._slider:SetEndValue(newCustomData.max)
        end

        return sliderGroup
    end,
}


local function CreateOption(parent, optionItemData)
    local bg = Bitmap(parent, UIUtil.SkinnableFile('/dialogs/options-02/content-box_bmp.dds'))


    bg._label = UIUtil.CreateText(bg, optionItemData.title, 16, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(bg._label, bg, 9, 6)
    bg._label._tipText = optionItemData.key

    bg._label.HandleEvent = function(self, event)
        if bg._label._tipText then
            if event.Type == 'MouseEnter' then
                Tooltip.CreateMouseoverDisplay(self, "options_" .. bg._label._tipText, .5, true)
            elseif event.Type == 'MouseExit' then
                Tooltip.DestroyMouseoverDisplay()
            end
        end
    end

    local controlGroup = Group(bg)
    LayoutHelpers.AtLeftTopIn(controlGroup, bg, 338, 5)
    LayoutHelpers.SetDimensions(controlGroup, 252, 24)

    if controlTypeCreate[optionItemData.type] then
        bg._control = controlTypeCreate[optionItemData.type](controlGroup, optionItemData)
    else
        LOG("Warning: Option item data [" .. optionItemData.key .. "] contains an unknown control type: " .. optionItemData.type .. ". Valid types are")
        for k,v in controlTypeCreate do
            LOG(k)
        end
    end

    if bg._control then
        LayoutHelpers.AtCenterIn(bg._control, controlGroup)
    end

    if not (optionItemData.type == 'header') then 
        optionKeyToControlMap[optionItemData.key] = bg._control
    end

    if optionItemData.type == 'header' then
        bg:SetAlpha(0.0)
    end

    return bg
end

local dialog = nil

function CreateDialog(over, exitBehavior)
    currentOptionsSet = OptionsLogic.GetCurrent()

    local parent = nil

    -- lots of state
    local function KillDialog()
        currentTabButton = false
        currentTabBitmap = false

        OptionsLogic.SetCustomDataChangedCallback(nil)
        OptionsLogic.SetSummonRestartDialogCallback(nil)
        OptionsLogic.SetSummonVerifyDialogCallback(nil)
        OptionsLogic.Repopulate()

        if over then
            dialog:Destroy()
        else
            parent:Destroy()
        end
    end

    if over then
        parent = over
    else
        parent = UIUtil.CreateScreenGroup(GetFrame(0), "Options ScreenGroup")
        local background = MenuCommon.SetupBackground(GetFrame(0))
    end

    dialog = Bitmap(parent, UIUtil.UIFile('/scx_menu/options/panel_bmp.dds'))
    LayoutHelpers.AtCenterIn(dialog, parent)

    dialog.brackets = UIUtil.CreateDialogBrackets(dialog, 41, 24, 41, 24)

    local title = UIUtil.CreateText(dialog, "<LOC _Options>", 24, UIUtil.titleFont)
    LayoutHelpers.AtTopIn(title, dialog, 30)
    LayoutHelpers.AtHorizontalCenterIn(title, dialog)

    if over then
        dialog.Depth:Set(GetFrame(over:GetRootFrame():GetTargetHead()):GetTopmostDepth() + 1)
    end

    local function roHandler(self, event)
        if event == 'enter' then
            self.label:SetColor('ff000000')
        elseif event == 'exit' then
            self.label:SetColor(UIUtil.fontColor)
        end
    end

    -- layout buttons
    local applyBtn = Button(dialog,
        UIUtil.UIFile('/scx_menu/small-short-btn/small-btn_up.dds'),
        UIUtil.UIFile('/scx_menu/small-short-btn/small-btn_down.dds'),
        UIUtil.UIFile('/scx_menu/small-short-btn/small-btn_over.dds'),
        UIUtil.UIFile('/scx_menu/small-short-btn/small-btn_dis.dds'),
        "UI_Opt_Yes_No", "UI_Opt_Affirm_Over")
    LayoutHelpers.AtRightTopIn(applyBtn, dialog, 15, 515)
    applyBtn.label = UIUtil.CreateText(applyBtn, LOC("<LOC _Apply>"), 16)
    LayoutHelpers.AtCenterIn(applyBtn.label, applyBtn)
    Tooltip.AddButtonTooltip(applyBtn, 'options_tab_apply')
    applyBtn.OnRolloverEvent = roHandler

    dialog.cancelBtn = Button(dialog,
        UIUtil.UIFile('/scx_menu/small-short-btn/small-btn_up.dds'),
        UIUtil.UIFile('/scx_menu/small-short-btn/small-btn_down.dds'),
        UIUtil.UIFile('/scx_menu/small-short-btn/small-btn_over.dds'),
        UIUtil.UIFile('/scx_menu/small-short-btn/small-btn_dis.dds'),
        "UI_Opt_Yes_No", "UI_Opt_Affirm_Over")
    dialog.cancelBtn.label = UIUtil.CreateText(dialog.cancelBtn, LOC("<LOC _Cancel>"), 16)
    LayoutHelpers.AtCenterIn(dialog.cancelBtn.label, dialog.cancelBtn)
    LayoutHelpers.LeftOf(dialog.cancelBtn, applyBtn, -6)
    dialog.cancelBtn.OnRolloverEvent = roHandler

    local okBtn = Button(dialog,
        UIUtil.UIFile('/scx_menu/small-short-btn/small-btn_up.dds'),
        UIUtil.UIFile('/scx_menu/small-short-btn/small-btn_down.dds'),
        UIUtil.UIFile('/scx_menu/small-short-btn/small-btn_over.dds'),
        UIUtil.UIFile('/scx_menu/small-short-btn/small-btn_dis.dds'),
        "UI_Opt_Yes_No", "UI_Opt_Affirm_Over")
    okBtn.label = UIUtil.CreateText(okBtn, LOC("<LOC _Ok>"), 16)
    LayoutHelpers.AtCenterIn(okBtn.label, okBtn)
    LayoutHelpers.LeftOf(okBtn, dialog.cancelBtn, -6)
    okBtn.OnRolloverEvent = roHandler


    local resetBtn = Button(dialog,
        UIUtil.UIFile('/scx_menu/small-short-btn/small-btn_up.dds'),
        UIUtil.UIFile('/scx_menu/small-short-btn/small-btn_down.dds'),
        UIUtil.UIFile('/scx_menu/small-short-btn/small-btn_over.dds'),
        UIUtil.UIFile('/scx_menu/small-short-btn/small-btn_dis.dds'),
        "UI_Opt_Yes_No", "UI_Opt_Affirm_Over")
    resetBtn.label = UIUtil.CreateText(resetBtn, LOC("<LOC _Reset>"), 16)
    LayoutHelpers.AtCenterIn(resetBtn.label, resetBtn)
    LayoutHelpers.LeftOf(resetBtn, okBtn, -6)
    Tooltip.AddButtonTooltip(resetBtn, 'options_reset_all')
    resetBtn.OnRolloverEvent = roHandler


    -- set up button logic
    okBtn.OnClick = function(self, modifiers)
        OptionsLogic.SetCurrent(currentOptionsSet)
        KillDialog()
        if exitBehavior then exitBehavior() end
    end

    dialog.cancelBtn.OnClick = function(self, modifiers)
        if currentTabButton then
            for index,option in currentTabButton.tabData.items do
                if option.cancel then
                    option.cancel()
                end
            end
        end

        KillDialog()
        if exitBehavior then exitBehavior() end
    end

    applyBtn.OnClick = function(self, modifiers)
        OptionsLogic.SetCurrent(currentOptionsSet)
    end

    resetBtn.OnClick = function(self, modifiers)
        local function DoReset()
            OptionsLogic.ResetToDefaults()
            -- creating the dialog will reload the old options without saving the new ones and will reset all the controls
            KillDialog()
            if exitBehavior then exitBehavior() end
        end

        UIUtil.QuickDialog(dialog, "<LOC options_0002>Are you sure you want to reset to default values?",
            "<LOC _Yes>", DoReset,
            "<LOC _No>", nil,
            nil, nil,
            true,
            {escapeButton = 2, enterButton = 1, worldCover = false})
    end

    UIUtil.MakeInputModal(dialog, function() okBtn:OnClick() end, function() dialog.cancelBtn:OnClick() end)

    -- set up option grid
    local elementWidth, elementHeight = GetTextureDimensions(UIUtil.UIFile('/dialogs/options-02/content-box_bmp.dds'))
    local optionGrid = Grid(dialog, elementWidth, elementHeight)
    LayoutHelpers.RelativeTo(optionGrid, dialog, UIUtil.SkinnableFile('/dialogs/options-02/options-02_layout.lua'), 'gameplay_bmp', 'panel_bmp')
    LayoutHelpers.AtRightBottomIn(optionGrid, dialog, 43, 100)
    LayoutHelpers.DimensionsRelativeTo(optionGrid, UIUtil.SkinnableFile('/dialogs/options-02/options-02_layout.lua'), 'gameplay_bmp')
    local scrollbar = UIUtil.CreateVertScrollbarFor(optionGrid, -4)

    -- set up a page
    function SetNewPage(tabControl)
        -- kill any other page
        if currentTabBitmap then
            currentTabBitmap:Destroy()
            currentTabBitmap = false
            currentTabButton:Show()
        end

        -- store the tab data for this tab for easy access
        local tabData = tabControl.tabData

        -- show the "selected" state of the tab, which hides the button and shows a bitmap
        currentTabButton = tabControl
        currentTabButton:Hide()
        currentTabBitmap = Bitmap(dialog, UIUtil.SkinnableFile('/scx_menu/tab_btn/tab_btn_selected.dds'))
        LayoutHelpers.AtCenterIn(currentTabBitmap, currentTabButton)
        local tabLabel = UIUtil.CreateText(currentTabBitmap, tabData.title, 16, UIUtil.titleFont)
        LayoutHelpers.AtCenterIn(tabLabel, currentTabBitmap)

        -- remove controls and populate grid
        optionGrid:DeleteAndDestroyAll(true)
        optionGrid:AppendCols(1, true)

        -- initialzie key to control map each time page is changed, as controls get destroyed
        optionKeyToControlMap = {}

        for index, option in tabData.items do
            optionGrid:AppendRows(1, true)
            local optCtrl = CreateOption(optionGrid, option)

            optCtrl.HandleEvent = function(self, event)
                if scrollbar and event.Type == 'WheelRotation' then
                    local scrollDim = { optionGrid:GetScrollValues('Vert') }
                    if event.WheelRotation <= 0 then -- scroll down ...
                        if scrollDim[2] != scrollDim[4] then -- ... if we can
                            PlaySound(Sound({ Cue = 'UI_Tab_Rollover_01', Bank = 'Interface' }))
                            scrollbar:DoScrollLines(1)
                        end
                    else -- scroll up ...
                        if scrollDim[1] != scrollDim[3] then -- ... if we can
                            PlaySound(Sound({ Cue = 'UI_Tab_Rollover_01', Bank = 'Interface' }))
                            scrollbar:DoScrollLines(-1)
                        end
                    end
                end
            end
            
            optionGrid:SetItem(optCtrl, 1, index, true)
            if option.init then
                option.init()
            end
        end

        optionGrid:EndBatch()
    end

    -- tab layout
    local prev = false
    local defaultTab = false

    -- get the tab data
    local options = import("/lua/options/options.lua").options
    local optionsOrder = import("/lua/options/options.lua").optionsOrder

    for index, key in optionsOrder do
        tabData = options[key]
        local curButton = UIUtil.CreateButtonStd(dialog, '/scx_menu/tab_btn/tab', tabData.title, 16, 0, 0, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
        curButton.label:SetDropShadow(true)
        if prev then
            LayoutHelpers.RightOf(curButton, prev, -10)
        else
            LayoutHelpers.AtLeftTopIn(curButton, dialog, 10, 64)
            defaultTab = curButton
        end
        prev = curButton

        curButton.OnClick = function(self, modifiers)
            SetNewPage(self)
        end

        curButton.tabData = tabData
    end

    SetNewPage(defaultTab)

    if not optionGrid:IsScrollable("Vert") then
        scrollbar:Hide()
    end

    OptionsLogic.SetCustomDataChangedCallback(function(optionKey, newCustomData, newDefault)
        if optionKeyToControlMap and optionKeyToControlMap[optionKey] then
            optionKeyToControlMap[optionKey].SetCustomData(newCustomData, newDefault)
        end
    end)

    local function OptionRestartFunc(proceedFunc, cancelFunc)
        UIUtil.QuickDialog(GetFrame(0) , "<LOC options_0001>You have modified an option which requires you to restart Forged Alliance. Selecting OK will exit the game, selecting Cancel will revert the option to its prior setting."
            , "<LOC _OK>", proceedFunc
            ,"<LOC _Cancel>", cancelFunc
            , nil, nil
            , true
            , {escapeButton = 2, enterButton = 1, worldCover = false}
        )
    end
    OptionsLogic.SetSummonRestartDialogCallback(OptionRestartFunc)

    local function VerifyFunc(undoFunc)
        local secondsToWait = 15
        local thread

        local dlg = UIUtil.QuickDialog(GetFrame(0), "<LOC options_0003>Click OK to accept these settings."
            , LOC("<LOC _Ok>") .. " [" .. secondsToWait .. "]", function() KillThread(thread) end
            , "<LOC _Cancel>", function() KillThread(thread) undoFunc() end
            , nil, nil
            , true
            , {escapeButton = 2, enterButton = 1, worldCover = false}
        )

        thread = ForkThread(function()
            for sec = 1, secondsToWait do
                WaitSeconds(1)
                dlg.content._button1.label:SetText(LOC("<LOC _Ok>") .. " [" .. (secondsToWait - sec) .. "]")
            end
            dlg:Destroy()
            undoFunc()
        end)
    end
    OptionsLogic.SetSummonVerifyDialogCallback(VerifyFunc)
end

function OnNISBegin()
    if dialog then
        dialog.cancelBtn:OnClick()
    end
end

-- kept for mod backwards compatibility
local Text = import("/lua/maui/text.lua").Text