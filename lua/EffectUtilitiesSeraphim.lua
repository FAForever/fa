
-- imports for functionality
local EffectTemplate = import('/lua/EffectTemplates.lua')

-- globals as upvalues for performance
local Warp = Warp
local WaitTicks = coroutine.yield

local CreateSlider = CreateSlider
local CreateEmitterOnEntity = CreateEmitterOnEntity
local AttachBeamEntityToEntity = AttachBeamEntityToEntity

-- moho functions as upvalues for performance
local EntityGetPosition = moho.entity_methods.GetPosition
local EntityBeenDestroyed = moho.entity_methods.BeenDestroyed
local EntityGetPositionXYZ = moho.entity_methods.GetPositionXYZ
local EntityGetOrientation = moho.entity_methods.GetOrientation

local UnitRevertElevation = moho.unit_methods.RevertElevation
local UnitGetFractionComplete = moho.unit_methods.GetFractionComplete
local UnitCreateProjectile = moho.unit_methods.CreateProjectile

local SliderSetSpeed = moho.SlideManipulator.SetSpeed
local SliderSetGoal = moho.SlideManipulator.SetGoal 
local SliderSetWorldUnits = moho.SlideManipulator.SetWorldUnits

-- upvalued trashbag functions for performance
local TrashBag = _G.TrashBag
local TrashBagAdd = TrashBag.Add

-- cached effects
local SeraphimBuildBeams01 = EffectTemplate.SeraphimBuildBeams01

local BuildEffectBaseEmitters = {
    '/effects/emitters/seraphim_being_built_ambient_01_emit.bp',
}

local BuildEffectsEmitters = {
    '/effects/emitters/seraphim_being_built_ambient_02_emit.bp',
    '/effects/emitters/seraphim_being_built_ambient_03_emit.bp',
    '/effects/emitters/seraphim_being_built_ambient_04_emit.bp',
    '/effects/emitters/seraphim_being_built_ambient_05_emit.bp',
}

--- Creates the seraphim factory building beam effects.
-- @param builder The factory that is building the unit.
-- @param unitBeingBuilt the unit that is being built by the factory.
-- @param effectBones The bones of the factory to spawn effects for.
-- @param effectsBag The trashbag for effects.
function CreateSeraphimUnitEngineerBuildingEffects(builder, unitBeingBuilt, effectBones, effectsBag)
    local army = builder.Army
    for _, vBone in effectBones do
        TrashBagAdd(effectsBag, CreateAttachedEmitter(builder, vBone, army, '/effects/emitters/seraphim_build_01_emit.bp'))
        for _, v in SeraphimBuildBeams01 do
            TrashBagAdd(effectsBag, AttachBeamEntityToEntity(builder, vBone, unitBeingBuilt, -1, army, v))
        end
    end
end

--- Creates the seraphim factory building effects.
-- @param builder The factory that is building the unit.
-- @param unitBeingBuilt the unit that is being built by the factory.
-- @param effectBones The bones of the factory to spawn effects for.
-- @param locationBone The main build bone where the unit spawns on top of.
-- @param effectsBag The trashbag for effects.
function CreateSeraphimFactoryBuildingEffects(builder, unitBeingBuilt, effectBones, locationBone, effectsBag)

    -- # initialize various info used throughout the function

    local completed = UnitGetFractionComplete(unitBeingBuilt)
    local x, y, z = EntityGetPositionXYZ(builder, locationBone)

    local sx = unitBeingBuilt.BuildExtentsX
    local sz = unitBeingBuilt.BuildExtentsZ
    local sy = unitBeingBuilt.BuildExtentsY or (sx + sz)
    sy = (1 - completed) * sy

    local effect = false
    local army = builder.Army

    -- # Create effects for each build bone

    local CreateAttachedEmitter = CreateAttachedEmitter
    for _, vBone in effectBones do
        TrashBagAdd(effectsBag, CreateAttachedEmitter(builder, vBone, army, '/effects/emitters/seraphim_build_01_emit.bp'))
        for _, vBeam in SeraphimBuildBeams01 do
            TrashBagAdd(effectsBag, AttachBeamEntityToEntity(builder, vBone, unitBeingBuilt, -1, army, vBeam))
        end
    end

    -- # Check if unit has been initialised

    local slider = unitBeingBuilt.ConstructionSlider
    local initialised = unitBeingBuilt.ConstructionInitialised

    if not initialised then 

        unitBeingBuilt.ConstructionInitialised = true

        -- # Add seraphim pool effect

        local unitBeingBuiltTrash = unitBeingBuilt.Trash
        local unitOnStopBeingBuiltTrash = unitBeingBuilt.OnBeingBuiltEffectsBag

        for k, bp in BuildEffectsEmitters do 
            effect = CreateAttachedEmitter(unitBeingBuilt, -1, army, bp)
            TrashBagAdd(unitBeingBuiltTrash, effect)
            TrashBagAdd(unitOnStopBeingBuiltTrash, effect)
        end

        -- # Create slider to move unit

        slider = CreateSlider(unitBeingBuilt, 0)
        unitBeingBuilt.ConstructionSlider = slider

        SliderSetWorldUnits(slider,true)
        SliderSetGoal(slider, 0, sy, 0)
        SliderSetSpeed(slider, 10)

        TrashBagAdd(unitBeingBuiltTrash, slider)
        TrashBagAdd(unitOnStopBeingBuiltTrash, slider)

        WaitFor(slider)
    end

    -- # Gradually move the unit to the plateau

    while not unitBeingBuilt.Dead do
        completed = UnitGetFractionComplete(unitBeingBuilt)
        SliderSetGoal(slider, 0, (1 - completed) * sy, 0)
        SliderSetSpeed(slider, completed * completed * completed)
        WaitTicks(2)
    end
end

--- Creates the seraphim build cube effect.
-- @param unitBeingBuilt the unit that is being built by the factory.
-- @param builder The factory that is building the unit.
-- @param effectsBag The trashbag for effects.
-- @param scaleFactor A scale factor for the effects.
function CreateSeraphimBuildThread(unitBeingBuilt, builder, effectsBag, scaleFactor)

    -- # initialize various info used throughout the function

    local effect = false
    local army = builder.Army

    -- # Create generic effects

    local effect = false

    -- matches with number of effects being made, pre-allocates the table
    local emitters = { false, false, false, false, false }
    local emittersHead = 1

    for _, vEffect in BuildEffectsEmitters do
        effect = CreateAttachedEmitter(unitBeingBuilt, -1, builder.Army, vEffect)
        effect:ScaleEmitter(scaleFactor)

        TrashBagAdd(effectsBag, effect)
        emitters[emittersHead] = effect
        emittersHead = emittersHead + 1
    end

    for _, vEffect in BuildEffectBaseEmitters do
        effect = CreateAttachedEmitter(unitBeingBuilt, -1, builder.Army, vEffect)
        effect:ScaleEmitter(scaleFactor)

        TrashBagAdd(effectsBag, effect)
        emitters[emittersHead] = effect
        emittersHead = emittersHead + 1
    end

    -- # Scale effects until the unit is finished

    -- only naval factories are not square, use the Z axis to get largest axis
    local unitScaleMetric = unitBeingBuilt.BuildExtentsZ * 0.75
    local complete = UnitGetFractionComplete(unitBeingBuilt)
    while not unitBeingBuilt.Dead and complete < 1.0 do

        for k = 1, emittersHead - 1 do
            emitters[k]:ScaleEmitter(scaleFactor + (unitScaleMetric * complete))
        end

        complete = UnitGetFractionComplete(unitBeingBuilt)
        WaitTicks(2)
    end

    -- # Poof - we're finished and clean up

    CreateLightParticleIntel(unitBeingBuilt, -1, army, unitScaleMetric * 3.5, 8, 'glow_02', 'ramp_blue_22')

end

--- Creates the seraphim build cube effect.
-- @param unitBeingBuilt the unit that is being built by the factory.
-- @param builder The factory that is building the unit.
-- @param effectsBag The trashbag for effects.
function CreateSeraphimBuildBaseThread(unitBeingBuilt, builder, effectsBag)
    CreateSeraphimBuildThread(unitBeingBuilt, builder, effectsBag, 1)
end

--- Creates the seraphim build cube effect.
-- @param unitBeingBuilt the unit that is being built by the factory.
-- @param builder The factory that is building the unit.
-- @param effectsBag The trashbag for effects.
function CreateSeraphimExperimentalBuildBaseThread(unitBeingBuilt, builder, effectsBag)
    CreateSeraphimBuildThread(unitBeingBuilt, builder, effectsBag, 2)
end