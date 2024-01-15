local AMissileSerpentine02Projectile = import("/lua/aeonprojectiles.lua").AMissileSerpentineProjectile

--- Serpentine Missile 03 : XAS0306
---@class AIFMissileTactical03: AMissileSerpentineProjectile
AIFMissileTactical03 = ClassProjectile(AMissileSerpentine02Projectile) {
    -- separate trajectory components to make it feel like a barrage
    LaunchTicks = 26,
    LaunchTicksRange = 10,
    LaunchTurnRate = 6,
    LaunchTurnRateRange = 2,
    HeightDistanceFactor = 5,
    MinHeight = 10,
    FinalBoostAngle = 45,
}
TypeClass = AIFMissileTactical03

--- backwards compatibility
AIFMissileTactical02 = AIFMissileTactical03