#****************************************************************************
#**
#**  File     :  /data/projectiles/SDFLightChronatronCannon02/SDFLightChronatronCannon02_script.lua
#**  Author(s):  Gordon Duclos
#**
#**  Summary  :  Light Chronatron Cannon Projectile script, Seraphim sub-commander overcharge, XSL0301
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local OverchargeProjectile = import('/lua/sim/DefaultProjectiles.lua').OverchargeProjectile
local SLightChronatronCannonOverCharge = import('/lua/seraphimprojectiles.lua').SLightChronatronCannonOverCharge

SDFLightChronatronCannon02 = Class(SLightChronatronCannonOverCharge, OverchargeProjectile) {
    OnImpact = function(self, targetType, targetEntity)
        OverchargeProjectile.OnImpact(self, targetType, targetEntity)
        SLightChronatronCannonOverCharge.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = SDFLightChronatronCannon02