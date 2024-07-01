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

local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Layouter = LayoutHelpers.ReusedLayoutFor
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local SkinnableFile = import('/lua/ui/uiutil.lua').SkinnableFile

local textures = {
    leftBracketLower = SkinnableFile('/game/bracket-left-energy/bracket_bmp_t.dds'),
    leftBracketUpper = SkinnableFile('/game/bracket-left-energy/bracket_bmp_b.dds'),
    leftBracketMiddle = SkinnableFile('/game/bracket-left-energy/bracket_bmp_m.dds'),
}

local TabCheckboxTextures = {
    construction = '/game/construct-tab_btn/top_tab_btn_',
    selection = '/game/construct-tab_btn/mid_tab_btn_',
    enhancement = '/game/construct-tab_btn/bot_tab_btn_',
}

local function GetTabTextures(id)
    if TabCheckboxTextures[id] then
        local pre = TabCheckboxTextures[id]
        return SkinnableFile(pre..'up_bmp.dds'),
            SkinnableFile(pre..'sel_bmp.dds'),
            SkinnableFile(pre..'over_bmp.dds'),
            SkinnableFile(pre..'down_bmp.dds'),
            SkinnableFile(pre..'dis_bmp.dds'),
            SkinnableFile(pre..'dis_bmp.dds')
    end
end

-- Calling this applies the Layout functions in this file to the given control
-- It adds the OnLayout and Layout functions, and the SubLayout table
InitLayoutFunctions = function(control)
    control.OnLayout = OnLayout
    control.Layout = Layout
end

---We need to determine our size based on the size of our children, then layout
OnLayout = function(self)

    if not self.leftBracketLower then self.leftBracketLower = Bitmap(self) end
    if not self.leftBracketUpper then self.leftBracketUpper = Bitmap(self) end
    if not self.leftBracketMiddle then self.leftBracketMiddle = Bitmap(self) end

    local maxWidth = 0
    local totalHeight = 0
    for key, item in self.items do
        self.items[key]:SetNewTextures(GetTabTextures(key))
        maxWidth = math.max(maxWidth, item.Width())
        totalHeight = totalHeight + item.Height()
    end
    LayoutHelpers.SetDimensions(self, maxWidth, totalHeight - 32)
end

Layout = function(self)

    Layouter(self.items.construction)
        :AtLeftTopIn(self)
    Layouter(self.items.selection)
        :Below(self.items.construction, -16)
    Layouter(self.items.enhancement)
        :Below(self.items.selection, -16)

    Layouter(self.leftBracketLower)
        :Texture(textures.leftBracketLower)
        :AtLeftTopIn(self, 4, 7)

    Layouter(self.leftBracketUpper)
        :Texture(textures.leftBracketUpper)
        :AtLeftIn(self.leftBracketLower)
        :AtBottomIn(self, 8)

    Layouter(self.leftBracketMiddle)
        :Texture(textures.leftBracketMiddle)
        :AtLeftIn(self.leftBracketLower)
        :Bottom(self.leftBracketUpper.Top)
        :Top(self.leftBracketLower.Bottom)

end