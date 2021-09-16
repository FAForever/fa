

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

local Bitmap = import('/lua/maui/bitmap.lua').Bitmap

--- Called when the window is made.
function OnConstruct(window)
    -- keeps track of anonymous text
    window.dividerElementIndex = 1
    window.dividerElementCount = 1
    window.dividerElements = { }
end

--- Called when the window is preparing for rendering.
function OnBegin(window)

    -- Set all previously used to unused
    local elements = window.dividerElements
    for k = 1, window.dividerElementCount - 1 do 
        elements[k].used = false
    end

    -- start using at the start of the cache
    window.dividerElementIndex = 1

end

--- Called when the window is done rendering.
function OnEnd(window)
    
    -- hide unused text elements
    local elements = window.dividerElements
    for k = 1, window.dividerElementCount - 1 do 
        local element = elements[k]
        if not element.used then 
            element:Hide()
        end
    end

end

--- Retrieves a divider element. Returns a cached element if possible, allocates a 
-- new one if no cached element is available.
function AllocateDivider(window)
    -- check if one is free
    local element = window.dividerElements[window.dividerElementIndex]
    if not element then 

        -- create the bitmap
        element = Bitmap(window.main)
        element:SetSolidColor('dddddddd')

        -- keep track of it
        window.dividerElements[window.dividerElementIndex] = element
        window.dividerElementCount = window.dividerElementCount + 1
    end

    -- check if we fit
    if window:HasSufficientSpace(2) then 
        -- keep track that it is used
        element.used = true

        -- check if the element was previously hidden
        if element:IsHidden() then 
            element:Show()
        end

        -- scale it
        local outline = window.outline 
        local rightOutline = window.rightOutline
        element.Left:Set( function() return window.main.Left() + outline end )
        element.Right:Set( function() return window.main.Right() - rightOutline end )
        element.Height:Set(1)

        -- update index that represents what text element we've used so far
        window.dividerElementIndex = window.dividerElementIndex + 1
    end

    return element
end

--- Adds a horizontal divider.
function Divider(window)
    -- allocate one
    local element = window:AllocateDivider()

    -- position it
    local outline = window.outline 
    local rightOutline = window.rightOutline 
    LayoutHelpers.AtLeftTopIn(element, window.main, window.outline, window.offset)

    -- update internal state
    window:UpdateOffset(2)
end