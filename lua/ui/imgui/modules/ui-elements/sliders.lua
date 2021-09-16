
local UIUtil = import('/lua/ui/uiutil.lua')
local Group = import('/lua/maui/group.lua').Group
local Slider = import('/lua/maui/slider.lua').Slider
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

-- utility files
local Conversion = import('/lua/ui/imgui//modules/conversion.lua')
local ToLabel = Conversion.ToLabel

-- upvalue for performance
local tostring = tostring 

--- Adds a slider for changing a float value.
-- @param identifier The identifier of this element.
-- @param label The name of this element displayed in the UI.
-- @param min The minimum value of the slider.
-- @param max The maximum value of the slider.
-- @param value The value of the slider.
function SliderFloat(window, identifier, min, max, value)

    local element = window.tracker[identifier]
    if not element then 

        element = Group(window.main)
        element:DisableHitTest()

        -- prevents errors with regard to the size of the group
        LayoutHelpers.SetWidth(element, 10)
        LayoutHelpers.SetHeight(element, 10)

        -- create label UI element
        local color = 'ffffffff'
        local size = 12
        local outline = window.outline

        -- create label UI element
        local label = ToLabel(identifier) 
        element.label = UIUtil.CreateText(element, label, size, UIUtil.bodyFont)
        LayoutHelpers.AtLeftTopIn(element.label, element, window.outline + 180, 14)
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
            function(window,value)
                element.dValue = value
                element.tValue:SetText(tostring(value))
            end

        element.slider.OnValueSet = 
            function(window, value) 
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
        window.tracker[identifier] = element
    end

    -- slider requires more space
    window:UpdateOffset(element.height - 38)

    -- position it
    LayoutHelpers.AtLeftTopIn(element, window.main, window.outline, window.offset)
    window:UpdateOffset(element.height - 2)

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
function SliderFloatCB(window, identifier, min, max, value, callbacks)

    -- todo: hefty copy of SliderFloat, not maintainable - fix!

    local element = window.tracker[identifier]
    if not element then 

        element = Group(window.main)
        element:DisableHitTest()

        -- prevents errors with regard to the size of the group
        LayoutHelpers.SetWidth(element, 10)
        LayoutHelpers.SetHeight(element, 10)

        -- create label UI element
        local color = 'ffffffff'
        local size = 12
        local outline = window.outline

        -- create label UI element
        local label = ToLabel(identifier) 
        element.label = UIUtil.CreateText(element, label, size, UIUtil.bodyFont)
        LayoutHelpers.AtLeftTopIn(element.label, element, window.outline + 180, 14)
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
            function(window,value)
                element.dValue = value
                element.tValue:SetText(tostring(value))

                if callbacks.OnScrub then 
                    callbacks.OnScrub(value)
                end
            end

        element.slider.OnValueSet = 
            function(window, value) 
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
        window.tracker[identifier] = element
    end

    -- slider requires more space
    window:UpdateOffset(element.height - 38)

    -- position it
    LayoutHelpers.AtLeftTopIn(element, window.main, window.outline, window.offset)
    window:UpdateOffset(element.height - 2)

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