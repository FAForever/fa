local AMissileSerpentineProjectile = import("/lua/aeonprojectiles.lua").AMissileSerpentineProjectile

--- Used by UAS0304 (T3 Stategic Missile Submarine)
---@class AIFMissileSerpentine02 : AMissileSerpentineProjectile
AIFMissileSerpentine02 = ClassProjectile(AMissileSerpentineProjectile) {
    FxWaterHitScale = 1.65,
}
TypeClass = AIFMissileSerpentine02