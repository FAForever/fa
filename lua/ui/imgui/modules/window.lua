

local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Button = import('/lua/maui/button.lua').Button
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local StatusBar = import('/lua/maui/statusbar.lua').StatusBar
local Combo = import('/lua/ui/controls/combo.lua').Combo
-- local Histogram = import('/lua/maui/histogram.lua').Histogram
local GameMain = import('/lua/ui/game/gamemain.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local Prefs = import('/lua/user/prefs.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')

local MapPreview = import('/lua/ui/controls/mappreview.lua').MapPreview

-- used
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Slider = import('/lua/maui/slider.lua').Slider

local Conversion = import('/lua/ui/imgui//modules/conversion.lua')
local ToLabel = Conversion.ToLabel

-- construction methods
local WindowConstructFloating = import('/lua/ui/imgui/modules/window-types/floating.lua').WindowConstructFloating
local WindowConstructDockedLeft = import('/lua/ui/imgui/modules/window-types/docked-left.lua').WindowConstructDockedLeft

local WindowText = import('/lua/ui/imgui/modules/ui-elements/text.lua')
local TextOnBegin = WindowText.OnBegin
local TextOnEnd = WindowText.OnEnd
local AllocateText = WindowText.AllocateText
local CreateText = WindowText.CreateText
local SetTextColor = WindowText.SetTextColor
local TextWithLabel = WindowText.TextWithLabel

-- Every element needs to expose / use the following data:
-- - height: determines the height of the element, used for lists
-- - used: determines whether the element should be hidden or not

--- Basic window metatable
mWindow = { }
mWindow.__index = mWindow

local windows = { }

--- Constructs a window.
-- @param identifier The identifier of the window used for the internal state.
-- @param type The type of window, either 'floating' or 'docked-left'.
-- @param data A table with additional data, including:
-- @param data.width The maximum width of the window
-- @param data.height The maximum height of the window
-- @param data.grow Whether or not the window grows accordingly (in height)
function WindowConstruct(identifier, type, width, height)

    -- if we already made this - return it
    if windows[identifier] then
        return windows[identifier]
    end

    -- make metatable connection
    local window = { }
    setmetatable(window, mWindow)

    -- receive and prepare information
    window.identifier = identifier
    window.height = height

    -- the original values used when drawing restarts
    window.oOutline = 20
    window.oOffset = 35
    window.oRightOutline = 16

    -- the current values 
    window.outline = window.oOutline
    window.offset = window.oOffset
    window.rightOutline = window.oRightOutline

    window.elements = { }

    -- keeps track of anonymous dividers
    window.dividerElementIndex = 1
    window.dividerElementCount = 0
    window.dividerElements = { }

    -- keeps track of anonymous bitmaps
    window.bitmapElementIndex = 1
    window.bitmapElementCount = 0
    window.bitmapElements = { }

    -- keeps track of anonymous text
    window.textElementIndex = 1
    window.textElements = { }
    window.textColor = "ffffffff"

    -- used for list and rendering elements
    window.oMinOffset = window.oOffset
    window.oMaxOffset = 800

    window.minOffset = window.oMinOffset
    window.maxOffset = window.oMaxOffset

    -- keeps track of the elements in this window
    window.tracker = window.elements

    -- construct the actual window
    window.main = { }
    if type == "floating" then 
        window.main = WindowConstructFloating(identifier)
        window.type = type 
    elseif type == "docked-left" then 
        window.main = WindowConstructDockedLeft(identifier, 172, width, 700)
        window.type = type 
    else 
        WARN("Unknown window type:" .. tostring(type) .. " , constructing floating window.")
        window.main = WindowConstructFloating(identifier)
        window.type = "floating" 
    end

    -- keep track of it
    windows[identifier] = window
    return window 
end

function WindowDeconstruct(identifier)
    -- if it exists, try to remove it.
    if windows[identifier] then
        windows[identifier]:Destroy()
        windows[identifier] = nil
    else
        WARN("Tried to remove a non-existing window: " .. identifier)
    end
end

--- Retrieves a window.
function WindowGet(identifier)
    -- if it exists, try to remove it.
    if windows[identifier] then
        return windows[identifier]
    else
        WARN("Tried to get a non-existing window: " .. identifier .. ". Constructing the window as backup.")
        return WindowConstruct(identifier)
    end
end

--- Completely destroy the window.
function mWindow:Destroy()
    for k, element in self.elements do 
        if element.Destroy then 
            element:Destroy()
        else 
            -- log?
        end 
    end
end

--- Initialises the window for rendering.
function mWindow:Begin()

    -- reset properties of the window
    self.outline = self.oOutline
    self.rightOutline = self.oRightOutline
    self.offset = self.oOffset
    self.minOffset = self.oMinOffset
    self.maxOffset = self.oMaxOffset

    -- reset used anonymous elements
    self.dividerElementIndex = 1
    self.textElementIndex = 1
    self.bitmapElementIndex = 1

    local function MarkElementsAsUnused(elements, count)
        if count then 
            -- index-based table
            for k = 1, count do 
                elements[k].used = false
            end
        else 
            -- hash-based table
            for k, element in elements do 
                element.used = false 
            end
        end
    end

    -- mark everything
    MarkElementsAsUnused(self.elements)
    MarkElementsAsUnused(self.textElements)
    MarkElementsAsUnused(self.dividerElements, self.dividerElementCount)
    MarkElementsAsUnused(self.bitmapElements, self.bitmapElementCount)
end

--- Finalizes the window for rendering.
function mWindow:End()

    local function HideUnusedElements(elements, count)
        if count then 
            -- index-based table
            for k = 1, count do 
                local element = elements[k]
                if not element.used then 
                    element:Hide()
                end
            end
        else 
            -- hash-based table
            for k, element in elements do 
                if not element.used then 
                    element:Hide()
                end
            end 
        end
    end

    -- hide unused elements
    HideUnusedElements(self.elements)
    HideUnusedElements(self.textElements)
    HideUnusedElements(self.dividerElements, self.dividerElementCount)
    HideUnusedElements(self.bitmapElements, self.bitmapElementCount)

    if self.type == "docked-left" then 
        LayoutHelpers.SetHeight(self.main, self.offset - 10)
    end

end

function mWindow:IsHidden()
    return self.main:IsHidden()
end

function mWindow:Show()
    self.main:Show()
end

function mWindow:Hide()
    self.main:Hide()
end

--- Adds a text entry.
-- @param identifier The identifier of this element.
-- @param value The text of this element.
mWindow.Text = CreateText
mWindow.CreateText = CreateText 

--- Adds a text entry.
-- @param identifier The identifier of this element.
-- @param value The text of this element.
mWindow.AllocateText = AllocateText

--- Sets the text color of the upcoming text element. Initial value is 'ffffffff'.
-- @param color The color to set the text to.
mWindow.SetTextColor = SetTextColor

--- Adds two text entries, as if they are two columns.
-- @param left The left text value.
-- @param right The right text value.
-- @param size The size of the text.
-- @param perc The percentage (in width) when the right column starts
mWindow.TextWithLabel = TextWithLabel

--- Allocates a generic bitmap.
-- @param color The color of the bitmap.
function mWindow:AllocateBitmap(color)
    -- check if one is free
    local element = self.bitmapElements[self.bitmapElementIndex]
    if not element then 

        -- create the bitmap
        element = Bitmap(self.main)
        element.Depth:Set(10)

        -- keep track of it
        self.bitmapElements[self.bitmapElementIndex] = element
        self.bitmapElementCount = self.bitmapElementCount + 1
    end

    -- default scaling
    element.Left:Set( function() return self.main.Left() + self.outline end )
    element.Right:Set( function() return self.main.Right() - self.outline end )
    element.Height:Set(5)

    -- keep track that it is used
    element.used = true
    element:SetSolidColor(color)

    -- check if the element was previously hidden
    if element:IsHidden() then 
        element:Show()
    end

    -- update index that represents what text element we've used so far
    self.bitmapElementIndex = self.bitmapElementIndex + 1

    return element
end

--- Retrieves a divider element. Returns a cached element if possible, allocates a 
-- new one if no cached element is available.
function mWindow:AllocateDivider()
    -- check if one is free
    local element = self.dividerElements[self.dividerElementIndex]
    if not element then 

        -- create the bitmap
        element = Bitmap(self.main)
        element:SetSolidColor('dddddddd')

        -- keep track of it
        self.dividerElements[self.dividerElementIndex] = element
        self.dividerElementCount = self.dividerElementCount + 1
    end

    -- check if we fit
    if self:HasSufficientSpace(2) then 
        -- keep track that it is used
        element.used = true

        -- check if the element was previously hidden
        if element:IsHidden() then 
            element:Show()
        end

        -- scale it
        local outline = self.outline 
        local rightOutline = self.rightOutline
        element.Left:Set( function() return self.main.Left() + outline end )
        element.Right:Set( function() return self.main.Right() - rightOutline end )
        element.Height:Set(1)

        -- update index that represents what text element we've used so far
        self.dividerElementIndex = self.dividerElementIndex + 1
    end

    return element
end

local _checkboxTextures = { }
_checkboxTextures["up"] = '/textures/ui/common/game/orders/intel-counter_btn_dis_sel.dds'
_checkboxTextures["up-sel"] = '/textures/ui/common/game/orders/intel-counter_btn_up.dds'
_checkboxTextures["down"] = '/textures/ui/common/game/orders/intel-counter_btn_down.dds'
_checkboxTextures["over"] = '/textures/ui/common/game/orders/intel-counter_btn_over.dds'
_checkboxTextures["over-sel"] = '/textures/ui/common/game/orders/intel-counter_btn_over_sel.dds'
_checkboxTextures["disabled"] = '/textures/ui/common/game/orders/advanced-empty_btn_slot.dds'

--- Adds a checkbox entry.
function mWindow:Checkbox(identifier, value)

    local element = self.tracker[identifier]
    if not element then 

        -- create a standard group
        element = Group(self.main)
        element:DisableHitTest()

        -- prevents errors with regard to the size of the group
        LayoutHelpers.SetWidth(element, 10)
        LayoutHelpers.SetHeight(element, 10)

        -- button parameters
        local normal = _checkboxTextures["up"]
        local active = _checkboxTextures["down"]
        local normalSel = _checkboxTextures["up-sel"]
        local highlight = _checkboxTextures["over"]
        local highlightSel = _checkboxTextures["over-sel"]
        local disabled = _checkboxTextures["disabled"]
        local clickCue = "UI_Mini_MouseDown"
        local rolloverCue = "UI_Mini_Rollover"

        -- create the checkbox
        element.checkbox = Checkbox(element, normal, normalSel, highlight, highlightSel, disabled, disabled, nil, nil, nil, clickCue, rolloverCue)
        LayoutHelpers.AtLeftTopIn(element.checkbox, element, 0, 0)
        element.checkbox.Width:Set(32)
        element.checkbox.Height:Set(32)
        element.checkbox.Depth:Set(2000)
        element.checkbox:SetCheck(value)

        -- create the label
        local label = ToLabel(identifier) 
        element.label = UIUtil.CreateText(element, label, 12, UIUtil.bodyFont)
        element.label:SetColor(self.textColor)
        element.label:SetText(label)
        LayoutHelpers.CenteredRightOf(element.label, element.checkbox, 6)

        -- keep track of whether we've changed
        element.interacted = false
        element.checkbox.OnClick = function(self)
            self:ToggleCheck()
            element.interacted = true
        end

        -- keep track of it
        self.tracker[identifier] = element
    end

    -- position it
    LayoutHelpers.AtLeftTopIn(element, self.main, self.outline, self.offset)

    -- update internal state
    self:UpdateOffset(36)
    
    element.used = true
    if element:IsHidden() then 
        element:Show()
    end

    -- update from external source if we didn't update internally
    if not element.interacted then 
        -- set value 
        element.checkbox:SetCheck(value, true)
    end

    -- store so that we can return it
    local interacted = element.interacted
    element.interacted = false

    -- return whether we're checked
    return element.checkbox:IsChecked(), interacted
end

--- Constructs a scroll bar that limits the elements inside
function mWindow:BeginList(identifier, height)



    local element = self.tracker[identifier]
    if not element then 

        -- create a standard group
        element = Group(self.main)
        element:DisableHitTest()

        -- prevents errors with regard to the size of the group
        LayoutHelpers.SetWidth(element, 10)
        LayoutHelpers.SetHeight(element, 10)

        -- create vertical
        -- create slider UI element
        local parent = element 
        local isVertical = true 
        local startValue = -2
        local endValue = height
        local thumb = "/lua/ui/imgui//textures/scrollbar-dds/button-up.dds"
        local thumbOver = "/lua/ui/imgui//textures/scrollbar-dds/button-over.dds"
        local thumbDown = "/lua/ui/imgui//textures/scrollbar-dds/button-down.dds"
        local background = "/lua/ui/imgui//textures/scrollbar-dds/background.dds"
        element.slider = Slider(element, isVertical, startValue, endValue, thumb, thumbOver, thumbDown, background)
        element.slider:SetValue(height)
        
        -- make it stick to the group
        local rightOutline = self.rightOutline
        LayoutHelpers.AtLeftTopIn(element.slider, element, 0, 10)
        element.slider.Left:Set(function() return self.main.Right() - rightOutline - 16 end )
        element.slider.Width:Set(16)
        element.slider.Height:Set(height - 20)
        element.slider._background.Width:Set(16)
        element.slider._background.Height:Set(height - 20)
        element.slider._thumb.Width:Set(16)
        element.slider._thumb.Height:Set(16)

        element.scrollbarOffset = 0

        -- slider functionality
        element.slider.OnBeginChange =
            function()
                element.update = false
            end

        element.slider.OnScrub = 
            function(self,value)
                element.scrollbarOffset = self._endValue - math.floor(value)
            end

        element.slider.OnValueSet = 
            function(self, value) 
                element.scrollbarOffset = self._endValue - math.floor(value)
            end

        element.slider.OnEndChange =
            function()
                element.update = true
            end

        -- keep track of it
        self.tracker[identifier] = element
    end

    -- position it
    LayoutHelpers.AtLeftTopIn(element, self.main, self.outline, self.offset)

    self:Indent()
    self:UpdateRightOffset(16)

    -- store old window state
    element.cOffset = self.offset - element.scrollbarOffset
    element.wOffset = self.offset
    element.wMinOffset = self.minOffset
    element.wMaxOffset = self.maxOffset

    -- set new window state
    -- todo: what if list is too big for window?
    self.minOffset = self.offset  
    self.maxOffset = self.minOffset + height
    self.offset = self.offset - element.scrollbarOffset

    element.height = height
end

function mWindow:EndList(identifier)

    local element = self.tracker[identifier]

    -- set slider end value
    local endValue = math.min(self.offset - element.cOffset - element.height) + 2
    element.slider:SetEndValue(endValue)

    if self.offset - element.wOffset + element.scrollbarOffset > element.height then 
        element.used = true
        if element:IsHidden() then 
            element:Show()
        end
    end

    -- restore window state
    self.minOffset = element.wMinOffset
    self.maxOffset = element.wMaxOffset
    self.offset = element.wOffset + element.height

    self:Unindent()
    self:UpdateRightOffset(-16)
end

local _buttonTextures = { }
_buttonTextures["up"] = '/textures/ui/common/game/orders/guard_btn_dis.dds'
_buttonTextures["down"] = '/textures/ui/common/game/orders/guard_btn_down.dds'
_buttonTextures["over"] = '/textures/ui/common/game/orders/guard_btn_over.dds'
_buttonTextures["disabled"] = '/textures/ui/common/game/orders/basic-empty_btn_slot.dds'

function mWindow:Button(identifier)

    local element = self.tracker[identifier]
    if not element then 

        -- create a standard group
        element = Group(self.main)
        element:DisableHitTest()

        -- prevents errors with regard to the size of the group
        LayoutHelpers.SetWidth(element, 10)
        LayoutHelpers.SetHeight(element, 10)

        -- button parameters
        local normal = _buttonTextures["up"]
        local active = _buttonTextures["down"]
        local highlight = _buttonTextures["over"]
        local disabled = _buttonTextures["disabled"]
        local clickCue = "UI_Opt_Yes_No"
        local rolloverCue = "UI_Opt_Affirm_Over"

        -- create the button
        element.button = Button(element, normal, active, highlight, disabled, clickCue, rolloverCue)
        LayoutHelpers.AtLeftTopIn(element.button, element, 0, 0)
        element.button.Width:Set(32)
        element.button.Height:Set(32)
        element.button.Depth:Set(2000)

        -- create the label
        local label = ToLabel(identifier) 
        element.label = UIUtil.CreateText(element, label, 12, UIUtil.bodyFont)
        element.label:SetColor(self.textColor)
        element.label:SetText(label)
        LayoutHelpers.CenteredRightOf(element.label, element.button, 6)

        -- state management
        element.height = 36
        element.enabled = false 
        element.button.OnClick = function(self, modifiers)
            element.enabled = true
        end

        -- keep track of it
        self.tracker[identifier] = element
    end

    -- position it
    LayoutHelpers.AtLeftTopIn(element, self.main, self.outline, self.offset)

    -- update internal state
    self:UpdateOffset(element.height)
    
    element.used = true
    if element:IsHidden() then 
        element:Show()
    end

    -- pass on the button state
    local enabled = element.enabled
    element.enabled = false

    return enabled
end

function mWindow:SetTextColor(color)
    self.textColor = color
end

--- Adds two text entries, as if they are two columns.
-- @param left The left text value.
-- @param right The right text value.
-- @param size The size of the text.
-- @param perc The percentage (in width) when the right column starts
function mWindow:TextWithLabel(label, value, perc)
    -- check if we fit
    if self:HasSufficientSpace(12) then 
        -- scope them so that they can be uplifted
        local outline = self.outline
        local oOutline = self.oOutline 
        local rightOutline = self.rightOutline
        local offset = self.offset

        do 
            -- retrieve a text element
            local element = self:AllocateText()

            -- update text content
            element:SetColor(self.textColor)
            element:SetText(label)

            -- position it
            element.Top:Set(function() return self.main.Top() + offset end )
            element.Left:Set(function() return self.main.Left() + outline end)
            element.height = 12
        end

        do 
            -- retrieve a text element
            local element = self:AllocateText()

            -- update text content
            element:SetColor("ffffffff")
            element:SetText(value)

            -- position it
            element.Top:Set(function() return self.main.Top() + offset end )
            element.Left:Set(function() return self.main.Left() + outline + math.floor(perc * (self.main.Right() - self.main.Left() - rightOutline )) - rightOutline end)
            element.height = 12
        end
    end

    -- update internal state
    self:UpdateOffset(12)
end

--- Adds a text input field.
-- @param identifier The identifier of this element.
-- @param label The name of this element displayed in the UI.
-- @param callback Called when the value is changed.
function mWindow:InputText(identifier, label, callback)

end

-- look up table for textures
local _collapsingHeaderTextures = { }
_collapsingHeaderTextures["up"] = "/lua/ui/imgui//textures/collapsable-header-dds/default-up.dds"
_collapsingHeaderTextures["up-off"] = "/lua/ui/imgui//textures/collapsable-header-dds/default-up-off.dds"
_collapsingHeaderTextures["down"] = "/lua/ui/imgui//textures/collapsable-header-dds/default-down.dds"
_collapsingHeaderTextures["over"] = "/lua/ui/imgui//textures/collapsable-header-dds/default-over.dds"
_collapsingHeaderTextures["disabled"] = "/lua/ui/imgui//textures/collapsable-header-dds/default-down.dds"

--- Adds a collapsable header. Returns a boolean indicating whether the header is open.
-- @param identifier The identifier of this element.
-- @param label The name of this element displayed in the UI.
function mWindow:BeginCollapsingHeader(identifier)

    local element = self.tracker[identifier]
    if not element then 

        -- generic group element
        element = Group(self.main)
        element:DisableHitTest()

        -- prevents errors with regard to the size of the group
        LayoutHelpers.SetWidth(element, 10)
        LayoutHelpers.SetHeight(element, 10)

        -- create the button element
        local normal = _collapsingHeaderTextures["up"]
        local active = _collapsingHeaderTextures["down"]
        local highlight = _collapsingHeaderTextures["over"]
        local disabled = _collapsingHeaderTextures["disabled"]
        local clickCue = "UI_Main_Window_Open"
        local rolloverCue = "UI_Opt_Affirm_Over"
        element.button = Button(element, normal, active, highlight, disabled, clickCue, rolloverCue)
        LayoutHelpers.AtLeftTopIn(element.button, element, 0, 0)
        
        -- uplift the value
        local outline = self.outline
        local rightOutline = self.rightOutline
        element.button.Left:Set( function() return self.main.Left() + outline end )
        element.button.Right:Set( function() return self.main.Right() - rightOutline end )
        element.button.Height:Set(20)
        element.button.Depth:Set(2000)

        -- toggles the element
        element.button.OnClick = function(self, modifiers)
            element.enabled = not element.enabled
            element.changed = true 
        end

        -- create the text element
        local size = 12
        local color = "ffffffff"
        local label = string.gsub(identifier, "(#.*)", "")
        element.text = UIUtil.CreateText(element, label, size, UIUtil.bodyFont)
        LayoutHelpers.AtLeftTopIn(element.text, element, 5, 2)
        element.text:SetColor(color)
        element.text.Depth:Set(2001)
        element.text:DisableHitTest()

        -- add properties
        element.height = 20
        element.changed = false
        element.enabled = false 
        element.identifier = identifier

        -- keep track of it
        self.tracker[identifier] = element
    end

    -- position it
    LayoutHelpers.AtLeftTopIn(element, self.main, self.outline, self.offset + 1)

    -- update the button if applicable
    if element.changed then 
        if element.enabled then 
            element.button:SetTexture(_collapsingHeaderTextures["up"])
            element.button:SetNewTextures(
                _collapsingHeaderTextures["up"], 
                _collapsingHeaderTextures["down"], 
                _collapsingHeaderTextures["over"],
                _collapsingHeaderTextures["disabled"]
            )
        else 
            element.button:SetTexture(_collapsingHeaderTextures["up-off"])
            element.button:SetNewTextures(
                _collapsingHeaderTextures["up-off"], 
                _collapsingHeaderTextures["down"], 
                _collapsingHeaderTextures["over"],
                _collapsingHeaderTextures["disabled"]
            )
        end

        element.button:ApplyTextures()
        element.changed = false 
    end 

    -- update internally
    self:UpdateOffset(element.height)
    self:Indent()

    -- show it
    element.used = true
    if element:IsHidden() then 
        element:Show()
    end

    -- return state
    return element.enabled
end

function mWindow:EndCollapsingHeader(identifier)

    -- todo: vertical bar?
    local element = self.tracker[identifier]

    self:Unindent()
end

--- Adds a slider for changing a float value.
-- @param identifier The identifier of this element.
-- @param label The name of this element displayed in the UI.
-- @param min The minimum value of the slider.
-- @param max The maximum value of the slider.
-- @param value The value of the slider.
function mWindow:SliderFloat(identifier, min, max, value)

    local element = self.tracker[identifier]
    if not element then 

        element = Group(self.main)
        element:DisableHitTest()

        -- prevents errors with regard to the size of the group
        LayoutHelpers.SetWidth(element, 10)
        LayoutHelpers.SetHeight(element, 10)

        -- create label UI element
        local color = 'ffffffff'
        local size = 12
        local outline = self.outline

        -- create label UI element
        local label = ToLabel(identifier) 
        element.label = UIUtil.CreateText(element, label, size, UIUtil.bodyFont)
        LayoutHelpers.AtLeftTopIn(element.label, element, self.outline + 180, 14)
        element.label:SetColor(color)

        -- create value UI element
        element.tValue = UIUtil.CreateText(element, tostring(value), size, UIUtil.bodyFont)
        LayoutHelpers.AtLeftTopIn(element.tValue, element, 10, 0)
        element.tValue:SetColor(color)

        -- the return value
        element.dValue = value

        -- create slider UI element
        local parent = element 
        local isVertical = false 
        local startValue = min
        local endValue = max
        local thumb = UIUtil.SkinnableFile('/slider02/slider_btn_up.dds')
        local thumbOver = UIUtil.SkinnableFile('/slider02/slider_btn_over.dds')
        local thumbDown = UIUtil.SkinnableFile('/slider02/slider_btn_down.dds')
        local background = UIUtil.SkinnableFile('/slider02/slider-back_bmp.dds')
        element.slider = Slider(element, isVertical, startValue, endValue, thumb, thumbOver, thumbDown, background)
        element.slider:SetValue(value)
        
        -- make it stick to the group
        LayoutHelpers.AtLeftTopIn(element.slider, element, 0, 14)

        -- slider functionality
        element.slider.OnBeginChange =
            function()
                element.update = false
            end

        element.slider.OnScrub = 
            function(self,value)
                element.dValue = value
                element.tValue:SetText(tostring(value))
            end

        element.slider.OnValueSet = 
            function(self, value) 
                element.dValue = value
                element.tValue:SetText(tostring(value))
            end

        element.slider.OnEndChange =
            function()
                element.update = true
            end

        -- add properties for internal state
        element.height = 40
        element.update = true
        element.identifier = identifier

        -- keep track of it
        self.tracker[identifier] = element
    end

    -- slider requires more space
    self:UpdateOffset(element.height - 38)

    -- position it
    LayoutHelpers.AtLeftTopIn(element, self.main, self.outline, self.offset)
    self:UpdateOffset(element.height - 2)

    -- update the value if it has changed
    if (element.dValue != value) and element.update then 
        element.dValue = value
        element.slider:SetValue(value)
        element.tValue:SetText(tostring(value))
    end

    -- show it
    element.used = true
    if element:IsHidden() then 
        element:Show()
    end

    return element.dValue
end

--- Adds a slider for changing a float value.
-- @param identifier The identifier of this element.
-- @param label The name of this element displayed in the UI.
-- @param min The minimum value of the slider.
-- @param max The maximum value of the slider.
-- @param value The value of the slider.
-- @param callbacks Called when the value is changing. Format is { OnScrub = function(value) }
function mWindow:SliderFloatCB(identifier, min, max, value, callbacks)

    -- todo: hefty copy of SliderFloat, not maintainable - fix!

    local element = self.tracker[identifier]
    if not element then 

        element = Group(self.main)
        element:DisableHitTest()

        -- prevents errors with regard to the size of the group
        LayoutHelpers.SetWidth(element, 10)
        LayoutHelpers.SetHeight(element, 10)

        -- create label UI element
        local color = 'ffffffff'
        local size = 12
        local outline = self.outline

        -- create label UI element
        local label = ToLabel(identifier) 
        element.label = UIUtil.CreateText(element, label, size, UIUtil.bodyFont)
        LayoutHelpers.AtLeftTopIn(element.label, element, self.outline + 180, 14)
        element.label:SetColor(color)

        -- create value UI element
        element.tValue = UIUtil.CreateText(element, tostring(value), size, UIUtil.bodyFont)
        LayoutHelpers.AtLeftTopIn(element.tValue, element, 10, 0)
        element.tValue:SetColor(color)

        -- the return value
        element.dValue = value

        -- create slider UI element
        local parent = element 
        local isVertical = false 
        local startValue = min
        local endValue = max
        local thumb = UIUtil.SkinnableFile('/slider02/slider_btn_up.dds')
        local thumbOver = UIUtil.SkinnableFile('/slider02/slider_btn_over.dds')
        local thumbDown = UIUtil.SkinnableFile('/slider02/slider_btn_down.dds')
        local background = UIUtil.SkinnableFile('/slider02/slider-back_bmp.dds')
        element.slider = Slider(element, isVertical, startValue, endValue, thumb, thumbOver, thumbDown, background)
        element.slider:SetValue(value)

        -- make it stick to the group
        LayoutHelpers.AtLeftTopIn(element.slider, element, 0, 14)

        -- slider functionality
        element.slider.OnBeginChange =
            function()
                element.update = false
            end

        element.slider.OnScrub = 
            function(self,value)
                element.dValue = value
                element.tValue:SetText(tostring(value))

                if callbacks.OnScrub then 
                    callbacks.OnScrub(value)
                end
            end

        element.slider.OnValueSet = 
            function(self, value) 
                element.dValue = value
                element.tValue:SetText(tostring(value))
            end

        element.slider.OnEndChange =
            function()
                element.update = true
            end

        -- add properties for internal state
        element.height = 40
        element.update = true
        element.identifier = identifier

        -- keep track of it
        self.tracker[identifier] = element
    end

    -- slider requires more space
    self:UpdateOffset(element.height - 38)

    -- position it
    LayoutHelpers.AtLeftTopIn(element, self.main, self.outline, self.offset)
    self:UpdateOffset(element.height - 2)

    -- update the value if it has changed
    if (element.dValue != value) and element.update then 
        element.dValue = value
        element.slider:SetValue(value)
        element.tValue:SetText(tostring(value))
    end

    -- show it
    element.used = true
    if element:IsHidden() then 
        element:Show()
    end

    return element.dValue

end

local RatioChartDividerWidth = 2

--- Adds in a ratio chart that will fill the entire width.
-- @param data The data for the ratio chart. Format is { { value = double, color = string }, ... }.
function mWindow:RatioChart(data)

    -- compute total value
    local total = 0
    local numberOfDividers = -1
    for k, entry in data do 
        total = total + entry.value

        if entry.value > 0 then 
            numberOfDividers = numberOfDividers + 1
        end
    end

    local width = self.main.Right() - self.main.Left() - 2 * self.outline - RatioChartDividerWidth * numberOfDividers

    -- no values set, default
    if total == 0 then 
        -- create a bitmap that stretches
        local bitmap = self:AllocateBitmap("ffffffff")

        -- position it
        LayoutHelpers.AtLeftTopIn(bitmap, self.main, self.outline, self.offset)

        -- scale it
        bitmap.Left:Set( function() return self.main.Left() + self.outline end )
        bitmap.Right:Set( function() return self.main.Right() - self.outline end )
        bitmap.Height:Set(5)
    else 
        -- position the bitmaps that make up the chart
        local bitmapPrev = false
        for k, entry in data do 
            if entry.value > 0 then 
                local bitmap = self:AllocateBitmap(entry.color)

                -- determine bitmap location
                -- fine-tune bitmap location

                if bitmapPrev then 
                    -- lock to previous bitmap
                    LayoutHelpers.RightOf(bitmap, bitmapPrev, RatioChartDividerWidth)

                    -- add small black divider
                    local divider = self:AllocateBitmap("ff000000")
                    LayoutHelpers.RightOf(divider, bitmapPrev, 0)
                    divider.Right:Set(function() return bitmap.Left() end)
                    divider.Height:Set(5)
                else 
                    -- lock to main window
                    LayoutHelpers.AtLeftTopIn(bitmap, self.main, self.outline, self.offset)
                end

                -- determine width (todo: make this more dynamic?)
                local bitmapWidth = (entry.value / total) * width
                bitmap.Right:Set(function() return bitmap.Left() + bitmapWidth end)
                bitmap.Height:Set(5)

                -- keep track of internal state
                bitmapPrev = bitmap
            end
        end
    end

    -- update internal state
    self:UpdateOffset(7)
end

--- Adds a horizontal divider.
function mWindow:Divider()
    -- allocate one
    local element = self:AllocateDivider()

    -- position it
    local outline = self.outline 
    local rightOutline = self.rightOutline 
    LayoutHelpers.AtLeftTopIn(element, self.main, self.outline, self.offset)

    -- update internal state
    self:UpdateOffset(0)
end

-- look up table for textures
local _tabBarTextures = { }
_tabBarTextures["up"] = "/lua/ui/imgui//textures/tab-bar-dds/default-up.dds"
_tabBarTextures["up-off"] = "/lua/ui/imgui//textures/tab-bar-dds/default-up-off.dds"
_tabBarTextures["down"] = "/lua/ui/imgui//textures/tab-bar-dds/default-down.dds"
_tabBarTextures["over"] = "/lua/ui/imgui//textures/tab-bar-dds/default-over.dds"
_tabBarTextures["disabled"] = "/lua/ui/imgui//textures/tab-bar-dds/default-down.dds"

--- Adds a tab bar.
-- @param identifier The identifier of this element.
-- @param tabs The identifiers of the tabs of the tab bar.
function mWindow:BeginTabBar(identifier, tabIdentifiers)

    local element = self.tracker[identifier]
    if not element then 

        -- generic group element
        element = Group(self.main)
        element:DisableHitTest()  

        -- prevents errors with regard to the size of the group
        LayoutHelpers.SetWidth(element, 10)
        LayoutHelpers.SetHeight(element, 10)

        -- choose a tab to enable
        element.chooseTab = function (identifier)
            -- disable all tabs
            for k, tab in element.tabs do 
                tab.enabled = false 
                tab.changed = true 
            end

            -- enable tab
            element.tabs[identifier].enabled = true
        end

        -- factor to determine the amount of space for each tab
        local factor = 1 / table.getn(tabIdentifiers)
        local width = self.main.Right() - self.main.Left() - 2 * self.outline

        -- the tabs available in this tab bar, populated down below
        element.tabs = { }

        -- for each tab identifier provided
        for k, tabIdentifier in tabIdentifiers do 

            local tab = self.tracker[tabIdentifier]
            if not tab then 
        
                -- generic group tab
                tab = Group(self.main)
                tab:DisableHitTest()
        
                -- prevents errors with regard to the size of the group
                LayoutHelpers.SetWidth(tab, 10)
                LayoutHelpers.SetHeight(tab, 10)
        
                -- create the button tab
                local parent = tab 
                local normal = _tabBarTextures["up"]
                local active = _tabBarTextures["down"]
                local highlight = _tabBarTextures["over"]
                local disabled = _tabBarTextures["disabled"]
                local clickCue = "UI_Opt_Yes_No"
                local rolloverCue = "UI_Opt_Affirm_Over"
                tab.button = Button(parent, normal, active, highlight, disabled, clickCue, rolloverCue)
                LayoutHelpers.AtLeftTopIn(tab.button, tab, 0, 0)
                tab.button.Left:Set( function() return self.main.Left() + self.outline end )
                tab.button.Right:Set( function() return self.main.Left() + self.outline + 135 end )
                tab.button.Height:Set(24)
                tab.button.Depth:Set(2000)
        
                -- toggles the tab
                tab.button.OnClick = function(self, modifiers)
                    element.chooseTab(tab.identifier)
                end
        
                -- create the text tab
                local size = 12
                local color = "ffffffff"
                tab.text = UIUtil.CreateText(element, tabIdentifier, size, UIUtil.bodyFont)
                LayoutHelpers.AtVerticalCenterIn(tab.text, tab.button)
                LayoutHelpers.AtLeftIn(tab.text, tab.button, 10)
                tab.text:SetColor(color)
                tab.text.Depth:Set(2001)
                tab.text:DisableHitTest()
        
                -- add properties
                tab.changed = false
                tab.enabled = false 
                tab.identifier = tabIdentifier
                tab.index = k
        
                -- keep track of it
                self.tracker[tabIdentifier] = tab
                element.tabs[tabIdentifier] = tab
            end
        
            -- position it
            -- todo
            LayoutHelpers.AtLeftTopIn(tab, self.main, self.outline - 10, self.offset)
            tab.button.Left:Set( function() return self.main.Left() + 10 +self.outline + (tab.index - 1) * (factor * width) end )
            tab.button.Right:Set( function() return self.main.Left() + self.outline + tab.index * (factor * width) - 10 end )

            -- update the button if applicable
            if tab.changed then 
                if tab.enabled then 
                    tab.button:SetTexture(_tabBarTextures["up"])
                    tab.button:SetNewTextures(
                        _tabBarTextures["up"], 
                        _tabBarTextures["down"], 
                        _tabBarTextures["over"],
                        _tabBarTextures["disabled"]
                    )
                else 
                    tab.button:SetTexture(_tabBarTextures["up-off"])
                    tab.button:SetNewTextures(
                        _tabBarTextures["up-off"], 
                        _tabBarTextures["down"], 
                        _tabBarTextures["over"],
                        _tabBarTextures["disabled"]
                    )
                end
        
                tab.button:ApplyTextures()
                tab.changed = false 
            end 
        
            -- show it
            tab.used = true
            if tab:IsHidden() then 
                tab:Show()
            end
        end

        element.height = 30
    end

    -- update internal state
    self:UpdateOffset(element.height)
end

--- Ends a tab bar.
-- @param identifier The identifier of this element. This should match with the identifier used in mWindow:BeginTabBar.
function mWindow:EndTabBar(identifier)
    self:Unindent()

    -- ??
    self:UpdateOffset(10)
end

--- Adds a tab bar.
-- @param identifier The identifier of this element. This should match with a tab used in mWindow:BeginTabBar.
function mWindow:BeginTab(identifier)
    local tab = self.tracker[identifier]
    if not tab then 
        WARN("Unknown tab: " .. identifier)
    end

    return tab.enabled
end

--- Constructs a progress bar.
function mWindow:ProgressBar(identifier, current, max)

    if self:HasSufficientSpace(10) then 
        local background = self:AllocateBitmap("ff000000")
        LayoutHelpers.AtLeftTopIn(background, self.main, self.outline, self.offset + 3)

        local progress = self:AllocateBitmap("ffffffff")
        LayoutHelpers.AtLeftTopIn(progress, self.main, self.outline, self.offset + 3)
        progress.Right:Set(function() return background.Left() + math.clamp(current / max, 0.0, 1.0) * (background.Right() - background.Left()) end )
    end

    self:UpdateOffset(10)
end

--- A utility function. Draws a rectangle.
function mWindow:DrawRectangle(x, y, width, height, color, solid)

    if solid then 

        local px = math.ceil(x)
        local py = math.ceil(y)
        local pw = math.ceil(width)
        local ph = math.ceil(height)

        local bitmap = self:AllocateBitmap(color)
        LayoutHelpers.AtLeftTopIn(bitmap, self.main, self.outline + px, self.offset + py)
        bitmap.Right:Set(function() return bitmap.Left() + pw end)
        bitmap.Bottom:Set(function() return bitmap.Top() + ph end)
    else 
        self:DrawRectangle(x, y, width, 1, color, true)
        self:DrawRectangle(x, y, 1, height, color, true)
        self:DrawRectangle(x + width, y + height, -1 * width, 1, color, true)
        self:DrawRectangle(x + width, y + height, 1, -1 * height, color, true)
    end

end

--- Adds an additional render target similar to the minimap. Sadly - it bugs out for now as the depth buffer of the GPU is not reset.
-- @param identifier The identifier of this element.
-- @param width The width of the render target.
-- @param height The height of the render target.
-- @param settings The camera settings to use for the render target.
function mWindow:RenderTarget(identifier, width, height, settings)

    local element = self.tracker[identifier]
    if not element then 
        element = import('/lua/ui/controls/worldview.lua').WorldView(self.main, identifier, 0, false, identifier)    -- depth value is above minimap
        element:SetName(identifier)
        element:Register(identifier, nil, identifier, 3)
        element:SetCartographic(true)
        element:SetRenderPass(UIUtil.UIRP_UnderWorld + UIUtil.UIRP_PostGlow) -- don't change this or the camera will lag one frame behind
        element.Depth:Set(2)
        element:SetNeedsFrameUpdate(true)
        element:EnableResourceRendering(true)

        local frameCount = 0
        element.OnFrame = function(self, elapsedTime)

                element:CameraReset()
                GetCamera(element._cameraName):SetMaxZoomMult(1.0)
                -- element.OnFrame = nil  -- we want the control to continue to get frame updates in the engine, but not in Lua. PLEASE DON'T CHANGE THIS OR IT BREAKS CAMERA DRAGGING
            frameCount = frameCount + 1
        end

        self.tracker[identifier] = element
    end

    -- position it
    LayoutHelpers.AtLeftTopIn(element, self.main, self.outline, self.offset )
    LayoutHelpers.SetWidth(element, width)
    LayoutHelpers.SetHeight(element, height)

    -- show it
    element.used = true
    if element:IsHidden() then 
        element:Show()
    end

    self:UpdateOffset(height)
end

function mWindow:MapPreview(identifier, map, shapes, width, height)

    local element = self.tracker[identifier]
    if not element then 
        element = MapPreview(self.main)
        element:SetTextureFromMap(map)
        self.tracker[identifier] = element
    end

    -- defaults, assume square map
    width = width or (self.main.Right() - self.main.Left()) - self.outline - self.rightOutline
    height = height or width

    -- position it
    LayoutHelpers.AtLeftTopIn(element, self.main, self.outline, self.offset )
    LayoutHelpers.SetWidth(element, width)
    LayoutHelpers.SetHeight(element, height)

    -- draw out shapes
    for k, shape in shapes do 
        local sx = shape.X * width 
        local sy = shape.Y * height
        local sw = shape.Width * width 
        local sh = shape.Height * height 
        local sc = shape.Color 
        local ss = shape.Solid
        self:DrawRectangle(sx, sy, sw, sh, sc, ss)
    end

    -- show it
    element.used = true
    if element:IsHidden() then 
        element:Show()
    end

    self:UpdateOffset(height)
end

--- Adds a texture. If the path to the texture is invalid (e.g., it is not there) a text element is placed instead.
-- @param identifier The identifier of this element.
-- @param path The path to the texture.
-- @param width The width of this element.
function mWindow:Texture(identifier, path, width)
    local element = self.tracker[identifier]
    if not element then 

        -- check if the texture exists
        if DiskGetFileInfo(path) then 

            -- generic group element
            element = Bitmap(self.main)
            element:SetTexture(path)

            -- find width / height of texture
            local dwidth, dheight = GetTextureDimensions(path)
            local factor = width / dwidth 
            local height = factor * dheight 

            -- scale the bitmap
            element.Width:Set(width)
            element.Height:Set(height)

            -- add properties
            element.height = height

        -- if it doesn't exist then do with a text element
        else 
            element = Text(self.main, "Invalid path to texture", 12, UIUtil.bodyFont)
            element.height = 12
        end

        -- keep track of it
        self.tracker[identifier] = element
    end

    if self:HasSufficientSpace(element.height) then 

        -- position it
        LayoutHelpers.AtLeftTopIn(element, self.main, self.outline, self.offset)

        -- show it
        element.used = true
        if element:IsHidden() then 
            element:Show()
        end

    end

    -- update internally
    self:UpdateOffset(element.height)

end

--- Constructs a histogram using the Moho API. Sadly - this doesn't produce any results.
-- @param identifier The identifier of this element.
-- @param width The width of this element.
-- @param height The height of this element.
function mWindow:Histogram(identifier, width, height)

    self:Text("Histogram is not supported.", 12)

    -- local element = self.tracker[identifier]
    -- if not element then 

    --     element = Group(self.main)
    --     element:DisableHitTest()

    --     -- prevents errors with regard to the size of the group
    --     LayoutHelpers.SetWidth(element, width)
    --     LayoutHelpers.SetHeight(element, height)

    --     element.histogram = Histogram(element)
        
    --     LayoutHelpers.FillParent(element.histogram, element)
    --     element.histogram:SetXIncrement(1)
    --     element.histogram:SetYIncrement(1)

            -- local data = { }
            -- data[1] = { color = "ffffff", data = {10, 20, 50, 60} }
            -- data[2] = { color = "00ffff", data = {0, 40, 20, 30} }

    --     element.histogram:SetData(data)

    --     self.tracker[identifier] = element
    -- end

    -- LayoutHelpers.AtLeftTopIn(element, self.main, self.outline, self.offset )

    -- -- show it
    -- element.used = true
    -- if element:IsHidden() then 
    --     element:Show()
    -- end

    -- self:UpdateOffset(height)

    -- return element.histogram
end

function mWindow:UpdateOffset(size)
    self.offset = self.offset + size + 2
end

function mWindow:UpdateRightOffset(size)
    self.rightOutline = self.rightOutline + size
end

--- Indents all elements added after this element.
function mWindow:Indent()
    self.outline = self.outline + 5
end

--- Unindents all elements added after this element.
function mWindow:Unindent()
    self.outline = math.max(self.oOutline, self.outline - 5)
end 

--- Adds a bit of vertical space.
-- @param size Amount of space to allocate. Optional, defaults to 12.
function mWindow:Space(size)
    size = size or 12
    self:UpdateOffset(size)
end

--- Checks whether the element has sufficient space in the window to be placed
function mWindow:HasSufficientSpace(height)
    return (self.minOffset <= self.offset) and (self.maxOffset >= self.offset + height)
end