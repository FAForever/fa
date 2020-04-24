------------------------------------------------------------------------------
-- File     :  /cdimage/lua/ai/opai/BaseManagerPlatoonThreads.lua
-- Author(s):  Drew Staltman
-- Summary  :  Houses a number of AI threads that are used by the Base Manager
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------

local AIUtils = import('/lua/ai/aiutilities.lua')
local AIAttackUtils = import('/lua/ai/aiattackutilities.lua')
local AMPlatoonHelperFunctions = import('/lua/editor/AMPlatoonHelperFunctions.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local SUtils = import('/lua/AI/sorianutilities.lua')
local TriggerFile = import('/lua/scenariotriggers.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')
local Buff = import('/lua/sim/Buff.lua')

local BMBC = import('/lua/editor/basemanagerbuildconditions.lua')
local MIBC = import('/lua/editor/MiscBuildConditions.lua')

-- Split the platoon into single unit platoons
function BaseManagerEngineerPlatoonSplit(platoon)
    local aiBrain = platoon:GetBrain()
    local units = platoon:GetPlatoonUnits()
    local baseName = platoon.PlatoonData.BaseName
    local bManager = aiBrain.BaseManagers[baseName]
    if not bManager then
        aiBrain:DisbandPlatoon(platoon)
    end
    for _, v in units do
        if not v.Dead then
            -- Make sure current base manager isnt at capacity of engineers
            if EntityCategoryContains(categories.ENGINEER, v) and bManager.EngineerQuantity > bManager.CurrentEngineerCount then
                if bManager.EngineerBuildRateBuff then
                    Buff.ApplyBuff(v, bManager.EngineerBuildRateBuff)
                end

                local engPlat = aiBrain:MakePlatoon('', '')
                aiBrain:AssignUnitsToPlatoon(engPlat, {v}, 'Support', 'None')
                engPlat.PlatoonData = table.deepcopy(platoon.PlatoonData)
                v.BaseName = baseName
                engPlat:ForkAIThread(BaseManagerSingleEngineerPlatoon)

                -- If engineer is not a commander or sub-commander, increment number of units working for the base
                -- set up death trigger for the engineer
                if not EntityCategoryContains(categories.COMMAND + categories.SUBCOMMANDER, v) then
                    bManager:AddCurrentEngineer()

                    -- Only add death callback if it hasnt been set yet
                    if not v.Subtracted then
                        TriggerFile.CreateUnitDeathTrigger(BaseManagerSingleDestroyed, v)
                    end

                    -- If the base is building engineers, subtract one from the amount being built
                    if bManager:GetEngineersBuilding() > 0 then
                        bManager:SetEngineersBuilding(-1)
                    end
                end
            end
        end
    end
    aiBrain:DisbandPlatoon(platoon)
end

-- Death callback when units die to decrease counter
function BaseManagerSingleDestroyed(unit)
    if not unit.Subtracted then
        unit.Subtracted = true
        local aiBrain = unit:GetAIBrain()
        local bManager = aiBrain.BaseManagers[unit.BaseName]
        bManager:SubtractCurrentEngineer()
    end
end

-- Callback when unit is removed from base manager
function BaseManagerSingleRemoved(unit)
    local aiBrain = unit:GetAIBrain()
    local bManager = aiBrain.BaseManagers[unit.BaseName]
    bManager:SubtractCurrentEngineer()
end

-- Main function for base manager engineers
function BaseManagerSingleEngineerPlatoon(platoon)
    platoon.PlatoonData.DontDisband = true

    local aiBrain = platoon:GetBrain()
    local pData = platoon.PlatoonData
    local baseName = pData.BaseName
    local bManager = aiBrain.BaseManagers[baseName]
    local unit = platoon:GetPlatoonUnits()[1]
    local canPermanentAssist = EntityCategoryContains(categories.ENGINEER - (categories.COMMAND + categories.SUBCOMMANDER), unit)
    local commandUnit = EntityCategoryContains(categories.COMMAND + categories.SUBCOMMANDER, unit)
    unit.BaseName = baseName
    while aiBrain:PlatoonExists(platoon) do
        if BMBC.BaseEngineersEnabled(aiBrain, baseName) then
            -- Move to expansion base
            if not commandUnit and BMBC.ExpansionBasesEnabled(aiBrain, baseName) and BMBC.ExpansionBasesNeedEngineers(aiBrain, baseName) then
                ExpansionEngineer(platoon)

            elseif canPermanentAssist and bManager.ConditionalBuildData.Unit and not bManager.ConditionalBuildData.Unit.Dead
            and bManager.ConditionalBuildData.NeedsMoreBuilders() then
                AssistConditionalBuild(platoon)

            -- If we can do a conditional build here, then do it
            elseif canPermanentAssist and CanConditionalBuild(platoon) then
                DoConditionalBuild(platoon)

            -- Try to build buildings
            elseif BMBC.NeedAnyStructure(aiBrain, baseName) and bManager:GetConstructionEngineerCount() < bManager:GetConstructionEngineerMaximum() then
                bManager:AddConstructionEngineer(unit)
                TriggerFile.CreateUnitDeathTrigger(ConstructionUnitDeath, unit)
                BaseManagerEngineerThread(platoon)
                bManager:RemoveConstructionEngineer(unit)

            -- Permanent Assist - Assist factories until the unit dies
            elseif canPermanentAssist and bManager:NeedPermanentFactoryAssist() then
                bManager:IncrementPermanentAssisting()
                PermanentFactoryAssist(platoon)

            -- Finish unfinished buildings
            elseif BMBC.UnfinishedBuildingsCheck(aiBrain, baseName) then
                BuildUnfinishedStructures(platoon)

            -- Reclaim nearby wreckage/trees/rocks/people; never do this right now dont want to destroy props and stuff
            elseif false and BMBC.BaseReclaimEnabled(aiBrain, baseName) and MIBC.ReclaimablesInArea(aiBrain, baseName) then
                BaseManagerReclaimThread(platoon)

            -- Try to assist
            elseif BMBC.CategoriesBeingBuilt(aiBrain, baseName, {'MOBILE LAND', 'ALLUNITS' }) or(bManager:ConstructionNeedsAssister()) then
                BaseManagerAssistThread(platoon)

            -- Try to patrol
            elseif BMBC.BasePatrollingEnabled(aiBrain, baseName) and not (unit:IsUnitState('Moving') or unit:IsUnitState('Patrolling')) then
                platoon.PlatoonData.LocationType = baseName
                if bManager:GetDefaultEngineerPatrolChain() then
                    BaseManagerEngineerPatrol(platoon)
                else
                    BaseManagerPatrolLocationFactoriesAI(platoon)
                end
            end
        end
        WaitTicks(Random(51, 113))
    end
end

-- If there is a conditional build that this engineer can tackle, then this function will return true
-- and the base managers ConditionalBuildData.Index will have the index of ConditionalBuildTable stored in it
function CanConditionalBuild(singleEngineerPlatoon)
    local aiBrain = singleEngineerPlatoon:GetBrain()
    local pData = singleEngineerPlatoon.PlatoonData
    local baseName = pData.BaseName
    local bManager = aiBrain.BaseManagers[baseName]
    local engineer = singleEngineerPlatoon:GetPlatoonUnits()[1]
    engineer.BaseName = baseName

    -- Is there a build in progress?
    if bManager.ConditionalBuildData.IsBuilding then
        -- If there's a build in progress but the unit is dead, reset the variables.
        if bManager.ConditionalBuildData.Unit.Dead then
            local selectedBuild = bManager.ConditionalBuildTable[bManager.ConditionalBuildData.Index]
            -- If we're not supposed to retry, then remove from the conditional build list
            if not selectedBuild.data.Retry then
                table.remove(bManager.ConditionalBuildTable, bManager.ConditionalBuildData.Index)
            end
            bManager.ConditionalBuildData.Reset()
        else
            return false
        end
    end

    -- Is there a build being initiated (unit is moving to start the build)?
    if bManager.ConditionalBuildData.IsInitiated then
        -- Is the initiator is still alive? (If the initiator is dead it means he died before the build was started and we can ignore the IsInitiated flag)
        if bManager.ConditionalBuildData.MainBuilder and not bManager.ConditionalBuildData.MainBuilder.Dead then
            return false
        end
    end

    -- Are there no conditional builds?
    if table.getn(bManager.ConditionalBuildTable) == 0 then
        return false
    end

    -- What we should build from the conditional build list.
    local buildIndex = 0

    -- Go through the list of conditional builds and see if any of the conditions are met
    table.foreachi(bManager.ConditionalBuildTable, function(index, build)
        if buildIndex ~= 0 then return end

        -- Check if this engineer can build this particular structure
        if type(build.name) == 'table' then --table of units to build at random
            for i, unitName in build.name do
                local unitToBuild = ScenarioUtils.FindUnit(unitName, Scenario.Armies[aiBrain.Name].Units)
                if not unitToBuild then error('*CONDITIONAL BUILD ERROR: No unit exists with name ' ..unitName) end
                if not engineer:CanBuild(unitToBuild.type) then return end
            end
        else
            local unitToBuild = ScenarioUtils.FindUnit(build.name, Scenario.Armies[aiBrain.Name].Units)
            if not unitToBuild then error('*CONDITIONAL BUILD ERROR: No unit exists with name ' ..build.name) end
            if not engineer:CanBuild(unitToBuild.type) then return end
        end

        local Conditions = build.data.BuildCondition or {}

        -- If this particular conditional build has a post-death timer lock on it.
        if ScenarioInfo.ConditionalBuildLocks and ScenarioInfo.ConditionalBuildLocks[build.name] then
            return
        end

        -- If Conditions is a new-style predicate condition function...
        if type(Conditions) == "function" then
            if not Conditions() then return end

            -- Condition is true.
            buildIndex = index

        -- If Conditions is an old-style condition table...
        else
            local conditionsMet = true
            table.foreachi(Conditions, function(idx, cond)
                if not conditionsMet then return end

                if not import(cond[1])[cond[2]](aiBrain, unpack(cond[3])) then
                    conditionsMet = false
                    return
                end
            end)

            if not conditionsMet then return end

            -- Condition is true.
            buildIndex = index

        end
    end)

    -- Bail out if we didnt find a conditional unit
    if buildIndex == 0 then return false end

    -- Save index for use
    bManager.ConditionalBuildData.Index = buildIndex

    return true
end

-- Called when a unit helping on a conditional build bites it
function ConditionalBuilderDead(engineer)
    local aiBrain = engineer:GetAIBrain()
    local bManager = aiBrain.BaseManagers[engineer.BaseName]

    bManager.ConditionalBuildData.DecrementAssisting()
end

function ConditionalBuildDied(conditionalUnit)
    local aiBrain = conditionalUnit:GetAIBrain()
    local bManager = aiBrain.BaseManagers[conditionalUnit.BaseName]
    local selectedBuild = conditionalUnit.ConditionalBuild

    -- Reinsert the conditional build (for one of these units)
    table.insert(bManager.ConditionalBuildTable, {
        name = selectedBuild.name,
        data =  {
            MaxAssist = selectedBuild.data.MaxAssist,
            BuildCondition = selectedBuild.data.BuildCondition,
            PlatoonAIFunction = selectedBuild.data.PlatoonAIFunction,
            PlatoonData = selectedBuild.data.PlatoonData,
            Retry = selectedBuild.data.Retry,
            KeepAlive = true,
            Amount = 1,
            WaitSecondsAfterDeath = selectedBuild.data.WaitSecondsAfterDeath,
        },
    })

end

function ConditionalBuildSuccessful(conditionalUnit)
    local aiBrain = conditionalUnit:GetAIBrain()
    local bManager = aiBrain.BaseManagers[conditionalUnit.BaseName]
    local selectedBuild = bManager.ConditionalBuildTable[bManager.ConditionalBuildData.Index]

    -- Assign AI
    local newPlatoon = aiBrain:MakePlatoon('', '')
    aiBrain:AssignUnitsToPlatoon(newPlatoon, {conditionalUnit}, 'Attack', 'None')
    newPlatoon:StopAI()
    newPlatoon:SetPlatoonData(selectedBuild.data.PlatoonData)
    newPlatoon:ForkAIThread(import(selectedBuild.data.PlatoonAIFunction[1])[selectedBuild.data.PlatoonAIFunction[2]])

    -- Set up a death wait thing for it to rebuild
    if bManager.ConditionalBuildData.WaitSecondsAfterDeath then
        -- If were supposed to wait a certain amount of time before building the unit again, handle that here.
        ScenarioInfo.ConditionalBuildLocks = ScenarioInfo.ConditionalBuildLocks or {}
        ScenarioInfo.ConditionalBuildLocks[selectedBuild.name] = true

        local waitTime = bManager.ConditionalBuildData.WaitSecondsAfterDeath

        -- Register death callback
        TriggerFile.CreateUnitDeathTrigger(function(unit)
            aiBrain:ForkThread(function()
                WaitSeconds(waitTime)
                ScenarioInfo.ConditionalBuildLocks[selectedBuild.name] = false
            end)
        end,
        conditionalUnit
        )
    end

    -- Remove from the conditional build list if were not supposed to build any more
    if not selectedBuild.data.Amount then
        table.remove(bManager.ConditionalBuildTable, bManager.ConditionalBuildData.Index)
    elseif selectedBuild.data.Amount > 0 then
        -- Decrement the amount left to build
        selectedBuild.data.Amount = selectedBuild.data.Amount - 1

        -- If none are left to build, remove from the build table
        if selectedBuild.data.Amount == 0 then
            table.remove(bManager.ConditionalBuildTable, bManager.ConditionalBuildData.Index)
        end
    end

    -- Reset conditional build variables
    bManager.ConditionalBuildData.Reset()
end

-- Called if there is a conditional build in progress that can be assisted
function AssistConditionalBuild(singleEngineerPlatoon)
    local aiBrain = singleEngineerPlatoon:GetBrain()
    local pData = singleEngineerPlatoon.PlatoonData
    local baseName = pData.BaseName
    local bManager = aiBrain.BaseManagers[baseName]
    local engineer = singleEngineerPlatoon:GetPlatoonUnits()[1]
    engineer.BaseName = baseName

    -- Restore the index saved in the CanConditionalBuild call
    local buildIndex = bManager.ConditionalBuildData.Index

    -- Register death callback
    TriggerFile.CreateUnitDeathTrigger(ConditionalBuilderDead, engineer)

    -- Increment number of units assisting
    bManager.ConditionalBuildData.IncrementAssisting()

    -- Give orders to repair the unit
    IssueClearCommands({engineer})
    IssueRepair({engineer}, bManager.ConditionalBuildData.Unit)

    -- Super loop
    while aiBrain:PlatoonExists(singleEngineerPlatoon) do
        WaitSeconds(3)

        if engineer:IsIdleState() then
            break
        end
    end

    IssueClearCommands({engineer})
    TriggerFile.RemoveUnitTrigger(engineer, ConditionalBuilderDead)
end

-- Called if there is a conditional build available to start
function DoConditionalBuild(singleEngineerPlatoon)
    local aiBrain = singleEngineerPlatoon:GetBrain()
    local pData = singleEngineerPlatoon.PlatoonData
    local baseName = pData.BaseName
    local bManager = aiBrain.BaseManagers[baseName]
    local engineer = singleEngineerPlatoon:GetPlatoonUnits()[1]
    engineer.BaseName = baseName

    -- Restore the index saved in the CanConditionalBuild call
    local buildIndex = bManager.ConditionalBuildData.Index
    local selectedBuild = bManager.ConditionalBuildTable[buildIndex]

    -- Get unit plans from the scenario
    local unitToBuild
    if type(selectedBuild.name) == 'table' then
        unitToBuild = ScenarioUtils.FindUnit(selectedBuild.name[math.random(1, table.getn(selectedBuild.name))], Scenario.Armies[aiBrain.Name].Units)
        if not unitToBuild then error('Unit with name "' .. selectedBuild.name .. '" could not be found for conditional building.') return end
    else
        unitToBuild = ScenarioUtils.FindUnit(selectedBuild.name, Scenario.Armies[aiBrain.Name].Units)
        if not unitToBuild then error('Unit with name "' .. selectedBuild.name .. '" could not be found for conditional building.') return end
    end

    -- Initialize variables
    bManager.ConditionalBuildData.MainBuilder = engineer
    bManager.ConditionalBuildData.NumAssisting = 1
    bManager.ConditionalBuildData.MaxAssisting = selectedBuild.data.MaxAssist or 1
    bManager.ConditionalBuildData.Unit = false
    bManager.ConditionalBuildData.IsInitiated = true  -- Prevents other engineers from trying to start their own builds
    bManager.ConditionalBuildData.IsBuilding = false
    bManager.ConditionalBuildData.WaitSecondsAfterDeath = selectedBuild.data.WaitSecondsAfterDeath or false

    -- Register death callback
    TriggerFile.CreateUnitDeathTrigger(ConditionalBuilderDead, engineer)

    -- Issue build orders
    IssueClearCommands({engineer})
    local result = aiBrain:BuildStructure(engineer, unitToBuild.type, {unitToBuild.Position[1], unitToBuild.Position[3], 0})

    -- Enter build monitoring loop
    local unitInstance = false
    while aiBrain:PlatoonExists(singleEngineerPlatoon) do
        if not unitInstance then
            unitInstance = engineer.UnitBeingBuilt
            if unitInstance then
                -- Store the unit
                bManager.ConditionalBuildData.Unit = unitInstance

                -- If were supposed to keep a certain number of these guys in the field, store the info on him so he can reinsert
                -- himself in the conditional build table when he bites it.
                if selectedBuild.data.KeepAlive then
                    unitInstance.KeepAlive = true
                    unitInstance.ConditionalBuild = selectedBuild
                    unitInstance.ConditionalBuildData = bManager.ConditionalBuildData

                    -- register rebuild callback
                    TriggerFile.CreateUnitDeathTrigger(ConditionalBuildDied, unitInstance)
                end

                -- Tell the unit the name of this base manager
                unitInstance.BaseName = baseName

                -- Set variables so other engineers can see whats going on
                bManager.ConditionalBuildData.IsInitiated = false
                bManager.ConditionalBuildData.IsBuilding = true

                -- Register callbacks
                TriggerFile.CreateUnitStopBeingBuiltTrigger(ConditionalBuildSuccessful, unitInstance)
            end
        end
        if engineer:IsIdleState() then
            break
        end
        WaitTicks(Random(7, 13))
    end
    IssueClearCommands({engineer})
    TriggerFile.RemoveUnitTrigger(engineer, ConditionalBuilderDead)
end

function BaseManagerEngineerPatrol(platoon)
    local aiBrain = platoon:GetBrain()
    local baseName = platoon.PlatoonData.BaseName
    local bManager = aiBrain.BaseManagers[baseName]
    local patrolChain = ScenarioUtils.ChainToPositions(bManager:GetDefaultEngineerPatrolChain())
    platoon:Stop()
    for k, v in patrolChain do
        platoon:Patrol(v)
    end
end

-- When a unit that was constructing dies
function ConstructionUnitDeath(unit)
    local aiBrain = unit:GetAIBrain()
    local bManager = aiBrain.BaseManagers[unit.BaseName]
    bManager:RemoveConstructionEngineer(unit)
end

function PermanentFactoryAssist(platoon)
    local aiBrain = platoon:GetBrain()
    local bManager = aiBrain.BaseManagers[platoon.PlatoonData.BaseName]
    local assisting = false
    local unit = platoon:GetPlatoonUnits()[1]

    TriggerFile.CreateUnitDeathTrigger(PermanentAssisterDead, unit)
    while aiBrain:PlatoonExists(platoon) do
        -- Get all factories in the base manager
        local facs = bManager:GetAllBaseFactories()

        -- Determine the number of guards on all factories
        local high, highFac, low, lowFac
        for _, v in facs do
            if not v.Dead then
                local guards = v:GetGuards()
                local numGuards = 0
                for gNum, gUnit in guards do
                    if not gUnit.Dead and not EntityCategoryContains(categories.FACTORY, gUnit)
                    and bManager.PermanentAssisters and bManager.PermanentAssisters[gUnit] then -- Make sure this guy is a permanent assister and not a transient assister
                        numGuards = numGuards + 1
                    end
                end
                if not high or numGuards > high then
                    high = numGuards
                    highFac = v
                end
                if not low or numGuards < low then
                    low = numGuards
                    lowFac = v
                end
            end
        end
        -- If the disparity between factories is more than 1, reorganize engineers
        if (not assisting and lowFac) or (high and low and lowFac and high > low + 1 and highFac == unit:GetGuardedUnit()) then
            assisting = true
            platoon:Stop()
            IssueGuard({unit}, lowFac)

            -- Add to the list of units that are permanently assisting in this base manager
            if not bManager.PermanentAssisters then bManager.PermanentAssisters = {} end

            bManager.PermanentAssisters[unit] = true
        end
        WaitTicks(Random(79, 181))
    end
end

function PermanentAssisterDead(unit)
    local bManager = unit:GetAIBrain().BaseManagers[unit.BaseName]
    if bManager then
        bManager:DecrementPermanentAssisting()

        -- Remove from permanent assister list
        if bManager.PermanentAssisters then
            bManager.PermanentAssisters[unit] = nil
        end
    end
end

-- Assist units that are building structures and units
function BaseManagerAssistThread(platoon)
    platoon:Stop()

    local platoonUnits = platoon:GetPlatoonUnits()
    local aiBrain = platoon:GetBrain()
    local bManager = aiBrain.BaseManagers[platoon.PlatoonData.BaseName]
    local assistData = platoon.PlatoonData.Assist
    local platoonPos = platoon:GetPlatoonPosition()
    local assistee = false
    local assistingBool = false
    local beingBuiltCategories = assistData.BeingBuiltCategories

    if not beingBuiltCategories then
        beingBuiltCategories = {'MASSEXTRACTION', 'MASSPRODUCTION', 'ENERGYPRODUCTION', 'FACTORY', 'EXPERIMENTAL', 'DEFENSE', 'MOBILE LAND', 'ALLUNITS' }
    end

    local assistRange = assistData.AssistRange or 80
    local counter = 0
    local unit = platoonUnits[1]
    while counter < (assistData.Time or 200) do

        -- If the engineer is assisting a construction unit that is building; break out and do nothing
        if not unit:GetGuardedUnit() or
                -- Check if the guarding unit is not building
                (not unit:GetGuardedUnit():IsUnitState('Building')
                -- Check if the base isnt constantly assisting a construction engineer
                and not bManager:ConstructionNeedsAssister()
                -- check if the unit being guarded is not
                and not bManager:IsConstructionUnit(unit:GetGuardedUnit())) then
            if bManager:ConstructionNeedsAssister() then
                local consUnits = bManager.ConstructionEngineers
                local lowNum = 100000
                local highNum = 0
                local currLow = false
                for _, v in consUnits do
                    local guardNum = table.getn(v:GetGuards())
                    if not v.Dead and guardNum < lowNum then
                        currLow = v
                        lowNum = table.getn(v:GetGuards())
                    end
                    if guardNum > highNum then
                        highNum = guardNum
                    end
                end
                if unit:GetGuardedUnit() then
                    if unit:GetGuardedUnit().Dead or EntityCategoryContains(categories.FACTORY, unit:GetGuardedUnit()) or
                            highNum > lowNum + 1 then
                        assistee = currLow
                    end
                else
                    assistee = currLow
                end
            end
            -- Find valid unit to assist
            -- Get all units building stuff - TODO get list with point and radius; get list of units with state
            if not assistee then
                local unitsBuilding = aiBrain:GetListOfUnits(categories.CONSTRUCTION, false)
                -- Iterate through being built categories
                for catNum, buildeeCat in beingBuiltCategories do
                    local buildCat = ParseEntityCategory(buildeeCat)
                    for unitNum, constructionUnit in unitsBuilding do
                        -- Check if the unit is actually building something
                        if not constructionUnit.Dead and constructionUnit:IsUnitState('Building') then
                            -- Check to make sure unit being built is of proper category
                            local buildingUnit = constructionUnit.UnitBeingBuilt
                            if buildingUnit and not buildingUnit.Dead and EntityCategoryContains(buildCat, buildingUnit) then
                                -- If the unit building is a factory make sure its in the right PBM Location Type
                                if not EntityCategoryContains(categories.FACTORY, constructionUnit) or aiBrain:PBMFactoryLocationCheck(constructionUnit, platoon.PlatoonData.BaseName) then
                                    -- make sure unit is within valid assist range
                                    local unitPos = constructionUnit:GetPosition()
                                    if unitPos and platoonPos and VDist2(platoonPos[1], platoonPos[3], unitPos[1], unitPos[3]) < assistRange then
                                        assistee = constructionUnit
                                        break
                                    end
                                end
                            end
                        end
                    end
                    -- If we have found a valid unit to assist break off
                    if assistee then
                        break
                    end
                end
            end

            -- If the unit to be assisted is a factory, assist whatever it is assisting or is assisting it
            -- Makes sure all factories have someone helping out to load balance better
            if assistee and not assistee.Dead and EntityCategoryContains(categories.FACTORY, assistee) then
                platoon:Stop()
                local guardee = assistee:GetGuardedUnit()
                if guardee and not guardee.Dead and EntityCategoryContains(categories.FACTORY, guardee) then
                    local factories = AIUtils.AIReturnAssistingFactories(guardee)
                    table.insert(factories, assistee)
                    AIUtils.AIEngineersAssistFactories(aiBrain, platoonUnits, factories)
                    assistingBool = true
                elseif table.getn(assistee:GetGuards()) > 0 then
                    local factories = AIUtils.AIReturnAssistingFactories(assistee)
                    table.insert(factories, assistee)
                    AIUtils.AIEngineersAssistFactories(aiBrain, platoonUnits, factories)
                    assistingBool = true
                end
            end
            if assistee and not assistee.Dead then
                if not assistingBool then
                    platoon:Stop()
                    IssueGuard(platoonUnits, assistee)
                end
            end
        end
        local waitTime = Random(5, 17)
        WaitTicks(waitTime)

        counter = counter + waitTime
    end
end

-- New base expansion
function ExpansionEngineer(platoon)
    platoon:Stop()

    local unitCount = table.getn(platoon:GetPlatoonUnits())
    local aiBrain = platoon:GetBrain()
    local data = platoon.PlatoonData

    if not (data.BaseName and aiBrain.BaseManagers[data.BaseName] and aiBrain.BaseManagers[data.BaseName].ExpansionBaseData) then
        aiBrain:DisbandPlatoon(platoon)
        return
    end

    local bManager = aiBrain.BaseManagers[data.BaseName]
    local cmd = false
    for num, eData in bManager.ExpansionBaseData do
        -- Find out what expansion base needs engineers
        if BMBC.NumEngiesInExpansionBase(aiBrain, data.BaseName, eData.BaseName) then
            if data.ExpansionBase ~= eData.BaseName then
                data.ExpansionBase = eData.BaseName
            end

            -- Tracks engineers that are on the way to the expansion base
            eData.IncomingEngineers = eData.IncomingEngineers + unitCount

            -- Remove engieneer from IncomingEngineers if it dies on the way
            platoon:AddDestroyCallback(ExpansionPlatoonDestroyed)

            if eData.TransportPlatoon or VDist3(platoon:GetPlatoonPosition(), aiBrain.BaseManagers[eData.BaseName]:GetPosition()) > 250 then
                cmd = TransportUnitsToLocation(platoon, aiBrain.BaseManagers[eData.BaseName]:GetPosition())
            end

            if not cmd then
                cmd = platoon:MoveToLocation(aiBrain.BaseManagers[eData.BaseName]:GetPosition(), false)
            end
            break
        end
    end
    WaitSeconds(2)

    if not aiBrain:PlatoonExists(platoon) then
        return
    end

    if cmd and type(cmd) ~= 'boolean' then
        while platoon:IsCommandsActive(cmd) do
            WaitSeconds(5)
            if not aiBrain:PlatoonExists(platoon) then
                return
            end
        end
    end

    for num, eData in bManager.ExpansionBaseData do
        if eData.BaseName == data.ExpansionBase then
            eData.IncomingEngineers = eData.IncomingEngineers - 1
        end
    end

    if aiBrain:PlatoonExists(platoon) then
        local unit = platoon:GetPlatoonUnits()[1]
        BaseManagerSingleRemoved(unit)
        platoon:RemoveDestroyCallback(ExpansionPlatoonDestroyed)
        aiBrain:DisbandPlatoon(platoon)
    end
end

function ExpansionPlatoonDestroyed(brain, platoon)
    local aiBrain = platoon:GetBrain()
    local data = platoon.PlatoonData
    local bManager = aiBrain.BaseManagers[data.BaseName]
    local eBaseName = false

    for num, eData in bManager.ExpansionBaseData do
        if eData.BaseName == data.ExpansionBase then
            eData.IncomingEngineers = eData.IncomingEngineers - 1
        end
    end
end

-- Move a unit to a new location
function TransportUnitsToLocation(platoon, finalLocation)
    local units = platoon:GetPlatoonUnits()
    if AIUtils.CheckUnitPathingEx(finalLocation, units[1]:GetPosition(), units[1]) then
        local cmd = platoon:MoveToLocation(finalLocation, false)
        return cmd
    end

    if not AIUtils.GetTransports(platoon) then
        return false
    end
    AIUtils.UseTransports(units, platoon:GetSquadUnits('Scout'), finalLocation)

    return true
end

-- Engineer build structures
function BaseManagerEngineerThread(platoon)
    platoon:Stop()

    local aiBrain = platoon:GetBrain()
    local platoonUnits = platoon:GetPlatoonUnits()
    local eng

    for _, v in platoonUnits do
        if not v.Dead and EntityCategoryContains(categories.CONSTRUCTION, v) then
            if not eng then
                eng = v
            else
                IssueClearCommands({v})
                IssueGuard({v}, eng)
            end
        end
    end

    if not eng or eng.Dead then
        aiBrain:DisbandPlatoon(platoon)
        return
    end

    -- CHOOSE APPROPRIATE BUILD FUNCTION AND SETUP BUILD VARIABLES

    if not platoon.PlatoonData.BaseName or not aiBrain.BaseManagers[platoon.PlatoonData.BaseName] then
        error('*AI DEBUG: Missing Base Name or invalid base name for base manager engineer thread', 2)
    end

    local structurePriTable
    if not platoon.PlatoonData.StructurePriorities then
        structurePriTable = { 'ALLUNITS' }
    else
        structurePriTable = platoon.PlatoonData.StructurePriorities
    end

    -- If there is a construction block use the stuff from here
    local buildFunction = BuildBaseManagerStructure

    -- BUILD BUILDINGS HERE
    if eng.Dead then
        aiBrain:DisbandPlatoon(platoon)
    end

    local structurePriorities = platoon.PlatoonData.StructurePriorities
    if not structurePriorities then
        structurePriorities = {'T3Resource', 'T2Resource', 'T1Resource', 'T3EnergyProduction', 'T2EnergyProduction', 'T1EnergyProduction', 'T3MassCreation',
            'T2EngineerSupport', 'T3SupportLandFactory', 'T3SupportAirFactory', 'T3SupportSeaFactory', 'T2SupportLandFactory', 'T2SupportAirFactory', 'T2SupportSeaFactory',
            'T1LandFactory', 'T1AirFactory', 'T1SeaFactory', 'T4LandExperimental1', 'T4LandExperimental2', 'T4AirExperimental1',
            'T4SeaExperimental1', 'T3ShieldDefense', 'T2ShieldDefense', 'T3StrategicMissileDefense', 'T3Radar', 'T2Radar', 'T1Radar',
            'T3AADefense', 'T3GroundDefense', 'T3NavalDefense', 'T2AADefense', 'T2MissileDefense', 'T2GroundDefense', 'T2NavalDefense', 'ALLUNITS'}
    end

    local retBool, unitName
    local nameSet = false
    local baseManager = aiBrain.BaseManagers[platoon.PlatoonData.BaseName]
    local armyIndex = aiBrain:GetArmyIndex()
    for dNum, levelData in baseManager.LevelNames do
        if levelData.Priority > 0 then
            for _, v in structurePriorities do
                local unitType = false
                if v ~= 'ALLUNITS' then
                    unitType = v
                end

                repeat
                    nameSet = false
                    local markedUnfinished = false
                    retBool, unitName = buildFunction(aiBrain, eng, aiBrain.BaseManagers[platoon.PlatoonData.BaseName], levelData.Name, unitType, platoon)
                    if retBool then
                        repeat
                            if not nameSet then
                                WaitSeconds(0.1)
                            else
                                WaitSeconds(3)
                            end

                            if not aiBrain:PlatoonExists(platoon) then
                                return
                            end

                            if not markedUnfinished and eng.UnitBeingBuilt then
                                baseManager.UnfinishedBuildings[unitName] = true
                            end

                            if not nameSet then
                                local buildingUnit = eng.UnitBeingBuilt
                                if unitName and buildingUnit and not buildingUnit.Dead then
                                    nameSet = true
                                    local armyIndex = aiBrain:GetArmyIndex()
                                    if ScenarioInfo.UnitNames[armyIndex] and EntityCategoryContains(categories.STRUCTURE, buildingUnit) then
                                        ScenarioInfo.UnitNames[armyIndex][unitName] = buildingUnit
                                    end
                                    buildingUnit.UnitName = unitName
                                end
                            end
                        until eng.Dead or eng:IsIdleState()
                        if not eng.Dead then
                            baseManager.UnfinishedBuildings[unitName] = false
                            baseManager:DecrementUnitBuildCounter(unitName)
                        end
                    end
                until not retBool
            end
        end
    end
    local tempPos = aiBrain.BaseManagers[platoon.PlatoonData.BaseName]:GetPosition()
    platoon:MoveToLocation(tempPos, false)
end

-- Guts of the build thing
function BuildBaseManagerStructure(aiBrain, eng, baseManager, levelName, buildingType, platoon)
    local buildTemplate = aiBrain.BaseTemplates[baseManager.BaseName .. levelName].Template
    local buildList = aiBrain.BaseTemplates[baseManager.BaseName .. levelName].List

    if not buildTemplate or not buildList then
        return false
    end

    local namesTable = aiBrain.BaseTemplates[baseManager.BaseName .. levelName].UnitNames
    local buildCounter = aiBrain.BaseTemplates[baseManager.BaseName .. levelName].BuildCounter
    for K, v in buildTemplate do
        -- Check if type (ex. T1AirFactory) is correct
        if (not buildingType or buildingType == 'ALLUNITS' or buildingType == v[1][1]) and baseManager:CheckStructureBuildable(v[1][1]) then
            local category
            for catName, catData in buildList do
                if catData.StructureType == v[1][1] then
                    category = catData.StructureCategory
                    break
                end
            end
            if category and eng:CanBuild(category) then
                -- Iterate through build locations
                for num, location in v do
                    -- Check if it can be built and then build
                    if num > 1 and aiBrain:CanBuildStructureAt(category, {location[1], 0, location[2]}) and baseManager:CheckUnitBuildCounter(location, buildCounter) then
                        -- Removed transport call as the pathing check was creating problems with base manager rebuilding
                        -- TODO: develop system where base managers more easily rebuild in far away or hard to reach locations
                        -- and TransportUnitsToLocation(platoon, {location[1], 0, location[2]}) then
                        IssueClearCommands({eng})
                        aiBrain:BuildStructure(eng, category, location, false)

                        local unitName = false
                        if namesTable[location[1]][location[2]] then
                            unitName = namesTable[location[1]][location[2]]
                        end

                        return true, unitName
                    end
                end
            end
        end
    end
    return false
end

-- Finish building structures that werent finshed
function BuildUnfinishedStructures(platoon)
    platoon:Stop()

    local aiBrain = platoon:GetBrain()
    local platoonUnits = platoon:GetPlatoonUnits()
    local armyIndex = aiBrain:GetArmyIndex()
    local eng = platoonUnits[1]
    local bManager = aiBrain.BaseManagers[platoon.PlatoonData.BaseName]

    if not eng or eng.Dead then
        aiBrain:DisbandPlatoon(platoon)
        return
    end

    -- Otherwise help build whatever needs us
    local unfinishedBuildings = false
    repeat
        unfinishedBuildings = false
        local beingBuiltList = {}
        local buildingEngs = aiBrain:GetListOfUnits(categories.ENGINEER, false)
        -- Find all engineers building structures
        for k, v in buildingEngs do
            local buildingUnit = v.UnitBeingBuilt
            if buildingUnit and buildingUnit.UnitName then
                beingBuiltList[buildingUnit.UnitName] = true
            end
        end
        -- Check all unfinished buildings to see if they need someone workin on them
        for k, v in bManager.UnfinishedBuildings do
            if v and ScenarioInfo.UnitNames[armyIndex][k] and not ScenarioInfo.UnitNames[armyIndex][k].Dead then
                if not beingBuiltList[k] then
                    unfinishedBuildings = true
                    IssueClearCommands({eng})
                    IssueRepair({eng}, ScenarioInfo.UnitNames[armyIndex][k])
                    repeat
                        WaitSeconds(3)
                        if not aiBrain:PlatoonExists(platoon) then
                            return
                        end
                    until eng:IsIdleState()
                    bManager.UnfinishedBuildings[v] = false
                end
            end
        end
    until not unfinishedBuildings
end

function BaseManagerPatrolLocationFactoriesAI(platoon)
    local aiBrain = platoon:GetBrain()
    local location = platoon.PlatoonData.BaseName
    local patrol = true
    if platoon.PlatoonData.BaseName and aiBrain.BaseManagers[platoon.PlatoonData.BaseName]
            and not aiBrain.BaseManagers[platoon.PlatoonData.BaseName].FunctionalityStates.EngineerReclaiming then
        patrol = false
    end

    local returnOut = false
    while aiBrain:PlatoonExists(platoon) and not returnOut do
        platoon:Stop()
        local factories = aiBrain:PBMGetLocationFactories(location)
        local posTable = {}
        if factories then
            for _, fac in factories do
                if not fac.Dead then
                    table.insert(posTable, fac:GetPosition())
                    local guards = fac:GetGuards()
                    if guards then
                        for num, guard in guards do
                            if not guard.Dead then
                                table.insert(posTable, guard:GetPosition())
                            end
                        end
                    end
                end
            end

            local i = 1
            while i <= table.getn(posTable) do
                local facNum = Random(1, table.getn(posTable))
                local movePos = posTable[facNum]
                movePos[3] = movePos[3] + 5
                if patrol then
                    platoon:Patrol(movePos)
                else
                    platoon:MoveToLocation(movePos, false)
                end
                table.remove(posTable, facNum)
            end
        end
        return
    end
end

function PlatoonSetTargetPriorities(platoon)
    if platoon.PlatoonData.CategoryPriorities then
        -- Get the list of units in the platoon
        local units = platoon:GetPlatoonUnits()

        -- For each unit, if they match any of the categories, assign the corresponding priorities
        for kCategory, vPriority in platoon.PlatoonData.CategoryPriorities do
            for iUnit, vUnit in units do
                if EntityCategoryContains(kCategory, vUnit) then
                    vUnit:SetTargetPriorities(vPriority)
                end
            end
        end
    else
        local priList = {}
        for k, v in platoon.PlatoonData.TargetPriorities do
            table.insert(priList, ParseEntityCategory(v))
        end

        local squads = { 'attack', 'support', 'scout', 'artillery' }
        for k, v in squads do
            platoon:SetPrioritizedTargetList(v, priList)
        end
    end
end

function GetScoutingPath(bManager, unit)
    local mapInfo = {}
    if not ScenarioInfo.MapData.PlayableRect then
        mapInfo[1] = 0
        mapInfo[2] = 0
        mapInfo[3] = ScenarioInfo.size[1]
        mapInfo[4] = ScenarioInfo.size[2]
    else
        mapInfo = ScenarioInfo.MapData.PlayableRect
    end

    local pathablePoints = {}
    local possiblePoints = {}
    if EntityCategoryContains(categories.AIR, unit) and bManager:GetDefaultAirScoutPatrolChain() then
        -- Do air thing
        pathablePoints = ScenarioUtils.ChainToPositions(bManager:GetDefaultAirScoutPatrolChain())
    elseif EntityCategoryContains(categories.LAND, unit) and bManager:GetDefaultLandScoutPatrolChain() then
        -- Do land thing
        pathablePoints = ScenarioUtils.ChainToPositions(bManager:GetDefaultLandScoutPatrolChain())
    else
        local startX = mapInfo[1]
        local startY = mapInfo[2]
        local currX = startX
        -- Create a table of possible points by increasing x and y vals
        while currX < mapInfo[3] do
            local currY = startY
            while currY < mapInfo[4] do
                local useY = currY
                local useX = currX
                -- Check if the coords are the map boundaries and move them in if they are
                if currX == mapInfo[1] then
                    useX = currX + 8
                end
                if currY == mapInfo[2] then
                    useY = currY + 8
                end
                if currX == mapInfo[3] then
                    useX = currX - 8
                end
                if currY == mapInfo[4] then
                    useY = currY - 8
                end
                table.insert(possiblePoints, { useX, 0, useY })
                currY = currY + 48
            end
            currX = currX + 48
        end
        -- Determine which poitnts the unit can actually path to
        for k, v in possiblePoints do
            if AIUtils.CheckUnitPathingEx(v, unit:GetPosition(), unit) then
                table.insert(pathablePoints, v)
            end
        end
    end
    return pathablePoints
end

function BaseManagerScoutingAI(platoon)
    local aiBrain = platoon:GetBrain()
    local unit = platoon:GetPlatoonUnits()[1]
    local bManager = aiBrain.BaseManagers[platoon.PlatoonData.BaseName]

    -- Set up move orders to up to 10 points
    while aiBrain:PlatoonExists(platoon) do
        -- Get new points every time so if the area changes we are on it
        local pathablePoints = GetScoutingPath(bManager, unit)
        local numPoints = table.getn(pathablePoints)
        if numPoints > 0 then
            platoon:Stop()
        end

        local count = 0
        if numPoints > 0 then
            while count < 10 do
                local pickNum = Random(1, numPoints)
                platoon:MoveToLocation(pathablePoints[pickNum], false)
                count = count + 1
            end
        end
        WaitSeconds(35)
    end
end

function BaseManagerTMLAI(platoon)
    local aiBrain = platoon:GetBrain()
    local pData = platoon.PlatoonData
    local baseName = pData.BaseName
    local bManager = aiBrain.BaseManagers[baseName]
    local unit = platoon:GetPlatoonUnits()[1]
    unit.BaseName = baseName

    if not unit then return end

    platoon:Stop()
    local bp = unit:GetBlueprint()
    local weapon = bp.Weapon[1]
    local maxRadius = weapon.MaxRadius
    local minRadius = weapon.MinRadius

    local simpleTargetting = true
    if ScenarioInfo.Options.Difficulty == 3 then
        simpleTargetting = false
    end

    unit:SetAutoMode(true)

    platoon:SetPrioritizedTargetList('Attack', {
        categories.COMMAND,
        categories.EXPERIMENTAL,
        categories.ENERGYPRODUCTION,
        categories.STRUCTURE,
        categories.TECH3 * categories.MOBILE})

    while aiBrain:PlatoonExists(platoon) do
        if BMBC.TMLsEnabled(aiBrain, baseName) then
            local target = false
            local blip = false
            while unit:GetTacticalSiloAmmoCount() < 1 or not target do
                WaitSeconds(7)
                target = false
                while not target do
                    target = platoon:FindPrioritizedUnit('Attack', 'Enemy', true, unit:GetPosition(), maxRadius)

                    if target then
                        break
                    end

                    WaitSeconds(3)

                    if not aiBrain:PlatoonExists(platoon) then
                        return
                    end
                end
            end
            if not target.Dead then
                if EntityCategoryContains(categories.STRUCTURE, target) or simpleTargetting then
                    IssueTactical({unit}, target)
                else
                    targPos = SUtils.LeadTarget(platoon, target)
                    if targPos then
                        IssueTactical({unit}, targPos)
                    end
                end
            end
        end
        WaitSeconds(3)
    end
end

function BaseManagerNukeAI(platoon)
end

function AMUnlockBuildTimer(platoon)
    ForkThread(AMPlatoonHelperFunctions.UnlockTimer, platoon.PlatoonData.LockTimer, platoon.PlatoonData.PlatoonName)
end

function AMUnlockRatio(platoon)
    local count = 0
    for k, v in platoon:GetPlatoonUnits() do
        if not v.Dead then
            count = count + 1
        end
    end
    platoon.MaxUnits = count
    platoon.LivingUnits = count
    platoon.Locked = true
    local callback = function(unit)
                         platoon.LivingUnits = platoon.LivingUnits - 1
                         if platoon.Locked and platoon.PlatoonData.Ratio > (platoon.LivingUnits / platoon.MaxUnits) then
                             ScenarioInfo.AMLockTable[platoon.PlatoonData.PlatoonName] = false
                             platoon.Locked = false
                         end
                     end
    for _, v in platoon:GetPlatoonUnits() do
        if not v.Dead then
            v.PlatoonHandle = platoon
            TriggerFile.CreateUnitDeathTrigger(callback, v)
        end
    end
end

function AMUnlockRatioTimer(platoon)
    local count = 0
    for _, v in platoon:GetPlatoonUnits() do
        if not v.Dead then
            count = count + 1
        end
    end
    platoon.MaxUnits = count
    platoon.LivingUnits = count
    platoon.Locked = true
    local callback = function(unit)
                         platoon.LivingUnits = platoon.LivingUnits - 1
                         if platoon.Locked and platoon.PlatoonData.Ratio > (platoon.LivingUnits / platoon.MaxUnits) then
                             ForkThread(AMPlatoonHelperFunctions.UnlockTimer, platoon.PlatoonData.LockTimer, platoon.PlatoonData.PlatoonName)
                             platoon.Locked = false
                         end
                     end
    for _, v in platoon:GetPlatoonUnits() do
        if not v.Dead then
            v.PlatoonHandle = platoon
            v:AddOnKilledCallback(callback)
            TriggerFile.CreateUnitDeathTrigger(callback, v)
        end
    end
end

function ClosestPBMLocation(aiBrain, location)
    local closest, distance
    for _, v in aiBrain.PBM.Locations do
        if not closest then
            closest = v
            distance = VDist3(location, v.Location)
        elseif VDist3(location, v.Location) < distance then
            closest = v
            distance = VDist3(location, v.Location)
        end
    end

    return closest
end

function UnitUpgradeBehavior(platoon)
    local unit = platoon:GetPlatoonUnits()[1]
    if not unit.UpgradeThread then
        if platoon.PlatoonData and not unit.CDRData then
            unit.CDRData = platoon.PlatoonData
        end
        unit.UpgradeThread = unit:ForkThread(UnitUpgradeThread)
    end
end

function UnitUpgradeThread(unit)
    local aiBrain = unit:GetAIBrain()
    local bManager = false

    if unit.CDRData.BaseName and aiBrain.BaseManagers[unit.CDRData.BaseName] then
        bManager = aiBrain.BaseManagers[unit.CDRData.BaseName]
    end

    -- Determine the type of unit
    local unitType = false
    if EntityCategoryContains(categories.COMMAND, unit) then
        unitType = 'DefaultACU'
    elseif EntityCategoryContains(categories.SUBCOMMANDER, unit) then
        unitType = 'DefaultSACU'
    end

    while not unit.Dead do
        if not bManager then
            bManager = aiBrain.BaseManagers[unit.PlatoonData.BaseName]
        end
        if bManager then
            local upgradeName = bManager:UnitNeedsUpgrade(unit, unitType)

            if upgradeName and not unit:IsUnitState('Building') then
                -- Remove the unit from the builders list
                if bManager:IsConstructionUnit(unit) then
                    bManager:RemoveConstructionEngineer(unit)
                end

                local platoon = aiBrain:MakePlatoon('', '')
                aiBrain:AssignUnitsToPlatoon(platoon, {unit}, 'support', 'none')

                local order = {
                    TaskName = "EnhanceTask",
                    Enhancement = upgradeName
                }
                IssueStop({unit})
                IssueClearCommands({unit})
                IssueScript({unit}, order)

                repeat
                    WaitSeconds(3)
                    if unit.Dead then
                        return
                    end
                until unit:IsIdleState()
                aiBrain:DisbandPlatoon(platoon)
            end
        end
        WaitSeconds(5)
    end
end
