local CIridiumRocketProjectile = import("/lua/cybranprojectiles.lua").CIridiumRocketProjectile

--- URA0203 : cybran T2 gunship & URA0401 : Soul Ripper
---@class CDFRocketIridium01 : CIridiumRocketProjectile
CDFRocketIridium01 = ClassProjectile(CIridiumRocketProjectile) { 
    -- scale values used for effects
    FxAirUnitHitScale = 1.5,
    FxLandHitScale = 1.5,
    FxNoneHitScale = 1.5,
    FxPropHitScale = 1.5,
    FxProjectileHitScale = 1.5,
    FxProjectileUnderWaterHitScale = 1,
    FxShieldHitScale = 1.5,
    FxUnderWaterHitScale = 0.25,
    FxUnitHitScale = 1.5,
    FxWaterHitScale = 1.5,
    FxOnKilledScale = 1,
}
TypeClass = CDFRocketIridium01