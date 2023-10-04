-- File     :  /data/projectiles/SIFLaanseTacticalMissile02/SIFLaanseTacticalMissile02_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Laanse Tactical Missile Projectile script, XSS0202
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------------------------
local SLaanseTacticalMissile = import("/lua/seraphimprojectiles.lua").SLaanseTacticalMissile
local TacticalMissileComponent = import('/lua/sim/DefaultProjectiles.lua').TacticalMissileComponent

SIFLaanseTacticalMissile02 = ClassProjectile(SLaanseTacticalMissile, TacticalMissileComponent) {

    LaunchTicks = 3,
    LaunchTicksRange = 1,
    LaunchTurnRate = 6,
    LaunchTurnRateRange = 1,
    HeightDistanceFactor = 5,
    MinHeight = 10,
    FinalBoostAngle = 50,

    OnCreate = function(self)
        SLaanseTacticalMissile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.Trash:Add(ForkThread( self.MovementThread,self ))
    end,
}
TypeClass = SIFLaanseTacticalMissile02

