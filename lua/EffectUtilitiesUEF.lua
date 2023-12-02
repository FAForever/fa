local AttachBeamEntityToEntity = AttachBeamEntityToEntity
local CreateAttachedEmitter = CreateAttachedEmitter
local CreateEmitterOnEntity = CreateEmitterOnEntity
local Random = Random
local WaitSeconds = WaitSeconds
local WaitTicks = WaitTicks
local Warp = Warp

local MathMin = math.min

local EntityCreateProjectile = moho.entity_methods.CreateProjectile
local EntityGetPositionXYZ = moho.entity_methods.GetPositionXYZ
local EntitySetScale = moho.entity_methods.SetScale
local EntityBeenDestroyed = moho.entity_methods.BeenDestroyed
local ProjectileSetVelocity = moho.projectile_methods.SetVelocity
local TrashBagAdd = TrashBag.Add
local UnitGetFractionComplete = moho.unit_methods.GetFractionComplete
local UnitShowBone = moho.unit_methods.ShowBone


local VectorCached = Vector(0, 0, 0)


-- various delays in ticks + 1
local BuildCubeGlowDuration = 2
local BuildCubeDelay = 8
local BuildCubeFirstSliceDelay = 3
local BuildCubeSlicePeriod = 12
local BuilderSlicePeriod = 6

--- Creates the default build beams that, among others, UEF engineers use to build non-UEF units
---@param builder Unit The builder
---@param unitBeingBuilt Unit The unit being build
---@param buildEffectBones string[] The effect bones of the builder
---@param buildEffectsBag TrashBag The effects bag of the builder
function CreateDefaultBuildBeams(builder, unitBeingBuilt, buildEffectBones, buildEffectsBag)
    WaitTicks(1)

    -- always confirm after waiting!
    if IsDestroyed(unitBeingBuilt) then
        return
    end

    local ProjectileSetVelocity = ProjectileSetVelocity
    local WaitTicks = WaitTicks

    local vc = VectorCached
    local army = builder.Army
    local ox, oy, oz = EntityGetPositionXYZ(unitBeingBuilt)

    -- allocation of entity
    local beamEndBuilder = builder.UEFBuildProjectile
    if not beamEndBuilder then
        beamEndBuilder = EntityCreateProjectile(unitBeingBuilt, '/effects/entities/UEFBuild/UEFBuild01_proj.bp', 0, 0, 0, nil, nil, nil)
        builder.UEFBuildProjectile = beamEndBuilder
        TrashBagAdd(builder.Trash, beamEndBuilder)
    end

    -- reset the state of the projectile
    ProjectileSetVelocity(beamEndBuilder, 0)
    TrashBagAdd(buildEffectsBag, CreateEmitterOnEntity(beamEndBuilder, army, '/effects/emitters/build_terran_glow_01_emit.bp'))
    TrashBagAdd(buildEffectsBag,  CreateEmitterOnEntity(beamEndBuilder, army, '/effects/emitters/sparks_08_emit.bp'))

    vc[1], vc[2], vc[3] = ox, oy, oz
    Warp(beamEndBuilder, vc)

    -- create build beams
    if buildEffectBones ~= nil then
        for _, buildBone in buildEffectBones do
            TrashBagAdd(buildEffectsBag, AttachBeamEntityToEntity(builder, buildBone, beamEndBuilder, -1, army, '/effects/emitters/build_beam_01_emit.bp'))
        end
    end

    local waitTime = Random(8, 15)
    local waitTimeInv =  10 / waitTime
    while not (EntityBeenDestroyed(builder) or EntityBeenDestroyed(unitBeingBuilt)) do
        local x, y, z = builder.GetRandomOffset(unitBeingBuilt, 1)
        local px, py, pz = EntityGetPositionXYZ(beamEndBuilder)
        local dx, dy, dz = waitTimeInv * (ox + x - px), waitTimeInv * (oy + y - py), waitTimeInv * (oz + z - pz)
        ProjectileSetVelocity(beamEndBuilder, dx, dy, dz)
        WaitTicks(waitTime)
    end
end

--- Creates the slice beams that UEF engineers use to build UEF units 
---@param builder Unit The builder
---@param unitBeingBuilt Unit The unit being build
---@param buildEffectBones string[] The effect bones of the builder
---@param buildEffectsBag TrashBag The effects bag of the builder
function CreateUEFBuildSliceBeams(builder, unitBeingBuilt, buildEffectBones, buildEffectsBag)
    WaitTicks(1)

    -- always confirm after waiting!
    if IsDestroyed(unitBeingBuilt) then
        return
    end

    -- store as locals for performance
    local UnitGetFractionComplete = UnitGetFractionComplete
    local ProjectileSetVelocity = ProjectileSetVelocity
    local Warp = Warp

    local vc = VectorCached
    local army = builder.Army

    -- create a projectile for the end of build effect and warp it to the unit
    local beamEndBuilder = builder.UEFBuildProjectile
    if not beamEndBuilder then
        beamEndBuilder = EntityCreateProjectile(unitBeingBuilt, '/effects/entities/UEFBuild/UEFBuild01_proj.bp', 0, 0, 0, nil, nil, nil)
        builder.UEFBuildProjectile = beamEndBuilder
        TrashBagAdd(builder.Trash, beamEndBuilder)
    end

    -- reset the state of the projectile
    ProjectileSetVelocity(beamEndBuilder, 0)
    TrashBagAdd(buildEffectsBag, CreateEmitterOnEntity(beamEndBuilder, army, '/effects/emitters/build_terran_glow_01_emit.bp'))
    TrashBagAdd(buildEffectsBag, CreateEmitterOnEntity(beamEndBuilder, army, '/effects/emitters/build_sparks_blue_01_emit.bp'))

    -- add the build beam between the build bones and the projectile
    if buildEffectBones ~= nil then
        for _, BuildBone in buildEffectBones do
            TrashBagAdd(buildEffectsBag, AttachBeamEntityToEntity(builder, BuildBone, beamEndBuilder, -1, army, '/effects/emitters/build_beam_01_emit.bp'))
            TrashBagAdd(buildEffectsBag, CreateAttachedEmitter(builder, BuildBone, army, '/effects/emitters/flashing_blue_glow_01_emit.bp'))
        end
    end

    local x1, z1, x2, z2, y, height = CalculateUEFBuildPoints(builder, unitBeingBuilt)

    -- Determine a the velocity of our projectile, used for the scanning effect
    local velX = 2 * (x2 - x1)
    local velZ = 2 * (z2 - z1)

    local fraction = UnitGetFractionComplete(unitBeingBuilt)
    if fraction == 0 then
        vc[1], vc[2], vc[3] = (x1 + x2) * 0.5, y - height, (z1 + z2) * 0.5
        Warp(beamEndBuilder, vc)
        WaitTicks(BuildCubeDelay)
    end

    -- Warp our projectile back to the initial corner and lower based on build completeness
    local flipDirection = true
    while not (EntityBeenDestroyed(builder) or EntityBeenDestroyed(unitBeingBuilt)) do
        fraction = UnitGetFractionComplete(unitBeingBuilt)
        if flipDirection then
            vc[1], vc[2], vc[3] = x1, y - height * fraction, z1
            Warp(beamEndBuilder, vc)
            ProjectileSetVelocity(beamEndBuilder, velX, 0, velZ)
            flipDirection = false
        else
            vc[1], vc[2], vc[3] = x2, y - height * fraction, z2
            Warp(beamEndBuilder, vc)
            ProjectileSetVelocity(beamEndBuilder, -velX, 0, -velZ)
            flipDirection = true
        end
        WaitTicks(BuilderSlicePeriod)
    end
end

--- Creates the build cube used by UEF structures
---@param unitBeingBuilt Unit The unit being build
---@param builder Unit The builder (unused)
---@param onBeingBuiltEffectsBag TrashBag The Effects bag of the unit being built
function CreateBuildCubeThread(unitBeingBuilt, builder, onBeingBuiltEffectsBag)
    -- used to differentiate between using a slice beam and a default build beam
    unitBeingBuilt.BuildingCube = true
    local buildbp = unitBeingBuilt.Blueprint
    local Physics = buildbp.Physics

    -- cache information used throughout the function
    local vc = VectorCached
    local px, py, pz = EntityGetPositionXYZ(unitBeingBuilt)
    py = py + (Physics.MeshExtentsOffsetY or 0)

    local bx = Physics.MeshExtentsX or buildbp.Footprint.SizeX
    local bz = Physics.MeshExtentsZ or buildbp.Footprint.SizeZ
    local by = Physics.MeshExtentsY or buildbp.Footprint.SizeY or MathMin(bx, bz)


    -- create a quick glow effect
    local proj = EntityCreateProjectile(unitBeingBuilt, '/effects/Entities/UEFBuildEffect/UEFBuildEffect02_proj.bp', 0, 0, 0)
    EntitySetScale(proj, bx * 1.05, by * 0.2, bz * 1.05)
    WaitTicks(BuildCubeGlowDuration)

    -- always check if we're still there after waiting
    if EntityBeenDestroyed(unitBeingBuilt) then
        return
    end

    -- create the build cube
    local buildBaseEffect = EntityCreateProjectile(unitBeingBuilt, '/effects/Entities/UEFBuildEffect/UEFBuildEffect03_proj.bp', 0, 0, 0)
    TrashBagAdd(onBeingBuiltEffectsBag, buildBaseEffect)
    TrashBagAdd(unitBeingBuilt.Trash, buildBaseEffect)
    -- warp it to the build site
    vc[1], vc[2], vc[3] = px, py - by, pz
    Warp(buildBaseEffect, vc)
    -- scale it accordingly
    EntitySetScale(buildBaseEffect, bx, by, bz)
    -- it warps at y = 0 (relative to the unit), move up until the build cube completely covered the unit
    ProjectileSetVelocity(buildBaseEffect, 0, 1.4 * by, 0)
    WaitTicks(BuildCubeDelay)

    -- always check if we're still there after waiting
    if EntityBeenDestroyed(unitBeingBuilt) or EntityBeenDestroyed(buildBaseEffect) then
        return
    end
    -- build cube is where it should be
    ProjectileSetVelocity(buildBaseEffect, 0)
    -- update internal state
    UnitShowBone(unitBeingBuilt, 0, true)
    if unitBeingBuilt.HideLandBones then
        -- non-structure units that use this setup do not have the land bones function
        -- we can't upvalue this, it is a Lua function
        unitBeingBuilt:HideLandBones()
    end
    unitBeingBuilt.BeingBuiltShowBoneTriggered = true

    local lComplete = UnitGetFractionComplete(unitBeingBuilt)
    WaitSeconds(BuildCubeFirstSliceDelay)

    -- always check if we're still there after waiting
    if EntityBeenDestroyed(unitBeingBuilt) or EntityBeenDestroyed(buildBaseEffect) then
        return
    end

    -- create glow slice cuts and resize base cube
    local slice = nil
    local cComplete = UnitGetFractionComplete(unitBeingBuilt)
    while not EntityBeenDestroyed(unitBeingBuilt) and cComplete < 1.0 do
        if lComplete < cComplete and not EntityBeenDestroyed(buildBaseEffect) then
            -- create a glow effect
            local effectY = by * (1 - cComplete)
            proj = EntityCreateProjectile(
                buildBaseEffect,
                '/effects/Entities/UEFBuildEffect/UEFBuildEffect02_proj.bp',
                0, effectY, 0
            )

            TrashBagAdd(onBeingBuiltEffectsBag, proj)

            -- size the build cube and the glow effect
            slice = cComplete - lComplete
            EntitySetScale(proj, bx, by * slice, bz)
            EntitySetScale(buildBaseEffect, bx, effectY, bz)
        end

        WaitTicks(BuildCubeSlicePeriod)

        -- always check if we're still there after waiting
        if not EntityBeenDestroyed(unitBeingBuilt) then
            lComplete = cComplete
            cComplete = UnitGetFractionComplete(unitBeingBuilt)
        end
    end

    -- keep track of state on the unit itself
    unitBeingBuilt.BuildingCube = nil
end

--- Creates the UEF unit being built effects
---@param builder Unit The builder
---@param unitBeingBuilt Unit The unit being build (unused)
---@param buildEffectsBag TrashBag The effects bag of the unit being built
function CreateUEFUnitBeingBuiltEffects(builder, unitBeingBuilt, buildEffectsBag)
    local buildAttachBone = builder.Blueprint.Display.BuildAttachBone
    TrashBagAdd(buildEffectsBag, CreateAttachedEmitter(builder, buildAttachBone, builder.Army, '/effects/emitters/uef_mobile_unit_build_01_emit.bp'))
end

--- Creates the commander-like slice beams where two beams originate from the build effect bones instead of one.
--- @param builder Unit an (S)ACU
--- @param unitBeingBuilt Unit The unit being build
--- @param buildEffectBones string[] The effect bones of the builder
--- @param buildEffectsBag TrashBag The effects bag of the builder
function CreateUEFCommanderBuildSliceBeams(builder, unitBeingBuilt, buildEffectBones, buildEffectsBag)
    WaitTicks(1)
    
    -- localize for optimal access
    local Warp = Warp
    local WaitTicks = WaitTicks
    local ProjectileSetVelocity = ProjectileSetVelocity
    local UnitGetFractionComplete = UnitGetFractionComplete

    local vc = VectorCached
    local army = builder.Army

    -- create a projectiles for the end of build effect and warp it to the unit
    local beamEndBuilder = builder.UEFBuildProjectile
    if not beamEndBuilder then
        beamEndBuilder = EntityCreateProjectile(unitBeingBuilt, '/effects/entities/UEFBuild/UEFBuild01_proj.bp', 0, 0, 0, nil, nil, nil)
        builder.UEFBuildProjectile = beamEndBuilder
        TrashBagAdd(builder.Trash, beamEndBuilder)
    end

    -- second beam for the commander
    local beamEndBuilder2 = builder.UEFBuildProjectile2
    if not beamEndBuilder2 then
        beamEndBuilder2 = EntityCreateProjectile(unitBeingBuilt, '/effects/entities/UEFBuild/UEFBuild01_proj.bp', 0, 0, 0, nil, nil, nil)
        builder.UEFBuildProjectile2 = beamEndBuilder2
        TrashBagAdd(builder.Trash, beamEndBuilder2)
    end

    -- reset the state of the projectiles
    ProjectileSetVelocity(beamEndBuilder, 0)
    ProjectileSetVelocity(beamEndBuilder2, 0)
    TrashBagAdd(buildEffectsBag, CreateEmitterOnEntity(beamEndBuilder, army, '/effects/emitters/build_terran_glow_01_emit.bp'))
    TrashBagAdd(buildEffectsBag, CreateEmitterOnEntity(beamEndBuilder, army, '/effects/emitters/build_sparks_blue_01_emit.bp'))
    TrashBagAdd(buildEffectsBag, CreateEmitterOnEntity(beamEndBuilder2, army, '/effects/emitters/build_terran_glow_01_emit.bp'))
    TrashBagAdd(buildEffectsBag, CreateEmitterOnEntity(beamEndBuilder2, army, '/effects/emitters/build_sparks_blue_01_emit.bp'))

    -- add the build beams between the build bones and the projectiles
    if buildEffectBones ~= nil then
        for _, buildBone in buildEffectBones do
            TrashBagAdd(buildEffectsBag, AttachBeamEntityToEntity(builder, buildBone, beamEndBuilder, -1, army, '/effects/emitters/build_beam_01_emit.bp'))
            TrashBagAdd(buildEffectsBag, AttachBeamEntityToEntity(builder, buildBone, beamEndBuilder2, -1, army, '/effects/emitters/build_beam_01_emit.bp'))
            TrashBagAdd(buildEffectsBag, CreateAttachedEmitter(builder, buildBone, army, '/effects/emitters/flashing_blue_glow_01_emit.bp'))
        end
    end

    local x1, z1, x2, z2, y, height = CalculateUEFBuildPoints(builder, unitBeingBuilt)

    -- determine a the velocity of our projectile, used for the scanning effect
    local velX = 2 * (x2 - x1)
    local velZ = 2 * (z2 - z1)

    local fraction = UnitGetFractionComplete(unitBeingBuilt)
    if fraction == 0 then
        vc[1], vc[2], vc[3] = (x1 + x2) * 0.5, y - height, (z1 + z2) * 0.5
        Warp(beamEndBuilder, vc)
        Warp(beamEndBuilder2, vc)
        WaitTicks(BuildCubeDelay)
    end

    -- Warp our projectile back to the initial corner and lower based on build completeness
    -- CrossWire cheat, but its fair game
    local flipDirection = true
    while not (builder.Dead or unitBeingBuilt.Dead) do
        fraction = UnitGetFractionComplete(unitBeingBuilt)
        if flipDirection then
            vc[1], vc[2], vc[3] = x1, y - height * fraction, z1
            Warp(beamEndBuilder, vc)
            ProjectileSetVelocity(beamEndBuilder, velX, 0, velZ)
            vc[1], vc[3] = x2, z2
            Warp(beamEndBuilder2, vc)
            ProjectileSetVelocity(beamEndBuilder2, -velX, 0, -velZ)
            flipDirection = false
        else
            vc[1], vc[2], vc[3] = x2, y - height * fraction, z2
            Warp(beamEndBuilder, vc)
            ProjectileSetVelocity(beamEndBuilder, -velX, 0, -velZ)
            vc[1], vc[3] = x1, z1
            Warp(beamEndBuilder2, vc)
            ProjectileSetVelocity(beamEndBuilder2, velX, 0, velZ)
            flipDirection = true
        end
        WaitTicks(BuilderSlicePeriod)
    end
end

--- Calculates the build points for the UEF slicing-style build lasers
---@param builder Unit
---@param unitBeingBuilt Unit
---@return number x1, number z1 the first point
---@return number x2, number z2 the second point
---@return number y the y coord of both points
---@return number height the height of the build size
function CalculateUEFBuildPoints(builder, unitBeingBuilt)
    local buildbp = unitBeingBuilt.Blueprint
    local Physics = buildbp.Physics
    -- determine beam positioning on build cube, this should match sizes of CreateBuildCubeThread
    local sx = Physics.MeshExtentsX or buildbp.Footprint.SizeX
    local sz = Physics.MeshExtentsZ or buildbp.Footprint.SizeZ
    sx = sx * 0.5
    sz = sz * 0.5
    local sy = Physics.MeshExtentsY or buildbp.Footprint.SizeY or MathMin(sx, sz)
    local x, y, z = EntityGetPositionXYZ(unitBeingBuilt)
    y = y + (Physics.MeshExtentsOffsetY or 0)

    local x1, z1, x2, z2

    -- determine direction to builder
    local px, _, pz = EntityGetPositionXYZ(builder)
    local dcpx = px - x
    local dcpzsz = (pz - z) * sz

    -- south west / north east comparison

    local dot = dcpzsz - sx * dcpx
    -- if this dot product is positive, then the engineer is closer to a than it is to b
    if dot > 0 then
        x1 = x - sx
        z1 = z + sz
    else
        x1 = x + sx
        z1 = z - sz
    end

    -- north west / south east comparison

    -- if this dot product is positive, then the engineer is closer to a than it is to b
    if dot - 2 * dcpzsz > 0 then
        x2 = x - sx
        z2 = z - sz
    else
        x2 = x + sx
        z2 = z + sz
    end

    -- the two vectors that represent the points
    -- (x1, y+sy, z1)
    -- (x2, y+sy, z2)
    return x1, z1, x2, z2, y + sy, sy
end