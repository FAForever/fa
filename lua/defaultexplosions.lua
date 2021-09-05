--****************************************************************************
--**
--**  File     :  /lua/defaultexplosions.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local Entity = import('/lua/sim/entity.lua').Entity

local util = import('utilities.lua')
local GetRandomFloat = util.GetRandomFloat
local GetRandomInt = util.GetRandomInt
local GetRandomOffset = util.GetRandomOffset
local GetRandomOffset2 = util.GetRandomOffset2

-- upvalue for performance
local EfctUtil = import('EffectUtilities.lua')
local CreateEffects = EfctUtil.CreateEffects
local CreateEffectsWithOffset = EfctUtil.CreateEffectsWithOffset
local CreateEffectsWithRandomOffset = EfctUtil.CreateEffectsWithRandomOffset
local CreateBoneEffects = EfctUtil.CreateBoneEffects
local CreateBoneEffectsOffset = EfctUtil.CreateBoneEffectsOffset
local CreateRandomEffects = EfctUtil.CreateRandomEffects
local ScaleEmittersParam = EfctUtil.ScaleEmittersParam

local EffectTemplate = import('/lua/EffectTemplates.lua')
local ExplosionSmall = EffectTemplate.ExplosionSmall
local ExplosionLarge = EffectTemplate.ExplosionLarge
local ExplosionMedium = EffectTemplate.ExplosionMedium
local ExplosionSmallAir = EffectTemplate.ExplosionSmallAir
local ExplosionSmallWater = EffectTemplate.ExplosionSmallWater
local ExplosionMediumWater = EffectTemplate.ExplosionMediumWater
local FireCloudMed01 = EffectTemplate.FireCloudMed01
local DefaultHitExplosion01 = EffectTemplate.DefaultHitExplosion01
local Splashy = EffectTemplate.Splashy

-- global functions as upvalue for performance
local Random = Random
local IsUnit = IsUnit

-- table functions as upvalue for performance
local TableGetn = table.getn

-- math functions as upvalue for performance
local MathMin = math.min

-- moho functions as upvalue for performance
local EntityGetPosition = moho.entity_methods.GetPosition
local EntityGetBlueprint = moho.entity_methods.GetBlueprint
local EntityShakeCamera = moho.entity_methods.ShakeCamera
local EntityCreateProjectile = moho.entity_methods.CreateProjectile

-- as upvalue for performance
local ScorchSplatTextures = {
    'scorch_001_albedo',
    'scorch_002_albedo',
    'scorch_003_albedo',
    'scorch_004_albedo',
    'scorch_005_albedo',
    'scorch_006_albedo',
    'scorch_007_albedo',
    'scorch_008_albedo',
    'scorch_009_albedo',
    'scorch_010_albedo',
}

local ScorchSplatTexturesN = TableGetn(ScorchSplatTextures)

-- as upvalue for performance
local ScorchDecalTextures = {
    'scorch_001_albedo',
    'scorch_002_albedo',
    'scorch_003_albedo',
    'scorch_004_albedo',
    'scorch_005_albedo',
    'scorch_006_albedo',
    'scorch_007_albedo',
    'scorch_008_albedo',
    'scorch_009_albedo',
    'scorch_010_albedo',
}

local ScorchDecalTexturesN = TableGetn(ScorchDecalTextures)

----------------------
-- UTILITY FUNCTION --
----------------------

--- Retrieves the size of the unit as defined in the blueprint. Do not use in critical code, instead
-- copy the body into your code for performance reasons.
-- @param unit The unit to get the size of.
function GetUnitSizes(unit)
    local bp = unit:GetBlueprint()
    return bp.SizeX or 0, bp.SizeY or 0, bp.SizeZ or 0
end

--- Retrieves the voume of the unit as defined in the blueprint. Do not use in critical code, instead
-- copy the body into your code for performance reasons.
-- @param unit The unit to get the volume of.
function GetUnitVolume(unit)
    local x, y, z = GetUnitSizes(unit)
    return x * y * z
end

--- Retrieves average x / z size. Do not use in critical code, instead
-- copy the body into your code for performance reasons.
-- @param unit The unit to get the volume of.
function GetAverageBoundingXZRadius(unit)
    local bp = unit:GetBlueprint()
    return ((bp.SizeX or 0 + bp.SizeZ or 0) * 0.5)
end

--- Retrieves average x / y / z size. Do not use in critical code, instead
-- copy the body into your code for performance reasons.
-- @param unit The unit to get the volume of.
function GetAverageBoundingXYZRadius(unit)
    local bp = unit:GetBlueprint()
    return ((bp.SizeX or 0 + bp.SizeY or 0 + bp.SizeZ or 0) * 0.333)
end

--- ??, what is the mathematics here exactly?
function QuatFromRotation(rotation, x, y, z)
    local angleRot, qw, qx, qy, qz, angle
    angle = 0.00872664625 * rotation
    angleRot = math.sin(angle)
    qw = math.cos(angle)
    qx = x * angleRot
    qy = y * angleRot
    qz = z * angleRot
    return qx, qy, qz, qw
end

--------------------------------------
-- DEFAULT EXPLOSION BASE FUNCTIONS --
--------------------------------------

-- keep these strings in memory so that garbage collector doesn't have to clean them up
local ProjectileDebrisBps = {
    '/effects/entities/DebrisMisc01/DebrisMisc01_proj.bp',
    '/effects/entities/DebrisMisc02/DebrisMisc02_proj.bp',
    '/effects/entities/DebrisMisc03/DebrisMisc03_proj.bp',
    '/effects/entities/DebrisMisc04/DebrisMisc04_proj.bp',
    '/effects/entities/DebrisMisc05/DebrisMisc05_proj.bp',
    '/effects/entities/DebrisMisc06/DebrisMisc06_proj.bp',
    '/effects/entities/DebrisMisc07/DebrisMisc07_proj.bp',
    '/effects/entities/DebrisMisc08/DebrisMisc08_proj.bp',
    '/effects/entities/DebrisMisc09/DebrisMisc09_proj.bp',
    '/effects/entities/DebrisMisc010/DebrisMisc010_proj.bp',
}

--- Creates the default unit explosion used by almost all units in the game.
-- @unit The Unit to create the explosion for.
-- @overKillRatio Has an impact on how strong the explosion is.
function CreateScalableUnitExplosion(unit, overKillRatio)
    if unit then
        if IsUnit(unit) then

            -- cache blueprint values
            local blueprint = EntityGetBlueprint(unit)
            local sx = blueprint.SizeX or 0 
            local sy = blueprint.SizeY or 0 
            local sz = blueprint.SizeZ or 0 

            -- cache stats 
            local army = unit.Army
            local boundingXZRadius = 0.5 * (sx + sz)
            local boundingXYZRadius = 0.333 * (sx + sy + sz)
            local volume = sx * sy * sz
            local layer = unit.Layer

            -- data for emitters / shaking
            local baseEffects = false
            local environmentEffects = false 
            local shakeTimeModifier = 0
            local shakeMaxMul = 1

            if layer == 'Land' then
                -- determine land effects
                if boundingXZRadius < 1.1 then
                    baseEffects = ExplosionSmall
                elseif boundingXZRadius > 3.75 then
                    -- large units cause camera to shake
                    baseEffects = ExplosionLarge
                    ShakeTimeModifier = 1.0
                    ShakeMaxMul = 0.25
                else
                    baseEffects = ExplosionMedium
                end

                -- environment effects (splat / decal creation)
                local position = EntityGetPosition(unit)
                local scorchRotation = 6.28 * Random()
                local scorchDuration = 200 + 150 * Random()
                local scorchLOD = 300 + 300 * Random()
                if boundingXZRadius > 1.2 then
                    CreateDecal(
                        position, 
                        scorchRotation, 
                        ScorchDecalTextures[Random(1, ScorchDecalTexturesN)], 
                        '', 
                        'Albedo', 
                        boundingXZRadius * 3, 
                        boundingXZRadius * 3, 
                        scorchLOD, 
                        scorchDuration, 
                        army
                    )
                else
                    CreateSplat(
                        position, 
                        scorchRotation, 
                        ScorchSplatTextures[Random(1, ScorchSplatTexturesN)], 
                        boundingXZRadius * 4, 
                        boundingXZRadius * 4, 
                        scorchLOD,
                        scorchDuration, 
                        army
                    )
                end

            elseif layer == 'Air' then
                -- determine air effects
                if boundingXZRadius < 1.1 then
                    baseEffects = ExplosionSmallAir
                elseif boundingXZRadius > 3 then
                    -- large units cause camera to shake
                    baseEffects = ExplosionLarge
                    ShakeTimeModifier = 1.0
                    ShakeMaxMul = 0.25
                else
                    baseEffects = ExplosionMedium
                end
            elseif layer == 'Water' then
                -- determine water effects
                if boundingXZRadius < 1 then
                    baseEffects = ExplosionSmallWater
                elseif boundingXZRadius > 3 then
                    -- large units cause camera to shake
                    baseEffects = ExplosionMediumWater
                    ShakeTimeModifier = 1.0
                    ShakeMaxMul = 0.25
                else
                    baseEffects = ExplosionMediumWater
                end

                -- environment effects
                if boundingXZRadius < 0.5 then
                    environmentEffects = Splashy
                end
            end

            -- create the emitters  
            if baseEffects then 
                CreateEffects(unit, army, baseEffects)
            end

            if environmentEffects then 
                CreateEffects(unit, army, environmentEffects)       
            end    

            -- create the flash
            CreateLightParticle(
                unit, 
                -1, 
                army, 
                boundingXZRadius * (6 + 4 * Random()),  -- (6, 10)
                10.5 + 4 * Random(), -- (10.5, 14.5)
                'glow_03', 
                'ramp_flare_02'
            )

            -- create debris
            local amount = MathMin(Random(1 + (boundingXYZRadius * 25), (boundingXYZRadius * 50)) , 100)
            for i = 1, amount do

                -- get some random numbers
                local r1, r2, r3 = Random(), Random(), Random() 

                -- position where debris starts
                local xpos = r1 * sx - (sx * 0.5)
                local ypos = r2 * sy
                local zpos = r3 * sz - (sz * 0.5)

                -- direction debris will go in
                local xdir = 10 * (r2 * sx - (sx * 0.5))
                local ydir = 10 * (r3 * sy)
                local zdir = 10 * ((1 - r1) * sz - (sz * 0.5))

                -- determine blueprint value
                local bp = false 
                if boundingXYZRadius < 0.2 then
                    bp = '/effects/entities/DebrisMisc09/DebrisMisc09_proj.bp'
                elseif boundingXYZRadius < 2.0 then
                    bp = '/effects/entities/DebrisMisc04/DebrisMisc04_proj.bp'
                else 
                    bp = '/effects/entities/DebrisMisc010/DebrisMisc010_proj.bp'
                end

                -- create debris projectile
                EntityCreateProjectile(unit, bp, xpos, xpos, zpos, xdir, ydir + 4.5, zdir)
            end

            -- do camera shake
            EntityShakeCamera(unit, 30 * boundingXZRadius, boundingXZRadius * shakeMaxMul, 0, 0.5 + shakeTimeModifier)
        end
    end
end

--- Creates a flash and fire emitters that represents an explosion on hit.
-- @param obj The entity to create the flash at.
-- @param scale The scale of the flash.
function CreateDefaultHitExplosion(obj, scale)
    if obj and not obj:BeenDestroyed() then

        local army = obj.Army 

        -- create the flash
        CreateLightParticle(
            obj, 
            -1, 
            army, 
            0.5 * scale * (6 + 4 * Random()),   -- (6, 10)
            10.5 + 4 * Random(),                -- (10.5, 14.5)
            'glow_03', 
            'ramp_flare_02'
        )
        
        -- create the fire cloud
        CreateEffects(obj, army, FireCloudMed01)
    end
end

--- Creates explosion emitters that represent a hit. Do not use in critical code, instead
-- copy the body.
-- @param obj The entity to create the emitters for.
-- @param scale Unused parameter.
-- @param xOffset Offset on the x-axis.
-- @param yOffset Offset on the y-axis.
-- @param zOffset Offset on the z-axis.
function CreateDefaultHitExplosionOffset(obj, scale, xOffset, yOffset, zOffset)
    if obj:BeenDestroyed() then
        return
    end

    CreateBoneEffectsOffset(obj, -1, obj.Army, DefaultHitExplosion01, xOffset, yOffset, zOffset)
end


--- Creates a flash and fire emitters that represents an explosion on hit.
-- @param obj The entity to create the flash at.
-- @param boneName The bone to attach the effect to.
-- @param scale The scale of the flash.
function CreateDefaultHitExplosionAtBone(obj, boneName, scale)
    local army = obj.Army
    CreateFlash(obj, boneName, scale * 0.5, army)
    CreateBoneEffects(obj, boneName, army, FireCloudMed01)
end

function CreateTimedStuctureUnitExplosion(obj)
    local numExplosions = math.floor(GetAverageBoundingXYZRadius(obj) * GetRandomInt(2,5))
    local x,y,z = GetUnitSizes(obj)
    obj:ShakeCamera(30, 1, 0, 0.45 * numExplosions)
    for i = 0, numExplosions do
        CreateDefaultHitExplosionOffset(obj, 1.0, unpack({GetRandomOffset(x, y, z, 1.2)}))
        obj:PlayUnitSound('DeathExplosion')
        WaitSeconds(GetRandomFloat(0.2, 0.7))
    end
end

--- Old function that is no longer in use. Do not use this function - it creates a whole
-- lot of overhead that is not necessary.
function MakeExplosionEntitySpec(unit, overKillRatio)
    return {
        Army = unit.Army,
        Dimensions = {GetUnitSizes(unit)},
        BoundingXZRadius = GetAverageBoundingXZRadius(unit),
        BoundingXYZRadius = GetAverageBoundingXYZRadius(unit),
        OverKillRatio = overKillRatio,
        Volume = GetUnitVolume(unit),
        Layer = unit.Layer,
    }
end

--- Old function that is no longer in use. Do not use this function - it creates a whole
-- lot of overhead that is not necessary.
function CreateUnitExplosionEntity(unit, overKillRatio)
    local localentity = Entity(MakeExplosionEntitySpec(unit, overKillRatio))
    Warp(localentity, unit:GetPosition())
    return localentity
end

--- Old function that is no longer in use. Do not use this function - it creates a whole
-- lot of overhead that is not necessary.
function _CreateScalableUnitExplosion(obj)
    local army = obj.Spec.Army
    local scale = obj.Spec.BoundingXZRadius
    local layer = obj.Spec.Layer
    local BaseEffectTable = {}
    local EnvironmentalEffectTable = {}
    local EffectTable = {}
    local ShakeTimeModifier = 0
    local ShakeMaxMul = 1

    -- Determine effect table to use, based on unit bounding box scale
    if layer == 'Land' then
        if scale < 1.1 then   ---- Small units
             BaseEffectTable = EffectTemplate.ExplosionSmall
        elseif scale > 3.75 then ---- Large units
            BaseEffectTable = EffectTemplate.ExplosionLarge
            ShakeTimeModifier = 1.0
            ShakeMaxMul = 0.25
        else                  ---- Medium units
            BaseEffectTable = EffectTemplate.ExplosionMedium
        end
    end

    if layer == 'Air' then
        if scale < 1.1 then   ---- Small units
             BaseEffectTable = EffectTemplate.ExplosionSmallAir
        elseif scale > 3 then ---- Large units
            BaseEffectTable = EffectTemplate.ExplosionLarge
            ShakeTimeModifier = 1.0
            ShakeMaxMul = 0.25
        else                  ---- Medium units
            BaseEffectTable = EffectTemplate.ExplosionMedium
        end
    end

    if layer == 'Water' then
        if scale < 1 then   ---- Small units
            BaseEffectTable = EffectTemplate.ExplosionSmallWater
        elseif scale > 3 then ---- Large units
            BaseEffectTable = EffectTemplate.ExplosionMediumWater
            ShakeTimeModifier = 1.0
            ShakeMaxMul = 0.25
        else                  ---- Medium units
            BaseEffectTable = EffectTemplate.ExplosionMediumWater
        end
    end

    -- Get Environmental effects for current layer
    EnvironmentalEffectTable = GetUnitEnvironmentalExplosionEffects(layer, scale)

    -- Merge resulting tables to final explosion emitter list
    if not table.empty(EnvironmentalEffectTable) then
        EffectTable = table.cat(BaseEffectTable, EnvironmentalEffectTable)
    else
        EffectTable = BaseEffectTable
    end

    -- Create Generic emitter effects
    CreateEffects(obj, army, EffectTable)

    -- Create Light particle flash
    CreateFlash(obj, -1, scale, army)

    -- Create scorch mark
    if layer == 'Land' then
        if scale > 1.2 then
            CreateScorchMarkDecal(obj, scale, army)
        else
            CreateScorchMarkSplat(obj, scale, army)
        end
    end

    -- Create GenericDebris chunks
    CreateDebrisProjectiles(obj, obj.Spec.BoundingXYZRadius, obj.Spec.Dimensions)

    -- Camera Shake  (.radius .maxshake .minshake .lifetime)
    obj:ShakeCamera(30 * scale, scale * ShakeMaxMul, 0, 0.5 + ShakeTimeModifier)
    obj:Destroy()
end

--- Old function that is no longer in use. Do not use this function - it creates a whole
-- lot of overhead that is not necessary.
function GetUnitEnvironmentalExplosionEffects(layer, scale)
    local EffectTable = {}
    if layer == 'Water' then
        if scale < 0.5 then
            EffectTable = EffectTemplate.Splashy
        elseif scale > 1.5 then
            EffectTable = EffectTemplate.ExplosionMediumWater
        else
            EffectTable = EffectTemplate.ExplosionSmallWater
        end
    end
    return EffectTable
end

-------------------------------
-- CREATELIGHTPARTICLE FLASH --
-------------------------------

--- A dummy function that should not be used in critical code. Instead, copy the body and adjust it accordingly.
function CreateFlash(obj, bone, scale, army)
    CreateLightParticle(obj, bone, army, scale * (6 + 4 * Random()) , 10.5 + 4 * Random(), 'glow_03', 'ramp_flare_02')
end

------------------------
-- SCORCH MARK SPLATS --
------------------------

--- A dummy function that should not be used in critical code. Instead, copy the body and adjust it accordingly.
function CreateScorchMarkSplat(obj, scale, army)
    CreateSplat(
        EntityGetPosition(obj), 
        6.28 * Random(), 
        ScorchSplatTextures[Random(1, ScorchSplatTexturesN)],
        scale * 4, scale * 4, 
        200 + 150 * Random(), 
        300 * 300 * Random(), 
        army
    )
end

--- A dummy function that should not be used in critical code. Instead, copy the body and adjust it accordingly.
function CreateScorchMarkDecal(obj, scale, army)
    CreateDecal(
        EntityGetPosition(obj), 
        6.28 * Random(), 
        ScorchDecalTextures[Random(1, ScorchDecalTexturesN)],
        '', 'Albedo', 
        scale * 3, scale * 3, 
        200 + 150 * Random(), 
        300 * 300 * Random(), 
        army
    )
end

--- A dummy function that should not be used in critical code. Instead, copy the body and adjust it accordingly.
function CreateRandomScorchSplatAtObject(obj, scale, LOD, lifetime, army)
    CreateSplat(
        EntityGetPosition(obj), 
        6.28 * Random(), 
        ScorchSplatTextures[Random(1, ScorchSplatTexturesN)],
        scale, scale, 
        LOD, lifetime, army)
end

----------------------
-- WRECKAGE EFFECTS --
----------------------

function CreateWreckageEffects(obj, prop)
    if IsUnit(obj) then
        local scale = GetAverageBoundingXYZRadius(obj)
        local emitters = {}
        local layer = obj.Layer

        if scale < 0.5 then -- SMALL UNITS
            emitters = CreateRandomEffects(prop, obj.Army, EffectTemplate.DefaultWreckageEffectsSml01, 1)
        elseif scale > 1.5 then -- LARGE UNITS
            local x,y,z = GetUnitSizes(obj)
            emitters = CreateEffectsWithRandomOffset(prop, obj.Army, EffectTemplate.DefaultWreckageEffectsLrg01, x, 0, z)
        else -- MEDIUM UNITS
            emitters = CreateRandomEffects(prop, obj.Army, EffectTemplate.DefaultWreckageEffectsMed01, 2)
        end

        -- Give the emitters created some random lifetimes
        ScaleEmittersParam(emitters, 'LIFETIME', 100, 1000)

        for k, v in emitters do
            v:ScaleEmitter(GetRandomFloat(0.25, 1))
        end
    end
end

--------------------------------
-- DEBRIS PROJECTILES EFFECTS --
--------------------------------

function CreateDebrisProjectiles(obj, volume, dimensions)

    -- for backwards compatibility
    local sx, sy, sz = unpack(dimensions)

    -- get number of projectiles
    local amount = MathMin(Random(1 + (volume * 25), (volume * 50)) , 100)
    for i = 1, amount do

        -- get some random numbers
        local r1, r2, r3 = Random(), Random(), Random() 

        -- position where debris starts
        local xpos = r1 * sx - (sx * 0.5)
        local ypos = r2 * sy
        local zpos = r3 * sz - (sz * 0.5)

        -- direction debris will go in
        local xdir = 10 * (r2 * sx - (sx * 0.5))
        local ydir = 10 * (r3 * sy)
        local zdir = 10 * ((1 - r1) * sz - (sz * 0.5))

        -- determine blueprint value
        local bp = false 
        if boundingXYZRadius < 0.2 then
            bp = '/effects/entities/DebrisMisc09/DebrisMisc09_proj.bp'
        elseif boundingXYZRadius < 2.0 then
            bp = '/effects/entities/DebrisMisc04/DebrisMisc04_proj.bp'
        else 
            bp = '/effects/entities/DebrisMisc010/DebrisMisc010_proj.bp'
        end

        -- create debris projectile
        EntityCreateProjectile(unit, bp, xpos, xpos, zpos, xdir, ydir + 4.5, zdir)
    end
end

------------------------
-- OLD EXPLOSION TECH --
------------------------

function CreateDefaultExplosion(unit, scale, overKillRatio)

    local spec = {
        Position = unit:GetPosition(),
        Dimensions = GetUnitSizes(unit),
        Volume = GetUnitVolume(unit),
    }
    local Explosion = unit
    local army = unit.Army

    CreateConcussionRing(Explosion, scale)
end

function CreateDestructionFire(object, scale)
    local proj = object:CreateProjectile('/effects/entities/DestructionFire01/DestructionFire01_proj.bp', 0, 0, 0, nil, nil, nil)
    proj:SetBallisticAcceleration(GetRandomFloat(-2, -3)):SetCollision(false)
    CreateEmitterOnEntity(proj, proj.Army, '/effects/emitters/destruction_explosion_fire_01_emit.bp'):ScaleEmitter(scale)
end

function CreateDestructionSparks(object, scale)
    local proj
    for i = 1, GetRandomInt(5, 10) do
        proj = object:CreateProjectile('/effects/entities/DestructionSpark01/DestructionSpark01_proj.bp', 0, 0, 0, nil, nil, nil)
        proj:SetBallisticAcceleration(GetRandomFloat(-2, -3)):SetCollision(false)
        CreateEmitterOnEntity(proj, proj.Army, '/effects/emitters/destruction_explosion_sparks_02_emit.bp'):ScaleEmitter(scale)
    end
end

function CreateFirePlume(object, scale)
    local proj
    for i = 1, GetRandomInt(4, 8) do
        proj = object:CreateProjectile('/effects/entities/DestructionFirePlume01/DestructionFirePlume01_proj.bp', 0, 0, 0, nil, nil, nil)
        proj:SetBallisticAcceleration(GetRandomFloat(-2, -3)):SetCollision(false)
        local emitter = CreateEmitterOnEntity(proj, proj.Army, '/effects/emitters/destruction_explosion_fire_plume_02_emit.bp')

        local lifetime = GetRandomFloat(12, 22)
        emitter:SetEmitterParam('REPEATTIME', lifetime)
        emitter:SetEmitterParam('LIFETIME', lifetime)
    end
end


function CreateExplosionProjectile(object, projectile, minnumber, maxnumber, effect, fxscalemin, fxscalemax, gravitymin, gravitymax, xpos, ypos, zpos, emitterparam)
    local fxscale = (Random() * (fxscalemax - fxscalemin) + fxscalemin)
    local yaccel = (Random() * (gravitymax - gravitymin) + gravitymin) * fxscale
    local number = (Random() * (maxnumber - minnumber) + minnumber)
    local proj, emitter
    ypos = ypos / 2
    for j = 1, number do
        proj = object:CreateProjectile(projectile, xpos, ypos, zpos, nil, nil, nil):SetBallisticAcceleration(yaccel):SetCollision(false)
        emitter = CreateEmitterOnEntity(proj, proj.Army, effect):ScaleEmitter(fxscale)
        if emitterparam then
            emitter:SetEmitterParam('REPEATTIME', math.floor(12 * fxscale + 0.5))
            emitter:SetEmitterParam('LIFETIME', math.floor(12 * fxscale + 0.5))
        end
    end
end

function CreateUnitDebrisEffects(object, bone)
    local Effects = {'/effects/emitters/destruction_explosion_smoke_09_emit.bp'}

    for k, v in Effects do
        CreateAttachedEmitter(object, bone, object.Army, v)
    end
end



-- Composite effects
-- *****************
function CreateExplosionMesh(object, projBP, posX, posY, posZ, scale, scaleVelocity, Lifetime, velX, velY, VelZ, orientRot, orientX, orientY, orientZ)

    proj = object:CreateProjectile(projBP, posX, posY, posZ, nil, nil, nil)
    proj:SetScale(scale,scale,scale):SetScaleVelocity(scaleVelocity):SetLifetime(Lifetime):SetVelocity(velX, velY, VelZ)

    local orient = {0, 0, 0, 0}
    orient[1], orient[2], orient[3], orient[4] = QuatFromRotation(orientRot, orientX, orientY, orientZ)
    proj:SetOrientation(orient, true)

    CreateEmitterAtEntity(proj, proj.Army, '/effects/emitters/destruction_explosion_smoke_10_emit.bp')
    return proj
end

function CreateCompositeExplosionMeshes(object)
    local lifetime = 6.0
    local explosionMeshProjectiles = {}
    local scalingmin = 0.065
    local scalingmax = 0.135

    table.insert(explosionMeshProjectiles, CreateExplosionMesh(object, '/effects/Explosion/Explosion01_a_proj.bp', 0.4, 0.4, 0.4, GetRandomFloat(0.1, 0.2), GetRandomFloat(scalingmin, scalingmax), lifetime, 0.1, 0.1, 0.1, -45, 1, 0, 0))
    table.insert(explosionMeshProjectiles, CreateExplosionMesh(object, '/effects/Explosion/Explosion01_b_proj.bp', -0.4, 0.4, 0.4, GetRandomFloat(0.1, 0.2), GetRandomFloat(scalingmin, scalingmax), lifetime, -0.1, 0.1, 0.1, -80, 1, 0, -1))
    table.insert(explosionMeshProjectiles, CreateExplosionMesh(object, '/effects/Explosion/Explosion01_c_proj.bp', -0.2, 0.4, -0.4, GetRandomFloat(0.1, 0.2), GetRandomFloat(scalingmin, scalingmax), lifetime, -0.04, 0.1, -0.1, -90, -1, 0, 0))
    table.insert(explosionMeshProjectiles, CreateExplosionMesh(object, '/effects/Explosion/Explosion01_d_proj.bp', 0.0, 0.7, 0.4, GetRandomFloat(0.1, 0.14), GetRandomFloat(scalingmin, scalingmax), lifetime, 0, 0.1, 0, 90, 1, 0, 0))

    -- Slow down scaling of secondary meshes
    WaitSeconds(0.3)
end

-----------------------------------------------------------------
--  Replaced by new effect structure (see EffectTemplates.lua) --
-----------------------------------------------------------------
function CreateSmoke(object, scale)
    local SmokeEffects = {'/effects/emitters/destruction_explosion_smoke_03_emit.bp',
                          '/effects/emitters/destruction_explosion_smoke_07_emit.bp'}

    for k, v in SmokeEffects do
        CreateEmitterAtEntity(object, object.Army, v):ScaleEmitter(scale)
    end
end

function CreateConcussionRing(object, scale)
    CreateEmitterAtEntity(object, object.Army, '/effects/emitters/destruction_explosion_concussion_ring_01_emit.bp'):ScaleEmitter(scale)
end

function CreateFireShadow(object, scale)
    CreateEmitterAtEntity(object ,object.Army, '/effects/emitters/destruction_explosion_fire_shadow_01_emit.bp'):ScaleEmitter(scale)
end


function OldCreateWreckageEffects(object)
    local Effects = {'/effects/emitters/destruction_explosion_smoke_08_emit.bp'}

    for k, v in Effects do
        CreateEmitterAtEntity(object, object.Army, v):SetEmitterParam('LIFETIME', GetRandomFloat(100, 1000))
    end
end
