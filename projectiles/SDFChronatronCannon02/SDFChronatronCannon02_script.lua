-- File     :  /data/projectiles/SDFChronatronCannon02/SDFChronatronCannon02_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  ChronatronCannon Projectile script, Seraphim commander overcharge, XSL0001
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------------------
local SChronatronCannonOverCharge = import("/lua/seraphimprojectiles.lua").SChronatronCannonOverCharge
local OverchargeProjectile = import("/lua/sim/DefaultProjectiles.lua").OverchargeProjectile

SDFChronatronCannon02 = ClassProjectile(SChronatronCannonOverCharge, OverchargeProjectile) {
    OnImpact = function(self, targetType, targetEntity)
        -- we need to run this the overcharge logic before running the usual on impact because that is where the damage is determined
        OverchargeProjectile.OnImpact(self, targetType, targetEntity)
        SChronatronCannonOverCharge.OnImpact(self, targetType, targetEntity)
    end,

    OnCreate = function(self)
        SChronatronCannonOverCharge.OnCreate(self)
        OverchargeProjectile.OnCreate(self)
    end,
}
TypeClass = SDFChronatronCannon02