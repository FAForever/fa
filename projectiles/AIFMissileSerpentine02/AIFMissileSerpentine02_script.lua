--
-- Aeon Serpentine Missile
--
local AMissileSerpentineProjectile = import("/lua/aeonprojectiles.lua").AMissileSerpentineProjectile
local TacticalMissileComponent = import('/lua/sim/DefaultProjectiles.lua').TacticalMissileComponent

AIFMissileSerpentine02 = ClassProjectile(AMissileSerpentineProjectile, TacticalMissileComponent) {

    LaunchTicks = 6,
    LaunchTurnRate = 6,
    HeightDistanceFactor = 5,
    MinHeight = 5,
    FinalBoostAngle = 0,

    FxWaterHitScale = 1.65,

    OnCreate = function(self)
        AMissileSerpentineProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self:ForkThread( self.MovementThread )
    end,
    
    OnExitWater = function(self)
        AMissileSerpentineProjectile.OnExitWater(self)
        self:SetDestroyOnWater(true)
    end,
}

TypeClass = AIFMissileSerpentine02