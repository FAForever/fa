
-- cache for performance
local util = import("/lua/utilities.lua")
local Entity = import("/lua/sim/entity.lua").Entity
local ReclaimObjectAOE = import("/lua/effecttemplates.lua").ReclaimObjectAOE
local ReclaimBeams = import("/lua/effecttemplates.lua").ReclaimBeams
local ReclaimObjectEnd = import("/lua/effecttemplates.lua").ReclaimObjectEnd

-- upvalue for performance
local AttachBeamEntityToEntity = AttachBeamEntityToEntity
local CreateEmitterAtBone = CreateEmitterAtBone
local CreateEmitterAtEntity = CreateEmitterAtEntity
local CreateEmitterOnEntity = CreateEmitterOnEntity
local CreateLightParticleIntel = CreateLightParticleIntel
local Random = Random
local Warp = Warp

local TableGetn = table.getn
local UtilGetRandomInt = util.GetRandomInt
local UtilGetRandomOffset = util.GetRandomOffset

local IEffectSetEmitterCurveParam = moho.IEffect.SetEmitterCurveParam
local IEffectOffsetEmitter = moho.IEffect.OffsetEmitter
local TrashBagAdd = TrashBag.Add


--- Creates all effects in a table at an entity.
--- It does not return a table with all of the effects.
--- Call `CreateEffectsInTrashbag` if you'd like to capture them.
---@param obj Entity
---@param army integer
---@param effectTable string[] Emitter blueprint names
function CreateEffectsOpti(obj, army, effectTable)
    for _, effect in effectTable do
        CreateEmitterAtEntity(obj, army, effect)
    end
end

--- Creates all effects in a table at an entity and adds them to a trashbag.
--- Call `CreateEffectsOpti` if you don't need the effects for later.
---@param obj Entity | Unit
---@param army integer
---@param effectTable string[] Emitter blueprint names
---@param trashbag TrashBag
function CreateEffectsInTrashbag(obj, army, effectTable, trashbag)
    for _, effect in effectTable do
        TrashBagAdd(trashbag, CreateEmitterAtEntity(obj, army, effect))
    end
end

--- Creates all effects in a table, with an offset from an entity.
--- It does not return a table with all of the effects.
--- Call `CreateEffectsWithOffsetInTrashbag` if you'd like to capture them.
---@param obj Entity | Unit
---@param army integer
---@param effectTable string[] Emitter blueprint names
---@param x number
---@param y number
---@param z number
function CreateEffectsWithOffsetOpti(obj, army, effectTable, x, y, z)
    for _, effect in effectTable  do
        IEffectOffsetEmitter(CreateEmitterAtEntity(obj, army, effect), x, y, z)
    end
end

--- Creates all effects in a table, with an offset from an entity, and adds them
--- to a trashbag.
--- Call `CreateEffectsWithOffsetOpti` if you don't need the effects for later.
---@param obj Entity
---@param army integer
---@param effectTable string[] Emitter blueprint names
---@param x number
---@param y number
---@param z number
---@param trashbag TrashBag
function CreateEffectsWithOffsetInTrashbag(obj, army, effectTable, x, y, z, trashbag)
    for _, effect in effectTable  do
        TrashBagAdd(trashbag, IEffectOffsetEmitter(CreateEmitterAtEntity(obj, army, effect), x, y, z))
    end
end

--- Creates all effects in a table, with random offsets from an entity.
--- It does not return a table with all of the effects.
--- Call `CreateEffectsWithRandomOffsetInTrashbag` if you'd like to capture them.
---@param obj Entity | Unit
---@param army integer
---@param effectTable string[] Emitter blueprint names
---@param xRange number
---@param yRange number
---@param zRange number
function CreateEffectsWithRandomOffsetOpti(obj, army, effectTable, xRange, yRange, zRange)
    for _, effect in effectTable do
        IEffectOffsetEmitter(CreateEmitterOnEntity(obj, army, effect), UtilGetRandomOffset(xRange, yRange, zRange, 1))
    end
end

--- Creates all effects in a table, with random offsets from an entity, and adds them
--- to a trashbag.
--- Call `CreateEffectsWithRandomOffsetOpti` if you don't need the effects for later.
---@param obj Entity | Unit
---@param army integer
---@param effectTable string[] Emitter blueprint names
---@param xRange number
---@param yRange number
---@param zRange number
---@param trashbag TrashBag
function CreateEffectsWithRandomOffsetInTrashbag(obj, army, effectTable, xRange, yRange, zRange, trashbag)
    for _, effect in effectTable do
        TrashBagAdd(trashbag, IEffectOffsetEmitter(CreateEmitterOnEntity(obj, army, effect), UtilGetRandomOffset(xRange, yRange, zRange, 1)))
    end
end

--- Creates all effects in a table at an entity's bone.
--- It does not return a table with all of the effects.
--- Call `CreateBoneEffectsInTrashbag` if you'd like to capture them.
---@param obj Entity | Unit
---@param bone string | number
---@param army integer
---@param effectTable string[] Emitter blueprint names
function CreateBoneEffectsOpti(obj, bone, army, effectTable)
    for _, effect in effectTable do
        CreateEmitterAtBone(obj, bone, army, effect)
    end
end

--- Creates all effects in a table at an entity's bone, and adds them
--- to a trashbag.
--- Call `CreateBoneEffectsOpti` if you don't need the effects for later.
---@param obj Entity
---@param bone string | number
---@param army integer
---@param effectTable string[] Emitter blueprint names
---@param trashbag TrashBag
function CreateBoneEffectsInTrashbag(obj, bone, army, effectTable, trashbag)
    for _, effect in effectTable do
        TrashBagAdd(trashbag, CreateEmitterAtBone(obj, bone, army, effect))
    end
end

--- Creates all effects in a table at an entity's bone, with offset.
--- It does not return a table with all of the effects.
--- Call `CreateBoneEffectsOffsetInTrashbag` if you'd like to capture them.
---@param obj Entity | Unit
---@param bone string | number
---@param army integer
---@param effectTable string[] Emitter blueprint names
---@param x number
---@param y number
---@param z number
function CreateBoneEffectsOffsetOpti(obj, bone, army, effectTable, x, y, z)
    for _, effect in effectTable do
        IEffectOffsetEmitter(CreateEmitterAtBone(obj, bone, army, effect), x, y, z)
    end
end

--- Creates all effects in a table at an entity's bone, with offset, and adds them
--- to a trashbag.
--- Call `CreateBoneEffectsOffsetOpti` if you don't need the effects for later.
---@param obj Entity | Unit
---@param bone string | number
---@param army integer
---@param effectTable string[] Emitter blueprint names
---@param x number
---@param y number
---@param z number
---@param trashbag TrashBag
function CreateBoneEffectsOffsetInTrashbag(obj, bone, army, effectTable, x, y, z, trashbag)
    for _, effect in effectTable do
        TrashBagAdd(trashbag, IEffectOffsetEmitter(CreateEmitterAtBone(obj, bone, army, effect), x, y, z))
    end
end

--- Creates a number of random effects out of a table at an entity.
--- It does not return a table with all of the effects.
--- Call `CreateRandomEffectsInTrashbag` if you'd like to capture them.
---@param obj Entity | Unit
---@param army integer
---@param effectTable string[] Emitter blueprint names
---@param numEffects integer number of random effects to create
function CreateRandomEffectsOpti(obj, army, effectTable, numEffects)
    local numTableEntries = TableGetn(effectTable)
    for _ = 1, numEffects do
        CreateEmitterOnEntity(obj, army, effectTable[UtilGetRandomInt(1, numTableEntries)])
    end
end

--- Creates a number of random effects out of a table at an entity, and adds them
--- to a trashbag.
--- Call `CreateRandomEffectsOpti` if you don't need the effects for later.
---@param obj Entity | Unit
---@param army integer
---@param effectTable string[] Emitter blueprint names
---@param numEffects integer number of random effects to create
---@param trashbag TrashBag
function CreateRandomEffectsInTrashbag(obj, army, effectTable, numEffects, trashbag)
    local numTableEntries = TableGetn(effectTable)
    for _ = 1, numEffects do
        TrashBagAdd(trashbag, CreateEmitterOnEntity(obj, army, effectTable[UtilGetRandomInt(1, numTableEntries)]))
    end
end

--- Played when reclaiming starts.
---@param reclaimer Unit Unit that is reclaiming
---@param reclaimed Unit | Prop Unit / prop that is being reclaimed
---@param buildEffectBones string[] Bones of the reclaimer to create beams from towards the reclaimed
---@param effectsBag TrashBag Trashbag that stores the effects
function PlayReclaimEffects(reclaimer, reclaimed, buildEffectBones, effectsBag)
    -- cache army
    local army = reclaimer.Army

    -- find reclaim end point
    local reclaimEndpoint = reclaimer.ReclaimEndpoint
    if not reclaimEndpoint then
        reclaimEndpoint = Entity()
        reclaimer.ReclaimEndpoint = reclaimEndpoint
        TrashBagAdd(reclaimer.Trash, reclaimEndpoint)
    end

    -- move end point
    Warp(reclaimEndpoint, reclaimed:GetPosition())

    -- create beams
    for _, bone in buildEffectBones do
        for _, effect in ReclaimBeams do
            TrashBagAdd(effectsBag, AttachBeamEntityToEntity(reclaimer, bone, reclaimEndpoint, -1, army, effect))
        end
    end

    -- create particle effects
    for _, effect in ReclaimObjectAOE do
        TrashBagAdd(effectsBag, CreateEmitterOnEntity(reclaimEndpoint, army, effect))
    end
end

--- Played when reclaiming has been completed.
---@param reclaimer Unit Unit that is reclaiming
---@param reclaimed Unit | Prop Unit / prop that is reclaimed
function PlayReclaimEndEffects(reclaimer, reclaimed)
    -- cache army of reclaiming unit
    army = reclaimer.Army or -1

    -- create particle effects
    for _, effect in ReclaimObjectEnd do
        CreateEmitterAtEntity(reclaimed, army, effect)
    end

    -- create light effect
    CreateLightParticleIntel(reclaimed, -1, army, 4, 6, 'glow_02', 'ramp_flare_02')
end

--- Applies the wind direction to an emitter.
---@param emitter moho.IEffect Emitter to apply the wind direction to
---@param factor number
function ApplyWindDirection(emitter, factor)
    factor = factor * 0.01
    local r = factor * (1 + Random())
    IEffectSetEmitterCurveParam(emitter, "XDIR_CURVE", factor, r)
    IEffectSetEmitterCurveParam(emitter, "YDIR_CURVE", factor * 0.25, factor * (0.5 + Random()))
    IEffectSetEmitterCurveParam(emitter, "ZDIR_CURVE", factor, r)
end
