--**********************************************************************************
--** Copyright (c) 2023 FAForever
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

local RadarJammerUnit = import('/lua/defaultunits.lua').RadarJammerUnit
local RadarJammerUnitOnStopBeingBuilt = RadarJammerUnit.OnStopBeingBuilt
local RadarJammerUnitOnIntelEnabled = RadarJammerUnit.OnIntelEnabled
local RadarJammerUnitOnIntelDisabled = RadarJammerUnit.OnIntelDisabled

-- upvalue scope for performance
local CreateAnimator = CreateAnimator
local CreateRotator = CreateRotator

---@class ARadarJammerUnit : RadarJammerUnit
---@field Rotator? moho.RotateManipulator
---@field OpenAnim? moho.AnimationManipulator
ARadarJammerUnit = ClassUnit(RadarJammerUnit) {
    RotateSpeed = 60,

    ---@param self ARadarJammerUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        RadarJammerUnitOnStopBeingBuilt(self, builder, layer)
        local animation = self.Blueprint.Display.AnimationOpen
        if not animation then
            return
        end

        local trash = self.Trash
        local openAnimation = self.OpenAnim
        if not openAnimation then
            openAnimation = CreateAnimator(self)
            openAnimation:PlayAnim(animation)
            self.OpenAnim = trash:Add(openAnimation)
        end

        local rotator = self.Rotator
        if not rotator then
            rotator = CreateRotator(self, 'B02', 'z', nil, 0, 50, 0)
            self.Rotator = trash:Add(rotator)
        end
    end,

    ---@param self ARadarJammerUnit
    ---@param intel string
    OnIntelEnabled = function(self, intel)
        RadarJammerUnitOnIntelEnabled(self, intel)

        local openAnimation = self.OpenAnim
        if openAnimation then
            openAnimation:SetRate(1)
        end

        local rotator = self.Rotator
        if rotator then
            rotator:SetSpinDown(false)
            rotator:SetTargetSpeed(self.RotateSpeed)
        end
    end,

    ---@param self ARadarJammerUnit
    ---@param intel string
    OnIntelDisabled = function(self, intel)
        RadarJammerUnitOnIntelDisabled(self, intel)

        local openAnimation = self.OpenAnim
        if openAnimation then
            openAnimation:SetRate(-1)
        end

        local rotator = self.Rotator
        if rotator then
            rotator:SetTargetSpeed(0)
        end
    end,
}
