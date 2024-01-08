local AMissileSerpentine02Projectile = import("/lua/aeonprojectiles.lua").AMissileSerpentine02Projectile

--- Serpentine Missile 03 : XAS0306
---@class AIFMissileTactical03: AMissileSerpentine02Projectile
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