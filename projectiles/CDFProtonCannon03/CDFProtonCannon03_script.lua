--
-- CDFProtonCannon03
--
local CDFProtonCannonProjectile = import('/lua/cybranprojectiles.lua').CDFProtonCannonProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')

CDFProtonCannon03 = Class(CDFProtonCannonProjectile) {

    FxTrails = EffectTemplate.CProtonCannonFXTrail02,
    PolyTrail = EffectTemplate.CProtonCannonPolyTrail02,
}
TypeClass = CDFProtonCannon03

