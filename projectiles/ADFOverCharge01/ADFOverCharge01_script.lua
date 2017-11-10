-- Aeon Mortar

local ALaserBotProjectile = import('/lua/aeonprojectiles.lua').ALaserBotProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')
local OverchargeProjectile = import('/lua/sim/DefaultProjectiles.lua').OverchargeProjectile

TDFOverCharge01 = Class(ALaserBotProjectile, OverchargeProjectile) {

    PolyTrail = '/effects/emitters/aeon_commander_overcharge_trail_01_emit.bp',
    FxTrails = EffectTemplate.ACommanderOverchargeFXTrail01,

    FxImpactUnit = EffectTemplate.ACommanderOverchargeHit01,
    FxImpactProp = EffectTemplate.ACommanderOverchargeHit01,
    FxImpactLand = EffectTemplate.ACommanderOverchargeHit01,

    OnImpact = function(self, targetType, targetEntity)
        OverchargeProjectile.OnImpact(self, targetType, targetEntity)
        ALaserBotProjectile.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = TDFOverCharge01
