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


local MapFloor = math.floor
local MapCeil = math.ceil

-- Store and set the current pixel scale multiplier. This will be used when the
-- artwork is scaled up or down so that offsets scale up and down appropriately.
-- Note that if you add a new layout helper function that uses offsets, you need
-- to scale the offset with this factor or your layout may get funky when the
-- art is changed
local Prefs = import('/lua/user/prefs.lua')
local pixelScaleFactor = Prefs.GetFromCurrentProfile('options').ui_scale or 1

--- Set new scale factor for absolute offset in layout functions
---@param newFactor number
function SetPixelScaleFactor(newFactor)
    pixelScaleFactor = newFactor
end

--- Get scale factor for absolute offset in layout functions
---@return number pixelScaleFactor 
function GetPixelScaleFactor()
    return pixelScaleFactor
end

--- Set absolute dimensions of a control
---@param control Control
---@param width? number no change if nil
---@param height? number no change if nil
function SetDimensions(control, width, height)
    SetWidth(control, width)
    SetHeight(control, height)
end

--- Set absolute width of a control
---@param control Control
---@param width? number no change if nil
function SetWidth(control, width)
    if width then
        control.Width:SetValue(MapFloor(width * pixelScaleFactor))
    end
end

--- Set absolute height of a control
---@param control Control
---@param height? number no change if nil
function SetHeight(control, height)
    if height then
        control.Height:SetValue(MapFloor(height * pixelScaleFactor))
    end
end

--- Set the depth of a control higher than a parent
---@param control Control
---@param parent Control
---@param depth? integer defaults to 1
function DepthOverParent(control, parent, depth)
    depth = depth or 1
    control.Depth:SetFunction(function() return parent.Depth() + depth end)
end

--- Set the depth of a control lower than a parent
---@param control Control
---@param parent Control
---@param depth? integer defaults to 1
function DepthUnderParent(control, parent, depth)
    depth = depth or 1
    control.Depth:SetFunction(function() return parent.Depth() - depth end)
end

--- Scales a control according to the globally set pixel ratio
---@param control Control
function Scale(control)
    SetDimensions(control, control.Width(), control.Height())
end

--- Scales a number by the pixel scale factor
---@param number number
---@return number scaledNumber
function ScaleNumber(number)
    return MapFloor(number * pixelScaleFactor)
end

--- Unscales a number by the pixel scale factor
---@param scaledNumber number
---@return number number
function InvScaleNumber(scaledNumber)
    return MathCeil(scaledNumber / pixelScaleFactor)
end



-- Anchor functions lock the appropriate side of a control to the side of another control

--- Anchors a control to the left of a parent, with optional padding
---@param control Control
---@param parent Control
---@param padding? number fixed padding between control and parent
function AnchorToLeft(control, parent, padding)
    if padding and padding ~= 0 then
        control.Right:SetFunction(function() return parent.Left() - MapFloor(padding * pixelScaleFactor) end)
    else
        -- We shouldn't need to let the child refer to the parent if the parent is already laid out
        -- however, this does change functionallity of the layout, so I've left them commented out for now
        control.Right:SetFunction(function() return parent.Left() end)
        --control.Right:SetFunction(parent.Left)
    end
end

--- Anchors a control to the top of a parent, with optional padding
---@param control Control
---@param parent Control
---@param padding? number fixed padding between control and parent
function AnchorToTop(control, parent, padding)
    if padding and padding ~= 0 then
        control.Bottom:SetFunction(function() return parent.Top() - MapFloor(padding * pixelScaleFactor) end)
    else
        control.Bottom:SetFunction(function() return parent.Top() end)
        --control.Bottom:SetFunction(parent.Top)
    end
end

--- Anchors a control to the right of a parent, with optional padding
---@param control Control
---@param parent Control
---@param padding? number fixed padding between control and parent
function AnchorToRight(control, parent, padding)
    if padding and padding ~= 0 then
        control.Left:SetFunction(function() return parent.Right() + MapFloor(padding * pixelScaleFactor) end)
    else
        control.Left:SetFunction(function() return parent.Right() end)
        --control.Left:SetFunction(parent.Right)
    end
end

--- Anchors a control to the bottom of a parent, with optional padding
---@param control Control
---@param parent Control
---@param padding? number fixed padding between control and parent
function AnchorToBottom(control, parent, padding)
    if padding and padding ~= 0 then
        control.Top:SetFunction(function() return parent.Bottom() + MapFloor(padding * pixelScaleFactor) end)
    else
        control.Top:SetFunction(function() return parent.Bottom() end)
        --control.Top:SetFunction(parent.Bottom)
    end
end

-- These functions will set the controls position to be placed relative to
-- its parents dimensions. 
-- note that the offset is in the opposite direction as placement, to position 
-- the controls further inside the parent

-- These are generally most useful for elements that don't change size, they can also be
-- used for controls that stretch to match parent.

--- Centers a control horizontally on a parent, with optional right offset
---@param control Control
---@param parent Control
---@param leftOffset? number
function AtHorizontalCenterIn(control, parent, leftOffset)
    if leftOffset then
        control.Left:SetFunction(function()
            return parent.Left() + MapFloor(((parent.Width() - control.Width()) / 2) + (leftOffset * pixelScaleFactor))
        end)
    else
        control.Left:SetFunction(function()
            return parent.Left() + MapFloor((parent.Width() - control.Width()) / 2)
        end)
    end
end

--- Centers a control vertically on a parent, with optional down offset
---@param control Control
---@param parent Control
---@param topOffset? number
function AtVerticalCenterIn(control, parent, topOffset)
    if topOffset then
        control.Top:SetFunction(function()
            return parent.Top() + MapFloor(((parent.Height() - control.Height()) / 2) + (topOffset * pixelScaleFactor))
        end)
    else
        control.Top:SetFunction(function()
            return parent.Top() + MapFloor((parent.Height() - control.Height()) / 2)
        end)
    end
end

--- Places a control inside the left edge of a parent, with optional right offset
---@param control Control
---@param parent Control
---@param leftOffset? number
function AtLeftIn(control, parent, leftOffset)
    if leftOffset and leftOffset ~= 0 then
        control.Left:SetFunction(function() return parent.Left() + MapFloor(leftOffset * pixelScaleFactor) end)
    else
        control.Left:SetFunction(function() return parent.Left() end)
        --control.Left:SetFunction(parent.Left)
    end
end

--- Places a control inside the top edge of a parent, with optional down offset
---@param control Control
---@param parent Control
---@param topOffset? number
function AtTopIn(control, parent, topOffset)
    if topOffset and topOffset ~= 0 then
        control.Top:SetFunction(function() return parent.Top() + MapFloor(topOffset * pixelScaleFactor) end)
    else
        control.Top:SetFunction(function() return parent.Top() end)
        --control.Top:SetFunction(parent.Top)
    end
end

--- Places a control inside the right edge of a parent, with optional left offset
---@param control Control
---@param parent Control
---@param rightOffset? number
function AtRightIn(control, parent, rightOffset)
    if rightOffset and rightOffset ~= 0 then
        control.Right:SetFunction(function() return parent.Right() - MapFloor(rightOffset * pixelScaleFactor) end)
    else
        control.Right:SetFunction(function() return parent.Right() end)
        --control.Right:SetFunction(parent.Right)
    end
end

--- Places a control inside the bottom edge of a parent, with optional up offset
---@param control Control
---@param parent Control
---@param bottomOffset? number
function AtBottomIn(control, parent, bottomOffset)
    if bottomOffset and bottomOffset ~= 0 then
        control.Bottom:SetFunction(function() return parent.Bottom() - MapFloor(bottomOffset * pixelScaleFactor) end)
    else
        control.Bottom:SetFunction(function() return parent.Bottom() end)
        --control.Bottom:SetFunction(parent.Bottom)
    end
end

-- These functions use percentages to place the item rather than offsets so they will
-- stay proportially spaced when the parent resizes

--- Places the control's left at a percentage along the width of a parent, with 0.00 at the parent's left
---@param control Control
---@param parent Control
---@param leftPercent? number
function FromLeftIn(control, parent, leftPercent)
    if leftPercent and leftPercent ~= 0 then
        control.Left:SetFunction(function() return parent.Left() + MapFloor(leftPercent * parent.Width()) end)
    else
        control.Left:SetFunction(function() return parent.Left() end)
        --control.Left:SetFunction(parent.Left)
    end
end

--- Places the control's top at a percentage along the height of a parent, with 0.00 at the parent's top
---@param control Control
---@param parent Control
---@param topPercent? number
function FromTopIn(control, parent, topPercent)
    if topPercent and topPercent ~= 0 then
        control.Top:SetFunction(function() return parent.Top() + MapFloor(topPercent * parent.Height()) end)
    else
        control.Top:SetFunction(function() return parent.Top() end)
        --control.Top:SetFunction(parent.Top)
    end
end

--- Places the control's right at a percentage along the width of a parent, with 0.00 at the parent's right
---@param control Control
---@param parent Control
---@param rightPercent? number
function FromRightIn(control, parent, rightPercent)
    if rightPercent and rightPercent ~= 0 then
        control.Right:SetFunction(function() return parent.Right() - MapFloor(rightPercent * parent.Width()) end)
    else
        control.Right:SetFunction(function() return parent.Right() end)
        --control.Right:SetFunction(parent.Right)
    end
end

--- Places the control's top at a percentage along the height of a parent, with 0.00 at the parent's bottom
---@param control Control
---@param parent Control
---@param bottomPercent? number
function FromBottomIn(control, parent, bottomPercent)
    if bottomPercent and bottomPercent ~= 0 then
        control.Bottom:SetFunction(function() return parent.Bottom() - MapFloor(bottomPercent * parent.Height()) end)
    else
        control.Bottom:SetFunction(function() return parent.Bottom() end)
        --control.Bottom:SetFunction(parent.Bottom)
    end
end

-- These functions reset a control to be calculated from the others

--- Resets a control's left to be calculated from its right and width
--- *Make sure Right and Width are defined!!!*
---@param control Control 
function ResetLeft(control)
    control.Left:SetFunction(function() return control.Right() - control.Width() end)
end

--- Resets a control's top to be calculated from its bottom and height
--- **Make sure Bottom and Height are defined!!!**
---@param control Control
function ResetTop(control)
    control.Top:SetFunction(function() return control.Bottom() - control.Height() end)
end

--- Resets a control's left to be calculated from its right and width
---@param control Control make sure Left and Width are defined!!!
function ResetRight(control)
    control.Right:SetFunction(function() return control.Left() + control.Width() end)
end

--- Resets a control's bottom to be calculated from its top and height
--- **Make sure Top and Height are Defined!!!**
---@param control Control
function ResetBottom(control)
    control.Bottom:SetFunction(function() return control.Top() + control.Height() end)
end

--- Resets a control's width to be calculated from its right and left
--- **Make sure Right and Left are defined!!!**
---@param control Control
function ResetWidth(control)
    control.Width:SetFunction(function() return control.Right() - control.Left() end)
end

--- Resets a control's height to be calculated from its top and bottom
--- **Make sure Bottom and Top are defined!!!**
---@param control Control
function ResetHeight(control)
    control.Height:SetFunction(function() return control.Bottom() - control.Top() end)
end


--**********
--* Composite Functions
--**********

--- Places a control in the center of a parent, with optional offsets
---@param control Control
---@param parent Control
---@param topOffset? number offset of top edge (offset in down direction)
---@param leftOffset? number offset of left edge (offset in right direction)
function AtCenterIn(control, parent, topOffset, leftOffset)
    AtHorizontalCenterIn(control, parent, leftOffset)
    AtVerticalCenterIn(control, parent, topOffset)
end

--- Lock right edge of a control to left of a parent, centered vertically
---@param control Control
---@param parent Control
---@param padding? number fixed padding between control and parent
function CenteredLeftOf(control, parent, padding)
    AnchorToLeft(control, parent, padding)
    AtVerticalCenterIn(control, parent)
end

--- Lock bottom edge of a control to top of a parent, centered horizontally
---@param control Control
---@param parent Control
---@param padding? number fixed padding between control and parent
function CenteredAbove(control, parent, padding)
    AtHorizontalCenterIn(control, parent)
    AnchorToTop(control, parent, padding)
end

--- Lock top left of a control to right of a parent, centered vertically
---@param control Control
---@param parent Control
---@param padding? number fixed padding between control and parent
function CenteredRightOf(control, parent, padding)
    AnchorToRight(control, parent, padding)
    AtVerticalCenterIn(control, parent)
end

--- Lock top left of a control to bottom left of a parent, centered horizontally
---@param control Control
---@param parent Control
---@param padding? number fixed padding between control and parent
function CenteredBelow(control, parent, padding)
    AtHorizontalCenterIn(control, parent)
    AnchorToBottom(control, parent, padding)
end

-- Set to a corner inside the parent

--- Places top left corner of a control inside of a parent's
---@param control Control
---@param parent Control
---@param leftOffset? number
---@param topOffset? number
function AtLeftTopIn(control, parent, leftOffset, topOffset)
    AtLeftIn(control, parent, leftOffset)
    AtTopIn(control, parent, topOffset)
end

--- Places top right corner of a control inside of a parent's
---@param control Control
---@param parent Control
---@param rightOffset? number
---@param topOffset? number
function AtRightTopIn(control, parent, rightOffset, topOffset)
    AtRightIn(control, parent, rightOffset)
    AtTopIn(control, parent, topOffset)
end

--- Places bottom left corner of a control inside of a parent's
---@param control Control
---@param parent Control
---@param leftOffset? number
---@param bottomOffset? number
function AtLeftBottomIn(control, parent, leftOffset, bottomOffset)
    AtLeftIn(control, parent, leftOffset)
    AtBottomIn(control, parent, bottomOffset)
end

--- Places bottom right corner of a control inside of its parent's
---@param control Control
---@param parent Control
---@param rightOffset? number
---@param bottomOffset? number
function AtRightBottomIn(control, parent, rightOffset, bottomOffset)
    AtRightIn(control, parent, rightOffset)
    AtBottomIn(control, parent, bottomOffset)
end

-- These functions will set the controls position relative to another, usually a sibling

--- Lock top right of a control to top left of a parent
---@param control Control
---@param parent Control
---@param padding? number fixed padding between control and parent
function LeftOf(control, parent, padding)
    AnchorToLeft(control, parent, padding)
    AtTopIn(control, parent)
end

--- Lock top left of a control to top right of a parent
---@param control Control
---@param parent Control
---@param padding? number fixed padding between control and parent
function RightOf(control, parent, padding)
    AnchorToRight(control, parent, padding)
    AtTopIn(control, parent)
end

--- Lock bottom left of a control to top left of a parent
---@param control Control
---@param parent Control
---@param padding? number fixed padding between control and parent
function Above(control, parent, padding)
    AtLeftIn(control, parent)
    AnchorToTop(control, parent, padding)
end

--- Lock top left of a control to bottom left of a parent
---@param control Control
---@param parent Control
---@param padding? number fixed padding between control and parent
function Below(control, parent, padding)
    AtLeftIn(control, parent)
    AnchorToBottom(control, parent, padding)
end


-- These functions will place the control and resize in a specified location within the parent
-- note that the offset version is more useful than hard coding the location
-- as it will take advantage of the pixel scale factor

--- Sets all sides of a control to be a certain amount inside of a parent
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

--- Sets all sides of a control to be a certain percentage inside of a parent
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

-- These functions will stretch the control to fill the parent and provide an optional border

--- Sets a control to fill a parent
--- Note this function copies the parent's side functions, it does not refer
---@param control Control
---@param parent Control
function FillParent(control, parent)
    control.Top:SetFunction(parent.Top)
    control.Left:SetFunction(parent.Left)
    control.Bottom:SetFunction(parent.Bottom)
    control.Right:SetFunction(parent.Right)
end

--- Sets a control to fill a parent's with fixed padding
---@param control Control
---@param parent Control
---@param offset? number
function FillParentFixedBorder(control, parent, offset)
    OffsetIn(control, parent, offset, offset, offset, offset)
end

--- Sets a control to fill a parent's with percent padding
---@param control Control
---@param parent Control
---@param percent? number
function FillParentRelativeBorder(control, parent, percent)
    PercentIn(control, parent, percent, percent, percent, percent)
end

--- Sets a control to fill a parent while preversing its width and height ratio
--- Fill the parent control while preserving the aspect ratio of the item
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
        return MapFloor(parent.Top() + ((parent.Height() - (control.Height() * GetRatio(control, parent))) / 2))
    end)
    control.Bottom:SetFunction(function()
        return MapFloor(parent.Bottom() - ((parent.Height() - (control.Height() * GetRatio(control, parent))) / 2))
    end)
    control.Left:SetFunction(function()
        return MapFloor(parent.Left() + ((parent.Width() - (control.Width() * GetRatio(control, parent))) / 2))
    end)
    control.Right:SetFunction(function()
        return MapFloor(parent.Right() - ((parent.Width() - (control.Width() * GetRatio(control, parent))) / 2))
    end)
end

--- Reset to the default layout functions
--- You should call control:ResetLayout() instead unless you cannot rely on overriden behavior
--- **Remember to redefine two horizontal and two vertical properties to avoid circular dependencies!**
---@param control Control
function Reset(control)
    ResetLeft(control)
    ResetTop(control)
    ResetRight(control)
    ResetBottom(control)
    ResetWidth(control)
    ResetHeight(control)
end


-- The following functions use layout files created with the Maui Photoshop Exporter to position controls
-- Layout files contain a single table in this format:
-- 
-- layout = {
--     {control_name_1 = {left = 0, top = 0, width = 100, height = 100,},
--     {control_name_2 = {left = 0, top = 0, width = 100, height = 100,},
-- }

--- Sets a control to be positioned to a parent using a layout table
---@param control Control
---@param parent Control
---@param fileName string full path and filename of the layout file. Must be a lazy var or function that returns the file name
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
        return MapFloor(parent.Top() + ((layoutTable[controlName].top - layoutTable[parentName].top) * pixelScaleFactor + (topOffset * pixelScaleFactor)))
    end)
    
    control.Left:SetFunction(function()
        local layoutTable = import(fileName()).layout
        return MapFloor(parent.Left() + ((layoutTable[controlName].left - layoutTable[parentName].left) * pixelScaleFactor + (leftOffset * pixelScaleFactor)))
    end)
end

--- Sets a control's left to be positioned to a parent using a layout table
---@param control Control
---@param parent Control
---@param fileName string full path and filename of the layout file. must be a lazy var or function that returns the file name
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
        return MapFloor(parent.Left() + (layoutTable[controlName].left - layoutTable[parentName].left))
    end)
end

--- Sets a control's top to be positioned to a parent using a layout table
---@param control Control
---@param parent Control
---@param fileName string full path and filename of the layout file. must be a lazy var or function that returns the file name
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
        return MapFloor(parent.Top() + (layoutTable[controlName].top - layoutTable[parentName].top))
    end)
end

--- Sets a control's right to be positioned to a parent using a layout table
---@param control Control the control to position
---@param parent Control the control that the above is positioned relative to
---@param fileName string the full path and filename of the layout file. must be a lazy var or function that returns the file name
---@param controlName string the name( table key) of the control to be positioned
---@param parentName string the name (table key) of the control to be positioned relative to
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
        return MapFloor(parent.Right() - ((layoutParent.left + layoutParent.width) - (layoutControl.left + layoutControl.width)))
    end)
end

--- Sets a control's bottom to be positioned to a parent using a layout table
---@param control Control
---@param parent Control
---@param fileName string full path and filename of the layout file. must be a lazy var or function that returns the file name
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
        return MapFloor(parent.Bottom() - ((layoutParent.top + layoutParent.height) - (layoutControl.top + layoutControl.height)))
    end)
end

--- Sets a control's dimensions using a layout table
---@param control Control
---@param fileName string full path and filename of the layout file. must be a lazy var or function that returns the file name
---@param controlName string name (table key) of the control to be positioned
function DimensionsRelativeTo(control, fileName, controlName)
    local layoutTable = import(fileName()).layout
    if not layoutTable[controlName] then
        WARN("Control not found in layout table: " .. controlName)
    end
    control.Width:SetFunction(function()
        local layoutTable = import(fileName()).layout
        return MapFloor(layoutTable[controlName].width * pixelScaleFactor)
    end)
    control.Height:SetFunction(function()
        local layoutTable = import(fileName()).layout
        return MapFloor(layoutTable[controlName].height * pixelScaleFactor)
    end)
end


--**********************************
--*********  Layouter  *************
--**********************************

---@class Layouter : moho.aibrain_methods
---@field c Control
local LayouterMetaTable = {}
LayouterMetaTable.__index = LayouterMetaTable


-- Get control
---@return Control c
function LayouterMetaTable:Get()
    return self.c
end

-- Controls' mostly used methods

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
---@param color string hexcolor
---@return Layouter
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
---@param isRecursive boolean
---@return Layouter
function LayouterMetaTable:EnableHitTest(isRecursive)
    self.c:EnableHitTest(isRecursive)
    return self
end

--- Disables the control's hit test
---@param isRecursive boolean
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
---@param forChildren boolean
---@return Layouter
function LayouterMetaTable:Alpha(alpha, forChildren)
    self.c:SetAlpha(alpha, forChildren)
    return self
end

-- Raw setting

--- Sets the left side of the control
---@param left function|number
---@return Layouter
function LayouterMetaTable:Left(left)
    self.c.Left:Set(left)
    return self
end

--- Sets the top side of the control
---@param top function|number
---@return Layouter
function LayouterMetaTable:Top(top)
    self.c.Top:Set(top)
    return self
end

--- Sets the right side of the control
---@param right function|number
---@return Layouter
function LayouterMetaTable:Right(right)
    self.c.Right:Set(right)
    return self
end

--- Sets the bottom side of the control
---@param bottom function|number
---@return Layouter
function LayouterMetaTable:Bottom(bottom)
    self.c.Bottom:Set(bottom)
    return self
end

--- Sets the width of the control
---@param width function|number #width will be scaled
---@return Layouter
function LayouterMetaTable:Width(width)
    if iscallable(width) then
        self.c.Width:SetFunction(width)
    else
        self.c.Width:SetValue(ScaleNumber(width))
    end
    return self
end

--- Sets the height of the control
---@param height function|number #height will be scaled
---@return Layouter
function LayouterMetaTable:Height(height)
    if iscallable(height) then
        self.c.Height:SetFunction(height)
    else
        self.c.Height:SetValue(ScaleNumber(height))
    end
    return self
end


-- Depth

--- Sets the depth of the control higher than a parent
---@param parent Control
---@param depth? integer defaults to 1
---@return Layouter
function LayouterMetaTable:Over(parent, depth)
    DepthOverParent(self.c, parent, depth)
    return self
end


--- Sets the depth of the control lower than a parent
---@param parent Control
---@param depth? integer defaults to 1
---@return Layouter
function LayouterMetaTable:Under(parent, depth)
    DepthUnderParent(self.c, parent, depth)
    return self
end



-- Single positioning methods

-- Anchors

--- Anchors the control to the left of a parent, with optional padding
---@param parent Control
---@param padding? number fixed padding between control and parent
---@return Layouter
function LayouterMetaTable:AnchorToLeft(parent, padding)
    AnchorToLeft(self.c, parent, padding)
    return self
end

--- Anchors a control to the top of a parent, with optional offset
---@param parent Control
---@param padding? number fixed padding between control and parent
---@return Layouter
function LayouterMetaTable:AnchorToTop(parent, padding)
    AnchorToTop(self.c, parent, padding)
    return self
end

--- Anchors a control to the right of a parent, with optional offset
---@param parent Control
---@param padding? number fixed padding between control and parent
---@return Layouter
function LayouterMetaTable:AnchorToRight(parent, padding)
    AnchorToRight(self.c, parent, padding)
    return self
end

--- Anchors a control to the bottom of a parent, with optional offset
---@param parent Control
---@param padding? number fixed padding between control and parent
---@return Layouter
function LayouterMetaTable:AnchorToBottom(parent, padding)
    AnchorToBottom(self.c, parent, padding)
    return self
end

-- Centered

--- Centers a control horizontally on a parent, with an optional offset
---@param parent Control
---@param leftOffset? number in right direction
---@return Layouter
function LayouterMetaTable:AtHorizontalCenterIn(parent, leftOffset)
    AtHorizontalCenterIn(self.c, parent, leftOffset)
    return self
end

--- Centers a control vertically on a parent, with an optional offset
---@param control Control
---@param parent Control
---@param topOffset? number in down direction
---@return Layouter
function LayouterMetaTable:AtVerticalCenterIn(parent, topOffset)
    AtVerticalCenterIn(self.c, parent, topOffset)
    return self
end

-- Inside

--- Places the control inside the left border of a parent, with optional right offset
---@param parent Control
---@param leftOffset? number
---@return Layouter
function LayouterMetaTable:AtLeftIn(parent, leftOffset)
    AtLeftIn(self.c, parent, leftOffset)
    return self
end

--- Places the control inside the top border of a parent, with optional down offset
---@param parent Control
---@param topOffset? number
---@return Layouter
function LayouterMetaTable:AtTopIn(parent, topOffset)
    AtTopIn(self.c, parent, topOffset)
    return self
end

--- Places the control inside the right border of a parent, with optional left offset
---@param parent Control
---@param rightOffset? number
---@return Layouter
function LayouterMetaTable:AtRightIn(parent, rightOffset)
    AtRightIn(self.c, parent, rightOffset)
    return self
end

--- Places the control inside the bottom border of a parent, with optional up offset
---@param parent Control
---@param bottomOffset? number
---@return Layouter
function LayouterMetaTable:AtBottomIn(parent, bottomOffset)
    AtBottomIn(self.c, parent, bottomOffset)
    return self
end

-- Resets

--- Resets the control's left to be calculated from its right and width
--- *Make sure Right and Width are defined!!!*
---@return Layouter
function LayouterMetaTable:ResetLeft()
    ResetLeft(self.c)
    return self
end

--- Resets the control's top to be calculated from its bottom and height
--- **Make sure Bottom and Height are defined!!!**
---@return Layouter
function LayouterMetaTable:ResetTop()
    ResetTop(self.c)
    return self
end

--- Resets the control's right to be calculated from its right and width
--- **Make sure Left and Width are defined!!!**
---@return Layouter
function LayouterMetaTable:ResetRight()
    ResetRight(self.c)
    return self
end

--- Resets the control's bottom to be calculated from its top and height
--- **Make sure Top and Height are Defined!!!**
---@return Layouter
function LayouterMetaTable:ResetBottom()
    ResetBottom(self.c)
    return self
end

--- Resets the control's width to be calculated from its right and left
--- **Make sure Right and Left are defined!!!**
---@return Layouter
function LayouterMetaTable:ResetWidth()
    ResetWidth(self.c)
    return self
end

--- Resets the control's height to be calculated from its top and bottom
--- **Make sure Bottom and Top are defined!!!**
---@return Layouter
function LayouterMetaTable:ResetHeight()
    ResetHeight(self.c)
    return self
end

--**********
--* Composite positioning
--**********

--- Surround positioning

--- Lock right of the control to left of a parent, centered vertically
---@param parent Control
---@param padding? number fixed padding between control and parent
---@return Layouter
function LayouterMetaTable:CenteredLeftOf(parent, padding)
    CenteredLeftOf(self.c, parent, padding)
    return self
end

--- Lock bottom of the control to top left of a parent, centered horizontally
---@param parent Control
---@param padding? number fixed padding between control and parent
---@return Layouter
function LayouterMetaTable:CenteredAbove(parent, padding)
    CenteredAbove(self.c, parent, padding)
    return self
end

--- Lock left of the control to right of a parent, centered vertically
---@param parent Control
---@param padding? number fixed padding between control and parent
---@return Layouter
function LayouterMetaTable:CenteredRightOf(parent, padding)
    CenteredRightOf(self.c, parent, padding)
    return self
end

--- Lock top of the control to bottom left of parent, centered horizontally
---@param parent Control
---@param padding? number fixed padding between control and parent
---@return Layouter
function LayouterMetaTable:CenteredBelow(parent, padding)
    CenteredBelow(self.c, parent, padding)
    return self
end


-- Inside positioning
-- note that the inside-edge layouts don't have a function counterpart like
-- the inside-corner layouts do

--- Places the control in the center of the parent, with optional offsets
---@param parent Control
---@param topOffset? number offset of top edge (offset in down direction)
---@param leftOffset? number offset of left edge (offset in right direction)
---@return Layouter
function LayouterMetaTable:AtCenterIn(parent, topOffset, leftOffset)
    AtCenterIn(self.c, parent, topOffset, leftOffset)
    return self
end

--- Places left edge of the control vertically centered inside of a parent's
---@param parent Control
---@param leftOffset? number
---@param topOffset? number
---@return Layouter
function LayouterMetaTable:AtLeftCenterIn(parent, leftOffset, topOffset)
    AtLeftIn(self.c, parent, leftOffset)
    AtVerticalCenterIn(self.c, parent, topOffset)
    return self
end

--- Places top left corner of the control inside of a parent's
---@param parent Control
---@param leftOffset? number
---@param topOffset? number
---@return Layouter
function LayouterMetaTable:AtLeftTopIn(parent, leftOffset, topOffset)
    AtLeftTopIn(self.c, parent, leftOffset, topOffset)
    return self
end

--- Places top edge of the control horizontally centered inside of a parent's
---@param parent Control
---@param topOffset? number
---@param leftOffset? number
---@return Layouter
function LayouterMetaTable:AtTopCenterIn(parent, topOffset, leftOffset)
    AtTopIn(self.c, parent, topOffset)
    AtHorizontalCenterIn(self.c, parent, leftOffset)
    return self
end

--- Places top right corner of the control inside of its parent's
---@param parent Control
---@param rightOffset? number
---@param topOffset? number
---@return Layouter
function LayouterMetaTable:AtRightTopIn(parent, rightOffset, topOffset)
    AtRightTopIn(self.c, parent, rightOffset, topOffset)
    return self
end

--- Places right edge of the control vertically centered inside of a parent's
---@param parent Control
---@param rightOffset? number
---@param topOffset? number
---@return Layouter
function LayouterMetaTable:AtRightCenterIn(parent, rightOffset, topOffset)
    AtRightIn(self.c, parent, rightOffset)
    AtVerticalCenterIn(self.c, parent, topOffset)
    return self
end

--- Places bottom right corner of the control inside of a parent's
---@param parent Control
---@param rightOffset? number
---@param bottomOffset? number
---@return Layouter
function LayouterMetaTable:AtRightBottomIn(parent, rightOffset, bottomOffset)
    AtRightBottomIn(self.c, parent, rightOffset, bottomOffset)
    return self
end

--- Places bottom edge of the control horizontally centered inside of a parent's
---@param parent Control
---@param leftOffset? number
---@param bottomOffset? number
---@return Layouter
function LayouterMetaTable:AtBottomCenterIn(parent, bottomOffset, leftOffset)
    AtBottomIn(self.c, parent, bottomOffset)
    AtHorizontalCenterIn(self.c, parent, leftOffset)
    return self
end

--- Places bottom left corner of the control inside of a parent's
---@param parent Control
---@param leftOffset? number
---@param bottomOffset? number
---@return Layouter
function LayouterMetaTable:AtLeftBottomIn(parent, leftOffset, bottomOffset)
    AtLeftBottomIn(self.c, parent, leftOffset, bottomOffset)
    return self
end


-- Out-of positioning

--- Lock top right of the control to top left of a parent
---@param control Control
---@param parent Control
---@param padding? number fixed padding between control and parent
---@return Layouter
function LayouterMetaTable:LeftOf(parent, padding)
    LeftOf(self.c, parent, padding)
    return self
end

--- Lock top left of the control to top right of a parent
---@param control Control
---@param parent Control
---@param padding? number fixed padding between control and parent
---@return Layouter
function LayouterMetaTable:RightOf(parent, padding)
    RightOf(self.c, parent, padding)
    return self
end

--- Lock bottom left of the control to top left of a parent
---@param control Control
---@param parent Control
---@param padding? number fixed padding between control and parent
---@return Layouter
function LayouterMetaTable:Above(parent, padding)
    Above(self.c, parent, padding)
    return self
end


--- Lock top left of the control to bottom left of a parent
---@param control Control
---@param parent Control
---@param padding? number fixed padding between control and parent
---@return Layouter
function LayouterMetaTable:Below(parent, padding)
    Below(self.c, parent, padding)
    return self
end

-- Fill parent

--- Sets control to fill a parent
--- Note this function copies the parent's side functions, it does not refer
---@param parent Control
---@return Layouter
function LayouterMetaTable:Fill(parent)
    FillParent(self.c, parent)
    return self
end

--- Sets control to fill a parent's with fixed padding
---@param parent Control
---@param offset? number
---@return Layouter
function LayouterMetaTable:FillFixedBorder(parent, offset)
    FillParentFixedBorder(self.c, parent, offset)
    return self
end


-- Calculates control's Properties to determine its layout completion and returns it
-- remember, if parent has incomplete layout it will warn you anyway
---@return Control
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

--- Returns a layouter for a control
---@param control Control
---@return Layouter
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

--- Use if you don't cache layouter object
---@param control Control
---@return Layouter #cached layouter
function ReusedLayoutFor(control)
    layouter.c = control or false
    return layouter
end
