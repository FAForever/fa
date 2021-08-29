--
-- Terran Land-Based Cruise Missile : UES0202 (UEF cruiser)
--

local TMissileCruiseProjectileOpti = import('/lua/terranprojectiles.lua').TMissileCruiseProjectileOpti
local MissileManager = import('/lua/sim/MissileManager.lua')
local AddMissile2Ticks = MissileManager.AddMissile2Ticks

-- upvalue for performance (globals)
local DamageArea = DamageArea
local CreateDecal = CreateDecal

-- upvalue for performance (math functions)
local MathPi = math.pi

-- upvalue for performance (moho functions)
local EntityBeenDestroyed = _G.moho.entity_methods.BeenDestroyed
local EntityGetPosition = _G.moho.entity_methods.GetPosition
local EntitySetCollisionShape = _G.moho.entity_methods.SetCollisionShape

TIFMissileCruise04 = Class(TMissileCruiseProjectileOpti) {

    FxScale = 1.5,

    OnCreate = function(self)
        TMissileCruiseProjectileOpti.OnCreate(self)
        EntitySetCollisionShape(self, 'Sphere', 0, 0, 0, 2.0)

        -- queue us up for changing the turn rate
        AddMissile2Ticks(self)
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
            TMissileCruiseProjectileOpti.OnImpact(self, targetType, targetEntity)

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
        TMissileCruiseProjectileOpti.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = TIFMissileCruise04

