--
-- Terran Land-Based Cruise Missile
--
local TMissileCruiseProjectile = import("/lua/terranprojectiles.lua").TMissileCruiseProjectile02
local TacticalMissileComponent = import('/lua/sim/DefaultProjectiles.lua').TacticalMissileComponent
local EffectTemplate = import("/lua/effecttemplates.lua")

TIFMissileCruise01 = ClassProjectile(TMissileCruiseProjectile, TacticalMissileComponent) {

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

    FxTrails = EffectTemplate.TMissileExhaust01,


    -- TacticalMissileComponent Trajectory Parameters

    -- LaunchTicks: how long we spend in the launch phase
    LaunchTicks = 6,

    -- LaunchTurnRate: inital launch phase turn rate, gives a little turnover coming out of the tube
    LaunchTurnRate = 6,

    -- HeightDistanceFactor: each missile calculates an optimal highest point of its trajectory,
    -- based on its distance to the target.
    -- This is the factor that determines how high above the target that point is, in relation to the horizontal distance.
    -- a higher number will result in a lower trajectory
    -- 5-8 is a decent value
    HeightDistanceFactor = 5,

    -- MinHeight: minimum height of the highest point of the trajectory
    -- measured from the position of the missile at the end of the launch phase
    -- minRadius/2 or so is a decent value
    MinHeight = 5,

    -- FinalBoostAngle: angle in degrees that we'll aim to be at the end of the boost phase
    -- 90 is vertical, 0 is horizontal
    FinalBoostAngle = 0,

    OnCreate = function(self)
        TMissileCruiseProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.Trash:Add(ForkThread( self.MovementThread,self ))
    end,
    
}
TypeClass = TIFMissileCruise01