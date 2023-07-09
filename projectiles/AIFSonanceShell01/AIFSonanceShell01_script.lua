local AArtilleryProjectile = import("/lua/aeonprojectiles.lua").AArtilleryProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")

-- Aeon T3 Mobile Artillery Projectile : ual0304
---@class AIFSonanceShell01: AArtilleryProjectile
AIFSonanceShell01 = ClassProjectile(AArtilleryProjectile) {

    PolyTrail = '/effects/emitters/aeon_sonicgun_trail_emit.bp',
    FxTrails = EffectTemplate.ASonanceWeaponFXTrail01,
    FxImpactUnit =  EffectTemplate.ASonanceWeaponHit02,
    FxImpactProp =  EffectTemplate.ASonanceWeaponHit02,
    FxImpactLand =  EffectTemplate.ASonanceWeaponHit02,

    ---@param self AIFSonanceShell01
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)
        AArtilleryProjectile.OnImpact(self, targetType, targetEntity)

        -- our favorite shake: the camera shake
        self:ShakeCamera( 20, 1, 0, 1 )
    end,
}
TypeClass = AIFSonanceShell01