--
-- Terran Land-Based Cruise Missile : UES0202 (UEF cruiser)
--

local TMissileCruiseProjectile = import('/lua/terranprojectiles.lua').TMissileCruiseProjectile
local Explosion = import('/lua/defaultexplosions.lua')


local ForkThread = ForkThread
local WaitTicks = coroutine.yield

local MathPi = math.pi

local EntityGetPosition = _G.moho.entity_methods.GetPosition
local EntityGetPositionXYZ = _G.moho.entity_methods.GetPositionXYZ
local EntitySetCollisionShape = _G.moho.entity_methods.SetCollisionShape

local ProjectileSetTurnRate = _G.moho.projectile_methods.SetTurnRate
local ProjectileGetCurrentTargetPosition = _G.moho.projectile_methods.GetCurrentTargetPosition

local function arc(projectile)

    -- compute distance
    local tpos = ProjectileGetCurrentTargetPosition(projectile)
    local px, _, pz = EntityGetPositionXYZ(projectile)
    local dist = VDist2(px, pz, tpos[1], tpos[3])

    -- compute multiplier
    local multiplier = 200 / dist
    if multiplier < 1.0 then 
        multiplier = 1.0
    end

    -- set turn rate accordingly
    ProjectileSetTurnRate(projectile, 0) 
    WaitTicks(6)
    ProjectileSetTurnRate(projectile, multiplier * 10)
end

TIFMissileCruise04 = Class(TMissileCruiseProjectile) {

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
        EntitySetCollisionShape(self, 'Sphere', 0, 0, 0, 2.0)
        ForkThread(arc, self)
    end,    
    
    OnImpact = function(self, targetType, targetEntity)

        -- retrieve for damage and decal
        local damageData = self.DamageData
        local radius = damageData.DamageRadius
        local FriendlyFire = damageData.DamageFriendly
        local pos = EntityGetPosition(self)
        
        -- make trees hop over
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )

        -- adjust damage
        damageData.DamageAmount = damageData.DamageAmount - 2
        
        -- skip decal if not applicable
        if targetType == 'Shield' or targetType == 'Water' or targetType == 'Air' or targetType == 'UnitAir' or targetType == 'Projectile' then

            -- perform typical logic
            TMissileCruiseProjectile.OnImpact(self, targetType, targetEntity)

            -- get out of here
            return
        end

        -- make decal
        CreateDecal(
            pos,                        -- position
            2 * MathPi * Random(),      -- orientation
            'nuke_scorch_002_albedo',   -- decal 1
            '',                         -- decal 2 (for spec)
            'Albedo',                   -- decal type
            radius,                     -- sx
            radius,                     -- sy
            180,                        -- level of detail
            40,                         -- duration
            self.Army                   -- army that the decal belongs to
        )

        -- perform typical logic
        TMissileCruiseProjectile.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = TIFMissileCruise04

