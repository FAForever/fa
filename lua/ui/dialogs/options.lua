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
local Edit = import("/lua/maui/edit.lua").Edit
local IntegerSlider = import("/lua/maui/slider.lua").IntegerSlider
local OptionsLogic = import("/lua/options/optionslogic.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")
local Scale = LayoutHelpers.ScaleNumber

-- storing a reference to this UI and all its children
local dialog = nil

-- this will hold the working set of options, which won't be valid until applied
local currentOptionsSet = nil

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
        local combo = Combo(parent, 16, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
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

        LayoutHelpers.AtLeftIn(sliderGroup._slider, sliderGroup)
        LayoutHelpers.AtVerticalCenterIn(sliderGroup._slider, sliderGroup)

        sliderGroup._value = UIUtil.CreateText(sliderGroup, "", 14)
        LayoutHelpers.RightOf(sliderGroup._value, sliderGroup._slider, 5)
        LayoutHelpers.AtVerticalCenterIn(sliderGroup._value, sliderGroup)

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

-- this table stores a list of collaped groups of options, e.g. Gameplay, UI, Sound, Video
local optionsCollapsed = {}
-- this table stores a list of options with localized strings and populate with extra info
local optionsList = {}
-- default size of option items that will scale to UI
local optionsHeight = 30

-- this string stores keyword typed by an user to search for specific options
local searchKeyword = ''

-- filter option list by matching for search keyword againt option's names or values
function FilterOptionsList()
    for group, options in optionsList do
        options.count = 0
        options.collapsed = optionsCollapsed[options.group]
        for _, optionInfo in options.items or {} do
            if searchKeyword ~= "" and optionInfo.keywords then
                -- seaching option's by their names and values
                optionInfo.value = string.lower(GetCurrentValue(optionInfo))
                optionInfo.collapsed = not string.find(optionInfo.keywords, searchKeyword)
                                   and not string.find(optionInfo.value, searchKeyword)
                if not optionInfo.collapsed then
                    options.count = options.count + 1
                end
            else
                options.count = options.count + 1
                optionInfo.collapsed = optionsCollapsed[optionInfo.group]
            end
        end
    end
    DisplayOptionsList(optionsList)
end

-- initialiing options hash table { ui = { ... }, gameplay = {...}, etc. }
-- into options list table { { gameplay }, { ui }, etc. }
-- and localizes strings only once to prevent repeat it each time we switch/expand between UI, Game, Video, Sound options list
function InitializeOptionsList()

    -- getting all options structured in hash table { ui = { ... }, game = {...}, etc. }
    local optionsData = table.deepcopy(import("/lua/options/options.lua").options) or {}
    -- getting options order { "gameplay", "ui", "video", "sound" }
    -- local optionsOrderList =  { "video", "gameplay", "sound" }
    local optionsOrderList = import("/lua/options/options.lua").optionsOrder or {}
    -- converting options order in to hash table for quick lookup
    local optionsOrderExists = table.hash(optionsOrderList)

    -- creating custom mod options for testing
    local modOptions = {
        title = "My Mod",
        key = 'mods_name',
        items  = {
            {
               custom = { min = 0, inc = 1, max = 100 },
               key = "mods_option_value",
               title = "Mod Option Value",
               default = 100,
               type = "slider",
            },
            {
                key = 'mods_option_toggle',
                title = "Mod Option Toggle",
                type = 'toggle',
                default = 1,
                update = function(control,value) end,
                set = function(key,value,startup) end,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0},
                        {text = "<LOC _On>", key = 1},
                    },
                },
            },
        }
    }
    -- uncomment out this line to test mod options
    -- optionsData.mods = modOptions

    -- converting option hash table { ui = { ... }, gameplay = {...}, etc. }
    -- into option list table with  { { ui }, { gameplay }, etc. } with localized strings
    -- this way we can filter and search options as well as order options by their group
    for group, options in optionsData do
        -- if group == 'ui' then continue end
        -- if group == 'gameplay' then continue end
        -- if group == 'video' then continue end

        options.group = group
        options.collaped = false
        options.title = LOC(options.title)
        if not options.title or options.title == '' then
           options.title = k
        end

        for _, optionInfo in options.items or {} do
            optionInfo.group = string.lower(group)
            optionInfo.collaped = false
            if optionInfo.type == 'header' then
                optionInfo.title = options.title .. ' - ' .. StringCapitalize(LOC(optionInfo.title))
            else
                optionInfo.title = StringCapitalize(LOC(optionInfo.title))
            end
            optionInfo.keywords = optionInfo.title
            optionInfo.keywords = string.lower(optionInfo.keywords)
            -- WARN(optionInfo.key ..  ' '   .. optionInfo.keywords )
        end

        options.title = options.title .. ' ' .. LOC('<LOC _Options>')
        options.title = string.upper(options.title)
        options.group = string.lower(group)
        options.type = 'expander' -- indicates expansion of options.items in this UI
        -- options added by mods that do not use existing order of options
        -- will be appended at the end of otions order
        if not optionsOrderExists[group] then
            table.insert(optionsOrderList, group)
        end
    end

    optionsList = {}
    -- making sure options are sorted in desired order
    for _, group in optionsOrderList do
        local options = optionsData[group]
        if not options then continue end

        -- if options.group == 'ui' then continue end
        -- if options.group == 'gameplay' then continue end
        -- if options.group == 'video' then continue end

        options.count = table.getsize(options.items)
        table.insert(optionsList, options)
    end
end

function DisplayOptionsItem(parent, option, count)
    local border = 1
    local fillColor = "F6010406"
    local borderColor = "FFAFDDDC"
    local highlightColor = "FF1B3543"

    local bg = Bitmap(parent)
    bg.option = option
    bg:SetSolidColor(borderColor)
    bg.Width:Set(function() return parent.Right() - parent.Left() - Scale(24) end)
    bg.Height:Set(function() return Scale(optionsHeight) end)

    -- optionKeyToControlMap[option.key] = bg._control

    bg.labelsFill = Bitmap(bg)
    bg.labelsFill:SetSolidColor('transparent')

    if option.type == 'expander' then
        LayoutHelpers.AtTopIn(bg.labelsFill, bg, 5)
        LayoutHelpers.AtLeftIn(bg.labelsFill, bg, 0)
        LayoutHelpers.AtRightIn(bg.labelsFill, bg, 0)
    else
        LayoutHelpers.AtTopIn(bg.labelsFill, bg, border)
        LayoutHelpers.AtLeftIn(bg.labelsFill, bg, border)
        LayoutHelpers.AtRightIn(bg.labelsFill, bg, 250)
    end
    LayoutHelpers.AtBottomIn(bg.labelsFill, bg, border)
    LayoutHelpers.ResetHeight(bg.labelsFill)

    bg.editorFill = Bitmap(bg)
    bg.editorFill:SetSolidColor('transparent')
    LayoutHelpers.RightOf(bg.editorFill, bg.labelsFill, border)
    LayoutHelpers.AtRightIn(bg.editorFill, bg, border)
    LayoutHelpers.AtTopIn(bg.editorFill, bg, border)
    LayoutHelpers.AtBottomIn(bg.editorFill, bg, border)

    bg.label = UIUtil.CreateText(bg.labelsFill or bg, option.title, 16, UIUtil.bodyFont)
    LayoutHelpers.AtVerticalCenterIn(bg.label, bg)
    LayoutHelpers.AtLeftIn(bg.label, bg, 10)

    if option.type == 'expander' then
        bg:SetSolidColor('transparent')
        bg.labelsFill:SetSolidColor("81AFDDDC")
        bg.label:SetColor('black')
        bg.label:SetFont('Arial Bold', 16)
        bg.label:SetText(option.title)

        bg.expander = UIUtil.CreateText(bg.labelsFill, '+', 20, 'Zeroes Three')
        LayoutHelpers.AtVerticalCenterIn(bg.expander, bg.labelsFill, 2)
        LayoutHelpers.AtLeftIn(bg.expander, bg, 10)
        bg.expander.Width:Set(function() return Scale(10) end)
        bg.expander:SetColor('black')
        bg.expander:SetText(optionsCollapsed[option.group] and '+' or '-')
        LayoutHelpers.RightOf(bg.label, bg.expander, 10)
        LayoutHelpers.AtVerticalCenterIn(bg.label, bg.labelsFill, 0)

        bg.counter = UIUtil.CreateText(bg.labelsFill, '', 16, 'Arial Bold')
        bg.counter:SetText('SHOWING ' .. count .. ' OF ' .. table.getsize(option.items) .. '')
        bg.counter:SetColor('black')
        LayoutHelpers.AtRightIn(bg.counter, bg, 10)
        LayoutHelpers.AtVerticalCenterIn(bg.counter, bg.labelsFill, 0)

        bg.tooltip = {
            text = '<LOC OPTIONS_toggle_text>Toggle Options List', 
            body = '<LOC OPTIONS_toggle_body>Expand or collapsed this list of options'
        }

        bg.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                bg.labelsFill:SetSolidColor("81C2D1D1")
                Tooltip.CreateMouseoverDisplay(self, bg.tooltip, .075, true)
            elseif event.Type == 'MouseExit' then
                bg.labelsFill:SetSolidColor("81AFDDDC")
                Tooltip.DestroyMouseoverDisplay()
            elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
                local group = bg.option.group or 'UNKNOWN'
                optionsCollapsed[group] = not optionsCollapsed[group]
                FilterOptionsList()
                dialog.searchText:AcquireFocus()
                return true
            end
            return false
        end

    elseif option.type == 'header' then
        bg:SetSolidColor(fillColor)
        bg.label:SetColor('white')
        LayoutHelpers.AtLeftIn(bg.label, bg, 5)
        LayoutHelpers.AtBottomIn(bg.label, bg, 0)

    else -- actual option item
        bg.editorFill:SetSolidColor(fillColor)
        bg.labelsFill:SetSolidColor(fillColor)
        LayoutHelpers.AtLeftIn(bg.label, bg, 10)
        LayoutHelpers.AtVerticalCenterIn(bg.label, bg)

        bg.tipText = ''
        if option.key and option.key ~= '' then
            bg.tipText = "options_" .. option.key
        else
            bg.tipText = { text = 'MISSING tooltip for options_' .. option.key }
        end

        bg.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                bg.labelsFill:SetSolidColor(highlightColor)
                bg.editorFill:SetSolidColor(highlightColor)
                Tooltip.CreateMouseoverDisplay(self, self.tipText, .075, true)
                return true
            elseif event.Type == 'MouseExit' then
                bg.labelsFill:SetSolidColor(fillColor)
                bg.editorFill:SetSolidColor(fillColor)
                Tooltip.DestroyMouseoverDisplay()
                return true
            end
            return false
        end

        local optionEditor = controlTypeCreate[option.type]
        if not optionEditor then
            WARN("Warning: Option item data [" .. option.key .. "] contains an unknown control type: " .. tostring(option.type) .. ". Valid types are")
            for k,v in controlTypeCreate do
                WARN(k)
            end
        else
            bg._control = optionEditor(bg.editorFill, option)

            if option.type == 'slider' then
                LayoutHelpers.AtCenterIn(bg._control, bg.editorFill)
                LayoutHelpers.AtVerticalCenterIn(bg._control, bg, 0)
            else
               LayoutHelpers.FillParentFixedBorder(bg._control, bg.editorFill, 5)
               LayoutHelpers.AtVerticalCenterIn(bg._control, bg, 0)
            end

            optionKeyToControlMap[option.key] = bg._control
        end
    end

    return bg
end

function StringTrim(str)
    return (string.gsub(str, "^%s*(.-)%s*$", "%1"))
end

function GetCurrentValue(optionInfo)
    local value = optionInfo.default

    if currentOptionsSet[optionInfo.key] then
        value = currentOptionsSet[optionInfo.key]
    end

    if optionInfo.type == 'toggle' then
        for _, states in optionInfo.custom or {} do
           for _, state in states or {} do
                if state.key == value then
                    value = LOC(state.text)
                    break -- skip not selected option values
                end
           end
        end
    end
    return value or ''
end

function DisplayOptionsList(currentOptions)
    -- removing peviously created controls and populate grid
    dialog.grid:DeleteAndDestroyAll(true)
    dialog.grid:AppendCols(1, true)

    -- initialzie key to control map each time page is changed, as controls get destroyed
    optionKeyToControlMap = {}

    local index = 1
    -- adding togglable list of options as items to the grid
    for _, options in currentOptions do
        dialog.grid:AppendRows(1, true)
        local optExpander = DisplayOptionsItem(dialog.grid, options, options.count)
        dialog.grid:SetItem(optExpander, 1, index, true)
        index = index + 1
        -- skip displaying collapded options
        if options.collapsed then continue end
        -- adding option list's items to the grid
        for i, option in options.items or {} do
            if option.collapsed then continue end
            dialog.grid:AppendRows(1, true)
            local optCtrl = DisplayOptionsItem(dialog.grid, option)
            dialog.grid:SetItem(optCtrl, 1, index, true)

            if option.init then
                option.init()
            end
            index = index + 1
        end
    end
    dialog.grid:EndBatch()
end

function CreateDialog(over, exitBehavior)
    -- defaulting this dialog to render over the main frame if parent is not passed
    if over == nil then over = GetFrame(0) end

    currentOptionsSet = OptionsLogic.GetCurrent()

    local parent = nil

    -- clear dialog if it was aready open
    if dialog then CloseDialog() end

    -- kill dialog and its current options
    local function KillDialog()

        OptionsLogic.SetCustomDataChangedCallback(nil)
        OptionsLogic.SetSummonRestartDialogCallback(nil)
        OptionsLogic.SetSummonVerifyDialogCallback(nil)
        OptionsLogic.Repopulate()

        if over then
            if dialog then dialog:Destroy() end
        else
            if parent then parent:Destroy() end
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
    LayoutHelpers.AtRightBottomIn(applyBtn, dialog, 15, 20)
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
        for _, optionsGroup in optionsList do
            for _, option in optionsGroup.items or {} do
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

    dialog.fill = Bitmap(dialog)
    dialog.fill:SetSolidColor("FD000000")
    LayoutHelpers.AtLeftTopIn(dialog.fill, dialog, 16, 30)
    LayoutHelpers.AtRightIn(dialog.fill, dialog, 12)
    LayoutHelpers.AnchorToTop(dialog.fill, applyBtn, -5)

    dialog.title = UIUtil.CreateText(dialog, "<LOC _Options>", 22, UIUtil.titleFont)
    LayoutHelpers.AtTopIn(dialog.title, dialog.fill, 5)
    LayoutHelpers.AtHorizontalCenterIn(dialog.title, dialog)

    -- set up option grid
    dialog.grid = Grid(dialog.fill, 100, optionsHeight)
    LayoutHelpers.AtLeftTopIn(dialog.grid, dialog.fill, 10, 75)
    LayoutHelpers.AtRightBottomIn(dialog.grid, dialog.fill, 5, 2)

    dialog.scrollbar = UIUtil.CreateLobbyVertScrollbar(dialog.grid, -15, 5, 5, 0) -- L, B, T, R

    dialog.fill.HandleEvent = function(control, event)
        if dialog.scrollbar and event.Type == 'WheelRotation' then
            local scrollDim = { dialog.grid:GetScrollValues('Vert') }
            if event.WheelRotation <= 0 then -- scroll down
                if scrollDim[2] != scrollDim[4] then -- if we can
                    PlaySound(Sound({ Cue = 'UI_Tab_Rollover_01', Bank = 'Interface' }))
                    dialog.scrollbar:DoScrollLines(1)
                end
            else -- scroll up
                if scrollDim[1] != scrollDim[3] then -- if we can
                    PlaySound(Sound({ Cue = 'UI_Tab_Rollover_01', Bank = 'Interface' }))
                    dialog.scrollbar:DoScrollLines(-1)
                end
            end
        end
    end

    InitializeOptionsList()
    DisplayOptionsList(optionsList)

    if not dialog.grid:IsScrollable("Vert") then
        dialog.scrollbar:Hide()
    end

    OptionsLogic.SetCustomDataChangedCallback(function(optionKey, newCustomData, newDefault)
        if optionKeyToControlMap and optionKeyToControlMap[optionKey] then
            optionKeyToControlMap[optionKey].SetCustomData(newCustomData, newDefault)
        end
    end)

    local function OptionRestartFunc(proceedFunc, cancelFunc)
        UIUtil.QuickDialog(GetFrame(0) , "<LOC options_0001>You have modified an option which requires you to restart Forged Alliance. Selecting OK will exit the game, selecting Cancel will revert the option to its prior setting."
            , "<LOC _OK>", proceedFunc
            , "<LOC _Cancel>", cancelFunc
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

    dialog.searchLabel = UIUtil.CreateText(dialog, 'Search', 17, UIUtil.titleFont)
    LayoutHelpers.AtLeftTopIn(dialog.searchLabel, dialog, 35, 75)

    dialog.searchFill = Bitmap(dialog)
    dialog.searchFill:SetSolidColor("B93E3E3E")
    LayoutHelpers.AtLeftTopIn(dialog.searchFill, dialog, 110, 68)
    LayoutHelpers.AtRightIn(dialog.searchFill, dialog, 20)
    LayoutHelpers.SetHeight(dialog.searchFill, 32)

    dialog.searchFill.Width:Set(function() return dialog.searchFill.Right() - dialog.searchFill.Left() end)
    Tooltip.AddControlTooltip(dialog.searchFill,
    {
        text = '<LOC OPTIONS_search_hint_text>Options Search Box', 
        body = '<LOC OPTIONS_search_hint_body>Search for options by their name or value'
    })
    local hint = LOC("<LOC OPTIONS_search_hint_body>Search for options by name or value")
    dialog.searchHint = UIUtil.CreateText(dialog, hint, 17, UIUtil.titleFont)
    dialog.searchHint:SetColor('FF828282')
    LayoutHelpers.AtHorizontalCenterIn(dialog.searchHint, dialog.searchFill, -10)
    LayoutHelpers.AtVerticalCenterIn(dialog.searchHint, dialog.searchFill, 2)

    dialog.searchText = Edit(dialog.searchFill)
    dialog.searchText:SetForegroundColor('FFF1ECEC') -- --FFF1ECEC
    dialog.searchText:SetBackgroundColor('04E1B44A') -- --04E1B44A
    dialog.searchText:SetHighlightForegroundColor(UIUtil.highlightColor)
    dialog.searchText:SetHighlightBackgroundColor("880085EF") ----880085EF
    LayoutHelpers.FillParentFixedBorder(dialog.searchText, dialog.searchFill, 5)
    LayoutHelpers.AtLeftIn(dialog.searchText, dialog.searchFill, 10)

    dialog.searchText:SetText('')
    dialog.searchText:SetFont(UIUtil.titleFont, 17)
    dialog.searchText:SetMaxChars(40)
    dialog.searchText.OnTextChanged = function(self, newText, oldText)
        -- prevent getting input from keybinding while this dialog is being created
        if not dialog.searchText.isInitialized then
            dialog.searchText.isInitialized = true
            dialog.searchText:SetText('')
            return
        end

        searchKeyword = string.lower(StringTrim(newText))
        if newText == '' then
            dialog.searchHint:SetAlpha(1)
        else
            dialog.searchHint:SetAlpha(0)
            optionsCollapsed = {}
        end
        FilterOptionsList()
    end
    dialog.searchText:AcquireFocus()

    dialog.searchClear = UIUtil.CreateText(dialog.searchText, 'X', 17, UIUtil.titleFont)
    dialog.searchClear:SetColor('FF8A8A8A')
    dialog.searchClear:EnableHitTest()
    LayoutHelpers.AtVerticalCenterIn(dialog.searchClear, dialog.searchFill, 1)
    LayoutHelpers.AtRightIn(dialog.searchClear, dialog.searchFill, 10)
    dialog.searchClear.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            dialog.searchClear:SetColor('FF48D8FC')  
        elseif event.Type == 'MouseExit' then
            dialog.searchClear:SetColor('FF8A8A8A')  
        elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
            dialog.searchText:SetText('')
            dialog.searchText:AcquireFocus()
        end
        return true
    end
    Tooltip.AddControlTooltip(dialog.searchClear,
    {
        text = '<LOC OPTIONS_search_clear_text>Clear Search Filter',
        body = '<LOC OPTIONS_search_clear_body>Clears text that was typed in the search input box.'
    })
end

function OnNISBegin()
    if dialog then
        dialog.cancelBtn:OnClick()
    end
end

function CloseDialog()
    if dialog then
       dialog:Destroy()
    end
end

-- kept for mod backwards compatibility
local Text = import("/lua/maui/text.lua").Text