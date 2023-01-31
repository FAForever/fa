--
-- CDFProtonCannon03
--
local CDFProtonCannonProjectile = import("/lua/cybranprojectiles.lua").CDFProtonCannonProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")

CDFProtonCannon03 = ClassProjectile(CDFProtonCannonProjectile) {

    FxTrails = EffectTemplate.CProtonCannonFXTrail02,
    PolyTrail = EffectTemplate.CProtonCannonPolyTrail02,
}
TypeClass = CDFProtonCannon03

