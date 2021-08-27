
-- imports for functionality
local Entity = import('/lua/sim/Entity.lua').Entity
local EffectTemplate = import('/lua/EffectTemplates.lua')

-- upvalued cache - do not use after waiting
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
local EntityGetPosition = moho.entity_methods.GetPosition
local EntityBeenDestroyed = moho.entity_methods.BeenDestroyed
local EntityGetPositionXYZ = moho.entity_methods.GetPositionXYZ
local EntityGetOrientation = moho.entity_methods.GetOrientation

local UnitRevertElevation = moho.unit_methods.RevertElevation

-- math functions as upvalues for performance
local MathPi = math.pi
local MathSin = math.sin 
local MathCos = math.cos

-- upvalued trashbag functions for performance
local TrashBag = _G.TrashBag
local TrashBagAdd = TrashBag.Add

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
-- the builder.BuildBotTotal value to be set.
-- @param builder A cybran builder such as an engineer, hive or commander.
-- @param botBlueprint The blueprint to use for the bot.
function SpawnBuildBots(builder)

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

        -- make it weak so that the garbage collection can clean up the table when the unit is destroyed
        setmetatable(builder.BuildBots, { __mode = "v" })

        bots = builder.BuildBots
    end

    -- get information about the builder
    local x, y, z = EntityGetPositionXYZ(builder)
    local q = EntityGetOrientation(builder)
    local qx, qy, qz, qw = q[1], q[2], q[3], q[4]

    -- prepare information required to make bots
    local angleInitial = 180
    local VecMul = 0.5
    local xVec = 0
    local yVec = 0.1
    local zVec = 0
    local angle = (2 * MathPi) / builder.BuildBotTotal

    -- go over all the bots and see which ones we're missing
    local builderArmy = builder.Army
    for k = 1, builder.BuildBotTotal do 

        -- check if the bot stil exists
        local bot = bots[k]
        if not bot or EntityBeenDestroyed(bot) then 

            -- get a random direction for the bot
            xVec = MathSin(angleInitial + (k * angle)) * VecMul
            zVec = MathCos(angleInitial + (k * angle)) * VecMul

            -- make the bot
            local botBlueprint = CybranBuildBotBlueprints[k] or 'ura0001o'
            bot = CreateUnit(botBlueprint, builderArmy, x + xVec, y + yVec, z + zVec, qx, qy, qz, qw, 'Air')

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
            local bot = bots[k]
            UnitRevertElevation(bot)
        end

        -- clear up commands and guard (assist) structure
        IssueClearCommands(bots)
        IssueGuard(bots, focus)
    end
end

-- add as upvalue for performance for CreateCybranBuildBeamsOpti
local BeamBuildEmtBp = '/effects/emitters/build_beam_02_emit.bp'
local CybranBuildSparks01 = EffectTemplate.CybranBuildSparks01
local CybranBuildFlash01 = EffectTemplate.CybranBuildFlash01

--- Creates the beams and welding points of the builder and its bots. The
-- bots share the welding point which each other, as does the builder with
-- itself.
-- @param builder A builder with builder.BuildEffectBones set. 
-- @param bots The bots of the builder.
-- @param unitBeingBuilt The unit that we're building.
-- @param buildEffectsBag The bag that we use to store / trash all effects.
-- @param stationary Whether or not the builder is a building.
function CreateCybranBuildBeams(builder, bots, unitBeingBuilt, buildEffectsBag, stationary)

    -- delay slightly for dramatic effect
    WaitTicks(2 + Random(1, 4))

    -- early out - make sure everything is still alive
    if builder.Dead or unitBeingBuilt.Dead then 
        return 
    end

    -- initialise   
    local army = builder.Army
    local trash = builder.Trash 
    local origin = EntityGetPosition(unitBeingBuilt)

    -- create beam entities and their emiters
    local beamEndBuilder

    -- hives do not have beams from builders
    if not stationary then 
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
    if not stationary then 
        if builder.BuildEffectBones then 
            for k, bone in builder.BuildEffectBones do 
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
    local blueprint = unitBeingBuilt:GetBlueprint()

    -- cache values for computing random offsets
    local vc = VectorCached
    local cy = blueprint.CollisionOffsetY or 0
    local sx, sy, sz = blueprint.SizeX, blueprint.SizeY, blueprint.SizeZ
    local r1, r2, r3 

    -- perform the build animation
    while not (builder.Dead or unitBeingBuilt.Dead) do

        -- get a few random numbers
        r1, r2, r3 = Random(), Random(), Random()

        -- get a new location for builder
        if not stationary then 
            vc[1] = ox + r1 * sx - (sx * 0.5)
            vc[2] = oy + r2 * sy + cy
            vc[3] = oz + r3 * sz - (sz * 0.5)
            Warp(beamEndBuilder, vc)
        end

        -- get a new location for bots
        vc[1] = ox + r2 * sx - (sx * 0.5)
        vc[2] = oy + r3 * sy + cy
        vc[3] = oz + (1 - r1) * sz - (sz * 0.5)
        Warp(beamEndBots, vc)

        -- skip a few ticks to make the effect work better
        WaitTicks(3)
    end
end

--- Creates tracker beams between the builder and its build bots. The
-- bots keep the tracker in their trashbag.
-- @param builder The builder / tracking entity of the build bots.
-- @param buildBones The bones to use as the origin of the beams.
-- @param buildBots The build bots that we're tracking.
-- @param total The number of build bots / bones. The 1st bone will track the 1st bot, etc.
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

-- AEON SPECIFICS --

function CreateAeonBuildBaseThread(unitBeingBuilt, builder, effectsBag)

end