-- File     :  /data/projectiles/SDFLightChronatronCannon02/SDFLightChronatronCannon02_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Light Chronatron Cannon Projectile script, Seraphim sub-commander overcharge, XSL0301
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------------------------------
local SLightChronatronCannonOverCharge = import("/lua/seraphimprojectiles.lua").SLightChronatronCannonOverCharge
local OverchargeProjectile = import("/lua/sim/DefaultProjectiles.lua").OverchargeProjectile

SDFLightChronatronCannon02 = ClassProjectile(SLightChronatronCannonOverCharge, OverchargeProjectile) {
    OnImpact = function(self, targetType, targetEntity)
        SLightChronatronCannonOverCharge.OnImpact(self, targetType, targetEntity)
        OverchargeProjectile.OnImpact(self, targetType, targetEntity)
    end,

    OnCreate = function(self)
        SLightChronatronCannonOverCharge.OnCreate(self)
        OverchargeProjectile.OnCreate(self)
    end,
}
TypeClass = SDFLightChronatronCannon02