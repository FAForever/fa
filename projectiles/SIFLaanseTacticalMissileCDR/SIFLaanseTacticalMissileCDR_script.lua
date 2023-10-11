
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

--- Used by the ACU
---@class SIFLaanseTacticalMissileCDR : SLaanseTacticalMissile, TacticalMissileComponent
SIFLaanseTacticalMissileCDR = ClassProjectile(SLaanseTacticalMissile, TacticalMissileComponent) {

    LaunchTicks = 16,
    LaunchTicksRange = 1,
    LaunchTurnRate = 20,
    LaunchTurnRateRange = 1,
    HeightDistanceFactor = 8,
    HeightDistanceFactorRange = 0,
    MinHeight = 5,
    MinHeightRange = 0,
    FinalBoostAngle = 30,
    FinalBoostAngleRange = 0,

    OnCreate = function(self)
        SLaanseTacticalMissile.OnCreate(self)
        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread,self))
    end,
}
TypeClass = SIFLaanseTacticalMissileCDR

