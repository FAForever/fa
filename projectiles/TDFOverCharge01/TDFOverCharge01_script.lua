local TLaserBotProjectile = import("/lua/terranprojectiles.lua").TLaserBotProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")
local OverchargeProjectile = import("/lua/sim/defaultprojectiles.lua").OverchargeProjectile

-- UEF Blaster
---@class TDFOverCharge01 : TLaserBotProjectile, OverchargeProjectile
TDFOverCharge01 = ClassProjectile(TLaserBotProjectile, OverchargeProjectile) {
    FxTrails = EffectTemplate.TCommanderOverchargeFXTrail01,
    FxTrailScale = 1.0,

	-- Hit Effects
    FxImpactUnit =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactProp =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactLand =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactAirUnit =  EffectTemplate.TCommanderOverchargeHit01,

    ---@param self TDFOverCharge01
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)
        -- we need to run this the overcharge logic before running the usual on impact because that is where the damage is determined
        OverchargeProjectile.OnImpact(self, targetType, targetEntity)
        TLaserBotProjectile.OnImpact(self, targetType, targetEntity)
    end,

    ---@param self TDFOverCharge01
    OnCreate = function(self)
        TLaserBotProjectile.OnCreate(self)
        OverchargeProjectile.OnCreate(self)
    end,
}
TypeClass = TDFOverCharge01