local ALaserBotProjectile = import("/lua/aeonprojectiles.lua").ALaserBotProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")
local OverchargeProjectile = import("/lua/sim/defaultprojectiles.lua").OverchargeProjectile

-- Aeon Mortar
---@class TDFOverCharge01 : ALaserBotProjectile, OverchargeProjectile
TDFOverCharge01 = ClassProjectile(ALaserBotProjectile, OverchargeProjectile) {
    PolyTrail = '/effects/emitters/aeon_commander_overcharge_trail_01_emit.bp',
    FxTrails = EffectTemplate.ACommanderOverchargeFXTrail01,
    FxImpactUnit = EffectTemplate.ACommanderOverchargeHit01,
    FxImpactProp = EffectTemplate.ACommanderOverchargeHit01,
    FxImpactLand = EffectTemplate.ACommanderOverchargeHit01,

    ---@param self TDFOverCharge01
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        -- we need to run this the overcharge logic before running the usual on impact because that is where the damage is determined
        OverchargeProjectile.OnImpact(self, targetType, targetEntity)
        ALaserBotProjectile.OnImpact(self, targetType, targetEntity)
    end,

    ---@param self TDFOverCharge01
    OnCreate = function(self)
        ALaserBotProjectile.OnCreate(self)
        OverchargeProjectile.OnCreate(self)
    end,
}
TypeClass = TDFOverCharge01