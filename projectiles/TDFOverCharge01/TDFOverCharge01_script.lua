-- UEF Blaster

local TLaserBotProjectile = import("/lua/terranprojectiles.lua").TLaserBotProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")
local OverchargeProjectile = import("/lua/sim/defaultprojectiles.lua").OverchargeProjectile

TDFOverCharge01 = ClassProjectile(TLaserBotProjectile, OverchargeProjectile) {
    FxTrails = EffectTemplate.TCommanderOverchargeFXTrail01,
    FxTrailScale = 1.0,

	-- Hit Effects
    FxImpactUnit =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactProp =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactLand =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactAirUnit =  EffectTemplate.TCommanderOverchargeHit01,

    OnImpact = function(self, targetType, targetEntity)
        TLaserBotProjectile.OnImpact(self, targetType, targetEntity)
        OverchargeProjectile.OnImpact(self, targetType, targetEntity)
    end,
    
    OnCreate = function(self)
        TLaserBotProjectile.OnCreate(self)
        OverchargeProjectile.OnCreate(self)
    end,
}

TypeClass = TDFOverCharge01
