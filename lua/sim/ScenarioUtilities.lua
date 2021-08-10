----[                                                                             ]--
----[  File     : ScenarioUtilities.lua                                           ]--
----[  Author(s): Ivan Rumsey                                                     ]--
----[                                                                             ]--
----[  Summary  : Utility functions for use with scenario save file.              ]--
----[             Created from examples provided by Jeff Petkau.                  ]--
----[                                                                             ]--
----[  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.             ]--
local Entity = import('/lua/sim/Entity.lua').Entity

function EnableLoadBalance(enabled, unitThreshold) --distributeTime)
    if not ScenarioInfo.LoadBalance then
        ScenarioInfo.LoadBalance =
        {
            Accumulator = 0,
            Enabled = false,
            SpawnGroups = {},
            PlatoonGroups = {},
        }
    end

    if enabled == ScenarioInfo.LoadBalance.Enabled then return end

    ScenarioInfo.LoadBalance.Enabled = enabled

    if enabled then
        ScenarioInfo.LoadBalance.UnitThreshold = unitThreshold or 50
    else
        ForkThread(function()
            --local timePerGroup = ScenarioInfo.DistributeTime/table.getn(ScenarioInfo.LoadBalance.SpawnGroups)

            --Get time
            local time = GetSystemTimeSecondsOnlyForProfileUse()

            --Spawn bases
            while not table.empty(ScenarioInfo.LoadBalance.SpawnGroups) do
                local base, name, uncapturable = unpack(table.remove(ScenarioInfo.LoadBalance.SpawnGroups, 1))
                base:SpawnGroup(name, uncapturable, true)
            end

            --Spawn units
            while not table.empty(ScenarioInfo.LoadBalance.PlatoonGroups) do
                local strArmy, strGroup, formation, callback = unpack(table.remove(ScenarioInfo.LoadBalance.PlatoonGroups, 1))
                CreateArmyGroupAsPlatoonBalanced(strArmy, strGroup, formation, callback)
            end

            --Report time taken
            LOG("Time to spawn: " .. (GetSystemTimeSecondsOnlyForProfileUse() - time))
        end)
    end
end

function GetMarkers()
    return Scenario.MasterChain._MASTERCHAIN_.Markers
end

function GetMarker(name)
    return Scenario.MasterChain._MASTERCHAIN_.Markers[name]
end

function ChainToPositions(chainName)
    local chain = Scenario.Chains[chainName]
    if not chain then
        error('ERROR: Invalid Chain Named- ' .. chainName, 2)
    end
    local positionTable = {}
    for num, marker in chain.Markers do
        table.insert(positionTable, Scenario.MasterChain._MASTERCHAIN_.Markers[marker]['position'])
    end
    return positionTable
end

----[  FindParentChain                                                ]--
----[                                                                      ]--
----[  Gets the parent chain that the supplied marker belongs to           ]--
function FindParentChain(markerName)
    for cName,chain in Scenario.Chains do
        for mNum,marker in chain.Markers do
            if marker == markerName then
                return chain
            end
        end
    end
    return nil
end

function GetMarkerChain(name)
    local chain = Scenario.Chains[name]
    if not chain then
        error('ERROR: Invalid Chain Named- ' .. name, 2)
    end
    return chain
end

----[  MarkerToPosition                                                           ]--
----[                                                                             ]--
----[  Converts a marker as specified in *_save.lua file to a position.           ]--
function MarkerToPosition(strMarker)
    local marker = GetMarker(strMarker)
        if not marker then
            error('ERROR: Invalid marker name- '..strMarker)
        end
    return marker.position
end

----[  AreaToRect                                                                 ]--
----[                                                                             ]--
----[  Converts an area as specified in *_save.lua file to a rectangle.           ]--
function AreaToRect(strArea)
    local area = Scenario.Areas[strArea]
    if not area then
        error('ERROR: Invalid area name')
    end
    local rectangle = area.rectangle
    return Rect(rectangle[1],rectangle[2],rectangle[3],rectangle[4])
end

function InRect(vectorPos, rect)
    return vectorPos[1] > rect.x0 and vectorPos[1] < rect.x1 and
           vectorPos[3] > rect.y0 and vectorPos[3] < rect.y1
end

----[  AssembleUnitGroup                                                          ]--
----[                                                                             ]--
----[  Returns all units (leaf nodes) under the specified group.                  ]--
function AssembleUnitGroup(tblNode,tblResult)
    tblResult = tblResult or {}

    if nil == tblNode then
        return tblResult
    end

    for strName, tblData in pairs(tblNode.Units) do
        if 'GROUP' == tblData.type then
            tblResult = AssembleUnitGroup(tblData,tblResult)
        else
            tblResult[strName] = tblData
        end
    end

    return tblResult
end

----[  AssemblePlatoons                                                           ]--
----[                                                                             ]--
----[  Returns all platoon template names specified under group.                  ]--
function AssemblePlatoons(tblNode,tblResult)
    tblResult = tblResult or {}

    if nil == tblNode then
        return tblResult
    end

    if nil ~= tblNode.platoon and '' ~= tblNode.platoon then
        table.insert(tblResult,tblNode.platoon)
    end

    if 'GROUP' == tblNode.type then
        for strName, tblData in pairs(tblNode.Units) do
            tblResult = AssemblePlatoons(tblData,tblResult)
        end
    end

    return tblResult
end

----[  FindUnit                                                                   ]--
----[                                                                             ]--
----[  Finds the unit with the specified name.                                    ]--
function FindUnit(strUnit,tblNode)
    if nil == tblNode then
        return nil
    end

    local tblResult = nil

    for strName, tblData in pairs(tblNode.Units) do
        if 'GROUP' == tblData.type then
            tblResult = FindUnit(strUnit,tblData)
        elseif strName == strUnit then
            tblResult = tblData
        end

        if nil ~= tblResult then
            break
        end
    end

    return tblResult
end

----[  CreateArmyUnit                                                             ]--
----[                                                                             ]--
----[  Creates a named unit in an army.                                           ]--
function CreateArmyUnit(strArmy,strUnit)
    local tblUnit = FindUnit(strUnit,Scenario.Armies[strArmy].Units)
    local brain = GetArmyBrain(strArmy)
    if not brain.IgnoreArmyCaps then
        SetIgnoreArmyUnitCap(brain:GetArmyIndex(), true)
    end
    if nil ~= tblUnit then
        local unit = CreateUnitHPR(
            tblUnit.type,
            strArmy,
            tblUnit.Position[1], tblUnit.Position[2], tblUnit.Position[3],
            tblUnit.Orientation[1], tblUnit.Orientation[2], tblUnit.Orientation[3]
        )
        if unit.Blueprint.Physics.FlattenSkirt then
            unit:CreateTarmac(true, true, true, false, false)
        end
        local platoon
        if tblUnit.platoon ~= nil and tblUnit.platoon ~= '' then
            local i = 3
            while i <= table.getn(Scenario.Platoons[tblUnit.platoon]) do
                if tblUnit.Type == currTemplate[i][1] then
                    platoon = brain:MakePlatoon('None', 'None')
                    brain:AssignUnitsToPlatoon(platoon, {unit}, currTemplate[i][4], currTemplate[i][5])
                    break
                end
                i = i + 1
            end
        end
        local armyIndex = brain:GetArmyIndex()
        if ScenarioInfo.UnitNames[armyIndex] then
            ScenarioInfo.UnitNames[armyIndex][strUnit] = unit
        end
        unit.UnitName = strUnit
        if not brain.IgnoreArmyCaps then
            SetIgnoreArmyUnitCap(brain:GetArmyIndex(), false)
        end
        return unit, platoon, tblUnit.platoon
    end
    if not brain.IgnoreArmyCaps then
        SetIgnoreArmyUnitCap(brain:GetArmyIndex(), false)
    end
    return nil
end

----[  FindUnitGroup                                                              ]--
----[                                                                             ]--
----[  Finds the unit group with the specified name.                              ]--
function FindUnitGroup(strGroup,tblNode)
    if nil == tblNode then
        return nil
    end

    local tblResult = nil
    for strName, tblData in pairs(tblNode.Units) do
        if 'GROUP' == tblData.type then
            if strName == strGroup then
                tblResult = tblData
            else
                tblResult = FindUnitGroup(strGroup,tblData)
            end
        end

        if nil ~= tblResult then
            break
        end
    end

    return tblResult
end

----[  AssembleArmyGroup                                                          ]--
----[                                                                             ]--
----[  Returns a table of units in the group owned by the specified army.         ]--
function AssembleArmyGroup(strArmy,strGroup)
    return AssembleUnitGroup(FindUnitGroup(strGroup,Scenario.Armies[strArmy].Units))
end

----[  CreateArmySubGroup                                                                      ]--
----[                                                                                          ]--
----[  Creates Army groups from a number of groups specified in order from the Units Hierarchy ]--
function CreateArmySubGroup(strArmy,strGroup,...)
    local tblNode = Scenario.Armies[strArmy].Units
    local tblResult = {}
    local treeResult = {}
    local platoonList = {}
    local brain = GetArmyBrain(strArmy)
    if not brain.IgnoreArmyCaps then
        SetIgnoreArmyUnitCap(brain:GetArmyIndex(), true)
    end
    for strName, tblData in pairs(tblNode.Units) do
        if 'GROUP' == tblData.type then
            if strName == strGroup then
                if arg['n'] >= 1 then
                    platoonList, tblResult, treeResult = CreateSubGroup(tblNode.Units[strName], strArmy, unpack(arg))
                else
                    platoonList, tblResult, treeResult = CreatePlatoons(strArmy, tblNode.Units[strName])
                end
            end
        end
    end
    if not brain.IgnoreArmyCaps then
        SetIgnoreArmyUnitCap(brain:GetArmyIndex(), false)
    end
    if tblResult == nil then
        error('SCENARIO UTILITIES WARNING: No units found for for Army- ' .. strArmy .. ' Group- ' .. strGroup, 2)
    end
    return tblResult, treeResult, platoonList
end

----[  CreateSubGroup                                                                      ]--
----[                                                                                      ]--
----[  Used by CreateArmySubGroup                                                          ]--
function CreateSubGroup(tblNode, strArmy, strGroup, ...)
    local tblResult = {}
    local treeResult = {}
    local platoonList = {}
    for strName, tblData in pairs(tblNode.Units) do
        if 'GROUP' == tblData.type then
            if strName == strGroup then
                if arg['n'] >= 1 then
                    platoonList, tblResult, treeResult = CreateSubGroup(tblNode.Units[strName], strArmy, unpack(arg))
                else
                    platoonList, tblResult, treeResult = CreatePlatoons(strArmy, tblNode.Units[strName])
                end
            end
        end
    end
    return platoonList, tblResult, treeResult
end

----[  CreateInitialArmyGroup                                                     ]--
----[                                                                             ]--
function CreateInitialArmyGroup(strArmy, createCommander)
    local tblGroup = CreateArmyGroup(strArmy, 'INITIAL')
    local cdrUnit = false

    if createCommander and (tblGroup == nil or 0 == table.getn(tblGroup)) then
        local factionIndex = GetArmyBrain(strArmy):GetFactionIndex()
        local initialUnitName = import('/lua/factions.lua').Factions[factionIndex].InitialUnit
        cdrUnit = CreateInitialArmyUnit(strArmy, initialUnitName)
        if EntityCategoryContains(categories.COMMAND, cdrUnit) then
            if ScenarioInfo.Options['PrebuiltUnits'] == 'Off' then
                cdrUnit:HideBone(0, true)
                ForkThread(CommanderWarpDelay, cdrUnit, 3, GetArmyBrain(strArmy))
            end

            local rotateOpt = ScenarioInfo.Options['RotateACU']
            if not rotateOpt or rotateOpt == 'On' then
                cdrUnit:RotateTowardsMid()
            elseif rotateOpt == 'Marker' then
                local marker = GetMarker(strArmy) or {}
                if marker['orientation'] then
                    local o = EulerToQuaternion(unpack(marker['orientation']))
                    cdrUnit:SetOrientation(o, true)
                end
            end
        end
    end

    return tblGroup, cdrUnit
end

function CommanderWarpDelay(cdrUnit, delay, ArmyBrain)
    if ArmyBrain.BrainType == 'Human' then
        cdrUnit:SetBlockCommandQueue(true)
    end
    WaitSeconds(delay)
    cdrUnit:PlayCommanderWarpInEffect()
end

----[  CreateProps                                                                ]--
----[                                                                             ]--
----[                                                                             ]--
function CreateProps()
    for i, tblData in pairs(Scenario['Props']) do
        CreatePropHPR(
            tblData.prop,
            tblData.Position[1], tblData.Position[2], tblData.Position[3],
            tblData.Orientation[1], tblData.Orientation[2], tblData.Orientation[3]
        )
    end
end

----[  CreateResources                                                            ]--
----[                                                                             ]--
----[                                                                             ]--
function CreateResources()
    local markers = GetMarkers()
    for i, tblData in pairs(markers) do
        if tblData.resource then
            CreateResourceDeposit(
                tblData.type,
                tblData.position[1], tblData.position[2], tblData.position[3],
                tblData.size
            )

            -- fixme: texture names should come from editor
            local albedo, sx, sz, lod
            if tblData.type == "Mass" then
                albedo = "/env/common/splats/mass_marker.dds"
                sx = 2
                sz = 2
                lod = 100
                CreatePropHPR(
                    '/env/common/props/massDeposit01_prop.bp',
                    tblData.position[1], tblData.position[2], tblData.position[3],
                    Random(0,360), 0, 0
                )
            else
                albedo = "/env/common/splats/hydrocarbon_marker.dds"
                sx = 6
                sz = 6
                lod = 200
                CreatePropHPR(
                    '/env/common/props/hydrocarbonDeposit01_prop.bp',
                    tblData.position[1], tblData.position[2], tblData.position[3],
                    Random(0,360), 0, 0
                )
            end
            -- Decal - (position, heading, textureName1, textureName2, type, sizeX, sizeZ, lodParam, duration, army)
            -- Splat - (position, heading, textureName1, textureName2, type, sizeX, sizeZ, lodParam, duration, army)
--            if not ScenarioInfo.MapData.Decals then
--                ScenarioInfo.MapData.Decals = {}
--            end
--            table.insert(ScenarioInfo.MapData.Decals, CreateDecal(
--                tblData.position, -- position
--                0, -- heading
--                albedo, "", -- TEX1, TEX2
--                "Albedo", -- TYPE
--                sx, sz, -- SIZE
--                lod, -- LOD
--                0, -- DURACTION
--                -1 -- ARMY
--            ))
            CreateSplat(
                tblData.position,           -- Position
                0,                          -- Heading (rotation)
                albedo,                     -- Texture name for albedo
                sx, sz,                     -- SizeX/Z
                lod,                        -- LOD
                0,                          -- Duration (0 == does not expire)
                -1 ,                         -- army (-1 == not owned by any single army)
                0
            )
        end
    end
end

function CreateWreckage(unit, needToRotate)
    prop = unit:CreateWreckageProp(0)
    if needToRotate then -- Some units like naval and air need to rotate for effect like after death in game
        local roll = 0.5 + Random() - 2 * Random(0, 1) -- Random angle +-(0.5->1.5) radian
        local pitch = 0.5 + Random() - 2 * Random(0, 1)
        local yaw = 0

        local unitRotation = unit:GetOrientation()
        local rotation = EulerToQuaternion(roll, pitch, yaw)
        local newOrientation = {}
        -- mmm I`m love quaternions... =3
        newOrientation[1] = unitRotation[4] * rotation[1] + unitRotation[1] * rotation[4] + unitRotation[2] * rotation[3] - unitRotation[3] * rotation[2]
        newOrientation[2] = unitRotation[4] * rotation[2] + unitRotation[2] * rotation[4] + unitRotation[3] * rotation[1] - unitRotation[1] * rotation[3]
        newOrientation[3] = unitRotation[4] * rotation[3] + unitRotation[3] * rotation[4] + unitRotation[1] * rotation[2] - unitRotation[2] * rotation[1]
        newOrientation[4] = unitRotation[4] * rotation[4] - unitRotation[1] * rotation[1] - unitRotation[2] * rotation[2] - unitRotation[3] * rotation[3]

        prop:SetOrientation(newOrientation, true)
    end
    unit:Destroy()
end

-- Animate unit death and skip it. Used for create wreckage like after death
function AnimateDeathThread(unit, deathAnim)
    local animBlock = unit:ChooseAnimBlock(deathAnim)
    local animator = CreateAnimator(unit)
    animator:PlayAnim(animBlock.Animation)
    local rate = unit.rate or 1

    if animBlock.AnimationRateMax and animBlock.AnimationRateMin then
        rate = Random(animBlock.AnimationRateMin * 10, animBlock.AnimationRateMax * 10) / 10
    end

    animator:SetRate(rate)
    animator:SetAnimationTime(1000)
    unit.Trash:Add(animator)

    if animator then
        WaitFor(animator)
    end

    CreateWreckage(unit, false)
end

function CreateWreckageUnit(unit)
	local bp = unit.Blueprint

	local isStructure = bp.CategoriesHash.STRUCTURE
	local isAir = bp.CategoriesHash.AIR
	local isLand = bp.CategoriesHash.LAND
	local isExperimental = bp.CategoriesHash.EXPERIMENTAL
	local isNaval = bp.CategoriesHash.NAVAL

	local layer = unit:GetCurrentLayer()
	local unitPos = unit:GetPosition()
	local deep = (GetSurfaceHeight(unitPos[1],unitPos[3]) - GetTerrainHeight(unitPos[1],unitPos[3]))
	local deathAnim = bp.Display['AnimationDeath']

	-- If unit stay on land or deep<5 and have death animation, animate this
	local needAnimate = deathAnim and unit.PlayDeathAnimation and (isLand or isAir) and (layer == 'Land' or deep < 5)
	-- We want to random rotate all naval and air units whats haven`t death animation
	local needRotate = not (layer == 'Land' or isStructure or isLand or (isNaval and deep < 2)) or (isAir and isExperimental)

	if needAnimate then
		ForkThread(AnimateDeathThread, unit, deathAnim)
	else
		unit.PlayDeathAnimation = false -- Coz some units have broken animation and hold on surfase for ever
		CreateWreckage(unit, needRotate)
	end
end

----[  InitializeArmies                                                           ]--
----[                                                                             ]--
----[                                                                             ]--
function InitializeArmies()
    local tblGroups = {}
    local tblArmy = ListArmies()

    local civOpt = ScenarioInfo.Options.CivilianAlliance

    local bCreateInitial = ShouldCreateInitialArmyUnits()

    for iArmy, strArmy in pairs(tblArmy) do
        local tblData = Scenario.Armies[strArmy]

        tblGroups[ strArmy ] = {}

        if tblData then

            ----[ If an actual starting position is defined, overwrite the        ]--
            ----[ randomly generated one.                                         ]--

            --LOG('*DEBUG: InitializeArmies, army = ', strArmy)

            SetArmyEconomy(strArmy, tblData.Economy.mass, tblData.Economy.energy)

            --GetArmyBrain(strArmy):InitializePlatoonBuildManager()
            --LoadArmyPBMBuilders(strArmy)
            if GetArmyBrain(strArmy).SkirmishSystems then
                GetArmyBrain(strArmy):InitializeSkirmishSystems()
            end

            local armyIsCiv = ScenarioInfo.ArmySetup[strArmy].Civilian

            if armyIsCiv and civOpt ~= 'neutral' and strArmy ~= 'NEUTRAL_CIVILIAN' then -- give enemy civilians darker color
                SetArmyColor(strArmy, 255, 48, 48) -- non-player red color for enemy civs
            end

            if (not armyIsCiv and bCreateInitial) or (armyIsCiv and civOpt ~= 'removed') then
                local commander = (not ScenarioInfo.ArmySetup[strArmy].Civilian)
                local cdrUnit
                tblGroups[strArmy], cdrUnit = CreateInitialArmyGroup(strArmy, commander)
                if commander and cdrUnit and ArmyBrains[iArmy].Nickname then
                    cdrUnit:SetCustomName(ArmyBrains[iArmy].Nickname)
                end
            end

            local wreckageGroup = FindUnitGroup('WRECKAGE', Scenario.Armies[strArmy].Units)
            if wreckageGroup then
			    local platoonList, tblResult, treeResult = CreatePlatoons(strArmy, wreckageGroup)
				for num, unit in tblResult do
					CreateWreckageUnit(unit)
				end
            end

            ----[ irumsey                                                         ]--
            ----[ Temporary defaults.  Make sure some fighting will break out.    ]--
            for iEnemy, strEnemy in tblArmy do
                local enemyIsCiv = ScenarioInfo.ArmySetup[strEnemy].Civilian
                local a, e = iArmy, iEnemy
                local state = 'Enemy'

                if a ~= e then
                    if armyIsCiv or enemyIsCiv then
                        if civOpt == 'neutral' or strArmy == 'NEUTRAL_CIVILIAN' or strEnemy == 'NEUTRAL_CIVILIAN' then
                            state = 'Neutral'
                        end

                        if ScenarioInfo.Options['RevealCivilians'] == 'Yes' and ScenarioInfo.ArmySetup[strEnemy].Human then
                            ForkThread(function()
                                WaitSeconds(.1)
                                local real_state = IsAlly(a, e) and 'Ally' or IsEnemy(a, e) and 'Enemy' or 'Neutral'

                                GetArmyBrain(e):SetupArmyIntelTrigger({
                                    Category=categories.ALLUNITS,
                                    Type='LOSNow',
                                    Value=true,
                                    OnceOnly=true,
                                    TargetAIBrain=GetArmyBrain(a),
                                    CallbackFunction=function()
                                        SetAlliance(a, e, real_state)
                                    end,
                                })
                                SetAlliance(a, e, 'Ally')
                            end)
                        end
                    end

                    if state then
                        SetAlliance(a, e, state)
                    end
                end
            end
        end
    end

    return tblGroups
end


----[  InitializeScenarioArmies                                                   ]--
----[                                                                             ]--
----[                                                                             ]--
function InitializeScenarioArmies()
    local tblGroups = {}
    local tblArmy = ListArmies()
    local factions = import('/lua/factions.lua')
    local bCreateInitial = ShouldCreateInitialArmyUnits()
    local armies = {}
    for i, name in tblArmy do
        armies[name] = i
    end

    ScenarioInfo.CampaignMode = true
    Sync.CampaignMode = true
    import('/lua/sim/simuistate.lua').IsCampaign(true)

    for iArmy, strArmy in tblArmy do
        local tblData = Scenario.Armies[strArmy]

        tblGroups[ strArmy ] = {}

        if tblData then
            LOG('*DEBUG: InitializeScenarioArmies, army = ', strArmy)
            SetArmyEconomy(strArmy, tblData.Economy.mass, tblData.Economy.energy)
            if tblData.faction ~= nil then
                if ScenarioInfo.ArmySetup[strArmy].Human or StringStartsWith(strArmy, "Player") then
                    local factionIndex = math.min(math.max(ScenarioInfo.ArmySetup[strArmy].Faction, 1), table.getsize(factions.Factions))
                    SetArmyFactionIndex(strArmy, factionIndex - 1)
                else
                    local factionIndex = math.min(math.max(tblData.faction, 0), table.getsize(factions.Factions))
                    SetArmyFactionIndex(strArmy, factionIndex)
                    GetArmyBrain(strArmy):SetCurrentPlan()
                end
            end

            if tblData.color ~= nil then
                SetArmyColorIndex(strArmy, tblData.color)
            end

            if tblData.personality ~= nil then
                SetArmyAIPersonality(strArmy, tblData.personality)
            end

            if bCreateInitial then
                tblGroups[strArmy] = CreateInitialArmyGroup(strArmy)
            end

            local wreckageGroup = FindUnitGroup('WRECKAGE', Scenario.Armies[strArmy].Units)
            if wreckageGroup then
			    local platoonList, tblResult, treeResult = CreatePlatoons(strArmy, wreckageGroup)
				for num, unit in tblResult do
					CreateWreckageUnit(unit)
				end
            end

            ----[ eemerson                                                         ]--
            ----[ Override alliances with custom alliance settings                 ]--
            if tblData.Alliances ~= nil then
               for army_name, state in tblData.Alliances do
                    if armies[army_name] and strArmy ~= army_name then
                        SetAllianceOneWay(strArmy, army_name, state)
                    end
               end
            end

            GetArmyBrain(strArmy):InitializePlatoonBuildManager()
            LoadArmyPBMBuilders(strArmy)
        end
    end

    return tblGroups
end

----[ AssignOrders                                                                ]--
----[                                                                             ]--
----[                                                                             ]--
function AssignOrders(strQueue, tblUnit, target)
    local tblOrder = Scenario.Orders[ strQueue ]
    for i, order in pairs(tblOrder) do
        order.cmd(tblUnit,target)
    end
end


----[ SpawnPlatoon                                                                ]--
----[ Spawns unit group and assigns to platoon it is a part of                    ]--
function SpawnPlatoon(strArmy, strGroup)
    local tblNode = FindUnitGroup(strGroup, Scenario.Armies[strArmy].Units)
    if nil == tblNode then
        error('SCENARIO UTILITIES WARNING: No Group found for Army- ' .. strArmy .. ' Group- ' .. strGroup, 2)
        return false
    end

    local brain = GetArmyBrain(strArmy)
    if not brain.IgnoreArmyCaps then
        SetIgnoreArmyUnitCap(brain:GetArmyIndex(), true)
    end
    local platoonName
    if nil ~= tblNode.platoon and '' ~= tblNode.platoon then
        platoonName = tblNode.platoon
    end

    local platoonList, tblResult, treeResult = CreatePlatoons(strArmy, tblNode)
    if not brain.IgnoreArmyCaps then
        SetIgnoreArmyUnitCap(brain:GetArmyIndex(), false)
    end
    if tblResult == nil then
        error('SCENARIO UTILITIES WARNING: No units found for for Army- ' .. strArmy .. ' Group- ' .. strGroup, 2)
    end
    return platoonList[platoonName], platoonList, tblResult, treeResult
end

function SpawnTableOfPlatoons(strArmy, strGroup)
    local brain = GetArmyBrain(strArmy)
    if not brain.IgnoreArmyCaps then
        SetIgnoreArmyUnitCap(brain:GetArmyIndex(), true)
    end
    local platoonList, tblResult, treeResult = CreatePlatoons(strArmy,
                                                              FindUnitGroup(strGroup, Scenario.Armies[strArmy].Units))
    if not brain.IgnoreArmyCaps then
        SetIgnoreArmyUnitCap(brain:GetArmyIndex(), false)
    end
    if tblResult == nil then
        error('SCENARIO UTILITIES WARNING: No units found for for Army- ' .. strArmy .. ' Group- ' .. strGroup, 2)
    end
    return platoonList, tblResult, treeResult
end

function CountChildUnits(tblNode)
    local count = 0

    for k,v in pairs(tblNode.Units) do
        if v.type == 'GROUP' then
            count = count + CountChildUnits(v)
        else
            count = count + 1
        end
    end

    tblNode.TotalUnits = count

    return count
end

function CreatePlatoons(strArmy, tblNode, tblResult, platoonList, currPlatoon, treeResult, balance)
    tblResult = tblResult or {}
    platoonList = platoonList or {}
    treeResult = treeResult or {}
    currPlatoon = currPlatoon or false
    local treeLocal = {}

    if nil == tblNode then
        return nil
    end

    local brain = GetArmyBrain(strArmy)
    local armyIndex = brain:GetArmyIndex()
    local currTemplate
    local numRows
    local reversePlatoon = false
    local reverseRows
    local reverseTemplate
    if nil ~= tblNode.platoon and '' ~= tblNode.platoon and tblNode ~= currPlatoon
        and not platoonList[tblNode.platoon] then
        currTemplate = Scenario.Platoons[tblNode.platoon]
        if currTemplate then
            platoonList[tblNode.platoon] = brain:MakePlatoon('', currTemplate[2])
            platoonList[tblNode.platoon].squadCounter = {}
            currPlatoon = tblNode.platoon
        end
    end
    if currPlatoon then
        currTemplate = Scenario.Platoons[currPlatoon]
        numRows = table.getn(currTemplate)
    end

    local unit = nil

    --local timePerChild = nil

    --[[
    if timeLeft and not tblNode.TotalUnits then
        --Calculate the number of units
        local totalUnits = CountChildUnits(tblNode)
    end

    if timeLeft then
        timePerChild = (timeLeft/tblNode.TotalUnits)
    end
    ]]--

    for strName, tblData in pairs(tblNode.Units) do
        if 'GROUP' == tblData.type then
            --[[
            if timeLeft and tblData.TotalUnits > 0 then
                timePerChild = (timeLeft/tblNode.TotalUnits)*tblData.TotalUnits
            end
            --]]--

            platoonList, tblResult, treeResult[strName] = CreatePlatoons(strArmy, tblData, tblResult,
                                                                         platoonList, currPlatoon, treeResult[strName], balance)

        else
            unit = CreateUnitHPR(tblData.type,
                                 strArmy,
                                 tblData.Position[1], tblData.Position[2], tblData.Position[3],
                                 tblData.Orientation[1], tblData.Orientation[2], tblData.Orientation[3]
                             )
            if unit.Blueprint.Physics.FlattenSkirt then
                unit:CreateTarmac(true, true, true, false, false)
            end
            table.insert(tblResult, unit)
            treeResult[strName] = unit
            if ScenarioInfo.UnitNames[armyIndex] then
                ScenarioInfo.UnitNames[armyIndex][strName] = unit
            end
            unit.UnitName = strName
            if tblData.platoon ~= nil and tblData.platoon ~= '' and tblData.platoon ~= currPlatoon then
                reversePlatoon = currPlatoon
                reverseRows = numRows
                reverseTemplate = currTemplate
                if not platoonList[tblData.platoon] then
                    currTemplate = Scenario.Platoons[tblData.platoon]
                    platoonList[tblData.platoon] = brain:MakePlatoon('', currTemplate[2])
                    platoonList[tblData.platoon].squadCounter = {}
                end
                currPlatoon = tblData.platoon
                currTemplate = Scenario.Platoons[currPlatoon]
                numRows = table.getn(currTemplate)
            end
            if currPlatoon then
                local i = 3
                local inserted = false
                while i <= numRows and not inserted do
                    if platoonList[currPlatoon].squadCounter[i] == nil then
                        platoonList[currPlatoon].squadCounter[i] = 0
                    end
                    if tblData.type == currTemplate[i][1] and
                            platoonList[currPlatoon].squadCounter[i] < currTemplate[i][3] then
                        platoonList[currPlatoon].squadCounter[i] = platoonList[currPlatoon].squadCounter[i] + 1
                        brain:AssignUnitsToPlatoon(platoonList[currPlatoon],{unit},currTemplate[i][4],currTemplate[i][5])
                        inserted = true
                    end
                    i = i + 1
                end
                if reversePlatoon then
                    currPlatoon = reversePlatoon
                    numRows = reverseRows
                    currTemplate = reverseTemplate
                    reversePlatoon = false
                end
            end

            if balance then
                --Accumulate for one tick so we don't get too much overhead from thread switching...
                --ScenarioInfo.LoadBalance.Accumulator = ScenarioInfo.LoadBalance.Accumulator + timePerChild
                ScenarioInfo.LoadBalance.Accumulator = ScenarioInfo.LoadBalance.Accumulator + 1

                if ScenarioInfo.LoadBalance.Accumulator > ScenarioInfo.LoadBalance.UnitThreshold then
                    WaitSeconds(0)
                    ScenarioInfo.LoadBalance.Accumulator = 0
                end
            end
        end
    end

    return platoonList, tblResult, treeResult
end



----[  CreateArmyGroup                                                            ]--
----[                                                                             ]--
----[  Creates the specified group in game.                                       ]--
function CreateArmyGroup(strArmy,strGroup,wreckage, balance)
    local brain = GetArmyBrain(strArmy)
    if not brain.IgnoreArmyCaps then
        SetIgnoreArmyUnitCap(brain:GetArmyIndex(), true)
    end
    local platoonList, tblResult, treeResult = CreatePlatoons(strArmy,
                                                              FindUnitGroup(strGroup, Scenario.Armies[strArmy].Units), nil, nil, nil, nil, balance)

    if not brain.IgnoreArmyCaps then
        SetIgnoreArmyUnitCap(brain:GetArmyIndex(), false)
    end
    if tblResult == nil and strGroup ~= 'INITIAL' then
        error('SCENARIO UTILITIES WARNING: No units found for for Army- ' .. strArmy .. ' Group- ' .. strGroup, 2)
    end
    if wreckage then
		for num, unit in tblResult do
			CreateWreckageUnit(unit)
		end
        return
    end
    return tblResult, treeResult, platoonList
end

-- CreateArmyTree
--
-- Returns tree of units created by the editor. 2nd return is table of units
function CreateArmyTree(strArmy, strGroup)
    local brain = GetArmyBrain(strArmy)
    if not brain.IgnoreArmyCaps then
        SetIgnoreArmyUnitCap(brain:GetArmyIndex(), true)
    end
    local platoonList, tblResult, treeResult = CreatePlatoons(strArmy,
                                                              FindUnitGroup(strGroup, Scenario.Armies[strArmy].Units))
    if not brain.IgnoreArmyCaps then
        SetIgnoreArmyUnitCap(brain:GetArmyIndex(), false)
    end
    if tblResult == nil then
        error('SCENARIO UTILITIES WARNING: No units found for for Army- ' .. strArmy .. ' Group- ' .. strGroup, 2)
    end
    return treeResult, tblResult, platoonList
end


function CreateArmyGroupAsPlatoonBalanced(strArmy, strGroup, formation, OnFinishedCallback)
    ScenarioInfo.LoadBalance.Accumulator = 0
    local units = CreateArmyGroupAsPlatoon(strArmy, strGroup, formation, nil, nil, true)

    OnFinishedCallback(units)
end

-- CreateArmyGroupAsPlatoon
--
-- Returns a platoon that is created out of all units in a group and its sub groups.
function CreateArmyGroupAsPlatoon(strArmy, strGroup, formation, tblNode, platoon, balance)
    if ScenarioInfo.LoadBalance.Enabled then
        --note that tblNode in this case is actually the callback function
        table.insert(ScenarioInfo.LoadBalance.PlatoonGroups, {strArmy, strGroup, formation, tblNode})
        return
    end

    local tblNode = tblNode or FindUnitGroup(strGroup, Scenario.Armies[strArmy].Units)
    if not tblNode then
        error('*SCENARIO UTILS ERROR: No group named- ' .. strGroup .. ' found for army- ' .. strArmy, 2)
    end
    if not formation then
        error('*SCENARIO UTILS ERROR: No formation given to CreateArmyGroupAsPlatoon')
    end
    local brain = GetArmyBrain(strArmy)
    if not brain.IgnoreArmyCaps then
        SetIgnoreArmyUnitCap(brain:GetArmyIndex(), true)
    end
    local platoon = platoon or brain:MakePlatoon('','')
    local armyIndex = brain:GetArmyIndex()

    local unit = nil
    for strName, tblData in pairs(tblNode.Units) do
        if 'GROUP' == tblData.type then
            platoon = CreateArmyGroupAsPlatoon(strArmy, strGroup, formation, tblData, platoon)
            if not brain.IgnoreArmyCaps then
                SetIgnoreArmyUnitCap(brain:GetArmyIndex(), true)
            end
        else
            unit = CreateUnitHPR(tblData.type,
                                 strArmy,
                                 tblData.Position[1], tblData.Position[2], tblData.Position[3],
                                 tblData.Orientation[1], tblData.Orientation[2], tblData.Orientation[3]
                             )
            if unit.Blueprint.Physics.FlattenSkirt then
                unit:CreateTarmac(true, true, true, false, false)
            end
            if ScenarioInfo.UnitNames[armyIndex] then
                ScenarioInfo.UnitNames[armyIndex][strName] = unit
            end
            unit.UnitName = strName
            brain:AssignUnitsToPlatoon(platoon, {unit}, 'Attack', formation)

            if balance then
                ScenarioInfo.LoadBalance.Accumulator = ScenarioInfo.LoadBalance.Accumulator + 1

                if ScenarioInfo.LoadBalance.Accumulator > ScenarioInfo.LoadBalance.UnitThreshold/5 then
                    WaitSeconds(0)
                    ScenarioInfo.LoadBalance.Accumulator = 0
                end
            end
        end
    end
    if not brain.IgnoreArmyCaps then
        SetIgnoreArmyUnitCap(brain:GetArmyIndex(), false)
    end
    return platoon
end

-- Creates an army group at a certain veteran level
function CreateArmyGroupAsPlatoonVeteran(strArmy, strGroup, formation, veteranLevel)
    local plat = CreateArmyGroupAsPlatoon(strArmy, strGroup, formation)
    veteranLevel = veteranLevel or 5
    for k,v in plat:GetPlatoonUnits() do
        v:SetVeterancy(veteranLevel)
    end
    return plat
end

function FlattenTreeGroup(strArmy, strGroup, tblData, unitGroup)
    tblData = tblData or FindUnitGroup(strGroup, Scenario.Armies[strArmy].Units)
    unitGroup = unitGroup or {}
    for strName, tblData in pairs(tblData.Units) do
        if 'GROUP' == tblData.type then
            FlattenTreeGroup(strArmy, strGroup, tblData, unitGroup)
        else
            table.insert(unitGroup, tblData)
        end
    end
    return unitGroup
end

-- LoadArmyPBMBuilders
--
-- Loads an Army Brain's PBM Builders from the save file
function LoadArmyPBMBuilders(strArmy)
    local aiBrain = GetArmyBrain(strArmy)
    if Scenario.Armies[strArmy].PlatoonBuilders.Builders then
        local nonGlobalOSB = {}
        for buildName, builderData in Scenario.Armies[strArmy].PlatoonBuilders.Builders do
            if builderData.PlatoonData then
                for k,v in builderData.PlatoonData do
                    if type(k) ~= 'string' then
                        builderData.PlatoonData = RebuildDataTable(builderData.PlatoonData)
                    end
                    break
                end
            end
            if builderData.BuildConditions then
                for num,conditionData in builderData.BuildConditions do
                    local tempBuildData = {}
                    table.insert(tempBuildData,conditionData[1])
                    table.insert(tempBuildData,conditionData[2])
                    table.insert(tempBuildData,conditionData[3])
                    builderData.BuildConditions[num] = tempBuildData
                end
            end
            if string.sub(buildName, 1, 11) == 'OSB_Master_' or string.sub(buildName, 1, 10) == 'OSB_Child_' then
                nonGlobalOSB[buildName] = builderData
            elseif string.sub(buildName, 1, 4) == 'OSB_' then
                LoadOSB(buildName, strArmy, builderData)
            elseif not builderData.PlatoonData.AMMasterPlatoon then
                local spec = {}
                for k, v in builderData do
                    spec[k] = v
                end
                spec.PlatoonTemplate = table.deepcopy(Scenario.Platoons[builderData.PlatoonTemplate])
                spec.BuilderName = buildName
                spec.PlatoonData.BuilderName = buildName
                if spec.BuildTimeOut and spec.BuildTimeOut < 0 then
                    spec.GenerateTimeOut = true
                end
                aiBrain:PBMAddPlatoon(spec)
            else
                if aiBrain.AttackData['AttackManagerState'] ~= 'ACTIVE' then
                    aiBrain:InitializeAttackManager()
                end
                local spec = {}
                if builderData.BuildConditions then
                    spec.AttackConditions = builderData.BuildConditions
                else
                    spec.AttackConditions = {}
                end
                spec.PlatoonData = builderData.PlatoonData
                spec.Priority = builderData.Priority
                if builderData.PlatoonAIFunction then
                    spec.AIThread = builderData.PlatoonAIFunction
                end
                if spec.PlatoonData.AIName then
                    spec.AIName = spec.PlatoonData.AIName
                end
                if builderData.PlatoonAddFunctions then
                    spec.FormCallbacks = builderData.PlatoonAddFunctions
                end
                if builderData.PlatoonBuildCallbacks then
                    spec.DestroyCallbacks = builderData.PlatoonBuildCallbacks
                end
                if builderData.PlatoonTemplate and not spec.AIName then
                    if Scenario.Platoons[builderData.PlatoonTemplate][2] ~= '' then
                        spec.AIName = Scenario.Platoons[builderData.PlatoonTemplate][2]
                    end
                end
                spec.PlatoonType = builderData.PlatoonType
                spec.PlatoonName = buildName
                spec.LocationType = builderData.LocationType
                spec.BuilderName = buildName
                if spec.PlatoonData.UsePool ~= nil then
                    spec.UsePool = spec.PlatoonData.UsePool
                end
                aiBrain:AMAddPlatoon(spec)
            end
        end
        for buildName, builderData in nonGlobalOSB do
            UpdateOSB(buildName, strArmy, builderData)
        end
    end
end

function RebuildDataTable(table)
    local newTable = {}
    for k,v in table do
        local checkType = type(v.value)
        if type(v.value) == 'table' then
            newTable[v.name] = RebuildDataTable(v.value)
        else
            newTable[v.name] = v.value
        end
    end
    return newTable
end

function InitializeStartLocation(strArmy)
    local start = GetMarker(strArmy)
    if start then
        SetArmyStart(strArmy, start.position[1], start.position[3])
    else
        GenerateArmyStart(strArmy)
    end
end

function SetPlans(strArmy)
    if Scenario.Armies[strArmy] then
        SetArmyPlans(strArmy, Scenario.Armies[strArmy].plans)
    end
end

function UpdateOSB(buildName, strArmy, builderData)
--    local buildNameNew, location, globalName, childPart = SplitUpdateOSBName(buildName)
    local aiBrain = GetArmyBrain(strArmy)
--    local amMasterName = 'OSB_Master_' .. globalName .. '_' .. strArmy
--    if location then
--        amMasterName = amMasterName .. '_' .. location
--    end
--
--    -- Find builder in brain
--    local builderName = buildName
--    builderName = builderName .. '_' .. strArmy
--    if location then
--        builderName = builderName .. '_' .. location
--    end
--    local found = false
--    local builderEdit = false
    for type, bTable in aiBrain.PBM.Platoons do
        for bCount, bData in bTable do
            local bName = bData.BuilderName
            if bName == buildName then
                UpdateGivenOSB(bData, builderData)
            end
        end
    end
end

function UpdateGivenOSB(builderEdit, builderData)
    -- Update data in builder in brain
    for dName, data in builderData.PlatoonData do
        if dName ~= 'PlatoonMultiplier' and dName ~= 'TransportCount' then
            builderEdit.PlatoonData[dName] = data
        end
    end
    if builderData.PlatoonData.PlatoonMultiplier and not builderEdit.PlatoonTemplate.MultiplierApplied then
        builderEdit.PlatoonTemplate.MultiplierApplied = true
        local squadNum = 3
        while squadNum <= table.getn(builderEdit.PlatoonTemplate) do
            if builderEdit.PlatoonTemplate[squadNum][2] < 0 then
                local num = builderEdit.PlatoonTemplate[squadNum][2] * builderData.PlatoonData.PlatoonMultiplier
                builderEdit.PlatoonTemplate[squadNum][2] = -(math.ceil(math.abs(num)))
            end
            squadNum = squadNum + 1
        end
    end
    if builderData.Priority ~= 0 then
        if builderData.Priority == -1 then
            builderEdit.Priority = 0
        else
            builderEdit.Priority = builderData.Priority
        end
    end
    if builderData.BuildConditions then
        for bcNum, bcData in builderData.BuildConditions do
            if childPart then
                table.insert(builderEdit.BuildConditions, bcData)
            else
                table.insert(builderEdit.AttackConditions, bcData)
            end
        end
    end
    if builderData.PlatoonBuildCallbacks then
        for buildNum, buildData in builderData.PlatoonBuildCallbacks do
            if childPart then
                table.insert(builderEdit.PlatoonBuildCallbacks, buildData)
            else
                table.insert(builderEdit.DestroyCallbacks, buildData)
            end
        end
    end
    if builderData.PlatoonAddFunctions then
        for addNum, addData in builderData.PlatoonAddFunctions do
            if childPart then
                table.insert(builderEdit.PlatoonAddFunctions, buildData)
            else
                table.insert(builderEdit.FormCallbacks, buildData)
            end
        end
    end
    if builderData.PlatoonAIFunction then
        if childPart then
            builderEdit.PlatoonAIFunction = builderData.PlatoonAIFunction
        else
            builderEdit.AIThread = builderData.PlatoonAIFunction
        end
    end
end

function LoadOSB(buildName, strArmy, builderData)
    local buildNameNew, location, globalName, childPart
    local saveFile

    if type(buildName) == 'table' then
        saveFile = {Scenario = buildName}

        buildNameNew = 'OSB_' .. saveFile.Scenario.Name
        globalName = saveFile.Scenario.Name
        location = false --string.gsub(builderData.LocationType, '_', '')
        childPart = false
    else
        buildNameNew, location, globalName, childPart = SplitOSBName(buildName)
        local fileName = '/lua/ai/OpAI/' .. globalName .. '_save.lua'
        saveFile = import(fileName)
    end

    local platoons = saveFile.Scenario.Platoons
    local aiBrain = GetArmyBrain(strArmy)
    if not aiBrain.OSBuilders then
        aiBrain.OSBuilders = {}
    end
    local factionIndex = aiBrain:GetFactionIndex()
    local builders = saveFile.Scenario.Armies['ARMY_1'].PlatoonBuilders.Builders
    local basePriority = builders['OSB_Master_'..globalName].Priority
    local amMasterName = 'OSB_Master_' .. globalName .. '_' .. strArmy
    if location then
        amMasterName =  amMasterName .. '_' .. location
    end
    if not builders then
        error('*OpAI ERROR: No OpAI Global named: '..globalName, 2)
    end
    for k,v in builders do
        local spec = {}
        local insert = true

        local pData = RebuildDataTable(v.PlatoonData)
        spec.PlatoonData = {}

        -- Store builder name
        if location then
            spec.BuilderName = k .. '_' .. strArmy .. '_' .. location
            spec.PlatoonData.BuilderName = k .. '_' .. strArmy .. '_' .. location
        else
            spec.BuilderName = k .. '_' .. strArmy
            spec.PlatoonData.BuilderName = k .. '_' .. strArmy
        end

        if ScenarioInfo.OSPlatoonCounter[spec.BuilderName] then
            UpdateOSB(spec.BuilderName, strArmy, builderData)
        else
            if string.sub(k, 1, 11) == 'OSB_Master_' then
                for name, data in builderData.PlatoonData do
                    if name ~= 'PlatoonMultiplier' and name ~= 'TransportCount' and name ~= 'PlatoonSize' then
                        spec.PlatoonData[name] = data
                    end
                end
            end
            if pData.AMPlatoons then
                spec.PlatoonData.AMPlatoons = {}
                for name, pName in pData.AMPlatoons do
                    local appendString = ''
                    if string.sub(name, 1, 6) == 'APPEND' then
                        appendString = string.sub(name, 7)
                    end
                    if location then
                        table.insert(spec.PlatoonData.AMPlatoons, pName..'_'..strArmy..'_'..location..appendString)
                    else
                        table.insert(spec.PlatoonData.AMPlatoons, pName .. '_' .. strArmy .. appendString)
                    end
                end
            end


            -- Set priority
            if builderData.Priority < 0 then
                insert = false
                spec.Priority = builderData.Priority
            elseif builderData.Priority ~= 0 then
                spec.Priority = builderData.Priority - (basePriority - v.Priority)
                if spec.Priority <= 0 then
                    spec.Priority = 1
                end
            else
                spec.Priority = v.Priority
            end
            if spec.LocationType ~= 'ALL' then
                spec.LocationType = builderData.LocationType
                spec.PlatoonData.LocationType = builderData.LocationType
            end
            spec.PlatoonType = v.PlatoonType

            -- Set platoon template
            if Scenario.Platoons['OST_' .. string.sub(spec.BuilderName, 5)] then
                spec.PlatoonTemplate = FactionConvert(table.deepcopy(Scenario.Platoons['OST_' .. string.sub(spec.BuilderName, 5)]), factionIndex)
            elseif Scenario.Platoons[v.PlatoonTemplate] then
                if type(buildName) ~= "table" then
                    spec.PlatoonTemplate = FactionConvert(table.deepcopy(Scenario.Platoons[v.PlatoonTemplate]), factionIndex)
                else
                    spec.PlatoonTemplate = table.deepcopy(Scenario.Platoons[v.PlatoonTemplate])
                end
            else
                if type(buildName) ~= "table" then
                    spec.PlatoonTemplate = FactionConvert(table.deepcopy(platoons[v.PlatoonTemplate]), factionIndex)
                else
                    spec.PlatoonTemplate = table.deepcopy(platoons[v.PlatoonTemplate])
                end


            end
            if builderData.PlatoonData.PlatoonMultiplier then
                local squadNum = 3
                while squadNum <= table.getn(spec.PlatoonTemplate) do
                    spec.PlatoonTemplate[squadNum][2] = spec.PlatoonTemplate[squadNum][2] * builderData.PlatoonData.PlatoonMultiplier
                    spec.PlatoonTemplate[squadNum][3] = spec.PlatoonTemplate[squadNum][3] * builderData.PlatoonData.PlatoonMultiplier
                    squadNum = squadNum + 1
                end
            end
            if builderData.PlatoonData.PlatoonSize then
                local squadNum = 3
                while squadNum <= table.getn(spec.PlatoonTemplate) do
                    spec.PlatoonTemplate[squadNum][2] = 1
                    spec.PlatoonTemplate[squadNum][3] = builderData.PlatoonData.PlatoonSize
                    squadNum = squadNum + 1
                end
            end

            -- Set buildout to
            if (v.BuildTimeOut and v.BuildTimeOut < 0) or (spec.PlatoonTemplate[3] and spec.PlatoonTemplate[3][2] < 0) then
                spec.GenerateTimeOut = true
            end
            spec.BuildTimeOut = v.BuildTimeOut

            -- Add AI Function to OSB global if needed
            if string.sub(k, 1, 11) == 'OSB_Master_' and builderData.PlatoonAIFunction then
                spec.PlatoonAIFunction = builderData.PlatoonAIFunction
            elseif v.PlatoonAIFunction then
                spec.PlatoonAIFunction = v.PlatoonAIFunction
            end

            -- Add Build Conditions
            spec.BuildConditions = {}
            if v.BuildConditions then
                for num, bCond in v.BuildConditions do
                    local addCond = table.deepcopy(bCond)
                    for sNum, pVal in addCond[3] do
                        if pVal == 'OSB_Master_' .. string.sub(buildNameNew,5) then
                            pVal = amMasterName
                        elseif pVal == 'default_master' then
                            addCond[3][sNum] = amMasterName
                        elseif pVal == 'default_army' then
                            addCond[3][sNum] = strArmy
                        elseif pVal == 'default_location' and location then
                            addCond[3][sNum] = location
                        elseif pVal == 'default_location_type' then
                            addCond[3][sNum] = spec.LocationType
                        elseif pVal == 'default_builder_name' then
                            addCond[3][sNum] = spec.BuilderName
                        elseif pVal == 'default_transport_count' then
                            if builderData.PlatoonData.TransportCount then
                                addCond[3][sNum] = builderData.PlatoonData.TransportCount
                            end
                        end
                    end
                    table.insert(spec.BuildConditions, addCond)
                end
            end
            -- Add build/form conditions to ALL builders
            if builderData.BuildConditions then
                for num, bCond in builderData.BuildConditions do
                    if bCond[3][1] == 'Remove' then
                        for bcNum,bcData in spec.BuildConditions do
                            if bcData[2] == bCond[2] then
                                table.remove(spec.BuildConditions, bcNum)
                            end
                        end
                    else
                        local addCond = table.deepcopy(bCond)
                        for sNum, pVal in addCond[3] do
                            if pVal == buildNameNew then
                                pVal = amMasterName
                            elseif pVal == 'default_master' then
                                addCond[3][sNum] = amMasterName
                            elseif pVal == 'default_army' then
                                addCond[3][sNum] = strArmy
                            elseif pVal == 'default_location' and location then
                                addCond[3][sNum] = location
                            elseif pVal == 'default_location_type' then
                                addCond[3][sNum] = spec.LocationType
                            elseif pVal == 'default_builder_name' then
                                addCond[3][sNum] = spec.BuilderName
                            elseif pVal == 'default_transport_count' then
                                if builderData.PlatoonData.TransportCount then
                                    addCond[3][sNum] = builderData.PlatoonData.TransportCount
                                end
                            end
                        end
                        table.insert(spec.BuildConditions, addCond)
                    end
                end
            end
            -- Check for faction specific builders
            for num, cond in spec.BuildConditions do
                if cond[2] == 'FactionIndex' then
                    local params = {}
                    for subNum, val in cond[3] do
                        table.insert(params, val)
                    end
                    table.remove(params, 1)
                    insert = import(cond[1])[cond[2]](aiBrain, unpack(params))
                end
            end

            -- Add BuildCallbacks
            spec.PlatoonBuildCallbacks = {}
            if v.PlatoonBuildCallbacks then
                for num, pbCallback in v.PlatoonBuildCallbacks do
                    table.insert(spec.PlatoonBuildCallbacks, pbCallback)
                end
            end
            -- Add DestroyCallbacks to Masters
            if builderData.PlatoonBuildCallbacks and string.sub(k,1,11) == 'OSB_Master_' then
                FilterFunctions(spec.PlatoonBuildCallbacks, builderData.PlatoonBuildCallbacks)
            end

            -- Add AddFunctions (Har!)
            spec.PlatoonAddFunctions = {}
            if v.PlatoonAddFunctions then
                for fNum, fData in v.PlatoonAddFunctions do
                    table.insert(spec.PlatoonAddFunctions, fData)
                end
            end
            if builderData.PlatoonAddFunctions and string.sub(k,1,11) == 'OSB_Master_' then
                FilterFunctions(spec.PlatoonAddFunctions, builderData.PlatoonAddFunctions)
            end


            -- Masters
            if pData.AMMasterPlatoon and insert then
                if string.sub(k,1,26) == 'OSB_Master_LeftoverCleanup' then
                    spec.PlatoonName = spec.LocationType..'_LeftoverUnits'
                else
                    spec.PlatoonName = spec.BuilderName
                end

                -- Add data to Masters
                if builderData.PlatoonData and string.sub(k,1,11) == 'OSB_Master_' then
                    if aiBrain.AttackData['AttackManagerState'] ~= 'ACTIVE' then
                        aiBrain:InitializeAttackManager()
                    end
                end

                spec.AttackConditions = spec.BuildConditions
                spec.DestroyCallbacks = spec.PlatoonBuildCallbacks
                spec.FormCallbacks = spec.PlatoonAddFunctions
                spec.AIThread = spec.PlatoonAIFunction

                if pData.AIName then
                    spec.AIName = pData.AIName
                end
                if spec.PlatoonTemplate and not spec.AIName then
                    if spec.PlatoonTemplate[2] ~= '' then
                        spec.AIName = spec.PlatoonTemplate[2]
                    end
                end

                -- Set if needed to draw from pool
                if pData.UsePool ~= nil then
                    spec.UsePool = pData.UsePool
                end
                aiBrain:AMAddPlatoon(spec)

                -- Children
            elseif insert then
                spec.RequiresConstruction = v.RequiresConstruction

                -- Add spec to brain
                spec.InstanceCount = v.InstanceCount
                aiBrain:PBMAddPlatoon(spec)
            end
        end
    end
end

-- TODO: This really ought to be hooked.... this file needs to be made game agnostic as it's in mohodata
function FactionConvert(template, factionIndex)
    local i = 3
    while i <= table.getn(template) do
        if factionIndex == 2 then
            if template[i][1] == 'uel0203' then
                template[i][1] = 'xal0203'
            elseif template[i][1] == 'xes0204' then
                template[i][1] = 'xas0204'
            elseif template[i][1] == 'uea0305' then
                template[i][1] = 'xaa0305'
            elseif template[i][1] == 'xel0305' then
                template[i][1] = 'xal0305'
            else
                template[i][1] = string.gsub(template[i][1], 'ue', 'ua')
            end
        elseif factionIndex == 3 then
            if template[i][1] == 'uea0305' then
                template[i][1] = 'xra0305'
            elseif template[i][1] == 'xes0204' then
                template[i][1] = 'xrs0204'
            elseif template[i][1] == 'xes0205' then
                template[i][1] = 'xrs0205'
            elseif template[i][1] == 'xel0305' then
                template[i][1] = 'xrl0305'
            elseif template[i][1] == 'uel0307' then
                template[i][1] = 'url0306'
            elseif template[i][1] == 'del0204' then
                template[i][1] = 'drl0204'
            else
                template[i][1] = string.gsub(template[i][1], 'ue', 'ur')
            end
        elseif factionIndex == 4 then
            if template[i][1] == 'uel0106' then
                template[i][1] = 'xsl0201'
            elseif template[i][1] == 'xel0305' then
                template[i][1] = 'xsl0305'
            else
                template[i][1] = string.gsub(template[i][1], 'ue', 'xs')
            end
        end
        i = i + 1
    end
    return template
end

function SplitUpdateOSBName(buildName)
    -- OSB_<bname>_location
    local startCheck = 5
    local specificBuilder = false
    if string.sub(buildName, 1, 11) == 'OSB_Master_' then
        startCheck = 12
    elseif string.sub(buildName, 1, 10) == 'OSB_Child_' then
        startCheck = 11
    end
    local pos = string.find(buildName, '_', startCheck)
    local location = false
    local retName = buildName
    local globName = false
    local childPart = false
    if pos then
        globName = string.sub(buildName, startCheck, pos-1)
        retName = string.sub(buildName, 1, pos-1)
    else
        globName = string.sub(buildName, startCheck)
        retName = buildName
    end
    if startCheck <= 5 and pos then
        location = string.sub(buildName, pos+1)
    elseif pos then
        local pos2 = string.find(buildName, '_', pos+1)
        if pos2 then
            childPart = string.sub(buildName, pos+1, pos2-1)
            location = string.sub(buildName, pos2+1)
        else
            childPart = string.sub(buildName, pos+1)
        end
    end
    return retName, location, globName, childPart
end

function SplitOSBName(buildName)
    -- OSB_<bname>_location
    local startCheck = 5
    local specificBuilder = false
    if string.sub(buildName, 1, 11) == 'OSB_Master_' then
        startCheck = 12
    elseif string.sub(buildName, 1, 10) == 'OSB_Child_' then
        startCheck = 11
    end
    local pos = string.find(buildName, '_', startCheck)
    local location = false
    local retName = buildName
    local globName = false
    local childPart = false
    if pos then
        globName = string.sub(buildName, startCheck, pos-1)
        retName = string.sub(buildName, 1, pos-1)
    else
        globName = string.sub(buildName, startCheck)
        retName = buildName
    end
    if startCheck <= 5 and pos then
        location = string.sub(buildName, pos+1)
    elseif pos then
        local pos2 = string.find(buildName, '_', pos+1)
        if pos2 then
            location = string.sub(buildName, pos+1, pos2-1)
            childPart = string.sub(buildName, pos2+1)
        else
            location = string.sub(buildName, pos+1)
        end
    end
    return retName, location, globName, childPart
end

function FilterFunctions(tableOne, tableTwo)
    for t2Num, t2Data in tableTwo do
        if t2Data[3][1] == 'Remove' then
            for t1Num,t1Data in tableOne do
                if t2Data[2] == t1Data[2] then
                    table.remove(tableOne, t1Num)
                end
            end
        else
            table.insert(tableOne, t2Data)
        end
    end
    return tableOne
end
