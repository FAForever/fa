

-- imports for functionality
local Entity = import('/lua/sim/Entity.lua').Entity
local EffectTemplate = import('/lua/EffectTemplates.lua')

-- globals as upvalues for performance
local WaitTicks = coroutine.yield

local CreateEmitterOnEntity = CreateEmitterOnEntity
local AttachBeamEntityToEntity = AttachBeamEntityToEntity

-- moho functions as upvalues for performance
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

local ProjectileSetScale = moho.projectile_methods.SetScale

local EmitterSetEmitterParam = moho.IEffect.SetEmitterParam
local EmitterSetEmitterCurveParam = moho.IEffect.SetEmitterCurveParam
local EmitterScaleEmitter = moho.IEffect.ScaleEmitter

local SliderSetSpeed = moho.SlideManipulator.SetSpeed
local SliderSetGoal = moho.SlideManipulator.SetGoal 
local SliderSetWorldUnits = moho.SlideManipulator.SetWorldUnits

-- math functions as upvalues for performance
local MathPi = math.pi
local MathMax = math.max
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

local function SharedBuildThread(pool, unitBeingBuilt, unitBeingBuiltTrash, unitBeingBuiltOnStopBeingBuiltTrash)

    -- # Initialize various info used throughout the function

    local sx = unitBeingBuilt.BuildExtentsX
    local sz = unitBeingBuilt.BuildExtentsZ
    local sy = unitBeingBuilt.BuildExtentsY or (sx + sz)

    -- # Determine offset for hover units

    local offset, slider = false, false
    if EntityCategoryContains(CategoriesHover, unitBeingBuilt) then 

        -- set elevation offset
        offset = unitBeingBuilt.Elevation or 0

        -- create a slider
        slider = CreateSlider(unitBeingBuilt, 0)

        SliderSetWorldUnits(slider, true)
        SliderSetGoal(slider, 0, 0, 0)
        SliderSetSpeed(slider, 100)

        TrashBagAdd(unitBeingBuiltTrash, slider)
        TrashBagAdd(unitBeingBuiltOnStopBeingBuiltTrash, slider)
    end

    -- # Shrink pool accordingly

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

    -- set correct shader of unitBeingBuilt?
    -- ooofff
    unitBeingBuilt:SetMesh(unitBeingBuilt:GetBlueprint().Display.MeshBlueprint)
end

local function ConstructPool(unitBeingBuilt, unitBeingBuiltTrash, unitBeingBuiltOnStopBeingBuiltTrash)

end

--- The build animation for Aeon buildings in general.
-- @param unitBeingBuilt The unit we're trying to build.
-- @param effectsBag The build effects bag containing the pool and emitters.
function CreateAeonBuildBaseThread(unitBeingBuilt, builder, effectsBag)

    LOG("CreateAeonBuildBaseThread")

    -- # Hold up for orientation to receive an update

    WaitTicks(2)

    -- always check after a wait
    if (not unitBeingBuilt) or unitBeingBuilt.Dead then 
        return 
    end

    -- # Initialize various info used throughout the function

    local effect = false
    local army = unitBeingBuilt.Army
    local orientation = EntityGetOrientation(unitBeingBuilt)
    local unitBeingBuiltTrash = unitBeingBuilt.Trash
    local unitOnStopBeingBuiltTrash = unitBeingBuilt.OnBeingBuiltEffectsBag
    local sx = unitBeingBuilt.BuildExtentsX
    local sz = unitBeingBuilt.BuildExtentsZ
    local sy = unitBeingBuilt.BuildExtentsY or (sx + sz)

    -- # Create pool of mercury

    local pool = EntityCreateProjectile(unitBeingBuilt, '/effects/entities/AeonBuildEffect/AeonBuildEffect01_proj.bp', nil, 0, 0, nil, nil, nil)
    TrashBagAdd(unitBeingBuiltTrash, pool)
    TrashBagAdd(unitOnStopBeingBuiltTrash, pool)

    EntitySetOrientation(pool, orientation, true)
    ProjectileSetScale(pool, sx, sy * 1.5, sz)

    -- # Create effects

    effect = CreateEmitterOnEntity(pool, army, '/effects/emitters/aeon_being_built_ambient_01_emit.bp')
    EmitterSetEmitterCurveParam(effect, 'X_POSITION_CURVE', 0, sx * 1.5)
    EmitterSetEmitterCurveParam(effect, 'Z_POSITION_CURVE', 0, sz * 1.5)

    effect = CreateEmitterOnEntity(pool, army, '/effects/emitters/aeon_being_built_ambient_03_emit.bp')
    EmitterScaleEmitter(effect, (sx + sz) * 0.3)

    -- # Create a thread to scale the pool

    local thread = ForkThread(SharedBuildThread, pool, unitBeingBuilt, unitBeingBuiltTrash, unitOnStopBeingBuiltTrash)
    TrashBagAdd(unitBeingBuiltTrash, thread)
    TrashBagAdd(unitOnStopBeingBuiltTrash, thread)
end

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

--- The build animation for Aeon factories, including the pool and dummy unit.
-- @param builder The factory that is building the unit.
-- @param unitBeingBuilt The unit we're trying to build.
-- @param buildEffectBones The arms of the factory where the build beams come from.
-- @param buildBone The location where the unit is beint built.
-- @param effectsBag The build effects bag.
function CreateAeonFactoryBuildingEffects(builder, unitBeingBuilt, buildEffectBones, buildBone, effectsBag)

    LOG("CreateAeonFactoryBuildingEffects")

    -- # Hold up for orientation to receive an update

    WaitTicks(2)

    -- always check after a wait
    if (not unitBeingBuilt) or unitBeingBuilt.Dead then 
        return 
    end

    -- # Create build beams for factory
    
    local army = unitBeingBuilt.Army
    for _, vBone in buildEffectBones do
        TrashBagAdd(effectsBag, CreateAttachedEmitter(builder, vBone, army, '/effects/emitters/aeon_build_03_emit.bp'))
        for _, vBeam in AeonBuildBeams02 do
            TrashBagAdd(effectsBag, AttachBeamEntityToEntity(builder, vBone, builder, buildBone, army, vBeam))
        end
    end

    -- # Create persistent state between calls

    local initialised = unitBeingBuilt.ConstructionInitialised
    if not initialised then 
        unitBeingBuilt.ConstructionInitialised = true

        -- # Initialize various info used throughout the function

        local effect = false
        local unitBeingBuiltTrash = unitBeingBuilt.Trash
        local unitOnStopBeingBuiltTrash = unitBeingBuilt.OnBeingBuiltEffectsBag
        local orientation = EntityGetOrientation(unitBeingBuilt)
        local sx = unitBeingBuilt.BuildExtentsX
        local sz = unitBeingBuilt.BuildExtentsZ
        local sy = unitBeingBuilt.BuildExtentsY or (sx + sz)

        -- # Create pool of mercury

        local pool = EntityCreateProjectile(unitBeingBuilt, '/effects/entities/AeonBuildEffect/AeonBuildEffect01_proj.bp', 0, 0, 0, nil, nil, nil)
        TrashBagAdd(unitBeingBuiltTrash, pool)
        TrashBagAdd(unitOnStopBeingBuiltTrash, pool)

        EntitySetOrientation(pool, orientation, true)
        ProjectileSetScale(pool, sx, sy * 1.5, sz)

        -- # Create effects of pool

        effect = CreateEmitterOnEntity(pool, army, '/effects/emitters/aeon_being_built_ambient_02_emit.bp')
        EmitterSetEmitterCurveParam(effect, 'X_POSITION_CURVE', 0, sx * 1.5)
        EmitterSetEmitterCurveParam(effect, 'Z_POSITION_CURVE', 0, sz * 1.5)

        effect = CreateEmitterOnEntity(pool, army, '/effects/emitters/aeon_being_built_ambient_03_emit.bp')
        EmitterScaleEmitter(effect, (sx + sz) * 0.3)

        -- # Create a thread to scale the pool and move the unit accordingly

        local thread = ForkThread(SharedBuildThread, pool, unitBeingBuilt, unitBeingBuiltTrash, unitOnStopBeingBuiltTrash)
        TrashBagAdd(unitBeingBuiltTrash, thread)
        TrashBagAdd(unitOnStopBeingBuiltTrash, thread)
    end
end