-- Aeon Serpentine Missile

local AMissileSerpentineProjectile = import("/lua/aeonprojectiles.lua").AMissileSerpentineProjectile
local TacticalMissileComponent = import('/lua/sim/DefaultProjectiles.lua').TacticalMissileComponent

AIFMissileSerpentine01 = ClassProjectile(AMissileSerpentineProjectile, TacticalMissileComponent) {

    LaunchTicks = 2,
    LaunchTurnRate = 6,
    HeightDistanceFactor = 5,
    MinHeight = 2,
    FinalBoostAngle = 0,
    
    OnCreate = function(self)
        AMissileSerpentineProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2)
        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread,self))
    end,
}
TypeClass = AIFMissileSerpentine01
