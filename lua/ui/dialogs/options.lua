--*****************************************************************************
--* File: lua/modules/ui/dialogs/options.lua
--* Author: Chris Blackwell
--* Summary: Manages the options dialog
--*
--* Copyright 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

-- ClassUI rework. Keeps the public CreateDialog/OnNISBegin entry points and the
-- optionslogic contract (each item keeps .control/.change + control.SetCustomData,
-- built by controlTypeCreate).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local MenuCommon = import("/lua/ui/menus/menucommon.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local NinePatch = import("/lua/ui/controls/ninepatch.lua").NinePatch
local Grid = import("/lua/maui/grid.lua").Grid
local Slider = import("/lua/maui/slider.lua").Slider
local Combo = import("/lua/ui/controls/combo.lua").Combo
local IntegerSlider = import("/lua/maui/slider.lua").IntegerSlider
local OptionsLogic = import("/lua/options/optionslogic.lua")
local OptionDefinitions = import("/lua/options/options.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")
local Edit = import("/lua/maui/edit.lua").Edit
local Dragger = import("/lua/maui/dragger.lua").Dragger

local Layouter = LayoutHelpers.ReusedLayoutFor
local scaled = LayoutHelpers.ScaleNumber

-- working options set; module-level so the controlTypeCreate factories close over it
local currentOptionsSet = nil

-- option key -> control map; rebuilt per page, read by the SetCustomData callback
local optionKeyToControlMap = nil

-- the single live dialog instance (or false); referenced by OnNISBegin
---@type UIOptionsDialog | false
local dialogInstance = false

local OptionRowWidth = 718
local OptionRowHeight = 34
local OptionRowContentLeft = 416
local OptionControlWidth = 280

local TabWidth = 136
local TabHeight = 42

local DialogWidth = 840
local DialogHeight = 754
local DialogMargin = 60  -- left/right inset shared by title, tabs, content box, buttons

-- neutral-grey palette, darkest -> lightest: contentAlt (content-area bg) <
-- content (rows) < hover
local ModernColors = {
    content = 'FF1B1B1B',
    contentAlt = 'FF131313',
    contentHover = 'FF272727',
    button = 'FF2C2C2C',
    buttonHover = 'FF3A3A3A',
    strokeSoft = '4C777777',
    text = 'FFEAEAEA',
    textMuted = 'FFAAAAAA',
    accent = 'FFBBBBBB',
    accentSoft = '88777777',
    danger = 'FFC85F5F',
}

-------------------------------------------------------------------------------
--#region Small helpers

---@param parent Control
---@param color Color
---@param width? number
---@param height? number
---@param hitTest? boolean
---@return Bitmap
local function CreateSolid(parent, color, width, height, hitTest)
    local control = UIUtil.CreateBitmapColor(parent, color)

    if width and height then
        LayoutHelpers.SetDimensions(control, width, height)
    end

    if not hitTest then
        control:DisableHitTest()
    end

    return control
end

-- attaches a one-pixel solid border on all four edges of a control
---@param parent Control
---@param color Color
---@param thickness? number
local function AddSolidBorder(parent, color, thickness)
    thickness = thickness or 1

    parent._borderTop = CreateSolid(parent, color, false, false)
    parent._borderBottom = CreateSolid(parent, color, false, false)
    parent._borderLeft = CreateSolid(parent, color, false, false)
    parent._borderRight = CreateSolid(parent, color, false, false)

    LayoutHelpers.AtLeftTopIn(parent._borderTop, parent)
    parent._borderTop.Width:Set(parent.Width)
    parent._borderTop.Height:Set(thickness)

    LayoutHelpers.AtLeftBottomIn(parent._borderBottom, parent)
    parent._borderBottom.Width:Set(parent.Width)
    parent._borderBottom.Height:Set(thickness)

    LayoutHelpers.AtLeftTopIn(parent._borderLeft, parent)
    parent._borderLeft.Width:Set(thickness)
    parent._borderLeft.Height:Set(parent.Height)

    LayoutHelpers.AtRightTopIn(parent._borderRight, parent)
    parent._borderRight.Width:Set(thickness)
    parent._borderRight.Height:Set(parent.Height)
end

-- helper to set all four borders of a control to a single colour at once
---@param control Control
---@param color Color
local function SetBorderColor(control, color)
    control._borderTop:SetSolidColor(color)
    control._borderBottom:SetSolidColor(color)
    control._borderLeft:SetSolidColor(color)
    control._borderRight:SetSolidColor(color)
end

-- routes WheelRotation events on an arbitrary control to a scroll handler while
-- leaving the rest of its event handling intact. Safe to call with nil controls.
---@param control Control
---@param scrollHandler fun(event: KeyEvent): boolean
local function AttachWheelScroll(control, scrollHandler)
    if not control or not scrollHandler or control._optionsWheelScrollAttached then
        return
    end

    control._optionsWheelScrollAttached = true
    control._optionsWheelScrollHandleEvent = control.HandleEvent

    control.HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' and scrollHandler(event) then
            return true
        end

        if self._optionsWheelScrollHandleEvent then
            return self:_optionsWheelScrollHandleEvent(event)
        end
    end
end

-- returns true if the option's localized title or tooltip contains the (already
-- lower-cased) search term; used to filter the option grid while searching
---@param option table
---@param lowerSearch string
---@return boolean
local function OptionMatchesSearch(option, lowerSearch)
    if string.find(string.lower(LOC(option.title)), lowerSearch, 1, true) then
        return true
    end
    if option.tip and string.find(string.lower(LOC(option.tip)), lowerSearch, 1, true) then
        return true
    end
    return false
end

-- chat-window nine-patch, stacked to form the dialog's rounded panel
local ChatPanelPath = '/game/ability_brd/chat'
local function CreatePanelNinePatch(parent)
    local sf = UIUtil.SkinnableFile
    return NinePatch(parent,
        sf(ChatPanelPath .. '_brd_m.dds'),
        sf(ChatPanelPath .. '_brd_ul.dds'), sf(ChatPanelPath .. '_brd_ur.dds'),
        sf(ChatPanelPath .. '_brd_ll.dds'), sf(ChatPanelPath .. '_brd_lr.dds'),
        sf(ChatPanelPath .. '_brd_vert_l.dds'), sf(ChatPanelPath .. '_brd_vert_r.dds'),
        sf(ChatPanelPath .. '_brd_horz_um.dds'), sf(ChatPanelPath .. '_brd_lm.dds'))
end

--#endregion

-------------------------------------------------------------------------------
--#region OptionsButton -- the modern flat button used for OK/Apply/etc. and the `button` control type

---@class UIOptionsButton : Bitmap
---@field Accent Bitmap
---@field Label Text
---@field OnClick? fun(self: UIOptionsButton, modifiers: table)
local OptionsButton = ClassUI(Bitmap) {

    ---@param self UIOptionsButton
    ---@param parent Control
    ---@param label string
    ---@param width number
    ---@param height number
    ---@param accentColor? Color
    __init = function(self, parent, label, width, height, accentColor)
        Bitmap.__init(self, parent)
        self:SetSolidColor(ModernColors.button)

        self._baseColor = ModernColors.button
        self._hoverColor = ModernColors.buttonHover
        self._pressColor = 'FF202020'
        self._accentColor = accentColor or ModernColors.accent
        self._width = width
        self._height = height

        AddSolidBorder(self, ModernColors.strokeSoft)

        self.Accent = CreateSolid(self, self._accentColor, 3, height)

        self.Label = UIUtil.CreateText(self, label, 13, UIUtil.bodyFont)
        self.Label:SetColor(ModernColors.text)
        self.Label:SetDropShadow(true)
        self.Label:DisableHitTest()
    end,

    ---@param self UIOptionsButton
    __post_init = function(self)
        LayoutHelpers.SetDimensions(self, self._width, self._height)
        LayoutHelpers.AtLeftTopIn(self.Accent, self, 0, 0)
        LayoutHelpers.AtCenterIn(self.Label, self)
    end,

    ---@param self UIOptionsButton
    ---@param state 'hover' | 'pressed' | 'normal'
    SetVisualState = function(self, state)
        if state == 'hover' then
            self:SetSolidColor(self._hoverColor)
            SetBorderColor(self, self._accentColor)
        elseif state == 'pressed' then
            self:SetSolidColor(self._pressColor)
        else
            self:SetSolidColor(self._baseColor)
            SetBorderColor(self, ModernColors.strokeSoft)
        end
    end,

    ---@param self UIOptionsButton
    ---@param event KeyEvent
    HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            self:SetVisualState('hover')
        elseif event.Type == 'MouseExit' then
            self:SetVisualState('normal')
        elseif event.Type == 'ButtonPress' then
            self:SetVisualState('pressed')
            PlaySound(Sound({ Cue = 'UI_Menu_MouseDown_Sml', Bank = 'Interface' }))
            if self.OnClick then
                self:OnClick(event.Modifiers)
            end
            return true
        elseif event.Type == 'ButtonRelease' then
            self:SetVisualState('hover')
        end

        return true
    end,
}

--#endregion

-------------------------------------------------------------------------------
--#region OptionsTab -- a category tab along the top of the dialog

---@class UIOptionsTab : Bitmap
---@field Accent Bitmap
---@field Label Text
---@field Selected boolean
---@field TabData table
---@field OnClick? fun(self: UIOptionsTab)
local OptionsTab = ClassUI(Bitmap) {

    ---@param self UIOptionsTab
    ---@param parent Control
    ---@param labelText string
    __init = function(self, parent, labelText)
        Bitmap.__init(self, parent)
        self:SetSolidColor('00000000')

        self._baseColor = '00000000'
        self._hoverColor = '1AFFFFFF'
        self._selectedColor = 'FF222222'
        self.Selected = false

        self.Accent = CreateSolid(self, '00000000', TabWidth, 3)

        self.Label = UIUtil.CreateText(self, labelText, 16, UIUtil.titleFont)
        self.Label:SetDropShadow(true)
        self.Label:SetColor(ModernColors.textMuted)
        self.Label:DisableHitTest()
    end,

    ---@param self UIOptionsTab
    __post_init = function(self)
        LayoutHelpers.SetDimensions(self, TabWidth, TabHeight)
        LayoutHelpers.AtBottomIn(self.Accent, self, 0)
        LayoutHelpers.AtHorizontalCenterIn(self.Accent, self)
        LayoutHelpers.AtCenterIn(self.Label, self, 2, 0)
        self:SetVisualState('normal')
    end,

    ---@param self UIOptionsTab
    ---@param state 'selected' | 'hover' | 'normal'
    SetVisualState = function(self, state)
        if state == 'selected' then
            -- selection is shown by the accent bar + bright label only; no grey box
            self:SetSolidColor('00000000')
            self.Accent:SetSolidColor(ModernColors.accent)
            self.Label:SetColor(ModernColors.text)
        elseif state == 'hover' then
            self:SetSolidColor(self._hoverColor)
            self.Accent:SetSolidColor(ModernColors.accentSoft)
            self.Label:SetColor(ModernColors.text)
        else
            self:SetSolidColor(self._baseColor)
            self.Accent:SetSolidColor('00000000')
            self.Label:SetColor(ModernColors.textMuted)
        end
    end,

    ---@param self UIOptionsTab
    ---@param event KeyEvent
    HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            if not self.Selected then
                self:SetVisualState('hover')
            end
        elseif event.Type == 'MouseExit' then
            if not self.Selected then
                self:SetVisualState('normal')
            end
        elseif event.Type == 'ButtonPress' then
            if self.OnClick then
                self:OnClick()
            end
            return true
        end
    end,
}

--#endregion

-------------------------------------------------------------------------------
--#region OptionsScrollbar -- thin auto-hiding scrollbar bound to a scrollable Grid

---@class UIOptionsScrollbar : Group
---@field Scrollable Grid
---@field Track Bitmap
---@field Thumb Bitmap
local OptionsScrollbar = ClassUI(Group) {

    ---@param self UIOptionsScrollbar
    ---@param parent Control
    ---@param scrollable Grid
    ---@param offsetRight number
    ---@param anchor? Control
    __init = function(self, parent, scrollable, offsetRight, anchor)
        Group.__init(self, parent, "OptionsScrollbar")

        self.Scrollable = scrollable
        self._offsetRight = offsetRight
        self._anchor = anchor or scrollable

        self.Track = CreateSolid(self, '00000000', 12, 12, true)
        self.Thumb = CreateSolid(self, '55FFFFFF', 6, 20, true)

        self.Thumb.HandleEvent = function(thumb, event)
            if event.Type == 'ButtonPress' then
                thumb._dragging = true
                self:SetThumbActive(true)
                local startMouseY = event.MouseY
                local startThumbTop = thumb.Top() - self.Top()
                local trackHeight = self.Height()
                local thumbHeight = thumb.Height()

                local dragger = Dragger()
                dragger.OnMove = function(draggerControl, x, y)
                    if trackHeight > thumbHeight then
                        local relativeY = startThumbTop + (y - startMouseY)
                        local maxRelativeY = trackHeight - thumbHeight
                        relativeY = math.max(0, math.min(maxRelativeY, relativeY))

                        local pct = relativeY / maxRelativeY
                        local minVal, maxVal, visibleMin, visibleMax = self.Scrollable:GetScrollValues('Vert')
                        local totalRange = maxVal - minVal
                        local visibleRange = visibleMax - visibleMin
                        local scrollRange = totalRange - visibleRange

                        if scrollRange > 0 then
                            local newTop = minVal + pct * scrollRange
                            self.Scrollable:ScrollSetTop('Vert', math.floor(newTop))
                        end
                    end
                end

                dragger.OnRelease = function(draggerControl, x, y)
                    thumb._dragging = false
                    if (x >= thumb.Left() and x <= thumb.Right()) and (y >= thumb.Top() and y <= thumb.Bottom()) then
                        self:SetThumbActive(true)
                    else
                        self:SetThumbActive(false)
                    end
                    dragger:Destroy()
                end

                PostDragger(thumb:GetRootFrame(), event.KeyCode, dragger)
                return true
            elseif event.Type == 'MouseEnter' then
                self:SetThumbActive(true)
                return true
            elseif event.Type == 'MouseExit' then
                if not thumb._dragging then
                    self:SetThumbActive(false)
                end
                return true
            end
        end

        self.Track.HandleEvent = function(track, event)
            if event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
                local trackHeight = self.Height()
                local thumbHeight = self.Thumb.Height()
                if trackHeight > thumbHeight then
                    local clickY = event.MouseY - self.Top()
                    local relativeY = clickY - thumbHeight / 2
                    local maxRelativeY = trackHeight - thumbHeight
                    relativeY = math.max(0, math.min(maxRelativeY, relativeY))

                    local pct = relativeY / maxRelativeY
                    local minVal, maxVal, visibleMin, visibleMax = self.Scrollable:GetScrollValues('Vert')
                    local totalRange = maxVal - minVal
                    local visibleRange = visibleMax - visibleMin
                    local scrollRange = totalRange - visibleRange

                    if scrollRange > 0 then
                        local newTop = minVal + pct * scrollRange
                        self.Scrollable:ScrollSetTop('Vert', math.floor(newTop))
                    end
                end
                return true
            elseif event.Type == 'MouseEnter' then
                self:SetThumbActive(true)
                return true
            elseif event.Type == 'MouseExit' then
                if not self.Thumb._dragging then
                    self:SetThumbActive(false)
                end
                return true
            end
        end
    end,

    ---@param self UIOptionsScrollbar
    __post_init = function(self)
        LayoutHelpers.SetWidth(self, 12)
        -- sit just OUTSIDE the content box (in the right margin), not over the rows
        self.Left:Set(function() return self._anchor.Right() + scaled(self._offsetRight) end)
        self.Top:Set(function() return self.Scrollable.Top() + 4 end)
        self.Bottom:Set(function() return self.Scrollable.Bottom() - 4 end)

        LayoutHelpers.FillParent(self.Track, self)
        LayoutHelpers.AtHorizontalCenterIn(self.Thumb, self)

        -- keep the thumb above the track (and both above the rows) so a click on
        -- the thumb starts a drag instead of falling through to a jump-scroll
        self.Track.Depth:Set(function() return self.Depth() + 1 end)
        self.Thumb.Depth:Set(function() return self.Depth() + 2 end)

        self:SetNeedsFrameUpdate(true)
    end,

    ---@param self UIOptionsScrollbar
    ---@param active boolean
    SetThumbActive = function(self, active)
        if active then
            self.Thumb:SetSolidColor('99FFFFFF')
            self.Thumb.Width:Set(scaled(10))
        else
            self.Thumb:SetSolidColor('55FFFFFF')
            self.Thumb.Width:Set(scaled(6))
        end
    end,

    ---@param self UIOptionsScrollbar
    ---@param delta number
    OnFrame = function(self, delta)
        local scrollable = self.Scrollable
        if not scrollable or IsDestroyed(scrollable) then
            self:SetNeedsFrameUpdate(false)
            return
        end

        local minVal, maxVal, visibleMin, visibleMax = scrollable:GetScrollValues('Vert')
        local totalRange = maxVal - minVal
        local visibleRange = visibleMax - visibleMin

        if totalRange <= 0 or visibleRange >= totalRange then
            self:Hide()
            return
        else
            self:Show()
        end

        -- runs every frame, including during a drag, so the thumb tracks the scroll
        local trackHeight = self.Height()
        local thumbHeight = math.max(scaled(20), trackHeight * (visibleRange / totalRange))
        self.Thumb.Height:Set(thumbHeight)

        local scrollRange = totalRange - visibleRange
        local currentPos = visibleMin - minVal
        local pct = 0
        if scrollRange > 0 then
            pct = currentPos / scrollRange
        end

        local maxTop = trackHeight - thumbHeight
        local topOffset = pct * maxTop
        self.Thumb.Top:Set(function() return self.Top() + topOffset end)
    end,

    ---@param self UIOptionsScrollbar
    ---@param delta number
    DoScrollLines = function(self, delta)
        self.Scrollable:ScrollLines('Vert', delta)
    end,
}

--#endregion

-------------------------------------------------------------------------------
--#region Control type factories
-- builds each control type and wires the optionslogic contract on the item:
-- .control, .change(control, value, skipUpdate) and control.SetCustomData(...)

local controlTypeCreate = {

    header = function(parent, optionItemData)
        local group = Group(parent)
        LayoutHelpers.SetDimensions(group, 10, 10)
        return group
    end,

    toggle = function(parent, optionItemData)
        local combo = Combo(parent, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
        LayoutHelpers.SetWidth(combo, 280)

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
        local bg = Group(parent)
        LayoutHelpers.SetDimensions(bg, OptionControlWidth, 24)

        bg._button = OptionsButton(bg, optionItemData.custom.text, 170, 24)
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
            bg._button.Label:SetText(newCustomData)
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

        sliderGroup._value = UIUtil.CreateText(sliderGroup, "", 12)
        LayoutHelpers.RightOf(sliderGroup._value, sliderGroup._slider, 5)
        LayoutHelpers.AtVerticalCenterIn(sliderGroup._value, sliderGroup)

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

--#endregion

-------------------------------------------------------------------------------
--#region OptionRow -- a single option line (label + control) or a section header

---@class UIOptionRow : Bitmap
---@field Control Control
---@field ControlGroup Group
---@field Label Text
---@field Split? Bitmap
---@field _label Text # legacy alias of Label; mod hooks (e.g. SupremeScoreBoard2) read row._label
local OptionRow = ClassUI(Bitmap) {

    ---@param self UIOptionRow
    ---@param parent Control
    ---@param optionItemData table
    __init = function(self, parent, optionItemData)
        Bitmap.__init(self, parent)

        self._optionData = optionItemData
        local isHeader = optionItemData.type == 'header'
        self._isHeader = isHeader

        if isHeader then
            self:SetSolidColor('00000000')
        else
            self:SetSolidColor(ModernColors.content)
            self._baseColor = ModernColors.content
            self._hoverColor = ModernColors.contentHover
            AddSolidBorder(self, ModernColors.strokeSoft)
            self.Split = CreateSolid(self, ModernColors.strokeSoft, 1, OptionRowHeight - 8)
        end

        local labelFont = isHeader and UIUtil.titleFont or UIUtil.bodyFont
        local labelSize = isHeader and 18 or 16
        self.Label = UIUtil.CreateText(self, optionItemData.title, labelSize, labelFont)
        self.Label:SetColor(ModernColors.text)
        self.Label:SetDropShadow(true)
        -- legacy alias so mod hooks can reach the label control as row._label
        self._label = self.Label

        if isHeader then
            self.HeaderLineLeft = CreateSolid(self, ModernColors.accentSoft)
            self.HeaderLineLeft.Height:Set(1)
            self.HeaderLineRight = CreateSolid(self, ModernColors.accentSoft)
            self.HeaderLineRight.Height:Set(1)
        else
            if optionItemData.tip then
                self._tipText = { text = LOC(optionItemData.title), body = LOC(optionItemData.tip) }
            else
                self._tipText = optionItemData.key
            end
        end

        self.ControlGroup = Group(self)
        LayoutHelpers.SetDimensions(self.ControlGroup, OptionControlWidth, 24)

        if controlTypeCreate[optionItemData.type] then
            self.Control = controlTypeCreate[optionItemData.type](self.ControlGroup, optionItemData)
        else
            LOG("Warning: Option item data [" .. optionItemData.key .. "] contains an unknown control type: " .. optionItemData.type .. ". Valid types are")
            for k, v in controlTypeCreate do
                LOG(k)
            end
        end
    end,

    -- the Grid positions the row, so use standalone helpers (legacy layout)
    ---@param self UIOptionRow
    __post_init = function(self)
        LayoutHelpers.SetDimensions(self, OptionRowWidth, OptionRowHeight)

        if self._isHeader then
            LayoutHelpers.AtTopIn(self.Label, self, -9)
            LayoutHelpers.AtHorizontalCenterIn(self.Label, self)

            LayoutHelpers.AtLeftIn(self.HeaderLineLeft, self, 20)
            self.HeaderLineLeft.Right:Set(function() return self.Label.Left() - scaled(18) end)
            LayoutHelpers.AtVerticalCenterIn(self.HeaderLineLeft, self.Label)

            self.HeaderLineRight.Left:Set(function() return self.Label.Right() + scaled(18) end)
            LayoutHelpers.AtRightIn(self.HeaderLineRight, self, 20)
            LayoutHelpers.AtVerticalCenterIn(self.HeaderLineRight, self.Label)
        else
            LayoutHelpers.AtLeftIn(self.Label, self, 14)
            LayoutHelpers.AtVerticalCenterIn(self.Label, self)
            LayoutHelpers.AtLeftIn(self.Split, self, OptionRowContentLeft - 12)
            LayoutHelpers.AtVerticalCenterIn(self.Split, self)
        end

        LayoutHelpers.AtLeftIn(self.ControlGroup, self, OptionRowContentLeft)
        LayoutHelpers.AtVerticalCenterIn(self.ControlGroup, self)

        if self.Control then
            LayoutHelpers.AtLeftIn(self.Control, self.ControlGroup)
            LayoutHelpers.AtVerticalCenterIn(self.Control, self.ControlGroup)
            self.Control.Width:Set(self.ControlGroup.Width)
        end
    end,

    ---@param self UIOptionRow
    ---@param event KeyEvent
    HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            if self._baseColor then
                self:SetSolidColor(self._hoverColor)
                SetBorderColor(self, ModernColors.accentSoft)
            end
            if self._tipText and (type(self._tipText) == 'table' or self._tipText ~= "") then
                if type(self._tipText) == 'table' then
                    Tooltip.CreateMouseoverDisplay(self, self._tipText, nil, true, nil, nil, nil, nil, nil, 'left')
                else
                    Tooltip.CreateMouseoverDisplay(self, "options_" .. self._tipText, nil, true, nil, nil, nil, nil, nil, 'left')
                end
            end
        elseif event.Type == 'MouseExit' then
            if self._baseColor then
                self:SetSolidColor(self._baseColor)
                SetBorderColor(self, ModernColors.strokeSoft)
            end
            Tooltip.DestroyMouseoverDisplay()
        end
    end,
}

--#endregion

-------------------------------------------------------------------------------
--#region Legacy extension seam

-- Mod hook surface: mods wrap global CreateOption and read row._label (e.g.
-- SupremeScoreBoard2). SetNewPage calls this global so overrides take effect.
---@param parent Control
---@param optionItemData table
---@return UIOptionRow
function CreateOption(parent, optionItemData)
    return OptionRow(parent, optionItemData)
end

--#endregion

-------------------------------------------------------------------------------
--#region OptionsDialog -- the dialog itself

---@class UIOptionsDialog : Group
---@field Trash TrashBag
---@field Over Control | false
---@field ScreenGroup Control | false
---@field ExitBehavior? function
---@field ScrollHandler fun(event: KeyEvent): boolean
---@field ContentParent Group
---@field SearchEdit Edit
---@field SearchLabel Text
---@field NoResultsLabel Text
---@field OptionGrid Grid
---@field Scrollbar UIOptionsScrollbar
---@field ContentBackground Bitmap
---@field SearchBackground Bitmap
---@field ApplyBtn UIOptionsButton
---@field CancelBtn UIOptionsButton
---@field OkBtn UIOptionsButton
---@field ResetBtn UIOptionsButton
---@field TabButtons UIOptionsTab[]
---@field DefaultTab UIOptionsTab | false
---@field CurrentTab UIOptionsTab | false
---@field BuildThread thread | false
local OptionsDialog = ClassUI(Group) {

    ---@param self UIOptionsDialog
    ---@param parent Control
    ---@param over Control | false
    ---@param screenGroup Control | false
    ---@param exitBehavior? function
    __init = function(self, parent, over, screenGroup, exitBehavior)
        Group.__init(self, parent, "OptionsDialog")

        self.Trash = TrashBag()
        self.Over = over
        self.ScreenGroup = screenGroup
        self.ExitBehavior = exitBehavior
        self.CurrentTab = false
        self.DefaultTab = false
        self.TabButtons = {}
        self.BuildThread = false  -- deferred row-build thread (see SetNewPage)

        currentOptionsSet = OptionsLogic.GetCurrent()

        -- a plain function bound to this instance for AttachWheelScroll / OptionRow
        self.ScrollHandler = function(event)
            return self:ScrollOptions(event)
        end

        -- two stacked nine-patches: rounded fill under rounded frame (corners match
        -- and the extra layer reads less see-through)
        self.PanelFill = CreatePanelNinePatch(self)
        self.Panel = CreatePanelNinePatch(self)

        self.ContentParent = Group(self, "OptionsContent")
        local content = self.ContentParent

        self.Title = UIUtil.CreateText(content, "<LOC _Options>", 28, UIUtil.titleFont)
        self.Title:SetColor(ModernColors.text)
        self.Title:SetDropShadow(true)

        self.ContentBackground = CreateSolid(content, ModernColors.contentAlt)
        AddSolidBorder(self.ContentBackground, ModernColors.strokeSoft)

        self.SearchBackground = CreateSolid(content, '66151516', 260, 34)
        AddSolidBorder(self.SearchBackground, ModernColors.strokeSoft)

        self.SearchEdit = Edit(content)
        self.SearchLabel = UIUtil.CreateText(content, LOC("<LOC options_search>Search..."), 14, UIUtil.bodyFont)
        self.SearchLabel:SetColor(ModernColors.textMuted)
        self.SearchLabel:DisableHitTest()

        self.SearchEdit.OnTextChanged = function(control, new, old)
            if new ~= "" then
                self.SearchLabel:Hide()
            else
                self.SearchLabel:Show()
            end
            if self.CurrentTab then
                self:SetNewPage(self.CurrentTab)
            end
        end

        -- buttons
        self.ApplyBtn = OptionsButton(content, LOC("<LOC _Apply>"), 116, 34, ModernColors.accent)
        self.CancelBtn = OptionsButton(content, LOC("<LOC _Cancel>"), 116, 34, ModernColors.textMuted)
        self.OkBtn = OptionsButton(content, LOC("<LOC _Ok>"), 116, 34, ModernColors.accent)
        self.ResetBtn = OptionsButton(content, LOC("<LOC _Reset>"), 116, 34, ModernColors.danger)

        self.OkBtn.OnClick = function(btn, modifiers) self:OnOk() end
        self.CancelBtn.OnClick = function(btn, modifiers) self:OnCancel() end
        self.ApplyBtn.OnClick = function(btn, modifiers) self:OnApply() end
        self.ResetBtn.OnClick = function(btn, modifiers) self:OnReset() end

        -- option grid + scrollbar + empty-search placeholder
        self.OptionGrid = Grid(content, OptionRowWidth, OptionRowHeight)
        self.Scrollbar = OptionsScrollbar(content, self.OptionGrid, 8, self.ContentBackground)

        self.NoResultsLabel = UIUtil.CreateText(content, LOC("<LOC options_no_results>No options match your search."), 16, UIUtil.bodyFont)
        self.NoResultsLabel:SetColor(ModernColors.textMuted)
        self.NoResultsLabel:SetDropShadow(true)
        self.NoResultsLabel:DisableHitTest()
        self.NoResultsLabel:Hide()

        -- category tabs
        for _, key in OptionDefinitions.optionsOrder do
            if not OptionDefinitions.options[key] then
                continue
            end

            local tabData = OptionDefinitions.options[key]
            local tab = OptionsTab(content, tabData.title)
            tab.TabData = tabData
            tab.OnClick = function(t) self:SetNewPage(t) end
            table.insert(self.TabButtons, tab)
            if not self.DefaultTab then
                self.DefaultTab = tab
            end
        end
    end,

    ---@param self UIOptionsDialog
    ---@param parent Control
    __post_init = function(self, parent)
        local content = self.ContentParent

        Layouter(self):Width(DialogWidth):Height(DialogHeight):AtCenterIn(GetFrame(0)):End()
        -- fill under frame, both filling the dialog (centres fill, rounded border extends out)
        Layouter(self.PanelFill):Fill(self):End()
        Layouter(self.Panel):Fill(self):End()
        Layouter(content):Fill(self):End()

        Layouter(self.Title):AtLeftTopIn(content, DialogMargin, 28):End()
        Layouter(self.SearchBackground):AtRightTopIn(content, DialogMargin, 30):End()

        -- content box sits under the tab row, spanning the dialog minus margins
        Layouter(self.ContentBackground)
            :AnchorToBottom(self.TabButtons[1], 0)
            :AtLeftIn(content, DialogMargin)
            :AtRightIn(content, DialogMargin)
            :Width(DialogWidth - 2 * DialogMargin)
            :Height(546)
            :End()

        -- the search edit's height is a deferred GetFontHeight() expression set
        -- after SetupEditStd, so lay it out with standalone helpers (no validation)
        LayoutHelpers.AtLeftIn(self.SearchEdit, self.SearchBackground, 8)
        LayoutHelpers.AtVerticalCenterIn(self.SearchEdit, self.SearchBackground)
        LayoutHelpers.SetWidth(self.SearchEdit, 240)
        self.SearchEdit.Height:Set(function() return self.SearchEdit:GetFontHeight() end)
        self.SearchEdit:ShowBackground(false)
        UIUtil.SetupEditStd(self.SearchEdit, ModernColors.text, '00151516', ModernColors.text, ModernColors.accentSoft, UIUtil.bodyFont, 14, 30)
        self.SearchEdit:SetDropShadow(true)
        LayoutHelpers.AtLeftIn(self.SearchLabel, self.SearchBackground, 8)
        LayoutHelpers.AtVerticalCenterIn(self.SearchLabel, self.SearchBackground)

        if self.Over then
            self.Depth:Set(GetFrame(self.Over:GetRootFrame():GetTargetHead()):GetTopmostDepth() + 1)
        end

        -- buttons along the bottom, aligned to the content-box edges
        Layouter(self.ApplyBtn):AtRightBottomIn(content, DialogMargin, 28):End()
        Tooltip.AddControlTooltip(self.ApplyBtn, 'options_tab_apply')
        Layouter(self.CancelBtn):LeftOf(self.ApplyBtn, 12):End()
        Layouter(self.OkBtn):LeftOf(self.CancelBtn, 12):End()
        Layouter(self.ResetBtn):AtLeftBottomIn(content, DialogMargin, 28):End()
        Tooltip.AddControlTooltip(self.ResetBtn, 'options_reset_all')

        -- option grid + scrollbar
        LayoutHelpers.SetDimensions(self.OptionGrid, OptionRowWidth, 544)
        Layouter(self.OptionGrid):AtLeftTopIn(self.ContentBackground, 1, 1):End()
        self.Scrollbar.Depth:Set(function() return self.OptionGrid.Depth() + 10 end)

        local gridDepth = self.OptionGrid.Depth
        self.ApplyBtn.Depth:Set(function() return gridDepth() + 20 end)
        self.CancelBtn.Depth:Set(function() return gridDepth() + 20 end)
        self.OkBtn.Depth:Set(function() return gridDepth() + 20 end)
        self.ResetBtn.Depth:Set(function() return gridDepth() + 20 end)

        Layouter(self.NoResultsLabel):AtCenterIn(self.ContentBackground):End()
        self.NoResultsLabel.Depth:Set(function() return gridDepth() + 5 end)

        -- lay out the tabs left to right
        local prev = false
        for _, tab in self.TabButtons do
            if prev then
                Layouter(tab):RightOf(prev, 8):AtTopIn(prev):End()
            else
                Layouter(tab):AtLeftTopIn(content, DialogMargin, 82):End()
            end
            prev = tab
        end

        -- input + wheel handling (modal first so the wheel wrapper sits outermost)
        UIUtil.MakeInputModal(self, function() self:OnOk() end, function() self:OnCancel() end)

        AttachWheelScroll(self, self.ScrollHandler)
        AttachWheelScroll(content, self.ScrollHandler)
        AttachWheelScroll(self.ContentBackground, self.ScrollHandler)
        AttachWheelScroll(self.SearchBackground, self.ScrollHandler)
        AttachWheelScroll(self.SearchEdit, self.ScrollHandler)
        AttachWheelScroll(self.ApplyBtn, self.ScrollHandler)
        AttachWheelScroll(self.CancelBtn, self.ScrollHandler)
        AttachWheelScroll(self.OkBtn, self.ScrollHandler)
        AttachWheelScroll(self.ResetBtn, self.ScrollHandler)
        AttachWheelScroll(self.OptionGrid, self.ScrollHandler)

        self:SetNewPage(self.DefaultTab)

        -- register optionslogic hooks now that the initial page exists
        OptionsLogic.SetCustomDataChangedCallback(function(optionKey, newCustomData, newDefault)
            if optionKeyToControlMap and optionKeyToControlMap[optionKey] then
                optionKeyToControlMap[optionKey].SetCustomData(newCustomData, newDefault)
            end
        end)

        OptionsLogic.SetSummonRestartDialogCallback(function(proceedFunc, cancelFunc)
            UIUtil.QuickDialog(GetFrame(0), "<LOC options_0001>You have modified an option which requires you to restart Forged Alliance. Selecting OK will exit the game, selecting Cancel will revert the option to its prior setting.",
                "<LOC _OK>", proceedFunc,
                "<LOC _Cancel>", cancelFunc,
                nil, nil,
                true,
                { escapeButton = 2, enterButton = 1, worldCover = false }
            )
        end)

        OptionsLogic.SetSummonVerifyDialogCallback(function(undoFunc)
            local secondsToWait = 15
            local thread

            local dlg = UIUtil.QuickDialog(GetFrame(0), "<LOC options_0003>Click OK to accept these settings.",
                LOC("<LOC _Ok>") .. " [" .. secondsToWait .. "]", function() KillThread(thread) end,
                "<LOC _Cancel>", function() KillThread(thread) undoFunc() end,
                nil, nil,
                true,
                { escapeButton = 2, enterButton = 1, worldCover = false }
            )

            thread = ForkThread(function()
                for sec = 1, secondsToWait do
                    WaitSeconds(1)
                    dlg.content._button1.label:SetText(LOC("<LOC _Ok>") .. " [" .. (secondsToWait - sec) .. "]")
                end
                dlg:Destroy()
                undoFunc()
            end)
        end)
    end,

    -- scrolls the option grid in response to a mouse wheel event
    ---@param self UIOptionsDialog
    ---@param event KeyEvent
    ---@return boolean
    ScrollOptions = function(self, event)
        local optionGrid = self.OptionGrid
        if not optionGrid:IsScrollable("Vert") then
            return false
        end

        local scrollDim = { optionGrid:GetScrollValues('Vert') }
        local direction = 1

        if event.WheelRotation > 0 then
            direction = -1
            if scrollDim[1] == scrollDim[3] then
                return true
            end
        elseif scrollDim[2] == scrollDim[4] then
            return true
        end

        local wheelDelta = math.abs(event.WheelRotation or 1)
        local lines = math.max(1, math.ceil(wheelDelta / 120))
        self.Scrollbar:DoScrollLines(direction * math.max(lines, 3))
        return true
    end,

    -- rebuilds the option grid for the given tab, honouring the search box. The
    -- visible rows are built now; the rest stream in over the next frames (see
    -- self.BuildThread) so the window appears immediately.
    ---@param self UIOptionsDialog
    ---@param tabControl UIOptionsTab
    SetNewPage = function(self, tabControl)
        -- cancel any in-flight deferred build from a previous page/keystroke
        if self.BuildThread then
            KillThread(self.BuildThread)
            self.BuildThread = false
        end

        if self.CurrentTab and self.CurrentTab ~= tabControl then
            self.CurrentTab.Selected = false
            self.CurrentTab:SetVisualState('normal')
        end

        local searchString = self.SearchEdit:GetText()
        local isSearching = searchString and searchString ~= ""
        local lowerSearch = isSearching and string.lower(searchString) or nil

        if self.CurrentTab ~= tabControl then
            self.CurrentTab = tabControl
            tabControl.Selected = true
            tabControl:SetVisualState('selected')
        end

        Tooltip.DestroyMouseoverDisplay()
        local optionGrid = self.OptionGrid
        optionGrid:DeleteAndDestroyAll(true)
        optionGrid:AppendCols(1, true)
        optionKeyToControlMap = {}

        -- collect the filtered, ordered list of options to show (no controls yet)
        local displayItems = {}
        local function collect(tData)
            for index, option in tData.items do
                if isSearching then
                    -- headers are dividers, not options; skip so results aren't orphaned
                    if option.type == 'header' then
                        continue
                    end
                    -- string.lower does not fully handle Unicode case matching
                    if not OptionMatchesSearch(option, lowerSearch) then
                        continue
                    end
                end
                table.insert(displayItems, option)
            end
        end
        if isSearching then
            for _, key in OptionDefinitions.optionsOrder do
                if OptionDefinitions.options[key] then
                    collect(OptionDefinitions.options[key])
                end
            end
        else
            collect(tabControl.TabData)
        end

        if isSearching and table.getn(displayItems) == 0 then
            self.NoResultsLabel:Show()
        else
            self.NoResultsLabel:Hide()
        end

        -- builds the next pending row (empty row before each header so all sections
        -- space the same); returns false when the list is exhausted
        local row = 1
        local nextItem = 1
        local function buildNext()
            local option = displayItems[nextItem]
            if not option then return false end
            nextItem = nextItem + 1

            if option.type == 'header' then
                optionGrid:AppendRows(1, true)
                row = row + 1
            end

            optionGrid:AppendRows(1, true)
            -- call the global factory (not OptionRow directly) so mod hooks that
            -- wrap CreateOption are honored
            local optCtrl = CreateOption(optionGrid, option)

            -- forward wheel scrolling from every hit-testable part of the row
            AttachWheelScroll(optCtrl, self.ScrollHandler)
            AttachWheelScroll(optCtrl._label, self.ScrollHandler)
            AttachWheelScroll(optCtrl.ControlGroup, self.ScrollHandler)
            AttachWheelScroll(optCtrl.Control, self.ScrollHandler)
            if optCtrl.Control then
                AttachWheelScroll(optCtrl.Control._button, self.ScrollHandler)
                AttachWheelScroll(optCtrl.Control._slider, self.ScrollHandler)
                AttachWheelScroll(optCtrl.Control._value, self.ScrollHandler)
            end

            if option.type ~= 'header' then
                optionKeyToControlMap[option.key] = optCtrl.Control
            end

            optionGrid:SetItem(optCtrl, 1, row, true)
            if option.init then
                option.init()
            end
            row = row + 1
            return true
        end

        -- first batch: fill the visible viewport (+buffer) right now
        local _, visibleRows = optionGrid:GetVisible()
        local firstBatchRows = (visibleRows or 16) + 2
        while row <= firstBatchRows and buildNext() do end
        optionGrid:EndBatch()

        -- stream the rest over the next frames. Every row is still built (within a
        -- few frames, before the user can realistically interact), so cross-control
        -- cascades like the video fidelity presets keep working. The scrollbar
        -- auto-sizes from the grid each frame in its OnFrame, so it needs no poke.
        if displayItems[nextItem] then
            self.BuildThread = ForkThread(function()
                while true do
                    WaitFrames(1)
                    if IsDestroyed(self) or IsDestroyed(optionGrid) then return end
                    local builtThisFrame = 0
                    while builtThisFrame < 8 and buildNext() do
                        builtThisFrame = builtThisFrame + 1
                    end
                    optionGrid:EndBatch()
                    if not displayItems[nextItem] then break end
                end
                self.BuildThread = false
            end)
        end
    end,

    ---@param self UIOptionsDialog
    OnOk = function(self)
        OptionsLogic.SetCurrent(currentOptionsSet)
        self:KillDialog()
        if self.ExitBehavior then self.ExitBehavior() end
    end,

    ---@param self UIOptionsDialog
    OnCancel = function(self)
        for _, key in OptionDefinitions.optionsOrder do
            if OptionDefinitions.options[key] then
                for _, option in OptionDefinitions.options[key].items do
                    if option.cancel then
                        option.cancel()
                    end
                end
            end
        end

        self:KillDialog()
        if self.ExitBehavior then self.ExitBehavior() end
    end,

    ---@param self UIOptionsDialog
    OnApply = function(self)
        OptionsLogic.SetCurrent(currentOptionsSet)
    end,

    ---@param self UIOptionsDialog
    OnReset = function(self)
        local function DoReset()
            OptionsLogic.ResetToDefaults()
            -- recreating the dialog reloads the old options without saving the new ones,
            -- which resets all the controls
            self:KillDialog()
            if self.ExitBehavior then self.ExitBehavior() end
        end

        UIUtil.QuickDialog(self, "<LOC options_0002>Are you sure you want to reset to default values?",
            "<LOC _Yes>", DoReset,
            "<LOC _No>", nil,
            nil, nil,
            true,
            { escapeButton = 2, enterButton = 1, worldCover = false })
    end,

    ---@param self UIOptionsDialog
    KillDialog = function(self)
        -- destroying triggers OnDestroy, which clears the module reference and
        -- resets the optionslogic hooks regardless of how the dialog is torn down
        if self.Over then
            self:Destroy()
        else
            self.ScreenGroup:Destroy()
        end
    end,

    ---@param self UIOptionsDialog
    OnDestroy = function(self)
        if self.BuildThread then
            KillThread(self.BuildThread)
            self.BuildThread = false
        end
        if dialogInstance == self then
            dialogInstance = false
        end
        OptionsLogic.SetCustomDataChangedCallback(nil)
        OptionsLogic.SetSummonRestartDialogCallback(nil)
        OptionsLogic.SetSummonVerifyDialogCallback(nil)
        OptionsLogic.Repopulate()
        self.Trash:Destroy()
    end,
}

--#endregion

-------------------------------------------------------------------------------
--#region Public API (preserved entry points)

--- Opens the options dialog.
---@param over? Control if given, the dialog is layered over this control; otherwise it builds its own screen group
---@param exitBehavior? function called after the dialog closes via OK/Cancel/Reset
function CreateDialog(over, exitBehavior)
    local parent
    local screenGroup = false

    if over then
        parent = over
    else
        parent = UIUtil.CreateScreenGroup(GetFrame(0), "Options ScreenGroup")
        MenuCommon.SetupBackground(GetFrame(0))
        screenGroup = parent
    end

    dialogInstance = OptionsDialog(parent, over or false, screenGroup, exitBehavior)
    return dialogInstance
end

--- Cancels an open options dialog when a non-interactive sequence begins.
function OnNISBegin()
    if dialogInstance then
        dialogInstance:OnCancel()
    end
end

--#endregion

-- kept for mod backwards compatibility
local Text = import("/lua/maui/text.lua").Text
