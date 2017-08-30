#
# Aeon Mortar
#
local TLaserBotProjectile = import('/lua/terranprojectiles.lua').TLaserBotProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')

TDFOverCharge01 = Class(TLaserBotProjectile) {
    FxTrails = EffectTemplate.TCommanderOverchargeFXTrail01,
    FxTrailScale = 1.0,    

	# Hit Effects
    FxImpactUnit =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactProp =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactLand =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactAirUnit =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactUnderWater = {},
}

TypeClass = TDFOverCharge01

