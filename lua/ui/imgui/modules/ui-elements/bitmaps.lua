
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

--- Called when the window is made.
function OnConstruct(window)
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
    for k = 1, window.textElementCount - 1 do 
        elements[k].used = false
    end

    -- start using at the start of the cache
    window.textElementIndex = 1
end

--- Called when the window is done rendering.
function OnEnd(window)
    
    -- hide unused text elements
    local elements = window.textElements
    for k = 1, window.textElementCount - 1 do 
        local element = elements[k]
        if not element.used then 
            element:Hide()
        end
    end

end


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