--
-- Terran Land-Based Cruise Missile
--
local TMissileCruiseProjectile = import("/lua/terranprojectiles.lua").TMissileCruiseProjectile02
local TacticalMissileComponent = import('/lua/sim/DefaultProjectiles.lua').TacticalMissileComponent
local Explosion = import("/lua/defaultexplosions.lua")
local EffectTemplate = import("/lua/effecttemplates.lua")

TIFMissileCruiseCDR = ClassProjectile(TMissileCruiseProjectile, TacticalMissileComponent) {

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

    LaunchTicks = 6,
    LaunchTurnRate = 6,
    HeightDistanceFactor = 5,
    MinHeight = 5,
    FinalBoostAngle = 0,

    OnCreate = function(self)
        TMissileCruiseProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2)
        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread,self))
    end,

    OnEnterWater = function(self)
        TMissileCruiseProjectile.OnEnterWater(self)
        self:SetDestroyOnWater(true)
    end,
}
TypeClass = TIFMissileCruiseCDR

