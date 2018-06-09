-----------------------------------------------------------------------------------------
-- File     :  /data/projectiles/SDFChronatronCannon02/SDFChronatronCannon02_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  ChronatronCannon Projectile script, Seraphim commander overcharge, XSL0001
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------------------

local SChronatronCannonOverCharge = import('/lua/seraphimprojectiles.lua').SChronatronCannonOverCharge
local OverchargeProjectile = import('/lua/sim/DefaultProjectiles.lua').OverchargeProjectile

SDFChronatronCannon02 = Class(SChronatronCannonOverCharge, OverchargeProjectile) {
    OnImpact = function(self, targetType, targetEntity)
        OverchargeProjectile.OnImpact(self, targetType, targetEntity)
        SChronatronCannonOverCharge.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = SDFChronatronCannon02
