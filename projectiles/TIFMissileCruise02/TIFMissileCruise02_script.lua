--
-- Terran Sub-Launched Cruise Missile
--
local TMissileCruiseSubProjectile = import("/lua/terranprojectiles.lua").TMissileCruiseSubProjectile
local TacticalMissileComponent = import('/lua/sim/DefaultProjectiles.lua').TacticalMissileComponent

TIFMissileCruise02 = ClassProjectile(TMissileCruiseSubProjectile, TacticalMissileComponent) {

	FxAirUnitHitScale = 1.65,
    FxLandHitScale = 1.65,
    FxNoneHitScale = 1.65,
    FxPropHitScale = 1.65,
    FxProjectileHitScale = 1.65,
    FxProjectileUnderWaterHitScale = 1.65,
    FxShieldHitScale = 1.65,
    FxUnderWaterHitScale = 1.65,
    FxUnitHitScale = 1.65,
    FxWaterHitScale = 1.65,
    FxOnKilledScale = 1.65,

    LaunchTicks = 6,
    LaunchTurnRate = 6,
    HeightDistanceFactor = 5,
    MinHeight = 5,
    FinalBoostAngle = 0,

    OnCreate = function(self)
        TMissileCruiseSubProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.Trash:Add(ForkThread( self.MovementThread,self ))
    end,
    
    OnExitWater = function(self)
        TMissileCruiseSubProjectile.OnExitWater(self)
        self:SetDestroyOnWater(true)
    end,
}

TypeClass = TIFMissileCruise02

