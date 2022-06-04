
-- imports for functionality
local AeonBuildBeams01 = import('/lua/EffectTemplates.lua').AeonBuildBeams01
local AeonBuildBeams02 = import('/lua/EffectTemplates.lua').AeonBuildBeams02

local CachedVector = Vector(0, 0, 0)

-- globals as upvalues for performance
local WaitTicks = coroutine.yield

local CreateAttachedEmitter = CreateAttachedEmitter
local CreateEmitterOnEntity = CreateEmitterOnEntity
local AttachBeamEntityToEntity = AttachBeamEntityToEntity

-- moho functions as upvalues for performance
local EntityGetOrientation = moho.entity_methods.GetOrientation
local EntitySetOrientation = moho.entity_methods.SetOrientation
local EntityCreateProjectile = moho.entity_methods.CreateProjectile
local EntityCreateProjectileAtBone = moho.entity_methods.CreateProjectileAtBone

local UnitGetFractionComplete = moho.unit_methods.GetFractionComplete

local ProjectileSetScale = moho.projectile_methods.SetScale

local EmitterSetEmitterCurveParam = moho.IEffect.SetEmitterCurveParam
local EmitterScaleEmitter = moho.IEffect.ScaleEmitter

local SliderSetSpeed = moho.SlideManipulator.SetSpeed
local SliderSetGoal = moho.SlideManipulator.SetGoal 
local SliderSetWorldUnits = moho.SlideManipulator.SetWorldUnits

-- upvalued trashbag functions for performance
local TrashBag = _G.TrashBag
local TrashBagAdd = TrashBag.Add

local CategoriesHover = categories.HOVER
local CategoriesLand = categories.LAND

--- The build animation of an engineer.
-- @param builder The engineer in question.
-- @param unitBeingBuilt The unit we're building.
-- @param buildEffectsBag The trash bag for the build effects.
function CreateAeonConstructionUnitBuildingEffects(builder, unitBeingBuilt, buildEffectsBag)
    local army = builder.Army

    -- create effect on builder
    TrashBagAdd(buildEffectsBag, CreateEmitterOnEntity(builder, army, '/effects/emitters/aeon_build_01_emit.bp') )

    -- create beam builder -> target
    for _, v in AeonBuildBeams01 do
        TrashBagAdd(buildEffectsBag, AttachBeamEntityToEntity(builder, -1, unitBeingBuilt, -1, army, v))
    end
end

--- The build animation of the commander.
-- @param builder The commander in question.
-- @param unitBeingBuilt The unit we're building.
-- @param buildEffectBones The bone(s) of the commander where the effect starts.
-- @param buildEffectsBag The trash bag for the build effects.
function CreateAeonCommanderBuildingEffects(builder, unitBeingBuilt, buildEffectBones, buildEffectsBag)
    local army = builder.Army

    -- create beam builder -> target
    for _, vBone in buildEffectBones do
        TrashBagAdd(buildEffectsBag, CreateAttachedEmitter(builder, vBone, army, '/effects/emitters/aeon_build_02_emit.bp'))
        for _, v in AeonBuildBeams01 do
            TrashBagAdd(buildEffectsBag, AttachBeamEntityToEntity(builder, vBone, unitBeingBuilt, -1, army, v))
        end
    end
end

--- The shared functionality between building structures and units
-- @param pool The mercury pool for the build effect.
-- @param unitBeingBuilt The unit that is being made.
-- @param unitBeingBuiltTrash The generic trashbag of the unit.
-- @param unitBeingBuiltOnStopBeingBuiltTrash The OnStopBeingBuilt trashbag of the unit.
local function SharedBuildThread(pool, unitBeingBuilt, unitBeingBuiltTrash, unitBeingBuiltOnStopBeingBuiltTrash, sx, sy, sz)

    -- -- Determine offset for hover units

    local offset, slider = false, false
    if EntityCategoryContains(CategoriesHover, unitBeingBuilt) then 

        -- set elevation offset
        offset = unitBeingBuilt.Blueprint.Elevation or 0

        -- create a slider
        slider = CreateSlider(unitBeingBuilt, 0)

        SliderSetWorldUnits(slider, true)
        SliderSetGoal(slider, 0, 0, 0)
        SliderSetSpeed(slider, 100)

        TrashBagAdd(unitBeingBuiltTrash, slider)
        TrashBagAdd(unitBeingBuiltOnStopBeingBuiltTrash, slider)
    end

    -- -- Shrink pool accordingly

    local cFraction, progress = false, false
    local fraction = UnitGetFractionComplete(unitBeingBuilt)
    while fraction < 1 do

        -- only update when we make progress
        cFraction = UnitGetFractionComplete(unitBeingBuilt)
        if cFraction > fraction then 

            -- store updated value
            fraction = cFraction

            -- only adjust pool when more than 80% complete to match the shader animation
            if fraction > 0.8 then 

                progress = 5 * (fraction - 0.8)
                if progress < 0 then 
                    progress = 0 
                end

                scale = 1 - progress * progress
                ProjectileSetScale(pool, sx * scale, 1.5 * sy * scale, sz * scale)
            end

            -- adjust slider for hover units
            if slider then 
                SliderSetGoal(slider, 0, fraction * offset, 0)
                SliderSetSpeed(slider, fraction * fraction * fraction)
            end
        end

        -- wait a tick
        WaitTicks(2)
    end

    -- set correct shader of unitBeingBuilt so that it happens instantly after finishing
    unitBeingBuilt:SetMesh(unitBeingBuilt.Blueprint.Display.MeshBlueprint, true)
end

--- The build animation for Aeon buildings in general.
-- @param unitBeingBuilt The unit we're trying to build.
-- @param effectsBag The build effects bag containing the pool and emitters.
function CreateAeonBuildBaseThread(unitBeingBuilt, builder, effectsBag)

    -- -- Hold up for orientation to receive an update

    WaitTicks(2)

    -- always check after a wait
    if (not unitBeingBuilt) or unitBeingBuilt.Dead then 
        return 
    end

    -- -- Initialize various info used throughout the function

    local effect = false
    local army = unitBeingBuilt.Army
    local unitBeingBuiltTrash = unitBeingBuilt.Trash
    local unitOnStopBeingBuiltTrash = unitBeingBuilt.OnBeingBuiltEffectsBag
    local bp = unitBeingBuilt.Blueprint
    local sx = bp.Physics.MeshExtentsX or bp.Footprint.SizeX
    local sz = bp.Physics.MeshExtentsZ or bp.Footprint.SizeZ
    local sy = bp.Physics.MeshExtentsY or bp.Footprint.SizeYX or (sx + sz)

    -- -- Create pool of mercury

    local pool = EntityCreateProjectile(unitBeingBuilt, '/effects/entities/AeonBuildEffect/AeonBuildEffect01_proj.bp', nil, 0, 0, nil, nil, nil)
    TrashBagAdd(unitBeingBuiltTrash, pool)
    TrashBagAdd(unitOnStopBeingBuiltTrash, pool)

    EntitySetOrientation(pool, EntityGetOrientation(unitBeingBuilt), true)
    ProjectileSetScale(pool, sx, sy * 1.5, sz)

    -- -- Create effects

    effect = CreateEmitterOnEntity(pool, army, '/effects/emitters/aeon_being_built_ambient_01_emit.bp')
    EmitterSetEmitterCurveParam(effect, 'X_POSITION_CURVE', 0, sx * 1.5)
    EmitterSetEmitterCurveParam(effect, 'Z_POSITION_CURVE', 0, sz * 1.5)

    effect = CreateEmitterOnEntity(pool, army, '/effects/emitters/aeon_being_built_ambient_03_emit.bp')
    EmitterScaleEmitter(effect, (sx + sz) * 0.3)

    -- -- Create a thread to scale the pool

    local thread = ForkThread(SharedBuildThread, 
        pool, unitBeingBuilt, 
        unitBeingBuiltTrash, unitOnStopBeingBuiltTrash, 
        sx, sy, sz
    )

    TrashBagAdd(unitBeingBuiltTrash, thread)
    TrashBagAdd(unitOnStopBeingBuiltTrash, thread)
end

--- The build animation for Aeon factories, including the pool and dummy unit.
-- @param builder The factory that is building the unit.
-- @param unitBeingBuilt The unit we're trying to build.
-- @param buildEffectBones The arms of the factory where the build beams come from.
-- @param buildBone The location where the unit is beint built.
-- @param effectsBag The build effects bag.
function CreateAeonFactoryBuildingEffects(builder, unitBeingBuilt, buildEffectBones, buildBone, effectsBag)

    -- -- Hold up for orientation to receive an update

    WaitTicks(2)

    -- always check after a wait
    if (not unitBeingBuilt) or unitBeingBuilt.Dead then 
        return 
    end

    -- -- Create build beams for factory
    
    local army = unitBeingBuilt.Army
    for _, vBone in buildEffectBones do
        TrashBagAdd(effectsBag, CreateAttachedEmitter(builder, vBone, army, '/effects/emitters/aeon_build_03_emit.bp'))
        for _, vBeam in AeonBuildBeams02 do
            TrashBagAdd(effectsBag, AttachBeamEntityToEntity(builder, vBone, builder, buildBone, army, vBeam))
        end
    end

    -- -- Create persistent state between calls

    local initialised = unitBeingBuilt.ConstructionInitialised
    if not initialised then 
        unitBeingBuilt.ConstructionInitialised = true

        -- -- Initialize various info used throughout the function

        local effect = false
        local unitBeingBuiltTrash = unitBeingBuilt.Trash
        local unitOnStopBeingBuiltTrash = unitBeingBuilt.OnBeingBuiltEffectsBag

        local sx = unitBeingBuilt.Blueprint.Physics.MeshExtentsX or unitBeingBuilt.Blueprint.Footprint.SizeX
        local sz = unitBeingBuilt.Blueprint.Physics.MeshExtentsZ or unitBeingBuilt.Blueprint.Footprint.SizeZ
        local sy = unitBeingBuilt.Blueprint.Physics.MeshExtentsY or unitBeingBuilt.Blueprint.Footprint.SizeY or (sx + sz)

        -- -- Create pool of mercury

        local pool = EntityCreateProjectile(unitBeingBuilt, '/effects/entities/AeonBuildEffect/AeonBuildEffect01_proj.bp', 0, 0, 0, nil, nil, nil)
        TrashBagAdd(unitBeingBuiltTrash, pool)
        TrashBagAdd(unitOnStopBeingBuiltTrash, pool)

        ProjectileSetScale(pool, sx, sy * 1.5, sz)
        if EntityCategoryContains(CategoriesLand, builder) then 
            local orientation = EntityGetOrientation(unitBeingBuilt)
            EntitySetOrientation(pool, orientation, true)
        end

        -- -- Create effects of pool

        effect = CreateEmitterOnEntity(pool, army, '/effects/emitters/aeon_being_built_ambient_02_emit.bp')
        EmitterSetEmitterCurveParam(effect, 'X_POSITION_CURVE', 0, sx * 1.5)
        EmitterSetEmitterCurveParam(effect, 'Z_POSITION_CURVE', 0, sz * 1.5)

        effect = CreateEmitterOnEntity(pool, army, '/effects/emitters/aeon_being_built_ambient_03_emit.bp')
        EmitterScaleEmitter(effect, (sx + sz) * 0.3)

        -- -- Create a thread to scale the pool and move the unit accordingly

        local thread = ForkThread(SharedBuildThread, 
            pool, unitBeingBuilt, 
            unitBeingBuiltTrash, unitOnStopBeingBuiltTrash,
            sx, sy, sz
        )

        TrashBagAdd(unitBeingBuiltTrash, thread)
        TrashBagAdd(unitOnStopBeingBuiltTrash, thread)
    end
end

--- Bones where the sparkles spawn at
local ColossusEffectBones = {
    "Left_Footfall"
  , "Left_Leg_B01"
  , "Left_Leg_B02"
  , "Right_Leg_B02"
  , "Right_Leg_B01"
  , "Right_Footfall"
  , "Right_Arm_Muzzle01"
  , "Left_Arm_Muzzle101"
}

--- Possible animations of the colossus, prevents a blueprint lookup
local ColossusAnimations = { 
      '/units/UAL0401/UAL0401_aactivate.sca'
    , '/units/UAL0401/UAL0401_aactivate_alt.sca'
}

--- Puddle locations of the colossus
local ColossusPuddleBones = { 
    {
          "Right_Footfall"
        , "Left_Footfall"
    },
    {
          "Right_Footfall"
        , "Left_Footfall"
    }
}

--- A helper function to create the pools of the Colossus.
-- @param unitBeingBuilt The Colossus that is being built.
-- @param bone The bone to create the pool at.
local function CreateColossusPool(unitBeingBuilt, bone, sx, sy, sz)

    -- -- Initialize various info used throughout the function

    local effect = false
    local army = unitBeingBuilt.Army
    local trash = unitBeingBuilt.Trash
    local onStopBeingBuiltTrash = unitBeingBuilt.OnBeingBuiltEffectsBag
    local orientation = EntityGetOrientation(unitBeingBuilt)

    -- -- Create pool of mercury

    local pool = EntityCreateProjectileAtBone(unitBeingBuilt, '/effects/entities/AeonBuildEffect/AeonBuildEffect01_proj.bp', bone)
    TrashBagAdd(trash, pool)
    TrashBagAdd(onStopBeingBuiltTrash, pool)

    EntitySetOrientation(pool, orientation, true)
    ProjectileSetScale(pool, sx, sy, sz)

    -- -- Create effects of pool

    effect = CreateEmitterOnEntity(pool, army, '/effects/emitters/aeon_being_built_ambient_02_emit.bp')
    EmitterSetEmitterCurveParam(effect, 'X_POSITION_CURVE', 0, sx)
    EmitterSetEmitterCurveParam(effect, 'Z_POSITION_CURVE', 0, sz)

    effect = CreateEmitterOnEntity(pool, army, '/effects/emitters/aeon_being_built_ambient_03_emit.bp')
    EmitterScaleEmitter(effect, sy)

    return pool
end

--- A helper function for the full build animation of the Colossus.
-- @param unitBeingBuilt The Colossus that is being built.
-- @param animator The animator that is applied.
-- @param puddleBones The set of bones to use for puddles.
local function CreateAeonColossusBuildingEffectsThread(unitBeingBuilt, animator, puddleBones)

    WaitTicks(2)

    -- -- Store information used throughout the function

    local sx = 1.25
    local sy = 2.25
    local sz = 1.25

    local army = unitBeingBuilt.Army
    local onDeathTrash = unitBeingBuilt.Trash
    local onFinishedTrash = unitBeingBuilt.OnBeingBuiltEffectsBag 

    -- -- Create pools of mercury

    local pools = { false, false }
    for k, v in puddleBones do 
        pools[k] = CreateColossusPool(unitBeingBuilt, v, sx, sy, sz)
    end

    -- -- Apply build effects

    for k, v in ColossusEffectBones do 
        effect = CreateEmitterAtBone(unitBeingBuilt, k, army, '/effects/emitters/aeon_being_built_ambient_02_emit.bp')
        EmitterSetEmitterCurveParam(effect, 'X_POSITION_CURVE', 0, 1)
        EmitterSetEmitterCurveParam(effect, 'Z_POSITION_CURVE', 0, 1)
        EmitterScaleEmitter(effect, 1.0)
        
        TrashBagAdd(onDeathTrash, effect)
        TrashBagAdd(onFinishedTrash, effect)
    end   

    -- -- Apply a manual animation

    local cFraction, progress = false, false
    local fraction = UnitGetFractionComplete(unitBeingBuilt)
    while fraction < 1 do

        -- only update when we make progress
        cFraction = UnitGetFractionComplete(unitBeingBuilt)
        if cFraction > fraction then 

            -- store updated value
            fraction = cFraction

            -- only adjust pool when more than 80% complete to match the shader animation
            if fraction > 0.8 then 

                progress = 5 * (fraction - 0.8)
                if progress < 0 then 
                    progress = 0 
                end
    
                scale = 1 - progress * progress

                -- progress pool
                for k, pool in pools do 
                    ProjectileSetScale(pool, sx * scale, 1.5 * sy * scale, sz * scale)
                end

                -- progress animation
                animator:SetAnimationFraction(progress * progress * progress)
            end
        end

        -- wait a tick
        WaitTicks(2)
    end
end

--- Creates the Aeon Tempest build effects, including particles and an animation.
-- @param unitBeingBuilt The Colossus that is being built.
function CreateAeonColossusBuildingEffects(unitBeingBuilt)

    local army = unitBeingBuilt.Army
    local onDeathTrash = unitBeingBuilt.Trash
    local onFinishedTrash = unitBeingBuilt.OnBeingBuiltEffectsBag 

    -- -- Apply build animation

    local animator = CreateAnimator(unitBeingBuilt, false)
    TrashBagAdd(onDeathTrash, animator)
    TrashBagAdd(onFinishedTrash, animator)

    local index = Random(1, 2)
    animator:PlayAnim(ColossusAnimations[index], false)
    animator:SetRate(0)
    animator:SetAnimationFraction(0)    

    local thread = ForkThread(CreateAeonColossusBuildingEffectsThread, unitBeingBuilt, animator, ColossusPuddleBones[index])
    TrashBagAdd(onDeathTrash, thread)
    TrashBagAdd(onFinishedTrash, thread)

end

--- Creates the Aeon CZAR build effects, including particles.
-- @param unitBeingBuilt The CZAR that is being built.
function CreateAeonCZARBuildingEffects(unitBeingBuilt)

    -- -- Initialize various info used throughout the function

    local effect = false
    local army = unitBeingBuilt.Army
    local onDeathTrash = unitBeingBuilt.Trash
    local onFinishedTrash = unitBeingBuilt.OnBeingBuiltEffectsBag
    local orientation = EntityGetOrientation(unitBeingBuilt)

    local sx = 0.6 * unitBeingBuilt.Blueprint.Physics.MeshExtentsX or unitBeingBuilt.Blueprint.Footprint.SizeX
    local sz = 0.6 * unitBeingBuilt.Blueprint.Physics.MeshExtentsZ or unitBeingBuilt.Blueprint.Footprint.SizeZ
    local sy = 1.5 * unitBeingBuilt.Blueprint.Physics.MeshExtentsY or unitBeingBuilt.Blueprint.Footprint.SizeY or (sx + sz)

    -- -- Create generic build effects

    effect = CreateEmitterOnEntity(unitBeingBuilt, army, '/effects/emitters/aeon_being_built_ambient_02_emit.bp')
    EmitterSetEmitterCurveParam(effect, 'X_POSITION_CURVE', 0, sx)
    EmitterSetEmitterCurveParam(effect, 'Z_POSITION_CURVE', 0, sz)

    TrashBagAdd(onDeathTrash, effect)
    TrashBagAdd(onFinishedTrash, effect)

    effect = CreateEmitterOnEntity(unitBeingBuilt, army, '/effects/emitters/aeon_being_built_ambient_03_emit.bp')
    EmitterScaleEmitter(effect, 0.75 * sx)

    TrashBagAdd(onDeathTrash, effect)
    TrashBagAdd(onFinishedTrash, effect)

    -- -- Create additional sparkles

    frac = false
    for k = 1, 10 do 
        frac = k / 10.0
        effect = CreateEmitterOnEntity(unitBeingBuilt, army, '/effects/emitters/aeon_being_built_ambient_02_emit.bp')
        EmitterSetEmitterCurveParam(effect, 'X_POSITION_CURVE', 0, 0.5 * frac * sx)
        EmitterSetEmitterCurveParam(effect, 'Z_POSITION_CURVE', 0, 0.5 * frac * sz)
        EmitterScaleEmitter(effect, 2.0)
        effect:OffsetEmitter(0, 2 - 2 * frac, 0)
        
        TrashBagAdd(onDeathTrash, effect)
        TrashBagAdd(onFinishedTrash, effect)
    end 
    
end

--- A helper function for the full build animation of the Tempest.
-- @param unitBeingBuilt The Tempest that is being built.
-- @param animator The animator that is applied.
local function CreateAeonTempestBuildingEffectsThread(unitBeingBuilt, animator)
    local cFraction, progress = false, false
    local fraction = UnitGetFractionComplete(unitBeingBuilt)
    while fraction < 1 do

        -- only update when we make progress
        cFraction = UnitGetFractionComplete(unitBeingBuilt)
        if cFraction > fraction then 

            -- store updated value
            fraction = cFraction
            animator:SetAnimationFraction(fraction)
        end

        -- wait a tick
        WaitTicks(2)
    end
end

--- Creates the Aeon Tempest build effects, including particles and an animation.
-- @param unitBeingBuilt The tempest that is being built.
function CreateAeonTempestBuildingEffects(unitBeingBuilt)

    -- -- Initialize various info used throughout the function

    local effect = false
    local army = unitBeingBuilt.Army
    local onDeathTrash = unitBeingBuilt.Trash
    local onFinishedTrash = unitBeingBuilt.OnBeingBuiltEffectsBag
    local orientation = EntityGetOrientation(unitBeingBuilt)

    local sx = 0.55 * unitBeingBuilt.Blueprint.Physics.MeshExtentsX or unitBeingBuilt.Blueprint.Footprint.SizeX
    local sz = 0.55 * unitBeingBuilt.Blueprint.Physics.MeshExtentsZ or unitBeingBuilt.Blueprint.Footprint.SizeZ
    local sy = 3 * unitBeingBuilt.Blueprint.Physics.MeshExtentsY or unitBeingBuilt.Blueprint.Footprint.SizeY or (sx + sz)

    -- -- Create effects of build animation

    effect = CreateEmitterOnEntity(unitBeingBuilt, army, '/effects/emitters/aeon_being_built_ambient_02_emit.bp')
    EmitterSetEmitterCurveParam(effect, 'X_POSITION_CURVE', 0, sx)
    EmitterSetEmitterCurveParam(effect, 'Z_POSITION_CURVE', 0, sz)

    TrashBagAdd(onDeathTrash, effect)
    TrashBagAdd(onFinishedTrash, effect)

    effect = CreateEmitterOnEntity(unitBeingBuilt, army, '/effects/emitters/aeon_being_built_ambient_03_emit.bp')
    EmitterScaleEmitter(effect, 0.75 * sx)

    TrashBagAdd(onDeathTrash, effect)
    TrashBagAdd(onFinishedTrash, effect)

    -- -- Create additional sparkles

    frac = false
    for k = 1, 10 do 
        frac = k / 10.0
        effect = CreateEmitterOnEntity(unitBeingBuilt, army, '/effects/emitters/aeon_being_built_ambient_02_emit.bp')
        EmitterSetEmitterCurveParam(effect, 'X_POSITION_CURVE', 0, 0.5 * frac * sx)
        EmitterSetEmitterCurveParam(effect, 'Z_POSITION_CURVE', 0, 0.5 * frac * sz)
        EmitterScaleEmitter(effect, 2.0)
        effect:OffsetEmitter(0, 2 - 2 * frac, 0)
        
        TrashBagAdd(onDeathTrash, effect)
        TrashBagAdd(onFinishedTrash, effect)
    end    

    -- -- Apply build animation

    local animator = CreateAnimator(unitBeingBuilt)
    TrashBagAdd(onDeathTrash, animator)
    TrashBagAdd(onFinishedTrash, animator)

    animator:PlayAnim('/units/uas0401/uas0401_build.sca', false)
    animator:SetRate(0)
    animator:SetAnimationFraction(1)    

    local thread = ForkThread(CreateAeonTempestBuildingEffectsThread, unitBeingBuilt, animator)
    TrashBagAdd(onDeathTrash, thread)
    TrashBagAdd(onFinishedTrash, thread)

end

--- A helper function for the full build animation of the Paragon.
-- @param unitBeingBuilt The Paragon that is being built.
local function CreateAeonParagonBuildingEffectsThread(unitBeingBuilt, sx, sy, sz)

    -- -- Initialize various info used throughout the function

    local effect = false
    local army = unitBeingBuilt.Army
    local onDeathTrash = unitBeingBuilt.Trash
    local onFinishedTrash = unitBeingBuilt.OnBeingBuiltEffectsBag

    -- -- Add various effects over time

    local k = 0.1
    local cFraction, progress = false, false
    local fraction = UnitGetFractionComplete(unitBeingBuilt)
    while fraction < 1 do

        -- only update when we make progress
        cFraction = UnitGetFractionComplete(unitBeingBuilt)
        if cFraction > fraction then 
            if k < cFraction then 
                frac = (1.1 - k) / 1
                effect = CreateEmitterOnEntity(unitBeingBuilt, army, '/effects/emitters/aeon_being_built_ambient_02_emit.bp')
                EmitterSetEmitterCurveParam(effect, 'X_POSITION_CURVE', 0, 0.5 * frac * sx)
                EmitterSetEmitterCurveParam(effect, 'Z_POSITION_CURVE', 0, 0.5 * frac * sz)
                EmitterScaleEmitter(effect, 2.0)
                effect:OffsetEmitter(0, 2 - 2 * frac, 0)
                
                TrashBagAdd(onDeathTrash, effect)
                TrashBagAdd(onFinishedTrash, effect)

                k = k + 0.08
            end

            -- store updated value
            fraction = cFraction
        end

        -- wait a tick
        WaitTicks(2)
    end
end

--- Creates the Aeon Paragon build effects, including particles and an animation.
-- @param unitBeingBuilt The tempest that is being built.
function CreateAeonParagonBuildingEffects(unitBeingBuilt)

    -- -- Initialize various info used throughout the function

    local effect = false
    local army = unitBeingBuilt.Army
    local onDeathTrash = unitBeingBuilt.Trash
    local onFinishedTrash = unitBeingBuilt.OnBeingBuiltEffectsBag
    local orientation = EntityGetOrientation(unitBeingBuilt)

    local sx = 1 * unitBeingBuilt.Blueprint.Physics.MeshExtentsX or unitBeingBuilt.Blueprint.Footprint.SizeX
    local sz = 1 * unitBeingBuilt.Blueprint.Physics.MeshExtentsZ or unitBeingBuilt.Blueprint.Footprint.SizeZ
    local sy = 2 * unitBeingBuilt.Blueprint.Physics.MeshExtentsY or unitBeingBuilt.Blueprint.Footprint.SizeY or (sx + sz)

    -- -- Create effects of build animation

    effect = CreateEmitterOnEntity(unitBeingBuilt, army, '/effects/emitters/aeon_being_built_ambient_02_emit.bp')
    EmitterSetEmitterCurveParam(effect, 'X_POSITION_CURVE', 0, sx)
    EmitterSetEmitterCurveParam(effect, 'Z_POSITION_CURVE', 0, sz)

    TrashBagAdd(onDeathTrash, effect)
    TrashBagAdd(onFinishedTrash, effect)

    effect = CreateEmitterOnEntity(unitBeingBuilt, army, '/effects/emitters/aeon_being_built_ambient_03_emit.bp')
    EmitterScaleEmitter(effect, 0.75 * sx)

    TrashBagAdd(onDeathTrash, effect)
    TrashBagAdd(onFinishedTrash, effect)

    -- -- Create additional sparkles

    local thread = ForkThread(CreateAeonParagonBuildingEffectsThread, unitBeingBuilt, sx, sy, sz)
    TrashBagAdd(onDeathTrash, thread)
    TrashBagAdd(onFinishedTrash, thread)
end