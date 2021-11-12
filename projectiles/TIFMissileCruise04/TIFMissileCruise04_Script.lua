--
-- Terran Land-Based Cruise Missile : UES0202 (UEF cruiser)
--

-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsSetCollisionShape = EntityMethods.SetCollisionShape

local GlobalMethods = _G
local GlobalMethodsCreateDecal = GlobalMethods.CreateDecal
local GlobalMethodsDamageArea = GlobalMethods.DamageArea

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileMethodsSetTurnRate = ProjectileMethods.SetTurnRate
-- End of automatically upvalued moho functions

local TMissileCruiseProjectile = import('/lua/terranprojectiles.lua').TMissileCruiseProjectile
local Explosion = import('/lua/defaultexplosions.lua')

TIFMissileCruise04 = Class(TMissileCruiseProjectile)({

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

    OnCreate = function(self)
        TMissileCruiseProjectile.OnCreate(self)
        EntityMethodsSetCollisionShape(self, 'Sphere', 0, 0, 0, 2.0)
        self.MovementTurnLevel = 1
        self:ForkThread(self.MovementThread)
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
        -- Get the nuke as close to 90 deg as possible
        if dist > 50 then
            -- Freeze the turn rate as to prevent steep angles at long distance targets
            WaitSeconds(2)
            ProjectileMethodsSetTurnRate(self, 20)
        elseif dist > 64 and dist <= 107 then
            -- Increase check intervals
            ProjectileMethodsSetTurnRate(self, 30)
            WaitSeconds(1.5)
            ProjectileMethodsSetTurnRate(self, 30)
        elseif dist > 21 and dist <= 53 then
            -- Further increase check intervals
            WaitSeconds(0.3)
            ProjectileMethodsSetTurnRate(self, 50)
        elseif dist > 0 and dist <= 21 then
            -- Further increase check intervals            
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

    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly and radius ~= 0

        GlobalMethodsDamageArea(self, pos, radius, 1, 'Force', FriendlyFire)
        GlobalMethodsDamageArea(self, pos, radius, 1, 'Force', FriendlyFire)

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2

        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0, 2 * math.pi)
            local army = self.Army

            GlobalMethodsCreateDecal(pos, rotation, 'nuke_scorch_002_albedo', '', 'Albedo', radius, radius, 180, 40, army)
        end

        TMissileCruiseProjectile.OnImpact(self, targetType, targetEntity)
    end,
})
TypeClass = TIFMissileCruise04

