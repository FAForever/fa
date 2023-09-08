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

    OnCreate = function(self)
        TMissileCruiseProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.Trash:Add(ForkThread( self.MovementThread,self ))
    end,
    
}
TypeClass = TIFMissileCruise01