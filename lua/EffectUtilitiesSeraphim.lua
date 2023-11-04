-- imports for functionality
local EffectTemplate = import("/lua/effecttemplates.lua")

-- globals as upvalues for performance
local AttachBeamEntityToEntity = AttachBeamEntityToEntity
local CreateSlider = CreateSlider
local WaitTicks = WaitTicks

local MathMax = math.max
local MathMin = math.min
local TableGetn = table.getn

local IEffectScaleEmitter = moho.IEffect.ScaleEmitter
local IEffectSetEmitterParam = moho.IEffect.SetEmitterParam
local SliderSetGoal = moho.SlideManipulator.SetGoal
local SliderSetSpeed = moho.SlideManipulator.SetSpeed
local SliderSetWorldUnits = moho.SlideManipulator.SetWorldUnits
local TrashBagAdd = TrashBag.Add
local UnitGetFractionComplete = moho.unit_methods.GetFractionComplete

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
---@param builder Unit The factory that is building the unit
---@param unitBeingBuilt Unit The unit that is being built by the factory
---@param effectBones string[] The bones of the factory to spawn effects for
---@param effectsBag TrashBag The trashbag for effects
function CreateSeraphimUnitEngineerBuildingEffects(builder, unitBeingBuilt, effectBones, effectsBag)
    -- do not create beams if things turn out to be destroyed
    if builder.Dead or unitBeingBuilt.Dead then
        return
    end

    local army = builder.Army
    for _, bone in effectBones do
        TrashBagAdd(effectsBag, CreateAttachedEmitter(builder, bone, army, '/effects/emitters/seraphim_build_01_emit.bp'))
        for _, effect in SeraphimBuildBeams01 do
            TrashBagAdd(effectsBag, AttachBeamEntityToEntity(builder, bone, unitBeingBuilt, -1, army, effect))
        end
    end
end

--- Creates the seraphim factory building effects.
---@param builder Unit The factory that is building the unit
---@param unitBeingBuilt Unit The unit that is being built by the factory
---@param effectBones string[] The bones of the factory to spawn effects for
---@param locationBone string The main build bone where the unit spawns on top of (unused)
---@param effectsBag TrashBag The trashbag for effects
function CreateSeraphimFactoryBuildingEffects(builder, unitBeingBuilt, effectBones, locationBone, effectsBag)
    -- -- initialize various info used throughout the function
    local army = builder.Army
    local bp = unitBeingBuilt.Blueprint
    local Physics = bp.Physics
    local Footprint = bp.Footprint
    local sx = Physics.MeshExtentsX or Footprint.SizeX or 1
    local sz = Physics.MeshExtentsZ or Footprint.SizeZ or 1
    local sy = Physics.MeshExtentsY or Footprint.SizeYX or MathMin(sx, sz)

    -- do not apply offsets for subs and air units
    local offset = 0
    if unitBeingBuilt.Blueprint.CategoriesHash["HOVER"] then
        offset = bp.Elevation or 0
    end

    -- -- Create effects for each build bone
    local CreateAttachedEmitter = CreateAttachedEmitter
    for _, bone in effectBones do
        TrashBagAdd(effectsBag, CreateAttachedEmitter(builder, bone, army, '/effects/emitters/seraphim_build_01_emit.bp'))
        for _, effect in SeraphimBuildBeams01 do
            TrashBagAdd(effectsBag, AttachBeamEntityToEntity(builder, bone, unitBeingBuilt, -1, army, effect))
        end
    end

    -- -- Check if unit has been initialised
    local slider = unitBeingBuilt.ConstructionSlider

    if not unitBeingBuilt.ConstructionInitialised then
        unitBeingBuilt.ConstructionInitialised = true

        -- -- Add seraphim pool effect
        local unitBeingBuiltTrash = unitBeingBuilt.Trash
        local unitOnStopBeingBuiltTrash = unitBeingBuilt.OnBeingBuiltEffectsBag

        for _, effect in BuildEffectsEmitters do
            local emitter = CreateAttachedEmitter(unitBeingBuilt, -1, army, effect)
            TrashBagAdd(unitBeingBuiltTrash, emitter)
            TrashBagAdd(unitOnStopBeingBuiltTrash, emitter)
        end

        -- -- Create slider to move unit
        slider = CreateSlider(unitBeingBuilt, 0)
        unitBeingBuilt.ConstructionSlider = slider

        SliderSetWorldUnits(slider,true)
        SliderSetGoal(slider, 0, sy + offset, 0)
        SliderSetSpeed(slider, 100)

        TrashBagAdd(unitBeingBuiltTrash, slider)
        TrashBagAdd(unitOnStopBeingBuiltTrash, slider)

        WaitFor(slider)
    end

    -- localize for optimal access
    local UnitGetFractionComplete = UnitGetFractionComplete
    local completed = UnitGetFractionComplete(unitBeingBuilt)
    -- -- Gradually move the unit to the plateau
    while not unitBeingBuilt.Dead and completed < 1.0 do
        SliderSetGoal(slider, 0, (1 - completed) * sy + offset, 0)
        SliderSetSpeed(slider, completed * completed * completed)
        completed = UnitGetFractionComplete(unitBeingBuilt)
        WaitTicks(2)
    end

    -- -- Nillify temporary tables
    unitBeingBuilt.ConstructionSlider = nil
    unitBeingBuilt.ConstructionInitialised = nil
end

--- Creates the seraphim build cube effect.
---@param unitBeingBuilt Unit The unit that is being built by the factory
---@param builder Unit The factory that is building the unit
---@param effectsBag TrashBag The trashbag for effects
---@param scaleFactor number A scale factor for the effects
function CreateSeraphimBuildThread(unitBeingBuilt, builder, effectsBag, scaleFactor)
    -- -- initialize various info used throughout the function
    local army = builder.Army

    -- optimize local access
    local IEffectScaleEmitter = IEffectScaleEmitter
    local UnitGetFractionComplete = UnitGetFractionComplete

    -- matches with number of effects being made, pre-allocates the table
    local emitters = { false, false, false, false, false }
    local emittersHead = 1

    -- determine a sane LOD cutoff for the size of the unit
    local bp = unitBeingBuilt.Blueprint
    local lods = bp.Display.Mesh.LODs
    local count = TableGetn(lods)

    local sx = bp.Physics.MeshExtentsX or bp.Footprint.SizeX
    local sz = bp.Physics.MeshExtentsZ or bp.Footprint.SizeZ
    local LODCutoff = 0.9 * lods[count].LODCutoff or (90 * MathMax(sx, sz))

    -- smaller inner, dark-purple effect
    for _, effect in BuildEffectsEmitters do
        local emitter = CreateAttachedEmitter(unitBeingBuilt, -1, army, effect)
        IEffectScaleEmitter(emitter, scaleFactor)
        IEffectSetEmitterParam(emitter, "LODCUTOFF", lods[1].LODCutoff)

        TrashBagAdd(effectsBag, emitter)
        emitters[emittersHead] = emitter
        emittersHead = emittersHead + 1
    end

    -- large outer radius effect
    for _, effect in BuildEffectBaseEmitters do
        local emitter = CreateAttachedEmitter(unitBeingBuilt, -1, army, effect)
        IEffectScaleEmitter(emitter,scaleFactor)
        IEffectSetEmitterParam(emitter, "LODCUTOFF", LODCutoff)

        TrashBagAdd(effectsBag, emitter)
        emitters[emittersHead] = emitter
        emittersHead = emittersHead + 1
    end

    -- -- Scale effects until the unit is finished

    -- only naval factories are not square, use the Z axis to get largest axis
    local unitScaleMetric = 0.75 * sz
    local scaledUnitMetric = unitScaleMetric * scaleFactor
    local complete = UnitGetFractionComplete(unitBeingBuilt)
    while not unitBeingBuilt.Dead and complete < 1.0 do
        local emitterScale = 1 + scaledUnitMetric * complete
        for k = 1, emittersHead - 1 do
            IEffectScaleEmitter(emitters[k], emitterScale)
        end

        complete = UnitGetFractionComplete(unitBeingBuilt)
        WaitTicks(4)
    end

    -- -- Poof - we're finished and clean up
    CreateLightParticleIntel(unitBeingBuilt, -1, army, unitScaleMetric * 3.5, 8, 'glow_02', 'ramp_blue_22')
end

--- Creates the seraphim build cube effect.
---@param unitBeingBuilt Unit the unit that is being built by the factory
---@param builder Unit The factory that is building the unit
---@param effectsBag TrashBag The trashbag for effects
function CreateSeraphimBuildBaseThread(unitBeingBuilt, builder, effectsBag)
    CreateSeraphimBuildThread(unitBeingBuilt, builder, effectsBag, 1)
end

--- Creates the seraphim build cube effect.
---@param unitBeingBuilt Unit the unit that is being built by the factory
---@param builder Unit The factory that is building the unit
---@param effectsBag TrashBag The trashbag for effects
---@param scale? number
function CreateSeraphimExperimentalBuildBaseThread(unitBeingBuilt, builder, effectsBag, scale)
    CreateSeraphimBuildThread(unitBeingBuilt, builder, effectsBag, scale or 1)
end