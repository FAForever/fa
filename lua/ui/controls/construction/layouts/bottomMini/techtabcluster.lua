--******************************************************************************************************
--** Copyright (c) 2024 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

local SkinnableFile = import('/lua/ui/uiutil.lua').SkinnableFile
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Layouter = LayoutHelpers.ReusedLayoutFor

local TabCheckboxTextures = import('/lua/ui/controls/construction/layouts/techtabicons.lua').TechTabTexturePrefixes

local function GetTabTextures(id)
    if TabCheckboxTextures[id] then
        local pre = TabCheckboxTextures[id]
        return SkinnableFile(pre..'up.dds'),
            SkinnableFile(pre..'selected.dds'),
            SkinnableFile(pre..'over.dds'),
            SkinnableFile(pre..'down.dds'),
            SkinnableFile(pre..'dis.dds'),
            SkinnableFile(pre..'dis.dds')
    end
end

-- Calling this applies the Layout functions in this file to the given control
-- It adds the OnLayout and Layout functions, and the SubLayout table
InitLayoutFunctions = function(control)
    control.OnLayout = OnLayout
    control.Layout = Layout
end

---This updates the textures of our buttons based on the keys, and is called whenever
---said keys are updated
---@param self TechTabCluster
OnLayout = function(self)
    local maxHeight = 0
    local totalWidth = 0
    for i, item in self.items do
        if item.key and TabCheckboxTextures[item.key] then
            item:SetNewTextures(GetTabTextures(item.key))
            maxHeight = math.max(maxHeight, item.Height())
            totalWidth = totalWidth + item.Width()
        else
            item:Hide()
        end
    end
    LayoutHelpers.SetDimensions(self, totalWidth, maxHeight)
end

Layout = function(self)
    local previousItem
    for i, item in self.items do
        if i == 1 then
            LayoutHelpers.AtLeftTopIn(item, self)
        else
            LayoutHelpers.RightOf(item, previousItem)
        end
        previousItem = item
    end
end