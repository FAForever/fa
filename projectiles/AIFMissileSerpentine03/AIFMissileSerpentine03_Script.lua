-- Serpentine Missile 03

local AMissileSerpentine02Projectile = import("/lua/aeonprojectiles.lua").AMissileSerpentine02Projectile
local TacticalMissileComponent = import('/lua/sim/DefaultProjectiles.lua').TacticalMissileComponent

AIFMissileTactical02 = ClassProjectile(AMissileSerpentine02Projectile, TacticalMissileComponent) {

    LaunchTicks = 32,
    LaunchTurnRate = 2,
    HeightDistanceFactor = 3,
    MinHeight = 5,
    FinalBoostAngle = 0,

    OnCreate = function(self)
        AMissileSerpentine02Projectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.Trash:Add(ForkThread( self.MovementThread,self))
    end,
}
TypeClass = AIFMissileTactical02