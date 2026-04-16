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
local MenuCommon = import("/lua/ui/menus/menucommon.lua")
local Group = import("/lua/maui/group.lua").Group
local Grid = import("/lua/maui/grid.lua").Grid
local Slider = import("/lua/maui/slider.lua").Slider
local Combo = import("/lua/ui/controls/combo.lua").Combo
local IntegerSlider = import("/lua/maui/slider.lua").IntegerSlider
local OptionsLogic = import("/lua/options/optionslogic.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")
local Edit = import("/lua/maui/edit.lua").Edit

-- this will hold the working set of options, which won't be valid until applied
local currentOptionsSet = nil
local currentTabButton = nil

-- contains a map of current option controls keyed by their option keys
local optionKeyToControlMap = nil

local OptionRowWidth = 700
local OptionRowHeight = 34

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
                optionItemData.update(self, combo.keyMap[index])
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
            sliderGroup._value:SetText(tostring(math.floor(newValue)))
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

        sliderGroup._slider.OnScrub = function(self, value)
            if optionItemData.update then
                optionItemData.update(self, value)
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
    local bg = Group(parent)

    if not bg.SetSolidColor then
        bg.SetSolidColor = function(self, color)
        end
    end

    LayoutHelpers.SetDimensions(bg, OptionRowWidth, OptionRowHeight)

    if optionItemData.type ~= 'header' then
        -- hover highlight background
        bg._bg = UIUtil.CreateBitmapColor(bg, '00000000')
        LayoutHelpers.AtLeftTopIn(bg._bg, bg, 4, 0)
        LayoutHelpers.SetDimensions(bg._bg, OptionRowWidth - 8, OptionRowHeight)
        bg._bg:DisableHitTest()

        -- bottom separator line
        bg._bottomSep = UIUtil.CreateBitmapColor(bg, '18FFFFFF')
        LayoutHelpers.AtLeftBottomIn(bg._bottomSep, bg, 4, 0)
        LayoutHelpers.SetDimensions(bg._bottomSep, OptionRowWidth - 8, 1)
        bg._bottomSep:DisableHitTest()
    end

    local labelFont = UIUtil.bodyFont
    local labelSize = 16
    if optionItemData.type == 'header' then
        labelFont = UIUtil.titleFont
        labelSize = 18
    end

    bg._label = UIUtil.CreateText(bg, optionItemData.title, labelSize, labelFont)

    if optionItemData.type == 'header' then
        LayoutHelpers.AtTopIn(bg._label, bg, 3)
        LayoutHelpers.AtHorizontalCenterIn(bg._label, bg)
        bg._label:SetColor('FFE4E4E4')
    else
        LayoutHelpers.AtLeftTopIn(bg._label, bg, 14, 7)
        if optionItemData.tip then
            bg._tipText = {text = LOC(optionItemData.title), body = LOC(optionItemData.tip)}
        else
            bg._tipText = optionItemData.key
        end
    end

    local controlGroup = Group(bg)
    LayoutHelpers.AtLeftTopIn(controlGroup, bg, 442, 5)
    LayoutHelpers.SetDimensions(controlGroup, 248, 24)

    if controlTypeCreate[optionItemData.type] then
        bg._control = controlTypeCreate[optionItemData.type](controlGroup, optionItemData)
    else
        LOG("Warning: Option item data [" .. optionItemData.key .. "] contains an unknown control type: " .. optionItemData.type .. ". Valid types are")
        for k, v in controlTypeCreate do
            LOG(k)
        end
    end

    if bg._control then
        LayoutHelpers.AtCenterIn(bg._control, controlGroup)
    end

    if not (optionItemData.type == 'header') then
        optionKeyToControlMap[optionItemData.key] = bg._control
    end

    return bg
end

local dialog = nil

function CreateDialog(over, exitBehavior)
    currentOptionsSet = OptionsLogic.GetCurrent()

    local options = import("/lua/options/options.lua").options
    local optionsOrder = import("/lua/options/options.lua").optionsOrder

    local parent = nil

    -- lots of state
    local function KillDialog()
        currentTabButton = false

        OptionsLogic.SetCustomDataChangedCallback(nil)
        OptionsLogic.SetSummonRestartDialogCallback(nil)
        OptionsLogic.SetSummonVerifyDialogCallback(nil)
        OptionsLogic.Repopulate()

        if over then
            dialog:Destroy()
        else
            parent:Destroy()
        end
        dialog = nil
    end

    if over then
        parent = over
    else
        parent = UIUtil.CreateScreenGroup(GetFrame(0), "Options ScreenGroup")
        MenuCommon.SetupBackground(GetFrame(0))
    end

    dialog = Group(parent)
    LayoutHelpers.SetDimensions(dialog, 1080, 820)
    LayoutHelpers.AtCenterIn(dialog, parent)

    local contentParent = Group(dialog)
    LayoutHelpers.SetDimensions(contentParent, 1000, 760)
    LayoutHelpers.AtCenterIn(contentParent, dialog)

    local title = UIUtil.CreateText(contentParent, "<LOC _Options>", 26, UIUtil.titleFont)
    LayoutHelpers.AtTopIn(title, contentParent, 18)
    LayoutHelpers.AtHorizontalCenterIn(title, contentParent)

    local contentBgLeft = 90
    local contentBgTop = 8
    local contentBgWidth = 820
    local contentBgHeight = 744

    local contentBackground = UIUtil.CreateBitmapColor(contentParent, 'E6060B12')
    LayoutHelpers.AtLeftTopIn(contentBackground, contentParent, contentBgLeft, contentBgTop)
    LayoutHelpers.SetDimensions(contentBackground, contentBgWidth, contentBgHeight)
    contentBackground:DisableHitTest()

    local borderBackground = UIUtil.CreateNinePatchStd(contentParent, '/scx_menu/lan-game-lobby/dialog/background/')
    LayoutHelpers.FillParentFixedBorder(borderBackground, contentBackground, 64)
    LayoutHelpers.DepthUnderParent(borderBackground, contentBackground)

    title.Depth:Set(function() return contentBackground.Depth() + 10 end)

    local searchEdit = Edit(contentParent)
    LayoutHelpers.AtRightTopIn(searchEdit, contentParent, 110, 28)
    LayoutHelpers.SetWidth(searchEdit, 180)
    searchEdit.Height:Set(function() return searchEdit:GetFontHeight() end)
    searchEdit:ShowBackground(true)
    UIUtil.SetupEditStd(searchEdit, UIUtil.fontColor, '77778888', UIUtil.fontColor, UIUtil.highlightColor, UIUtil.bodyFont, 14, 30)
    searchEdit:SetDropShadow(true)
    searchEdit.Depth:Set(function() return contentBackground.Depth() + 10 end)

    local searchLabel = UIUtil.CreateText(contentParent, LOC("<LOC options_search>Search..."), 16, UIUtil.bodyFont)
    LayoutHelpers.LeftOf(searchLabel, searchEdit, 10)
    LayoutHelpers.AtVerticalCenterIn(searchLabel, searchEdit)
    searchLabel.Depth:Set(function() return contentBackground.Depth() + 10 end)

    -- forward declaration so OnTextChanged captures the local page switcher
    local SetNewPage

    searchEdit.OnTextChanged = function(self, new, old)
        if currentTabButton then
            SetNewPage(currentTabButton)
        end
    end

    if over then
        dialog.Depth:Set(GetFrame(over:GetRootFrame():GetTargetHead()):GetTopmostDepth() + 1)
    end

    -- layout buttons
    local applyBtn = UIUtil.CreateButtonWithDropshadow(contentParent, '/BUTTON/medium/', LOC("<LOC _Apply>"))
    LayoutHelpers.SetWidth(applyBtn, 150)
    LayoutHelpers.AtRightBottomIn(applyBtn, contentParent, 188, 24)
    Tooltip.AddButtonTooltip(applyBtn, 'options_tab_apply')

    dialog.cancelBtn = UIUtil.CreateButtonWithDropshadow(contentParent, '/BUTTON/medium/', LOC("<LOC _Cancel>"))
    LayoutHelpers.SetWidth(dialog.cancelBtn, 150)
    LayoutHelpers.LeftOf(dialog.cancelBtn, applyBtn, 8)

    local okBtn = UIUtil.CreateButtonWithDropshadow(contentParent, '/BUTTON/medium/', LOC("<LOC _Ok>"))
    LayoutHelpers.SetWidth(okBtn, 150)
    LayoutHelpers.LeftOf(okBtn, dialog.cancelBtn, 8)

    local resetBtn = UIUtil.CreateButtonWithDropshadow(contentParent, '/BUTTON/medium/', LOC("<LOC _Reset>"))
    LayoutHelpers.SetWidth(resetBtn, 150)
    LayoutHelpers.LeftOf(resetBtn, okBtn, 8)
    Tooltip.AddButtonTooltip(resetBtn, 'options_reset_all')

    -- set up button logic
    okBtn.OnClick = function(self, modifiers)
        OptionsLogic.SetCurrent(currentOptionsSet)
        KillDialog()
        if exitBehavior then exitBehavior() end
    end

    dialog.cancelBtn.OnClick = function(self, modifiers)
        for _, key in optionsOrder do
            if options[key] then
                for _, option in options[key].items do
                    if option.cancel then
                        option.cancel()
                    end
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
    local elementWidth, elementHeight = OptionRowWidth, OptionRowHeight
    local optionGrid = Grid(contentParent, elementWidth, elementHeight)
    LayoutHelpers.SetDimensions(optionGrid, elementWidth, 560)
    LayoutHelpers.AtLeftTopIn(optionGrid, contentParent, 150, 122)
    local scrollbar = UIUtil.CreateVertScrollbarFor(optionGrid, 15)

    applyBtn.Depth:Set(function() return optionGrid.Depth() + 20 end)
    dialog.cancelBtn.Depth:Set(function() return optionGrid.Depth() + 20 end)
    okBtn.Depth:Set(function() return optionGrid.Depth() + 20 end)
    resetBtn.Depth:Set(function() return optionGrid.Depth() + 20 end)

    local tabWidth = 166
    local tabHeight = 34

    local function CreateModernTab(parent, labelText)
        local tab = Group(parent)
        LayoutHelpers.SetDimensions(tab, tabWidth, tabHeight)

        tab.label = UIUtil.CreateText(tab, labelText, 18, UIUtil.titleFont)
        tab.label:SetColor('FFBFC8D0')
        LayoutHelpers.AtCenterIn(tab.label, tab)
        tab.label:DisableHitTest()

        tab.underline = UIUtil.CreateBitmapColor(tab, '00000000')
        LayoutHelpers.AtBottomIn(tab.underline, tab)
        LayoutHelpers.AtHorizontalCenterIn(tab.underline, tab.label)
        LayoutHelpers.SetDimensions(tab.underline, tabWidth - 20, 2)
        tab.underline:DisableHitTest()

        tab.SetVisualState = function(self, state)
            if state == 'selected' then
                self.label:SetColor('FFF2F5F8')
                self.underline:SetSolidColor('C8A6C6DA')
            elseif state == 'hover' then
                self.label:SetColor('FFE1E8EE')
                self.underline:SetSolidColor('66A6C6DA')
            else
                self.label:SetColor('FFBFC8D0')
                self.underline:SetSolidColor('00000000')
            end
        end

        tab.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                if currentTabButton ~= self then
                    self:SetVisualState('hover')
                end
            elseif event.Type == 'MouseExit' then
                if currentTabButton ~= self then
                    self:SetVisualState('normal')
                end
            elseif event.Type == 'ButtonPress' then
                if self.OnClick then
                    self:OnClick()
                end
                return true
            end
        end

        return tab
    end

    local tabButtons = {}

    -- set up a page
    SetNewPage = function(tabControl)

        if currentTabButton and currentTabButton ~= tabControl and currentTabButton.SetVisualState then
            currentTabButton:SetVisualState('normal')
        end

        local searchString = searchEdit:GetText()
        local isSearching = searchString and searchString ~= ""

        if currentTabButton ~= tabControl then
            currentTabButton = tabControl
            if currentTabButton.SetVisualState then
                currentTabButton:SetVisualState('selected')
            end
        end

        optionGrid:DeleteAndDestroyAll(true)
        optionGrid:AppendCols(1, true)
        optionKeyToControlMap = {}

        for _, btn in tabButtons do
            if isSearching then
                btn:Hide()
            else
                btn:Show()
            end
        end

        local row = 1
        local function AddOptionsFromTabData(tData)
            for index, option in tData.items do
                if isSearching then
                    local titleStr = LOC(option.title)
                    if not string.find(string.lower(titleStr), string.lower(searchString), 1, true) then
                        continue
                    end
                end

                -- add an empty row before headers for visual spacing (except the very first row)
                if option.type == 'header' and row > 1 then
                    optionGrid:AppendRows(1, true)
                    row = row + 1
                end

                optionGrid:AppendRows(1, true)
                local optCtrl = CreateOption(optionGrid, option)

                optCtrl.HandleEvent = function(self, event)
                    if event.Type == 'MouseEnter' then
                        if self._bg then self._bg:SetSolidColor('1AA6C6DA') end
                        if self._tipText and (type(self._tipText) == 'table' or self._tipText ~= "") then
                            if type(self._tipText) == 'table' then
                                Tooltip.CreateMouseoverDisplay(self, self._tipText, nil, true, nil, nil, nil, nil, nil, 'left')
                            else
                                Tooltip.CreateMouseoverDisplay(self, "options_" .. self._tipText, nil, true, nil, nil, nil, nil, nil, 'left')
                            end
                        end
                    elseif event.Type == 'MouseExit' then
                        if self._bg then self._bg:SetSolidColor('00000000') end
                        Tooltip.DestroyMouseoverDisplay()
                    elseif event.Type == 'WheelRotation' then
                        local scrollDim = { optionGrid:GetScrollValues('Vert') }
                        if event.WheelRotation <= 0 then
                            if scrollDim[2] ~= scrollDim[4] then
                                PlaySound(Sound({ Cue = 'UI_Tab_Rollover_01', Bank = 'Interface' }))
                                scrollbar:DoScrollLines(1)
                            end
                        else
                            if scrollDim[1] ~= scrollDim[3] then
                                PlaySound(Sound({ Cue = 'UI_Tab_Rollover_01', Bank = 'Interface' }))
                                scrollbar:DoScrollLines(-1)
                            end
                        end
                    end
                end

                optionGrid:SetItem(optCtrl, 1, row, true)
                if option.init then
                    option.init()
                end
                row = row + 1
            end
        end

        if isSearching then
            for _, key in optionsOrder do
                if options[key] then
                    AddOptionsFromTabData(options[key])
                end
            end
        else
            AddOptionsFromTabData(tabControl.tabData)
        end

        optionGrid:EndBatch()

        if optionGrid:IsScrollable("Vert") then
            scrollbar:Show()
        else
            scrollbar:Hide()
        end
    end

    -- tab layout
    local prev = false
    local defaultTab = false

    -- get the tab data
    for _, key in optionsOrder do
        if not options[key] then
            continue
        end

        local tabData = options[key]
        local curButton = CreateModernTab(contentParent, tabData.title)
        if prev then
            LayoutHelpers.RightOf(curButton, prev, 12)
        else
            LayoutHelpers.AtLeftTopIn(curButton, contentParent, 150, 72)
            defaultTab = curButton
        end
        prev = curButton
        table.insert(tabButtons, curButton)

        curButton.OnClick = function(self, modifiers)
            SetNewPage(self)
        end

        curButton.tabData = tabData
    end

    SetNewPage(defaultTab)

    OptionsLogic.SetCustomDataChangedCallback(function(optionKey, newCustomData, newDefault)
        if optionKeyToControlMap and optionKeyToControlMap[optionKey] then
            optionKeyToControlMap[optionKey].SetCustomData(newCustomData, newDefault)
        end
    end)

    local function OptionRestartFunc(proceedFunc, cancelFunc)
        UIUtil.QuickDialog(GetFrame(0), "<LOC options_0001>You have modified an option which requires you to restart Forged Alliance. Selecting OK will exit the game, selecting Cancel will revert the option to its prior setting.",
            "<LOC _OK>", proceedFunc,
            "<LOC _Cancel>", cancelFunc,
            nil, nil,
            true,
            {escapeButton = 2, enterButton = 1, worldCover = false}
        )
    end
    OptionsLogic.SetSummonRestartDialogCallback(OptionRestartFunc)

    local function VerifyFunc(undoFunc)
        local secondsToWait = 15
        local thread

        local dlg = UIUtil.QuickDialog(GetFrame(0), "<LOC options_0003>Click OK to accept these settings.",
            LOC("<LOC _Ok>") .. " [" .. secondsToWait .. "]", function() KillThread(thread) end,
            "<LOC _Cancel>", function() KillThread(thread) undoFunc() end,
            nil, nil,
            true,
            {escapeButton = 2, enterButton = 1, worldCover = false}
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
