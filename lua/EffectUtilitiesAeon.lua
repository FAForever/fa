-- imports for functionality
local AeonBuildBeams01 = import("/lua/effecttemplates.lua").AeonBuildBeams01
local AeonBuildBeams02 = import("/lua/effecttemplates.lua").AeonBuildBeams02

local AttachBeamEntityToEntity = AttachBeamEntityToEntity
local CreateAttachedEmitter = CreateAttachedEmitter
local CreateEmitterOnEntity = CreateEmitterOnEntity
local WaitTicks = WaitTicks

local MathMin = math.min

local EntityCreateProjectile = moho.entity_methods.CreateProjectile
local EntityCreateProjectileAtBone = moho.entity_methods.CreateProjectileAtBone
local EntityGetOrientation = moho.entity_methods.GetOrientation
local EntitySetOrientation = moho.entity_methods.SetOrientation
local IEffectScaleEmitter = moho.IEffect.ScaleEmitter
local IEffectSetEmitterCurveParam = moho.IEffect.SetEmitterCurveParam
local IEffectOffsetEmitter = moho.IEffect.OffsetEmitter
local ProjectileSetScale = moho.projectile_methods.SetScale
local SliderSetGoal = moho.SlideManipulator.SetGoal
local SliderSetSpeed = moho.SlideManipulator.SetSpeed
local SliderSetWorldUnits = moho.SlideManipulator.SetWorldUnits
local UnitGetFractionComplete = moho.unit_methods.GetFractionComplete
local TrashBagAdd = TrashBag.Add


--- Creates an Aeon mercury pool build effect
---@param unitBeingBuilt Unit Unit to attach mercury pool to
---@param army integer Army of the pool
---@param sx number Size x of the pool
---@param sy number Size y of the pool
---@param sz number Size z of the pool
---@param scale number Scale of secondary build effect
---@return Entity pool
function CreateMercuryPool(unitBeingBuilt, army, sx, sy, sz, scale)
    local onDeathTrash = unitBeingBuilt.Trash
    local onFinishedTrash = unitBeingBuilt.OnBeingBuiltEffectsBag

    -- Create the mercury pool
    local pool = unitBeingBuilt:CreateProjectile('/effects/entities/AeonBuildEffect/AeonBuildEffect01_proj.bp', 0, 0, 0, 0, 0, 0)
    TrashBagAdd(onDeathTrash, pool)
    TrashBagAdd(onFinishedTrash, pool)

    ProjectileSetScale(pool, sx, sy, sz)
    local offset = unitBeingBuilt.Blueprint.Display.AeonMercuryPoolOffset
    if offset then
        local position = pool:GetPosition()
        position[2] = position[2] + offset
        Warp(pool, position)
    end

    pool:SetOrientation(unitBeingBuilt:GetOrientation(), true)

    -- Create effects of build animation
    local emitter = CreateEmitterOnEntity(pool, army, '/effects/emitters/aeon_being_built_ambient_02_emit.bp')
    IEffectSetEmitterCurveParam(emitter, 'X_POSITION_CURVE', 0, sx * 1.5)
    IEffectSetEmitterCurveParam(emitter, 'Z_POSITION_CURVE', 0, sz * 1.5)
    TrashBagAdd(onDeathTrash, emitter)
    TrashBagAdd(onFinishedTrash, emitter)

    emitter = CreateEmitterOnEntity(pool, army, '/effects/emitters/aeon_being_built_ambient_03_emit.bp')
    IEffectScaleEmitter(emitter, scale)
    TrashBagAdd(onDeathTrash, emitter)
    TrashBagAdd(onFinishedTrash, emitter)

    return pool
end

--- Creates an Aeon mercury pool build effect
---@param unitBeingBuilt Unit Unit to attach mercury pool to
---@param army integer
---@param bone Bone Bone to place pool at
---@param sx number Size x of the pool
---@param sy number Size y of the pool
---@param sz number Size z of the pool
---@param scale number Scale of secondary build effect
---@return Entity pool
function CreateMercuryPoolOnBone(unitBeingBuilt, army, bone, sx, sy, sz, scale)
    local onDeathTrash = unitBeingBuilt.Trash
    local onFinishedTrash = unitBeingBuilt.OnBeingBuiltEffectsBag

    -- -- Create the mercury pool
    local pool = EntityCreateProjectileAtBone(unitBeingBuilt, '/effects/entities/AeonBuildEffect/AeonBuildEffect01_proj.bp', bone)
    TrashBagAdd(onDeathTrash, pool)
    TrashBagAdd(onFinishedTrash, pool)
    EntitySetOrientation(pool, EntityGetOrientation(unitBeingBuilt), true)
    ProjectileSetScale(pool, sx, sy, sz)

    -- -- Create effects of build animation
    local emitter = CreateEmitterOnEntity(pool, army, '/effects/emitters/aeon_being_built_ambient_02_emit.bp')
    IEffectSetEmitterCurveParam(emitter, 'X_POSITION_CURVE', 0, sx * 1.5)
    IEffectSetEmitterCurveParam(emitter, 'Z_POSITION_CURVE', 0, sz * 1.5)
    TrashBagAdd(onDeathTrash, emitter)
    TrashBagAdd(onFinishedTrash, emitter)

    emitter = CreateEmitterOnEntity(pool, army, '/effects/emitters/aeon_being_built_ambient_03_emit.bp')
    IEffectScaleEmitter(emitter, scale)
    TrashBagAdd(onDeathTrash, emitter)
    TrashBagAdd(onFinishedTrash, emitter)

    return pool
end

--- Creates some generic build effects for Aeon
---@param unitBeingBuilt Unit Unit to attach build effects to
---@param army integer
---@param sx number Size x of the emitter curve parameter
---@param sz number Size z of the emitter curve parameter
---@param scale number Scale of the build effect
function CreateAeonGenericBuildEffects(unitBeingBuilt, army, sx, sz, scale)
    local onDeathTrash = unitBeingBuilt.Trash
    local onFinishedTrash = unitBeingBuilt.OnBeingBuiltEffectsBag

    -- -- Create effects of build animation
    local emitter = CreateEmitterOnEntity(unitBeingBuilt, army, '/effects/emitters/aeon_being_built_ambient_02_emit.bp')
    IEffectSetEmitterCurveParam(emitter, 'X_POSITION_CURVE', 0, sx)
    IEffectSetEmitterCurveParam(emitter, 'Z_POSITION_CURVE', 0, sz)
    TrashBagAdd(onDeathTrash, emitter)
    TrashBagAdd(onFinishedTrash, emitter)

    emitter = CreateEmitterOnEntity(unitBeingBuilt, army, '/effects/emitters/aeon_being_built_ambient_03_emit.bp')
    IEffectScaleEmitter(emitter, scale)
    TrashBagAdd(onDeathTrash, emitter)
    TrashBagAdd(onFinishedTrash, emitter)
end

--- Creates generic Aeon build sparkles
---@param unitBeingBuilt Unit Unit to attach sparkles to
---@param army integer
---@param sx number Size x of the emitter curve parameter
---@param sz number Size z of the emitter curve parameter
function CreateAeonGenericBuildSparkles(unitBeingBuilt, army, sx, sz)
    local onDeathTrash = unitBeingBuilt.Trash
    local onFinishedTrash = unitBeingBuilt.OnBeingBuiltEffectsBag
    -- Create additional sparkles
    local quartSx, quartSz = sx * 0.25, sz * 0.25
    for k = 1, 10 do
        local doubFrac = k / 5
        local emitter = CreateEmitterOnEntity(unitBeingBuilt, army, '/effects/emitters/aeon_being_built_ambient_02_emit.bp')
        IEffectSetEmitterCurveParam(emitter, 'X_POSITION_CURVE', 0, doubFrac * quartSx)
        IEffectSetEmitterCurveParam(emitter, 'Z_POSITION_CURVE', 0, doubFrac * quartSz)
        IEffectScaleEmitter(emitter, 2.0)
        IEffectOffsetEmitter(emitter, 0, 2 - doubFrac, 0)
        TrashBagAdd(onDeathTrash, emitter)
        TrashBagAdd(onFinishedTrash, emitter)
    end
end

--- The build animation of an engineer.
---@param builder Unit The engineer in question
---@param unitBeingBuilt Unit The unit we're building
---@param buildEffectsBag TrashBag The trash bag for the build effects
function CreateAeonConstructionUnitBuildingEffects(builder, unitBeingBuilt, buildEffectsBag)
    local army = builder.Army
    -- create effect on builder
    TrashBagAdd(buildEffectsBag, CreateEmitterOnEntity(builder, army, '/effects/emitters/aeon_build_01_emit.bp') )

    -- create beam builder -> target
    for _, effect in AeonBuildBeams01 do
        TrashBagAdd(buildEffectsBag, AttachBeamEntityToEntity(builder, -1, unitBeingBuilt, -1, army, effect))
    end
end

--- The build animation of the commander.
---@param builder Unit The commander in question
---@param unitBeingBuilt Unit The unit we're building
---@param buildEffectBones string[] The bone(s) of the commander where the effect starts
---@param buildEffectsBag TrashBag The trash bag for the build effects
function CreateAeonCommanderBuildingEffects(builder, unitBeingBuilt, buildEffectBones, buildEffectsBag)
    local army = builder.Army
    -- create beam builder -> target
    for _, bone in buildEffectBones do
        TrashBagAdd(buildEffectsBag, CreateAttachedEmitter(builder, bone, army, '/effects/emitters/aeon_build_02_emit.bp'))
        for _, effect in AeonBuildBeams01 do
            TrashBagAdd(buildEffectsBag, AttachBeamEntityToEntity(builder, bone, unitBeingBuilt, -1, army, effect))
        end
    end
end

--- The shared functionality between building structures and units
---@param pool Entity The mercury pool for the build effect
---@param unitBeingBuilt Unit The unit that is being made
---@param trash TrashBag The generic trashbag of the unit
---@param onStopBeingBuiltTrash TrashBag The OnStopBeingBuilt trashbag of the unit
---@param sx number
---@param sy number
---@param sz number
local function SharedBuildThread(pool, unitBeingBuilt, trash, onStopBeingBuiltTrash, sx, sy, sz)
    -- -- Determine offset for hover units
    local offset = 0
    local slider = nil
    if unitBeingBuilt.Blueprint.CategoriesHash["HOVER"] then
        -- set elevation offset
        offset = unitBeingBuilt.Blueprint.Elevation or 0
        -- create a slider
        slider = CreateSlider(unitBeingBuilt, 0)
        SliderSetWorldUnits(slider, true)
        SliderSetGoal(slider, 0, 0, 0)
        SliderSetSpeed(slider, 100)

        TrashBagAdd(trash, slider)
        TrashBagAdd(onStopBeingBuiltTrash, slider)
    end

    -- -- Shrink pool accordingly
    local fraction = UnitGetFractionComplete(unitBeingBuilt)
    local scaledSy = 1.5 * sy
    while fraction < 1 do
        -- only update when we make progress
        local cFraction = UnitGetFractionComplete(unitBeingBuilt)
        if cFraction > fraction then
            -- store updated value
            fraction = cFraction

            -- only adjust pool when more than 80% complete to match the shader animation
            if fraction > 0.8 then
                local progress = 5 * (fraction - 0.8)
                if progress < 0 then
                    progress = 0
                end

                scale = 1 - progress * progress
                ProjectileSetScale(pool, sx * scale, scaledSy * scale, sz * scale)
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
---@param unitBeingBuilt Unit The unit we're trying to build
---@param builder Unit Unused
---@param effectsBag TrashBag The build effects bag containing the pool and emitters (unused)
function CreateAeonBuildBaseThread(unitBeingBuilt, builder, effectsBag)
    -- -- Hold up for orientation to receive an update
    WaitTicks(2)
    -- always check after a wait
    if (not unitBeingBuilt) or unitBeingBuilt.Dead then
        return
    end

    -- -- Initialize various info used throughout the function
    local army = unitBeingBuilt.Army
    local unitBeingBuiltTrash = unitBeingBuilt.Trash
    local unitOnStopBeingBuiltTrash = unitBeingBuilt.OnBeingBuiltEffectsBag
    local Physics = unitBeingBuilt.Blueprint.Physics
    local Footprint = unitBeingBuilt.Blueprint.Footprint
    local sx = Physics.MeshExtentsX or Footprint.SizeX
    local sz = Physics.MeshExtentsZ or Footprint.SizeZ
    local sy = Physics.MeshExtentsY or Footprint.SizeY or MathMin(sx, sz)

    local pool = CreateMercuryPool(unitBeingBuilt, army, sx, sy * 1.5, sz, (sx + sz) * 0.3)

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
---@param builder Unit The factory that is building the unit
---@param unitBeingBuilt Unit The unit we're trying to build
---@param buildEffectBones string[] The arms of the factory where the build beams come from
---@param buildBone string The location where the unit is beint built
---@param effectsBag TrashBag The build effects bag
function CreateAeonFactoryBuildingEffects(builder, unitBeingBuilt, buildEffectBones, buildBone, effectsBag)
    -- -- Hold up for orientation to receive an update
    WaitTicks(2)

    -- always check after a wait
    if (not unitBeingBuilt) or unitBeingBuilt.Dead then
        return
    end

    -- -- Create build beams for factory
    local army = unitBeingBuilt.Army
    for _, bone in buildEffectBones do
        TrashBagAdd(effectsBag, CreateAttachedEmitter(builder, bone, army, '/effects/emitters/aeon_build_03_emit.bp'))
        for _, effect in AeonBuildBeams02 do
            TrashBagAdd(effectsBag, AttachBeamEntityToEntity(builder, bone, builder, buildBone, army, effect))
        end
    end

    -- -- Create persistent state between calls
    if not unitBeingBuilt.ConstructionInitialised then
        unitBeingBuilt.ConstructionInitialised = true
        -- -- Initialize various info used throughout the function
        local unitBeingBuiltTrash = unitBeingBuilt.Trash
        local unitOnStopBeingBuiltTrash = unitBeingBuilt.OnBeingBuiltEffectsBag
        local Physics = unitBeingBuilt.Blueprint.Physics
        local Footprint = unitBeingBuilt.Blueprint.Footprint
        local sx = Physics.MeshExtentsX or Footprint.SizeX
        local sz = Physics.MeshExtentsZ or Footprint.SizeZ
        local sy = Physics.MeshExtentsY or Footprint.SizeY or MathMin(sz, sz)

        if unitBeingBuilt.Blueprint.CategoriesHash["AIR"] then
            local t = sx
            sx = sz
            sz = t
        end

        local pool = CreateMercuryPool(unitBeingBuilt, army, sx, sy * 1.5, sz, (sx + sz) * 0.3)

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
    "Left_Footfall",
    "Left_Leg_B01",
    "Left_Leg_B02",
    "Right_Leg_B02",
    "Right_Leg_B01",
    "Right_Footfall",
    "Right_Arm_Muzzle01",
    "Left_Arm_Muzzle101",
}

--- Possible animations of the colossus, prevents a blueprint lookup
local ColossusAnimations = {
    '/units/UAL0401/UAL0401_aactivate.sca',
    '/units/UAL0401/UAL0401_aactivate_alt.sca',
}

--- Puddle locations of the colossus
local ColossusPuddleBones = {
    {
        "Right_Footfall",
        "Left_Footfall",
    }, {
        "Right_Footfall",
        "Left_Footfall",
    }
}


--- A helper function for the full build animation of the Colossus.
---@param unitBeingBuilt Unit The Colossus that is being built
---@param animator Animator The animator that is applied
---@param puddleBones string[] The set of bones to use for puddles
local function CreateAeonColossusBuildingEffectsThread(unitBeingBuilt, animator, puddleBones)
    WaitTicks(2)

    -- -- Store information used throughout the function
    local sx = 1.5
    local sy = 2.25
    local sz = 1.5
    local army = unitBeingBuilt.Army
    local onDeathTrash = unitBeingBuilt.Trash
    local onFinishedTrash = unitBeingBuilt.OnBeingBuiltEffectsBag

    -- -- Create pools of mercury
    local pools = { false, false }
    for k, bone in puddleBones do
        pools[k] = CreateMercuryPoolOnBone(unitBeingBuilt, army, bone, sx, sy, sz, sy)
    end

    -- -- Apply build effects
    for k, _ in ColossusEffectBones do
        local emitter = CreateEmitterAtBone(unitBeingBuilt, k, army, '/effects/emitters/aeon_being_built_ambient_02_emit.bp')
        IEffectSetEmitterCurveParam(emitter, 'X_POSITION_CURVE', 0, 1)
        IEffectSetEmitterCurveParam(emitter, 'Z_POSITION_CURVE', 0, 1)
        IEffectScaleEmitter(emitter, 1.0)

        TrashBagAdd(onDeathTrash, emitter)
        TrashBagAdd(onFinishedTrash, emitter)
    end

    -- -- Apply a manual animation
    local fraction = UnitGetFractionComplete(unitBeingBuilt)
    local scaledSy = sy * 1.5
    while fraction < 1 do
        -- only update when we make progress
        local cFraction = UnitGetFractionComplete(unitBeingBuilt)
        if cFraction > fraction then
            -- store updated value
            fraction = cFraction
            -- only adjust pool when more than 80% complete to match the shader animation
            if fraction > 0.8 then
                local progress = 5 * (fraction - 0.8)
                if progress < 0 then
                    progress = 0
                end
                local prog2 = progress * progress
                scale = 1 - prog2

                -- progress pool
                local scaleX, scaleY, scaleZ = sx * scale, scaledSy * scale, sz * scale
                for _, pool in pools do
                    ProjectileSetScale(pool, scaleX, scaleY, scaleZ)
                end

                -- progress animation
                animator:SetAnimationFraction(progress * prog2)
            end
        end
        -- wait a tick
        WaitTicks(2)
    end
end

--- Creates the Aeon Tempest build effects, including particles and an animation.
---@param unitBeingBuilt Unit The Colossus that is being built
function CreateAeonColossusBuildingEffects(unitBeingBuilt)
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
---@param unitBeingBuilt Unit The CZAR that is being built
function CreateAeonCZARBuildingEffects(unitBeingBuilt)
    -- -- Initialize various info used throughout the function
    local army = unitBeingBuilt.Army
    local bp = unitBeingBuilt.Blueprint
    local sx = 0.6 * bp.Physics.MeshExtentsX or bp.Footprint.SizeX
    local sz = 0.6 * bp.Physics.MeshExtentsZ or bp.Footprint.SizeZ

    CreateAeonGenericBuildEffects(unitBeingBuilt, army, sx, 0.75 * sx, sz)
    CreateAeonGenericBuildSparkles(unitBeingBuilt, army, sx, sz)
end

--- A helper function for the full build animation of the Tempest.
---@param unitBeingBuilt Unit The Tempest that is being built
---@param animator Animator The animator that is applied
local function CreateAeonTempestBuildingEffectsThread(unitBeingBuilt, animator)
    local fraction = UnitGetFractionComplete(unitBeingBuilt)
    while fraction < 1 do
        -- only update when we make progress
        local cFraction = UnitGetFractionComplete(unitBeingBuilt)
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
---@param unitBeingBuilt Unit The tempest that is being built
function CreateAeonTempestBuildingEffects(unitBeingBuilt)
    -- -- Initialize various info used throughout the function
    local army = unitBeingBuilt.Army
    local onDeathTrash = unitBeingBuilt.Trash
    local onFinishedTrash = unitBeingBuilt.OnBeingBuiltEffectsBag
    local bp = unitBeingBuilt.Blueprint
    local sx = 0.55 * bp.Physics.MeshExtentsX or bp.Footprint.SizeX
    local sz = 0.55 * bp.Physics.MeshExtentsZ or bp.Footprint.SizeZ

    CreateAeonGenericBuildEffects(unitBeingBuilt, army, sx, 0.75 * sx, sz)
    CreateAeonGenericBuildSparkles(unitBeingBuilt, army, sx, sz)

    -- -- Apply build animation
    local animator = CreateAnimator(unitBeingBuilt)
    animator:PlayAnim('/units/uas0401/uas0401_build.sca', false)
    animator:SetRate(0)
    animator:SetAnimationFraction(1)
    TrashBagAdd(onDeathTrash, animator)
    TrashBagAdd(onFinishedTrash, animator)

    local thread = ForkThread(CreateAeonTempestBuildingEffectsThread, unitBeingBuilt, animator)
    TrashBagAdd(onDeathTrash, thread)
    TrashBagAdd(onFinishedTrash, thread)
end

--- A helper function for the full build animation of the Paragon.
---@param unitBeingBuilt Unit The Paragon that is being built
---@param sx number
---@param sy number unused
---@param sz number
local function CreateAeonParagonBuildingEffectsThread(unitBeingBuilt, sx, sy, sz)
    -- -- Initialize various info used throughout the function
    local army = unitBeingBuilt.Army
    local onDeathTrash = unitBeingBuilt.Trash
    local onFinishedTrash = unitBeingBuilt.OnBeingBuiltEffectsBag

    local quartSx, quartSz = sx * 0.25, sz * 0.25

    -- -- Add various effects over time
    local k = 0.1
    local fraction = UnitGetFractionComplete(unitBeingBuilt)
    while fraction < 1 do
        -- only update when we make progress
        local cFraction = UnitGetFractionComplete(unitBeingBuilt)
        if cFraction > fraction then
            -- store updated value
            fraction = cFraction
            if k < cFraction then
                local doubFrac = 2 * (1.1 - k)
                local emitter = CreateEmitterOnEntity(unitBeingBuilt, army, '/effects/emitters/aeon_being_built_ambient_02_emit.bp')
                IEffectSetEmitterCurveParam(emitter, 'X_POSITION_CURVE', 0, doubFrac * quartSx)
                IEffectSetEmitterCurveParam(emitter, 'Z_POSITION_CURVE', 0, doubFrac * quartSz)
                IEffectScaleEmitter(emitter, 2.0)
                IEffectOffsetEmitter(emitter, 0, 2 - doubFrac, 0)

                TrashBagAdd(onDeathTrash, emitter)
                TrashBagAdd(onFinishedTrash, emitter)

                k = k + 0.08
            end
        end
        -- wait a tick
        WaitTicks(2)
    end
end

--- Creates the Aeon Paragon build effects, including particles and an animation.
---@param unitBeingBuilt Unit The Tempest that is being built
function CreateAeonParagonBuildingEffects(unitBeingBuilt)
    -- -- Initialize various info used throughout the function
    local army = unitBeingBuilt.Army

    local Physics = unitBeingBuilt.Blueprint.Physics
    local Footprint = unitBeingBuilt.Blueprint.Footprint
    local sx = Physics.MeshExtentsX or Footprint.SizeX
    local sz = Physics.MeshExtentsZ or Footprint.SizeZ
    local sy = 2 * Physics.MeshExtentsY or Footprint.SizeY or MathMin(sx, sz)

    CreateAeonGenericBuildEffects(unitBeingBuilt, army, sx, sy, sz)

    -- -- Create additional sparkles
    local thread = ForkThread(CreateAeonParagonBuildingEffectsThread, unitBeingBuilt, sx, sy, sz)
    TrashBagAdd(unitBeingBuilt.Trash, thread)
    TrashBagAdd(unitBeingBuilt.OnBeingBuiltEffectsBag, thread)
end