--*****************************************************************************
--* File: lua/modules/maui/layouthelpers.lua
--* Author: Chris Blackwell
--* Summary: functions that make it simpler to set up control layouts.
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

--* Percentage versus offset
--* Percentages are specified as a float, with 0.00 to 1.00 the normal ranges
--* Percentages can change spacing when dimension is expended.
--*
--* Offsets are specified in pixels for the "base art" size. If the art is
--* scaled (ie large UI mode) this factor will keep the layout correct

--* Store and set the current pixel scale multiplier. This will be used when the
--* artwork is scaled up or down so that offsets scale up and down appropriately.
--* Note that if you add a new layout helper function that uses offsets, you need
--* to scale the offset with this factor or your layout may get funky when the
--* art is changed
local Prefs = import('/lua/user/prefs.lua')
local pixelScaleFactor = Prefs.GetFromCurrentProfile('options').ui_scale or 1

function SetPixelScaleFactor(newFactor)
    pixelScaleFactor = newFactor
end

function GetPixelScaleFactor()
    return pixelScaleFactor
end

--* These functions will set the controls position to be placed relative to
--* its parents dimensions. They are generally most useful for elements that
--* don't change size, they can also be used for controls that stretch
--* to match parent.

function AtCenterIn(control, parent, vertOffset, horzOffset)
    vertOffset = vertOffset or 0
    horzOffset = horzOffset or 0
    control.Left:Set(
        function()
            return math.floor(parent.Left() + (((parent.Width() / 2) - (control.Width() / 2)) + (horzOffset * pixelScaleFactor)))
        end)
    control.Top:Set(
        function()
            return math.floor(parent.Top() + (((parent.Height() / 2) - (control.Height() / 2)) + (vertOffset * pixelScaleFactor)))
        end)
end

function AtHorizontalCenterIn(control, parent, offset)
    offset = offset or 0
    control.Left:Set(
        function()
            return math.floor(parent.Left() + (((parent.Width() / 2) - (control.Width() / 2)) + (offset * pixelScaleFactor)))
        end)
end

function AtVerticalCenterIn(control, parent, offset)
    offset = offset or 0
    control.Top:Set(
        function()
            return math.floor(parent.Top() + (((parent.Height() / 2) - (control.Height() / 2)) + (offset * pixelScaleFactor)))
        end)
end

function AtLeftIn(control, parent, offset)
    offset = offset or 0
    control.Left:Set(function() return math.floor(parent.Left() + (offset * pixelScaleFactor)) end)
end

function AtRightIn(control, parent, offset)
    offset = offset or 0
    control.Right:Set(function() return math.floor(parent.Right() - (offset * pixelScaleFactor)) end)
end

function AtBottomIn(control, parent, offset)
    offset = offset or 0
    control.Bottom:Set(function() return math.floor(parent.Bottom() - (offset * pixelScaleFactor)) end)
end

function AtTopIn(control, parent, offset)
    offset = offset or 0
    control.Top:Set(function() return math.floor(parent.Top() + (offset * pixelScaleFactor)) end)
end

function AtLeftTopIn(control, parent, leftOffset, topOffset)
    leftOffset = leftOffset or 0
    topOffset = topOffset or 0
    control.Left:Set(function() return math.floor(parent.Left() + (leftOffset * pixelScaleFactor)) end)
    control.Top:Set(function() return math.floor(parent.Top() + (topOffset * pixelScaleFactor)) end)
end

function AtRightTopIn(control, parent, rightOffset, topOffset)
    rightOffset = rightOffset or 0
    topOffset = topOffset or 0
    control.Right:Set(function() return math.floor(parent.Right() - (rightOffset * pixelScaleFactor)) end)
    control.Top:Set(function() return math.floor(parent.Top() + (topOffset * pixelScaleFactor)) end)
end

--* these functions use percentages to place the item rather than offsets so they will
--* stay proportially spaced when the parent resizes
function FromLeftIn(control, parent, percent)
    percent = percent or 0.00
    control.Left:Set(function() return math.floor(parent.Left() + (parent.Width() * percent)) end)
end

function FromTopIn(control, parent, percent)
    percent = percent or 0.00
    control.Top:Set( function() return math.floor(parent.Top() + (parent.Height() * percent)) end)
end

function FromRightIn(control, parent, percent)
    percent = percent or 0.00
    control.Right:Set(function() return math.floor(parent.Right() - (parent.Width() * percent)) end)
end

function FromBottomIn(control, parent, percent)
    percent = percent or 0.00
    control.Bottom:Set( function() return math.floor(parent.Bottom() - (parent.Height() * percent)) end)
end

--* these functions will stretch the control to fill the parent and provide an optional border
function FillParent(control, parent)
    control.Top:Set(function() return parent.Top() end)
    control.Left:Set(function() return parent.Left() end)
    control.Bottom:Set(function() return parent.Bottom() end)
    control.Right:Set(function() return parent.Right() end)
end

function FillParentRelativeBorder(control, parent, percent)
    percent = percent or 0.00
    control.Top:Set(function() return math.floor(parent.Top() + (parent.Height() * percent)) end)
    control.Left:Set(function() return math.floor(parent.Left() + (parent.Width() * percent)) end)
    control.Bottom:Set(function() return math.floor(parent.Bottom() - (parent.Height() * percent)) end)
    control.Right:Set(function() return math.floor(parent.Right() - (parent.Width() * percent)) end)
end

function FillParentFixedBorder(control, parent, offset)
    offset = offset or 0
    control.Top:Set(function() return math.floor(parent.Top() + (offset * pixelScaleFactor)) end)
    control.Left:Set(function() return math.floor(parent.Left() + (offset * pixelScaleFactor)) end)
    control.Bottom:Set(function() return math.floor(parent.Bottom() - (offset * pixelScaleFactor)) end)
    control.Right:Set(function() return math.floor(parent.Right() - (offset * pixelScaleFactor)) end)
end

-- Fill the parent control while preserving the aspect ratio of the item
function FillParentPreserveAspectRatio(control, parent)
    local function GetRatio(control, parent)
        local ratio = parent.Height() / control.Height()
        if ratio * control.Width() > parent.Width() then
            ratio = parent.Width() / control.Width()
        end
        return ratio
    end
    
    control.Top:Set(function() return 
        math.floor(parent.Top() + ((parent.Height() - (control.Height() * GetRatio(control, parent))) / 2))
    end)     
    control.Bottom:Set(function()
        return math.floor(parent.Bottom() - ((parent.Height() - (control.Height() * GetRatio(control, parent))) / 2))
    end)     
    control.Left:Set(function()
        return math.floor(parent.Left() + ((parent.Width() - (control.Width() * GetRatio(control, parent))) / 2))
    end)     
    control.Right:Set(function()
        return math.floor(parent.Right() - ((parent.Width() - (control.Width() * GetRatio(control, parent))) / 2))
    end)     
end

--* these functions will place the control and resize in a specified location within the parent
--* note that the offset version is more useful than hard coding the location
--* as it will take advantage of the pixel scale factor
function PercentIn(control, parent, left, top, right, bottom)
    leftOffset = left or 0.00
    topOffset = top or 0.00
    rightOffset = right or 0.00
    bottomOffset = bottom or 0.00

    control.Left:Set(function() return math.floor(parent.Left() + (left * parent.Width())) end)
    control.Top:Set(function() return math.floor(parent.Top() + (top * parent.Height())) end)
    control.Right:Set(function() return math.floor(parent.Left() + (right * parent.Width())) end)
    control.Bottom:Set(function() return math.floor(parent.Top() + (bottom * parent.Height())) end)
end

function OffsetIn(control, parent, left, top, right, bottom)
    leftOffset = left or 0
    topOffset = top or 0
    rightOffset = right or 0
    bottomOffset = bottom or 0

    control.Left:Set(function() return math.floor(parent.Left() + (left * pixelScaleFactor)) end)
    control.Top:Set(function() return math.floor(parent.Top() + (top * pixelScaleFactor)) end)
    control.Right:Set(function() return math.floor(parent.Left() + (right * pixelScaleFactor)) end)
    control.Bottom:Set(function() return math.floor(parent.Top() + (bottom * pixelScaleFactor)) end)
end

--* these functions will set the controls position relative to a sibling

--* lock right top of control to left top of parent
function LeftOf(control, parent, offset)
    offset = offset or 0
    control.Right:Set(function() return math.floor(parent.Left() - (offset * pixelScaleFactor)) end)
    control.Top:Set(function() return parent.Top() end)
end

--* lock left top of control to right top of parent
function RightOf(control, parent, offset)
    offset = offset or 0
    control.Left:Set(function() return math.floor(parent.Right() + (offset * pixelScaleFactor)) end)
    control.Top:Set(function() return parent.Top() end)
end

--* lock right top of control to left of parent, cenetered vertically to the parent
function CenteredLeftOf(control, parent, offset)
    offset = offset or 0
    control.Right:Set(function() return math.floor(parent.Left() - (offset * pixelScaleFactor)) end)
    control.Top:Set(function() return math.floor(parent.Top() + ((parent.Height() / 2) - (control.Height() / 2))) end)
end

--* lock left top of control to right of parent, centered vertically to the parent
function CenteredRightOf(control, parent, offset)
    offset = offset or 0
    control.Left:Set(function() return math.floor(parent.Right() + (offset * pixelScaleFactor)) end)
    control.Top:Set(function() return math.floor(parent.Top() + ((parent.Height() / 2) - (control.Height() / 2))) end)
end

--* lock bottom left of control to top left of parent
function Above(control, parent, offset)
    offset = offset or 0
    control.Left:Set(function() return parent.Left() end)
    control.Bottom:Set(function() return parent.Top() - (offset * pixelScaleFactor) end)
end

--* lock top left of control to bottom left of parent
function Below(control, parent, offset)
    offset = offset or 0
    control.Left:Set(function() return parent.Left() end)
    control.Top:Set(function() return math.floor(parent.Bottom() + (offset * pixelScaleFactor)) end)
end

--* lock bottom left of control to top left of parent, centered horizontally to the parent
function CenteredAbove(control, parent, offset)
    offset = offset or 0
    control.Left:Set(function() return math.floor(parent.Left() + ((parent.Width() / 2) - (control.Width() / 2))) end)
    control.Bottom:Set(function() return math.floor(parent.Top() - (offset * pixelScaleFactor)) end)
end

--* lock top left of control to bottom left of parent, centered horizontally to the parent
function CenteredBelow(control, parent, offset)
    offset = offset or 0
    control.Left:Set(function() return math.floor(parent.Left() + ((parent.Width() / 2) - (control.Width() / 2))) end)
    control.Top:Set(function() return math.floor(parent.Bottom() + (offset * pixelScaleFactor)) end)
end

-- anchor functions lock the appropriate side of a control to the side of another control
-- lock top of control to parent bottom
function AnchorToTop(control, parent, offset)
    offset = offset or 0
    control.Bottom:Set(function() return math.floor(parent.Top() - (offset * pixelScaleFactor)) end)
end

-- lock bottom of control parent top
function AnchorToBottom(control, parent, offset)
    offset = offset or 0
    control.Top:Set(function() return math.floor(parent.Bottom() + (offset * pixelScaleFactor)) end)
end

-- lock left of control to parent right
function AnchorToRight(control, parent, offset)
    offset = offset or 0
    control.Left:Set(function() return math.floor(parent.Right() + (offset * pixelScaleFactor)) end)
end

-- lock right of control to parent left
function AnchorToLeft(control, parent, offset)
    offset = offset or 0
    control.Right:Set(function() return math.floor(parent.Left() - (offset * pixelScaleFactor)) end)
end

--* Reset to the default layout functions
function Reset(control)
    control.Left:Set(function() return control.Right() - control.Width() end)
    control.Top:Set(function() return control.Bottom() - control.Height() end)
    control.Right:Set(function() return control.Left() + control.Width() end)
    control.Bottom:Set(function() return control.Top() + control.Height() end)
    control.Width:Set(function() return control.Right() - control.Left() end)
    control.Height:Set(function() return control.Bottom() - control.Top() end)
end

function ResetLeft(control)
    control.Left:Set(function() return control.Right() - control.Width() end)
end

function ResetTop(control)
    control.Top:Set(function() return control.Bottom() - control.Height() end)
end

function ResetRight(control)
    control.Right:Set(function() return control.Left() + control.Width() end)
end

function ResetBottom(control)
    control.Bottom:Set(function() return control.Top() + control.Height() end)
end

function ResetWidth(control)
    control.Width:Set(function() return control.Right() - control.Left() end)
end

function ResetHeight(control)
    control.Height:Set(function() return control.Bottom() - control.Top() end)
end

--[[
The following functions use layout files created with the Maui Photoshop Exporter to position controls
Layout files contain a single table in this format:

layout = {
    {control_name_1 = {left = 0, top = 0, width = 100, height = 100,},
    {control_name_2 = {left = 0, top = 0, width = 100, height = 100,},
}

inputs are:
    control - the control to position
    parent - the control that the above is positioned relative to
    fileName - the full path and filename of the layout file. must be a lazy var or function that returns the file name
    controlName - the name( table key) of the control to be positioned
    parentName - the name (table key) of the control to be positioned relative to
    topOffset and leftOffset are optional
--]]

function RelativeTo(control, parent, fileName, controlName, parentName, topOffset, leftOffset)
    local layoutTable = import(fileName()).layout
    if not layoutTable[controlName] then
        WARN("Control not found in layout table: " .. controlName)
    end
    if not layoutTable[parentName] then
        WARN("Parent not found in layout table: " .. parentName)
    end
    control.Left:Set(function()
        local layoutTable = import(fileName()).layout
        return math.floor(parent.Left() + (layoutTable[controlName].left - layoutTable[parentName].left + ((leftOffset or 0) * pixelScaleFactor)))
    end)

    control.Top:Set(function()
        local layoutTable = import(fileName()).layout
        return math.floor(parent.Top() + (layoutTable[controlName].top - layoutTable[parentName].top + ((topOffset or 0) * pixelScaleFactor)))
    end)
end


function LeftRelativeTo(control, parent, fileName, controlName, parentName)
    local layoutTable = import(fileName()).layout
    if not layoutTable[controlName] then
        WARN("Control not found in layout table: " .. controlName)
    end
    if not layoutTable[parentName] then
        WARN("Parent not found in layout table: " .. parentName)
    end
    control.Left:Set(function()
        local layoutTable = import(fileName()).layout
        return math.floor(parent.Left() + (layoutTable[controlName].left - layoutTable[parentName].left))
    end)
end

function TopRelativeTo(control, parent, fileName, controlName, parentName)
    local layoutTable = import(fileName()).layout
    if not layoutTable[controlName] then
        WARN("Control not found in layout table: " .. controlName)
    end
    if not layoutTable[parentName] then
        WARN("Parent not found in layout table: " .. parentName)
    end
    control.Top:Set(function()
        local layoutTable = import(fileName()).layout
        return math.floor(parent.Top() + (layoutTable[controlName].top - layoutTable[parentName].top))
    end)
end

function RightRelativeTo(control, parent, fileName, controlName, parentName)
    local layoutTable = import(fileName()).layout
    if not layoutTable[controlName] then
        WARN("Control not found in layout table: " .. controlName)
    end
    if not layoutTable[parentName] then
        WARN("Parent not found in layout table: " .. parentName)
    end
    control.Right:Set(function()
        local layoutTable = import(fileName()).layout
        return math.floor(parent.Right() - ((layoutTable[parentName].left + layoutTable[parentName].width) - (layoutTable[controlName].left + layoutTable[controlName].width)))
    end)
end

function BottomRelativeTo(control, parent, fileName, controlName, parentName)
    local layoutTable = import(fileName()).layout
    if not layoutTable[controlName] then
        WARN("Control not found in layout table: " .. controlName)
    end
    if not layoutTable[parentName] then
        WARN("Parent not found in layout table: " .. parentName)
    end
    control.Bottom:Set(function()
        local layoutTable = import(fileName()).layout
        return math.floor(parent.Bottom() - ((layoutTable[parentName].top + layoutTable[parentName].height) - (layoutTable[controlName].top + layoutTable[controlName].height)))
    end)
end

function DimensionsRelativeTo(control, fileName, controlName)
    local layoutTable = import(fileName()).layout
    if not layoutTable[controlName] then
        WARN("Control not found in layout table: " .. controlName)
    end
    control.Width:Set(function()
        local layoutTable = import(fileName()).layout
        return math.floor(layoutTable[controlName].width * pixelScaleFactor)
    end)
    control.Height:Set(function()
        local layoutTable = import(fileName()).layout
        return math.floor(layoutTable[controlName].height * pixelScaleFactor)
    end)
end

--* set the dimensions
function SetDimensions(control, width, height)
    if width then
        control.Width:Set(function()
            return math.floor(width * pixelScaleFactor)
        end)
    end
    
    if height then
        control.Height:Set(function()
            return math.floor(height * pixelScaleFactor)
        end)
    end
end

function SetWidth(control, width)
    if width then
        control.Width:Set(function()
            return math.floor(width * pixelScaleFactor)
        end)
    end
end

function SetHeight(control, height)
    if height then
        control.Height:Set(function()
            return math.floor(height * pixelScaleFactor)
        end)
    end
end

--* set the depth relative to the parent
function DepthOverParent(control, parent, depth)
    depth = depth or 1
    control.Depth:Set(function() return parent.Depth() + depth end)
end

function DepthUnderParent(control, parent, depth)
    depth = depth or 1
    control.Depth:Set(function() return parent.Depth() - depth end)
end

-- Scale according to the globally set ratio 
function Scale(control)
    SetDimensions(control, control.Width(), control.Height())
end

function ScaleNumber(number)
    return math.floor(number * pixelScaleFactor)
end