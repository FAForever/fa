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

local RadioCluster = import('/lua/ui/controls/radiocluster.lua').RadioCluster
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Layouter = LayoutHelpers.ReusedLayoutFor

local TabTexturePrefix = {
    construction = '/game/construct-tab_btn/top_tab_btn_',
    selection = '/game/construct-tab_btn/mid_tab_btn_',
    enhancement = '/game/construct-tab_btn/bot_tab_btn_',
}

local TabCheckboxClasses = {
    construction = Checkbox,
    selection = Checkbox,
    enhancement = Checkbox,
}

local Textures

local function GetTabTextures(id)
    if TabTexturePrefix[id] then
        local pre = TabTexturePrefix[id]
        return UIUtil.UIFile(pre..'up_bmp.dds'), UIUtil.UIFile(pre..'sel_bmp.dds'),
            UIUtil.UIFile(pre..'over_bmp.dds'), UIUtil.UIFile(pre..'down_bmp.dds'),
            UIUtil.UIFile(pre..'dis_bmp.dds'), UIUtil.UIFile(pre..'dis_bmp.dds')
    end
end

---@class ConstructionTabCluster : RadioCluster
ConstructionTabCluster = ClassUI(RadioCluster) {

    __init = function(self, parent, SelectionCallback)
        RadioCluster.__init(self, parent, TabCheckboxClasses, SelectionCallback)
    end,

    ---We need to determine our size based on the size of our children, then layout
    OnLayout = function(self)
        
        local maxWidth = 0
        local totalHeight = 0
        for key, item in self.items do
            self.items[key]:SetNewTextures(GetTabTextures(key))
            maxWidth = math.max(maxWidth, item.Width())
            totalHeight = totalHeight + item.Height()
        end
        LayoutHelpers.SetDimensions(self, maxWidth, totalHeight - 32)
    end,

    Layout = function(self)

        Layouter(self.items.construction)
            :AtLeftTopIn(self)
        Layouter(self.items.selection)
            :Below(self.items.construction, -16)
        Layouter(self.items.enhancement)
            :Below(self.items.selection, -16)

    end,
}