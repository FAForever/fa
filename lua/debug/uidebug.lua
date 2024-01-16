--******************************************************************************************************
--** Copyright (c) 2024  FAForever
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

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Statistics = import("/lua/shared/statistics.lua")

local fps = false

local framerateCurrent = 1
local framerateMax = 30
local framerates = {}
for k = 1, framerateMax do
    framerates[k] = 0
end

function ShowFPS()
    if fps then
        fps:Destroy()
        fps = false
        return
    end

    fps = UIUtil.CreateText(GetFrame(0), '', 12)
    fps:SetColor('ffffff')
    fps:SetFont(UIUtil.fixedFont, 12)
    fps:SetDropShadow(true)
    fps:DisableHitTest()
    fps.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    LayoutHelpers.AtRightTopIn(fps, GetFrame(0), 425, 0)

    fps:SetNeedsFrameUpdate(true)
    fps.OnFrame = function(self, deltatime)
        for key, val in __EngineStats.Children do
            if val.Name == 'Frame' then
                for childKey, childVal in val.Children do
                    if childVal.Name == 'FPS' then

                        framerates[framerateCurrent] = childVal.Value
                        framerateCurrent = framerateCurrent + 1
                        if framerateCurrent > framerateMax then
                            framerateCurrent = 1
                        end

                        local mean = Statistics.Mean(framerates, framerateMax)
                        local std = Statistics.Deviation(framerates, framerateMax, mean)

                        self:SetText(string.format("FPS: %03.0f (σ %0.03f)", mean, std))
                        break
                    end
                end
                break
            end
        end
    end
end

--- Called by the module manager when this module is dirty due to a disk change
function __moduleinfo.OnDirty()
    if fps then
        fps:Destroy()
    end
end
