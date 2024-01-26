local AMissileSerpentineProjectile = import("/lua/aeonprojectiles.lua").AMissileSerpentineProjectile

--- Aeon Serpentine Missile
---@class AIFMissileSerpentine02 : AMissileSerpentineProjectile
AIFMissileSerpentine02 = ClassProjectile(AMissileSerpentineProjectile) {
    FxWaterHitScale = 1.65,
}
TypeClass = AIFMissileSerpentine02