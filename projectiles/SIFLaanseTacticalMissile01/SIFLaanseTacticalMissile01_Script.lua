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

local SLaanseTacticalMissile = import("/lua/seraphimprojectiles.lua").SLaanseTacticalMissile
local TacticalMissileComponent = import('/lua/sim/DefaultProjectiles.lua').TacticalMissileComponent

--- Used by XSL0111
---@class SIFLaanseTacticalMissile01 : SLaanseTacticalMissile, TacticalMissileComponent
SIFLaanseTacticalMissile01 = ClassProjectile(SLaanseTacticalMissile, TacticalMissileComponent) {

    LaunchTicks = 6,
    LaunchTicksRange = 1,
    LaunchTurnRate = 8,
    LaunchTurnRateRange = 1,
    HeightDistanceFactor = 5,
    HeightDistanceFactorRange = 0,
    MinHeight = 4,
    MinHeightRange = 0,
    FinalBoostAngle = 12,
    FinalBoostAngleRange = 2,

    ---@param self SIFLaanseTacticalMissile01
    OnCreate = function(self)
        SLaanseTacticalMissile.OnCreate(self)
        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread, self))
    end,
}
TypeClass = SIFLaanseTacticalMissile01