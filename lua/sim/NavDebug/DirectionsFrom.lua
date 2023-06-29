--**********************************************************************************
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
--**********************************************************************************

local Shared = import("/lua/shared/navgenerator.lua")
local NavUtils = import("/lua/sim/navutils.lua")

local Enabled = false

function Enable()
    NavUtils.Generate()
    Enabled = true
end

function Disable()
    Enabled = false
end

---@class NavDebugDirectionsFromState
---@field Layer NavLayers
---@field Distance number
---@field Threshold number
local State = {}

---@param data NavDebugDirectionsFromState
function Update(data)
    State = data
end

function Debug()
    while true do
        if Enabled then
            local origin = GetMouseWorldPos()
            local layer = State.Layer
            local distance = State.Distance
            local threshold = State.Threshold
            if layer and origin and distance and threshold then
                local directions, error = NavUtils.DirectionsFrom(layer, origin, distance, threshold)
                if directions then
                    DrawCircle(origin, 10, 'ffffff')
                    for k, direction in directions do
                        DrawLinePop(origin, direction, 'ffffff')
                    end
                else
                    DrawCircle(origin, 10, 'ff0000')
                    WARN("NavDirectionsFrom - " .. error)
                end
            end
        end

        WaitTicks(1)
    end
end

local DebugThread = ForkThread(Debug)

--- Called by the module manager when this module is dirty due to a disk change
function __moduleinfo.OnDirty()
    if DebugThread then
        DebugThread:Destroy()
    end
end
