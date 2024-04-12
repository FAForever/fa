
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
local SLaanseTacticalMissileOnCreate = SLaanseTacticalMissile.OnCreate
local SLaanseTacticalMissileOnImpact = SLaanseTacticalMissile.OnImpact
local TacticalMissileComponent = import('/lua/sim/DefaultProjectiles.lua').TacticalMissileComponent

--- used by XSB2108
---@class SIFLaanseTacticalMissile04 : SLaanseTacticalMissile, TacticalMissileComponent
SIFLaanseTacticalMissile04 = ClassProjectile(SLaanseTacticalMissile, TacticalMissileComponent) {

    LaunchTicks = 9,
    LaunchTicksRange = 1,
    LaunchTurnRate = 20,
    LaunchTurnRateRange = 1,
    HeightDistanceFactor = 8,
    HeightDistanceFactorRange = 0,
    MinHeight = 5,
    MinHeightRange = 0,
    FinalBoostAngle = 30,
    FinalBoostAngleRange = 0,

    TerminalSpeed = 13,
    TerminalDistance = 30,

    ---@param self SIFLaanseTacticalMissile04
    OnCreate = function(self)
        SLaanseTacticalMissileOnCreate(self)

        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread, self))
    end,

    --- Called by the engine when the projectile impacts something
    ---@param self Projectile
    ---@param targetType string
    ---@param targetEntity Unit | Prop
    OnImpact = function(self, targetType, targetEntity)
        SLaanseTacticalMissileOnImpact(self, targetType, targetEntity)

        local army = self.Army

        -- create light flashes
        CreateLightParticleIntel(self, -1, army, 6, 2, 'flare_lens_add_02', 'ramp_blue_build_spray')
        CreateLightParticleIntel(self, -1, army, 10, 4, 'flare_lens_add_02', 'ramp_ser_11')
    end
}
TypeClass = SIFLaanseTacticalMissile04
