#
# Cybran Molecular Cannon
#
local CMolecularCannonProjectile = import('/lua/cybranprojectiles.lua').CMolecularCannonProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')

CDFCannonMolecular01 = Class(CMolecularCannonProjectile) {

    PolyTrail = '/effects/emitters/default_polytrail_03_emit.bp',
    FxTrails = EffectTemplate.CCommanderOverchargeFxTrail01,

    # Hit Effects
    FxImpactUnit = EffectTemplate.CCommanderOverchargeHit01,
    FxImpactProp = EffectTemplate.CCommanderOverchargeHit01,
    FxImpactLand = EffectTemplate.CCommanderOverchargeHit01,
}
TypeClass = CDFCannonMolecular01

