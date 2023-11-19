local CDFProtonCannonProjectile = import("/lua/cybranprojectiles.lua").CDFProtonCannonProjectile
local EffectTemplate = import("/lua/EffectTemplates.lua")

--- Cybran Proton Cannon
---@class CDFProtonCannon03 : CDFProtonCannonProjectile
CDFProtonCannon03 = ClassProjectile(CDFProtonCannonProjectile) {
    FxTrails = EffectTemplate.CProtonCannonFXTrail02,
    PolyTrail = EffectTemplate.CProtonCannonPolyTrail02,
}
TypeClass = CDFProtonCannon03