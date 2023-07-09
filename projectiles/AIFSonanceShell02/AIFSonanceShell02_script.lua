local AArtilleryProjectile = import("/lua/aeonprojectiles.lua").AArtilleryProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")

-- Aeon T3 Static Artillery Projectile : uab2302
---@class AIFSonanceShell02: AArtilleryProjectile
AIFSonanceShell02 = ClassProjectile(AArtilleryProjectile) {
    FxTrails = EffectTemplate.ASonanceWeaponFXTrail02,
    FxImpactUnit =  EffectTemplate.ASonanceWeaponHit02,
    FxImpactProp =  EffectTemplate.ASonanceWeaponHit02,
    FxImpactLand =  EffectTemplate.ASonanceWeaponHit02,

    ---@param self AIFSonanceShell02
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)
        AArtilleryProjectile.OnImpact( self, targetType, targetEntity )
        self:ShakeCamera(20, 2, 0, 1)
    end,
}
TypeClass = AIFSonanceShell02