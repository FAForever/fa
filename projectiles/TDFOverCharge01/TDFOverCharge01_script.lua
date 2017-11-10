-- UEF Blaster

local TLaserBotProjectile = import('/lua/terranprojectiles.lua').TLaserBotProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')
local OverchargeProjectile = import('/lua/sim/DefaultProjectiles.lua').OverchargeProjectile

TDFOverCharge01 = Class(TLaserBotProjectile, OverchargeProjectile) {
    FxTrails = EffectTemplate.TCommanderOverchargeFXTrail01,
    FxTrailScale = 1.0,

	-- Hit Effects
    FxImpactUnit =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactProp =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactLand =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactAirUnit =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactUnderWater = {},

    OnImpact = function(self, targetType, targetEntity)
        OverchargeProjectile.OnImpact(self, targetType, targetEntity)
        TLaserBotProjectile.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = TDFOverCharge01
