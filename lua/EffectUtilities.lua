-----------------------------------------------------------------
-- File     :  /lua/EffectUtilities.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Effect Utility functions for scripts.
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local util = import('utilities.lua')
local Entity = import('/lua/sim/Entity.lua').Entity
local EffectTemplate = import('/lua/EffectTemplates.lua')

local CreateEmitterAtBone = CreateEmitterAtBone
local CreateEmitterAtEntity = CreateEmitterAtEntity
local CreateEmitterOnEntity = CreateEmitterOnEntity
local GetTerrainHeight = GetTerrainHeight
local GetTerrainTypeOffset = GetTerrainTypeOffset
local Warp = Warp

local MathAbs = math.abs
local MathCeil = math.ceil
local MathCos = math.cos
local MathPow = math.pow
local MathMax = math.max
local MathMin = math.min
local MathSin = math.sin
local MathTau = 2 * math.pi
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
local UtilGetRandomInt = util.getRandomInt
local UtilGetRandomFloat = util.getRandomFloat
local UtilGetRandomOffset = util.GetRandomOffset
local UtilGetScaledDirectionVector = util.GetScaledDirectionVector

local IEffectOffsetEmitter = moho.IEffect.OffsetEmitter
local IEffectScaleEmitter = moho.IEffect.ScaleEmitter
local IEffectSetEmitterCurveParam = moho.IEffect.SetEmitterCurveParam
local IEffectSetEmitterParam = moho.IEffect.SetEmitterParam
local TrashBagAdd = TrashBag.Add

-- local DeprecatedWarnings = { }

function CreateEffects(obj, army, effectTable)
    local emitters = {}
    for i, effect in effectTable do
        emitters[i] = CreateEmitterAtEntity(obj, army, effect)
    end
    return emitters
end

function CreateEffectsWithOffset(obj, army, effectTable, x, y, z)
    local emitters = {}
    for i, effect in effectTable  do
        emitters[i] = IEffectOffsetEmitter(CreateEmitterAtEntity(obj, army, effect), x, y, z)
    end
    return emitters
end

function CreateEffectsWithRandomOffset(obj, army, effectTable, xRange, yRange, zRange)
    local emitters = {}
    for i, effect in effectTable do
        emitters[i] = IEffectOffsetEmitter(CreateEmitterOnEntity(obj, army, effect), UtilGetRandomOffset(xRange, yRange, zRange, 1))
    end
    return emitters
end

function CreateBoneEffects(obj, bone, army, effectTable)
    local emitters = {}
    for i, effect in effectTable do
        emitters[i] = CreateEmitterAtBone(obj, bone, army, effect)
    end
    return emitters
end

function CreateBoneEffectsOffset(obj, bone, army, effectTable, x, y, z)
    local emitters = {}
    for i, effect in effectTable do
        emitters[i] = IEffectOffsetEmitter(CreateEmitterAtBone(obj, bone, army, effect), x, y, z)
    end
    return emitters
end

function CreateBoneTableEffects(obj, boneTable, army, effectTable)
    for _, bone in boneTable do
        for _, effect in effectTable do
            CreateEmitterAtBone(obj, bone, army, effect)
        end
    end
end

function CreateBoneTableRangedScaleEffects(obj, boneTable, effectTable, army, min, max)
    for _, bone in boneTable do
        for _, effect in effectTable do
            IEffectScaleEmitter(CreateEmitterAtBone(obj, bone, army, effect), UtilGetRandomFloat(min, max))
        end
    end
end

function CreateRandomEffects(obj, army, effectTable, numEffects)
    local numTableEntries = TableGetn(effectTable)
    local emitters = {}
    for i = 1, numEffects do
        emitters[i] = CreateEmitterOnEntity(obj, army, effectTable[UtilGetRandomInt(1, numTableEntries)])
    end
    return emitters
end

function ScaleEmittersParam(emitters, param, minRange, maxRange)
    for _, emitter in emitters do
        IEffectSetEmitterParam(emitter, param, UtilGetRandomFloat(minRange, maxRange))
    end
end

function CreateCybranBuildBeams(builder, unitBeingBuilt, buildEffectBones, buildEffectsBag)

    -- -- deprecation warning for more effcient alternative
    -- if not DeprecatedWarnings.CreateCybranBuildBeams then
    --     DeprecatedWarnings.CreateCybranBuildBeams = true
    --     WARN("CreateCybranBuildBeams is deprecated: use CreateCybranBuildBeamsOpti instead.")
    --     WARN("Source: " .. repr(debug.getinfo(2)))
    -- end

    WaitSeconds(0.2)
    local beamEndEntities = {}
    local ox, oy, oz = unpack(unitBeingBuilt:GetPosition())
    local army = builder.Army

    if buildEffectBones then
        for i, buildBone in buildEffectBones do
            local beamEnd = Entity()
            TrashBagAdd(builder.Trash, beamEnd)
            beamEndEntities[i] = beamEnd
            TrashBagAdd(buildEffectsBag, beamEnd)
            Warp(beamEnd, Vector(ox, oy, oz))
            CreateEmitterOnEntity(beamEnd, army, EffectTemplate.CybranBuildSparks01)
            CreateEmitterOnEntity(beamEnd, army, EffectTemplate.CybranBuildFlash01)
            TrashBagAdd(buildEffectsBag, AttachBeamEntityToEntity(builder, buildBone, beamEnd, -1, army, '/effects/emitters/build_beam_02_emit.bp'))
        end
    end

    while not builder:BeenDestroyed() and not unitBeingBuilt:BeenDestroyed() do
        for _, v in beamEndEntities do
            local x, y, z = builder.GetRandomOffset(unitBeingBuilt, 1)
            if v and not v:BeenDestroyed() then
                Warp(v, Vector(ox + x, oy + y, oz + z))
            end
        end
        WaitSeconds(0.2)
    end
end

function SpawnBuildBots(builder, unitBeingBuilt, buildEffectsBag)

    -- -- deprecation warning for more effcient alternative
    -- if not DeprecatedWarnings.SpawnBuildBots then 
    --     DeprecatedWarnings.SpawnBuildBots = true 
    --     WARN("SpawnBuildBots is deprecated: use SpawnBuildBotsOpti instead.")
    --     WARN("Source: " .. repr(debug.getinfo(2)))
    -- end

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

    -- If is new, won't spawn build bots if they might accidentally capture the unit
    if unitBeingBuiltArmy and (builderArmy == unitBeingBuiltArmy or IsHumanUnit(unitBeingBuilt)) then
        for k, b in buildBots do
            if b:BeenDestroyed() then
                buildBots[k] = nil
            end
        end

        local numUnits = numBots - TableGetsize(buildBots)
        if numUnits > 0 then
            local x, y, z = unpack(builder:GetPosition())
            local qx, qy, qz, qw = unpack(builder:GetOrientation())
            local angleInitial = 180
            local VecMul = 0.5
            local xVec = 0
            local yVec = builder:GetBlueprint().SizeY * 0.5
            local zVec = 0

            local angle = MathTau / numUnits

            -- Launch projectiles at semi-random angles away from the sphere, with enough
            -- initial velocity to escape sphere core
            for i = 0, numUnits - 1 do
                xVec = MathSin(angleInitial + i * angle) * VecMul
                zVec = MathCos(angleInitial + i * angle) * VecMul

                local bot = CreateUnit('ura0001', builderArmy, x + xVec, y + yVec, z + zVec, qx, qy, qz, qw, 'Air')

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

function CreateCybranEngineerBuildEffects(builder, buildBones, buildBots, buildEffectsBag)

    -- -- deprecation warning for more effcient alternative
    -- if not DeprecatedWarnings.CreateCybranEngineerBuildEffects then
    --     DeprecatedWarnings.CreateCybranEngineerBuildEffects = true
    --     WARN("CreateCybranEngineerBuildEffects is deprecated: use CreateCybranEngineerBuildEffectsOpti instead.")
    --     WARN("Source: " .. repr(debug.getinfo(2)))
    -- end
    local army = builder.Army

    -- Create build constant build effect for each build effect bone defined
    if buildBones and buildBots then
        for _, bone in buildBones do
            for _, effect in  EffectTemplate.CybranBuildUnitBlink01 do
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

function CreateCybranFactoryBuildEffects(builder, unitBeingBuilt, buildBones, buildEffectsBag)

    CreateCybranBuildBeams(builder, unitBeingBuilt, buildBones.BuildEffectBones, buildEffectsBag)
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
            IEffectOffsetEmitter(CreateEmitterOnEntity(unitBeingBuilt, builder.Army, effect), sx, sy, sz)
        end
        WaitSeconds(UtilGetRandomFloat(0.1, 0.6))
    end
end

--- Creates the seraphim factory building beam effects.
-- @param builder The factory that is building the unit.
-- @param unitBeingBuilt the unit that is being built by the factory.
-- @param effectBones The bones of the factory to spawn effects for.
-- @param effectsBag The trashbag for effects.
CreateSeraphimUnitEngineerBuildingEffects = import("/lua/EffectUtilitiesSeraphim.lua").CreateSeraphimUnitEngineerBuildingEffects

--- Creates the seraphim factory building effects.
-- @param builder The factory that is building the unit.
-- @param unitBeingBuilt the unit that is being built by the factory.
-- @param effectBones The bones of the factory to spawn effects for.
-- @param locationBone The main build bone where the unit spawns on top of.
-- @param effectsBag The trashbag for effects.
CreateSeraphimFactoryBuildingEffects = import("/lua/EffectUtilitiesSeraphim.lua").CreateSeraphimFactoryBuildingEffects

--- Creates the seraphim build cube effect.
-- @param unitBeingBuilt the unit that is being built by the factory.
-- @param builder The factory that is building the unit.
-- @param effectsBag The trashbag for effects.
-- @param scaleFactor A scale factor for the effects.
CreateSeraphimBuildThread = import("/lua/EffectUtilitiesSeraphim.lua").CreateSeraphimBuildThread

--- Creates the seraphim build cube effect.
-- @param unitBeingBuilt the unit that is being built by the factory.
-- @param builder The factory that is building the unit.
-- @param effectsBag The trashbag for effects.
CreateSeraphimBuildBaseThread = import("/lua/EffectUtilitiesSeraphim.lua").CreateSeraphimBuildBaseThread

--- Creates the seraphim build cube effect.
-- @param unitBeingBuilt the unit that is being built by the factory.
-- @param builder The factory that is building the unit.
-- @param effectsBag The trashbag for effects.
CreateSeraphimExperimentalBuildBaseThread = import("/lua/EffectUtilitiesSeraphim.lua").CreateSeraphimExperimentalBuildBaseThread

function CreateAdjacencyBeams(unit, adjacentUnit, adjacencyBeamsBag)
    local info = {
        Unit = adjacentUnit,
        Trash = TrashBag(),
    }

    TableInsert(adjacencyBeamsBag, info)

    local uBp = unit:GetBlueprint()
    local aBp = adjacentUnit:GetBlueprint()
    local faction = uBp.General.FactionName

    -- Determine which effects we will be using
    local nodeMesh = nil
    local beamEffect = nil
    local emitterNodeEffects = {}
    local numNodes = 2
    local nodeList = {}
    local validAdjacency = true


    local unitPos = unit:GetPosition()
    local adjPos = adjacentUnit:GetPosition()

    -- Create hub start/end and all midpoint nodes
    local unitHubPos = unit:GetPosition()
    local adjacentHubPos = adjacentUnit:GetPosition()

    local spec = { Owner = unit }

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
        local node = {
            entity = Entity(spec),
            pos = {0, 0, 0},
            --mesh = nil,
        }
        node.entity:SetVizToNeutrals('Intel')
        node.entity:SetVizToEnemies('Intel')
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
            perpVec[2] = -perpVec[2]
            perpVec[3] = -perpVec[3]
        end

        local offsetMul = 0.15

        for i = 1, numNodes do
            local segmentMul = i * segmentLen

            if segmentMul <= 0.5 then
                offsetMul = offsetMul + 0.12
            else
                offsetMul = offsetMul - 0.12
            end

            nodeList[i].pos = {
                unitHubPos[1] - (directionVec[1] * segmentMul) - (perpVec[1] * offsetMul),
                nil,
                unitHubPos[3] - (directionVec[3] * segmentMul) - (perpVec[3] * offsetMul),
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
                perpVec[2] = -perpVec[2]
                perpVec[3] = -perpVec[3]
            end

            -- Initialize 2 midpoint segments
            nodeList[1].pos = {
                unitHubPos[1] - directionVec[1],
                unitHubPos[2] - directionVec[2],
                unitHubPos[3] - directionVec[3]
            }
            nodeList[2].pos = {
                adjacentHubPos[1] + directionVec[1],
                adjacentHubPos[2] + directionVec[2],
                adjacentHubPos[3] + directionVec[3]
            }

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
            if unitSkirtBounds[3] == adjacentSkirtBounds[1] then
                nodeList[1].pos[1] = unitHubPos[1]
                nodeList[2].pos[1] = adjacentHubPos[1]
                nodeList[1].pos[3] = (unitHubPos[3] + adjacentHubPos[3]) * 0.5 - UtilGetRandomFloat(0, 1)
                nodeList[2].pos[3] = (unitHubPos[3] + adjacentHubPos[3]) * 0.5 + UtilGetRandomFloat(0, 1)
            elseif unitSkirtBounds[1] == adjacentSkirtBounds[3] then
                nodeList[1].pos[1] = unitHubPos[1]
                nodeList[2].pos[1] = adjacentHubPos[1]
                nodeList[1].pos[3] = (unitHubPos[3] + adjacentHubPos[3]) * 0.5 + UtilGetRandomFloat(0, 1)
                nodeList[2].pos[3] = (unitHubPos[3] + adjacentHubPos[3]) * 0.5 - UtilGetRandomFloat(0, 1)
            elseif unitSkirtBounds[4] == adjacentSkirtBounds[2] then
                nodeList[1].pos[1] = (unitHubPos[1] + adjacentHubPos[1]) * 0.5 - UtilGetRandomFloat(0, 1)
                nodeList[2].pos[1] = (unitHubPos[1] + adjacentHubPos[1]) * 0.5 + UtilGetRandomFloat(0, 1)
                nodeList[1].pos[3] = unitHubPos[3]
                nodeList[2].pos[3] = adjacentHubPos[3]
            elseif unitSkirtBounds[2] == adjacentSkirtBounds[4] then
                nodeList[1].pos[1] = (unitHubPos[1] + adjacentHubPos[1]) * 0.5 + UtilGetRandomFloat(0, 1)
                nodeList[2].pos[1] = (unitHubPos[1] + adjacentHubPos[1]) * 0.5 - UtilGetRandomFloat(0, 1)
                nodeList[1].pos[3] = unitHubPos[3]
                nodeList[2].pos[3] = adjacentHubPos[3]
            else
                validAdjacency = false
            end
        end
    elseif faction == 'UEF' then
        if unitPos[1] == adjPos[1] or unitPos[3] == adjPos[3] then
            local directionVec = UtilGetScaledDirectionVector(unitHubPos, adjacentHubPos, 0.35)
            directionVec[2] = 0
            local perpVec = UtilCross(directionVec, Vector(0, 0.35, 0))
            if UtilGetRandomInt(0, 1) == 1 then
                perpVec[1] = -perpVec[1]
                perpVec[2] = -perpVec[2]
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
                nodeList[1].pos[1] = unitHubPos[1]
                nodeList[2].pos[1] = adjacentHubPos[1]
                nodeList[1].pos[3] = (unitHubPos[3] + adjacentHubPos[3]) * 0.5
                nodeList[2].pos[3] = (unitHubPos[3] + adjacentHubPos[3]) * 0.5

            -- Unit right skirt is on left skirt of adjacent unit
            elseif unitSkirtBounds[4] == adjacentSkirtBounds[2] or unitSkirtBounds[2] == adjacentSkirtBounds[4] then
                nodeList[1].pos[1] = (unitHubPos[1] + adjacentHubPos[1]) * 0.5
                nodeList[2].pos[1] = (unitHubPos[1] + adjacentHubPos[1]) * 0.5
                nodeList[1].pos[3] = unitHubPos[3]
                nodeList[2].pos[3] = adjacentHubPos[3]
            else
                validAdjacency = false
            end
        end
    end

    if validAdjacency then
        local unitArmy = unit.Army
        -- Offset beam positions above the ground at current positions terrain height
        for _, node in nodeList do
            node.pos[2] = GetTerrainHeight(node.pos[1], node.pos[3]) + verticalOffset
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
                    TrashBagAdd(info.Trash, emitter)
                    TrashBagAdd(unit.Trash, emitter)
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
            TrashBagAdd(info.Trash, entity)
            TrashBagAdd(unit.Trash, entity)
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
                local beam = AttachBeamEntityToEntity(node.entity, -1, nodeList[i + 1].entity, -1, unitArmy, beamEffect)
                TrashBagAdd(info.Trash, beam)
                TrashBagAdd(unit.Trash, beam)
            end
        end
    end
end

function PlaySacrificingEffects(unit, target_unit)
    if unit.Blueprint.General.FactionName == 'Aeon' then
        local unitArmy = unit.Army
        local unitTrash = unit.Trash
        for _, effect in EffectTemplate.ASacrificeOfTheAeon01 do
            TrashBagAdd(unitTrash, CreateEmitterOnEntity(unit, unitArmy, effect))
        end
    end
end

function PlaySacrificeEffects(unit, targetUnit)
    if unit.Blueprint.General.FactionName == 'Aeon' then
        for _, effect in EffectTemplate.ASacrificeOfTheAeon02 do
            CreateEmitterAtEntity(targetUnit, unit.Army, effect)
        end
    end
end



function PlayCaptureEffects(capturer, captive, buildEffectBones, effectsBag)
    local capturerArmy = capturer.Army
    for _, bone in buildEffectBones do
        for _, effect in EffectTemplate.CaptureBeams do
            local beamEffect = AttachBeamEntityToEntity(capturer, bone, captive, -1, capturerArmy, effect)
            TrashBagAdd(effectsBag, beamEffect)
        end
    end
end

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

function CreateEnhancementEffectAtBone(unit, bone, trashbag)
    for _, effect in EffectTemplate.UpgradeBoneAmbient do
        TrashBagAdd(trashbag, CreateAttachedEmitter(unit, bone, unit.Army, effect))
    end
end

function CreateEnhancementUnitAmbient(unit, bone, trashbag)
    local unitArmy = unit.Army
    for _, effect in EffectTemplate.UpgradeUnitAmbient do
        TrashBagAdd(trashbag, CreateAttachedEmitter(unit, bone, unitArmy, effect))
    end
end

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

function SeraphimRiftIn(unit)
    unit:HideBone(0, true)
    for _, effect in EffectTemplate.SerRiftIn_Small do
        CreateAttachedEmitter(unit, -1, unit.Army, effect)
    end
    WaitSeconds (2.0)

    CreateLightParticle(unit, -1, unit.Army, 4, 15, 'glow_05', 'ramp_jammer_01')
    WaitSeconds (0.1)

    unit:ShowBone(0, true)
    WaitSeconds (0.25)

    for _, effect in EffectTemplate.SerRiftIn_SmallFlash do
        CreateAttachedEmitter(unit, -1, unit.Army, effect)
    end
end

function SeraphimRiftInLarge(unit)
    unit:HideBone(0, true)
    for _, effect in EffectTemplate.SerRiftIn_Large do
        CreateAttachedEmitter(unit, -1, unit.Army, effect)
    end
    WaitSeconds (2.0)

    CreateLightParticle(unit, -1, unit.Army, 25, 15, 'glow_05', 'ramp_jammer_01')
    WaitSeconds (0.1)

    unit:ShowBone(0, true)
    WaitSeconds (0.25)

    for _, effect in EffectTemplate.SerRiftIn_LargeFlash do
        CreateAttachedEmitter(unit, -1, unit.Army, effect)
    end
end

function CybranBuildingInfection(unit)
    local unitArmy = unit.Army
    for _, effect in EffectTemplate.CCivilianBuildingInfectionAmbient do
        CreateAttachedEmitter(unit, -1, unitArmy, effect)
    end
end

function CybranQaiShutdown(unit)
    local unitArmy = unit.Army
    for _, effect in EffectTemplate.CQaiShutdown do
        CreateAttachedEmitter(unit, -1, unitArmy, effect)
    end
end

function AeonHackACU(unit)
    local unitArmy = unit.Army
    for _, effect in EffectTemplate.AeonOpHackACU do
        CreateAttachedEmitter(unit, -1, unitArmy, effect)
    end
end

-- New function for insta capture fix
function IsHumanUnit(self)
    local selfArmy = self.Army
    for _, army in ScenarioInfo.ArmySetup do
        if army.ArmyIndex == selfArmy then
            return army.Human == true
        end
    end
end

function PlayTeleportChargingEffects(unit, teleDest, effectsBag, teleDelay)
    -- Plays teleport effects for the given unit
    if not unit then
        return
    end

    local bp = unit:GetBlueprint()
    local faction = bp.General.FactionName
    local Yoffset = TeleportGetUnitYOffset(unit)
    local unitArmy = unit.Army

    teleDest = TeleportLocationToSurface(teleDest)

    -- Play tele FX at unit location
    if bp.Display.TeleportEffects.PlayChargeFxAtUnit ~= false then
        unit:PlayUnitAmbientSound('TeleportChargingAtUnit')

        if faction == 'UEF' then
            -- We recycle the teleport destination effects since they are way more epic
            teleChargeBag = {}
            unit.TeleportChargeBag = teleChargeBag
            local k = 1
            local telefx = EffectTemplate.UEFTeleportCharge02
            for _, effect in telefx do
                local fx = CreateEmitterAtEntity(unit, unitArmy, effect)
                IEffectOffsetEmitter(fx, 0, Yoffset, 0)
                IEffectScaleEmitter(fx, 0.75)
                fx:SetEmitterCurveParam('Y_POSITION_CURVE', 0, Yoffset * 2) -- To make effects cover entire height of unit
                fx:SetEmitterCurveParam('ROTATION_RATE_CURVE', 1, 0) -- Small initial rotation, will be faster as charging
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

    unitArmy = unit.Army

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
                unit.Trash:Add(sndEnt)
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
                IEffectOffsetEmitter(fx, 0, Yoffset, 0)
                IEffectScaleEmitter(fx, 0.75)
                IEffectSetEmitterCurveParam(fx, 'Y_POSITION_CURVE', 0, Yoffset * 2) -- To make effects cover entire height of unit
                IEffectSetEmitterCurveParam(fx, 'ROTATION_RATE_CURVE', 1, 0) -- Small initial rotation, will be faster as charging
                TableInsert(unit.TeleportDestChargeBag, fx)
                TrashBagAdd(effectsBag, fx)
            end
        elseif faction == 'Cybran' then
            local pos = table.copy(teleDest)
            pos[2] = pos[2] + Yoffset -- Make sure sphere isn't half in the ground
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
                IEffectOffsetEmitter(fx, 0, Yoffset, 0)
                IEffectScaleEmitter(fx, 0.01)
                TableInsert(unit.TeleportDestChargeBag, fx)
                TrashBagAdd(effectsBag, fx)
            end

            teleportDestFxEntity:Destroy()
        else
            local telefx = EffectTemplate.GenericTeleportCharge02
            for _, effect in telefx do
                local fx = CreateEmitterAtEntity(teleportDestFxEntity, unitArmy, effect)
                IEffectOffsetEmitter(fx, 0, Yoffset, 0)
                IEffectScaleEmitter(fx, 0.01)
                TableInsert(unit.TeleportDestChargeBag, fx)
                TrashBagAdd(effectsBag, fx)
            end

            teleportDestFxEntity:Destroy()
        end
    end
end

function TeleportGetUnitYOffset(unit)
    -- Returns how high to create effects to make the effects appear in the center of the unit
    local bp = unit.Blueprint
    return bp.Display.TeleportEffects.FxChargeAtDestOffsetY or ((bp.Physics.MeshExtentsY or bp.SizeY or 2) / 2)
end

function TeleportGetUnitSizes(unit)
    -- Returns the sizes of the unit, to be used for teleportation effects
    local bp = unit.Blueprint
    local telefx = bp.Display.TeleportEffects
    return (telefx.FxSizeX or bp.Physics.MeshExtentsX or bp.SizeX or 1),
           (telefx.FxSizeY or bp.Physics.MeshExtentsY or bp.SizeY or 1),
           (telefx.FxSizeZ or bp.Physics.MeshExtentsZ or bp.SizeZ or 1),
           (telefx.FxOffsetX or bp.CollisionOffsetX or 0),
           (telefx.FxOffsetY or bp.CollisionOffsetY or 0),
           (telefx.FxOffsetZ or bp.CollisionOffsetZ or 0)
end

function TeleportLocationToSurface(loc)
    -- Takes the given location, adjust the Y value to the surface height on that location
    local pos = table.copy(loc)
    pos[2] = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3])
    return pos
end

function TeleportShowChargeUpFxAtUnit(unit, effectTemplate, effectsBag)
    -- Creates charge up effects at the unit
    local bp = unit:GetBlueprint()
    local bones = bp.Display.TeleportEffects.ChargeFxAtUnitBones or {Bone = 0, Offset = {0, 0.25, 0}, }
    local unitArmy = unit.Army
    local bone, ox, oy, oz
    local emitters = {}
    local k = 1
    for _, value in bones do
        bone = value.Bone or 0
        ox = value.Offset[1] or 0
        oy = value.Offset[2] or 0
        oz = value.Offset[3] or 0
        for _, effect in effectTemplate do
            local fx = IEffectOffsetEmitter(CreateEmitterAtBone(unit, bone, unitArmy, effect), ox, oy, oz)
            emitters[k] = fx
            k = k + 1
            TrashBagAdd(effectsBag, fx)
        end
    end
    return emitters
end

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

function TeleportChargingProgress(unit, fraction)
    local bp = unit.Blueprint

    if bp.Display.TeleportEffects.PlayChargeFxAtDestination ~= false then
        fraction = MathMin(MathMax(fraction, 0.01), 1)
        local faction = bp.General.FactionName

        if faction == 'UEF' then
            -- Increase rotation of effects as progressing
            if unit.TeleportDestChargeBag then
                local scale = 0.75 + (0.5 * math.max(fraction, 0.01))
                for _, fx in unit.TeleportDestChargeBag do
                    IEffectSetEmitterCurveParam(fx, 'ROTATION_RATE_CURVE', -(25 + (100 * fraction)), (30 * fraction))
                    IEffectScaleEmitter(fx, scale)
                end

                -- Scale FX at unit location as well
                for _, fx in unit.TeleportChargeBag do
                    IEffectSetEmitterCurveParam(fx, 'ROTATION_RATE_CURVE', -(25 + (100 * fraction)), (30 * fraction))
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

            local scale = (2 * fraction) - MathPow(fraction, 2)
            for _, fx in unit.TeleportDestChargeBag do
                IEffectScaleEmitter(fx, scale)
            end
        end
    end
end

function PlayTeleportOutEffects(unit, EffectsBag)
    -- Fired when the unit is being teleported, just before the unit is taken from its original location
    local bp = unit.Blueprint
    local faction = bp.General.FactionName
    local Yoffset = TeleportGetUnitYOffset(unit)

    if bp.Display.TeleportEffects.PlayTeleportOutFx ~= false then
        unit:PlayUnitSound('TeleportOut')
        local unitArmy = unit.Army
        if faction == 'UEF' then
            local scaleX, scaleY, scaleZ = TeleportGetUnitSizes(unit)
            local cfx = unit:CreateProjectile('/effects/Entities/UEFBuildEffect/UEFBuildEffect02_proj.bp', 0, 0, 0, nil, nil, nil)
            cfx:SetScale(scaleX, scaleY, scaleZ)
            EffectsBag:Add(cfx)

            CreateLightParticle(unit, -1, unitArmy, 3, 7, 'glow_03', 'ramp_blue_02')
            local templ = unit.TeleportOutFxOverride or EffectTemplate.UEFTeleportOut01
            for _, effect in templ do
                IEffectOffsetEmitter(CreateEmitterAtEntity(unit, unitArmy, effect), 0, Yoffset, 0)
            end
        elseif faction == 'Cybran' then
            CreateLightParticle(unit, -1, unitArmy, 4, 10, 'glow_02', 'ramp_red_06')
            local templ = unit.TeleportOutFxOverride or EffectTemplate.CybranTeleportOut01
            for _, effect in templ do
                IEffectOffsetEmitter(CreateEmitterAtEntity(unit, unitArmy, effect), 0, Yoffset, 0)
            end
        elseif faction == 'Seraphim' then
            CreateLightParticle(unit, -1, unitArmy, 4, 15, 'glow_05', 'ramp_jammer_01')
            local templ = unit.TeleportOutFxOverride or EffectTemplate.SeraphimTeleportOut01
            for _, effect in templ do
                IEffectOffsetEmitter(CreateEmitterAtEntity(unit, unitArmy, effect), 0, Yoffset, 0)
            end
        else  -- Aeon or other factions
            local templ = unit.TeleportOutFxOverride or EffectTemplate.GenericTeleportOut01
            for _, effect in templ do
                CreateEmitterAtEntity(unit, unitArmy, effect)
            end
        end
    end
end

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

function CreateTeleSteamFX(unit)
    local totalBones = unit:GetBoneCount() - 1
    local unitArmy = unit.Army
    for _, effect in EffectTemplate.UnitTeleportSteam01 do
        for bone = 1, totalBones do
            CreateAttachedEmitter(unit, bone, unitArmy, effect)
        end
    end
end

function PlayTeleportInEffects(unit, effectsBag)
    -- Fired when the unit is being teleported, just after the unit is taken from its original location
    local bp = unit.Blueprint
    local faction = bp.General.FactionName
    local offsetY = TeleportGetUnitYOffset(unit)
    local decalOrient = UtilGetRandomFloat(0, MathTau)
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

                local decalOrient = UtilGetRandomFloat(0, MathTau)
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

function DestroyTeleportChargingEffects(unit, effectsBag)
    -- Called when charging up is done because successful or cancelled
    if unit.TeleportChargeBag then
        for _, values in unit.TeleportChargeBag do
            values:Destroy()
        end
        unit.TeleportChargeBag = {}
    end
    if unit.TeleportDestChargeBag then
        for _, values in unit.TeleportDestChargeBag do
            values:Destroy()
        end
        unit.TeleportDestChargeBag = {}
    end
    if unit.TeleportSoundChargeBag then -- Emptying the sounds so they stop.
        for _, values in unit.TeleportSoundChargeBag do
            values:Destroy()
        end
        if unit.AmbientSounds then
            unit.AmbientSounds = {} -- For some reason we couldnt simply add this to trash so empyting it like this
        end
        unit.TeleportSoundChargeBag = {}
    end
    effectsBag:Destroy()

    unit:StopUnitAmbientSound('TeleportChargingAtUnit')
    unit:StopUnitAmbientSound('TeleportChargingAtDestination')
end

function DestroyRemainingTeleportChargingEffects(unit, effectsBag)
    -- Called when we're done teleporting (because succesfull or cancelled)
    if unit.TeleportCybranSphere then
        unit.TeleportCybranSphere:Destroy()
    end
end

--- Optimized functions --

local EffectUtilitiesOpti = import('/lua/EffectUtilitiesOpti.lua')

--- Creates tracker beams between the builder and its build bots. The
-- bots keep the tracker in their trashbag.
-- @param builder The builder / tracking entity of the build bots.
-- @param buildBones The bones to use as the origin of the beams.
-- @param buildBots The build bots that we're tracking.
-- @param total The number of build bots / bones. The 1st bone will track the 1st bot, etc.
CreateCybranEngineerBuildEffectsOpti = EffectUtilitiesOpti.CreateCybranEngineerBuildEffects
-- original: CreateCybranEngineerBuildEffects

--- Creates the beams and welding points of the builder and its bots. The
-- bots share the welding point which each other, as does the builder with
-- itself.
-- @param builder A builder with builder.BuildEffectBones set. 
-- @param bots The bots of the builder.
-- @param unitBeingBuilt The unit that we're building.
-- @param buildEffectsBag The bag that we use to store / trash all effects.
-- @param stationary Whether or not the builder is a building.
CreateCybranBuildBeamsOpti = EffectUtilitiesOpti.CreateCybranBuildBeams
-- original: CreateCybranBuildBeams

--- Creates the build drones for the (cybran) builder in question. Expects  
-- the builder.BuildBotTotal value to be set.
-- @param builder A cybran builder such as an engineer, hive or commander.
-- @param botBlueprint The blueprint to use for the bot.
SpawnBuildBotsOpti = EffectUtilitiesOpti.SpawnBuildBots
-- original: SpawnBuildBots

--- The build animation for Aeon buildings in general.
-- @param unitBeingBuilt The unit we're trying to build.
-- @param effectsBag The build effects bag containing the pool and emitters.
CreateAeonBuildBaseThread = import("/lua/EffectUtilitiesAeon.lua").CreateAeonBuildBaseThread

--- The build animation of an engineer.
-- @param builder The engineer in question.
-- @param unitBeingBuilt The unit we're building.
-- @param buildEffectsBag The trash bag for the build effects.
CreateAeonConstructionUnitBuildingEffects = import("/lua/EffectUtilitiesAeon.lua").CreateAeonConstructionUnitBuildingEffects
-- original: CreateAeonConstructionUnitBuildingEffects

--- The build animation of the commander.
-- @param builder The commander in question.
-- @param unitBeingBuilt The unit we're building.
-- @param buildEffectBones The bone(s) of the commander where the effect starts.
-- @param buildEffectsBag The trash bag for the build effects.
CreateAeonCommanderBuildingEffects = import("/lua/EffectUtilitiesAeon.lua").CreateAeonCommanderBuildingEffects
-- original: CreateAeonCommanderBuildingEffects

--- The build animation for Aeon factories, including the pool and dummy unit.
-- @param builder The factory that is building the unit.
-- @param unitBeingBuilt The unit we're trying to build.
-- @param buildEffectBones The arms of the factory where the build beams come from.
-- @param buildBone The location where the unit is beint built.
-- @param effectsBag The build effects bag.
CreateAeonFactoryBuildingEffects = import("/lua/EffectUtilitiesAeon.lua").CreateAeonFactoryBuildingEffects
-- original: CreateAeonFactoryBuildingEffects

--- Creates the Aeon Tempest build effects, including particles and an animation.
-- @param unitBeingBuilt The Colossus that is being built.
CreateAeonColossusBuildingEffects = import("/lua/EffectUtilitiesAeon.lua").CreateAeonColossusBuildingEffects

--- Creates the Aeon CZAR build effects, including particles.
-- @param unitBeingBuilt The CZAR that is being built.
CreateAeonCZARBuildingEffects = import("/lua/EffectUtilitiesAeon.lua").CreateAeonCZARBuildingEffects

--- Creates the Aeon Tempest build effects, including particles and an animation.
-- @param unitBeingBuilt The tempest that is being built.
CreateAeonTempestBuildingEffects = import("/lua/EffectUtilitiesAeon.lua").CreateAeonTempestBuildingEffects

--- Creates the Aeon Paragon build effects, including particles and an animation.
-- @param unitBeingBuilt The tempest that is being built.
CreateAeonParagonBuildingEffects = import("/lua/EffectUtilitiesAeon.lua").CreateAeonParagonBuildingEffects

--- Played when reclaiming starts.
-- @param reclaimer Unit that is reclaiming
-- @param reclaimed Unit that is reclaimed 
-- @param buildEffectBones Bones of the reclaimer to create beams from towards the reclaimed
-- @param effectsBag Trashbag that stores the effects
PlayReclaimEffects = import("/lua/EffectUtilitiesGeneric.lua").PlayReclaimEffects

--- Played when reclaiming has been completed.
-- @param reclaimer Unit that is reclaiming
-- @param reclaimed Unit that is reclaimed (and no longer exists after this effect)
PlayReclaimEndEffects = import("/lua/EffectUtilitiesGeneric.lua").PlayReclaimEndEffects

--- Played when reclaiming has been completed.
-- @param reclaimer Unit that is reclaiming
-- @param reclaimed Unit that is reclaimed (and no longer exists after this effect)
ApplyWindDirection = import("/lua/EffectUtilitiesGeneric.lua").ApplyWindDirection

--- Creates the default build beams that, among others, UEF engineers use to build non-UEF units
-- @param builder The builder
-- @param unitBeingBuilt The unit being build
-- @param buildEffectBones The effect bones of the builder
-- @param buildeffectsBag The effects bag of the builder
CreateDefaultBuildBeams = import("/lua/EffectUtilitiesUEF.lua").CreateDefaultBuildBeams

--- Creates the slice beams that UEF engineers use to build UEF units 
-- @param builder The builder
-- @param unitBeingBuilt The unit being build
-- @param buildEffectBones The effect bones of the builder
-- @param buildeffectsBag The effects bag of the builder
CreateUEFBuildSliceBeams = import("/lua/EffectUtilitiesUEF.lua").CreateUEFBuildSliceBeams

--- Creates the UEF unit being built effects
-- @param builder The builder
-- @param unitBeingBuilt The unit being build
-- @param buildeffectsBag The effects bag of the unit being built
CreateUEFUnitBeingBuiltEffects = import("/lua/EffectUtilitiesUEF.lua").CreateUEFUnitBeingBuiltEffects

--- Creates the commander-like slice beams where two beams originate from the build effect bones instead of one. 
-- This function is not optimized.
-- @param builder a (S)ACU
-- @param unitBeingBuilt The unit being build
-- @param buildEffectBones The effect bones of the builder
-- @param buildeffectsBag The effects bag of the builder
CreateUEFCommanderBuildSliceBeams = import("/lua/EffectUtilitiesUEF.lua").CreateUEFCommanderBuildSliceBeams

--- Creates the build cube used by UEF structures
-- @param builder The builder
-- @param unitBeingBuilt The unit being build
-- @param onBeingBuiltEffectsBag The Effects bag of the unit being built
CreateBuildCubeThread = import("/lua/EffectUtilitiesUEF.lua").CreateBuildCubeThread
