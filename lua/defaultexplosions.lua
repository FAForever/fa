--****************************************************************************
--**
--**  File     :  /lua/defaultexplosions.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local Entity = import("/lua/sim/entity.lua").Entity

local util = import("/lua/utilities.lua")
local GetRandomFloat = util.GetRandomFloat
local GetRandomInt = util.GetRandomInt
local GetRandomOffset = util.GetRandomOffset
local GetRandomOffset2 = util.GetRandomOffset2

-- upvalue for performance
local EfctUtil = import("/lua/effectutilities.lua")
local ApplyWindDirection = EfctUtil.ApplyWindDirection
local CreateEffectsOpti = EfctUtil.CreateEffectsOpti
local CreateBoneEffectsOpti = EfctUtil.CreateBoneEffectsOpti
local CreateBoneEffectsOffsetOpti = EfctUtil.CreateBoneEffectsOffsetOpti

local EffectTemplate = import("/lua/effecttemplates.lua")
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
local MathCos = math.cos 
local MathSin = math.sin 

-- moho functions as upvalue for performance
local EntityGetPosition = moho.entity_methods.GetPosition
local EntityGetBlueprint = moho.entity_methods.GetBlueprint
local EntityShakeCamera = moho.entity_methods.ShakeCamera
local EntityCreateProjectile = moho.entity_methods.CreateProjectile

ScorchSplatTextures = {
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

-- as upvalue for performance
local UpvaluedScorchSplatTextures = ScorchSplatTextures
local ScorchSplatTexturesN = TableGetn(ScorchSplatTextures)

ScorchDecalTextures = {
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

-- as upvalue for performance
local UpvaluedScorchDecalTextures = ScorchDecalTextures
local ScorchDecalTexturesN = TableGetn(ScorchDecalTextures)

----------------------
-- UTILITY FUNCTION --
----------------------

--- Retrieves the size of the unit as defined in the blueprint. Do not use in critical code, instead
-- copy the body into your code for performance reasons.
---@param unit Unit The unit to get the size of.
---@return number 
---@return number
---@return number
function GetUnitSizes(unit)
    local bp = unit:GetBlueprint()
    return bp.SizeX or 0, bp.SizeY or 0, bp.SizeZ or 0
end

--- Retrieves the mesh extents of the unit as defined in the blueprint. Do not use in critical code, instead
-- copy the body into your code for performance reasons.
---@param unit any
---@return number
---@return number
---@return number
function GetUnitMeshExtents(unit)
    local bp = unit.Blueprint or unit:GetBlueprint()
    return bp.Physics.MeshExtentsX or bp.SizeX or 0, bp.Physics.MeshExtentsY or bp.SizeY or 0, bp.Physics.MeshExtentsZ or bp.SizeZ or 0
end

--- Retrieves the voume of the unit as defined in the blueprint. Do not use in critical code, instead
-- copy the body into your code for performance reasons.
---@param unit Unit The unit to get the volume of.
---@return number
function GetUnitVolume(unit)
    local x, y, z = GetUnitSizes(unit)
    return x * y * z
end

--- Retrieves bounding diameter over x/z axis. Do not use in critical code, instead
-- copy the body into your code for performance reasons. This function is 
-- legacy code and is full of errors. Use GetAverageBoundingXZRadiusCorrect 
-- if you're interested in the actual average bounding radius.
---@param unit Unit The unit to get the diameter of.
---@return number
function GetAverageBoundingXZRadius(unit)
    local bp = unit:GetBlueprint()
    return ((bp.SizeX or 0) + (bp.SizeZ or 0)) * 0.5
end

--- Retrieves bounding radius over x/z axis. Do not use in critical code, instead
-- copy the body into your code for performance reasons. This function is 
---@param unit Unit The unit to get the radius of.
---@return number
function GetAverageBoundingXZRadiusCorrect(unit)
    local bp = unit:GetBlueprint()
    return ((bp.SizeX or 1) + (bp.SizeZ or 1)) * 0.25
end

--- Retrieves bounding diameter x/y/z. Do not use in critical code, instead
-- copy the body into your code for performance reasons. This function is 
-- legacy code and is full of errors. Use GetAverageBoundingXYZRadiusCorrect 
-- if you're interested in the actual average bounding radius.
---@param unit Unit The unit to get the diameter of.
---@return number
function GetAverageBoundingXYZRadius(unit)
    local x, y, z = GetUnitMeshExtents(unit)
    return (x + y + z) * 0.333
end

--- Retrieves bounding radius over all axis. Do not use in critical code, instead
-- copy the body into your code for performance reasons.
---@param unit Unit The unit to get the radius of.
---@return number
function GetAverageBoundingXYZRadiusCorrect(unit)
    local bp = unit:GetBlueprint()
    return ((bp.SizeX or 1) + (bp.SizeZ or 1) + (bp.SizeY or 1)) * 0.166
end

--- ??, what is the mathematics here exactly?
---@param rotation number
---@param x number
---@param y number
---@param z number
---@return number qx
---@return number qy
---@return number qz
---@return number qw
function QuatFromRotation(rotation, x, y, z)
    local angleRot, qw, qx, qy, qz, angle
    angle = 0.00872664625 * rotation
    angleRot = MathSin(angle)
    qw = MathCos(angle)
    qx = x * angleRot
    qy = y * angleRot
    qz = z * angleRot
    return qx, qy, qz, qw
end

--------------------------------------
-- DEFAULT EXPLOSION BASE FUNCTIONS --
--------------------------------------

-- random selection of debris that is useful, the earlier the debris is in the table
-- the more likely it is spawned.
local ProjectileDebrisBps = {
    '/effects/entities/DebrisMisc04/DebrisMisc04_proj.bp',
    '/effects/entities/DebrisMisc04/DebrisMisc04_proj.bp',
    '/effects/entities/DebrisMisc04/DebrisMisc04_proj.bp',
    '/effects/entities/DebrisMisc04/DebrisMisc04_proj.bp',
    '/effects/entities/DebrisMisc09/DebrisMisc09_proj.bp',
    '/effects/entities/DebrisMisc09/DebrisMisc09_proj.bp',
    '/effects/entities/DebrisMisc09/DebrisMisc09_proj.bp',
    '/effects/entities/DebrisMisc010/DebrisMisc010_proj.bp',
    '/effects/entities/DebrisMisc010/DebrisMisc010_proj.bp',
    '/effects/entities/DebrisMisc010/DebrisMisc010_proj.bp',
}

local ProjectileDebrisBpsN = TableGetn(ProjectileDebrisBps)

--- Creates the default unit explosion used by almost all units in the game.
-- @unit The Unit to create the explosion for.
-- @overKillRatio Has an impact on how strong the explosion is.
---@param unit Unit
---@param debrisMultiplier? number
---@param circularDebris? boolean
function CreateScalableUnitExplosion(unit, debrisMultiplier, circularDebris)

    debrisMultiplier = debrisMultiplier or 1
    circularDebris = circularDebris or false

    if unit and (not IsDestroyed(unit)) then
        if IsUnit(unit) then

            -- cache blueprint values
            local blueprint = EntityGetBlueprint(unit)
            local sx = blueprint.SizeX or 1 
            local sy = blueprint.SizeY or 1 
            local sz = blueprint.SizeZ or 1 

            -- cache stats 
            local army = unit.Army
            local boundingXZRadius = 0.25 * (sx + sz)
            local boundingXYZRadius = 0.166 * (sx + sy + sz)
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
                        UpvaluedScorchDecalTextures[Random(1, ScorchDecalTexturesN)], 
                        '', 
                        'Albedo', 
                        boundingXZRadius, 
                        boundingXZRadius, 
                        scorchLOD, 
                        scorchDuration, 
                        army
                    )
                else
                    CreateSplat(
                        position, 
                        scorchRotation, 
                        UpvaluedScorchSplatTextures[Random(1, ScorchSplatTexturesN)], 
                        boundingXZRadius, 
                        boundingXZRadius, 
                        scorchLOD,
                        scorchDuration, 
                        army
                    )
                end

            elseif layer == 'Air' then
                -- determine air effects
                if boundingXZRadius < 1.1 then
                    baseEffects = ExplosionSmallAir
                elseif boundingXZRadius > 7 then
                    -- large units cause camera to shake
                    baseEffects = ExplosionLarge
                    ShakeTimeModifier = 1.0
                    ShakeMaxMul = 0.25
                else
                    baseEffects = ExplosionMedium
                end
            elseif layer == 'Water' then
                -- determine water effects
                if boundingXZRadius < 2 then
                    baseEffects = ExplosionSmallWater
                elseif boundingXZRadius > 3.6 then
                    -- large units cause camera to shake
                    baseEffects = ExplosionMediumWater
                    ShakeTimeModifier = 1.0
                    ShakeMaxMul = 0.25
                else
                    baseEffects = ExplosionMediumWater
                end

                -- environment effects
                if boundingXZRadius < 1.0 then
                    environmentEffects = Splashy
                end
            end

            -- create the emitters  
            if baseEffects then 
                CreateEffectsOpti(unit, army, baseEffects)
            end

            if environmentEffects then 
                CreateEffectsOpti(unit, army, environmentEffects)       
            end    

            -- create the flash
            CreateLightParticle(
                unit, 
                -1, 
                army, 
                boundingXZRadius * (2 + 1 * Random()),  -- (2, 3)
                10.5 + 4 * Random(), -- (10.5, 14.5)
                'glow_03', 
                'ramp_flare_02'
            )

            -- determine debris amount
            local amount = debrisMultiplier * MathMin(Random(1 + (boundingXYZRadius * 6), (boundingXYZRadius * 15)) , 100)

            -- determine debris velocity range
            local velocity = 2 * boundingXYZRadius
            local hVelocity = 0.5 * velocity

            -- determine heading adjustments for debris origin
            local heading = -1 * unit:GetHeading() -- inverse heading because Supreme Commander :)
            local mch = MathCos(heading)
            local msh = MathSin(heading)

            -- make it slightly smaller so that debris originates from mesh and not from the air
            sx = 0.8 * sx 
            sy = 0.8 * sy 
            sz = 0.8 * sz

            -- create debris
            for i = 1, amount do

                -- get some random numbers
                local r1, r2, r3 = Random(), Random(), Random() 

                -- position somewhere in the size of the unit
                local xpos = r1 * sx - (sx * 0.5)
                local ypos = 0.1 * sy + 0.5 * r2 * sy
                local zpos = r3 * sz - (sz * 0.5)

                -- launch them into space
                local xdir, ydir, zdir 
                if circularDebris then 
                    xdir = velocity * r1 - (hVelocity)
                    ydir = velocity * r2 - (hVelocity)
                    zdir = velocity * r3 - (hVelocity)
                else 
                    xdir = velocity * r1 - (hVelocity)
                    ydir = boundingXYZRadius + velocity * r2
                    zdir = velocity * r3 - (hVelocity)
                end

                -- choose a random blueprint
                local bp = ProjectileDebrisBps[MathMin(ProjectileDebrisBpsN, Random(1, i))]

                EntityCreateProjectile(
                    unit, 
                    bp, 
                    xpos * mch - zpos * msh, -- adjust for orientation of unit
                    ypos, 
                    xpos * msh + zpos * mch, -- adjust for orientation of unit
                    xdir * mch - zdir * msh, -- adjust for orientation of unit 
                    ydir, 
                    xdir * msh + zdir * mch  -- adjust for orientation of unit
                )
            end

            -- do camera shake
            EntityShakeCamera(unit, 30 * boundingXZRadius, boundingXZRadius * shakeMaxMul, 0, 0.5 + shakeTimeModifier)
        end
    end
end

--- Creates a flash and fire emitters that represents an explosion on hit.
-- @param obj The entity to create the flash at.
-- @param scale The scale of the flash.
---@param obj Unit
---@param scale number
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
        CreateEffectsOpti(obj, army, FireCloudMed01)
    end
end

--- Creates explosion emitters that represent a hit. Do not use in critical code, instead
-- copy the body.
-- @param obj The entity to create the emitters for.
---@param obj Unit
---@param scale number Unused parameter.
---@param xOffset number Offset on the x-axis.
---@param yOffset number Offset on the y-axis.
---@param zOffset number Offset on the z-axis.
function CreateDefaultHitExplosionOffset(obj, scale, xOffset, yOffset, zOffset)
    if obj:BeenDestroyed() then
        return
    end

    CreateBoneEffectsOffsetOpti(obj, -1, obj.Army, DefaultHitExplosion01, xOffset, yOffset, zOffset)
end

--- Creates a flash and fire emitters that represents an explosion on hit.
---@param obj Unit The entity to create the flash at.
---@param boneName Bone The bone to attach the effect to.
---@param scale number The scale of the flash.
function CreateDefaultHitExplosionAtBone(obj, boneName, scale)
    local army = obj.Army
    CreateFlash(obj, boneName, scale * 0.5, army)
    CreateBoneEffectsOpti(obj, boneName, army, FireCloudMed01)
end

---@param obj Unit
function CreateTimedStuctureUnitExplosion(obj, deathAnimation)

    local numExplosions = math.floor(0.75 * GetAverageBoundingXYZRadius(obj) * GetRandomInt(2,4))
    local x,y,z = GetUnitMeshExtents(obj)
    obj:ShakeCamera(30, 1, 0, 0.45 * numExplosions)

    -- if there is a death animation, roll with that
    if deathAnimation then
        while deathAnimation:GetAnimationFraction() < 1 do
            CreateDefaultHitExplosionOffset(obj, 1.0, unpack({GetRandomOffset(x, y, z, 0.8)}))
            obj:PlayUnitSound('DeathExplosion')
            WaitSeconds(GetRandomFloat(0.1, 0.2))
        end
    -- do generic destruction effect
    else
        for i = 0, numExplosions do
            CreateDefaultHitExplosionOffset(obj, 1.0, unpack({GetRandomOffset(x, y, z, 0.8)}))
            obj:PlayUnitSound('DeathExplosion')
            WaitSeconds(GetRandomFloat(0.1, 0.2))
        end
    end
end

--- Old function that is no longer in use. Do not use this function - it creates a whole
-- lot of overhead that is not necessary.
---@param unit Unit
---@param overKillRatio number
---@return table
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
---@param unit Unit
---@param overKillRatio number
---@return Entity
function CreateUnitExplosionEntity(unit, overKillRatio)
    local localentity = Entity(MakeExplosionEntitySpec(unit, overKillRatio))
    Warp(localentity, unit:GetPosition())
    return localentity
end

--- Old function that is no longer in use. Do not use this function - it creates a whole
-- lot of overhead that is not necessary.
---@param obj Unit
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
    CreateEffectsOpti(obj, army, EffectTable)

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
---@param layer string
---@param scale number
---@return table
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
---@param obj Unit
---@param bone string
---@param scale number
---@param army string
function CreateFlash(obj, bone, scale, army)
    CreateLightParticle(obj, bone, army, scale * (6 + 4 * Random()) , 10.5 + 4 * Random(), 'glow_03', 'ramp_flare_02')
end

------------------------
-- SCORCH MARK SPLATS --
------------------------

--- A dummy function that should not be used in critical code. Instead, copy the body and adjust it accordingly.
---@param obj Unit
---@param scale number
---@param army string
function CreateScorchMarkSplat(obj, scale, army)
    CreateSplat(
        EntityGetPosition(obj),
        6.28 * Random(),
        UpvaluedScorchSplatTextures[Random(1, ScorchSplatTexturesN)],
        scale * 4, scale * 4,
        200 + 150 * Random(),
        300 * 300 * Random(),
        army
    )
end

--- A dummy function that should not be used in critical code. Instead, copy the body and adjust it accordingly.
---@param obj Unit
---@param scale number
---@param army string
function CreateScorchMarkDecal(obj, scale, army)
    CreateDecal(
        EntityGetPosition(obj), 
        6.28 * Random(), 
        UpvaluedScorchDecalTextures[Random(1, ScorchDecalTexturesN)],
        '', 'Albedo', 
        scale * 3, scale * 3, 
        200 + 150 * Random(), 
        300 * 300 * Random(), 
        army
    )
end

--- A dummy function that should not be used in critical code. Instead, copy the body and adjust it accordingly.
---@param obj Unit
---@param scale number
---@param LOD integer
---@param lifetime integer
---@param army string
function CreateRandomScorchSplatAtObject(obj, scale, LOD, lifetime, army)
    CreateSplat(
        EntityGetPosition(obj), 
        6.28 * Random(), 
        UpvaluedScorchSplatTextures[Random(1, ScorchSplatTexturesN)],
        scale, scale, 
        LOD, lifetime, army)
end

----------------------
-- WRECKAGE EFFECTS --
----------------------

local MathFloor = math.floor

-- upvalue for performance
local IEffectSetEmitterParam = _G.moho.IEffect.SetEmitterParam
local IEffectScaleEmitter = _G.moho.IEffect.ScaleEmitter
local IEffectOffsetEmitter = _G.moho.IEffect.OffsetEmitter
local IEffectSetEmitterCurveParam = _G.moho.IEffect.SetEmitterCurveParam

-- direct access for performance
local DefaultWreckageEffects = EffectTemplate.DefaultWreckageEffectsLrg01
local DefaultWreckageEffectsCount = EffectTemplate.DefaultWreckageEffectsLrg01Count

-- remove all wreckage effects, but keep for compatibility
---@param unit Unit
---@param prop Prop
function CreateWreckageEffects(unit, prop)

    -- determine number of effects
    local blueprint = unit.Blueprint or EntityGetBlueprint(unit)

    -- we can't make an animation for these based on bones: they spawn at the unanimated locations
    if blueprint.Display.AnimationDeath then
        return
    end

    -- determine number of effects
    local bones = unit:GetBoneCount()
    local size = MathFloor(0.2 * (blueprint.SizeX + blueprint.SizeY + blueprint.SizeZ)) + 1
    if size > bones - 1 then
        size = bones - 1
    end

    -- localize for performance
    local Random = Random
    local bone, effect, emitter, r1

    -- spawn the effects
    for k = 1, size do 
        -- create an emitter at a bone
        bone = Random(1, bones - 1) - 1
        effect = Random(1, DefaultWreckageEffectsCount)
        emitter = CreateEmitterAtBone(prop, bone, unit.Army, DefaultWreckageEffects[effect])

        -- larger smoke tends to live longer
        r1 = Random()
        IEffectScaleEmitter(emitter, 0.5 + 0.75 * r1)
        IEffectSetEmitterParam(emitter, 'LIFETIME', 40 + 75 * r1)

        -- apply wind direction
        ApplyWindDirection(emitter, 1.0)

        prop.Trash:Add(emitter)
    end
end

--------------------------------
-- DEBRIS PROJECTILES EFFECTS --
--------------------------------

---@param obj Unit
---@param volume number
---@param dimensions Vector
function CreateDebrisProjectiles(obj, volume, dimensions)

    -- for backwards compatibility
    local sx, sy, sz = unpack(dimensions)

    -- determine blueprint value
    local bp = false
    if volume < 0.2 then
        bp = '/effects/entities/DebrisMisc09/DebrisMisc09_proj.bp'
    elseif volume < 2.0 then
        bp = '/effects/entities/DebrisMisc04/DebrisMisc04_proj.bp'
    else 
        bp = '/effects/entities/DebrisMisc010/DebrisMisc010_proj.bp'
    end

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

        -- create debris projectile
        EntityCreateProjectile(obj, bp, xpos, xpos, zpos, xdir, ydir + 4.5, zdir)
    end
end

------------------------
-- OLD EXPLOSION TECH --
------------------------

---@param unit Unit
---@param scale number
---@param overKillRatio number
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

---@param object Unit
---@param scale number
function CreateDestructionFire(object, scale)
    local proj = object:CreateProjectile('/effects/entities/DestructionFire01/DestructionFire01_proj.bp', 0, 0, 0, nil, nil, nil)
    proj:SetBallisticAcceleration(GetRandomFloat(-2, -3)):SetCollision(false)
    CreateEmitterOnEntity(proj, proj.Army, '/effects/emitters/destruction_explosion_fire_01_emit.bp'):ScaleEmitter(scale)
end

---@param object Unit
---@param scale number
function CreateDestructionSparks(object, scale)
    local proj
    for i = 1, GetRandomInt(5, 10) do
        proj = object:CreateProjectile('/effects/entities/DestructionSpark01/DestructionSpark01_proj.bp', 0, 0, 0, nil, nil, nil)
        proj:SetBallisticAcceleration(GetRandomFloat(-2, -3)):SetCollision(false)
        CreateEmitterOnEntity(proj, proj.Army, '/effects/emitters/destruction_explosion_sparks_02_emit.bp'):ScaleEmitter(scale)
    end
end

---@param object Unit
---@param scale number
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

---@param object Unit
---@param projectile string
---@param minnumber integer
---@param maxnumber integer
---@param effect string
---@param fxscalemin number
---@param fxscalemax number
---@param gravitymin number
---@param gravitymax number
---@param xpos number
---@param ypos number
---@param zpos number
---@param emitterparam string
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


---@param object Unit
---@param bone Bone
function CreateUnitDebrisEffects(object, bone)
    local Effects = {'/effects/emitters/destruction_explosion_smoke_09_emit.bp'}

    for k, v in Effects do
        CreateAttachedEmitter(object, bone, object.Army, v)
    end
end

-- Composite effects
-- *****************

---@param object Unit
---@param projBP string
---@param posX number
---@param posY number
---@param posZ number
---@param scale number
---@param scaleVelocity number
---@param Lifetime number
---@param velX number
---@param velY number
---@param VelZ number
---@param orientRot number
---@param orientX number
---@param orientY number
---@param orientZ number
---@return Projectile
function CreateExplosionMesh(object, projBP, posX, posY, posZ, scale, scaleVelocity, Lifetime, velX, velY, VelZ, orientRot, orientX, orientY, orientZ)

    local proj = object:CreateProjectile(projBP, posX, posY, posZ, nil, nil, nil)
    proj:SetScale(scale,scale,scale):SetScaleVelocity(scaleVelocity):SetLifetime(Lifetime):SetVelocity(velX, velY, VelZ)

    local orient = {0, 0, 0, 0}
    orient[1], orient[2], orient[3], orient[4] = QuatFromRotation(orientRot, orientX, orientY, orientZ)
    proj:SetOrientation(orient, true)

    CreateEmitterAtEntity(proj, proj.Army, '/effects/emitters/destruction_explosion_smoke_10_emit.bp')
    return proj
end

---@param object Unit
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

---@param object Unit
---@param scale number
function CreateSmoke(object, scale)
    local SmokeEffects = {'/effects/emitters/destruction_explosion_smoke_03_emit.bp',
                          '/effects/emitters/destruction_explosion_smoke_07_emit.bp'}

    for k, v in SmokeEffects do
        CreateEmitterAtEntity(object, object.Army, v):ScaleEmitter(scale)
    end
end

---@param object Unit
---@param scale number
function CreateConcussionRing(object, scale)
    CreateEmitterAtEntity(object, object.Army, '/effects/emitters/destruction_explosion_concussion_ring_01_emit.bp'):ScaleEmitter(scale)
end

---@param object Unit
---@param scale number
function CreateFireShadow(object, scale)
    CreateEmitterAtEntity(object ,object.Army, '/effects/emitters/destruction_explosion_fire_shadow_01_emit.bp'):ScaleEmitter(scale)
end

---@param object Unit
function OldCreateWreckageEffects(object)
    local Effects = {'/effects/emitters/destruction_explosion_smoke_08_emit.bp'}

    for k, v in Effects do
        CreateEmitterAtEntity(object, object.Army, v):SetEmitterParam('LIFETIME', GetRandomFloat(100, 1000))
    end
end



----------------------------------------------------------------
-- Modern explosion effects

--#region 

--- Creates various fire plumes at bones that move away from the origin of the entity
---@param entity BoneObject
---@param army Army
---@param bones Bone[]
---@param yOffset number | nil
CreateFirePlumes = function(entity, army, bones, yOffset)
    yOffset = yOffset or 0
    local ex, ey, ez = entity:GetPositionXYZ()
    for _, vBone in bones do
        -- determine local offset
        local bx, by, bz = entity:GetPositionXYZ(vBone)
        local dx, dy, dz = bx - ex, by - ey, bz - ez

        -- determine velocity and make it a bit random
        local id = 1 / math.sqrt(dx * dx + dy * dy + dz * dz)
        local vx = id * dx + Random() * 0.6 - 0.3
        local vy = id * dy + Random() * 0.3
        local vz = id * dz + Random() * 0.6 - 0.3

        -- create the projectile and the plume
        local projectile = entity:CreateProjectile('/effects/entities/DestructionFirePlume01/DestructionFirePlume01_proj.bp', dx, dy + yOffset, dz, vx, vy, vz)
        projectile:SetBallisticAcceleration(-1 - Random())
        projectile:SetVelocity(1 + 3 * Random())
        CreateEmitterOnEntity(projectile, army, '/effects/emitters/destruction_explosion_fire_plume_02_emit.bp')
    end
end

local CreateFirePlumeCache = { }

--- Creates a single fire plume at a bone that moves away from the origin of the entity
---@param entity BoneObject
---@param army Army
---@param bone Bone
---@param yOffset number | nil
CreateFirePlume = function(entity, army, bone, yOffset)
    CreateFirePlumeCache[1] = bone
    CreateFirePlumes(entity, army, CreateFirePlumeCache, yOffset)
end

--- Creates basic large-sized debris / dirt as emitters
---@param entity BoneObject
---@param army Army
---@param bone Bone
CreateLargeDebrisEmitters  = function(entity, army, bone)
    for _, effect in EffectTemplate.ExplosionDebrisLrg01 do
        CreateAttachedEmitter(entity, bone, army, effect)
    end
end

--- Creates basic medium-sized debris / dirt as emitters
---@param entity BoneObject
---@param army Army
---@param bone Bone
CreateMediumDebrisEmitters = function(entity, army, bone)
    for _, effect in EffectTemplate.ExplosionDebrisMed01 do
        CreateAttachedEmitter(entity, bone, army, effect)
    end
end

--- Creates basic small-sized debris / dirt as emitters
---@param entity BoneObject
---@param army Army
---@param bone Bone
CreateSmallDebrisEmitters = function(entity, army, bone)
    for _, effect in EffectTemplate.ExplosionDebrisSml01 do
        CreateAttachedEmitter(entity, bone, army, effect)
    end
end

--- Creates basic damage effect emitters
---@param self BoneObject
---@param bone Bone
---@param army Army
---@param scale number | nil
CreateDamageEmitters = function(self, bone, army, scale)
    scale = scale or 1.0
    for k, v in EffectTemplate.DamageFireSmoke01 do
        CreateAttachedEmitter(self, bone, army, v):ScaleEmitter(1.5)
    end
end

--#endregion
