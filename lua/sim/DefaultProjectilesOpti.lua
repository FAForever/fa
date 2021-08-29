-----------------------------------------------------------------
-- File     : /lua/defaultprojectiles.lua
-- Author(s): John Comes, Gordon Duclos
-- Summary  : Script for default projectiles
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- get original projectile and upvalue often called base functions
local ProjectileOpti = import('/lua/sim/Projectile.lua').ProjectileOpti
local ProjectileOnCreate = ProjectileOpti.OnCreate

-- globals as upvalues for performance 
local Damage = Damage
local Random = Random
local DamageRing = DamageRing
local ForkThread = ForkThread
local WaitSeconds = WaitSeconds
local CreateTrail = CreateTrail
local CreateEmitterOnEntity = CreateEmitterOnEntity
local CreateBeamEmitterOnEntity = CreateBeamEmitterOnEntity

local TableGetN = table.getn

-- math functions as upvalues for performance
local MathFloor = _G.math.floor
local MathMin = _G.math.min
local MathMax = _G.math.max 

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition
local EntityGetHealth = EntityMethods.GetHealth
local EntityPlaySound = EntityMethods.PlaySound
local EntityBeenDestroyed = EntityMethods.BeenDestroyed
local EntityCreateProjectile = EntityMethods.CreateProjectile
local EntitySetAmbientSound = EntityMethods.SetAmbientSound

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileSetAcceleration = ProjectileMethods.SetAcceleration
local ProjectileStayUnderwater = ProjectileMethods.StayUnderwater
local ProjectileSetTurnRate = ProjectileMethods.SetTurnRate

local ProjectileTrackTarget = ProjectileMethods.TrackTarget
local ProjectileSetDestroyOnWater = ProjectileMethods.SetDestroyOnWater
local ProjectileGetCurrentTargetPosition = ProjectileMethods.GetCurrentTargetPosition
local ProjectileSetCollisionShape = ProjectileMethods.SetCollisionShape
local ProjectileSetCollision = ProjectileMethods.SetCollision

local EmitterMethods = _G.moho.IEffect
local EmitterScaleEmitter = EmitterMethods.ScaleEmitter
local EmitterOffsetEmitter = EmitterMethods.OffsetEmitter

local TrashAdd = TrashBag.Add

EmitterProjectile = Class(ProjectileOpti) {

    -- typical trail emitters
    FxTrailScale = 1,
    FxTrailOffset = 0,
    FxTrails = { '/effects/emitters/missile_munition_trail_01_emit.bp', },

    OnCreate = function(self)
        ProjectileOnCreate(self)

        -- make sure there is at least one effect in it 
        local fxTrails = self.FxTrails
        if fxTrails[1] then 

            -- sequential / cached table look ups are faster
            local emit = false
            local army = self.Army
            local fxTrailScale = self.FxTrailScale
            local fxTrailOffset = self.FxTrailOffset
            for i in fxTrails do
                emit = CreateEmitterOnEntity(self, army, fxTrails[i])

                -- only scale if it matters
                if fxTrailScale != 1 then 
                    EmitterScaleEmitter(emit, fxTrailScale)
                end

                -- only apply offset if it matters
                if fxTrailOffset != 0 then 
                    EmitterOffsetEmitter(emit, 0, 0, fxTrailOffset)
                end
            end
        end
    end,
}

-- upvalue often called base functions
local EmitterProjectileOnCreate = EmitterProjectile.OnCreate

SingleBeamProjectile = Class(EmitterProjectile) {

    -- beam of the projectile (typically part of trail)
    BeamName = '/effects/emitters/default_beam_01_emit.bp',

    -- do not allocate these
    FxTrails = false,

    OnCreate = function(self)
        EmitterProjectileOnCreate(self)

        -- sequential / cached table look ups are faster
        local army = self.Army 
        local beamName = self.BeamName 

        if beamName then
            CreateBeamEmitterOnEntity(self, -1, army, beamName)
        end
    end,
}

MultiPolyTrailProjectile = Class(EmitterProjectile) {

    PolyTrails = { '/effects/emitters/test_missile_trail_emit.bp' },
    PolyTrailOffset = false,
    RandomPolyTrails = 0,   -- Count of how many are selected randomly for PolyTrail table

    FxTrails = false,

    OnCreate = function(self)
        EmitterProjectileOnCreate(self)

        -- see if we have trails
        local polyTrails = self.PolyTrails
        if polyTrails then

            -- information that is used in both branches
            local emit = false
            local army = self.Army
            local randomPolyTrails = self.RandomPolyTrails
            local polyTrailOffset = self.PolyTrailOffset
            local NumPolyTrails = TableGetN(self.PolyTrails)

            -- choose random trail
            if randomPolyTrails ~= 0 then
                local index = 0
                for i = 1, randomPolyTrails do
                    index = Random(1, NumPolyTrails)
                    emit = CreateTrail(self, -1, army, polyTrails[index])

                    if polyTrailOffset then 
                        EmitterOffsetEmitter(emit, 0, 0, polyTrailOffset[index])
                    end
                end
            -- choose fixed trail
            else
                for i = 1, NumPolyTrails do
                    emit = CreateTrail(self, -1, army, polyTrails[i])

                    if polyTrailOffset then 
                        EmitterOffsetEmitter(emit, 0, 0, polyTrailOffset[i])
                    end
                end
            end
        end
    end,
}