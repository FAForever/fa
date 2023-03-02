--
-- Aeon T3 Static Artillery Projectile : uab2302
--

local AArtilleryProjectile = import("/lua/aeonprojectiles.lua").AArtilleryProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat

AIFSonanceShell02 = Class(AArtilleryProjectile) {
    
    FxTrails = EffectTemplate.ASonanceWeaponFXTrail02,
    
    FxImpactUnit =  EffectTemplate.ASonanceWeaponHit02,
    FxImpactProp =  EffectTemplate.ASonanceWeaponHit02,
    FxImpactLand =  EffectTemplate.ASonanceWeaponHit02,
    
    OnImpact = function(self, targetType, targetEntity)
        AArtilleryProjectile.OnImpact( self, targetType, targetEntity )

        -- from left to right!
        self:ShakeCamera(20, 2, 0, 1)
    end,
}

TypeClass = AIFSonanceShell02