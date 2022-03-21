
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

local EntityCreateProjectile = _G.moho.entity_methods.CreateProjectile
local UnitGetPositionXYZ = _G.moho.unit_methods.GetPositionXYZ
local UnitGetFractionComplete = _G.moho.unit_methods.GetFractionComplete
local ProjectileSetVelocity = _G.moho.projectile_methods.SetVelocity

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
    local ox, oy, oz = UnitGetPositionXYZ(unitBeingBuilt)

    -- allocation of entity
    local BeamEndEntity = Entity()
    TrashAdd(buildEffectsBag, BeamEndEntity)

    vc[1] = ox 
    vc[2] = oy 
    vc[3] = oz
    Warp(BeamEndEntity, vc)

    -- Create build beams
    if buildEffectBones ~= nil then
        local beamEffect = nil
        for i, BuildBone in buildEffectBones do
            local beamEffect = AttachBeamEntityToEntity(builder, BuildBone, BeamEndEntity, -1, builder.Army, '/effects/emitters/build_beam_01_emit.bp')
            TrashAdd(buildEffectsBag, beamEffect)
        end
    end

    CreateEmitterOnEntity(BeamEndEntity, builder.Army, '/effects/emitters/sparks_08_emit.bp')

    local Warp = Warp 
    local CoroutineYield = CoroutineYield

    local waitTime = Random(3, 15)
    while not (builder.Dead or unitBeingBuilt.Dead) do
        local x, y, z = builder.GetRandomOffset(unitBeingBuilt, 1)

        -- use orientation

        vc[1] = ox + x
        vc[2] = oy + y
        vc[3] = oz + z 

        Warp(BeamEndEntity, vc)
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

    local buildbp = unitBeingBuilt.Blueprint
    local cx, cy, cz = UnitGetPositionXYZ(unitBeingBuilt)
    cy = cy + (buildbp.Physics.MeshExtentsOffsetY or 0)

    -- Create a projectile for the end of build effect and warp it to the unit
    local BeamEndEntity = EntityCreateProjectile(unitBeingBuilt, '/effects/entities/UEFBuild/UEFBuild01_proj.bp', 0, 0, 0, nil, nil, nil)
    
    TrashAdd(buildEffectsBag, BeamEndEntity)

    -- Create build beams
    if buildEffectBones ~= nil then
        for i, BuildBone in buildEffectBones do
            TrashAdd(buildEffectsBag, AttachBeamEntityToEntity(builder, BuildBone, BeamEndEntity, -1, builder.Army, '/effects/emitters/build_beam_01_emit.bp'))
            TrashAdd(buildEffectsBag, CreateAttachedEmitter(builder, BuildBone, builder.Army, '/effects/emitters/flashing_blue_glow_01_emit.bp'))
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
    ex, ey, ez = UnitGetPositionXYZ(builder)
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

    -- (fx1, fy, fz1)
    -- (fx2, fy, fz2)

    -- Determine a the velocity of our projectile, used for the scanning effect
    local velX = 2 * (fx2 - fx1)
    local velZ = 2 * (fz2 - fz1)

    if UnitGetFractionComplete(unitBeingBuilt) == 0 then
        vc[1] = (fx1 + fx2) * 0.5
        vc[2] = fy - oy
        vc[3] = (fz1 + fz2) * 0.5
        Warp(BeamEndEntity, vc)
        CoroutineYield(8)
    end

    -- store as locals for performance
    local UnitGetFractionComplete = UnitGetFractionComplete
    local ProjectileSetVelocity = ProjectileSetVelocity
    local Warp = Warp

    -- Warp our projectile back to the initial corner and lower based on build completeness
    local flipDirection = true
    while not (builder.Dead or unitBeingBuilt.Dead) do
        if flipDirection then
            vc[1] = fx1
            vc[2] = (fy - (oy * UnitGetFractionComplete(unitBeingBuilt)))
            vc[3] = fz1
            Warp(BeamEndEntity, vc)
            ProjectileSetVelocity(BeamEndEntity, velX, 0, velZ)
            flipDirection = false
        else
            vc[1] = fx2
            vc[2] = (fy - (oy * UnitGetFractionComplete(unitBeingBuilt)))
            vc[3] = fz2
            Warp(BeamEndEntity, vc)
            ProjectileSetVelocity(BeamEndEntity, -velX, 0, -velZ)
            flipDirection = true
        end
        CoroutineYield(6)
    end
end