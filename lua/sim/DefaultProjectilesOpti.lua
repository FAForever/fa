-----------------------------------------------------------------
-- File     : /lua/defaultprojectiles.lua
-- Author(s): John Comes, Gordon Duclos
-- Summary  : Script for default projectiles
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- get original projectile and upvalue often called base functions
local ProjectileOpti = import('/lua/sim/Projectile.lua').ProjectileOpti
local ProjectileOnCreate = ProjectileOpti.OnCreate

-- upvalue for performance (globals)
local CreateBeamEmitterOnEntity = CreateBeamEmitterOnEntity

-- upvalue for performance (moho)
local EmitterScaleEmitter = _G.moho.IEffect.ScaleEmitter
local EmitterOffsetEmitter = _G.moho.IEffect.OffsetEmitter

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