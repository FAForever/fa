local MobileUnit = import('/lua/sim/units/MobileUnit.lua').MobileUnit
local EffectTemplate = import('/lua/EffectTemplates.lua')

SubUnit = Class(MobileUnit) {
    -- use default spark effect until underwater damaged states are made
    FxDamage1 = {EffectTemplate.DamageSparks01},
    FxDamage2 = {EffectTemplate.DamageSparks01},
    FxDamage3 = {EffectTemplate.DamageSparks01},

    -- DESTRUCTION PARAMS
    ShowUnitDestructionDebris = false,
    DeathThreadDestructionWaitTime = 0,
}
