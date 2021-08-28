--
-- Terran Land-Based Cruise Missile : UES0202 (UEF cruiser)
--

local TMissileCruiseProjectileOpti = import('/lua/terranprojectiles.lua').TMissileCruiseProjectileOpti
local Explosion = import('/lua/defaultexplosions.lua')

-- upvalue for performance (globals)
local ForkThread = ForkThread
local WaitTicks = coroutine.yield

-- upvalue for performance (math functions)
local MathPi = math.pi

-- upvalue for performance (moho functions)
local EntityBeenDestroyed = _G.moho.entity_methods.BeenDestroyed
local EntityGetPosition = _G.moho.entity_methods.GetPosition
local EntityGetPositionXYZ = _G.moho.entity_methods.GetPositionXYZ
local EntitySetCollisionShape = _G.moho.entity_methods.SetCollisionShape

local ProjectileSetTurnRate = _G.moho.projectile_methods.SetTurnRate
local ProjectileGetCurrentTargetPosition = _G.moho.projectile_methods.GetCurrentTargetPosition

-- stores all references to missiles that need to be adjusted 
local MissilesT1 = { }
local MissilesT2 = { }
local MissilesT3 = { }

-- make garbage collector pick up projectiles as it sees fit
local Weak = { __mode = "v" }
setmetatable(MissilesT1, Weak)
setmetatable(MissilesT2, Weak)
setmetatable(MissilesT3, Weak)

local MissileT1Next = 1
local MissileT2Next = 1
local MissileT3Next = 1

-- a thread that runs over all missiles in a continious loop and kicks them out again
ForkThread(
    function()

        while true do 

            for k = 1, MissileT3Next - 1 do 

                -- get the missile and check if it is still valid
                local missile = MissilesT3[k]
                if not missile or EntityBeenDestroyed(missile) then 
                    continue 
                end

                -- compute distance
                local tpos = ProjectileGetCurrentTargetPosition(missile)
                local px, _, pz = EntityGetPositionXYZ(missile)
                local dist = VDist2(px, pz, tpos[1], tpos[3])

                -- compute multiplier
                local multiplier = 200 / dist
                if multiplier < 1.0 then 
                    multiplier = 1.0
                end

                -- set turn rate accordingly
                ProjectileSetTurnRate(missile, multiplier * 10)
            end

            -- switch them up
            local temp = MissilesT3
            MissilesT3 = MissilesT2 
            MissilesT2 = MissilesT1 
            MissilesT1 = temp

            -- switch them up
            MissileT3Next = MissileT2Next
            MissileT2Next = MissileT1Next
            MissileT1Next = 1 

            -- wait a bit
            WaitTicks(3)
        end
    end
)

TIFMissileCruise04 = Class(TMissileCruiseProjectileOpti) {

    FxScale = 1.5,

    OnCreate = function(self)
        TMissileCruiseProjectileOpti.OnCreate(self)
        EntitySetCollisionShape(self, 'Sphere', 0, 0, 0, 2.0)

        -- queue us up for changing the turn rate
        MissilesT1[MissileT1Next] = self
        MissileT1Next = MissileT1Next + 1
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

