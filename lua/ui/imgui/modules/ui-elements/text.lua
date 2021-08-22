
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

--- Called when the window is made.
function OnCreate(window)
    -- keeps track of anonymous text
    window.textElementIndex = 1
    window.textElementCount = 1
    window.textElements = { }
    window.textColor = "ffffffff"
end

--- Called when the window is preparing for rendering.
function OnBegin(window)

    -- Set all previously used to unused
    local elements = window.textElements
    for k = 1, textElementIndex - 1 do 
        elements[k].used = false
    end

    -- start using at the start of the cache
    window.textElementIndex = 1

end

--- Called when the window is done rendering.
function OnEnd(window)
    
    -- hide unused text elements
    local elements = window.textElements
    for k = 1, count do 
        local element = elements[k]
        if not element.used then 
            element:Hide()
        end
    end

end

--- Retrieves a text element. Returns a cached element if possible, allocates a 
-- new one if no cached element is available.
function AllocateText(window)

    -- check if one is free
    local element = window.textElements[window.textElementIndex]
    if not element then 
        -- allocate it
        element = UIUtil.CreateText(window.main, "Placeholder", 12, UIUtil.bodyFont)
        LayoutHelpers.DepthOverParent(element, window.main, 2)
    
        -- keep track of it
        table.insert(window.textElements, element)
    end

    -- keep track that it is used
    element.used = true

    -- check if the element was previously hidden
    if element:IsHidden() then 
        element:Show()
    end

    -- update index that represents what text element we've used so far
    window.textElementIndex = window.textElementIndex + 1 

    return element
end

--- Adds a text entry.
-- @param identifier The identifier of this element.
-- @param value The text of this element.
function CreateText(window, value)

    if window:HasSufficientSpace(12) then 

        -- retrieve a text element
        local element = window:AllocateText()

        -- update text content
        element:SetText(value)
        element:SetColor(window.textColor)

        -- position it
        LayoutHelpers.AtLeftTopIn(element, window.main, window.outline, window.offset)

    end

    -- update internal state
    window:UpdateOffset(12 + 1)
end

--- Sets the text color of the upcoming text element. Initial value is 'ffffffff'.
-- @param color The color to set the text to.
function SetTextColor(window, color)
    window.textColor = color
end

--- Adds two text entries, as if they are two columns.
-- @param left The left text value.
-- @param right The right text value.
-- @param size The size of the text.
-- @param perc The percentage (in width) when the right column starts
function TextWithLabel(window, label, value, perc)
    -- check if we fit
    if window:HasSufficientSpace(12) then 
        -- scope them so that they can be uplifted
        local outline = window.outline
        local oOutline = window.oOutline 
        local rightOutline = window.rightOutline
        local offset = window.offset

        do 
            -- retrieve a text element
            local element = window:AllocateText()

            -- update text content
            element:SetColor(window.textColor)
            element:SetText(label)

            -- position it
            element.Top:Set(function() return window.main.Top() + offset end )
            element.Left:Set(function() return window.main.Left() + outline end)
            element.height = 12
        end

        do 
            -- retrieve a text element
            local element = window:AllocateText()

            -- update text content
            element:SetColor("ffffffff")
            element:SetText(value)

            -- position it
            element.Top:Set(function() return window.main.Top() + offset end )
            element.Left:Set(function() return window.main.Left() + outline + math.floor(perc * (window.main.Right() - window.main.Left() - rightOutline )) - rightOutline end)
            element.height = 12
        end
    end

    -- update internal state
    window:UpdateOffset(12)
end