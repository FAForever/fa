
local util = import('utilities.lua')
local Entity = import('/lua/sim/Entity.lua').Entity
local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- upvalue for performance
local Warp = Warp
local Random = Random
local VectorCached = Vector(0, 0, 0)

local CoroutineYield = coroutine.yield

local AttachBeamEntityToEntity = AttachBeamEntityToEntity
local CreateEmitterOnEntity = CreateEmitterOnEntity
local CreateAttachedEmitter = CreateAttachedEmitter

local TrashBag = TrashBag
local TrashAdd = TrashBag.Add
local TrashDestroy = TrashBag.Destroy

local EntityBeenDestroyed = _G.moho.entity_methods.BeenDestroyed
local EntityCreateProjectile = _G.moho.entity_methods.CreateProjectile
local EntityGetPositionXYZ = _G.moho.entity_methods.GetPositionXYZ
local EntitySetScale = _G.moho.entity_methods.SetScale 

local UnitGetFractionComplete = _G.moho.unit_methods.GetFractionComplete
local UnitShowBone = _G.moho.unit_methods.ShowBone 

local ProjectileSetVelocity = _G.moho.projectile_methods.SetVelocity

-- various delays in ticks + 1
local BuildCubeGlowDuration = 2
local BuildCubeDelay = 8 
local BuildCubeFirstSliceDelay = 3 
local BuildCubeSlicePeriod = 12
local BuilderSlicePeriod = 6

--- Creates the default build beams that, among others, UEF engineers use to build non-UEF units
-- @param builder The builder
-- @param unitBeingBuilt The unit being build
-- @param buildEffectBones The effect bones of the builder
-- @param buildeffectsBag The effects bag of the builder
function CreateDefaultBuildBeams(
    builder,            -- Unit that is building
    unitBeingBuilt,     -- Unit being built
    buildEffectBones,   -- Table of bones
    buildEffectsBag     -- Trashbag
)

    local vc = VectorCached
    local army = builder.Army 
    local ox, oy, oz = EntityGetPositionXYZ(unitBeingBuilt)

    -- allocation of entity
    local beamEndBuilder = builder.UEFBuildProjectile 
    if not beamEndBuilder then 
        beamEndBuilder = EntityCreateProjectile(unitBeingBuilt, '/effects/entities/UEFBuild/UEFBuild01_proj.bp', 0, 0, 0, nil, nil, nil)
        builder.UEFBuildProjectile = beamEndBuilder
        TrashAdd(builder.Trash, beamEndBuilder)
    end

    -- reset the state of the projectile
    ProjectileSetVelocity(beamEndBuilder, 0)
    TrashAdd(buildEffectsBag, CreateEmitterOnEntity(beamEndBuilder, army, '/effects/emitters/build_terran_glow_01_emit.bp'))
    TrashAdd(buildEffectsBag,  CreateEmitterOnEntity(beamEndBuilder, builder.Army, '/effects/emitters/sparks_08_emit.bp'))

    vc[1] = ox 
    vc[2] = oy 
    vc[3] = oz
    Warp(beamEndBuilder, vc)

    -- Create build beams
    if buildEffectBones ~= nil then
        local beamEffect = nil
        for i, BuildBone in buildEffectBones do
            TrashAdd(buildEffectsBag, AttachBeamEntityToEntity(builder, BuildBone, beamEndBuilder, -1, army, '/effects/emitters/build_beam_01_emit.bp'))
        end
    end

    local ProjectileSetVelocity = ProjectileSetVelocity 
    local CoroutineYield = CoroutineYield

    local waitTime = Random(8, 15)
    local waitTimeInv =  10 * 1 / waitTime
    while not (builder.Dead or unitBeingBuilt.Dead) do
        local x, y, z = builder.GetRandomOffset(unitBeingBuilt, 1)
        local px, py, pz = EntityGetPositionXYZ(beamEndBuilder)
        local dx, dy, dz = waitTimeInv * ((ox + x) - px), waitTimeInv * ((oy + y) - py), waitTimeInv * ((oz + z) - pz)
        ProjectileSetVelocity(beamEndBuilder, dx, dy, dz )

        CoroutineYield(waitTime)
    end
end

--- Creates the slice beams that UEF engineers use to build UEF units 
-- @param builder The builder
-- @param unitBeingBuilt The unit being build
-- @param buildEffectBones The effect bones of the builder
-- @param buildeffectsBag The effects bag of the builder
function CreateUEFBuildSliceBeams(
    builder,            -- Unit that is building
    unitBeingBuilt,     -- Unit being built
    buildEffectBones,   -- Table of bones
    buildEffectsBag     -- Trashbag
)

    local vc = VectorCached
    local army = builder.Army
    local buildbp = unitBeingBuilt.Blueprint
    local cx, cy, cz = EntityGetPositionXYZ(unitBeingBuilt)
    cy = cy + (buildbp.Physics.MeshExtentsOffsetY or 0)

    -- Create a projectile for the end of build effect and warp it to the unit
    local beamEndBuilder = builder.UEFBuildProjectile 
    if not beamEndBuilder then 
        beamEndBuilder = EntityCreateProjectile(unitBeingBuilt, '/effects/entities/UEFBuild/UEFBuild01_proj.bp', 0, 0, 0, nil, nil, nil)
        builder.UEFBuildProjectile = beamEndBuilder
        TrashAdd(builder.Trash, beamEndBuilder)
    end

    -- reset the state of the projectile
    ProjectileSetVelocity(beamEndBuilder, 0)
    TrashAdd(buildEffectsBag, CreateEmitterOnEntity(beamEndBuilder, army, '/effects/emitters/build_terran_glow_01_emit.bp'))
    TrashAdd(buildEffectsBag, CreateEmitterOnEntity(beamEndBuilder, army, '/effects/emitters/build_sparks_blue_01_emit.bp'))

    -- add the build beam between the build bones and the projectile
    if buildEffectBones ~= nil then
        for i, BuildBone in buildEffectBones do
            TrashAdd(buildEffectsBag, AttachBeamEntityToEntity(builder, BuildBone, beamEndBuilder, -1, army, '/effects/emitters/build_beam_01_emit.bp'))
            TrashAdd(buildEffectsBag, CreateAttachedEmitter(builder, BuildBone, army, '/effects/emitters/flashing_blue_glow_01_emit.bp'))
        end
    end

    -- Determine beam positioning on build cube, this should match sizes of CreateBuildCubeThread
    local ox = unitBeingBuilt.BuildExtentsX
    local oz = unitBeingBuilt.BuildExtentsZ
    local oy = unitBeingBuilt.BuildExtentsY

    ox = ox * 0.5
    oz = oz * 0.5

    -- allocate alllllll the locals

    local ax, az, bx, bz
    local ex, ey, ez
    local dot
    local fx1, fz1, fx2, fz2, fy
    local dcax, dcaz
    local dcex, dcez

    -- determine direction to builder
    ex, ey, ez = EntityGetPositionXYZ(builder)
    dcex = ex - cx 
    dcez = ez - cz 

    -- south west / north east comparison

    -- compute a / b points 
    ax = cx - ox
    az = cz + oz
    bx = cx + ox 
    bz = cz - oz

    -- compute direction c -> a
    dcax = ax - cx 
    dcaz = az - cz 

    -- if this dot product is positive, then the engineer is closer to a than it is to b
    if dcax * dcex + dcaz * dcez > 0 then 
        fx1 = ax 
        fz1 = az 
    else 
        fx1 = bx 
        fz1 = bz 
    end

    -- north west / south east comparison

    -- compute a / b points 
    ax = cx - ox
    az = cz - oz
    bx = cx + ox 
    bz = cz + oz

    -- compute direction c -> a
    dcax = ax - cx 
    dcaz = az - cz 

    -- if this dot product is positive, then the engineer is closer to a than it is to b
    if dcax * dcex + dcaz * dcez > 0 then 
        fx2 = ax 
        fz2 = az 
    else 
        fx2 = bx 
        fz2 = bz 
    end

    -- compute the y component of the vectors, which is always the same regardless of the point chosen because
    -- we flatten the ground :))
    fy = cy + oy

    -- the two vectors that represent the points
    -- (fx1, fy, fz1)
    -- (fx2, fy, fz2)

    -- Determine a the velocity of our projectile, used for the scanning effect
    local velX = 2 * (fx2 - fx1)
    local velZ = 2 * (fz2 - fz1)

    local fraction = UnitGetFractionComplete(unitBeingBuilt)
    if fraction == 0 then
        vc[1] = (fx1 + fx2) * 0.5
        vc[2] = fy - oy
        vc[3] = (fz1 + fz2) * 0.5
        Warp(beamEndBuilder, vc)
        CoroutineYield(BuildCubeDelay)
    end

    -- store as locals for performance
    local UnitGetFractionComplete = UnitGetFractionComplete
    local ProjectileSetVelocity = ProjectileSetVelocity
    local Warp = Warp

    -- Warp our projectile back to the initial corner and lower based on build completeness
    local flipDirection = true
    while not (builder.Dead or unitBeingBuilt.Dead) do

        fraction = UnitGetFractionComplete(unitBeingBuilt)

        if flipDirection then
            vc[1] = fx1
            vc[2] = (fy - (oy * fraction))
            vc[3] = fz1
            Warp(beamEndBuilder, vc)
            ProjectileSetVelocity(beamEndBuilder, velX, 0, velZ)
            flipDirection = false
        else
            vc[1] = fx2
            vc[2] = (fy - (oy * UnitGetFractionComplete(unitBeingBuilt)))
            vc[3] = fz2
            Warp(beamEndBuilder, vc)
            ProjectileSetVelocity(beamEndBuilder, -velX, 0, -velZ)
            flipDirection = true
        end
        CoroutineYield(BuilderSlicePeriod)
    end
end

--- Creates the build cube used by UEF structures
-- @param builder The builder
-- @param unitBeingBuilt The unit being build
-- @param onBeingBuiltEffectsBag The Effects bag of the unit being built
function CreateBuildCubeThread(
    unitBeingBuilt, 
    builder, 
    onBeingBuiltEffectsBag
)

    -- used to differentiate between using a 
    -- slice beam and a default build beam
    unitBeingBuilt.BuildingCube = true

    -- cache information used throughout the function
    local vc = VectorCached
    local px, py, pz = EntityGetPositionXYZ(unitBeingBuilt)
    py = py + (unitBeingBuilt.Blueprint.Physics.MeshExtentsOffsetY or 0)

    local bx = unitBeingBuilt.BuildExtentsX
    local by = unitBeingBuilt.BuildExtentsY
    local bz = unitBeingBuilt.BuildExtentsZ

    -- create a quick glow effect
    local proj = EntityCreateProjectile(unitBeingBuilt, '/effects/Entities/UEFBuildEffect/UEFBuildEffect02_proj.bp', 0, 0, 0, nil, nil, nil)
    EntitySetScale(proj, bx * 1.05, by * 0.2, bz * 1.05)
    CoroutineYield(BuildCubeGlowDuration)

    -- always check if we're still there after waiting
    if unitBeingBuilt.Dead then
        return
    end

    -- create the build cube
    local BuildBaseEffect = EntityCreateProjectile(unitBeingBuilt, '/effects/Entities/UEFBuildEffect/UEFBuildEffect03_proj.bp', 0, 0, 0, nil, nil, nil)
    TrashAdd(onBeingBuiltEffectsBag, BuildBaseEffect)
    TrashAdd(unitBeingBuilt.Trash, BuildBaseEffect)

    -- warp it to the build site
    vc[1], vc[2], vc[3] = px, py - by, pz
    Warp(BuildBaseEffect, vc)

    -- scale it accordingly
    EntitySetScale(BuildBaseEffect, bx, by, bz)

    -- it warps at y = 0 (relative to the unit), move up until the build cube completely covered the unit
    ProjectileSetVelocity(BuildBaseEffect, 0, 1.4 * by, 0)
    CoroutineYield(BuildCubeDelay)

    -- always check if we're still there after waiting
    if unitBeingBuilt.Dead then
        return
    end

    -- build cube is where it should be
    ProjectileSetVelocity(BuildBaseEffect, 0)

    -- update internal state
    UnitShowBone(unitBeingBuilt, 0, true)
    unitBeingBuilt:HideLandBones() -- we can't upvalue this, it is a Lua function
    unitBeingBuilt.BeingBuiltShowBoneTriggered = true

    local lComplete = UnitGetFractionComplete(unitBeingBuilt)
    WaitSeconds(BuildCubeFirstSliceDelay)

    -- always check if we're still there after waiting
    if unitBeingBuilt.Dead then
        return
    end

    -- Create glow slice cuts and resize base cube
    local slice = nil
    local cComplete = UnitGetFractionComplete(unitBeingBuilt)
    while not unitBeingBuilt.Dead and cComplete < 1.0 do

        if lComplete < cComplete and not EntityBeenDestroyed(BuildBaseEffect) then

            -- create a glow effect
            proj = EntityCreateProjectile(
                BuildBaseEffect, 
                '/effects/Entities/UEFBuildEffect/UEFBuildEffect02_proj.bp', 
                0, 
                by * (1 - cComplete), 
                0, 
                nil, nil, nil
            )


            TrashAdd(onBeingBuiltEffectsBag, proj)

            -- size the build cube and the glow effect
            slice = cComplete - lComplete
            EntitySetScale(proj, bx, by * slice, bz)
            EntitySetScale(BuildBaseEffect, bx, by * (1 - cComplete), bz)
        end

        CoroutineYield(BuildCubeSlicePeriod)

        -- always check if we're still there after waiting
        if not unitBeingBuilt.Dead then 
            lComplete = cComplete
            cComplete = UnitGetFractionComplete(unitBeingBuilt)
        end
    end

    -- keep track of state on the unit itself
    unitBeingBuilt.BuildingCube = nil
end

--- Creates the UEF unit being built effects
-- @param builder The builder
-- @param unitBeingBuilt The unit being build
-- @param buildeffectsBag The effects bag of the unit being built
function CreateUEFUnitBeingBuiltEffects(builder, unitBeingBuilt, buildEffectsBag)
    local buildAttachBone = builder.Blueprint.Display.BuildAttachBone
    TrashAdd(buildEffectsBag, CreateAttachedEmitter(builder, buildAttachBone, builder.Army, '/effects/emitters/uef_mobile_unit_build_01_emit.bp'))
end

--- Creates the commander-like slice beams where two beams originate from the build effect bones instead of one. 
-- This function is not optimized.
-- @param builder a (S)ACU
-- @param unitBeingBuilt The unit being build
-- @param buildEffectBones The effect bones of the builder
-- @param buildeffectsBag The effects bag of the builder
function CreateUEFCommanderBuildSliceBeams(builder, unitBeingBuilt, BuildEffectBones, BuildEffectsBag)
    local BeamBuildEmtBp = '/effects/emitters/build_beam_01_emit.bp'
    local buildbp = unitBeingBuilt:GetBlueprint()
    local x, y, z = unpack(unitBeingBuilt:GetPosition())
    y = y + (buildbp.Physics.MeshExtentsOffsetY or 0)

    -- Create a projectile for the end of build effect and warp it to the unit
    local beamEndBuilder = unitBeingBuilt:CreateProjectile('/effects/entities/UEFBuild/UEFBuild01_proj.bp', 0, 0, 0, nil, nil, nil)
    local beamEndBuilder2 = unitBeingBuilt:CreateProjectile('/effects/entities/UEFBuild/UEFBuild01_proj.bp', 0, 0, 0, nil, nil, nil)
    BuildEffectsBag:Add(beamEndBuilder)
    BuildEffectsBag:Add(beamEndBuilder2)

    -- Create build beams
    if BuildEffectBones ~= nil then
        local beamEffect = nil
        for i, BuildBone in BuildEffectBones do
            BuildEffectsBag:Add(AttachBeamEntityToEntity(builder, BuildBone, beamEndBuilder, -1, builder.Army, BeamBuildEmtBp))
            BuildEffectsBag:Add(AttachBeamEntityToEntity(builder, BuildBone, beamEndBuilder2, -1, builder.Army, BeamBuildEmtBp))
            BuildEffectsBag:Add(CreateAttachedEmitter(builder, BuildBone, builder.Army, '/effects/emitters/flashing_blue_glow_01_emit.bp'))
        end
    end

    -- Determine beam positioning on build cube, this should match sizes of CreateBuildCubeThread
    local mul = 1.15
    local ox = buildbp.Physics.MeshExtentsX or (buildbp.Footprint.SizeX * mul)
    local oz = buildbp.Physics.MeshExtentsZ or (buildbp.Footprint.SizeZ * mul)
    local oy = (buildbp.Physics.MeshExtentsY or (0.5 + (ox + oz) * 0.1))

    ox = ox * 0.5
    oz = oz * 0.5

    -- Determine the the 2 closest edges of the build cube and use those for the location of our laser
    local VectorExtentsList = { Vector(x + ox, y + oy, z + oz), Vector(x + ox, y + oy, z - oz), Vector(x - ox, y + oy, z + oz), Vector(x - ox, y + oy, z - oz) }
    local endVec1 = util.GetClosestVector(builder:GetPosition(), VectorExtentsList)

    for k, v in VectorExtentsList do
        if v == endVec1 then
            table.remove(VectorExtentsList, k)
        end
    end

    local endVec2 = util.GetClosestVector(builder:GetPosition(), VectorExtentsList)
    local cx1, cy1, cz1 = unpack(endVec1)
    local cx2, cy2, cz2 = unpack(endVec2)

    -- Determine a the velocity of our projectile, used for the scaning effect
    local velX = 2 * (endVec2.x - endVec1.x)
    local velY = 2 * (endVec2.y - endVec1.y)
    local velZ = 2 * (endVec2.z - endVec1.z)

    if unitBeingBuilt:GetFractionComplete() == 0 then
        Warp(beamEndBuilder, Vector(cx1, cy1 - oy, cz1))
        Warp(beamEndBuilder2, Vector(cx2, cy2 - oy, cz2))
        WaitSeconds(0.7)
    end

    local flipDirection = true

    -- Warp our projectile back to the initial corner and lower based on build completeness
    while not builder:BeenDestroyed() and not unitBeingBuilt:BeenDestroyed() do
        if flipDirection then
            Warp(beamEndBuilder, Vector(cx1, (cy1 - (oy * unitBeingBuilt:GetFractionComplete())), cz1))
            beamEndBuilder:SetVelocity(velX, velY, velZ)
            Warp(beamEndBuilder2, Vector(cx2, (cy2 - (oy * unitBeingBuilt:GetFractionComplete())), cz2))
            beamEndBuilder2:SetVelocity(-velX, -velY, -velZ)
            flipDirection = false
        else
            Warp(beamEndBuilder, Vector(cx2, (cy2 - (oy * unitBeingBuilt:GetFractionComplete())), cz2))
            beamEndBuilder:SetVelocity(-velX, -velY, -velZ)
            Warp(beamEndBuilder2, Vector(cx1, (cy1 - (oy * unitBeingBuilt:GetFractionComplete())), cz1))
            beamEndBuilder2:SetVelocity(velX, velY, velZ)
            flipDirection = true
        end
        WaitSeconds(0.5)
    end
end