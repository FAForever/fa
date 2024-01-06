local AMissileSerpentineProjectile = import("/lua/aeonprojectiles.lua").AMissileSerpentineProjectile

-- Aeon Serpentine Missile
---@class AIFMissileSerpentine01: AMissileSerpentineProjectile
AIFMissileSerpentine01 = ClassProjectile(AMissileSerpentineProjectile) {
    LaunchTicks = 2,
    LaunchTurnRate = 6,
    HeightDistanceFactor = 8,
    MinHeight = 2,
    FinalBoostAngle = 20,
}
TypeClass = AIFMissileSerpentine01
