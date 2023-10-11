--
-- Terran Land-Based Cruise Missile : UEL0111 (UEF T2 MML)
--

local TMissileCruiseProjectile = import("/lua/terranprojectiles.lua").TMissileCruiseProjectile
local TacticalMissileComponent = import('/lua/sim/DefaultProjectiles.lua').TacticalMissileComponent
local EffectTemplate = import("/lua/effecttemplates.lua")

TIFMissileCruise03 = ClassProjectile(TMissileCruiseProjectile, TacticalMissileComponent) {

    FxTrails = EffectTemplate.TMissileExhaust01,
    FxTrailOffset = -0.85,
    
    FxAirUnitHitScale = 0.65,
    FxLandHitScale = 0.65,
    FxNoneHitScale = 0.65,
    FxPropHitScale = 0.65,
    FxProjectileHitScale = 0.65,
    FxProjectileUnderWaterHitScale = 0.65,
    FxShieldHitScale = 0.65,
    FxUnderWaterHitScale = 0.65,
    FxUnitHitScale = 0.65,
    FxWaterHitScale = 0.65,
    FxOnKilledScale = 0.65,
    
    LaunchTicks = 2,
    LaunchTurnRate = 6,
    HeightDistanceFactor = 5,
    MinHeight = 2,
    FinalBoostAngle = 0,

    OnCreate = function(self)
        TMissileCruiseProjectile.OnCreate(self) 
        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread,self))
    end,


}
TypeClass = TIFMissileCruise03

