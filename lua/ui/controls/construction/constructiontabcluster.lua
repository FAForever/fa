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

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Layouter = LayoutHelpers.ReusedLayoutFor

local TabTexturePrefix = {
    construction = '/game/construct-tab_btn/top_tab_btn_',
    selection = '/game/construct-tab_btn/mid_tab_btn_',
    enhancement = '/game/construct-tab_btn/bot_tab_btn_',
}

local Textures

local function GetTabTextures(id)
    if TabTexturePrefix[id] then
        local pre = TabTexturePrefix[id]
        return UIUtil.UIFile(pre..'up_bmp.dds'), UIUtil.UIFile(pre..'sel_bmp.dds'),
            UIUtil.UIFile(pre..'over_bmp.dds'), UIUtil.UIFile(pre..'down_bmp.dds'),
            UIUtil.UIFile(pre..'dis_bmp.dds'), UIUtil.UIFile(pre..'dis_bmp.dds')
    elseif techFiles[id] then
        local pre = techFiles[id]
        return UIUtil.UIFile(pre..'up.dds'), UIUtil.UIFile(pre..'selected.dds'),
            UIUtil.UIFile(pre..'over.dds'), UIUtil.UIFile(pre..'down.dds'),
            UIUtil.UIFile(pre..'dis.dds'), UIUtil.UIFile(pre..'dis.dds')
    end
end

FetchConstructionTabTextures = function