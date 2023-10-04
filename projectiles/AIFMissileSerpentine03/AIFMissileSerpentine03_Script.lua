-- Serpentine Missile 03

local AMissileSerpentine02Projectile = import("/lua/aeonprojectiles.lua").AMissileSerpentine02Projectile
local TacticalMissileComponent = import('/lua/sim/DefaultProjectiles.lua').TacticalMissileComponent

---@class AIFMissileTactical02: AMissileSerpentine02Projectile, TacticalMissileComponent
AIFMissileTactical02 = ClassProjectile(AMissileSerpentine02Projectile, TacticalMissileComponent) {

    LaunchTicks = 46,
    LaunchTicksRange = 100,
    LaunchTurnRate = 6,
    LaunchTurnRateRange = 2,
    HeightDistanceFactor = 5,
    MinHeight = 10,
    FinalBoostAngle = 45,

    OnCreate = function(self)
        AMissileSerpentine02Projectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.Trash:Add(ForkThread( self.MovementThread,self))
    end,
}
TypeClass = AIFMissileTactical02