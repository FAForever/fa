-- Terran Land-Based Cruise Missile : UES0202 (UEF cruiser)

local TMissileCruiseProjectile = import("/lua/terranprojectiles.lua").TMissileCruiseProjectile
local TacticalMissileComponent = import('/lua/sim/DefaultProjectiles.lua').TacticalMissileComponent

---@class TIFMissileCruise04 : TMissileCruiseProjectile, TacticalMissileComponent
TIFMissileCruise04 = ClassProjectile(TMissileCruiseProjectile, TacticalMissileComponent) {

    FxAirUnitHitScale = 1.5,
    FxLandHitScale = 1.5,
    FxNoneHitScale = 1.5,
    FxPropHitScale = 1.5,
    FxProjectileHitScale = 1.5,
    FxProjectileUnderWaterHitScale = 1.5,
    FxShieldHitScale = 1.5,
    FxUnderWaterHitScale = 1.5,
    FxUnitHitScale = 1.5,
    FxWaterHitScale = 1.5,
    FxOnKilledScale = 1.5,

    LaunchTicks = 12,
    LaunchTicksRange = 2,
    LaunchTurnRate = 6,
    LaunchTurnRateRange = 2,
    HeightDistanceFactor = 5.5,
    HeightDistanceFactorRange = 0.5,
    MinHeight = 10,
    MinHeightRange = 1,
    FinalBoostAngle = 50,
    FinalBoostAngleRange = 5,

    OnCreate = function(self)
        TMissileCruiseProjectile.OnCreate(self)
        self.Trash:Add(ForkThread( self.MovementThread,self ))
    end,
}
TypeClass = TIFMissileCruise04

