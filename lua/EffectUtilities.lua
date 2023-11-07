-----------------------------------------------------------------
-- File     :  /lua/EffectUtilities.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Effect Utility functions for scripts.
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local util = import("/lua/utilities.lua")
local Entity = import("/lua/sim/entity.lua").Entity
local EffectTemplate = import("/lua/effecttemplates.lua")

local AttachBeamEntityToEntity = AttachBeamEntityToEntity
local CreateAttachedEmitter = CreateAttachedEmitter
local CreateEmitterAtBone = CreateEmitterAtBone
local CreateEmitterAtEntity = CreateEmitterAtEntity
local CreateEmitterOnEntity = CreateEmitterOnEntity
local GetTerrainHeight = GetTerrainHeight
local GetTerrainTypeOffset = GetTerrainTypeOffset
local Warp = Warp
local unpack = unpack

local MathAbs = math.abs
local MathCeil = math.ceil
local MathPow = math.pow
local MathMax = math.max
local MathMin = math.min
local MathSin = math.sin
local MathSqrt = math.sqrt
local mathTau = 2 * math.pi
local TableCopy = table.copy
local TableEmpty = table.empty
local TableGetn = table.getn
local TableGetsize = table.getsize
local TableInsert = table.insert
local UtilCross = util.Cross
local UtilGetDifferenceVector = util.GetDifferenceVector
local UtilGetDirectionVector = util.GetDirectionVector
local UtilGetDistanceBetweenTwoVectors = util.GetDistanceBetweenTwoVectors
local UtilGetMidPoint = util.GetMidPoint
local UtilGetRandomInt = util.GetRandomInt
local UtilGetRandomFloat = util.GetRandomFloat
local UtilGetRandomOffset = util.GetRandomOffset
local UtilGetScaledDirectionVector = util.GetScaledDirectionVector

local IEffectOffsetEmitter = moho.IEffect.OffsetEmitter
local IEffectScaleEmitter = moho.IEffect.ScaleEmitter
local IEffectSetEmitterCurveParam = moho.IEffect.SetEmitterCurveParam
local IEffectSetEmitterParam = moho.IEffect.SetEmitterParam
local TrashBagAdd = TrashBag.Add

-- local DeprecatedWarnings = { }

---@alias AdjacencyBeam {Unit: Unit, Trash: TrashBag}


---@deprecated
--- Creates all effects in a table at an entity
---@param obj BoneObject
---@param army Army
---@param effectTable FileName[] Emitter blueprint names
---@return moho.IEffect[] emitters
function CreateEffects(obj, army, effectTable)
    local emitters = {}
    for i, effect in effectTable do
        emitters[i] = CreateEmitterAtEntity(obj, army, effect)
    end
    return emitters
end

---@deprecated
--- Creates all effects in a table, with an offset from an entity
---@param obj BoneObject
---@param army number
---@param effectTable FileName[] Emitter blueprint names
---@param x number
---@param y number
---@param z number
---@return moho.IEffect[] emitters
function CreateEffectsWithOffset(obj, army, effectTable, x, y, z)
    local emitters = {}
    for i, effect in effectTable  do
        emitters[i] = IEffectOffsetEmitter(CreateEmitterAtEntity(obj, army, effect), x, y, z)
    end
    return emitters
end

---@deprecated
--- Creates all effects in a table, with random offsets from an entity
---@param obj BoneObject
---@param army number
---@param effectTable FileName[] Emitter blueprint names
---@param xRange number
---@param yRange number
---@param zRange number
---@return moho.IEffect[] emitters
function CreateEffectsWithRandomOffset(obj, army, effectTable, xRange, yRange, zRange)
    local emitters = {}
    for i, effect in effectTable do
        emitters[i] = IEffectOffsetEmitter(CreateEmitterOnEntity(obj, army, effect), UtilGetRandomOffset(xRange, yRange, zRange, 1))
    end
    return emitters
end

---@deprecated
--- Creates all effects in a table at an entity's bone
---@param obj BoneObject
---@param bone Bone
---@param army number
---@param effectTable FileName[] Emitter blueprint names
---@return moho.IEffect[] emitters
function CreateBoneEffects(obj, bone, army, effectTable)
    local emitters = {}
    for i, effect in effectTable do
        emitters[i] = CreateEmitterAtBone(obj, bone, army, effect)
    end
    return emitters
end

---@deprecated
--- Creates all effects in a table at an entity's bone, with offset
---@param obj BoneObject
---@param bone Bone
---@param army number
---@param effectTable FileName[] Emitter blueprint names
---@param x number
---@param y number
---@param z number
---@return moho.IEffect[] emitters
function CreateBoneEffectsOffset(obj, bone, army, effectTable, x, y, z)
    local emitters = {}
    for i, effect in effectTable do
        emitters[i] = IEffectOffsetEmitter(CreateEmitterAtBone(obj, bone, army, effect), x, y, z)
    end
    return emitters
end

--- Creates all effects in a table at each bone in a table for an entity
---@param obj BoneObject
---@param boneTable Bone[]
---@param army number
---@param effectTable FileName[] Emitter blueprint names
function CreateBoneTableEffects(obj, boneTable, army, effectTable)
    for _, bone in boneTable do
        for _, effect in effectTable do
            CreateEmitterAtBone(obj, bone, army, effect)
        end
    end
end

--- Creates all effects in a table at each bone in a table for an entity
---@param obj BoneObject
---@param boneTable Bone[]
---@param effectTable FileName[] Emitter blueprint names
---@param army number
---@param min number
---@param max number
function CreateBoneTableRangedScaleEffects(obj, boneTable, effectTable, army, min, max)
    for _, bone in boneTable do
        for _, effect in effectTable do
            IEffectScaleEmitter(CreateEmitterAtBone(obj, bone, army, effect), UtilGetRandomFloat(min, max))
        end
    end
end

---@deprecated
--- Creates a number of random effects out of a table at an entity
---@param obj BoneObject
---@param army number
---@param effectTable FileName[] Emitter blueprint names
---@param numEffects integer
---@return moho.IEffect[] emitters
function CreateRandomEffects(obj, army, effectTable, numEffects)
    local numTableEntries = TableGetn(effectTable)
    local emitters = {}
    for i = 1, numEffects do
        emitters[i] = CreateEmitterOnEntity(obj, army, effectTable[UtilGetRandomInt(1, numTableEntries)])
    end
    return emitters
end

--- Sets the param of each effect to a random ranged float
---@param emitters moho.IEffect[]
---@param param string
---@param minRange number
---@param maxRange number
function ScaleEmittersParam(emitters, param, minRange, maxRange)
    for _, emitter in emitters do
        IEffectSetEmitterParam(emitter, param, UtilGetRandomFloat(minRange, maxRange))
    end
end

---@deprecated
--- You can use `CreateCybranBuildBeamsOpti` instead
---@param builder Unit
---@param unitBeingBuilt Unit
---@param buildEffectBones Bone[]
---@param buildEffectsBag TrashBag
function CreateCybranBuildBeams(builder, unitBeingBuilt, buildEffectBones, buildEffectsBag)
    WaitSeconds(0.2)
    local beamEndEntities = {}
    local ox, oy, oz = unpack(unitBeingBuilt:GetPosition())
    local army = builder.Army
    local trash = builder.Trash

    if buildEffectBones then
        for i, buildBone in buildEffectBones do
            local beamEnd = Entity()
            TrashBagAdd(trash, beamEnd)
            beamEndEntities[i] = beamEnd
            TrashBagAdd(buildEffectsBag, beamEnd)
            Warp(beamEnd, Vector(ox, oy, oz))
            CreateEmitterOnEntity(beamEnd, army, EffectTemplate.CybranBuildSparks01)
            CreateEmitterOnEntity(beamEnd, army, EffectTemplate.CybranBuildFlash01)
            TrashBagAdd(buildEffectsBag, AttachBeamEntityToEntity(builder, buildBone, beamEnd, -1, army, '/effects/emitters/build_beam_02_emit.bp'))
        end
    end

    while not builder:BeenDestroyed() and not unitBeingBuilt:BeenDestroyed() do
        for _, entity in beamEndEntities do
            local x, y, z = builder.GetRandomOffset(unitBeingBuilt, 1)
            if entity and not entity:BeenDestroyed() then
                Warp(entity, Vector(ox + x, oy + y, oz + z))
            end
        end
        WaitSeconds(0.2)
    end
end

---@deprecated
--- You can use `SpawnBuildBotsOpti` instead
---@param builder Unit
---@param unitBeingBuilt Unit
---@param buildEffectsBag TrashBag unused
---@return Unit[]?
function SpawnBuildBots(builder, unitBeingBuilt, buildEffectsBag)
    -- Buildbots are scaled: ~ 1 pr 15 units of BP
    -- clamped to a max of 10 to avoid insane FPS drop
    -- with mods that modify BP
    local numBots = MathMin(MathCeil((10 + builder:GetBuildRate()) / 15), 10)

    local buildBots = builder.buildBots
    if not buildBots then
        buildBots = {}
        builder.buildBots = buildBots
    end

    local unitBeingBuiltArmy = unitBeingBuilt.Army
    local builderArmy = builder.Army

    -- If new, won't spawn buildbots if they might accidentally capture the unit
    if unitBeingBuiltArmy and (builderArmy == unitBeingBuiltArmy or IsHumanUnit(unitBeingBuilt)) then
        for k, bot in buildBots do
            if bot:BeenDestroyed() then
                buildBots[k] = nil
            end
        end

        local numUnits = numBots - TableGetsize(buildBots)
        if numUnits > 0 then
            local x, y, z = unpack(builder:GetPosition())
            y = y + builder.Blueprint.SizeY * 0.5
            local qx, qy, qz, qw = unpack(builder:GetOrientation())
            local angle = 180
            local vecMul = 0.5

            local angleChange = mathTau / numUnits

            -- Launch projectiles at semi-random angles away from the sphere, with enough
            -- initial velocity to escape sphere core
            for _ = 0, numUnits - 1 do
                local xVec = MathSin(angle)
                local zVec = MathSqrt(1 - xVec*xVec)
                angle = angle + angleChange

                local bot = CreateUnit('ura0001', builderArmy, x + xVec * vecMul, y, z + zVec * vecMul, qx, qy, qz, qw, 'Air')

                -- Make build bots unkillable
                bot.CanTakeDamage = false
                bot.CanBeKilled = false
                bot.spawnedBy = builder

                TableInsert(buildBots, bot)
            end
        end

        for _, bot in buildBots do
            ChangeState(bot, bot.BuildState)
        end

        return buildBots
    end
end

---@deprecated
--- You can use `CreateCybranEngineerBuildEffectsOpti` instead
---@param builder Unit
---@param buildBones Bone[]
---@param buildBots Unit[]
---@param buildEffectsBag TrashBag
function CreateCybranEngineerBuildEffects(builder, buildBones, buildBots, buildEffectsBag)
    local army = builder.Army
    -- Create build constant build effect for each build effect bone defined
    if buildBones and buildBots then
        for _, bone in buildBones do
            for _, effect in EffectTemplate.CybranBuildUnitBlink01 do
                TrashBagAdd(buildEffectsBag, CreateAttachedEmitter(builder, bone, army, effect))
            end
            WaitSeconds(UtilGetRandomFloat(0.2, 1))
        end

        if builder:BeenDestroyed() then
            return
        end

        local i = 1
        for _, bot in buildBots do
            if not bot or bot:BeenDestroyed() then
                continue
            end

            TrashBagAdd(buildEffectsBag, AttachBeamEntityToEntity(builder, buildBones[i], bot, -1, army, '/effects/emitters/build_beam_03_emit.bp'))
            i = i + 1
        end
    end
end

local BuildEffects = {
    '/effects/emitters/sparks_03_emit.bp',
    '/effects/emitters/flashes_01_emit.bp',
}
local UnitBuildEffects = {
    '/effects/emitters/build_cybran_spark_flash_04_emit.bp',
    '/effects/emitters/build_sparks_blue_02_emit.bp',
}

--- Creates the Cybran factor build effects
---@param builder Unit
---@param unitBeingBuilt Unit
---@param buildBones Bone[]
---@param buildEffectsBag TrashBag
function CreateCybranFactoryBuildEffects(builder, unitBeingBuilt, buildBones, buildEffectsBag)
    CreateCybranBuildBeamsOpti(builder, nil, unitBeingBuilt, buildEffectsBag, false)

    local builderArmy = builder.Army
    for _, bone in buildBones.BuildEffectBones do
        for _, effect in BuildEffects do
            TrashBagAdd(buildEffectsBag, CreateAttachedEmitter(builder, bone, builderArmy, effect))
        end
    end

    TrashBagAdd(buildEffectsBag, CreateAttachedEmitter(builder, buildBones.BuildAttachBone, builderArmy, '/effects/emitters/cybran_factory_build_01_emit.bp'))

    -- Add sparks to the collision box of the unit being built
    while not unitBeingBuilt.Dead and unitBeingBuilt:GetFractionComplete() < 1 do
        local sx, sy, sz = unitBeingBuilt:GetRandomOffset(1)
        for _, effect in UnitBuildEffects do
            IEffectOffsetEmitter(CreateEmitterOnEntity(unitBeingBuilt, builderArmy, effect), sx, sy, sz)
        end
        WaitSeconds(UtilGetRandomFloat(0.1, 0.6))
    end
end


CreateSeraphimUnitEngineerBuildingEffects = import("/lua/effectutilitiesseraphim.lua").CreateSeraphimUnitEngineerBuildingEffects
CreateSeraphimFactoryBuildingEffects = import("/lua/effectutilitiesseraphim.lua").CreateSeraphimFactoryBuildingEffects
CreateSeraphimBuildThread = import("/lua/effectutilitiesseraphim.lua").CreateSeraphimBuildThread
CreateSeraphimBuildBaseThread = import("/lua/effectutilitiesseraphim.lua").CreateSeraphimBuildBaseThread
CreateSeraphimExperimentalBuildBaseThread = import("/lua/effectutilitiesseraphim.lua").CreateSeraphimExperimentalBuildBaseThread

--- Creates the adjacency beams between structures
---@param unit Unit
---@param adjacentUnit Unit
---@param adjacencyBeamsBag AdjacencyBeam[]
function CreateAdjacencyBeams(unit, adjacentUnit, adjacencyBeamsBag)
    local infoTrash = TrashBag()
    local unitTrash = unit.Trash
    local info = {
        Unit = adjacentUnit,
        Trash = infoTrash
    }

    TableInsert(adjacencyBeamsBag, info)

    local uBp = unit.Blueprint
    local aBp = adjacentUnit.Blueprint
    local faction = uBp.General.FactionName

    -- Determine which effects we will be using
    local nodeMesh = nil
    local beamEffect = nil
    local emitterNodeEffects = {}
    local numNodes = 2
    local nodeList = {}


    local unitPos = unit:GetPosition()
    local adjPos = adjacentUnit:GetPosition()

    -- Create hub start/end and all midpoint nodes
    local unitHubPos = unit:GetPosition()
    local adjacentHubPos = adjacentUnit:GetPosition()

    local spec = {Owner = unit}

    if faction == 'Aeon' then
        nodeMesh = '/effects/entities/aeonadjacencynode/aeonadjacencynode_mesh'
        beamEffect = '/effects/emitters/adjacency_aeon_beam_0' .. UtilGetRandomInt(1, 3) .. '_emit.bp'
        numNodes = 3
    elseif faction == 'Cybran' then
        nodeMesh = '/effects/entities/cybranadjacencynode/cybranadjacencynode_mesh'
        beamEffect = '/effects/emitters/adjacency_cybran_beam_01_emit.bp'
    elseif faction == 'UEF' then
        nodeMesh = '/effects/entities/uefadjacencynode/uefadjacencynode_mesh'
        beamEffect = '/effects/emitters/adjacency_uef_beam_01_emit.bp'
    elseif faction == 'Seraphim' then
        nodeMesh = '/effects/entities/seraphimadjacencynode/seraphimadjacencynode_mesh'
        TableInsert(emitterNodeEffects, EffectTemplate.SAdjacencyAmbient01)
        if  UtilGetDistanceBetweenTwoVectors(unitHubPos, adjacentHubPos) < 2.5 then
            numNodes = 1
        else
            numNodes = 3
            TableInsert(emitterNodeEffects, EffectTemplate.SAdjacencyAmbient02)
            TableInsert(emitterNodeEffects, EffectTemplate.SAdjacencyAmbient03)
        end
    end

    for i = 1, numNodes do
        local entity = Entity(spec)
        local node = {
            entity = entity,
            pos = {0, 0, 0},
        }
        entity:SetVizToNeutrals('Intel')
        entity:SetVizToEnemies('Intel')
        nodeList[i] = node
    end

    local verticalOffset = 0.05

    -- Move Unit Pos towards adjacent unit by bounding box size
    local uBpSizeX = uBp.SizeX * 0.5
    local uBpSizeZ = uBp.SizeZ * 0.5
    local aBpSizeX = aBp.SizeX * 0.5
    local aBpSizeZ = aBp.SizeZ * 0.5

    -- To Determine positioning, need to use the bounding box or skirt size
    local uBpSkirtX = uBp.Physics.SkirtSizeX * 0.5
    local uBpSkirtZ = uBp.Physics.SkirtSizeZ * 0.5
    local aBpSkirtX = aBp.Physics.SkirtSizeX * 0.5
    local aBpSkirtZ = aBp.Physics.SkirtSizeZ * 0.5

    -- Get edge corner positions, {TOP, LEFT, BOTTOM, RIGHT}
    local unitSkirtBounds = {
        unitHubPos[3] - uBpSkirtZ,
        unitHubPos[1] - uBpSkirtX,
        unitHubPos[3] + uBpSkirtZ,
        unitHubPos[1] + uBpSkirtX,
    }
    local adjacentSkirtBounds = {
        adjacentHubPos[3] - aBpSkirtZ,
        adjacentHubPos[1] - aBpSkirtX,
        adjacentHubPos[3] + aBpSkirtZ,
        adjacentHubPos[1] + aBpSkirtX,
    }

    -- Figure out the best matching ogrid position on units bounding box
    -- depending on it's skirt size
    -- Unit bottom or top skirt is aligned to adjacent unit
    if unitSkirtBounds[3] == adjacentSkirtBounds[1] or unitSkirtBounds[1] == adjacentSkirtBounds[3] then

        local sharedSkirtLower = unitSkirtBounds[4] - (unitSkirtBounds[4] - adjacentSkirtBounds[2])
        local sharedSkirtUpper = unitSkirtBounds[4] - (unitSkirtBounds[4] - adjacentSkirtBounds[4])
        local sharedSkirtLen = sharedSkirtUpper - sharedSkirtLower

        -- Depending on shared skirt bounds, determine the position of unit hub
        -- Find out how many times the shared skirt fits into the unit hub shared skirt
        local numAdjSkirtsOnUnitSkirt = (uBpSkirtX * 2) / sharedSkirtLen
        local numUnitSkirtsOnAdjSkirt = (aBpSkirtX * 2) / sharedSkirtLen

         -- Z-offset, offset adjacency hub positions the proper direction
        if unitSkirtBounds[3] == adjacentSkirtBounds[1] then
            unitHubPos[3] = unitHubPos[3] + uBpSizeZ
            adjacentHubPos[3] = adjacentHubPos[3] - aBpSizeZ
        else -- unitSkirtBounds[1] == adjacentSkirtBounds[3]
            unitHubPos[3] = unitHubPos[3] - uBpSizeZ
            adjacentHubPos[3] = adjacentHubPos[3] + aBpSizeZ
        end

        -- X-offset, Find the shared adjacent x position range
        -- If we have more than skirt on this section, then we need to adjust the x position of the unit hub
        if numAdjSkirtsOnUnitSkirt > 1 or numUnitSkirtsOnAdjSkirt < 1 then
            local uSkirtLen = (unitSkirtBounds[4] - unitSkirtBounds[2]) * 0.5           -- Unit skirt length
            local uGridUnitSize = (uBpSizeX * 2) / uSkirtLen                            -- Determine one grid of adjacency along that length
            local xoffset = MathAbs(unitSkirtBounds[2] - adjacentSkirtBounds[2]) * 0.5  -- Get offset of the unit along the skirt
            unitHubPos[1] = (unitHubPos[1] - uBpSizeX) + (xoffset * uGridUnitSize) + (uGridUnitSize * 0.5) -- Now offset the position of adjacent point
        end

        -- If we have more than skirt on this section, then we need to adjust the x position of the adjacent hub
        if numUnitSkirtsOnAdjSkirt > 1  or numAdjSkirtsOnUnitSkirt < 1 then
            local aSkirtLen = (adjacentSkirtBounds[4] - adjacentSkirtBounds[2]) * 0.5   -- Adjacent unit skirt length
            local aGridUnitSize = (aBpSizeX * 2) / aSkirtLen                            -- Determine one grid of adjacency along that length ??
            local xoffset = MathAbs(adjacentSkirtBounds[2] - unitSkirtBounds[2]) * 0.5  -- Get offset of the unit along the adjacent unit
            adjacentHubPos[1] = (adjacentHubPos[1] - aBpSizeX) + (xoffset * aGridUnitSize) + (aGridUnitSize * 0.5) -- Now offset the position of adjacent point
        end

    -- Unit right or top left is aligned to adjacent unit
    elseif unitSkirtBounds[4] == adjacentSkirtBounds[2] or unitSkirtBounds[2] == adjacentSkirtBounds[4] then
        local sharedSkirtLower = unitSkirtBounds[3] - (unitSkirtBounds[3] - adjacentSkirtBounds[1])
        local sharedSkirtUpper = unitSkirtBounds[3] - (unitSkirtBounds[3] - adjacentSkirtBounds[3])
        local sharedSkirtLen = sharedSkirtUpper - sharedSkirtLower

        -- Depending on shared skirt bounds, determine the position of unit hub
        -- Find out how many times the shared skirt fits into the unit hub shared skirt
        local numAdjSkirtsOnUnitSkirt = (uBpSkirtX * 2) / sharedSkirtLen
        local numUnitSkirtsOnAdjSkirt = (aBpSkirtX * 2) / sharedSkirtLen

        -- X-offset
        if unitSkirtBounds[4] == adjacentSkirtBounds[2] then
            unitHubPos[1] = unitHubPos[1] + uBpSizeX
            adjacentHubPos[1] = adjacentHubPos[1] - aBpSizeX
        else -- unitSkirtBounds[2] == adjacentSkirtBounds[4]
            unitHubPos[1] = unitHubPos[1] - uBpSizeX
            adjacentHubPos[1] = adjacentHubPos[1] + aBpSizeX
        end

        -- Z-offset, Find the shared adjacent x position range
        -- If we have more than skirt on this section, then we need to adjust the x position of the unit hub
        if numAdjSkirtsOnUnitSkirt > 1 or numUnitSkirtsOnAdjSkirt < 1 then
            local uSkirtLen = (unitSkirtBounds[3] - unitSkirtBounds[1]) * 0.5           -- Unit skirt length
            local uGridUnitSize = (uBpSizeZ * 2) / uSkirtLen                            -- Determine one grid of adjacency along that length
            local zoffset = MathAbs(unitSkirtBounds[1] - adjacentSkirtBounds[1]) * 0.5  -- Get offset of the unit along the skirt
            unitHubPos[3] = (unitHubPos[3] - uBpSizeZ) + (zoffset * uGridUnitSize) + (uGridUnitSize * 0.5) -- Now offset the position of adjacent point
        end

        -- If we have more than skirt on this section, then we need to adjust the x position of the adjacent hub
        if numUnitSkirtsOnAdjSkirt > 1 or numAdjSkirtsOnUnitSkirt < 1 then
            local aSkirtLen = (adjacentSkirtBounds[3] - adjacentSkirtBounds[1]) * 0.5   -- Adjacent unit skirt length
            local aGridUnitSize = (aBpSizeZ * 2) / aSkirtLen                            -- Determine one grid of adjacency along that length ??
            local zoffset = MathAbs(adjacentSkirtBounds[1] - unitSkirtBounds[1]) * 0.5  -- Get offset of the unit along the adjacent unit
            adjacentHubPos[3] = (adjacentHubPos[3] - aBpSizeZ) + (zoffset * aGridUnitSize) + (aGridUnitSize * 0.5) -- Now offset the position of adjacent point
        end
    end

    -- Setup our midpoint positions
    if faction == 'Aeon' or faction == 'Seraphim' then
        local directionVec = UtilGetDifferenceVector(unitHubPos, adjacentHubPos)
        local perpVec = UtilCross(directionVec, Vector(0, 0.35, 0))
        local segmentLen = 1 / (numNodes + 1)

        if UtilGetRandomInt(0, 1) == 1 then
            perpVec[1] = -perpVec[1]
            perpVec[3] = -perpVec[3]
        end

        local offsetMul = 0.15
        local segmentMul = 0
        for i = 1, numNodes do
            segmentMul = segmentMul + segmentLen

            if segmentMul <= 0.5 then
                offsetMul = offsetMul + 0.12
            else
                offsetMul = offsetMul - 0.12
            end

            nodeList[i].pos = {
                unitHubPos[1] - directionVec[1] * segmentMul - perpVec[1] * offsetMul,
                nil,
                unitHubPos[3] - directionVec[3] * segmentMul - perpVec[3] * offsetMul,
            }
        end
    elseif faction == 'Cybran' then
        if unitPos[1] == adjPos[1] or unitPos[3] == adjPos[3] then
            local dist = UtilGetDistanceBetweenTwoVectors(unitHubPos, adjacentHubPos)
            local directionVec = UtilGetScaledDirectionVector(unitHubPos, adjacentHubPos, UtilGetRandomFloat(0.35, dist * 0.48))
            directionVec[2] = 0
            local perpVec = UtilCross(directionVec, Vector(0, UtilGetRandomFloat(0.2, 0.35), 0))

            if UtilGetRandomInt(0, 1) == 1 then
                perpVec[1] = -perpVec[1]
                perpVec[3] = -perpVec[3]
            end

            -- Initialize 2 midpoint segments
            nodeList[1].pos = {
                unitHubPos[1] - directionVec[1] - perpVec[1],
                unitHubPos[2] - directionVec[2],
                unitHubPos[3] - directionVec[3] - perpVec[3]
            }
            nodeList[2].pos = {
                adjacentHubPos[1] + directionVec[1] + perpVec[1],
                adjacentHubPos[2] + directionVec[2],
                adjacentHubPos[3] + directionVec[3] + perpVec[3]
            }

            unitHubPos[1] = unitHubPos[1] - perpVec[1]
            unitHubPos[3] = unitHubPos[3] - perpVec[3]
            adjacentHubPos[1] = adjacentHubPos[1] + perpVec[1]
            adjacentHubPos[3] = adjacentHubPos[3] + perpVec[3]
        else
            -- Unit bottom skirt is on top skirt of adjacent unit
            if unitSkirtBounds[3] == adjacentSkirtBounds[1] then
                local pos3 = (unitHubPos[3] + adjacentHubPos[3]) * 0.5
                nodeList[1].pos[1] = unitHubPos[1]
                nodeList[2].pos[1] = adjacentHubPos[1]
                nodeList[1].pos[3] = pos3 - UtilGetRandomFloat(0, 1)
                nodeList[2].pos[3] = pos3 + UtilGetRandomFloat(0, 1)
            elseif unitSkirtBounds[1] == adjacentSkirtBounds[3] then
                local pos3 = (unitHubPos[3] + adjacentHubPos[3]) * 0.5
                nodeList[1].pos[1] = unitHubPos[1]
                nodeList[2].pos[1] = adjacentHubPos[1]
                nodeList[1].pos[3] = pos3 + UtilGetRandomFloat(0, 1)
                nodeList[2].pos[3] = pos3 - UtilGetRandomFloat(0, 1)
            elseif unitSkirtBounds[4] == adjacentSkirtBounds[2] then
                local pos1 = (unitHubPos[1] + adjacentHubPos[1]) * 0.5
                nodeList[1].pos[1] = pos1 - UtilGetRandomFloat(0, 1)
                nodeList[2].pos[1] = pos1 + UtilGetRandomFloat(0, 1)
                nodeList[1].pos[3] = unitHubPos[3]
                nodeList[2].pos[3] = adjacentHubPos[3]
            elseif unitSkirtBounds[2] == adjacentSkirtBounds[4] then
                local pos1 = (unitHubPos[1] + adjacentHubPos[1]) * 0.5
                nodeList[1].pos[1] = pos1 + UtilGetRandomFloat(0, 1)
                nodeList[2].pos[1] = pos1 - UtilGetRandomFloat(0, 1)
                nodeList[1].pos[3] = unitHubPos[3]
                nodeList[2].pos[3] = adjacentHubPos[3]
            else
                return  -- invalid adjacency!
            end
        end
    elseif faction == 'UEF' then
        if unitPos[1] == adjPos[1] or unitPos[3] == adjPos[3] then
            local directionVec = UtilGetScaledDirectionVector(unitHubPos, adjacentHubPos, 0.35)
            directionVec[2] = 0
            local perpVec = UtilCross(directionVec, Vector(0, 0.35, 0))
            if UtilGetRandomInt(0, 1) == 1 then
                perpVec[1] = -perpVec[1]
                perpVec[3] = -perpVec[3]
            end

            -- Initialize 2 midpoint segments
            for _, node in nodeList do
                node.pos = UtilGetMidPoint(unitHubPos, adjacentHubPos)
            end

            -- Offset beam positions
            nodeList[1].pos[1] = nodeList[1].pos[1] - perpVec[1]
            nodeList[1].pos[3] = nodeList[1].pos[3] - perpVec[3]
            nodeList[2].pos[1] = nodeList[2].pos[1] + perpVec[1]
            nodeList[2].pos[3] = nodeList[2].pos[3] + perpVec[3]

            unitHubPos[1] = unitHubPos[1] - perpVec[1]
            unitHubPos[3] = unitHubPos[3] - perpVec[3]
            adjacentHubPos[1] = adjacentHubPos[1] + perpVec[1]
            adjacentHubPos[3] = adjacentHubPos[3] + perpVec[3]
        else
            -- Unit bottom skirt is on top skirt of adjacent unit
            if unitSkirtBounds[3] == adjacentSkirtBounds[1] or unitSkirtBounds[1] == adjacentSkirtBounds[3] then
                local pos3 = (unitHubPos[3] + adjacentHubPos[3]) * 0.5
                nodeList[1].pos[1] = unitHubPos[1]
                nodeList[2].pos[1] = adjacentHubPos[1]
                nodeList[1].pos[3] = pos3
                nodeList[2].pos[3] = pos3
            -- Unit right skirt is on left skirt of adjacent unit
            elseif unitSkirtBounds[4] == adjacentSkirtBounds[2] or unitSkirtBounds[2] == adjacentSkirtBounds[4] then
                local pos1 = (unitHubPos[1] + adjacentHubPos[1]) * 0.5
                nodeList[1].pos[1] = pos1
                nodeList[2].pos[1] = pos1
                nodeList[1].pos[3] = unitHubPos[3]
                nodeList[2].pos[3] = adjacentHubPos[3]
            else
                return  -- invalid adjacency!
            end
        end
    end

    local unitArmy = unit.Army
    -- Offset beam positions above the ground at current positions terrain height
    for _, node in nodeList do
        local pos = node.pos
        pos[2] = GetTerrainHeight(pos[1], pos[3]) + verticalOffset
    end

    unitHubPos[2] = GetTerrainHeight(unitHubPos[1], unitHubPos[3]) + verticalOffset
    adjacentHubPos[2] = GetTerrainHeight(adjacentHubPos[1], adjacentHubPos[3]) + verticalOffset

    -- Set the mesh of the entity and attach any node effects
    for i = 1, numNodes do
        local entity = nodeList[i].entity
        entity:SetMesh(nodeMesh, false)
        nodeList[i].mesh = true
        if emitterNodeEffects[i] ~= nil and not TableEmpty(emitterNodeEffects[i]) then
            for _, emitter in emitterNodeEffects[i] do
                emitter = CreateAttachedEmitter(entity, 0, unitArmy, emitter)
                TrashBagAdd(infoTrash, emitter)
                TrashBagAdd(unitTrash, emitter)
            end
        end
    end

    -- Insert start and end points into our list
    TableInsert(nodeList, 1, {
        pos = unitHubPos,
        entity = Entity{}
    })
    TableInsert(nodeList, {
        pos = adjacentHubPos,
        entity = Entity{}
    })

    -- Warp everything to its final position
    for i = 1, numNodes + 2 do
        local entity = nodeList[i].entity
        Warp(entity, nodeList[i].pos)
        TrashBagAdd(infoTrash, entity)
        TrashBagAdd(unitTrash, entity)
    end

    -- Attach beams to the adjacent unit
    for i = 1, numNodes + 1 do
        local node = nodeList[i]
        if node.mesh ~= nil then
            local curPos = node.pos
            local nextPos = nodeList[i + 1].pos
            local vec = UtilGetDirectionVector(Vector(curPos[1], curPos[2], curPos[3]), Vector(nextPos[1], nextPos[2], nextPos[3]))
            node.entity:SetOrientation(OrientFromDir(vec), true)
        end
        if beamEffect then
            local beam
            local categoriesHash = adjacentUnit.Blueprint.CategoriesHash
            if categoriesHash["MASSSTORAGE"] or categoriesHash["ENERGYSTORAGE"] then
                beam = AttachBeamEntityToEntity(node.entity, -1, nodeList[i + 1].entity, -1, unitArmy, beamEffect)
            else
                beam = AttachBeamEntityToEntity(nodeList[i + 1].entity, -1, node.entity, -1, unitArmy, beamEffect)
            end

            TrashBagAdd(infoTrash, beam)
            TrashBagAdd(unitTrash, beam)
        end
    end
end

--- Creates the sacrificing effects on the unit
---@param unit Unit
---@param targetUnit Unit unused
function PlaySacrificingEffects(unit, targetUnit)
    if unit.Blueprint.General.FactionName == 'Aeon' then
        local unitArmy = unit.Army
        local unitTrash = unit.Trash
        for _, effect in EffectTemplate.ASacrificeOfTheAeon01 do
            TrashBagAdd(unitTrash, CreateEmitterOnEntity(unit, unitArmy, effect))
        end
    end
end

--- Creates the sacrifice effects on the target unit
---@param unit Unit
---@param targetUnit Unit
function PlaySacrificeEffects(unit, targetUnit)
    if unit.Blueprint.General.FactionName == 'Aeon' then
        for _, effect in EffectTemplate.ASacrificeOfTheAeon02 do
            CreateEmitterAtEntity(targetUnit, unit.Army, effect)
        end
    end
end


--- Creates capturing effects on the capturing unit
---@param capturer Unit
---@param captive Unit
---@param buildEffectBones Bone[]
---@param effectsBag TrashBag
function PlayCaptureEffects(capturer, captive, buildEffectBones, effectsBag)
    local capturerArmy = capturer.Army
    for _, bone in buildEffectBones do
        for _, effect in EffectTemplate.CaptureBeams do
            TrashBagAdd(effectsBag, AttachBeamEntityToEntity(capturer, bone, captive, -1, capturerArmy, effect))
        end
    end
end

--- Creates the ping-ponging quantum effect for the Summoner
---@param unit Unit
---@param bone1 Bone
---@param bone2 Bone
---@param trashbag TrashBag
---@param startwaitSeed number
function CreateCybranQuantumGateEffect(unit, bone1, bone2, trashbag, startwaitSeed)
    -- Adding a quick wait here so that unit bone positions are correct
    WaitSeconds(startwaitSeed)

    local pos1 = unit:GetPosition(bone1)
    local pos2 = unit:GetPosition(bone2)
    pos1[2] = pos1[2] - 0.72
    pos2[2] = pos2[2] - 0.72

    -- Create a projectile for the end of build effect and warp it to the unit
    local beamStartEntity = unit:CreateProjectile('/effects/entities/UEFBuild/UEFBuild01_proj.bp', 0, 0, 0)
    TrashBagAdd(trashbag, beamStartEntity)
    Warp(beamStartEntity, pos1)

    local beamEndEntity = unit:CreateProjectile('/effects/entities/UEFBuild/UEFBuild01_proj.bp', 0, 0, 0)
    TrashBagAdd(trashbag, beamEndEntity)
    Warp(beamEndEntity, pos2)

    -- Create beam effect
    TrashBagAdd(trashbag, AttachBeamEntityToEntity(beamStartEntity, -1, beamEndEntity, -1, unit.Army, '/effects/emitters/cybran_gate_beam_01_emit.bp'))

    -- Determine a the velocity of our projectile, used for the scaning effect
    local velY = 1
    beamEndEntity:SetVelocity(0, velY, 0)

    -- Warp our projectile back to the initial corner and lower based on build completeness
    while not unit:BeenDestroyed() do
        beamStartEntity:SetVelocity(0, velY, 0)
        beamEndEntity:SetVelocity(0, velY, 0)
        velY =- velY
        WaitSeconds(1.5)
    end
end

--- Creates an enhancement effect at an unit's bone
---@param unit Unit
---@param bone Bone
---@param trashbag TrashBag
function CreateEnhancementEffectAtBone(unit, bone, trashbag)
    for _, effect in EffectTemplate.UpgradeBoneAmbient do
        TrashBagAdd(trashbag, CreateAttachedEmitter(unit, bone, unit.Army, effect))
    end
end


--- Creates an enhancement ambient at an unit
---@param unit Unit
---@param bone Bone
---@param trashbag TrashBag
function CreateEnhancementUnitAmbient(unit, bone, trashbag)
    local unitArmy = unit.Army
    for _, effect in EffectTemplate.UpgradeUnitAmbient do
        TrashBagAdd(trashbag, CreateAttachedEmitter(unit, bone, unitArmy, effect))
    end
end

--- Cleans up a trash bag (whether an old-style table or new-style TrashBag)
---@param self Entity
---@param identifier string
function CleanupEffectBag(self, identifier)
    local bag = self[identifier]
    -- old 'bag' where it is just a table
    if TableEmpty(getmetatable(bag)) then
        for k, v in bag do
            if v.Destroy then
                v:Destroy()
            end
            bag[k] = nil
        end
    -- new 'bag' that is a trashbag
    else
        bag:Destroy()
    end
end

--- Plays rift-in effects
---@param unit Unit
---@param effects FileName[]
---@param flashEffects string[]
---@param size number
function PlayRiftInEffects(unit, effects, flashEffects, size)
    unit:HideBone(0, true)
    local unitArmy = unit.Army
    for _, effect in effects do
        CreateAttachedEmitter(unit, -1, unitArmy, effect)
    end
    WaitSeconds(2.0)

    CreateLightParticle(unit, -1, unit.Army, size, 15, 'glow_05', 'ramp_jammer_01')
    WaitSeconds(0.1)

    unit:ShowBone(0, true)
    WaitSeconds(0.25)

    unitArmy = unit.Army    -- just in case it changed
    for _, effect in flashEffects do
        CreateAttachedEmitter(unit, -1, unitArmy, effect)
    end
end

--- Creates a small Seraphim rift-in effect
---@param unit Unit
function SeraphimRiftIn(unit)
    PlayRiftInEffects(unit, EffectTemplate.SerRiftIn_Small, EffectTemplate.SerRiftIn_SmallFlash, 4)
end

--- Creates a large Seraphim rift-in effect
---@param unit Unit
function SeraphimRiftInLarge(unit)
    PlayRiftInEffects(unit, EffectTemplate.SerRiftIn_Large, EffectTemplate.SerRiftIn_LargeFlash, 25)
end

--- Creates a Cybran building infection effect
---@param unit Unit
function CybranBuildingInfection(unit)
    local unitArmy = unit.Army
    for _, effect in EffectTemplate.CCivilianBuildingInfectionAmbient do
        CreateAttachedEmitter(unit, -1, unitArmy, effect)
    end
end

--- Creates a QAI shutdown effect
---@param unit Unit
function CybranQaiShutdown(unit)
    local unitArmy = unit.Army
    for _, effect in EffectTemplate.CQaiShutdown do
        CreateAttachedEmitter(unit, -1, unitArmy, effect)
    end
end

--- Creates Aeon ACU hack effects
---@param unit Unit
function AeonHackACU(unit)
    local unitArmy = unit.Army
    for _, effect in EffectTemplate.AeonOpHackACU do
        CreateAttachedEmitter(unit, -1, unitArmy, effect)
    end
end

-- New function for insta capture fix
---@param self Unit
---@return boolean
function IsHumanUnit(self)
    local selfArmy = self.Army
    for _, army in ScenarioInfo.ArmySetup do
        if army.ArmyIndex == selfArmy then
            return army.Human == true
        end
    end
end


--- Creates the teleport charging effects
---@param unit Unit
---@param teleDest Vector
---@param effectsBag TrashBag
---@param teleDelay? number
function PlayTeleportChargingEffects(unit, teleDest, effectsBag, teleDelay)
    -- Plays teleport effects for the given unit
    if not unit then
        return
    end

    local bp = unit.Blueprint
    local faction = bp.General.FactionName
    local offsetY = TeleportGetUnitYOffset(unit)
    local unitArmy = unit.Army

    teleDest = TeleportLocationToSurface(teleDest)

    -- Play tele FX at unit location
    if bp.Display.TeleportEffects.PlayChargeFxAtUnit ~= false then
        unit:PlayUnitAmbientSound('TeleportChargingAtUnit')

        if faction == 'UEF' then
            -- We recycle the teleport destination effects since they are way more epic
            local teleChargeBag = {}
            unit.TeleportChargeBag = teleChargeBag
            local k = 1
            local telefx = EffectTemplate.UEFTeleportCharge02
            for _, effect in telefx do
                local fx = CreateEmitterAtEntity(unit, unitArmy, effect)
                IEffectOffsetEmitter(fx, 0, offsetY, 0)
                IEffectScaleEmitter(fx, 0.75)
                IEffectSetEmitterCurveParam(fx, 'Y_POSITION_CURVE', 0, offsetY * 2) -- To make effects cover entire height of unit
                IEffectSetEmitterCurveParam(fx, 'ROTATION_RATE_CURVE', 1, 0) -- Small initial rotation, will be faster as charging
                teleChargeBag[k] = fx
                k = k + 1
                TrashBagAdd(effectsBag, fx)
            end

            -- Make steam FX
            local totalBones = unit:GetBoneCount() - 1
            for _, effect in EffectTemplate.UnitTeleportSteam01 do
                for bone = 1, totalBones do
                    local emitter = CreateAttachedEmitter(unit, bone, unitArmy, effect)
                    IEffectSetEmitterParam(emitter, 'Lifetime', 9999) -- Adjust the lifetime so we always teleport before its done
                    teleChargeBag[k] = emitter
                    k = k + 1
                    TrashBagAdd(effectsBag, emitter)
                end
            end
        -- Use a per-bone FX construction rather than wrap-around for the non-UEF factions
        elseif faction == 'Cybran' then
            unit.TeleportChargeBag = TeleportShowChargeUpFxAtUnit(unit, EffectTemplate.CybranTeleportCharge01, effectsBag)
        elseif faction == 'Seraphim' then
            unit.TeleportChargeBag = TeleportShowChargeUpFxAtUnit(unit, EffectTemplate.SeraphimTeleportCharge01, effectsBag)
        else
            unit.TeleportChargeBag = TeleportShowChargeUpFxAtUnit(unit, EffectTemplate.GenericTeleportCharge01, effectsBag)
        end
    end

    if teleDelay then
        WaitSeconds(teleDelay)
    end

    unitArmy = unit.Army    -- just in case it changed

    -- Play tele FX at destination, including sounds
    if bp.Display.TeleportEffects.PlayChargeFxAtDestination ~= false then
        -- Customized version of PlayUnitAmbientSound() from unit.lua to play sound at target destination
        local sound = 'TeleportChargingAtDestination'
        local sndEnt = false

        unit.TeleportSoundChargeBag = {}
        if sound and bp.Audio[sound] then
            if not unit.AmbientSounds then
                unit.AmbientSounds = {}
            end
            if not unit.AmbientSounds[sound] then
                sndEnt = Entity {}
                unit.AmbientSounds[sound] = sndEnt
                TrashBagAdd(unit.Trash, sndEnt)
                Warp(sndEnt, teleDest) -- Warping sound entity to destination so ambient sound plays there (and not at unit)
                TableInsert(unit.TeleportSoundChargeBag, sndEnt)
            end
            unit.AmbientSounds[sound]:SetAmbientSound(bp.Audio[sound], nil)
        end

        -- Using a barebone entity to position effects, it is destroyed afterwards
        local teleportDestFxEntity = Entity()
        Warp(teleportDestFxEntity, teleDest)
        unit.TeleportDestChargeBag = {}

        if faction == 'UEF' then
            local telefx = EffectTemplate.UEFTeleportCharge02
            for _, effect in telefx do
                local fx = CreateEmitterAtEntity(teleportDestFxEntity, unitArmy, effect)
                IEffectOffsetEmitter(fx, 0, offsetY, 0)
                IEffectScaleEmitter(fx, 0.75)
                IEffectSetEmitterCurveParam(fx, 'Y_POSITION_CURVE', 0, offsetY * 2) -- To make effects cover entire height of unit
                IEffectSetEmitterCurveParam(fx, 'ROTATION_RATE_CURVE', 1, 0) -- Small initial rotation, will be faster as charging
                TableInsert(unit.TeleportDestChargeBag, fx)
                TrashBagAdd(effectsBag, fx)
            end
        elseif faction == 'Cybran' then
            local pos = TableCopy(teleDest)
            pos[2] = pos[2] + offsetY -- Make sure sphere isn't half in the ground
            local sphere = TeleportCreateCybranSphere(unit, pos, 0.01)

            local telefx = EffectTemplate.CybranTeleportCharge02

            for _, effect in telefx do
                local fx = CreateEmitterAtEntity(sphere, unitArmy, effect)
                IEffectScaleEmitter(fx, 0.01 * unit.TeleportCybranSphereScale)
                TableInsert(unit.TeleportDestChargeBag, fx)
                TrashBagAdd(effectsBag, fx)
            end
        elseif faction == 'Seraphim' then
            local telefx = EffectTemplate.SeraphimTeleportCharge02
            for _, effect in telefx do
                local fx = CreateEmitterAtEntity(teleportDestFxEntity, unitArmy, effect)
                IEffectOffsetEmitter(fx, 0, offsetY, 0)
                IEffectScaleEmitter(fx, 0.01)
                TableInsert(unit.TeleportDestChargeBag, fx)
                TrashBagAdd(effectsBag, fx)
            end

            teleportDestFxEntity:Destroy()
        else
            local telefx = EffectTemplate.GenericTeleportCharge02
            for _, effect in telefx do
                local fx = CreateEmitterAtEntity(teleportDestFxEntity, unitArmy, effect)
                IEffectOffsetEmitter(fx, 0, offsetY, 0)
                IEffectScaleEmitter(fx, 0.01)
                TableInsert(unit.TeleportDestChargeBag, fx)
                TrashBagAdd(effectsBag, fx)
            end

            teleportDestFxEntity:Destroy()
        end
    end
end

--- Gets a unit's teleport effect y-offset, so it appears centered
---@param unit Unit
---@return number
function TeleportGetUnitYOffset(unit)
    -- Returns how high to create effects to make the effects appear in the center of the unit
    local bp = unit.Blueprint
    return bp.Display.TeleportEffects.FxChargeAtDestOffsetY or ((bp.Physics.MeshExtentsY or bp.SizeY or 2) * 0.5)
end

--- Gets the teleport sizes of a unit
---@param unit Unit
---@return number sizeX
---@return number sizeY
---@return number sizeZ
---@return number offsetX
---@return number offsetY
---@return number offsetZ
function TeleportGetUnitSizes(unit)
    -- Returns the sizes of the unit, to be used for teleportation effects
    local bp = unit.Blueprint
    local telefx = bp.Display.TeleportEffects
    return telefx.FxSizeX or bp.Physics.MeshExtentsX or bp.SizeX or 1,
           telefx.FxSizeY or bp.Physics.MeshExtentsY or bp.SizeY or 1,
           telefx.FxSizeZ or bp.Physics.MeshExtentsZ or bp.SizeZ or 1,
           telefx.FxOffsetX or bp.CollisionOffsetX or 0,
           telefx.FxOffsetY or bp.CollisionOffsetY or 0,
           telefx.FxOffsetZ or bp.CollisionOffsetZ or 0
end

--- Gets the teleport location, based on the terrain height and terrain type offset
---@param loc Vector
---@return table|nil
function TeleportLocationToSurface(loc)
    -- Takes the given location, adjust the Y value to the surface height on that location
    local pos = TableCopy(loc)
    pos[2] = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3])
    return pos
end

--- Creates the teleport charge-up effects at a unit
---@param unit Unit
---@param effectTemplate string[]
---@param effectsBag TrashBag
---@return TrashBag
function TeleportShowChargeUpFxAtUnit(unit, effectTemplate, effectsBag)
    -- Creates charge up effects at the unit
    local bp = unit.Blueprint
    local bones = bp.Display.TeleportEffects.ChargeFxAtUnitBones or {Bone = 0, Offset = {0, 0.25, 0}}
    local unitArmy = unit.Army
    local emitters = {}
    local k = 1
    for _, value in bones do
        local bone = value.Bone or 0
        local ox = value.Offset[1] or 0
        local oy = value.Offset[2] or 0
        local oz = value.Offset[3] or 0
        for _, effect in effectTemplate do
            local fx = IEffectOffsetEmitter(CreateEmitterAtBone(unit, bone, unitArmy, effect), ox, oy, oz)
            emitters[k] = fx
            k = k + 1
            TrashBagAdd(effectsBag, fx)
        end
    end
    return emitters
end

--- Creates the Cybran teleport effect
---@param unit Unit
---@param location Vector
---@param initialScale number
---@return Entity sphere
function TeleportCreateCybranSphere(unit, location, initialScale)
    -- Creates the sphere used by Cybran teleportation effects
    local sx, sy, sz = TeleportGetUnitSizes(unit)
    local scale = 1.25 * MathMax(sx, sy, sz)
    unit.TeleportCybranSphereScale = scale

    local sphere = Entity()
    sphere:SetPosition(location, true)
    sphere:SetMesh('/effects/Entities/CybranTeleport/CybranTeleport_mesh', false)
    sphere:SetDrawScale(initialScale or scale)
    unit.TeleportCybranSphere = sphere
    TrashBagAdd(unit.Trash, sphere)

    sphere:SetVizToAllies('Intel')
    sphere:SetVizToEnemies('Intel')
    sphere:SetVizToFocusPlayer('Intel')
    sphere:SetVizToNeutrals('Intel')

    return sphere
end

--- Sets a unit's teleport effect parameters based on the charging progress
---@param unit Unit
---@param fraction number
function TeleportChargingProgress(unit, fraction)
    local bp = unit.Blueprint

    if bp.Display.TeleportEffects.PlayChargeFxAtDestination ~= false then
        fraction = MathMin(MathMax(fraction, 0.01), 1)
        local faction = bp.General.FactionName

        if faction == 'UEF' then
            -- Increase rotation of effects as progressing
            if unit.TeleportDestChargeBag then
                local height = -(25 + 100 * fraction)
                local size = 30 * fraction
                local scale = 0.75 + 0.5 * MathMax(fraction, 0.01)
                for _, fx in unit.TeleportDestChargeBag do
                    IEffectSetEmitterCurveParam(fx, 'ROTATION_RATE_CURVE', height, size)
                    IEffectScaleEmitter(fx, scale)
                end
                -- Scale FX at unit location as well
                for _, fx in unit.TeleportChargeBag do
                    IEffectSetEmitterCurveParam(fx, 'ROTATION_RATE_CURVE', height, size)
                    IEffectScaleEmitter(fx, scale)
                end
            end
        elseif faction == 'Cybran' then
            -- Increase size of sphere and effects as progressing
            local scale = MathMax(fraction, 0.01) * (unit.TeleportCybranSphereScale or 5)
            if unit.TeleportCybranSphere then
                unit.TeleportCybranSphere:SetDrawScale(scale)
            end
            if unit.TeleportDestChargeBag then
                for _, fx in unit.TeleportDestChargeBag do
                   IEffectScaleEmitter(fx, scale)
                end
            end
        elseif unit.TeleportDestChargeBag then
            -- Increase size of effects as progressing
            local scale = 2 * fraction - MathPow(fraction, 2)
            for _, fx in unit.TeleportDestChargeBag do
                IEffectScaleEmitter(fx, scale)
            end
        end
    end
end

--- Creates the final teleport out effects
---@param unit Unit
---@param effectsBag TrashBag
function PlayTeleportOutEffects(unit, effectsBag)
    -- Fired when the unit is being teleported, just before the unit is taken from its original location
    local bp = unit.Blueprint
    local faction = bp.General.FactionName

    if bp.Display.TeleportEffects.PlayTeleportOutFx ~= false then
        unit:PlayUnitSound('TeleportOut')
        local unitArmy = unit.Army
        local offsetY = TeleportGetUnitYOffset(unit)
        local templ
        if faction == 'UEF' then
            local scaleX, scaleY, scaleZ = TeleportGetUnitSizes(unit)
            local cfx = unit:CreateProjectile('/effects/Entities/UEFBuildEffect/UEFBuildEffect02_proj.bp', 0, 0, 0)
            cfx:SetScale(scaleX, scaleY, scaleZ)
            effectsBag:Add(cfx)

            CreateLightParticle(unit, -1, unitArmy, 3, 7, 'glow_03', 'ramp_blue_02')
            templ = unit.TeleportOutFxOverride or EffectTemplate.UEFTeleportOut01
        elseif faction == 'Cybran' then
            CreateLightParticle(unit, -1, unitArmy, 4, 10, 'glow_02', 'ramp_red_06')
            templ = unit.TeleportOutFxOverride or EffectTemplate.CybranTeleportOut01
        elseif faction == 'Seraphim' then
            CreateLightParticle(unit, -1, unitArmy, 4, 15, 'glow_05', 'ramp_jammer_01')
            templ = unit.TeleportOutFxOverride or EffectTemplate.SeraphimTeleportOut01
        else  -- Aeon or other factions
            templ = unit.TeleportOutFxOverride or EffectTemplate.GenericTeleportOut01
        end
        for _, effect in templ do
            IEffectOffsetEmitter(CreateEmitterAtEntity(unit, unitArmy, effect), 0, offsetY, 0)
        end
    end
end

--- Applies the teleport area damage and creates their effects
---@param unit Unit
function DoTeleportInDamage(unit)
    -- Check for teleport dummy weapon and deal the specified damage. Also show fx.
    local bp = unit.Blueprint
    local Yoffset = TeleportGetUnitYOffset(unit)

    local dmg = 0
    local dmgRadius = 0
    local dmgType = 'Normal'
    local dmgFriendly = false
    if bp.Weapon then
        for _, wep in bp.Weapon do
            if wep.Label == 'TeleportWeapon' then
                dmg = wep.Damage or dmg
                dmgRadius = wep.DamageRadius or dmgRadius
                dmgType = wep.DamageType or dmgType
                dmgFriendly = wep.DamageFriendly or dmgFriendly
                break
            end
        end
        if dmg > 0 and dmgRadius > 0 then
            local faction = bp.General.FactionName
            local army = unit.Army
            local templ
            if unit.TeleportInWeaponFxOverride then
                templ = unit.TeleportInWeaponFxOverride
            elseif faction == 'UEF' then
                templ = EffectTemplate.UEFTeleportInWeapon01
            elseif faction == 'Cybran' then
                templ = EffectTemplate.CybranTeleportInWeapon01
            elseif faction == 'Seraphim' then
                templ = EffectTemplate.SeraphimTeleportInWeapon01
            else -- Aeon or other factions
                templ = EffectTemplate.GenericTeleportInWeapon01
            end

            for _, effect in templ do
                IEffectOffsetEmitter(CreateEmitterAtEntity(unit, army, effect), 0, Yoffset, 0)
            end

            DamageArea(unit, unit:GetPosition(), dmgRadius, dmg, dmgType, dmgFriendly)
        end
    end
end

--- Creates the lingering teleport steam effects
---@param unit Unit
function CreateTeleSteamFX(unit)
    local totalBones = unit:GetBoneCount() - 1
    local unitArmy = unit.Army
    for _, effect in EffectTemplate.UnitTeleportSteam01 do
        for bone = 1, totalBones do
            CreateAttachedEmitter(unit, bone, unitArmy, effect)
        end
    end
end


--- Creates the teleport-in effects
---@param unit Unit
---@param effectsBag TrashBag unused
function PlayTeleportInEffects(unit, effectsBag)
    -- Fired when the unit is being teleported, just after the unit is taken from its original location
    local bp = unit.Blueprint
    local faction = bp.General.FactionName
    local offsetY = TeleportGetUnitYOffset(unit)
    local decalOrient = UtilGetRandomFloat(0, mathTau)
    local unitArmy = unit.Army

    DoTeleportInDamage(unit)  -- Fire teleport weapon

    if bp.Display.TeleportEffects.PlayTeleportInFx ~= false then
        unit:PlayUnitSound('TeleportIn')
        if faction == 'UEF' then
            local templ = unit.TeleportInFxOverride or EffectTemplate.UEFTeleportIn01
            for _, effect in templ do
                IEffectOffsetEmitter(CreateEmitterAtEntity(unit, unitArmy, effect), 0, offsetY, 0)
            end

            CreateDecal(unit:GetPosition(), decalOrient, 'Scorch_generic_002_albedo', '', 'Albedo', 7, 7, 200, 300, unitArmy)

            local fn = function(unit)
                CreateLightParticle(unit, -1, unitArmy, 4, 10, 'glow_03', 'ramp_yellow_01')
                DamageArea(unit, unit:GetPosition(), 9, 1, 'Force', true)

                unit.TeleportFx_IsInvisible = true
                unit:HideBone(0, true)

                WaitSeconds(0.3)

                unit:ShowBone(0, true)
                unit:ShowEnhancementBones()
                unit.TeleportFx_IsInvisible = false

                CreateTeleSteamFX(unit)
            end
            unit:ForkThread(fn)
        elseif faction == 'Cybran' then
            if not unit.TeleportCybranSphere then
                local pos = TeleportLocationToSurface(TableCopy(unit:GetPosition()))
                pos[2] = pos[2] + offsetY
                unit.TeleportCybranSphere = TeleportCreateCybranSphere(unit, pos)
            end

            local templ = unit.TeleportInFxOverride or EffectTemplate.CybranTeleportIn01
            for _, effect in templ do
                IEffectOffsetEmitter(CreateEmitterAtEntity(unit, unitArmy, effect), 0, offsetY, 0)
            end

            CreateLightParticle(unit.TeleportCybranSphere, -1, unitArmy, 4, 10, 'glow_02', 'ramp_white_01')
            DamageArea(unit, unit:GetPosition(), 9, 1, 'Force', true)

            CreateDecal(unit:GetPosition(), decalOrient, 'Scorch_generic_002_albedo', '', 'Albedo', 7, 7, 200, 300, unitArmy)

            local fn = function(unit)
                unit.TeleportFx_IsInvisible = true
                unit:HideBone(0, true)

                WaitSeconds(0.3)

                unit:ShowBone(0, true)
                unit:ShowEnhancementBones()
                unit.TeleportFx_IsInvisible = false

                WaitSeconds(0.8)

                if unit.TeleportCybranSphere then
                    unit.TeleportCybranSphere:Destroy()
                    unit.TeleportCybranSphere = false
                end

                CreateTeleSteamFX(unit)
            end
            unit:ForkThread(fn)
        elseif faction == 'Seraphim' then
            local fn = function(unit)
                local offsetY = TeleportGetUnitYOffset(unit)

                unit.TeleportFx_IsInvisible = true
                unit:HideBone(0, true)

                local templ = unit.TeleportInFxOverride or EffectTemplate.SeraphimTeleportIn01
                for _, effect in templ do
                    IEffectOffsetEmitter(CreateEmitterAtEntity(unit, unitArmy, effect), 0, offsetY, 0)
                end

                CreateLightParticle(unit, -1, unitArmy, 4, 15, 'glow_05', 'ramp_jammer_01')
                DamageArea(unit, unit:GetPosition(), 9, 1, 'Force', true)

                local decalOrient = UtilGetRandomFloat(0, mathTau)
                CreateDecal(unit:GetPosition(), decalOrient, 'crater01_albedo', '', 'Albedo', 4, 4, 200, 300, unitArmy)
                CreateDecal(unit:GetPosition(), decalOrient, 'crater01_normals', '', 'Normals', 4, 4, 200, 300, unitArmy)

                WaitSeconds (0.3)

                unit:ShowBone(0, true)
                unit:ShowEnhancementBones()
                unit.TeleportFx_IsInvisible = false

                WaitSeconds (0.25)

                for _, effect in EffectTemplate.SeraphimTeleportIn02 do
                    IEffectOffsetEmitter(CreateEmitterAtEntity(unit, unitArmy, effect), 0, offsetY, 0)
                end

                CreateTeleSteamFX(unit)
            end

            unit:ForkThread(fn)
        else
            local templ = unit.TeleportInFxOverride or EffectTemplate.GenericTeleportIn01
            for _, effect in templ do
                IEffectOffsetEmitter(CreateEmitterAtEntity(unit, unitArmy, effect), 0, offsetY, 0)
            end

            DamageArea(unit, unit:GetPosition(), 9, 1, 'Force', true)
            CreateDecal(unit:GetPosition(), decalOrient, 'Scorch_generic_002_albedo', '', 'Albedo', 7, 7, 200, 300, unitArmy)
            CreateTeleSteamFX(unit)
        end
    end
end

--- Destroys teleport charge-up effects
---@param unit Unit
---@param effectsBag TrashBag
function DestroyTeleportChargingEffects(unit, effectsBag)
    -- Called when charging up is done because successful or cancelled
    if unit.TeleportChargeBag then
        for _, effect in unit.TeleportChargeBag do
            effect:Destroy()
        end
        unit.TeleportChargeBag = {}
    end
    if unit.TeleportDestChargeBag then
        for _, effect in unit.TeleportDestChargeBag do
            effect:Destroy()
        end
        unit.TeleportDestChargeBag = {}
    end
    if unit.TeleportSoundChargeBag then -- Emptying the sounds so they stop
        for _, effect in unit.TeleportSoundChargeBag do
            effect:Destroy()
        end
        if unit.AmbientSounds then
            unit.AmbientSounds = {} -- For some reason we couldn't simply add this to trash, so emptying it like this
        end
        unit.TeleportSoundChargeBag = {}
    end
    effectsBag:Destroy()

    unit:StopUnitAmbientSound('TeleportChargingAtUnit')
    unit:StopUnitAmbientSound('TeleportChargingAtDestination')
end

--- Destroys the remaining teleport charge-up effects
---@param unit Unit
---@param effectsBag TrashBag unused
function DestroyRemainingTeleportChargingEffects(unit, effectsBag)
    -- Called when we're done teleporting (because successful or cancelled)
    if unit.TeleportCybranSphere then
        unit.TeleportCybranSphere:Destroy()
    end
end

--- Optimized functions --

local EffectUtilitiesOpti = import("/lua/effectutilitiesopti.lua")
local EffectUtilitiesUEF = import("/lua/effectutilitiesuef.lua")
local EffectUtilitiesGeneric = import("/lua/effectutilitiesgeneric.lua")
local EffectUtilitiesAeon = import("/lua/effectutilitiesaeon.lua")

CreateCybranEngineerBuildEffectsOpti = EffectUtilitiesOpti.CreateCybranEngineerBuildEffects
CreateCybranBuildBeamsOpti = EffectUtilitiesOpti.CreateCybranBuildBeams
SpawnBuildBotsOpti = EffectUtilitiesOpti.SpawnBuildBots

CreateAeonBuildBaseThread = EffectUtilitiesAeon.CreateAeonBuildBaseThread
CreateAeonConstructionUnitBuildingEffects = EffectUtilitiesAeon.CreateAeonConstructionUnitBuildingEffects
CreateAeonCommanderBuildingEffects = EffectUtilitiesAeon.CreateAeonCommanderBuildingEffects
CreateAeonFactoryBuildingEffects = EffectUtilitiesAeon.CreateAeonFactoryBuildingEffects
CreateAeonColossusBuildingEffects = EffectUtilitiesAeon.CreateAeonColossusBuildingEffects
CreateAeonCZARBuildingEffects = EffectUtilitiesAeon.CreateAeonCZARBuildingEffects
CreateAeonTempestBuildingEffects = EffectUtilitiesAeon.CreateAeonTempestBuildingEffects
CreateAeonParagonBuildingEffects = EffectUtilitiesAeon.CreateAeonParagonBuildingEffects

CreateEffectsOpti = EffectUtilitiesGeneric.CreateEffectsOpti
CreateEffectsInTrashbag = EffectUtilitiesGeneric.CreateEffectsInTrashbag
CreateEffectsWithOffsetOpti = EffectUtilitiesGeneric.CreateEffectsWithOffsetOpti
CreateEffectsWithOffsetInTrashbag = EffectUtilitiesGeneric.CreateEffectsWithOffsetInTrashbag
CreateEffectsWithRandomOffsetOpti = EffectUtilitiesGeneric.CreateEffectsWithRandomOffsetOpti
CreateEffectsWithRandomOffsetInTrashbag = EffectUtilitiesGeneric.CreateEffectsWithRandomOffsetInTrashbag
CreateBoneEffectsOpti = EffectUtilitiesGeneric.CreateBoneEffectsOpti
CreateBoneEffectsInTrashbag = EffectUtilitiesGeneric.CreateBoneEffectsInTrashbag
CreateBoneEffectsOffsetOpti = EffectUtilitiesGeneric.CreateBoneEffectsOffsetOpti
CreateBoneEffectsOffsetInTrashbag = EffectUtilitiesGeneric.CreateBoneEffectsOffsetInTrashbag
CreateRandomEffectsOpti = EffectUtilitiesGeneric.CreateRandomEffectsOpti
CreateRandomEffectsInTrashbag = EffectUtilitiesGeneric.CreateRandomEffectsInTrashbag
PlayReclaimEffects = EffectUtilitiesGeneric.PlayReclaimEffects
PlayReclaimEndEffects = EffectUtilitiesGeneric.PlayReclaimEndEffects
ApplyWindDirection = EffectUtilitiesGeneric.ApplyWindDirection

CreateDefaultBuildBeams = EffectUtilitiesUEF.CreateDefaultBuildBeams
CreateUEFBuildSliceBeams = EffectUtilitiesUEF.CreateUEFBuildSliceBeams
CreateUEFUnitBeingBuiltEffects = EffectUtilitiesUEF.CreateUEFUnitBeingBuiltEffects
CreateUEFCommanderBuildSliceBeams = EffectUtilitiesUEF.CreateUEFCommanderBuildSliceBeams
CreateBuildCubeThread = EffectUtilitiesUEF.CreateBuildCubeThread
