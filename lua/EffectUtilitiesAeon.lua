

-- imports for functionality
local Entity = import('/lua/sim/Entity.lua').Entity
local EffectTemplate = import('/lua/EffectTemplates.lua')

-- upvalued cached vector. Prevents various table allocations
-- throughout the code. Use carefully: the state of the vector
-- is different after a wait because another function can have
-- used it in between.
local VectorCached = Vector(0, 0, 0)

-- globals as upvalues for performance
local Warp = Warp
local Vector = Vector
local Random = Random
local ArmyBrains = ArmyBrains
local CreateUnit = CreateUnit
local KillThread = KillThread 
local setmetatable = setmetatable
local WaitTicks = coroutine.yield

local CreateEmitterOnEntity = CreateEmitterOnEntity
local AttachBeamEntityToEntity = AttachBeamEntityToEntity

local IssueClearCommands = IssueClearCommands
local IssueGuard = IssueGuard

-- moho functions as upvalues for performance
local EntityDestroy = moho.entity_methods.Destroy
local EntitySetMesh = moho.entity_methods.SetMesh 
local EntitySetScale = moho.entity_methods.SetScale
local EntityGetPosition = moho.entity_methods.GetPosition
local EntityGetBlueprint = moho.entity_methods.GetBlueprint
local EntityBeenDestroyed = moho.entity_methods.BeenDestroyed
local EntityGetPositionXYZ = moho.entity_methods.GetPositionXYZ
local EntityGetOrientation = moho.entity_methods.GetOrientation
local EntitySetOrientation = moho.entity_methods.SetOrientation
local EntityCreateProjectile = moho.entity_methods.CreateProjectile
local EntitySetVizToAllies = moho.entity_methods.SetVizToAllies
local EntitySetVizToEnemies = moho.entity_methods.SetVizToEnemies
local EntitySetVizToNeutrals = moho.entity_methods.SetVizToNeutrals

local UnitRevertElevation = moho.unit_methods.RevertElevation
local UnitGetFractionComplete = moho.unit_methods.GetFractionComplete
local UnitShowBone = moho.unit_methods.ShowBone
local UnitHideBone = moho.unit_methods.HideBone

local ProjectileSetScale = moho.projectile_methods.SetScale

local EmitterSetEmitterParam = moho.IEffect.SetEmitterParam
local EmitterSetEmitterCurveParam = moho.IEffect.SetEmitterCurveParam
local EmitterScaleEmitter = moho.IEffect.ScaleEmitter

-- math functions as upvalues for performance
local MathPi = math.pi
local MathSin = math.sin 
local MathCos = math.cos
local MathPow = math.pow

-- upvalued trashbag functions for performance
local TrashBag = _G.TrashBag
local TrashBagAdd = TrashBag.Add

local CategoriesHover = categories.HOVER

-- cache as upvalue to prevent table operation
local AeonBuildBeams01 = EffectTemplate.AeonBuildBeams01
local AeonBuildBeams02 = EffectTemplate.AeonBuildBeams02

--- The build animation for Aeon buildings in general.
-- @param unitBeingBuilt The unit we're trying to build.
-- @param effectsBag The build effects bag containing the pool and emitters.
function CreateAeonBuildBaseThread(unitBeingBuilt, effectsBag)

    -- reset the mesh of the unit and hide it immediately
    local blueprint = EntityGetBlueprint(unitBeingBuilt)

    -- wait one tick (= 2) to get the right orientation.
    WaitTicks(2)

    -- always check after a wai
    if unitBeingBuilt.Dead then 
        return 
    end

    -- retrieve and cache data right off the bat
    local emit = false
    local o = EntityGetPosition(unitBeingBuilt)
    local ox, oy, oz = o[1], o[2], o[3]

    local army = unitBeingBuilt.Army
    local orientation = EntityGetOrientation(unitBeingBuilt)
    local physics = blueprint.Physics
    local footprint = blueprint.Footprint
    local sx = physics.MeshExtentsX or footprint.SizeX * 0.5
    local sz = physics.MeshExtentsZ or footprint.SizeZ * 0.5
    local sy = physics.MeshExtentsY or sx + sz

    -- FEATURE OF THE YEAR:
    -- for larger units, when reclaiming hide random bones on X percentages

    -- create a pool mercury that slow draws into the build unit
    local pool = EntityCreateProjectile(unitBeingBuilt, '/effects/entities/AeonBuildEffect/AeonBuildEffect01_proj.bp', nil, 0, 0, nil, nil, nil)
    TrashBagAdd(effectsBag, pool)

    EntitySetOrientation(pool, orientation, true)
    ProjectileSetScale(pool, sx, sy * 1.5, sz)
    Warp(pool, o)

    -- create effects for the build animation
    emit = CreateEmitterOnEntity(pool, army, '/effects/emitters/aeon_being_built_ambient_01_emit.bp')
    EmitterSetEmitterCurveParam(emit, 'X_POSITION_CURVE', 0, sx * 1.5)
    EmitterSetEmitterCurveParam(emit, 'Z_POSITION_CURVE', 0, sz * 1.5)

    emit = CreateEmitterOnEntity(pool, army, '/effects/emitters/aeon_being_built_ambient_03_emit.bp')
    EmitterScaleEmitter(emit, (sx + sz) * 0.3)

    -- move the dummy unit around
    local vc = VectorCached
    local fraction = UnitGetFractionComplete(unitBeingBuilt)
    while not unitBeingBuilt.Dead and fraction < 1 do
        -- get current fraction and see if we progressed
        local frac = UnitGetFractionComplete(unitBeingBuilt)
        if frac > fraction then 

            -- store updated value
            fraction = frac

            -- adjust scale of pool
            scale = 1.2 - fraction * fraction * fraction * fraction * fraction
            ProjectileSetScale(pool, 0.9 * sx * scale, 1.5 * sy * scale, 0.9 * sz * scale)
        end

        -- wait a tick
        WaitTicks(2)
    end
end

--- The build animation of an engineer.
-- @param builder The engineer in question.
-- @param unitBeingBuilt The unit we're building.
-- @param buildEffectsBag The trash bag for the build effects.
function CreateAeonConstructionUnitBuildingEffects(builder, unitBeingBuilt, buildEffectsBag)
    local army = builder.Army
    -- create effect on builder
    local effect = CreateEmitterOnEntity(builder, army, '/effects/emitters/aeon_build_01_emit.bp') 
    TrashBagAdd(buildEffectsBag, effect)

    -- create beam between builder and unit being built
    for _, v in AeonBuildBeams01 do
        -- create the beam and adjust it
        effect = AttachBeamEntityToEntity(builder, -1, unitBeingBuilt, -1, army, v)
        -- EmitterSetEmitterParam(effect, 'POSITION_Z', 0.45)
        TrashBagAdd(buildEffectsBag, effect)
    end
end

--- The build animation of the commander.
-- @param builder The commander in question.
-- @param unitBeingBuilt The unit we're building.
-- @param buildEffectBones The bone(s) of the commander where the effect starts.
-- @param buildEffectsBag The trash bag for the build effects.
function CreateAeonCommanderBuildingEffects(builder, unitBeingBuilt, buildEffectBones, buildEffectsBag)
    local effect = false 
    local army = builder.Army
    for _, vBone in buildEffectBones do
        -- create effect on builder bones
        effect = CreateAttachedEmitter(builder, vBone, army, '/effects/emitters/aeon_build_02_emit.bp')
        TrashBagAdd(buildEffectsBag, effect)

        for _, v in AeonBuildBeams01 do
            -- create the beam from builder bone to unit
            effect = AttachBeamEntityToEntity(builder, vBone, unitBeingBuilt, -1, army, v)
            TrashBagAdd(buildEffectsBag, effect)
        end
    end
end

--- The build animation for Aeon factories, including the pool and dummy unit.
-- @param builder The factory that is building the unit.
-- @param unitBeingBuilt The unit we're trying to build.
-- @param buildEffectBones The arms of the factory where the build beams come from.
-- @param buildBone The location where the unit is beint built.
-- @param effectsBag The build effects bag.
function CreateAeonFactoryBuildingEffects(builder, unitBeingBuilt, buildEffectBones, buildBone, effectsBag)

    -- reset the mesh of the unit and hide it immediately
    local blueprint = EntityGetBlueprint(unitBeingBuilt)
    local display = blueprint.Display
    unitBeingBuilt.SetMesh(unitBeingBuilt, display.MeshBlueprint, true)
    UnitHideBone(unitBeingBuilt, 0, true)

    -- wait one tick (= 2) to get the right orientation.
    WaitTicks(2)

    -- retrieve and cache data right off the bat
    local o = EntityGetPosition(builder, buildBone)
    local ox, oy, oz = o[1], o[2], o[3]

    local vc = VectorCached
    local army = unitBeingBuilt.Army
    local paused = builder.IsPaused(builder)
    local orientation = EntityGetOrientation(unitBeingBuilt)

    local physics = blueprint.Physics
    local footprint = blueprint.Footprint
    local sx = physics.MeshExtentsX or footprint.SizeX * 0.5
    local sz = 1.5 * (physics.MeshExtentsZ or footprint.SizeZ * 0.5)
    local sy = physics.MeshExtentsY or sx + sz

    -- create dummy entity for the build animation and 
    -- store it with the factory for re-use
    local entity = Entity()
    TrashBagAdd(effectsBag, entity)

    -- warp it to the correct position and set the mesh
    vc[1] = ox
    vc[2] = oy - (2 * sy)
    vc[3] = oz 
    Warp(entity, vc)
    EntitySetOrientation(entity, orientation, true)
    EntitySetScale(entity, display.UniformScale)
    EntitySetMesh(entity, display.BuildMeshBlueprint, true)

    -- make sure enemies don't get to see them
    EntitySetVizToEnemies(entity, 'Intel')
    EntitySetVizToAllies(entity, 'Intel')
    EntitySetVizToNeutrals(entity, 'Intel')

    -- Create a pool mercury that slow draws into the build unit
    local pool = EntityCreateProjectile(unitBeingBuilt, '/effects/entities/AeonBuildEffect/AeonBuildEffect01_proj.bp', 0, 0, 1, nil, nil, nil)
    TrashBagAdd(effectsBag, pool)

    -- position the pool mercury
    vc[1] = ox
    vc[2] = oy - 0.05
    vc[3] = oz 
    EntitySetOrientation(pool, orientation, true)
    Warp(pool, vc)

    -- add effects depending on state
    if paused then
        local fraction = UnitGetFractionComplete(unitBeingBuilt)
        local scale = 1 - MathPow(fraction, 2)
        ProjectileSetScale(pool, sx * scale, 1.5 * sy * scale, sz * scale)
    else
        ProjectileSetScale(pool, sx, 1.5 * sy, sz)
    end

    -- add factory build effects
    if not paused then

        -- create ambient effects like light smoke / particles
        local effect = CreateEmitterOnEntity(pool, army, '/effects/emitters/aeon_being_built_ambient_02_emit.bp')
        EmitterSetEmitterCurveParam(effect, 'X_POSITION_CURVE', 0, sx * 1.5)
        EmitterSetEmitterCurveParam(effect, 'Z_POSITION_CURVE', 0, sz * 1.5)

        effect = CreateEmitterOnEntity(pool, army, '/effects/emitters/aeon_being_built_ambient_03_emit.bp')
        EmitterScaleEmitter(effect, (sx + sz) * 0.3)

        -- create build beam effects
        for _, vBone in buildEffectBones do
            effect = CreateAttachedEmitter(builder, vBone, army, '/effects/emitters/aeon_build_03_emit.bp')
            TrashBagAdd(effectsBag, effect)
            for _, vBeam in AeonBuildBeams02 do
                effect = AttachBeamEntityToEntity(builder, vBone, builder, buildBone, army, vBeam)
                TrashBagAdd(effectsBag, effect)
            end
        end
    end

    -- do progression checks
    if not paused then

        -- find offset for hover units so that they do not suddenly jump when finished
        local offset = 0
        if EntityCategoryContains(categories.HOVER, unitBeingBuilt) then
            offset = physics.Elevation 
        end

        local vc = VectorCached
        local fraction = UnitGetFractionComplete(unitBeingBuilt)
        while not unitBeingBuilt.Dead and not EntityBeenDestroyed(pool) and fraction < 1 do
            -- get current fraction and see if we made progress
            local frac = UnitGetFractionComplete(unitBeingBuilt)
            if frac > fraction then 

                -- store updated value
                fraction = frac

                -- adjust scale of pool
                scale = 1 - MathPow(fraction, 2)
                ProjectileSetScale(pool, sx * scale, 1.5 * sy * scale, sz * scale)

                -- adjust height of dummy unit
                vc[1] = ox
                vc[2] = (oy + offset) - (1 - fraction) * (sy + offset)
                vc[3] = oz
                Warp(entity, vc)
            end

            -- wait a tick
            WaitTicks(2)
        end

        -- show the actual unit
        UnitShowBone(unitBeingBuilt, 0, true)
    end
end