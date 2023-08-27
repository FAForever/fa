-- imports for functionality
local Entity = import("/lua/sim/entity.lua").Entity
local EffectTemplate = import("/lua/effecttemplates.lua")

-- globals as upvalues for performance
local AttachBeamEntityToEntity = AttachBeamEntityToEntity
local CreateEmitterOnEntity = CreateEmitterOnEntity
local CreateUnit = CreateUnit
local IssueClearCommands = IssueClearCommands
local IssueGuard = IssueGuard
local KillThread = KillThread
local Random = Random
local WaitTicks = WaitTicks
local Warp = Warp
local setmetatable = setmetatable
local unpack = unpack

local MathTau = 2 * math.pi
local MathSin = math.sin
local MathSqrt = math.sqrt
local BeamBuildEmtBp = '/effects/emitters/build_beam_02_emit.bp'
local CybranBuildSparks01 = EffectTemplate.CybranBuildSparks01
local CybranBuildFlash01 = EffectTemplate.CybranBuildFlash01

local EntityGetPosition = moho.entity_methods.GetPosition
local EntityBeenDestroyed = moho.entity_methods.BeenDestroyed
local EntityGetPositionXYZ = moho.entity_methods.GetPositionXYZ
local EntityGetOrientation = moho.entity_methods.GetOrientation
local UnitRevertElevation = moho.unit_methods.RevertElevation
local TrashBagAdd = TrashBag.Add


-- upvalued cached vector. Prevents various table allocations
-- throughout the code. Use carefully: the state of the vector
-- is different after a wait because another function can have
-- used it in between.
local VectorCached = Vector(0, 0, 0)

-- CYBRAN SPECIFICS --

-- all possible bot blueprint values
local CybranBuildBotBlueprints = {
    'ura0001o',
    'ura0002o',
    'ura0003o',
    -- 'ura0004'
}

local CybranBuildBotBeams = {
    '/effects/emitters/build_bot_beam_01_emit.bp',
    '/effects/emitters/build_bot_beam_02_emit.bp',
    '/effects/emitters/build_bot_beam_03_emit.bp',
}

--- Creates the build drones for the (cybran) builder in question. Expects
--- the builder.BuildBotTotal value to be set.
---@param builder Unit A Cybran builder such as an engineer, hive or commander
function SpawnBuildBots(builder, botBlueprintId, botBone)

    -- kill potential return thread
    if builder.ReturnBotsThreadInstance then
        KillThread(builder.ReturnBotsThreadInstance)
        builder.ReturnBotsThreadInstance = nil
    end

    -- initialisation block
    -- if there have been no bots before then prepare data to have bots
    local bots = builder.BuildBots
    if not bots then
        builder.BuildBotsNext = 1
        builder.BuildBots = { }
        bots = builder.BuildBots

        -- make it weak so that the garbage collection can clean up the table when the unit is destroyed
        setmetatable(bots, { __mode = "v" })
    end

    -- get information about the builder
    local x, y, z = EntityGetPositionXYZ(builder, botBone or -1)
    y = y + 0.1
    local qx, qy, qz, qw = unpack(EntityGetOrientation(builder))

    -- prepare information required to make bots
    local angle = 180
    local vecMul = 0.5
    local xVec = 0
    local zVec = 0
    local angleChange = MathTau / builder.BuildBotTotal

    -- go over all the bots and see which ones we're missing
    local builderArmy = builder.Army
    for k = 1, builder.BuildBotTotal do
        -- check if the bot stil exists
        local bot = bots[k]
        if not bot or EntityBeenDestroyed(bot) then
            -- get a random direction for the bot
            angle = angle + angleChange
            xVec = MathSin(angle)
            zVec = MathSqrt(1 - xVec*xVec)

            -- make the bot
            local botBlueprint = botBlueprintId or CybranBuildBotBlueprints[k] or 'ura0001o'
            bot = CreateUnit(botBlueprint, builderArmy, x + xVec * vecMul, y, z + zVec * vecMul, qx, qy, qz, qw, 'Air')

            -- make build bots unkillable
            bot.SpawnedBy = builder

            -- store the bot
            bots[k] = bot
            builder.BuildBotsNext = builder.BuildBotsNext + 1
        end
    end

    -- make the drones focus builder target
    local focus = builder:GetFocusUnit()

    -- focus may be nil if we got paused and building is finished
    if focus then
        for k = 1, builder.BuildBotTotal do
            -- revert drone elevation to blueprint value
            UnitRevertElevation(bots[k])
        end

        -- clear up commands and guard (assist) structure
        IssueClearCommands(bots)
        IssueGuard(bots, focus)
    end
end

--- Creates the beams and welding points of the builder and its bots. The
--- bots share the welding point which each other, as does the builder with
--- itself.
---@param builder Unit A builder with builder.buildEffectBones set
---@param bots Unit[] The bots of the builder
---@param unitBeingBuilt Unit The unit that we're building
---@param buildEffectsBag TrashBag The bag that we use to store / trash all effects
---@param noBuilderBeams boolean Whether or not the builder is a building
function CreateCybranBuildBeams(builder, bots, unitBeingBuilt, buildEffectsBag, noBuilderBeams)
    -- delay slightly for dramatic effect
    WaitTicks(2 + Random(1, 4))

    -- early out - make sure everything is still alive
    if builder.Dead or (not unitBeingBuilt) or unitBeingBuilt.Dead then
        return
    end

    -- initialise
    local army = builder.Army
    local trash = builder.Trash
    local origin = EntityGetPosition(unitBeingBuilt)

    -- create beam entities and their emiters
    local beamEndBuilder

    -- hives do not have beams from builders
    if not noBuilderBeams then
        beamEndBuilder = builder.BeamEndBuilder or Entity()
        builder.BeamEndBuilder = beamEndBuilder
        Warp(beamEndBuilder, origin)
        TrashBagAdd(buildEffectsBag, CreateEmitterOnEntity(beamEndBuilder, army, CybranBuildSparks01))
        TrashBagAdd(buildEffectsBag, CreateEmitterOnEntity(beamEndBuilder, army, CybranBuildFlash01))
        TrashBagAdd(trash, beamEndBuilder)
    end

    local beamEndBots = builder.BeamEndBots or Entity()
    builder.BeamEndBots = beamEndBots
    Warp(beamEndBots, origin)
    TrashBagAdd(buildEffectsBag, CreateEmitterOnEntity(beamEndBots, army, CybranBuildSparks01))
    TrashBagAdd(buildEffectsBag, CreateEmitterOnEntity(beamEndBots, army, CybranBuildFlash01))
    TrashBagAdd(trash, beamEndBots)

    -- create a beam from each build effect bone of the builder
    if not noBuilderBeams then
        if builder.BuildEffectBones then
            for _, bone in builder.BuildEffectBones do
                TrashBagAdd(buildEffectsBag, AttachBeamEntityToEntity(builder, bone, beamEndBuilder, -1, army, BeamBuildEmtBp))
            end
        end
    end

    -- create a beam from each bot of the builder
    if bots then
        for k, bot in bots do
            local beam = CybranBuildBotBeams[k] or BeamBuildEmtBp
            TrashBagAdd(buildEffectsBag, AttachBeamEntityToEntity(bot, "Muzzle_01", beamEndBots, -1, army, beam))
        end
    end

    -- make the end entity move around
    local ox, oy, oz = origin[1], origin[2], origin[3]
    local blueprint = unitBeingBuilt.Blueprint

    -- cache values for computing random offsets
    local vc = VectorCached
    oy = oy + (blueprint.CollisionOffsetY or 0)
    local sx, sy, sz = blueprint.SizeX, blueprint.SizeY, blueprint.SizeZ

    -- perform the build animation
    while not (builder.Dead or unitBeingBuilt.Dead) do

        -- get a few random numbers
        local r1, r2, r3 = Random(), Random(), Random()

        -- get a new location for builder
        if not noBuilderBeams then
            vc[1] = ox + (r1 - 0.5) * sx
            vc[2] = oy + r2 * sy
            vc[3] = oz + (r3 - 0.5) * sz
            Warp(beamEndBuilder, vc)
        end

        -- get a new location for bots
        vc[1] = ox + (r2 - 0.5) * sx
        vc[2] = oy + r3 * sy
        vc[3] = oz + (0.5 - r1) * sz
        Warp(beamEndBots, vc)

        -- skip a few ticks to make the effect work better
        WaitTicks(3)
    end
end

--- Creates tracker beams between the builder and its build bots. The
--- bots keep the tracker in their trashbag.
---@param builder Unit The builder / tracking entity of the build bots
---@param buildBones string[] The bones to use as the origin of the beams
---@param buildBots Unit[] The build bots that we're tracking
---@param total number The number of build bots / bones. The 1st bone will track the 1st bot, etc.
function CreateCybranEngineerBuildEffects(builder, buildBones, buildBots, total)
    local army = builder.Army
    for k = 1, total do
        local bone = buildBones[k]
        local bot = buildBots[k]
        if bone and bot and not bot.Tracked then
            bot.Tracked = true
            TrashBagAdd(bot.Trash, AttachBeamEntityToEntity(builder, bone, bot, -1, army, '/effects/emitters/build_beam_03_emit.bp'))
        end
    end
end