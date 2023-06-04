--*****************************************************************************
--* File: lua/modules/maui/layouthelpers.lua
--* Author: Chris Blackwell
--* Summary: functions that make it simpler to set up control layouts.
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

-- Percentage versus offset:
--
-- Percentages are specified as a float, with 0.00 to 1.00 as the normal ranges
-- Percentages can change spacing when dimension is expanded.
--
-- Offsets are specified in pixels for the "base art" size. If the UI is
-- scaled (e.g. large UI mode) the pixel scale factor will keep the layout correct.


local iscallable = iscallable
local GetTextureDimensions = GetTextureDimensions
local MathFloor = math.floor
local MathCeil = math.ceil



------------------------------
-- UI Scaling
------------------------------

-- Store and set the current pixel scale multiplier. This will be used when the
-- artwork is scaled up or down so that offsets scale up and down appropriately.
-- Note that if you add a new layout helper function that uses offsets, you need
-- to scale the offset with this factor or your layout may get funky when the
-- art is changed
---@type number
local pixelScaleFactor = import("/lua/user/prefs.lua").GetFromCurrentProfile("options").ui_scale or 1


----------
-- Scale manipulation functions
----------

--- Sets new pixel scale factor for fixed offset in layout functions
---@param newFactor number
function SetPixelScaleFactor(newFactor)
    pixelScaleFactor = newFactor
end

--- Gets pixel scale factor for fixed offset in layout functions
---@return number pixelScaleFactor
function GetPixelScaleFactor()
    return pixelScaleFactor
end

--- Scales a number by the pixel scale factor
---@param number number
---@return number scaledNumber
function ScaleNumber(number)
    return MathFloor(number * pixelScaleFactor)
end

--- Unscales a number by the pixel scale factor
---@param scaledNumber number
---@return number number
function InvScaleNumber(scaledNumber)
    return MathCeil(scaledNumber / pixelScaleFactor)
end


----------
-- Dimensional functions
----------

--- Sets fixed width of a control, scaled by the pixel scale factor
---@param control Control
---@param width? LazyVar | number change if nil
function SetWidth(control, width)
    if width then
        if type(width) == 'number' then
            control.Width:SetValue(MathFloor(width * pixelScaleFactor))
        else
            control.Width:Set(width)
        end
    end
end

--- Sets fixed height of a control, scaled by the pixel scale factor
---@param control Control
---@param height? LazyVar | number no change if nil
function SetHeight(control, height)
    if height then
        if type(height) == 'number' then
            control.Height:SetValue(MathFloor(height * pixelScaleFactor))
        else
            control.Height:Set(height)
        end
    end
end

--- Sets fixed dimensions of a control, scaled by the pixel scale factor
---@param control Control
---@param width? LazyVar | number no change if nil
---@param height? LazyVar | number no change if nil
function SetDimensions(control, width, height)
    SetWidth(control, width)
    SetHeight(control, height)
end

--- Scales a control's dimensions by the pixel scale factor
---@param control Control
function Scale(control)
    SetDimensions(control, control.Width(), control.Height())
end


----------
-- Texture functions
----------

--- Sets a control's height to the height of a texture (with optional padding)
---@param control Control
---@param filename Lazy<FileName>
---@param padding? number
function SetHeightFromTexture(control, filename, padding)
    if iscallable(filename) then -- skinnable file
        control.Height:SetFunction(function()
            local _, height = GetTextureDimensions(filename())
            if padding then
                return height + ScaleNumber(padding)
            end
            return MathFloor(height)
        end)
    else -- UI file
        local _, height = GetTextureDimensions(filename)
        if padding then
            height = height + ScaleNumber(padding)
        end
        control.Height:SetValue(MathFloor(height))
    end
end

--- Sets a control's width to the width of a texture (with optional padding)
---@param control Control
---@param filename Lazy<FileName>
---@param padding? number defaults to 0, not 1
function SetWidthFromTexture(control, filename, padding)
    if iscallable(filename) then -- skinnable file
        control.Width:SetFunction(function()
            local width = GetTextureDimensions(filename())
            if padding then
                return width + ScaleNumber(padding)
            end
            return MathFloor(width)
        end)
    else -- UI file
        local width = GetTextureDimensions(filename)
        if padding then
            width = width + ScaleNumber(padding)
        end
        control.Width:SetValue(MathFloor(width))
    end
end

--- Set a control's dimensions to the dimensions of a texture (with an optional border)
---@param control Control
---@param filename Lazy<FileName>
---@param border? number defaults to 0, not 1
function SetDimensionsFromTexture(control, filename, border)
    if iscallable(filename) then -- skinnable file
        control.Width:SetFunction(function()
            local width = GetTextureDimensions(filename())
            if border then
                return width + ScaleNumber(border)
            end
            return width
        end)
        control.Height:SetFunction(function()
            local _, height = GetTextureDimensions(filename())
            if border then
                return height + ScaleNumber(border)
            end
            return height
        end)
    else -- UI file
        local width, height = GetTextureDimensions(filename)
        if border then
            border = ScaleNumber(border)
            width = width + border
            height = height + border
        end
        control.Width:SetValue(width)
        control.Height:SetValue(height)
    end
end


----------
-- Depth functions
----------

--- Sets depth of a control to be above a parent
---@param control Control
---@param parent Control
---@param depth? integer defaults to 1
function DepthOverParent(control, parent, depth)
    if depth and depth ~= 1 then
        control.Depth:SetFunction(function() return parent.Depth() + depth end)
    else
        control.Depth:SetFunction(function() return parent.Depth() + 1 end)
    end
end

--- Sets depth of a control to be below a parent
---@param control Control
---@param parent Control
---@param depth? integer defaults to 1
function DepthUnderParent(control, parent, depth)
    if depth and depth ~= 1 then
        control.Depth:SetFunction(function() return parent.Depth() - depth end)
    else
        control.Depth:SetFunction(function() return parent.Depth() - 1 end)
    end
end



------------------------------
-- Single positioning functions
------------------------------

-- These function set only one layout property of the six a control has

----------
-- Reset functions
----------

--- Resets a control's left edge to be calculated from its right edge and width.  
--- Make sure `control.Right` and `control.Width` are not reset.
---@param control Control
function ResetLeft(control)
    control.Left:SetFunction(function() return control.Right() - control.Width() end)
end

--- Resets a control's top edge to be calculated from its bottom edge and height.  
--- Make sure `control.Bottom` and `control.Height` are not reset.
---@param control Control
function ResetTop(control)
    control.Top:SetFunction(function() return control.Bottom() - control.Height() end)
end

--- Resets a control's right edge to be calculated from its left edge and width.  
--- Make sure `control.Left` and `control.Width` are not reset.
---@param control Control
function ResetRight(control)
    control.Right:SetFunction(function() return control.Left() + control.Width() end)
end

--- Resets a control's bottom edge to be calculated from its top edge and height.  
--- Make sure `control.Top` and `control.Height` are not reset.
---@param control Control
function ResetBottom(control)
    control.Bottom:SetFunction(function() return control.Top() + control.Height() end)
end

--- Resets a control's width to be calculated from its left and right edges.  
--- Make sure `control.Left` and `control.Right` are not reset.
---@param control Control
function ResetWidth(control)
    control.Width:SetFunction(function() return control.Right() - control.Left() end)
end

--- Resets a control's height to be calculated from its top and bottom edges.  
--- Make sure `control.Top` and `control.Bottom` are not reset.
---@param control Control
function ResetHeight(control)
    control.Height:SetFunction(function() return control.Bottom() - control.Top() end)
end


----------
-- Anchor functions lock the appropriate edge of a control to the edge of another control
----------

--- Anchors a control's right edge to the left edge of a parent, with optional padding
---@param control Control
---@param parent Control
---@param padding? number fixed padding between control and parent, scaled by the pixel scale factor
function AnchorToLeft(control, parent, padding)
    if padding and padding ~= 0 then
        control.Right:SetFunction(function() return MathFloor(parent.Left() - padding * pixelScaleFactor) end)
    else
        -- We shouldn't need to let the child refer to the parent if the parent is already laid out
        -- however, this does change functionallity of the layout, so I've had to refrain
        --control.Right:SetFunction(parent.Left)
        control.Right:SetFunction(function() return parent.Left() end)
    end
end

--- Anchors a control's bottom edge to the top edge of a parent, with optional padding
---@param control Control
---@param parent Control
---@param padding? number fixed padding between control and parent, scaled by the pixel scale factor
function AnchorToTop(control, parent, padding)
    if padding and padding ~= 0 then
        control.Bottom:SetFunction(function() return MathFloor(parent.Top() - padding * pixelScaleFactor) end)
    else
        control.Bottom:SetFunction(function() return parent.Top() end)
    end
end

--- Anchors a control's left edge to the right edge of a parent, with optional padding
---@param control Control
---@param parent Control
---@param padding? number fixed padding between control and parent, scaled by the pixel scale factor
function AnchorToRight(control, parent, padding)
    if padding and padding ~= 0 then
        control.Left:SetFunction(function() return MathFloor(parent.Right() + padding * pixelScaleFactor) end)
    else
        control.Left:SetFunction(function() return parent.Right() end)
    end
end

--- Anchors a control's top edge to the bottom edge of a parent, with optional padding
---@param control Control
---@param parent Control
---@param padding? number fixed padding between control and parent, scaled by the pixel scale factor
function AnchorToBottom(control, parent, padding)
    if padding and padding ~= 0 then
        control.Top:SetFunction(function() return MathFloor(parent.Bottom() + padding * pixelScaleFactor) end)
    else
        control.Top:SetFunction(function() return parent.Bottom() end)
    end
end


----------
-- Inside offset functions
----------

-- These functions will set the control's position to be placed relative to its parent's dimensions.
-- Note that the offset is in the opposite direction as placement, to position
-- the controls further inside the parent.

-- These are generally most useful for elements that don't change size, though they can also be
-- used for controls that stretch to match parent.

--- Centers a control horizontally on a parent, with optional rightward offset.
--- This sets the control's left edge.
---@param control Control
---@param parent Control
---@param leftOffset? number Offset of control's left edge in the rightward direction, scaled by the pixel scale factor. Defaults to 0.
function AtHorizontalCenterIn(control, parent, leftOffset)
    if leftOffset then
        control.Left:SetFunction(function()
            return MathFloor(parent.Left() + (parent.Width() - control.Width()) * 0.5 + leftOffset * pixelScaleFactor)
        end)
    else
        control.Left:SetFunction(function()
            return MathFloor(parent.Left() + (parent.Width() - control.Width()) * 0.5)
        end)
    end
end

--- Centers a control vertically on a parent, with optional downward offset.
--- This sets the control's top edge.
---@param control Control
---@param parent Control
---@param topOffset? number Offset of the control's top edge in the downward direction, scaled by the pixel scale factor. Defaults to 0.
function AtVerticalCenterIn(control, parent, topOffset)
    if topOffset then
        control.Top:SetFunction(function()
            return MathFloor(parent.Top() + (parent.Height() - control.Height()) * 0.5 + topOffset * pixelScaleFactor)
        end)
    else
        control.Top:SetFunction(function()
            return MathFloor(parent.Top() + (parent.Height() - control.Height()) * 0.5)
        end)
    end
end

--- Places a control's left edge inside of a parent's, with optional rightward offset
---@param control Control
---@param parent Control
---@param leftOffset? number Offset of the control's left edge in the rightward direction, scaled by the pixel scale factor. Defaults to 0.
function AtLeftIn(control, parent, leftOffset)
    if leftOffset and leftOffset ~= 0 then
        control.Left:SetFunction(function()
            return MathFloor(parent.Left() + leftOffset * pixelScaleFactor)
        end)
    else
        control.Left:SetFunction(function() return parent.Left() end)
    end
end

--- Places a control's top edge inside of a parent's, with optional downward offset
---@param control Control
---@param parent Control
---@param topOffset? number Offset of the control's top edge in the downward direction, scaled by the pixel scale factor. Defaults to 0.
function AtTopIn(control, parent, topOffset)
    if topOffset and topOffset ~= 0 then
        control.Top:SetFunction(function()
            return MathFloor(parent.Top() + topOffset * pixelScaleFactor)
        end)
    else
        control.Top:SetFunction(function() return parent.Top() end)
    end
end

--- Places a control's right edge inside of a parent's, with optional leftward offset
---@param control Control
---@param parent Control
---@param rightOffset? number Offset of the control's right edge in the leftward direction, scaled by the pixel scale factor. Defaults to 0.
function AtRightIn(control, parent, rightOffset)
    if rightOffset and rightOffset ~= 0 then
        control.Right:SetFunction(function()
            return MathFloor(parent.Right() - rightOffset * pixelScaleFactor)
        end)
    else
        control.Right:SetFunction(function() return parent.Right() end)
    end
end

--- Places a control's bottom edge inside of a parent's, with optional upward offset
---@param control Control
---@param parent Control
---@param bottomOffset? number Offset of the control's bottom edge in the upward direction, scaled by the pixel scale factor. Defaults to 0.
function AtBottomIn(control, parent, bottomOffset)
    if bottomOffset and bottomOffset ~= 0 then
        control.Bottom:SetFunction(function()
            return MathFloor(parent.Bottom() - bottomOffset * pixelScaleFactor)
        end)
    else
        control.Bottom:SetFunction(function() return parent.Bottom() end)
    end
end


----------
-- Inside percentage functions
----------

-- These functions use percentages to place the item rather than offsets so they will
-- stay proportially spaced when the parent resizes

--- Places the control's left edge at a percentage along the width of a parent,
--- with 0.00 at the parent's left edge
---@param control Control
---@param parent Control
---@param leftPercent? number defaults to 0.00 (all the way to left)
function FromLeftIn(control, parent, leftPercent)
    if leftPercent and leftPercent ~= 0 then
        control.Left:SetFunction(function()
            return MathFloor(parent.Left() + leftPercent * parent.Width())
        end)
    else
        AtLeftIn(control, parent)
    end
end

--- Places the control's top edge at a percentage along the height of a parent,
--- with 0.00 at the parent's top edge
---@param control Control
---@param parent Control
---@param topPercent? number defaults to 0.00 (all the way at the top)
function FromTopIn(control, parent, topPercent)
    if topPercent and topPercent ~= 0 then
        control.Top:SetFunction(function()
            return MathFloor(parent.Top() + topPercent * parent.Height())
        end)
    else
        AtTopIn(control, parent)
    end
end

--- Places the control's right edge at a percentage along the width of a parent,
--- with 0.00 at the parent's right edge
---@param control Control
---@param parent Control
---@param rightPercent? number defaults to 0.00 (all the way right)
function FromRightIn(control, parent, rightPercent)
    if rightPercent and rightPercent ~= 0 then
        control.Right:SetFunction(function()
            return MathFloor(parent.Right() - rightPercent * parent.Width())
        end)
    else
        AtRightIn(control, parent)
    end
end

--- Places the control's bottom edge at a percentage along the height of a parent,
--- with 0.00 at the parent's bottom edge
---@param control Control
---@param parent Control
---@param bottomPercent? number defaults to 0.00 (all the way at the bottom)
function FromBottomIn(control, parent, bottomPercent)
    if bottomPercent and bottomPercent ~= 0 then
        control.Bottom:SetFunction(function()
            return MathFloor(parent.Bottom() - bottomPercent * parent.Height())
        end)
    else
        AtBottomIn(control, parent)
    end
end


----------
-- Inside space functions
----------

--- Places the control's left edge a percentage along the horizontal space of a parent,
--- with 0.00 at the parent's left edge (this requires the control's width to be set)
---@param control Control
---@param parent Control
---@param leftPercent? number
function FromLeftWith(control, parent, leftPercent)
    if leftPercent and leftPercent ~= 0 then
        control.Left:SetFunction(function()
            return MathFloor(parent.Left() + leftPercent * (parent.Width() - control.Width()))
        end)
    else
        AtLeftIn(control, parent)
    end
end

--- Places the control's top edge a percentage along the vertical space of a parent
--- with 0.00 at the parent's top edge (this requires the control's height to be set)
---@param control Control
---@param parent Control
---@param topPercent? number
function FromTopWith(control, parent, topPercent)
    if topPercent and topPercent ~= 0 then
        control.Top:SetFunction(function()
            return MathFloor(parent.Top() + topPercent * (parent.Height() - control.Height()))
        end)
    else
        AtTopIn(control, parent)
    end
end

--- Places the control's right edge a percentage along the horizontal space of a parent,
--- with 0.00 at the parent's right edge (this requires the control's width to be set)
---@param control Control
---@param parent Control
---@param rightPercent? number
function FromRightWith(control, parent, rightPercent)
    if rightPercent and rightPercent ~= 0 then
        control.Right:SetFunction(function()
            return MathFloor(parent.Right() - rightPercent * (parent.Width() - control.Width()))
        end)
    else
        AtRightIn(control, parent)
    end
end

--- Places the control's bottom edge a percentage along the vertical space of a parent
--- with 0.00 at the parent's bottom edge (this requires the control's height to be set)
---@param control Control
---@param parent Control
---@param bottomPercent? number
function FromBottomWith(control, parent, bottomPercent)
    if bottomPercent and bottomPercent ~= 0 then
        control.Bottom:SetFunction(function()
            return MathFloor(parent.Bottom() - bottomPercent * (parent.Height() - control.Height()))
        end)
    else
        AtBottomIn(control, parent)
    end
end



------------------------------
-- Double-positioning Functions
------------------------------

--- Places a control in the center of a parent, with optional offsets.
--- This sets the control's left and top edges.  
--- Note the argument order.
---@param control Control
---@param parent Control
---@param topOffset? number offset of top edge in downward direction, scaled by the pixel scale factor
---@param leftOffset? number offset of left edge in rightward direction, scaled by the pixel scale factor
function AtCenterIn(control, parent, topOffset, leftOffset)
    AtHorizontalCenterIn(control, parent, leftOffset)
    AtVerticalCenterIn(control, parent, topOffset)
end


----------
-- Outside edge positioning functions
----------

--- Lock right edge of a control to left edge of a parent, centered vertically.
--- This sets the control's right and top edges.
---@param control Control
---@param parent Control
---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
function CenteredLeftOf(control, parent, padding)
    AnchorToLeft(control, parent, padding)
    AtVerticalCenterIn(control, parent)
end

--- Lock bottom edge of a control to top edge of a parent, centered horizontally.
--- This sets the control's left and bottom edges.
---@param control Control
---@param parent Control
---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
function CenteredAbove(control, parent, padding)
    AtHorizontalCenterIn(control, parent)
    AnchorToTop(control, parent, padding)
end

--- Lock left edge of a control to right edge of a parent, centered vertically.
--- This sets the control's left and top edges.
---@param control Control
---@param parent Control
---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
function CenteredRightOf(control, parent, padding)
    AnchorToRight(control, parent, padding)
    AtVerticalCenterIn(control, parent)
end

--- Lock top edge of a control to bottom edge of a parent, centered horizontally.
--- This sets the control's left and top edges.
---@param control Control
---@param parent Control
---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
function CenteredBelow(control, parent, padding)
    AtHorizontalCenterIn(control, parent)
    AnchorToBottom(control, parent, padding)
end


----------
-- Inside 8-way positioning functions
----------

--- Places left edge of the control vertically centered inside of a parent's, with optional offsets.
--- This sets the control's left and top edges.
---@param control Control
---@param parent Control
---@param leftOffset? number offset of the control's left edge in the rightward direction, scaled by the pixel scale factor
---@param topOffset? number offset of the control's top edge in the downward direction, scaled by the pixel scale factor
function AtLeftCenterIn(control, parent, leftOffset, topOffset)
    AtLeftIn(control, parent, leftOffset)
    AtVerticalCenterIn(control, parent, topOffset)
end

--- Places top left corner of a control inside of a parent's, with optional offsets
---@param control Control
---@param parent Control
---@param leftOffset? number offset of the control's left edge in the rightward direction, scaled by the pixel scale factor
---@param topOffset? number offset of the control's top edge in the downward direction, scaled by the pixel scale factor
function AtLeftTopIn(control, parent, leftOffset, topOffset)
    AtLeftIn(control, parent, leftOffset)
    AtTopIn(control, parent, topOffset)
end

--- Places top edge of the control horizontally centered inside of a parent's, with optional offsets.
--- Sets the control's left and top edges.  
--- Note the argument order.
---@param control Control
---@param parent Control
---@param topOffset? number offset of the control's top edge in the downward direction, scaled by the pixel scale factor
---@param leftOffset? number offset of the control's left edge in the rightward direction, scaled by the pixel scale factor
function AtTopCenterIn(control, parent, topOffset, leftOffset)
    AtTopIn(control, parent, topOffset)
    AtHorizontalCenterIn(control, parent, leftOffset)
end

--- Places top right corner of a control inside of a parent's, with optional offsets
---@param control Control
---@param parent Control
---@param rightOffset? number offset of the control's right edge in the leftward direction, scaled by the pixel scale factor
---@param topOffset? number offset of the control's top edge in the downward direction, scaled by the pixel scale factor
function AtRightTopIn(control, parent, rightOffset, topOffset)
    AtRightIn(control, parent, rightOffset)
    AtTopIn(control, parent, topOffset)
end

--- Places right edge of the control vertically centered inside of a parent's, with optional offsets.
--- Sets the control's right and top edges.
---@param control Control
---@param parent Control
---@param rightOffset? number offset of the control's right edge in the leftward direction, scaled by the pixel scale factor
---@param topOffset? number offset of the control's top edge in the downward direction, scaled by the pixel scale factor
function AtRightCenterIn(control, parent, rightOffset, topOffset)
    AtRightIn(control, parent, rightOffset)
    AtVerticalCenterIn(control, parent, topOffset)
end

--- Places bottom right corner of a control inside of a parent's, with optional offsets
---@param control Control
---@param parent Control
---@param rightOffset? number offset of the control's right edge in the leftward direction, scaled by the pixel scale factor
---@param bottomOffset? number offset of the control's bottom edge in the upward direction, scaled by the pixel scale factor
function AtRightBottomIn(control, parent, rightOffset, bottomOffset)
    AtRightIn(control, parent, rightOffset)
    AtBottomIn(control, parent, bottomOffset)
end

--- Places bottom edge of the control horizontally centered inside of a parent's, with optional offsets.
--- Sets the control's left and bottom edges.  
--- Note the argument order.
---@param control Control
---@param parent Control
---@param leftOffset? number offset of the control's left edge in the rightward direction, scaled by the pixel scale factor
---@param bottomOffset? number offset of the control's bottom edge in the upward direction, scaled by the pixel scale factor
function AtBottomCenterIn(control, parent, bottomOffset, leftOffset)
    AtBottomIn(control, parent, bottomOffset)
    AtHorizontalCenterIn(control, parent, leftOffset)
end

--- Places bottom left corner of a control inside of a parent's, with optional offsets
---@param control Control
---@param parent Control
---@param leftOffset? number offset of the control's left edge in the rightward direction, scaled by the pixel scale factor
---@param bottomOffset? number offset of the control's bottom edge in the upward direction, scaled by the pixel scale factor
function AtLeftBottomIn(control, parent, leftOffset, bottomOffset)
    AtLeftIn(control, parent, leftOffset)
    AtBottomIn(control, parent, bottomOffset)
end


----------
-- Flow-positioning functions
----------

-- These functions will set the controls position relative to another, usually a sibling

--- Lock top right of a control to top left of a parent
---@param control Control
---@param parent Control
---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
function LeftOf(control, parent, padding)
    AnchorToLeft(control, parent, padding)
    AtTopIn(control, parent)
end

--- Lock top left of a control to top right of a parent
---@param control Control
---@param parent Control
---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
function RightOf(control, parent, padding)
    AnchorToRight(control, parent, padding)
    AtTopIn(control, parent)
end

--- Lock bottom left of a control to top left of a parent
---@param control Control
---@param parent Control
---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
function Above(control, parent, padding)
    AtLeftIn(control, parent)
    AnchorToTop(control, parent, padding)
end

--- Lock top left of a control to bottom left of a parent
---@param control Control
---@param parent Control
---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
function Below(control, parent, padding)
    AtLeftIn(control, parent)
    AnchorToBottom(control, parent, padding)
end



------------------------------
-- Axial Functions
------------------------------

-- These functions set two of the three axial properties a control has
-- (the third can be reset or left alone)

--- Sets a control to fill the horizontal space of a parent
---@param control Control
---@param parent Control
function FillHorizontally(control, parent)
    AtLeftIn(control, parent)
    AtRightIn(control, parent)
end

--- Sets a control to fill the vertical space of a parent
---@param control Control
---@param parent Control
function FillVertically(control, parent)
    AtTopIn(control, parent)
    AtBottomIn(control, parent)
end



------------------------------
-- Composite Functions
------------------------------

--- Reset all edges and dimensions to the default layout functions.  
--- You should call `control:ResetLayout()` instead unless you cannot rely on overriden behavior.  
--- Remember to redefine two horizontal and two vertical properties to avoid circular dependencies.
---@param control Control
function Reset(control)
    ResetLeft(control)
    ResetTop(control)
    ResetRight(control)
    ResetBottom(control)
    ResetWidth(control)
    ResetHeight(control)
end

-- These functions will place the control and resize in a specified location within the parent.
-- Note that the offset version is more useful than hard coding the location
-- as it will take advantage of the pixel scale factor

--- Sets all edges of a control to be a certain amount inside of a parent.
--- Offsets are optional and scaled by the pixel scale factor.
---@param control Control
---@param parent Control
---@param left? number
---@param top? number
---@param right? number
---@param bottom? number
function OffsetIn(control, parent, left, top, right, bottom)
    AtLeftIn(control, parent, left)
    AtTopIn(control, parent, top)
    AtRightIn(control, parent, right)
    AtBottomIn(control, parent, bottom)
end

--- Sets all edges of a control to be a certain percentage inside of a parent.
--- Percentages are optional.
---@param control Control
---@param parent Control
---@param left? number
---@param top? number
---@param right? number
---@param bottom? number
function PercentIn(control, parent, left, top, right, bottom)
    FromLeftIn(control, parent, left)
    FromTopIn(control, parent, top)
    FromRightIn(control, parent, right)
    FromBottomIn(control, parent, bottom)
end


----------
-- Fill functions
----------

--- Sets a control to fill a parent
---@param control Control
---@param parent Control
function FillParent(control, parent)
    FillHorizontally(control, parent)
    FillVertically(control, parent)
end

--- Sets a control to fill a parent's with fixed padding on all edges
---@param control Control
---@param parent Control
---@param offset? number
function FillParentFixedBorder(control, parent, offset)
    OffsetIn(control, parent, offset, offset, offset, offset)
end

--- Sets a control to fill a parent's with percent padding on all edges
---@param control Control
---@param parent Control
---@param percent? number
function FillParentRelativeBorder(control, parent, percent)
    PercentIn(control, parent, percent, percent, percent, percent)
end

--- Sets a control's edges to fill a parent while preserving its width-to-height ratio
---@param control Control
---@param parent Control
function FillParentPreserveAspectRatio(control, parent)
    local function GetRatio(control, parent)
        local ratio = parent.Height() / control.Height()
        if ratio * control.Width() > parent.Width() then
            ratio = parent.Width() / control.Width()
        end
        return ratio
    end

    control.Top:SetFunction(function()
        return MathFloor(parent.Top() + (parent.Height() - control.Height() * GetRatio(control, parent)) * 0.5)
    end)
    control.Bottom:SetFunction(function()
        return MathFloor(parent.Bottom() - (parent.Height() - control.Height() * GetRatio(control, parent)) * 0.5)
    end)
    control.Left:SetFunction(function()
        return MathFloor(parent.Left() + (parent.Width() - control.Width() * GetRatio(control, parent)) * 0.5)
    end)
    control.Right:SetFunction(function()
        return MathFloor(parent.Right() - (parent.Width() - control.Width() * GetRatio(control, parent)) * 0.5)
    end)
end


----------
-- Maui functions
----------

-- The following functions use layout files created with the Maui Photoshop Exporter to position controls
-- Layout files contain a single table in this format:
-- 
-- layout = {
--     {control_name_1 = {left = 0, top = 0, width = 100, height = 100,},
--     {control_name_2 = {left = 0, top = 0, width = 100, height = 100,},
-- }

--- Sets a control's top and left edges to be positioned to a parent using a layout table.  
--- Note the argument order.
---@param control Control
---@param parent Control
---@param fileName LazyVar|function Full path and filename of the layout file. Must be a lazy var or function that returns the filename.
---@param controlName string name (table key) of the control to be positioned
---@param parentName string name (table key) of the control to be positioned relative to
---@param topOffset? number
---@param leftOffset? number
function RelativeTo(control, parent, fileName, controlName, parentName, topOffset, leftOffset)
    local layoutTable = import(fileName()).layout
    if not layoutTable[controlName] then
        WARN("Control not found in layout table: " .. controlName)
    end
    if not layoutTable[parentName] then
        WARN("Parent not found in layout table: " .. parentName)
    end
    topOffset = topOffset or 0
    leftOffset = leftOffset or 0
    control.Top:SetFunction(function()
        local layoutTable = import(fileName()).layout
        return MathFloor(parent.Top() + (layoutTable[controlName].top - layoutTable[parentName].top + topOffset) * pixelScaleFactor)
    end)

    control.Left:SetFunction(function()
        local layoutTable = import(fileName()).layout
        return MathFloor(parent.Left() + (layoutTable[controlName].left - layoutTable[parentName].left + leftOffset) * pixelScaleFactor)
    end)
end

--- Sets a control's left edge to be positioned to a parent using a layout table
---@param control Control
---@param parent Control
---@param fileName LazyVar|function Full path and filename of the layout file. Must be a lazy var or function that returns the filename.
---@param controlName string name (table key) of the control to be positioned
---@param parentName string name (table key) of the control to be positioned relative to
function LeftRelativeTo(control, parent, fileName, controlName, parentName)
    local layoutTable = import(fileName()).layout
    if not layoutTable[controlName] then
        WARN("Control not found in layout table: " .. controlName)
    end
    if not layoutTable[parentName] then
        WARN("Parent not found in layout table: " .. parentName)
    end
    control.Left:SetFunction(function()
        local layoutTable = import(fileName()).layout
        return MathFloor(parent.Left() + layoutTable[controlName].left - layoutTable[parentName].left)
    end)
end

--- Sets a control's top edge to be positioned to a parent using a layout table
---@param control Control
---@param parent Control
---@param fileName LazyVar|function Full path and filename of the layout file. Must be a lazy var or function that returns the filename.
---@param controlName string name (table key) of the control to be positioned
---@param parentName string name (table key) of the control to be positioned relative to
function TopRelativeTo(control, parent, fileName, controlName, parentName)
    local layoutTable = import(fileName()).layout
    if not layoutTable[controlName] then
        WARN("Control not found in layout table: " .. controlName)
    end
    if not layoutTable[parentName] then
        WARN("Parent not found in layout table: " .. parentName)
    end
    control.Top:SetFunction(function()
        local layoutTable = import(fileName()).layout
        return MathFloor(parent.Top() + layoutTable[controlName].top - layoutTable[parentName].top)
    end)
end

--- Sets a control's right edge to be positioned to a parent using a layout table
---@param control Control
---@param parent Control
---@param fileName LazyVar|function Full path and filename of the layout file. Must be a lazy var or function that returns the filename.
---@param controlName string name (table key) of the control to be positioned
---@param parentName string name (table key) of the control to be positioned relative to
function RightRelativeTo(control, parent, fileName, controlName, parentName)
    local layoutTable = import(fileName()).layout
    if not layoutTable[controlName] then
        WARN("Control not found in layout table: " .. controlName)
    end
    if not layoutTable[parentName] then
        WARN("Parent not found in layout table: " .. parentName)
    end
    control.Right:SetFunction(function()
        local layoutTable = import(fileName()).layout
        local layoutParent = layoutTable[parentName]
        local layoutControl = layoutTable[controlName]
        return MathFloor(parent.Right() - ((layoutParent.left + layoutParent.width) - (layoutControl.left + layoutControl.width)))
    end)
end

--- Sets a control's bottom edge to be positioned to a parent using a layout table
---@param control Control
---@param parent Control
---@param fileName LazyVar|function Full path and filename of the layout file. Must be a lazy var or function that returns the filename.
---@param controlName string name (table key) of the control to be positioned
---@param parentName string name (table key) of the control to be positioned relative to
function BottomRelativeTo(control, parent, fileName, controlName, parentName)
    local layoutTable = import(fileName()).layout
    if not layoutTable[controlName] then
        WARN("Control not found in layout table: " .. controlName)
    end
    if not layoutTable[parentName] then
        WARN("Parent not found in layout table: " .. parentName)
    end
    control.Bottom:SetFunction(function()
        local layoutTable = import(fileName()).layout
        local layoutParent = layoutTable[parentName]
        local layoutControl = layoutTable[controlName]
        return MathFloor(parent.Bottom() - ((layoutParent.top + layoutParent.height) - (layoutControl.top + layoutControl.height)))
    end)
end

--- Sets a control's dimensions using a layout table
---@param control Control
---@param fileName LazyVar|function Full path and filename of the layout file. Must be a lazy var or function that returns the filename.
---@param controlName string name (table key) of the control to be positioned
function DimensionsRelativeTo(control, fileName, controlName)
    local layoutTable = import(fileName()).layout
    if not layoutTable[controlName] then
        WARN("Control not found in layout table: " .. controlName)
    end
    control.Width:SetFunction(function()
        local layoutTable = import(fileName()).layout
        return MathFloor(layoutTable[controlName].width * pixelScaleFactor)
    end)
    control.Height:SetFunction(function()
        local layoutTable = import(fileName()).layout
        return MathFloor(layoutTable[controlName].height * pixelScaleFactor)
    end)
end



------------------------------
-- Compound Functions
------------------------------

-- These functions layout multiple controls at once

---@param left Control
---@param right Control
---@param parent Control
---@param percentage number
---@param sep? number
function SplitHorizontallyIn(left, right, parent, percentage, sep)
    AtRightIn(right, parent)
    FillVertically(right, parent)
    if sep then
        right.Left:SetFunction(function()
            return parent.Left() + MathFloor(percentage * parent.Width() + ScaleNumber(sep) * 0.5)
        end)
    else
        FromLeftIn(right, parent, percentage)
    end

    AtLeftIn(left, parent)
    FillVertically(left, parent)
    AnchorToLeft(left, right, sep)
end

---@param top Control
---@param bottom Control
---@param parent Control
---@param percentage number
---@param sep? number
function SplitVerticallyIn(top, bottom, parent, percentage, sep)
    FillHorizontally(bottom, parent)
    AtBottomIn(bottom, parent)
    if sep then
        bottom.Top:SetFunction(function()
            return parent.Top() + MathFloor(percentage * parent.Height() + ScaleNumber(sep) * 0.5)
        end)
    else
        FromTopIn(bottom, parent, percentage)
    end

    FillHorizontally(top, parent)
    AtTopIn(top, parent)
    AnchorToTop(top, bottom, sep)
end




--------------------------------------------------------------------------------
-- Layouters
--------------------------------------------------------------------------------

-- An extremely helpful design pattern for laying out components, it is intended to make
-- UI code readable, maintainable, robust, and easily diagnosable
--
-- To use it, start by making sure these lines are at the top of your UI file
--[[
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Layouter = LayoutHelpers.ReusedLayoutFor
--]]
-- (This is mostly for readability, but there's also efficiency reasons)
--
-- After that, you can use the Layouter to replace most calls to a LayoutHelper.lua function by
-- using its daisy-chain semantics:
--[[
Layouter(component)
    :AtLeftIn(parent, 3)
    :AnchorToBottom(previousComponent)
    :End()
--]]
-- Whenever a Layouter calls `End()` it makes sure its positional properties don't have any
-- lingering circular dependencies and it returns the control. Additionally, if the control it just
-- finished laying out has a method called `Layout()`, it is called and this is why:
--
-- Any UI components you initialize should only initialize child components, it should NOT layout
-- anything inside of the `__init` function. This is because a UI component should be built with
-- reusability and encapsulation in mind--a component should not lay itself out because it is up to
-- its parent to decide where it goes. Therefore, any children that component has also should not be
-- laid out in the initializer since they depend on its layout to be positioned correctly.
--
-- Not only that, but it's possible that your class needs to change how it looks when the layout
-- skin changes (either by it rotating or different faction being selected).
--
-- (Calling `Layouter` also calls a control's `OnLayout()` method, but you shouldn't need to use
-- that unless there's some dynamic component instantiation going on that requires external data)
-- If you need to establish layout defaults that are easily overwritten and would need to be done in
-- `__init()`, you still shouldn't lay anything out there as it actually belongs in the `OnInit()`
-- function (as with any overriden function, make sure to call your parent's `OnInit()` first).
--
-- Thus, a basic UI class might end up looking something like this:
--[[
UIComponent = Class(Group) {
    __init = function(self, parent)
        Group.__init(self, parent)

        self.component = UIUtil.CreateText( ... )
        ...
    end;

    Layout = function(self)
        local component = Layouter(self.component)
            :AtTopLeftIn(self)
            ...
    end;
}
--]]
-- This means that the only thing that needs to happen is either for another UI class to use this
-- component in their layout, or, if it's a top-level singleton class, to create an interface using
-- the following idiom:
--[[
local GUI = false

function Create(parent)
    local component = GUI
    if component then
        return component
    end
    component = UIComponent(parent)
    GUI = component
    return component
end

function SetLayout()
    Layouter(GUI)
        :AtTopLeftIn(parent)
        :Width(364)
        :Height(180)
        :End()
end
--]]
-- Do not try to layout more than control at a time; it is confusing and will break the default
-- layouter. However, should it be absolutely necessary (e.g. for UI utilities that may not create a
-- control with a valid hierarchy or in legacy code), you can construct a new layouter using
-- `LayoutHelpers.LayoutFor(control)` that won't interrupt the default one.


-- Set this to true to validate a control's layout on `End()`
ValidateLayouter = false


---@alias Layoutable Layoutable

--- Returns the control a layout represents, whether a layouter or an actual control
---@param layout Layoutable
---@return Control
function GetLayoutControl(layout)
    return layout.layoutControl or layout
end

--------------------------------------------------
-- Control Attribute
--------------------------------------------------

---@class LayouterAttributeControl
local LayouterAttributeControl = ClassSimple {
    --- Sets the name of the control
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param debugName string
    ---@return T
    Name = function(self, debugName)
        self.layoutControl:SetName(debugName)
        return self
    end;

    --- Disables the control
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@return T
    Disable = function(self)
        self.layoutControl:Disable()
        return self
    end;

    --- Hides the control
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@return T
    Hide = function(self)
        self.layoutControl:Hide()
        return self
    end;

    --- Enables the control's hit test
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param isRecursive? boolean
    ---@return T
    EnableHitTest = function(self, isRecursive)
        self.layoutControl:EnableHitTest(isRecursive)
        return self
    end;

    --- Disables the control's hit test
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param isRecursive? boolean
    ---@return T
    DisableHitTest = function(self, isRecursive)
        self.layoutControl:DisableHitTest(isRecursive)
        return self
    end;

    --- Sets if the control needs a frame update
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param needsUpdate boolean
    ---@return T
    NeedsFrameUpdate = function(self, needsUpdate)
        self.layoutControl:SetNeedsFrameUpdate(needsUpdate)
        return self
    end;

    --- Sets the alpha of the control
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param alpha number
    ---@param forChildren? boolean
    ---@return T
    Alpha = function(self, alpha, forChildren)
        self.layoutControl:SetAlpha(alpha, forChildren)
        return self
    end;



    ------------------------------
    -- Property Setters
    ------------------------------

    ----------
    -- Positional setters
    ----------

    --- Sets the left edge of the control
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param left Lazy<number>
    ---@return T
    Left = function(self, left)
        self.layoutControl.Left:Set(left)
        return self
    end;

    --- Sets the top edge of the control
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param top Lazy<number>
    ---@return T
    Top = function(self, top)
        self.layoutControl.Top:Set(top)
        return self
    end;

    --- Sets the right edge of the control
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param right Lazy<number>
    ---@return T
    Right = function(self, right)
        self.layoutControl.Right:Set(right)
        return self
    end;

    --- Sets the bottom edge of the control
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param bottom Lazy<number>
    ---@return T
    Bottom = function(self, bottom)
        self.layoutControl.Bottom:Set(bottom)
        return self
    end;


    ----------
    -- Dimensional setters
    ----------

    --- Sets the width of the control
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param width Lazy<number> if a number, width will be scaled by the pixel factor
    ---@return T
    Width = function(self, width)
        local controlWidth = self.layoutControl.Width
        if iscallable(width) then
            controlWidth:SetFunction(width)
        else
            controlWidth:SetValue(ScaleNumber(width))
        end
        return self
    end;

    --- Sets the height of the control
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param height Lazy<number> if a number, height will be scaled by the pixel factor
    ---@return T
    Height = function(self, height)
        local controlHeight = self.layoutControl.Height
        if iscallable(height) then
            controlHeight:SetFunction(height)
        else
            controlHeight:SetValue(ScaleNumber(height))
        end
        return self
    end;

    --- Sets the width of the control to a texture
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param filename Lazy<FileName>
    ---@param padding? number defaults to 0, not 1
    ---@return T
    WidthFromTexture = function(self, filename, padding)
        SetWidthFromTexture(self.layoutControl, filename, padding)
        return self
    end;

    --- Sets the height of the control to a texture
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param filename Lazy<FileName>
    ---@param padding? number defaults to 0, not 1
    ---@return T
    HeightFromTexture = function(self, filename, padding)
        SetHeightFromTexture(self.layoutControl, filename, padding)
        return self
    end;

    --- Sets the dimensions of the control to a texture
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param filename Lazy<FileName>
    ---@param padding? number defaults to 0, not 1
    ---@return T
    DimensionsFromTexture = function(self, filename, padding)
        SetDimensionsFromTexture(self.layoutControl, filename, padding)
        return self
    end;


    ----------
    -- Depth setters
    ----------

    --- Sets depth of the control to be above a parent
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param depth? integer defaults to 1
    ---@return T
    Over = function(self, parent, depth)
        DepthOverParent(self.layoutControl, GetLayoutControl(parent), depth)
        return self
    end;


    --- Sets depth of the control to be below a parent
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param depth? integer defaults to 1
    ---@return T
    Under = function(self, parent, depth)
        DepthUnderParent(self.layoutControl, GetLayoutControl(parent), depth)
        return self
    end;



    ------------------------------
    -- Single positioning methods
    ------------------------------

    ----------
    -- Reset methods
    ----------

    --- Resets the control's left edge to be calculated from its right edge and width.  
    --- Make sure `control.Right` and `control.Width` are not reset.
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@return T
    ResetLeft = function(self)
        ResetLeft(self.layoutControl)
        return self
    end;

    --- Resets the control's top edge to be calculated from its bottom edge and height.  
    --- Make sure `control.Bottom` and `control.Height` are not reset.
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@return T
    ResetTop = function(self)
        ResetTop(self.layoutControl)
        return self
    end;

    --- Resets the control's right edge to be calculated from its left edge and width.  
    --- Make sure `control.Left` and `control.Width` are not reset.
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@return T
    ResetRight = function(self)
        ResetRight(self.layoutControl)
        return self
    end;

    --- Resets the control's bottom edge to be calculated from its top edge and height.  
    --- Make sure `control.Top` and `control.Height` are not reset.
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@return T
    ResetBottom = function(self)
        ResetBottom(self.layoutControl)
        return self
    end;

    --- Resets the control's width to be calculated from its left and right edges.  
    --- Make sure `control.Left` and `control.Right` are not reset.
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@return T
    ResetWidth = function(self)
        ResetWidth(self.layoutControl)
        return self
    end;

    --- Resets the control's height to be calculated from its top and bottom edges.  
    --- Make sure `control.Top` and `control.Bottom` are not reset.
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@return T
    ResetHeight = function(self)
        ResetHeight(self.layoutControl)
        return self
    end;


    ----------
    -- Anchor methods
    ----------

    --- Anchors the control's right edge to the left edge of a parent, with optional padding
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param padding? number fixed padding between control and parent, scaled by the pixel scale factor
    ---@return T
    AnchorToLeft = function(self, parent, padding)
        AnchorToLeft(self.layoutControl, GetLayoutControl(parent), padding)
        return self
    end;

    --- Anchors the control's bottom edge to the top edge of a parent, with optional padding
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param padding? number fixed padding between control and parent, scaled by the pixel scale factor
    ---@return T
    AnchorToTop = function(self, parent, padding)
        AnchorToTop(self.layoutControl, GetLayoutControl(parent), padding)
        return self
    end;

    --- Anchors the control's left edge to the right edge of a parent, with optional padding
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param padding? number fixed padding between control and parent, scaled by the pixel scale factor
    ---@return T
    AnchorToRight = function(self, parent, padding)
        AnchorToRight(self.layoutControl, GetLayoutControl(parent), padding)
        return self
    end;

    --- Anchors the control's top edge to the bottom edge of a parent, with optional padding
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param padding? number fixed padding between control and parent, scaled by the pixel scale factor
    ---@return T
    AnchorToBottom = function(self, parent, padding)
        AnchorToBottom(self.layoutControl, GetLayoutControl(parent), padding)
        return self
    end;


    ----------
    -- Inside offset methods
    ----------

    --- Centers the control horizontally on a parent, with optional rightward offset.
    --- This sets the control's left edge.
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param leftOffset? number Offset of control's left edge in the rightward direction, scaled by the pixel scale factor. Defaults to 0.
    ---@return T
    AtHorizontalCenterIn = function(self, parent, leftOffset)
        AtHorizontalCenterIn(self.layoutControl, GetLayoutControl(parent), leftOffset)
        return self
    end;

    --- Centers the control vertically on a parent, with optional downward offset.
    --- This sets the control's top edge.
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param topOffset? number Offset of the control's top edge in the downward direction, scaled by the pixel scale factor. Defaults to 0.
    ---@return T
    AtVerticalCenterIn = function(self, parent, topOffset)
        AtVerticalCenterIn(self.layoutControl, GetLayoutControl(parent), topOffset)
        return self
    end;

    --- Places the control's left edge inside of a parent's, with optional rightward offset
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param leftOffset? number Offset of the control's left edge in the rightward direction, scaled by the pixel scale factor. Defaults to 0.
    ---@return T
    AtLeftIn = function(self, parent, leftOffset)
        AtLeftIn(self.layoutControl, GetLayoutControl(parent), leftOffset)
        return self
    end;

    --- Places the control's top edge inside of a parent's, with optional downward offset
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param topOffset? number Offset of the control's top edge in the downward direction, scaled by the pixel scale factor. Defaults to 0.
    ---@return T
    AtTopIn = function(self, parent, topOffset)
        AtTopIn(self.layoutControl, GetLayoutControl(parent), topOffset)
        return self
    end;

    --- Places the control's right edge inside of a parent's, with optional leftward offset
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param rightOffset? number Offset of the control's right edge in the leftward direction, scaled by the pixel scale factor. Defaults to 0.
    ---@return T
    AtRightIn = function(self, parent, rightOffset)
        AtRightIn(self.layoutControl, GetLayoutControl(parent), rightOffset)
        return self
    end;

    --- Places the control's bottom edge inside of a parent's, with optional upward offset
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param bottomOffset? number Offset of the control's bottom edge in the upward direction, scaled by the pixel scale factor. Defaults to 0.
    ---@return T
    AtBottomIn = function(self, parent, bottomOffset)
        AtBottomIn(self.layoutControl, GetLayoutControl(parent), bottomOffset)
        return self
    end;


    ----------
    -- Inside percentage methods
    ----------

    --- Places the control's left edge at a percentage along the width of a parent,
    --- with 0.00 at the parent's left edge
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param leftPercent? number defaults to 0.00 (all the way to left)
    FromLeftIn = function(self, parent, leftPercent)
        FromLeftIn(self.layoutControl, GetLayoutControl(parent), leftPercent)
        return self
    end;

    --- Places the control's top edge at a percentage along the height of a parent,
    --- with 0.00 at the parent's top edge
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param topPercent? number defaults to 0.00 (all the way at the top)
    FromTopIn = function(self, parent, topPercent)
        FromTopIn(self.layoutControl, GetLayoutControl(parent), topPercent)
        return self
    end;

    --- Places the control's right edge at a percentage along the width of a parent,
    --- with 0.00 at the parent's right edge
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param rightPercent? number defaults to 0.00 (all the way right)
    FromRightIn = function(self, parent, rightPercent)
        FromRightIn(self.layoutControl, GetLayoutControl(parent), rightPercent)
        return self
    end;

    --- Places the control's bottom edge at a percentage along the height of a parent,
    --- with 0.00 at the parent's bottom edge
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param bottomPercent? number defaults to 0.00 (all the way at the bottom)
    FromBottomIn = function(self, parent, bottomPercent)
        FromBottomIn(self.layoutControl, GetLayoutControl(parent), bottomPercent)
        return self
    end;


    ----------
    -- Inside space methods
    ----------

    --- Places the control's left edge a percentage along the horizontal space of a parent
    --- with 0.00 at the parent's left edge (this requires the control's width to be set)
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param leftPercent? number
    ---@return T
    FromLeftWith = function(self, parent, leftPercent)
        FromLeftWith(self.layoutControl, GetLayoutControl(parent), leftPercent)
        return self
    end;

    --- Places the control's top edge a percentage along the vertical space of a parent
    --- with 0.00 at the parent's top edge (this requires the control's height to be set)
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param topPercent? number
    ---@return T
    FromTopWith = function(self, parent, topPercent)
        FromTopWith(self.layoutControl, GetLayoutControl(parent), topPercent)
        return self
    end;

    --- Places the control's right edge a percentage along the horizontal space of a parent
    --- with 0.00 at the parent's right edge (this requires the control's width to be set)
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param rightPercent? number
    ---@return T
    FromRightWith = function(self, parent, rightPercent)
        FromRightWith(self.layoutControl, GetLayoutControl(parent), rightPercent)
        return self
    end;

    --- Places the control's bottom edge a percentage along the vertical space of a parent
    --- with 0.00 at the parent's bottom edge (this requires the control's height to be set)
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param bottomPercent? number
    ---@return T
    FromBottomWith = function(self, parent, bottomPercent)
        FromBottomWith(self.layoutControl, GetLayoutControl(parent), bottomPercent)
        return self
    end;



    ------------------------------
    -- Double positioning methods
    ------------------------------

    --- Places the control in the center of the parent, with optional offsets.
    --- This sets the control's left and top edges.  
    --- Note the argument order.
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param topOffset? number offset of top edge in downward direction, scaled by the pixel scale factor
    ---@param leftOffset? number offset of left edge in rightward direction, scaled by the pixel scale factor
    ---@return T
    AtCenterIn = function(self, parent, topOffset, leftOffset)
        AtCenterIn(self.layoutControl, GetLayoutControl(parent), topOffset, leftOffset)
        return self
    end;


    ----------
    -- Outside edge positioning methods
    ----------

    --- Lock right edge of the control to the left edge of a parent, centered vertically.
    --- This sets the control's right and top edges.
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
    ---@return T
    CenteredLeftOf = function(self, parent, padding)
        CenteredLeftOf(self.layoutControl, GetLayoutControl(parent), padding)
        return self
    end;

    --- Lock bottom edge of the control to the top edge of a parent, centered horizontally.
    --- This sets the control's left and bottom edges.
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
    ---@return T
    CenteredAbove = function(self, parent, padding)
        CenteredAbove(self.layoutControl, GetLayoutControl(parent), padding)
        return self
    end;

    --- Lock left edge of the control to the right edge of a parent, centered vertically.
    --- This sets the control's left and top edges.
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
    ---@return T
    CenteredRightOf = function(self, parent, padding)
        CenteredRightOf(self.layoutControl, GetLayoutControl(parent), padding)
        return self
    end;

    --- Lock top edge of the control to the bottom edge of parent, centered horizontally.
    --- This sets the controls's left and top edges.
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
    ---@return T
    CenteredBelow = function(self, parent, padding)
        CenteredBelow(self.layoutControl, GetLayoutControl(parent), padding)
        return self
    end;


    ----------
    -- Inside positioning methods
    ----------

    --- Places left edge of the control vertically centered inside of a parent's, with optional offsets.
    --- This sets the control's left and top edges.
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param leftOffset? number offset of the control's left edge in the rightward direction, scaled by the pixel scale factor
    ---@param topOffset? number offset of the control's top edge in the downward direction, scaled by the pixel scale factor
    ---@return T
    AtLeftCenterIn = function(self, parent, leftOffset, topOffset)
        AtLeftCenterIn(self.layoutControl, GetLayoutControl(parent), leftOffset, topOffset)
        return self
    end;

    --- Places top left corner of the control inside of a parent's, with optional offsets
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param leftOffset? number offset of the control's left edge in the rightward direction, scaled by the pixel scale factor
    ---@param topOffset? number offset of the control's top edge in the downward direction, scaled by the pixel scale factor
    ---@return T
    AtLeftTopIn = function(self, parent, leftOffset, topOffset)
        AtLeftTopIn(self.layoutControl, GetLayoutControl(parent), leftOffset, topOffset)
        return self
    end;

    --- Places top edge of the control horizontally centered inside of a parent's, with optional offsets.
    --- Sets the control's left and top edges.  
    --- Note the argument order.
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param topOffset? number offset of the control's top edge in the downward direction, scaled by the pixel scale factor
    ---@param leftOffset? number offset of the control's left edge in the rightward direction, scaled by the pixel scale factor
    ---@return T
    AtTopCenterIn = function(self, parent, topOffset, leftOffset)
        AtTopCenterIn(self.layoutControl, GetLayoutControl(parent), topOffset, leftOffset)
        return self
    end;

    --- Places top right corner of the control inside of a parent's, with optional offsets
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param rightOffset? number offset of the control's right edge in the leftward direction, scaled by the pixel scale factor
    ---@param topOffset? number offset of the control's top edge in the downward direction, scaled by the pixel scale factor
    ---@return T
    AtRightTopIn = function(self, parent, rightOffset, topOffset)
        AtRightTopIn(self.layoutControl, GetLayoutControl(parent), rightOffset, topOffset)
        return self
    end;

    --- Places right edge of the control vertically centered inside of a parent's, with optional offsets.
    --- Sets the control's right and top edges.
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param rightOffset? number offset of the control's right edge in the leftward direction, scaled by the pixel scale factor
    ---@param topOffset? number offset of the control's top edge in the downward direction, scaled by the pixel scale factor
    ---@return T
    AtRightCenterIn = function(self, parent, rightOffset, topOffset)
        AtRightCenterIn(self.layoutControl, GetLayoutControl(parent), rightOffset, topOffset)
        return self
    end;

    --- Places bottom right corner of the control inside of a parent's, with optional offsets
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param rightOffset? number offset of the control's right edge in the leftward direction, scaled by the pixel scale factor
    ---@param bottomOffset? number offset of the control's bottom edge in the upward direction, scaled by the pixel scale factor
    ---@return T
    AtRightBottomIn = function(self, parent, rightOffset, bottomOffset)
        AtRightBottomIn(self.layoutControl, GetLayoutControl(parent), rightOffset, bottomOffset)
        return self
    end;

    --- Places bottom edge of the control horizontally centered inside of a parent's, with optional offsets.
    --- Sets the control's left and bottom edges.  
    --- Note the argument order.
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param leftOffset? number offset of the control's left edge in the rightward direction, scaled by the pixel scale factor
    ---@param bottomOffset? number offset of the control's bottom edge in the upward direction, scaled by the pixel scale factor
    ---@return T
    AtBottomCenterIn = function(self, parent, bottomOffset, leftOffset)
        AtBottomCenterIn(self.layoutControl, GetLayoutControl(parent), bottomOffset, leftOffset)
        return self
    end;

    --- Places bottom left corner of the control inside of a parent's, with optional offsets
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param leftOffset? number offset of the control's left edge in the rightward direction, scaled by the pixel scale factor
    ---@param bottomOffset? number offset of the control's bottom edge in the upward direction, scaled by the pixel scale factor
    ---@return T
    AtLeftBottomIn = function(self, parent, leftOffset, bottomOffset)
        AtLeftBottomIn(self.layoutControl, GetLayoutControl(parent), leftOffset, bottomOffset)
        return self
    end;


    ----------
    -- Flow-positioning methods
    ----------

    --- Lock top right of the control to the top left of a parent
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
    ---@return T
    LeftOf = function(self, parent, padding)
        LeftOf(self.layoutControl, GetLayoutControl(parent), padding)
        return self
    end;

    --- Lock top left of the control to the top right of a parent
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
    ---@return T
    RightOf = function(self, parent, padding)
        RightOf(self.layoutControl, GetLayoutControl(parent), padding)
        return self
    end;

    --- Lock bottom left of the control to the top left of a parent
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
    ---@return T
    Above = function(self, parent, padding)
        Above(self.layoutControl, GetLayoutControl(parent), padding)
        return self
    end;

    --- Lock top left of the control to the bottom left of a parent
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
    ---@return T
    Below = function(self, parent, padding)
        Below(self.layoutControl, GetLayoutControl(parent), padding)
        return self
    end;



    ------------------------------
    -- Axial methods
    ------------------------------

    --- Sets a control to fill the horizontal space of a parent
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@return T
    FillHorizontally = function(self, parent)
        FillHorizontally(self.layoutControl, GetLayoutControl(parent))
        return self
    end;

    --- Sets a control to fill the vertical space of a parent
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@return T
    FillVertically = function(self, parent)
        FillVertically(self.layoutControl, GetLayoutControl(parent))
        return self
    end;



    ------------------------------
    -- Composite methods
    ------------------------------

    --- Sets all edges of a control to be a certain amount inside of a parent.
    --- Offsets are optional and scaled by the pixel scale factor.
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param left? number
    ---@param top? number
    ---@param right? number
    ---@param bottom? number
    ---@return T
    OffsetIn = function(self, parent, left, top, right, bottom)
        OffsetIn(self.layoutControl, GetLayoutControl(parent), left, top, right, bottom)
        return self
    end;

    --- Sets all edges of the control to be a certain percentage inside of a parent.
    --- Percentages are optional.
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param left? number
    ---@param top? number
    ---@param right? number
    ---@param bottom? number
    ---@return T
    PercentIn = function(self, parent, left, top, right, bottom)
        PercentIn(self.layoutControl, GetLayoutControl(parent), left, top, right, bottom)
        return self
    end;


    ----------
    -- Fill methods
    ----------

    --- Sets the control to fill a parent
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@return T
    Fill = function(self, parent)
        FillParent(self.layoutControl, GetLayoutControl(parent))
        return self
    end;

    --- Sets the control to fill a parent's with fixed padding
    ---@generic T : LayouterAttributeControl
    ---@param self T
    ---@param parent Layoutable
    ---@param offset? number
    ---@return T
    FillFixedBorder = function(self, parent, offset)
        FillParentFixedBorder(self.layoutControl, GetLayoutControl(parent), offset)
        return self
    end;
}

------------------------------
-- Drop Shadow Attribute
------------------------------

---@class LayouterAttributeDropShadow
local LayouterAttributeDropShadow = ClassSimple {
    --- Sets if the control has a drop shadow
    ---@generic T : LayouterAttributeDropShadow
    ---@param self T
    ---@param hasShadow boolean
    ---@return T
    DropShadow = function(self, hasShadow)
        local control = self.layoutControl
        local setDropShadow = control.SetDropShadow
        if setDropShadow then
            setDropShadow(control, hasShadow)
        else
            WARN("Cannot set drop shadow for \"" .. control:GetName() .. '\"')
        end
        return self
    end;
}

------------------------------
-- Font Attribute
------------------------------

---@class LayouterAttributeFont
local LayouterAttributeFont = ClassSimple {
    --- Sets the font of the control
    ---@generic T : LayouterAttributeFont
    ---@param self T
    ---@param font Lazy<string>
    ---@param size number
    ---@return T
    Font = function(self, font, size)
        local control = self.layoutControl
        local setFont = control.SetFont
        if setFont then
            setFont(control, font, size)
        else
            WARN("Cannot set font for \"" .. control:GetName() .. '\"')
        end
        return self
    end;
}

------------------------------
-- Editor Attribute
------------------------------

---@class LayouterAttributeEditor : LayouterAttributeFont
local LayouterAttributeEditor = Class(LayouterAttributeFont) {
    --- Sets up the editor of the control
    ---@generic T : LayouterAttributeEditor
    ---@param self T
    ---@param foreColor? Lazy<Color>
    ---@param backColor? Lazy<Color>
    ---@param highlightFore? Lazy<Color>
    ---@param highlightBack? Lazy<Color>
    ---@param fontFace? Lazy<string>
    ---@param fontSize? number
    ---@param charLimit? number
    ---@return T
    Setup = function(self, foreColor, backColor, highlightFore, highlightBack, fontFace, fontSize, charLimit)
        import("/lua/ui/uiutil.lua").SetupEditStd(self.layoutControl,
                foreColor, backColor, highlightFore, highlightBack, fontFace, fontSize, charLimit)
        return self
    end;
}

------------------------------
-- Color Attribute
------------------------------

---@class LayouterAttributeColor
local LayouterAttributeColor = ClassSimple {
    --- Sets the color of the control
    ---@generic T : LayouterAttributeColor
    ---@param self T
    ---@param color Lazy<Color> color as a hexcode
    ---@return T
    Color = function(self, color)
        local control = self.layoutControl
        local setColor = control.SetColor or control.SetSolidColor
        if setColor then
            setColor(control, color)
        else
            WARN("Cannot set color for \"" .. control:GetName() .. '\"')
        end
        return self
    end;
}

------------------------------
-- Texture Attribute
------------------------------

---@class LayouterAttributeTexture : LayouterAttributeColor
local LayouterAttributeTexture = Class(LayouterAttributeColor) {
    --- Sets the control's texture
    ---@generic T : LayouterAttributeTexture
    ---@param self T
    ---@param texture Lazy<string> resource location
    ---@param border? Border
    ---@return T
    Texture = function(self, texture, border)
        local control = self.layoutControl
        local setTexture = control.SetTexture
        if setTexture then
            setTexture(control, texture, border)
        else
            WARN("Cannot set texture for \"" .. control:GetName() .. '\"')
        end
        return self
    end;
}

------------------------------
-- Selection Color Attribute
------------------------------

---@class LayouterAttributeSelection
local LayouterAttributeSelection = ClassSimple {
    --- Sets the list's selection colors
    ---@generic T : LayouterAttributeSelection
    ---@param self T
    ---@param fore? Lazy<Color>
    ---@param back? Lazy<Color>
    ---@param selectedFore? Lazy<Color>
    ---@param selectedBack? Lazy<Color>
    ---@param mouseoverFore? Lazy<Color>
    ---@param mouseoverBack? Lazy<Color>
    ---@return T
    Colors = function(self, fore, back, selectedFore, selectedBack, mouseoverFore, mouseoverBack)
        local control = self.layoutControl
        local setColors = control.SetColors
        if setColors then
            setColors(control, fore, back, selectedFore, selectedBack, mouseoverFore, mouseoverBack)
        else
            WARN("Cannot set colors for \"" .. control:GetName() .. '\"')
        end
        return self
    end;

    --- Sets the list's mouseover behavior
    ---@generic T : LayouterAttributeSelection
    ---@param self T
    ---@param show boolean
    ---@return T
    MouseoverItem = function(self, show)
        local control = self.layoutControl
        local showMouseoverItem = control.ShowMouseoverItem
        if showMouseoverItem then
            showMouseoverItem(control, show)
        else
            WARN("Cannot set show mouseover item for \"" .. control:GetName() .. '\"')
        end
        return self
    end;
}



--------------------------------------------------------------------------------
-- Base Layouter
--------------------------------------------------------------------------------

-- While it can be useful to build specific layouters for individual controls, this monolithic
-- class is the most versatile

---@class Layouter : LayouterAttributeControl, LayouterAttributeDropShadow, LayouterAttributeEditor, LayouterAttributeTexture, LayouterAttributeSelection
---@field layoutControl Control
Layouter = Class(LayouterAttributeControl, LayouterAttributeDropShadow, LayouterAttributeEditor, LayouterAttributeTexture, LayouterAttributeSelection) {
    ---@param self Layouter
    ---@param control Control
    __init = function(self, control)
        if not control then
            return
        end
        local onLayout = control.OnLayout
        if onLayout then
            onLayout(control)
        end
        self.layoutControl = GetLayoutControl(control)
    end;

    OnLayout = function(self)
        local control = self.layoutControl
        local onLayout = control.OnLayout
        if onLayout then
            onLayout(control)
        end
    end;

    Layout = function(self)
        local control = self.layoutControl
        local layout = control.Layout
        if layout then
            layout(control)
        end
    end;

    -- Gets the control
    ---@param self Layouter
    ---@return Control layoutControl
    Get = function(self)
        return self.layoutControl
    end;

    --- Computes the control's properties and returns it.
    --- This calls the `Layout()` method from the control if it exists.  
    --- Remember, if a parent has an incomplete layout it will warn you anyway.
    ---@param self Layouter
    ---@return Control
    End = function(self)
        local control = self.layoutControl

        if ValidateLayouter then
            local pcall = pcall
            local ok, error = pcall(control.Top)
            if ok then ok, error = pcall(control.Bottom) end
            if ok then ok, error = pcall(control.Height) end
            if not ok then
                WARN("Incorrect layout for \"" .. control:GetName() .. "\" Top-Height-Bottom: " .. error)
            end

            ok, error = pcall(control.Left)
            if ok then ok, error = pcall(control.Right) end
            if ok then ok, error = pcall(control.Width) end
            if not ok then
                WARN("Incorrect layout for \"" .. control:GetName() .. "\" Left-Width-Right: " .. error)
            end
        end

        self.layoutControl = nil
        local layout = control.Layout
        if layout then
            layout(control)
        end

        return control
    end;
}


--- Returns a layouter for a control--you usually want to use `ReusedLayoutFor()` unless
--- you're doing some advanced interlacing of the layout. This calls `OnLayout()` from the control
--- if it exists. Make sure to call `End()` when you're done laying out the control (which calls
--- `Layout()` from the control if it exists).
---@param control Control
---@return Layouter
function LayoutFor(control)
    return Layouter(control)
end


local reusedLayouter = Layouter()
--- Returns the cached layouter applied to a control--this is usually what you want to use unless
--- you're doing some advanced interlacing of the layout. This calls `OnLayout()` from the control
--- if it exists. Make sure to call `End()` when you're done laying out the control (which calls
--- `Layout()` from the control if it exists).
---@param control Control
---@return Layouter #cached layouter
function ReusedLayoutFor(control)
    control = GetLayoutControl(control)
    local reusedLayouter = reusedLayouter
    local cur = reusedLayouter.layoutControl
    if cur then
        if cur == control then
            -- same object, probably some inherited laying out, let it go
            return reusedLayouter
        else
            -- uh-oh, someone is interlacing the default layouter!
            if ValidateLayouter then
                WARN(_TRACEBACK(1, "Reused layouter is already in use by " .. tostring(control) .. "! (did you forget to call `End()` or use the non-reused version?)"))
            end
            return Layouter(control)
        end
    end
    reusedLayouter:__init(control)
    return reusedLayouter
end
