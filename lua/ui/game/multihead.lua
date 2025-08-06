--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
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

--- This module is responsible for creating the secondary worldview.
---
--- This module is tightly coupled with the following module(s):
--- - lua/ui/game/worldview.lua

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

---@type WorldView | false
view = false

--- Shows the logo in the secondary adapter.
function ShowLogoInHead1()
    -- don't do anything if there's only one root frame
    if GetNumRootFrames() < 2 then
        return
    end

    local rootFrame = GetFrame(1)
    local bg = Bitmap(rootFrame, UIUtil.UIFile('/marketing/splash.dds'))
    LayoutHelpers.FillParentPreserveAspectRatio(bg, rootFrame)
end

--- Creates a world view on the secondary adapter. The worldview is registered and available in the world view manager.
---
--- This function is referenced directly by the engine.
function CreateSecondView()
    -- don't do anything if there's only one root frame
    if GetNumRootFrames() < 2 then
        return
    end

    ClearFrame(1)
    secondHeadGroup = Group(GetFrame(1), "secondHeadGroup")
    LayoutHelpers.FillParent(secondHeadGroup, GetFrame(1))

    view = import("/lua/ui/controls/worldview.lua").WorldView(secondHeadGroup, 'CameraHead2', 1, false) -- depth value should be below minimap
    view:Register('CameraHead2', nil, '<LOC map_view_0003>Secondary View', 3)
    view:SetRenderPass(UIUtil.UIRP_UnderWorld | UIUtil.UIRP_PostGlow) -- don't change this or the camera will lag one frame behind
    LayoutHelpers.FillParent(view, secondHeadGroup)
end

-- backwards compatibility for mods

local GameCommon = import("/lua/ui/game/gamecommon.lua")
