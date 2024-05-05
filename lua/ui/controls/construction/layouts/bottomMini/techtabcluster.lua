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

local TabCheckboxTextures = {
    t1 = '/game/construct-tech_btn/t1_btn_',
    t2 = '/game/construct-tech_btn/t2_btn_',
    t3 = '/game/construct-tech_btn/t3_btn_',
    t4 = '/game/construct-tech_btn/t4_btn_',
    templates = '/game/construct-tech_btn/template_btn_',
    LCH = '/game/construct-tech_btn/left_upgrade_btn_',
    RCH = '/game/construct-tech_btn/r_upgrade_btn_',
    Back = '/game/construct-tech_btn/m_upgrade_btn_',
}

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

local OnLayout = function(self)
    local maxHeight = 0
    local totalWidth = 0
    for key, item in self.items do
        self.items[key]:SetNewTextures(GetTabTextures(key))
        maxHeight = math.max(maxHeight, item.Height())
        totalWidth = totalWidth + item.Width()
    end
    LayoutHelpers.SetDimensions(self, totalWidth, maxHeight)
end

local Layout = function(self)

    -- We could do this in a loop, but it's nice to spell it out so it's clear.
    Layouter(self.items.t1)
        :AtLeftTopIn(self)
    Layouter(self.items.t2)
        :RightOf(self.items.t1)
    Layouter(self.items.t3)
        :RightOf(self.items.t2)
    Layouter(self.items.t4)
        :RightOf(self.items.t3)
    Layouter(self.items.templates)
        :RightOf(self.items.t4)

end