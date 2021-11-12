-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsSetCollisionShape = EntityMethods.SetCollisionShape

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileMethodsSetDestroyOnWater = ProjectileMethods.SetDestroyOnWater
local ProjectileMethodsSetTurnRate = ProjectileMethods.SetTurnRate
-- End of automatically upvalued moho functions

#
# Terran Land-Based Cruise Missile
#
local TMissileCruiseProjectile = import('/lua/terranprojectiles.lua').TMissileCruiseProjectile02
local Explosion = import('/lua/defaultexplosions.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')

TIFMissileCruiseCDR = Class(TMissileCruiseProjectile)({

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
        EntityMethodsSetCollisionShape(self, 'Sphere', 0, 0, 0, 2)
        self.MoveThread = self:ForkThread(self.MovementThread)
    end,

    MovementThread = function(self)
        self.WaitTime = 0.1
        ProjectileMethodsSetTurnRate(self, 8)
        WaitSeconds(0.3)
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitSeconds(self.WaitTime)
        end
    end,

    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        #Get the nuke as close to 90 deg as possible
        if dist > 50 then
            #Freeze the turn rate as to prevent steep angles at long distance targets
            WaitSeconds(2)
            ProjectileMethodsSetTurnRate(self, 20)
        elseif dist > 30 and dist <= 150 then
            # Increase check intervals
            ProjectileMethodsSetTurnRate(self, 30)
            WaitSeconds(1.5)
            ProjectileMethodsSetTurnRate(self, 30)
        elseif dist > 10 and dist <= 30 then
            # Further increase check intervals
            WaitSeconds(0.3)
            ProjectileMethodsSetTurnRate(self, 50)
        elseif dist > 0 and dist <= 10 then
            # Further increase check intervals
            ProjectileMethodsSetTurnRate(self, 100)
            KillThread(self.MoveThread)
        end
    end,

    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,

    OnEnterWater = function(self)
        TMissileCruiseProjectile.OnEnterWater(self)
        ProjectileMethodsSetDestroyOnWater(self, true)
    end,
})
TypeClass = TIFMissileCruiseCDR

