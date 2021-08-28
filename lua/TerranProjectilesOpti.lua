------------------------------------------------------------
--
--  File     : /lua/terranprojectiles.lua
--  Author(s): John Comes, Gordon Duclos, Matt Vainio
--
--  Summary  :
--
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

--------------------------------------------------------------------------
--  TERRAN PROJECTILES SCRIPTS
--------------------------------------------------------------------------

local EffectTemplate = import('/lua/EffectTemplates.lua')
local DefaultProjectileFile = import('/lua/sim/defaultprojectiles.lua')
local SingleBeamProjectileOpti = DefaultProjectileFile.SingleBeamProjectileOpti


-- upvalue for performance (globals)
local CreateEmitterAtEntity = CreateEmitterAtEntity

-- upvalue for performance (moho functions)
local EmitterScaleEmitter = _G.moho.IEffect.ScaleEmitter 

TMissileCruiseProjectile = Class(SingleBeamProjectileOpti) {

    -- ??
    DestroyOnImpact = false,

    -- trail effects
    FxTrails = EffectTemplate.TMissileExhaust02,
    FxTrailOffset = -1,

    -- beam effects (part of trail)
    BeamName = '/effects/emitters/missile_munition_exhaust_beam_01_emit.bp',

    -- impact effects
    FxImpactUnit = EffectTemplate.TMissileHit01,
    FxImpactLand = EffectTemplate.TMissileHit01,
    FxImpactProp = EffectTemplate.TMissileHit01,
    FxImpactUnderWater = false,

    CreateImpactEffects = function(self, army, effectTable, effectScale)
        -- store reference in memory once
        local emit = false

        -- only loop over an effectTable that exists
        if effectTable then 
            for k, v in effectTable do

                -- create the emitter on ourselves
                emit = CreateEmitterAtEntity(self, army, v)

                -- no need to scale if it is just 1
                if effectScale ~= 1 then
                    EmitterScaleEmitter(emit, effectScale)
                end
            end
        end
    end,
}
