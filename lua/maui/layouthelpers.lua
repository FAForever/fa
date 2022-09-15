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
---@param width? number no change if nil
function SetWidth(control, width)
    if width then
        control.Width:SetValue(MathFloor(width * pixelScaleFactor))
    end
end

--- Sets fixed height of a control, scaled by the pixel scale factor
---@param control Control
---@param height? number no change if nil
function SetHeight(control, height)
    if height then
        control.Height:SetValue(MathFloor(height * pixelScaleFactor))
    end
end

--- Sets fixed dimensions of a control, scaled by the pixel scale factor
---@param control Control
---@param width? number no change if nil
---@param height? number no change if nil
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
---@param filename FileName | fun(): FileName
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
---@param filename FileName | fun(): FileName
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
        local width = GetTextureDimensions(filename())
        if padding then
            width = width + ScaleNumber(padding)
        end
        control.Width:SetValue(MathFloor(width))
    end
end

--- Set a control's dimensions to the dimensions of a texture (with an optional border)
---@param control Control
---@param filename FileName | fun(): FileName
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
-- Layouter
--------------------------------------------------------------------------------

-- An extremely helpful design pattern for laying out components, it is intended to make
-- UI code readable, maintainable, robust, and easily diagnosable
--
-- To use it, start by localizing this function at the top of your UI file
--[[
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
-- skin changes (either by it rotating or different faction being skinned).
--
-- (Calling `Layouter` also calls a control's `OnLayout()` method, but you shouldn't need to use
-- that unless there's some dynamic component instantiation going on that requires external data)
--
-- Thus, the UI class might end up looking something like this:
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
-- component in their layout, or to create a top-level creation function for singleton classes
-- like this:
--[[
local GUI = false

function Create(parent)
    local component = GUI
    if component then
        return component
    end
    component = Layouter(UIComponent(parent))
        :AtTopLeftIn(parent)
        :Width(364)
        :Height(180)
        :End()

    GUI = component
    return component
end
--]]
-- Do not try to layout more than control at a time; it is confusing and will break the default
-- layouter. However, should it be absolutely necessary (e.g. for UIUtils that may not create a
-- control with a valid hierarchy), you can explicitly call `LayoutHelpers.LayoutFor(...)` to create
-- separate layouter objects.

---@class Layouter
---@field c Control
local LayouterMetaTable = {}
LayouterMetaTable.__index = LayouterMetaTable

function LayouterMetaTable:__newindex(key, value)
    error("attempt to set new index for a Layouter object")
end

-- Gets the control
---@return Control c
function LayouterMetaTable:Get()
    return self.c
end

--- Computes the control's properties and returns it.
--- This calls the `Layout()` method from the control if it exists.  
--- Remember, if a parent has an incomplete layout it will warn you anyway.
---@return Control
function LayouterMetaTable:End()
    local control = self.c

    if not pcall(control.Top) or not pcall(control.Bottom) or not pcall(control.Height) then
        WARN(_TRACEBACK(1, "Incorrect layout for \"" .. control:GetName() .. "\" Top-Height-Bottom"))
    end
    if not pcall(control.Left) or not pcall(control.Right) or not pcall(control.Width) then
        WARN(_TRACEBACK(1, "Incorrect layout for \"" .. control:GetName() .. "\" Left-Width-Right"))
    end

    self.c = false
    local layout = control.Layout
    if layout then
        layout(control)
    end

    return control
end


--- Returns a layouter for a control--you usually want the reused version unless you're doing some
--- advanced interlacing of the layout. This calls `OnLayout()` from the control if it exists.
--- Make sure to call `End()` when you're done laying out the control (which calls `Layout()` from
--- the control if it exists).
---@param control Control
---@return Layouter
function LayoutFor(control)
    if control == nil then
        control = false -- key needs to exist to not trigger the `__newindex` error
    else
        local onLayout = control.OnLayout
        if onLayout then
            onLayout(control)
        end
    end
    local result = {
        c = control
    }
    setmetatable(result, LayouterMetaTable)

    return result
end

local reusedLayouter = LayoutFor()
--- Returns the cached layouter applied to a control--this is usually what you want to use unless
--- you're doing some advanced interlacing of the layout. This calls `OnLayout()` from the control
--- if it exists. Make sure to call `End()` when you're done laying out the control (which calls
--- `Layout()` from the control if it exists).
---@param control Control
---@return Layouter #cached layouter
function ReusedLayoutFor(control)
    local reusedLayouter = reusedLayouter
    do
        local cur = reusedLayouter.c
        if cur then
            if cur == control then
                -- probably some inherited laying out
                return reusedLayouter
            else
                -- uh-oh, someone is interlacing the default layouter!
                WARN(_TRACEBACK(1, "Reused layouter is already in use! (did you forget to call `End()` or use the non-reused version?)"))
            end
        end
    end
    reusedLayouter.c = control

    local onLayout = control.OnLayout
    if onLayout then
        onLayout(control)
    end
    return reusedLayouter
end



------------------------------
-- Property Setters
------------------------------

--- Sets the name of the control
---@param debugName string
---@return Layouter
function LayouterMetaTable:Name(debugName)
    self.c:SetName(debugName)
    return self
end

--- Disables the control
---@return Layouter
function LayouterMetaTable:Disable()
    self.c:Disable()
    return self
end

--- Hides the control
---@return Layouter
function LayouterMetaTable:Hide()
    self.c:Hide()
    return self
end

--- Sets the color of the control
---@param color string color as a hexcode
---@return Layouter
function LayouterMetaTable:Color(color)
    local control = self.c
    if control.SetSolidColor then
        control:SetSolidColor(color)
    elseif control.SetColor then
        control:SetColor(color)
    else
        WARN(string.format("Unable to set color for control \"%s\"", control:GetName()))
    end
    return self
end

--- Sets the font of the control
---@param font function | string
---@param size number
---@return Layouter
function LayouterMetaTable:Font(font, size)
    self.c:SetFont(font, size)
    return self
end

--- Sets if the control has a drop shadow
---@param hasShadow boolean
---@return Layouter
function LayouterMetaTable:DropShadow(hasShadow)
    self.c:SetDropShadow(hasShadow)
    return self
end

--- Sets the control's texture
---@param texture string resource location
---@param border? Border
---@return Layouter
function LayouterMetaTable:Texture(texture, border)
    self.c:SetTexture(texture, border)
    return self
end

--- Enables the control's hit test
---@param isRecursive? boolean
---@return Layouter
function LayouterMetaTable:EnableHitTest(isRecursive)
    self.c:EnableHitTest(isRecursive)
    return self
end

--- Disables the control's hit test
---@param isRecursive? boolean
---@return Layouter
function LayouterMetaTable:DisableHitTest(isRecursive)
    self.c:DisableHitTest(isRecursive)
    return self
end

--- Sets if the control needs a frame update
---@param needsUpdate boolean
---@return Layouter
function LayouterMetaTable:NeedsFrameUpdate(needsUpdate)
    self.c:SetNeedsFrameUpdate(needsUpdate)
    return self
end

--- Sets the alpha of the control
---@param alpha number
---@param forChildren? boolean
---@return Layouter
function LayouterMetaTable:Alpha(alpha, forChildren)
    self.c:SetAlpha(alpha, forChildren)
    return self
end


----------
-- Positional setters
----------

-- Raw setting
---@alias lazyvarType LazyVar | function | number

--- Sets the left edge of the control
---@param left lazyvarType
---@return Layouter
function LayouterMetaTable:Left(left)
    self.c.Left:Set(left)
    return self
end

--- Sets the top edge of the control
---@param top lazyvarType
---@return Layouter
function LayouterMetaTable:Top(top)
    self.c.Top:Set(top)
    return self
end

--- Sets the right edge of the control
---@param right lazyvarType
---@return Layouter
function LayouterMetaTable:Right(right)
    self.c.Right:Set(right)
    return self
end

--- Sets the bottom edge of the control
---@param bottom lazyvarType
---@return Layouter
function LayouterMetaTable:Bottom(bottom)
    self.c.Bottom:Set(bottom)
    return self
end


----------
-- Dimensional setters
----------

--- Sets the width of the control
---@param width lazyvarType if a number, width will be scaled by the pixel factor
---@return Layouter
function LayouterMetaTable:Width(width)
    local controlWidth = self.c.Width
    if iscallable(width) then
        controlWidth:SetFunction(width)
    else
        controlWidth:SetValue(ScaleNumber(width))
    end
    return self
end

--- Sets the height of the control
---@param height lazyvarType #if a number, height will be scaled by the pixel factor
---@return Layouter
function LayouterMetaTable:Height(height)
    local controlHeight = self.c.Height
    if iscallable(height) then
        controlHeight:SetFunction(height)
    else
        controlHeight:SetValue(ScaleNumber(height))
    end
    return self
end

---@param filename FileName | fun(): FileName
---@param border? number
---@return Layouter
function LayouterMetaTable:WidthFromTexture(filename, border)
    SetWidthFromTexture(self.c, filename, border)
    return self
end

---@param filename FileName | fun(): FileName
---@param border? number
---@return Layouter
function LayouterMetaTable:HeightFromTexture(filename, border)
    SetHeightFromTexture(self.c, filename, border)
    return self
end

---@param filename FileName | fun(): FileName
---@param border? number
---@return Layouter
function LayouterMetaTable:DimensionsFromTexture(filename, border)
    SetDimensionsFromTexture(self.c, filename, border)
    return self
end


----------
-- Depth setters
----------

--- Sets depth of the control to be above a parent
---@param parent Control
---@param depth? integer defaults to 1
---@return Layouter
function LayouterMetaTable:Over(parent, depth)
    DepthOverParent(self.c, parent, depth)
    return self
end


--- Sets depth of the control to be below a parent
---@param parent Control
---@param depth? integer defaults to 1
---@return Layouter
function LayouterMetaTable:Under(parent, depth)
    DepthUnderParent(self.c, parent, depth)
    return self
end


------------------------------
-- Single positioning methods
------------------------------

----------
-- Reset methods
----------

--- Resets the control's left edge to be calculated from its right edge and width.  
--- Make sure `control.Right` and `control.Width` are not reset.
---@return Layouter
function LayouterMetaTable:ResetLeft()
    ResetLeft(self.c)
    return self
end

--- Resets the control's top edge to be calculated from its bottom edge and height.  
--- Make sure `control.Bottom` and `control.Height` are not reset.
---@return Layouter
function LayouterMetaTable:ResetTop()
    ResetTop(self.c)
    return self
end

--- Resets the control's right edge to be calculated from its left edge and width.  
--- Make sure `control.Left` and `control.Width` are not reset.
---@return Layouter
function LayouterMetaTable:ResetRight()
    ResetRight(self.c)
    return self
end

--- Resets the control's bottom edge to be calculated from its top edge and height.  
--- Make sure `control.Top` and `control.Height` are not reset.
---@return Layouter
function LayouterMetaTable:ResetBottom()
    ResetBottom(self.c)
    return self
end

--- Resets the control's width to be calculated from its left and right edges.  
--- Make sure `control.Left` and `control.Right` are not reset.
---@return Layouter
function LayouterMetaTable:ResetWidth()
    ResetWidth(self.c)
    return self
end

--- Resets the control's height to be calculated from its top and bottom edges.  
--- Make sure `control.Top` and `control.Bottom` are not reset.
---@return Layouter
function LayouterMetaTable:ResetHeight()
    ResetHeight(self.c)
    return self
end


----------
-- Anchor methods
----------

--- Anchors the control's right edge to the left edge of a parent, with optional padding
---@param parent Control
---@param padding? number fixed padding between control and parent, scaled by the pixel scale factor
---@return Layouter
function LayouterMetaTable:AnchorToLeft(parent, padding)
    AnchorToLeft(self.c, parent, padding)
    return self
end

--- Anchors the control's bottom edge to the top edge of a parent, with optional padding
---@param parent Control
---@param padding? number fixed padding between control and parent, scaled by the pixel scale factor
---@return Layouter
function LayouterMetaTable:AnchorToTop(parent, padding)
    AnchorToTop(self.c, parent, padding)
    return self
end

--- Anchors the control's left edge to the right edge of a parent, with optional padding
---@param parent Control
---@param padding? number fixed padding between control and parent, scaled by the pixel scale factor
---@return Layouter
function LayouterMetaTable:AnchorToRight(parent, padding)
    AnchorToRight(self.c, parent, padding)
    return self
end

--- Anchors the control's top edge to the bottom edge of a parent, with optional padding
---@param parent Control
---@param padding? number fixed padding between control and parent, scaled by the pixel scale factor
---@return Layouter
function LayouterMetaTable:AnchorToBottom(parent, padding)
    AnchorToBottom(self.c, parent, padding)
    return self
end


----------
-- Inside offset methods
----------

--- Centers the control horizontally on a parent, with optional rightward offset.
--- This sets the control's left edge.
---@param parent Control
---@param leftOffset? number Offset of control's left edge in the rightward direction, scaled by the pixel scale factor. Defaults to 0.
---@return Layouter
function LayouterMetaTable:AtHorizontalCenterIn(parent, leftOffset)
    AtHorizontalCenterIn(self.c, parent, leftOffset)
    return self
end

--- Centers the control vertically on a parent, with optional downward offset.
--- This sets the control's top edge.
---@param parent Control
---@param topOffset? number Offset of the control's top edge in the downward direction, scaled by the pixel scale factor. Defaults to 0.
---@return Layouter
function LayouterMetaTable:AtVerticalCenterIn(parent, topOffset)
    AtVerticalCenterIn(self.c, parent, topOffset)
    return self
end

--- Places the control's left edge inside of a parent's, with optional rightward offset
---@param parent Control
---@param leftOffset? number Offset of the control's left edge in the rightward direction, scaled by the pixel scale factor. Defaults to 0.
---@return Layouter
function LayouterMetaTable:AtLeftIn(parent, leftOffset)
    AtLeftIn(self.c, parent, leftOffset)
    return self
end

--- Places the control's top edge inside of a parent's, with optional downward offset
---@param parent Control
---@param topOffset? number Offset of the control's top edge in the downward direction, scaled by the pixel scale factor. Defaults to 0.
---@return Layouter
function LayouterMetaTable:AtTopIn(parent, topOffset)
    AtTopIn(self.c, parent, topOffset)
    return self
end

--- Places the control's right edge inside of a parent's, with optional leftward offset
---@param parent Control
---@param rightOffset? number Offset of the control's right edge in the leftward direction, scaled by the pixel scale factor. Defaults to 0.
---@return Layouter
function LayouterMetaTable:AtRightIn(parent, rightOffset)
    AtRightIn(self.c, parent, rightOffset)
    return self
end

--- Places the control's bottom edge inside of a parent's, with optional upward offset
---@param parent Control
---@param bottomOffset? number Offset of the control's bottom edge in the upward direction, scaled by the pixel scale factor. Defaults to 0.
---@return Layouter
function LayouterMetaTable:AtBottomIn(parent, bottomOffset)
    AtBottomIn(self.c, parent, bottomOffset)
    return self
end


----------
-- Inside percentage methods
----------

--- Places the control's left edge at a percentage along the width of a parent,
--- with 0.00 at the parent's left edge
---@param parent Control
---@param leftPercent? number defaults to 0.00 (all the way to left)
function LayouterMetaTable:FromLeftIn(parent, leftPercent)
    FromLeftIn(self.c, parent, leftPercent)
    return self
end

--- Places the control's top edge at a percentage along the height of a parent,
--- with 0.00 at the parent's top edge
---@param parent Control
---@param topPercent? number defaults to 0.00 (all the way at the top)
function LayouterMetaTable:FromTopIn(parent, topPercent)
    FromTopIn(self.c, parent, topPercent)
    return self
end

--- Places the control's right edge at a percentage along the width of a parent,
--- with 0.00 at the parent's right edge
---@param parent Control
---@param rightPercent? number defaults to 0.00 (all the way right)
function LayouterMetaTable:FromRightIn(parent, rightPercent)
    FromRightIn(self.c, parent, rightPercent)
    return self
end

--- Places the control's bottom edge at a percentage along the height of a parent,
--- with 0.00 at the parent's bottom edge
---@param parent Control
---@param bottomPercent? number defaults to 0.00 (all the way at the bottom)
function LayouterMetaTable:FromBottomIn(parent, bottomPercent)
    FromBottomIn(self.c, parent, bottomPercent)
    return self
end


----------
-- Inside space methods
----------

--- Places the control's left edge a percentage along the horizontal space of a parent
--- with 0.00 at the parent's left edge (this requires the control's width to be set)
---@param parent Control
---@param leftPercent? number
---@return Layouter
function LayouterMetaTable:FromLeftWith(parent, leftPercent)
    FromLeftWith(self.c, parent, leftPercent)
    return self
end

--- Places the control's top edge a percentage along the vertical space of a parent
--- with 0.00 at the parent's top edge (this requires the control's height to be set)
---@param parent Control
---@param topPercent? number
---@return Layouter
function LayouterMetaTable:FromTopWith(parent, topPercent)
    FromTopWith(self.c, parent, topPercent)
    return self
end

--- Places the control's right edge a percentage along the horizontal space of a parent
--- with 0.00 at the parent's right edge (this requires the control's width to be set)
---@param parent Control
---@param rightPercent? number
---@return Layouter
function LayouterMetaTable:FromRightWith(parent, rightPercent)
    FromRightWith(self.c, parent, rightPercent)
    return self
end

--- Places the control's bottom edge a percentage along the vertical space of a parent
--- with 0.00 at the parent's bottom edge (this requires the control's height to be set)
---@param parent Control
---@param bottomPercent? number
---@return Layouter
function LayouterMetaTable:FromBottomWith(parent, bottomPercent)
    FromBottomWith(self.c, parent, bottomPercent)
    return self
end



------------------------------
-- Double positioning methods
------------------------------

--- Places the control in the center of the parent, with optional offsets.
--- This sets the control's left and top edges.  
--- Note the argument order.
---@param parent Control
---@param topOffset? number offset of top edge in downward direction, scaled by the pixel scale factor
---@param leftOffset? number offset of left edge in rightward direction, scaled by the pixel scale factor
---@return Layouter
function LayouterMetaTable:AtCenterIn(parent, topOffset, leftOffset)
    AtCenterIn(self.c, parent, topOffset, leftOffset)
    return self
end


----------
-- Outside edge positioning methods
----------

--- Lock right edge of the control to the left edge of a parent, centered vertically.
--- This sets the control's right and top edges.
---@param parent Control
---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
---@return Layouter
function LayouterMetaTable:CenteredLeftOf(parent, padding)
    CenteredLeftOf(self.c, parent, padding)
    return self
end

--- Lock bottom edge of the control to the top edge of a parent, centered horizontally.
--- This sets the control's left and bottom edges.
---@param parent Control
---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
---@return Layouter
function LayouterMetaTable:CenteredAbove(parent, padding)
    CenteredAbove(self.c, parent, padding)
    return self
end

--- Lock left edge of the control to the right edge of a parent, centered vertically.
--- This sets the control's left and top edges.
---@param parent Control
---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
---@return Layouter
function LayouterMetaTable:CenteredRightOf(parent, padding)
    CenteredRightOf(self.c, parent, padding)
    return self
end

--- Lock top edge of the control to the bottom edge of parent, centered horizontally.
--- This sets the controls's left and top edges.
---@param parent Control
---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
---@return Layouter
function LayouterMetaTable:CenteredBelow(parent, padding)
    CenteredBelow(self.c, parent, padding)
    return self
end


----------
-- Inside positioning methods
----------

--- Places left edge of the control vertically centered inside of a parent's, with optional offsets.
--- This sets the control's left and top edges.
---@param parent Control
---@param leftOffset? number offset of the control's left edge in the rightward direction, scaled by the pixel scale factor
---@param topOffset? number offset of the control's top edge in the downward direction, scaled by the pixel scale factor
---@return Layouter
function LayouterMetaTable:AtLeftCenterIn(parent, leftOffset, topOffset)
    AtLeftCenterIn(self.c, parent, leftOffset, topOffset)
    return self
end

--- Places top left corner of the control inside of a parent's, with optional offsets
---@param parent Control
---@param leftOffset? number offset of the control's left edge in the rightward direction, scaled by the pixel scale factor
---@param topOffset? number offset of the control's top edge in the downward direction, scaled by the pixel scale factor
---@return Layouter
function LayouterMetaTable:AtLeftTopIn(parent, leftOffset, topOffset)
    AtLeftTopIn(self.c, parent, leftOffset, topOffset)
    return self
end

--- Places top edge of the control horizontally centered inside of a parent's, with optional offsets.
--- Sets the control's left and top edges.  
--- Note the argument order.
---@param parent Control
---@param topOffset? number offset of the control's top edge in the downward direction, scaled by the pixel scale factor
---@param leftOffset? number offset of the control's left edge in the rightward direction, scaled by the pixel scale factor
---@return Layouter
function LayouterMetaTable:AtTopCenterIn(parent, topOffset, leftOffset)
    AtTopCenterIn(self.c, parent, topOffset, leftOffset)
    return self
end

--- Places top right corner of the control inside of a parent's, with optional offsets
---@param parent Control
---@param rightOffset? number offset of the control's right edge in the leftward direction, scaled by the pixel scale factor
---@param topOffset? number offset of the control's top edge in the downward direction, scaled by the pixel scale factor
---@return Layouter
function LayouterMetaTable:AtRightTopIn(parent, rightOffset, topOffset)
    AtRightTopIn(self.c, parent, rightOffset, topOffset)
    return self
end

--- Places right edge of the control vertically centered inside of a parent's, with optional offsets.
--- Sets the control's right and top edges.
---@param parent Control
---@param rightOffset? number offset of the control's right edge in the leftward direction, scaled by the pixel scale factor
---@param topOffset? number offset of the control's top edge in the downward direction, scaled by the pixel scale factor
---@return Layouter
function LayouterMetaTable:AtRightCenterIn(parent, rightOffset, topOffset)
    AtRightCenterIn(self.c, parent, rightOffset, topOffset)
    return self
end

--- Places bottom right corner of the control inside of a parent's, with optional offsets
---@param parent Control
---@param rightOffset? number offset of the control's right edge in the leftward direction, scaled by the pixel scale factor
---@param bottomOffset? number offset of the control's bottom edge in the upward direction, scaled by the pixel scale factor
---@return Layouter
function LayouterMetaTable:AtRightBottomIn(parent, rightOffset, bottomOffset)
    AtRightBottomIn(self.c, parent, rightOffset, bottomOffset)
    return self
end

--- Places bottom edge of the control horizontally centered inside of a parent's, with optional offsets.
--- Sets the control's left and bottom edges.  
--- Note the argument order.
---@param parent Control
---@param leftOffset? number offset of the control's left edge in the rightward direction, scaled by the pixel scale factor
---@param bottomOffset? number offset of the control's bottom edge in the upward direction, scaled by the pixel scale factor
---@return Layouter
function LayouterMetaTable:AtBottomCenterIn(parent, bottomOffset, leftOffset)
    AtBottomCenterIn(self.c, parent, bottomOffset, leftOffset)
    return self
end

--- Places bottom left corner of the control inside of a parent's, with optional offsets
---@param parent Control
---@param leftOffset? number offset of the control's left edge in the rightward direction, scaled by the pixel scale factor
---@param bottomOffset? number offset of the control's bottom edge in the upward direction, scaled by the pixel scale factor
---@return Layouter
function LayouterMetaTable:AtLeftBottomIn(parent, leftOffset, bottomOffset)
    AtLeftBottomIn(self.c, parent, leftOffset, bottomOffset)
    return self
end


----------
-- Flow-positioning methods
----------

--- Lock top right of the control to the top left of a parent
---@param parent Control
---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
---@return Layouter
function LayouterMetaTable:LeftOf(parent, padding)
    LeftOf(self.c, parent, padding)
    return self
end

--- Lock top left of the control to the top right of a parent
---@param parent Control
---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
---@return Layouter
function LayouterMetaTable:RightOf(parent, padding)
    RightOf(self.c, parent, padding)
    return self
end

--- Lock bottom left of the control to the top left of a parent
---@param parent Control
---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
---@return Layouter
function LayouterMetaTable:Above(parent, padding)
    Above(self.c, parent, padding)
    return self
end

--- Lock top left of the control to the bottom left of a parent
---@param parent Control
---@param padding? number Fixed padding between control and parent, scaled by the pixel scale factor. Defaults to 0.
---@return Layouter
function LayouterMetaTable:Below(parent, padding)
    Below(self.c, parent, padding)
    return self
end



------------------------------
-- Axial methods
------------------------------

--- Sets a control to fill the horizontal space of a parent
function LayouterMetaTable:FillHorizontally(parent)
    FillHorizontally(self.c, parent)
    return self
end

--- Sets a control to fill the vertical space of a parent
function LayouterMetaTable:FillVertically(parent)
    FillVertically(self.c, parent)
    return self
end



------------------------------
-- Composite methods
------------------------------

--- Sets all edges of a control to be a certain amount inside of a parent.
--- Offsets are optional and scaled by the pixel scale factor.
---@param parent Control
---@param left? number
---@param top? number
---@param right? number
---@param bottom? number
function LayouterMetaTable:OffsetIn(parent, left, top, right, bottom)
    OffsetIn(self.c, parent, left, top, right, bottom)
    return self
end

--- Sets all edges of the control to be a certain percentage inside of a parent.
--- Percentages are optional.
---@param parent Control
---@param left? number
---@param top? number
---@param right? number
---@param bottom? number
---@return Layouter
function LayouterMetaTable:PercentIn(parent, left, top, right, bottom)
    PercentIn(self.c, parent, left, top, right, bottom)
    return self
end


----------
-- Fill methods
----------

--- Sets the control to fill a parent
---@param parent Control
---@return Layouter
function LayouterMetaTable:Fill(parent)
    FillParent(self.c, parent)
    return self
end

--- Sets the control to fill a parent's with fixed padding
---@param parent Control
---@param offset? number
---@return Layouter
function LayouterMetaTable:FillFixedBorder(parent, offset)
    FillParentFixedBorder(self.c, parent, offset)
    return self
end

