--*****************************************************************************
--* File: lua/modules/maui/layouthelpers.lua
--* Author: Chris Blackwell
--* Summary: functions that make it simpler to set up control layouts.
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

-- Percentage versus offset
-- Percentages are specified as a float, with 0.00 to 1.00 the normal ranges
-- Percentages can change spacing when dimension is expended.
--
-- Offsets are specified in pixels for the "base art" size. If the art is
-- scaled (ie large UI mode) this factor will keep the layout correct


local floor = math.floor

-- Store and set the current pixel scale multiplier. This will be used when the
-- artwork is scaled up or down so that offsets scale up and down appropriately.
-- Note that if you add a new layout helper function that uses offsets, you need
-- to scale the offset with this factor or your layout may get funky when the
-- art is changed
local Prefs = import('/lua/user/prefs.lua')
local pixelScaleFactor = Prefs.GetFromCurrentProfile('options').ui_scale or 1


function SetPixelScaleFactor(newFactor)
    pixelScaleFactor = newFactor
end

function GetPixelScaleFactor()
    return pixelScaleFactor
end

-- Set the dimensions
function SetDimensions(control, width, height)
    SetWidth(control, width)
    SetHeight(control, height)
end

function SetWidth(control, width)
    if width then
        control.Width:Set(floor(width * pixelScaleFactor))
    end
end

function SetHeight(control, height)
    if height then
        control.Height:Set(floor(height * pixelScaleFactor))
    end
end

-- Set the depth relative to the parent
function DepthOverParent(control, parent, depth)
    depth = depth or 1
    control.Depth:SetFunction(function() return parent.Depth() + depth end)
end

function DepthUnderParent(control, parent, depth)
    depth = depth or 1
    control.Depth:SetFunction(function() return parent.Depth() - depth end)
end

-- Scale according to the globally set ratio
function Scale(control)
    SetDimensions(control, control.Width(), control.Height())
end

function ScaleNumber(number)
    return floor(number * pixelScaleFactor)
end

function InvScaleNumber(number)
    return floor(number / pixelScaleFactor)
end

-- These functions will set the controls position to be placed relative to
-- its parents dimensions. They are generally most useful for elements that
-- don't change size, they can also be used for controls that stretch
-- to match parent.

function AtHorizontalCenterIn(control, parent, offset)
    if offset then
        control.Left:SetFunction(function()
            return parent.Left() + floor(((parent.Width() - control.Width()) / 2) + (offset * pixelScaleFactor))
        end)
    else
        control.Left:SetFunction(function()
            return parent.Left() + floor((parent.Width() - control.Width()) / 2)
        end)
    end
end

function AtVerticalCenterIn(control, parent, offset)
    if offset then
        control.Top:SetFunction(function()
            return parent.Top() + floor(((parent.Height() - control.Height()) / 2) + (offset * pixelScaleFactor))
        end)
    else
        control.Top:SetFunction(function()
            return parent.Top() + floor((parent.Height() - control.Height()) / 2)
        end)
    end
end

-- These functions place a controls inside a parent

function AtLeftIn(control, parent, offset)
    if offset and offset ~= 0 then
        control.Left:SetFunction(function() return parent.Left() + floor(offset * pixelScaleFactor) end)
    else
        -- We shouldn't need to let the child refer to the parent if the parent is already laid out
        -- however, this does change functionallity of the layout, so I've left them commented out for now
        control.Left:SetFunction(function() return parent.Left() end)
        --control.Left:SetFunction(parent.Left)
    end
end

function AtTopIn(control, parent, offset)
    if offset and offset ~= 0 then
        control.Top:SetFunction(function() return parent.Top() + floor(offset * pixelScaleFactor) end)
    else
        control.Top:SetFunction(function() return parent.Top() end)
        --control.Top:SetFunction(parent.Top)
    end
end

function AtRightIn(control, parent, offset)
    if offset and offset ~= 0 then
        control.Right:SetFunction(function() return parent.Right() - floor(offset * pixelScaleFactor) end)
    else
        control.Right:SetFunction(function() return parent.Right() end)
        --control.Right:SetFunction(parent.Right)
    end
end

function AtBottomIn(control, parent, offset)
    if offset and offset ~= 0 then
        control.Bottom:SetFunction(function() return parent.Bottom() - floor(offset * pixelScaleFactor) end)
    else
        control.Bottom:SetFunction(function() return parent.Bottom() end)
        --control.Bottom:SetFunction(parent.Bottom)
    end
end

-- Anchor functions lock the appropriate side of a control to the side of another control

function AnchorToLeft(control, parent, offset)
    if offset and offset ~= 0 then
        control.Right:SetFunction(function() return parent.Left() - floor(offset * pixelScaleFactor) end)
    else
        control.Right:SetFunction(function() return parent.Left() end)
        --control.Right:SetFunction(parent.Left)
    end
end

function AnchorToTop(control, parent, offset)
    if offset and offset ~= 0 then
        control.Bottom:SetFunction(function() return parent.Top() - floor(offset * pixelScaleFactor) end)
    else
        control.Bottom:SetFunction(function() return parent.Top() end)
        --control.Bottom:SetFunction(parent.Top)
    end
end

function AnchorToRight(control, parent, offset)
    if offset and offset ~= 0 then
        control.Left:SetFunction(function() return parent.Right() + floor(offset * pixelScaleFactor) end)
    else
        control.Left:SetFunction(function() return parent.Right() end)
        --control.Left:SetFunction(parent.Right)
    end
end

function AnchorToBottom(control, parent, offset)
    if offset and offset ~= 0 then
        control.Top:SetFunction(function() return parent.Bottom() + floor(offset * pixelScaleFactor) end)
    else
        control.Top:SetFunction(function() return parent.Bottom() end)
        --control.Top:SetFunction(parent.Bottom)
    end
end

-- These functions use percentages to place the item rather than offsets so they will
-- stay proportially spaced when the parent resizes

function FromLeftIn(control, parent, percent)
    if percent and percent ~= 0 then
        control.Left:SetFunction(function() return parent.Left() + floor(percent * parent.Width()) end)
    else
        control.Left:SetFunction(function() return parent.Left() end)
        --control.Left:SetFunction(parent.Left)
    end
end

function FromTopIn(control, parent, percent)
    if percent and percent ~= 0 then
        control.Top:SetFunction(function() return parent.Top() + floor(percent * parent.Height()) end)
    else
        control.Top:SetFunction(function() return parent.Top() end)
    end
end

function FromRightIn(control, parent, percent)
    if percent and percent ~= 0 then
        control.Right:SetFunction(function() return parent.Right() - floor(percent * parent.Width()) end)
    else
        control.Right:SetFunction(function() return parent.Right() end)
        --control.Right:SetFunction(parent.Right)
    end
end

function FromBottomIn(control, parent, percent)
    if percent and percent ~= 0 then
        control.Bottom:SetFunction(function() return parent.Bottom() - floor(percent * parent.Height()) end)
    else
        control.Bottom:SetFunction(function() return parent.Bottom() end)
        --control.Bottom:SetFunction(parent.Bottom)
    end
end

-- These functions reset a control to be calculated from the others

function ResetLeft(control)
    control.Left:SetFunction(function() return control.Right() - control.Width() end)
end

function ResetTop(control)
    control.Top:SetFunction(function() return control.Bottom() - control.Height() end)
end

function ResetRight(control)
    control.Right:SetFunction(function() return control.Left() + control.Width() end)
end

function ResetBottom(control)
    control.Bottom:SetFunction(function() return control.Top() + control.Height() end)
end

function ResetWidth(control)
    control.Width:SetFunction(function() return control.Right() - control.Left() end)
end

function ResetHeight(control)
    control.Height:SetFunction(function() return control.Bottom() - control.Top() end)
end


--**************************************
--*      Composite Functions           *
--**************************************

function AtCenterIn(control, parent, vertOffset, horzOffset)
    AtHorizontalCenterIn(control, parent, horzOffset)
    AtVerticalCenterIn(control, parent, vertOffset)
end

-- Lock right top of control to left of parent, centered vertically to the parent
function CenteredLeftOf(control, parent, offset)
    AnchorToLeft(control, parent, offset)
    AtVerticalCenterIn(control, parent)
end

-- Lock bottom left of control to top left of parent, centered horizontally to the parent
function CenteredAbove(control, parent, offset)
    AtHorizontalCenterIn(control, parent)
    AnchorToTop(control, parent, offset)
end

-- Lock left top of control to right of parent, centered vertically to the parent
function CenteredRightOf(control, parent, offset)
    AnchorToRight(control, parent, offset)
    AtVerticalCenterIn(control, parent)
end

-- Lock top left of control to bottom left of parent, centered horizontally to the parent
function CenteredBelow(control, parent, offset)
    AtHorizontalCenterIn(control, parent)
    AnchorToBottom(control, parent, offset)
end

-- Set to a corner inside the parent

function AtLeftTopIn(control, parent, leftOffset, topOffset)
    AtLeftIn(control, parent, leftOffset)
    AtTopIn(control, parent, topOffset)
end

function AtRightTopIn(control, parent, rightOffset, topOffset)
    AtRightIn(control, parent, rightOffset)
    AtTopIn(control, parent, topOffset)
end

function AtLeftBottomIn(control, parent, leftOffset, bottomOffset)
    AtLeftIn(control, parent, leftOffset)
    AtBottomIn(control, parent, bottomOffset)
end

function AtRightBottomIn(control, parent, rightOffset, bottomOffset)
    AtRightIn(control, parent, rightOffset)
    AtBottomIn(control, parent, bottomOffset)
end

-- These functions will set the controls position relative to a sibling

-- Lock right top of control to left top of parent
function LeftOf(control, parent, offset)
    AnchorToLeft(control, parent, offset)
    AtTopIn(control, parent)
end

-- Lock bottom left of control to top left of parent
function Above(control, parent, offset)
    AtLeftIn(control, parent)
    AnchorToTop(control, parent, offset)
end

-- Lock left top of control to right top of parent
function RightOf(control, parent, offset)
    AnchorToRight(control, parent, offset)
    AtTopIn(control, parent)
end

-- Lock top left of control to bottom left of parent
function Below(control, parent, offset)
    AtLeftIn(control, parent)
    AnchorToBottom(control, parent, offset)
end



-- These functions will place the control and resize in a specified location within the parent
-- note that the offset version is more useful than hard coding the location
-- as it will take advantage of the pixel scale factor

function OffsetIn(control, parent, left, top, right, bottom)
    AtLeftIn(control, parent, left)
    AtTopIn(control, parent, top)
    AtRightIn(control, parent, right)
    AtBottomIn(control, parent, bottom)
end

function PercentIn(control, parent, left, top, right, bottom)
    FromLeftIn(control, parent, left)
    FromTopIn(control, parent, top)
    FromRightIn(control, parent, right)
    FromBottomIn(control, parent, bottom)
end

-- These functions will stretch the control to fill the parent and provide an optional border

function FillParent(control, parent)
    control.Top:SetFunction(parent.Top)
    control.Left:SetFunction(parent.Left)
    control.Bottom:SetFunction(parent.Bottom)
    control.Right:SetFunction(parent.Right)
end

function FillParentRelativeBorder(control, parent, percent)
    PercentIn(control, parent, percent, percent, percent, percent)
end

function FillParentFixedBorder(control, parent, offset)
    OffsetIn(control, parent, offset, offset, offset, offset)
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

    control.Top:SetFunction(function()
        return floor(parent.Top() + ((parent.Height() - (control.Height() * GetRatio(control, parent))) / 2))
    end)
    control.Bottom:SetFunction(function()
        return floor(parent.Bottom() - ((parent.Height() - (control.Height() * GetRatio(control, parent))) / 2))
    end)
    control.Left:SetFunction(function()
        return floor(parent.Left() + ((parent.Width() - (control.Width() * GetRatio(control, parent))) / 2))
    end)
    control.Right:SetFunction(function()
        return floor(parent.Right() - ((parent.Width() - (control.Width() * GetRatio(control, parent))) / 2))
    end)
end

-- Reset to the default layout functions
function Reset(control)
    ResetLeft(control)
    ResetTop(control)
    ResetRight(control)
    ResetBottom(control)
    ResetWidth(control)
    ResetHeight(control)
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
    topOffset = topOffset or 0
    leftOffset = leftOffset or 0
    control.Top:SetFunction(function()
        local layoutTable = import(fileName()).layout
        return floor(parent.Top() + ((layoutTable[controlName].top - layoutTable[parentName].top) * pixelScaleFactor + (topOffset * pixelScaleFactor)))
    end)
    
    control.Left:SetFunction(function()
        local layoutTable = import(fileName()).layout
        return floor(parent.Left() + ((layoutTable[controlName].left - layoutTable[parentName].left) * pixelScaleFactor + (leftOffset * pixelScaleFactor)))
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
    control.Top:SetFunction(function()
        local layoutTable = import(fileName()).layout
        return floor(parent.Top() + (layoutTable[controlName].top - layoutTable[parentName].top))
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
    control.Left:SetFunction(function()
        local layoutTable = import(fileName()).layout
        return floor(parent.Left() + (layoutTable[controlName].left - layoutTable[parentName].left))
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
    control.Right:SetFunction(function()
        local layoutTable = import(fileName()).layout
        local layoutParent = layoutTable[parentName]
        local layoutControl = layoutTable[controlName]
        return floor(parent.Right() - ((layoutParent.left + layoutParent.width) - (layoutControl.left + layoutControl.width)))
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
    control.Bottom:SetFunction(function()
        local layoutTable = import(fileName()).layout
        local layoutParent = layoutTable[parentName]
        local layoutControl = layoutTable[controlName]
        return floor(parent.Bottom() - ((layoutParent.top + layoutParent.height) - (layoutControl.top + layoutControl.height)))
    end)
end

function DimensionsRelativeTo(control, fileName, controlName)
    local layoutTable = import(fileName()).layout
    if not layoutTable[controlName] then
        WARN("Control not found in layout table: " .. controlName)
    end
    control.Width:SetFunction(function()
        local layoutTable = import(fileName()).layout
        return floor(layoutTable[controlName].width * pixelScaleFactor)
    end)
    control.Height:SetFunction(function()
        local layoutTable = import(fileName()).layout
        return floor(layoutTable[controlName].height * pixelScaleFactor)
    end)
end


--**********************************
--*********  Layouter  *************
--**********************************

local LayouterMetaTable = {}
LayouterMetaTable.__index = LayouterMetaTable

-- Controls' mostly used methods

function LayouterMetaTable:Name(debugName)
    self.c:SetName(debugName)
    return self
end

function LayouterMetaTable:Disable()
    self.c:Disable()
    return self
end

function LayouterMetaTable:Hide()
    self.c:Hide()
    return self
end

function LayouterMetaTable:Color(color)
    if self.c.SetSolidColor then
        self.c:SetSolidColor(color)
    elseif self.c.SetColor then
        self.c:SetColor(color)
    else
        WARN(string.format("Unable to set color for control \"%s\"", self.c:GetName()))
    end
    return self
end

function LayouterMetaTable:DropShadow(bool)
    self.c:SetDropShadow(bool)
    return self
end

function LayouterMetaTable:Texture(texture, border)
    self.c:SetTexture(texture, border)
    return self
end

function LayouterMetaTable:EnableHitTest(recursive)
    self.c:EnableHitTest(recursive)
    return self
end

function LayouterMetaTable:DisableHitTest(recursive)
    self.c:DisableHitTest(recursive)
    return self
end

function LayouterMetaTable:NeedsFrameUpdate(bool)
    self.c:SetNeedsFrameUpdate(bool)
    return self
end

function LayouterMetaTable:Alpha(alpha, children)
    self.c:SetAlpha(alpha, children)
    return self
end

-- Raw setting

function LayouterMetaTable:Left(left)
    self.c.Left:Set(left)
    return self
end

function LayouterMetaTable:Right(right)
    self.c.Right:Set(right)
    return self
end

function LayouterMetaTable:Top(top)
    self.c.Top:Set(top)
    return self
end

function LayouterMetaTable:Bottom(bottom)
    self.c.Bottom:Set(bottom)
    return self
end

function LayouterMetaTable:Width(width)
    if iscallable(width) then
        self.c.Width:SetFunction(width)
    else
        self.c.Width:SetValue(ScaleNumber(width))
    end
    return self
end

function LayouterMetaTable:Height(height)
    if iscallable(height) then
        self.c.Height:SetFunction(height)
    else
        self.c.Height:SetValue(ScaleNumber(height))
    end
    return self
end

-- Fill parent

function LayouterMetaTable:Fill(parent)
    FillParent(self.c, parent)
    return self
end

function LayouterMetaTable:FillFixedBorder(parent, offset)
    FillParentFixedBorder(self.c, parent, offset)
    return self
end

-- Double-based positioning

function LayouterMetaTable:AtLeftTopIn(parent, leftOffset, topOffset)
    AtLeftTopIn(self.c, parent, leftOffset, topOffset)
    return self
end

function LayouterMetaTable:AtRightBottomIn(parent, rightOffset, bottomOffset)
    AtRightBottomIn(self.c, parent, rightOffset, bottomOffset)
    return self
end

function LayouterMetaTable:AtLeftBottomIn(parent, leftOffset, bottomOffset)
    AtLeftBottomIn(self.c, parent, leftOffset, bottomOffset)
    return self
end

function LayouterMetaTable:AtRightTopIn(parent, rightOffset, topOffset)
    AtRightTopIn(self.c, parent, rightOffset, topOffset)
    return self
end

-- Centered out of parent

function LayouterMetaTable:CenteredLeftOf(parent, offset)
    CenteredLeftOf(self.c, parent, offset)
    return self
end

function LayouterMetaTable:CenteredRightOf(parent, offset)
    CenteredRightOf(self.c, parent, offset)
    return self
end

function LayouterMetaTable:CenteredAbove(parent, offset)
    CenteredAbove(self.c, parent, offset)
    return self
end

function LayouterMetaTable:CenteredBelow(parent, offset)
    CenteredBelow(self.c, parent, offset)
    return self
end

-- Centered

function LayouterMetaTable:AtHorizontalCenterIn(parent, offset)
    AtHorizontalCenterIn(self.c, parent, offset)
    return self
end

function LayouterMetaTable:AtVerticalCenterIn(parent, offset)
    AtVerticalCenterIn(self.c, parent, offset)
    return self
end

function LayouterMetaTable:AtCenterIn(parent, vertOffset, horzOffset)
    AtCenterIn(self.c, parent, vertOffset, horzOffset)
    return self
end

-- Single-in positioning

function LayouterMetaTable:AtLeftIn(parent, offset)
    AtLeftIn(self.c, parent, offset)
    return self
end

function LayouterMetaTable:AtRightIn(parent, offset)
    AtRightIn(self.c, parent, offset)
    return self
end

function LayouterMetaTable:AtTopIn(parent, offset)
    AtTopIn(self.c, parent, offset)
    return self
end

function LayouterMetaTable:AtBottomIn(parent, offset)
    AtBottomIn(self.c, parent, offset)
    return self
end

-- Center-in positioning

function LayouterMetaTable:AtLeftCenterIn(parent, offset, verticalOffset)
    AtLeftIn(self.c, parent, offset)
    AtVerticalCenterIn(self.c, parent, verticalOffset)
    return self
end

function LayouterMetaTable:AtRightCenterIn(parent, offset, verticalOffset)
    AtRightIn(self.c, parent, offset)
    AtVerticalCenterIn(self.c, parent, verticalOffset)
    return self
end

function LayouterMetaTable:AtTopCenterIn(parent, offset, horizonalOffset)
    AtTopIn(self.c, parent, offset)
    AtHorizontalCenterIn(self.c, parent, horizonalOffset)
    return self
end

function LayouterMetaTable:AtBottomCenterIn(parent, offset, horizonalOffset)
    AtBottomIn(self.c, parent, offset)
    AtHorizontalCenterIn(self.c, parent, horizonalOffset)
    return self
end

-- Center-in positioning

function LayouterMetaTable:AtLeftCenterIn(parent, offset, verticalOffset)
    AtLeftIn(self.c, parent, offset)
    AtVerticalCenterIn(self.c, parent, verticalOffset)
    return self
end

function LayouterMetaTable:AtRightCenterIn(parent, offset, verticalOffset)
    AtRightIn(self.c, parent, offset)
    AtVerticalCenterIn(self.c, parent, verticalOffset)
    return self
end

function LayouterMetaTable:AtTopCenterIn(parent, offset, horizonalOffset)
    AtTopIn(self.c, parent, offset)
    AtHorizontalCenterIn(self.c, parent, horizonalOffset)
    return self
end

function LayouterMetaTable:AtBottomCenterIn(parent, offset, horizonalOffset)
    AtBottomIn(self.c, parent, offset)
    AtHorizontalCenterIn(self.c, parent, horizonalOffset)
    return self
end

-- Out-of positioning

function LayouterMetaTable:Below(parent, offset)
    Below(self.c, parent, offset)
    return self
end

function LayouterMetaTable:Above(parent, offset)
    Above(self.c, parent, offset)
    return self
end

function LayouterMetaTable:RightOf(parent, offset)
    RightOf(self.c, parent, offset)
    return self
end

function LayouterMetaTable:LeftOf(parent, offset)
    LeftOf(self.c, parent, offset)
    return self
end

-- Depth

function LayouterMetaTable:Over(parent, depth)
    DepthOverParent(self.c, parent, depth)
    return self
end

function LayouterMetaTable:Under(parent, depth)
    DepthUnderParent(self.c, parent, depth)
    return self
end

-- Anchor

function LayouterMetaTable:AnchorToTop(parent, offset)
    AnchorToTop(self.c, parent, offset)
    return self
end

function LayouterMetaTable:AnchorToLeft(parent, offset)
    AnchorToLeft(self.c, parent, offset)
    return self
end

function LayouterMetaTable:AnchorToRight(parent, offset)
    AnchorToRight(self.c, parent, offset)
    return self
end

function LayouterMetaTable:AnchorToBottom(parent, offset)
    AnchorToBottom(self.c, parent, offset)
    return self
end


-- Resets control's properties to default

function LayouterMetaTable:ResetLeft()
    ResetLeft(self.c)
    return self
end

function LayouterMetaTable:ResetTop()
    ResetTop(self.c)
    return self
end

function LayouterMetaTable:ResetRight()
    ResetRight(self.c)
    return self
end

function LayouterMetaTable:ResetBottom()
    ResetBottom(self.c)
    return self
end

function LayouterMetaTable:ResetWidth()
    ResetWidth(self.c)
    return self
end

function LayouterMetaTable:ResetHeight()
    ResetHeight(self.c)
    return self
end

-- Get control
function LayouterMetaTable:Get()
    return self.c
end

-- Calculates control's Properties to determine its layout completion and returns it
-- remember, if parent has incomplete layout it will warn you anyway
function LayouterMetaTable:End()
    if not pcall(self.c.Top) or not pcall(self.c.Bottom) or not pcall(self.c.Height) then
        WARN(string.format("Incorrect layout for \"%s\" Top-Height-Bottom", self.c:GetName()))
        WARN(debug.traceback())
    end
    
    if not pcall(self.c.Left) or not pcall(self.c.Right) or not pcall(self.c.Width)  then
        WARN(string.format("Incorrect layout for \"%s\" Left-Width-Right", self.c:GetName()))
        WARN(debug.traceback())
    end
    
    return self.c
end

function LayouterMetaTable:__newindex(key, value)
    error("attempt to set new index for a Layouter object")
end

function LayoutFor(control)
    local result = {
        c = control
    }
    setmetatable(result, LayouterMetaTable)
    return result
end

local layouter = {
    c = false
}
setmetatable(layouter, LayouterMetaTable)

-- Use if you don't cache layouter object
function ReusedLayoutFor(control)
    layouter.c = control or false
    return layouter
end
