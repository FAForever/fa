------------------------------------------------------------------------
--- File     :  /lua/ai/ScenarioPlatoonAI.lua
--- Author(s):  Drew Staltman
--- Summary  :  Houses a number of AI threads that are used in operations
--- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------

local AIBuildStructures = import("/lua/ai/aibuildstructures.lua")
local ScenarioFramework = import("/lua/scenarioframework.lua")
local StructureTemplates = import("/lua/buildingtemplates.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")

--- Retrieves all human brains that are hostile to the given army index
---@param armyIndex number Army index to check alliance with
---@return table AIBrain[]
function GetHumanEnemies(armyIndex)
    humans = {}

    for i, brain in ArmyBrains do
        if brain.BrainType == 'Human' and IsEnemy(armyIndex, brain:GetArmyIndex()) then
            table.insert(humans, brain)
        end
    end

    return humans
end

---@param platoon Platoon
function BuildOnce(platoon)
    local aiBrain = platoon:GetBrain()
    if aiBrain.HasPlatoonList then
        aiBrain:PBMSetPriority(platoon, 0)
    else
        platoon.BuilderHandle:SetPriority(0)
    end
end

---@param platoon Platoon
function DefaultOSBasePatrol(platoon)
    local aiBrain = platoon:GetBrain()
    local master = string.sub(platoon.PlatoonData.BuilderName, 11)
    local chain = false
    if platoon.PlatoonData.LocationType and Scenario.Chains[aiBrain.Name .. '_' .. platoon.PlatoonData.LocationType .. '_BasePatrolChain'] then
        chain = aiBrain.Name .. '_' .. platoon.PlatoonData.LocationType .. '_BasePatrolChain'
    elseif Scenario.Chains[master .. '_BasePatrolChain'] then
        chain = master .. '_BasePatrolChain'
    elseif Scenario.Chains[aiBrain.Name .. '_BasePatrolChain'] then
        chain = aiBrain.Name .. '_BasePatrolChain'
    end
    if chain then
        platoon.PlatoonData.PatrolChain = chain
        PatrolThread(platoon)
    end
end


--- Uses OrderName - Name of the Order from the editor & Target - Handle to Unit used in orders that require a target (OPTIONAL)
---@param platoon Platoon
---@return boolean
function PlatoonAssignOrders(platoon)
    platoon:Stop()
    local data = platoon.PlatoonData
    if not data.OrderName then
        error('*SCENARIO PLATOON AI ERROR: No OrderName given to PlatoonAssignOrders AI Function', 2)
        return false
    end
    ScenarioUtils.AssignOrders(data.OrderName, platoon, data.Target)
end

--- Attacks the closest unit the AIBrain is aware of, based on intel
---@param platoon Platoon
function PlatoonAttackClosestUnit(platoon)
    local aiBrain = platoon:GetBrain()
    local target

    while not target do
        target = platoon:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS)
        WaitSeconds(3)
    end
    platoon:Stop()

    local cmd = platoon:AggressiveMoveToLocation(target:GetPosition())
    while aiBrain:PlatoonExists(platoon) do
        if target ~= nil then
            if target.Dead or not platoon:IsCommandsActive(cmd) then
                target = platoon:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS-categories.WALL)
                if target and not target.Dead then
                    platoon:Stop()
                    cmd = platoon:AggressiveMoveToLocation(target:GetPosition())
                end
            end
        else
            target = platoon:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS)
        end
        WaitSeconds(17)
    end
end

--- Attacks the closest unit the AIBrain is aware of, based on intel
---@param platoon Platoon
function PlatoonAttackHighestThreat(platoon)
    local patrol = false
    local aiBrain = platoon:GetBrain()
    local location, threat = aiBrain:GetHighestThreatPosition(1, true)
    platoon:Stop()
    local cmd = platoon:AggressiveMoveToLocation(location)
    while aiBrain:PlatoonExists(platoon) do
        if not platoon:IsCommandsActive(cmd) then
            location, threat = aiBrain:GetHighestThreatPosition(1, true)
            if threat > 0 then
                platoon:Stop()
                cmd = platoon:AggressiveMoveToLocation(location)
            end
        end
        WaitSeconds(13)
    end
end

--- Attack moves to a specific location on the map, once arrived it will attack the highest threat
---@param platoon Platoon
function PlatoonAttackLocation(platoon)
    platoon:Stop()
    local data = platoon.PlatoonData
    if not data.Location then
        error('*SCENARIO PLATOON AI ERROR: PlatoonAttackLocation requires a Location to operate', 2)
    end
    local location = data.Location
    if type(location) == 'string' then
        location = ScenarioUtils.MarkerToPosition(location)
    end
    local aiBrain = platoon:GetBrain()
    local cmd = platoon:AggressiveMoveToLocation(location)
    local threat = 0
    while aiBrain:PlatoonExists(platoon) do
        if not platoon:IsCommandsActive(cmd) then
            location, threat = platoon:GetBrain():GetHighestThreatPosition(1, true)
            platoon:Stop()
            cmd = platoon:AggressiveMoveToLocation(location)
        end
        WaitSeconds(13)
    end
end

--- # PlatoonAttackLocationList
--- Attack moves to a location chosen from a list. Location can be the highest threat or the lowest non-negative threat.
--- After reaching location will attack next location from the list.
--- ## PlatoonData:
--- - LocationList - (REQUIRED) location on the map to attack move to
--- - LocationChain - (REQUIRED) Chain on the map to attack move to
--- - High - true will attack highest threats first, false lowest - defaults to false/lowest
---@param platoon Platoon
function PlatoonAttackLocationList(platoon)
    platoon:Stop()
    local location = nil
    local aiBrain = platoon:GetBrain()
    local data = platoon.PlatoonData
    if not data.LocationList and not data.LocationChain then
        error('*SCENARIO PLATOON AI ERROR: PlatoonAttackLocationList requires a LocationList or LocationChain in PlatoonData to operate', 2)
    end

    local positions = {}
    if data.LocationChain then
        positions = ScenarioUtils.ChainToPositions(data.LocationChain)
    else
        for _, v in data.LocationList do
            if type(v) == 'string' then
                table.insert(positions, ScenarioUtils.MarkerToPosition(v))
            else
                table.insert(positions, v)
            end
        end
    end

    if data.High then
        location = PlatoonChooseHighest(platoon:GetBrain(), positions, 1)
    else
        location = PlatoonChooseLowestNonNegative(platoon:GetBrain(), positions, 1)
    end

    local cmd
    if location then
        cmd = platoon:AggressiveMoveToLocation(location)
    end

    while aiBrain:PlatoonExists(platoon) do
        if not location or not platoon:IsCommandsActive(cmd) then
            if data.High then
                location = PlatoonChooseHighest(platoon:GetBrain(), positions, 1, location)
            else
                location = PlatoonChooseLowestNonNegative(platoon:GetBrain(), positions, 1, location)
            end
            if location then
                platoon:Stop()
                cmd = platoon:AggressiveMoveToLocation(location)
            end
        end
        WaitSeconds(13)
    end
end

--- Assigns units in platoon to TransportPool platoon for other platoons to use and moves to to specified location if specified.
--- - TransportMoveLocation - Location to move transport to before assigning to transport pool
--- - MoveRoute - List of locations to move to
--- - MoveChain - Chain of locations to move
---@param platoon Platoon
function TransportPool(platoon)
    local aiBrain = platoon:GetBrain()
    local data = platoon.PlatoonData

    -- Default transport platoon to grab from
	local poolName = 'TransportPool'
	local BaseName = data.BaseName
	
	-- If base name is specified in platoon data, use that instead
	if BaseName then 
		poolName = BaseName .. '_TransportPool'
	end
	
    local tPool = aiBrain:GetPlatoonUniquelyNamed(poolName)
	if not tPool then
        tPool = aiBrain:MakePlatoon('', '')
        tPool:UniquelyNamePlatoon(poolName)
    end
    
    if data.TransportMoveLocation then
        if type(data.TransportMoveLocation) == 'string' then
            data.MoveRoute = {ScenarioUtils.MarkerToPosition(data.TransportMoveLocation)}
        else
            data.MoveRoute = {data.TransportMoveLocation}
        end
    end

    if data.MoveChain or data.MoveRoute then
        MoveToThread(platoon)
    end

    aiBrain:AssignUnitsToPlatoon(tPool, platoon:GetPlatoonUnits(), 'Scout', 'GrowthFormation')
end

--- Grabs a specific number of transports from the transports pool and loads units into the transport. Once ready a scenario variable can be set. Can wait on another scenario variable. Attempts to land at the location with the least threat and uses the accompanying attack chain for the units that have landed.
--- - ReadyVariable   - `ScenarioInfo.VarTable[ReadyVariable]` Variable set when units are on transports
--- - WaitVariable    - `ScenarioInfo.VarTable[WaitVariable]` Variable checked before transports leave
--- - LandingList     - (REQUIRED or LandingChain) List of possible locations for transports to unload units
--- - LandingChain    - (REQUIRED or LandingList) Chain of possible landing locations
--- - TransportReturn - Location for transports to return to (they will attack with land units if this isn't set)
--- - TransportChain  - (or TransportRoute) Route to move along the transports before dropping the units.
--- - AttackPoints    - (REQUIRED or AttackChain or PatrolChain) List of locations to attack. The platoon attacks the highest threat first
--- - AttackChain     - (REQUIRED or AttackPoints or PatrolChain) Marker Chain of postitions to attack
--- - PatrolChain     - (REQUIRED or AttackChain or AttackPoints) Chain of patrolling
--- - RandomPatrol    - Bool if you want the patrol things to be random rather than in order
---@param platoon Platoon
function LandAssaultWithTransports(platoon)
    local aiBrain = platoon:GetBrain()
    local data = platoon.PlatoonData

    if not data.AttackPoints and not data.AttackChain and not data.AssaultChains then
        error('*SCENARIO PLATOON AI ERROR: LandAssaultWithTransports requires AttackPoints in PlatoonData to operate', 2)
    elseif not data.LandingList and not data.LandingChain and not data.AssaultChains then
        error('*SCENARIO PLATOON AI ERROR: LandAssaultWithTransports requires LandingList in PlatoonData to operate', 2)
    end

    -- Fix wrongly named variable from the GPG era.
    if data.MovePath then
        data.TransportChain = data.MovePath
    end

    local assaultAttackChain, assaultLandingChain
    if data.AssaultChains then
        local tempChains = {}
        local tempNum = 0
        for landingChain, attackChain in data.AssaultChains do
            for num, pos in ScenarioUtils.ChainToPositions(attackChain) do
                if aiBrain:GetThreatAtPosition(pos, 1, true) > 0 then
                    tempChains[landingChain] = attackChain
                    tempNum = tempNum + 1
                    break
                end
            end
        end
        local pickNum = Random(1, tempNum)
        tempNum = 0
        for landingChain, attackChain in tempChains do
            tempNum = tempNum + 1
            if tempNum == pickNum then
                assaultAttackChain = attackChain
                assaultLandingChain = landingChain
                break
            end
        end
    end

    -- Make attack positions out of chain, markers, or marker names
    local attackPositions = {}
    if data.AttackChain then
        attackPositions = ScenarioUtils.ChainToPositions(data.AttackChain)
    elseif assaultAttackChain then
        attackPositions = ScenarioUtils.ChainToPositions(assaultAttackChain)
    else
        for _, v in data.AttackPoints do
            if type(v) == 'string' then
                table.insert(attackPositions, ScenarioUtils.MarkerToPosition(v))
            else
                table.insert(attackPositions, v)
            end
        end
    end

    -- Make landing positions out of chain, markers, or marker names
    local landingPositions = {}
    if data.LandingChain then
        landingPositions = ScenarioUtils.ChainToPositions(data.LandingChain)
    elseif assaultLandingChain then
        landingPositions = ScenarioUtils.ChainToPositions(assaultLandingChain)
    else
        for _, v in data.LandingList do
            if type(v) == 'string' then
                table.insert(landingPositions, ScenarioUtils.MarkerToPosition(v))
            else
                table.insert(landingPositions, v)
            end
        end
    end
    platoon:Stop()

    -- Load transports
    if not GetLoadTransports(platoon) then
        return
    end

    if not ReadyWaitVariables(data) then
        return
    end

    -- Move the transports along desired route
    if data.TransportRoute then
        ScenarioFramework.PlatoonMoveRoute(platoon, data.TransportRoute)
    elseif data.TransportChain then
        ScenarioFramework.PlatoonMoveChain(platoon, data.TransportChain)
    end

    -- Find landing location and unload units at right spot
    local landingLocation = PlatoonChooseRandomNonNegative(aiBrain, landingPositions, 1)
    local cmd = platoon:UnloadAllAtLocation(landingLocation)

    -- Wait until the units are dropped
    while platoon:IsCommandsActive(cmd) do
        WaitSeconds(1)
        if not aiBrain:PlatoonExists(platoon) then
            return
        end
    end

    -- Send transports back to base if desired
    if platoon.PlatoonData.TransportReturn then
        ReturnTransportsToPool(platoon, data)
    end

    if data.PatrolChain then
        if data.RandomPatrol then
            ScenarioFramework.PlatoonPatrolRoute(platoon, GetRandomPatrolRoute(ScenarioUtils.ChainToPositions(data.PatrolChain)))
        else
            ScenarioFramework.PlatoonPatrolChain(platoon, data.PatrolChain)
        end
    else
        -- Patrol attack route by creating attack route
        local attackRoute = PlatoonChooseHighestAttackRoute(aiBrain, attackPositions, 1)
        ScenarioFramework.PlatoonPatrolRoute(platoon, attackRoute)
    end

    for num, unit in platoon:GetPlatoonUnits() do
        if EntityCategoryContains(categories.ENGINEER, unit) then
            platoon:CaptureAI()
            break
        end
    end
end

--- Platoon moves to a set of locations
--- - MoveRoute     - List of locations to move to |
--- - MoveChain     - Chain of locations to move |
--- - UseTransports - Boolean, if true, use transports to move |
---@param platoon Platoon
function MoveToThread(platoon)
    local data = platoon.PlatoonData

    if data then
        if data.MoveRoute or data.MoveChain then
            local movePositions = {}
            if data.MoveChain then
                movePositions = ScenarioUtils.ChainToPositions(data.MoveChain)
            else
                for _, v in data.MoveRoute do
                    if type(v) == 'string' then
                        table.insert(movePositions, ScenarioUtils.MarkerToPosition(v))
                    else
                        table.insert(movePositions, v)
                    end
                end
            end
            if data.UseTransports then
                for _, v in movePositions do
                    platoon:MoveToLocation(v, data.UseTransports)
                end
            else
                for _, v in movePositions do
                    platoon:MoveToLocation(v, false)
                end
            end
        else
            error('*SCENARIO PLATOON AI ERROR: MoveToRoute or MoveChain not defined', 2)
        end
    else
        error('*SCENARIO PLATOON AI ERROR: PlatoonData not defined', 2)
    end
end

--- Platoon patrols a set of locations
--- - PatrolRoute - List of locations to patrol
--- - PatrolChain - Chain of locations to patrol
---@param platoon Platoon
function PatrolThread(platoon)
    local data = platoon.PlatoonData
    platoon:Stop()
    if data then
        if data.PatrolRoute or data.PatrolChain then
            if data.PatrolChain then
                ScenarioFramework.PlatoonPatrolRoute(platoon, ScenarioUtils.ChainToPositions(data.PatrolChain))
            else
                for _, v in data.PatrolRoute do
                    if type(v) == 'string' then
                        platoon:Patrol(ScenarioUtils.MarkerToPosition(v))
                    else
                        platoon:Patrol(v)
                    end
                end
            end
        else
            error('*SCENARIO PLATOON AI ERROR: PatrolRoute or PatrolChain not defined', 2)
        end
    else
        error('*SCENARIO PLATOON AI ERROR: PlatoonData not defined', 2)
    end
end

--- Platoon patrols a random set of locations
--- - PatrolRoutes - List of locations to patrol
--- - PatrolChains - Chain of locations to patrol
---@param platoon Platoon
function RandomPatrolThread(platoon)
    local data = platoon.PlatoonData
    platoon:Stop()
    if data then
        if data.PatrolRoute or data.PatrolChain then
            if data.PatrolChain then
                ScenarioFramework.PlatoonPatrolRoute(platoon,
                                  GetRandomPatrolRoute(ScenarioUtils.ChainToPositions(data.PatrolChain)))
            else
                local route = {}
                for _, v in data.PatrolRoute do
                    if type(v) == 'string' then
                        table.insert(route, ScenarioUtils.MarkerToPosition(v))
                    else
                        table.insert(route, v)
                    end
                end
                ScenarioFramework.PlatoonPatrolRoute(platoon, GetRandomPatrolRoute(route))
            end
        else
            error('*SCENARIO PLATOON AI ERROR: PatrolRoute or PatrolChain not defined', 2)
        end
    else
        error('*SCENARIO PLATOON AI ERROR: PlatoonData not defined', 2)
    end
end

--- Gives a platoon a random patrol path from a set of locations
--- - PatrolChain - Chain of locations to patrol
---@param platoon Platoon
function RandomDefensePatrolThread(platoon)
    local data = platoon.PlatoonData
    platoon:Stop()
    if data then
        if data.PatrolChain then
            for _, v in platoon:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, GetRandomPatrolRoute(ScenarioUtils.ChainToPositions(data.PatrolChain)))
            end
        else
            error('*SCENARIO PLATOON AI ERROR: PatrolChain not defined', 2)
        end
    else
        error('*SCENARIO PLATOON AI ERROR: PlatoonData not defined', 2)
    end
end

--- Gives a platoon a random patrol path from a set of chains
--- - PatrolChains - Chains of locations to patrol
---@param platoon Platoon
function PatrolChainPickerThread(platoon)
    local data = platoon.PlatoonData
    platoon:Stop()
    if data then
        if data.PatrolChains then
            local chain = Random(1, table.getn(data.PatrolChains))
            ScenarioFramework.PlatoonPatrolRoute(platoon, ScenarioUtils.ChainToPositions(data.PatrolChains[chain]))
        else
            error('*SCENARIO PLATOON AI ERROR: PatrolChains not defined', 2)
        end
    else
        error('*SCENARIO PLATOON AI ERROR: PlatoonData not defined', 2)
    end
end

--- Gives a random patrol chain form the list to each unit of the platoon
--- - PatrolChains - List of chains to choose from
---@param platoon Platoon
function SplitPatrolThread(platoon)
    local data = platoon.PlatoonData
    platoon:Stop()
    if data then
        if data.PatrolChains then
            local num = table.getn(data.PatrolChains)
            for _, v in platoon:GetPlatoonUnits() do
                local chain = Random(1, num)
                ScenarioFramework.GroupPatrolChain({v}, data.PatrolChains[chain])
            end
        else
            error('*SCENARIO PLATOON AI ERROR: PatrolChains not defined', 2)
        end
    else
        error('*SCENARIO PLATOON AI ERROR: PlatoonData not defined', 2)
    end
end

--- The default engineer build platoon
---@param platoon Platoon
function EngineersBuildPlatoon(platoon)
    local aiBrain = platoon:GetBrain()
    local platoonUnits = platoon:GetPlatoonUnits()
    local data = platoon.PlatoonData
    local platoonName = data.PlatoonName
    local eng = false
    local engTable = {}
    local buildingPlatoon = false
    local buildingData
    local unitBeingBuilt = false
    local busy = false
    local buildingTemplate = StructureTemplates.BuildingTemplates[aiBrain:GetFactionIndex()]

    if not data.PlatoonsTable then
        error('*SCENARIO PLATOON AI ERROR: EngineersBuildPlatoon requires PlatoonsTable', 2)
    end

    -- Find all engineers in platoon
    for _, v in platoonUnits do
        if EntityCategoryContains(categories.CONSTRUCTION, v) then
            if not eng then
                eng = v
            else
                table.insert(engTable, v)
            end
        end
    end
    if not eng then
        error('*SCENARIO PLATOON AI ERROR: No Engineers found in platoon using EngineersBuildPlatoon', 2)
    end

    -- Wait for eng to stop moving
    while eng:IsUnitState('Moving') do
        WaitSeconds(3)
        if not aiBrain:PlatoonExists(platoon) then
            return
        end
    end

    -- Have all engineers guard main engineer
    if not table.empty(engTable) then
        if eng.Dead then -- Must check if a death occured since platoon was forked
            for num, unit in engTable do
                if not unit.Dead then
                    eng = table.remove(engTable, num)
                    if not table.empty(engTable) then
                        IssueGuard(engTable, eng)
                    end
                    break
                end
            end
        else
            IssueGuard(engTable, eng)
        end
    end

    if not aiBrain.EngBuiltPlatoonList then
        aiBrain.EngBuiltPlatoonList = {}
    end

    while aiBrain:PlatoonExists(platoon) do
        -- Set new primary eng
        if eng.Dead then
            return
        end
        if not buildingPlatoon then
            for _, v in data.PlatoonsTable do
                if not aiBrain.EngBuiltPlatoonList[v.PlatoonName] then
                    buildingPlatoon = v.PlatoonName
                    buildingData = v
                    break
                else
                    local plat = aiBrain.EngBuiltPlatoonList[v.PlatoonName]
                    if not aiBrain:PlatoonExists(plat) then
                        buildingPlatoon = v.PlatoonName
                        buildingData = v
                        break
                    end
                end
            end
        end
        if not eng:IsUnitState('Patrolling') and (eng:IsUnitState('Reclaiming') or eng:IsUnitState('Building') or eng:IsUnitState('Upgrading') or eng:IsUnitState('Repairing')) then
            busy = true
        end
        if not busy and buildingPlatoon then
            local newPlatoonUnits = {}
            local unitGroup = ScenarioUtils.FlattenTreeGroup(aiBrain.Name, buildingPlatoon)
            local plat
            for strName, tblData in unitGroup do
                if eng and aiBrain:CanBuildStructureAt(tblData.type, tblData.Position) then
                    IssueStop({eng})
                    IssueToUnitClearCommands(eng)
                    local result = aiBrain:BuildStructure(eng, tblData.type, {tblData.Position[1], tblData.Position[3], 0}, false)
                    unitBeingBuilt = false

                    repeat
                        WaitSeconds(5)
                        if eng.Dead then
                            eng, engTable = AssistOtherEngineer(eng, engTable, unitBeingBuilt)
                        else
                            if not unitBeingBuilt then
                                unitBeingBuilt = eng.UnitBeingBuilt
                                if unitBeingBuilt then
                                    table.insert(newPlatoonUnits, unitBeingBuilt)
                                end
                            end
                        end
                    until not eng or eng.Dead or eng:IsIdleState()
                    if not aiBrain.EngBuiltPlatoonList[buildingPlatoon] then
                        plat = aiBrain:MakePlatoon('', '')
                        aiBrain.EngBuiltPlatoonList[buildingPlatoon] = plat
                        plat.EngBuildName = buildingPlatoon
                        plat:AddDestroyCallback(function(aiBrain, plat)
                            aiBrain.EngBuiltPlatoonList[plat.EngBuildName] = false
                        end
                       )
                    end
                    aiBrain:AssignUnitsToPlatoon(aiBrain.EngBuiltPlatoonList[buildingPlatoon], {unitBeingBuilt}, 'Attack', 'NoFormation')
                end
            end
            buildingPlatoon = false
            if not table.empty(plat:GetPlatoonUnits()) then
                if buildingData.PlatoonData then
                    plat.PlatoonData = buildingData.PlatoonData
                end
                if plat.PlatoonData.AMPlatoons then
                    for _, v in plat.PlatoonData.AMPlatoons do
                        plat:SetPartOfAttackForce()
                        break
                    end
                end
                if buildingData.ScenPlatoonAI then
                    plat:ForkAIThread(import("/lua/scenarioplatoonai.lua")[buildingData.ScenPlatoonAI])
                elseif buildingData.PlatoonAI then
                    plat:ForkAIThread(import("/lua/platoon.lua")[buildingData.PlatoonAI])
                elseif buildingData.LocalFunction and buildingData.ScenName then
                    plat:ForkAIThread(import('/maps/'..buildingData.ScenName..'/'..buildingData.ScenName..'_script.lua')[LocalFunction])
                end
            end
            newPlatoonUnits = {}

            -- Disband if desired
            if aiBrain:PlatoonExists(platoon) and data.DisbandAfterBuilding then
                aiBrain:DisbandPlatoon(platoon)
            end
        end
        if not eng:IsUnitState('Patrolling') and data.PatrolChain then
            for _, v in ScenarioUtils.ChainToPositions(data.PatrolChain) do
                platoon:Patrol(v)
            end
        end
        WaitSeconds(11)
    end
end

--- Sends out units to hunt and attack Experimental Air units (Soul Ripper, Czar, etc). It cheats to find the air units.  This should *NOT* ever be used in skirmish. This platoon only seeks out PLAYER experimentals. It won't register experimentals from other AIs
--- - CategoryList - The categories we are going to find and attack
---@param platoon Platoon
function CategoryHunterPlatoonAI(platoon)
    local aiBrain = platoon:GetBrain()
    local platoonUnits = platoon:GetPlatoonUnits()
    local data = platoon.PlatoonData
    local target = false
    while aiBrain:PlatoonExists(platoon) do
        -- Find nearest enemy category to this platoon
        -- Cheat to find the focus army's units
        local newTarget = false
        local platPos = platoon:GetPlatoonPosition()
        local enemies = table.shuffle(GetHumanEnemies(aiBrain:GetArmyIndex()))
        for i, enemy in enemies do
            for catNum, category in platoon.PlatoonData.CategoryList do
                local unitList = enemy:GetListOfUnits(category, false, false)
                if not table.empty(unitList) then
                    local distance = 100000
                    for _, v in unitList do
                        if not v.Dead then
                            local currDist = VDist3(platPos, v:GetPosition())
                            if currDist < distance then
                                newTarget = v
                                distance = currDist
                            end
                        end
                    end
                    -- If the target has changed, attack new target
                    if newTarget ~= target then
                        platoon:Stop()
                        platoon:AttackTarget(newTarget)
                    end
                end
                if newTarget then
                    break
                end
            end
        end

        -- If there are no targets, seek out and fight nearest enemy the platoon can find; no cheeting here
        if not newTarget then
            target = platoon:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS-categories.WALL)
            if target and not target.Dead then
                platoon:Stop()
                platoon:AggressiveMoveToLocation(target:GetPosition())

            -- If we still cant find a target, go to the highest threat position on the map
            else
                platoon:Stop()
                local pos, threat = aiBrain:GetHighestThreatPosition(1, true)
                platoon:AggressiveMoveToLocation(pos)
            end
        end
        WaitSeconds(Random(73, 181) * .1)
    end
end

--- Upgrades / retrieves an engineer of the desired tech. Then moves the engineer to a location, possibly with a transport. Builds the specific buildings found in PlatoonData.Construction, and then maintains or patrols the base depending on what is defined.
--- | Platoon data value    | Description   |
--- | --------------------- | ------------- |
--- | ReadyVariable         | (optional) `ScenarioInfo.VarTable[ReadyVariable]` Variable set when units are on transports
--- | WaitVariable          | (optional) `ScenarioInfo.VarTable[WaitVariable]` Variable checked before transports leave
--- | LandingLocation       | (optional) Location for transports to drop engineers
--- | MoveBeacon            | (optional) TransportBeacon to use to move engineer to location
--- | Construction          | A table, see _Construction Data_ below for more information
--- | BuildBaseTemplate     | BaseTemplate of the base to build once
--- | MaintainBaseTemplate  | BaseTemplate of base to build any non-existing buildings for.
--- | AssistFactories       | Bool; will assist factories in a Location Type when set true; break off and rebuild if maintain
--- | LocationType          | Platoon base manager location type to have the engineers assist build factories in
--- | BuildingTemplate      | building template found in BaseTemplates.lua (only required if trying to build different factions buildings)
--- | PatrolRoute           | Route of locations to patrol while maintaining or after platoon disbanded
--- | PatrolChain           | Chain of locations to patrol while maintaining or after platoon disbanded
--- | TransportRoute        | List of locations for the transport to use to get to the location
--- | TransportChain        | Chain of locations for the transport to use to get to landing location
--- | DisbandAfterPatrol    | bool, if true, platoon will disband if its not maintaining a base and given a patrol order
--- | RandomPatrol          | bool, if true, platoon will sort PatrolRoute randomly
--- | UseTransports         | bool, if true, platoons will use transports to move
--- | NamedUnitBuild        | table of unit names; platoon will build these specific units and only build them once
--- | GroupBuildOnce        | name of a group to build each thing in the group only once
---
--- | Construction data value   | Description   |
--- | ------------------------- | ------------- |
--- | BuildingTemplate          | building template found in BaseTemplates.lua (only required if trying to build different factions buildings)
--- | BaseTemplate              | Name of base template to use.  This template is generated from bases made in the editor
--- | BuildClose                | Bool if you want to have unit pick closest of next building to build
--- | BuildStructures           | List of buildings to build in order, ex:T1AirFactory, T2ShieldDefense, etc
---
--- Order of events:
--- - Grab transports
--- - set ready variable
--- - wait for wait variable
--- - travel using transports
--- - travel using beacon
--- - build structures in Construction block
--- - build base using BuildBaseTemplate
--- - the platoon will assist factories if assigned to do so, they will break off and rebuild if Maintain is set
--- - maintain a base using MaintainBaseTemplate (will patrol here if PatrolRoute given)
--- - patrol using PatrolRoute, platoon can disband if given a patrol and is not maintaining a base
---@param platoon Platoon
function StartBaseEngineerThread(platoon)
    local aiBrain = platoon:GetBrain()
    local platoonUnits = platoon:GetPlatoonUnits()
    local data = platoon.PlatoonData
    local baseName
    -- Check Construction table for bad variables
    if data.Construction then
        for varName, varData in data.Construction do
            if not(varName == 'BuildingTemplate' or varName == 'BaseTemplate' or varName == 'BuildClose' or
                   varName == 'BuildStructures') then
                error('*SCENARIO PLATOON AI ERROR: StartBaseEngineerThread does not accept Construction Table variable named-'..varName, 2)
            end
        end
    end

    -- Set BaseTemplats in brain if not existing already
    if data then
        baseName = data.MaintainBaseTemplate
        if baseName then
            if not aiBrain.BaseTemplates[baseName] then
                AIBuildStructures.CreateBuildingTemplate(aiBrain, aiBrain.Name, baseName)
            end
        end
        if data.BuildBaseTemplate then
            if not aiBrain.BaseTemplates[data.BuildBaseTemplate] then
                AIBuildStructures.CreateBuildingTemplate(aiBrain, aiBrain.Name, data.BuildBaseTemplate)
            end
        end
        if data.Construction then
            if data.Construction.BaseTemplate then
                if not aiBrain.BaseTemplates[data.Construction.BaseTemplate] then
                    AIBuildStructures.CreateBuildingTemplate(aiBrain, aiBrain.Name, data.Construction.BaseTemplate)
                end
            end
        end
    end
    local eng = false
    local engTable = {}
    local cmd
    local unitBeingBuilt

    -- Find all engineers in platoon
    for _, v in platoonUnits do
        if EntityCategoryContains(categories.CONSTRUCTION, v) then
            if not eng then
                eng = v
            else
                table.insert(engTable, v)
            end
        end
    end
    if not eng then
        error('*SCENARIO PLATOON AI ERROR: No Engineers found in platoon using StartBaseEngineer', 2)
    end
    -- Wait for eng to stop moving
    while not eng.Dead and  eng:IsUnitState('Moving') do
        WaitSeconds(3)
        if not aiBrain:PlatoonExists(platoon) then
            return
        end
    end
    platoon:Stop()

    -- If platoon needs transports get em
    if data.UseTransports then
        if not GetLoadTransports(platoon) then
            return
        end
    end

    -- Set Ready and hold for Wait variable
    if not ReadyWaitVariables(data) then
        return
    end

    -- Move and unload units
    if not StartBaseTransports(platoon, data, aiBrain) then
        return
    end

    -- Have all engineers guard main engineer
    if not table.empty(engTable) then
        if eng.Dead then -- Must check if a death occured since platoon was forked
            for num, unit in engTable do
                if not unit.Dead then
                    eng = table.remove(engTable, num)
                    if not table.empty(engTable) then
                        IssueGuard(engTable, eng)
                    end
                    break
                end
            end
        else
            IssueGuard(engTable, eng)
        end
    end

    -- Construction Block building
    if not StartBaseConstruction(eng, engTable, data, aiBrain) then
        return
    end

    -- Build specific units
    if not StartBaseBuildUnits(eng, engTable, data, aiBrain) then
        return
    end

    -- Build group unit once thing
    if not StartBaseGroupOnceBuild(eng, engTable, data, aiBrain) then
        return
    end

    -- BuildBaseTemplate building
    if not StartBaseBuildBase(eng, engTable, data, aiBrain) then
        return
    end

    -- Factory assisting
    if data.LocationType and data.AssistFactories then
        ForkThread(EngineersAssistFactories, platoon, data.LocationType)
    end

    -- MaintainBaseTemplate
    if ScenarioInfo.Options.Difficulty >= (data.MaintainDiffLevel or 2) then
        if not StartBaseMaintainBase(platoon, eng, engTable, data, aiBrain) then
            return
        end
    end

    -- Send engineers on patrol
    if aiBrain:PlatoonExists(platoon) then
        EngPatrol(eng, engTable, data)
    end

    -- Disband if desired
    if aiBrain:PlatoonExists(platoon) and data.DisbandAfterPatrol then
        aiBrain:DisbandPlatoon(platoon)
    end
end


--- Utility Function
--- Gets engineers using StartBaseEngineers to their location
---@param platoon Platoon
---@param data table
---@param aiBrain AIBrain
---@return boolean
function StartBaseTransports(platoon, data, aiBrain)
    -- Move the unit using transports
    if data.UseTransports then
        if data.TransportRoute then
            for _, v in data.TransportRoute do
                if type(v) == 'string' then
                    platoon:MoveToLocation(ScenarioUtils.MarkerToPosition(v), false, 'Scout')
                else
                    platoon:MoveToLocation(v, false, 'Scout')
                end
            end
        elseif data.TransportChain then
            local transPositionChain = {}
            transPositionChain = ScenarioUtils.ChainToPositions(data.TransportChain)
            for _, v in transPositionChain do
                platoon:MoveToLocation(v, false, 'Scout')
            end
        end

        -- Unload transports
        if type(data.LandingLocation) == 'string' then
            cmd = platoon:UnloadAllAtLocation(ScenarioUtils.MarkerToPosition(data.LandingLocation))
        else
            cmd = platoon:UnloadAllAtLocation(data.LandingLocation)
        end
        -- Wait for unload to end
        while platoon:IsCommandsActive(cmd) do
            WaitSeconds(3)
            if not aiBrain:PlatoonExists(platoon) then
                return false
            end
        end
        if data.TransportReturn then
            ReturnTransportsToPool(platoon, data)
        end
    end

    -- Move unit if needed - USING FERRYS
    if data.MoveBeacon then
        while not ScenarioInfo.VarTable[data.MoveBeacon] do
            WaitSeconds(3)
            if not aiBrain:PlatoonExists(platoon) then
                return false
            end
        end
        cmd = platoon:UseFerryBeacon(categories.ALLUNITS, ScenarioInfo.VarTable[data.MoveBeacon])
        while platoon:IsCommandsActive(cmd) do
            WaitSeconds(3)
            if not aiBrain:PlatoonExists(platoon) then
                return false
            end
        end
    end

    return true
end

--- Utility Function
--- Takes transports in platoon, returns them to pool, flys them back to return location
---@param platoon Platoon
---@param data table
function ReturnTransportsToPool(platoon, data)
    -- Put transports back in TPool
    local aiBrain = platoon:GetBrain()
    local transports = platoon:GetSquadUnits('Scout')

    -- Default transport platoon to grab from
    local poolName = 'TransportPool'
    local BaseName = data.BaseName

    -- If base name is specified in platoon data, use that instead
    if BaseName then 
        poolName = BaseName .. '_TransportPool'
    end

    local tPool = aiBrain:GetPlatoonUniquelyNamed(poolName)
    if not tPool then
        tPool = aiBrain:MakePlatoon('', '')
        tPool:UniquelyNamePlatoon(poolName)
    end
    
    if table.empty(transports) then
        return
    end

    for _, unit in transports do
        aiBrain:AssignUnitsToPlatoon(tPool, {unit}, 'Scout', 'None')
    end

    -- If a route or chain was given, reverse it on return
    if data.TransportRoute then
        for i = table.getn(data.TransportRoute), 1, -1 do
            if type(data.TransportRoute[i]) == 'string' then
                IssueMove(transports, ScenarioUtils.MarkerToPosition(data.TransportRoute[i]))
            else
                IssueMove(transports, data.TransportRoute[i])
            end
        end
        -- If a route chain was given, reverse the route on return
    elseif data.TransportChain then
        local transPositionChain = ScenarioUtils.ChainToPositions(data.TransportChain)
        for i = table.getn(transPositionChain), 1, -1 do
            IssueMove(transports, transPositionChain[i])
        end
    end

    -- Return to Transport Return position
    if data.TransportReturn then
        if type(data.TransportReturn) == 'string' then
            IssueMove(transports, ScenarioUtils.MarkerToPosition(data.TransportReturn))
        else
            IssueMove(transports, data.TransportReturn)
        end
    end
end

--- Utility Function
--- Uses UnitBuild block to build specific units on the map using StartBaseEngineer
---@param eng EngineerBuilder
---@param engTable table
---@param data table
---@param aiBrain AIBrain
---@return boolean
function StartBaseBuildUnits(eng, engTable, data, aiBrain)
    local unitBeingBuilt
    local unitTable = data.NamedUnitBuild
    if unitTable then
        for num, unitName in unitTable do
            local unit = ScenarioUtils.FindUnit(unitName, Scenario.Armies[aiBrain.Name].Units)
            if unit then
                if aiBrain:CanBuildStructureAt(unit.type, unit.Position) then
                    IssueStop({eng})
                    IssueToUnitClearCommands(eng)
                    local result = aiBrain:BuildStructure(eng, unit.type, {unit.Position[1], unit.Position[3], 0}, false)
                    if result then
                        unitBeingBuilt = eng.UnitBeingBuilt
                    end
                    repeat
                        WaitSeconds(5)
                        if eng.Dead then
                            eng, engTable = AssistOtherEngineer(eng, engTable, unitBeingBuilt)
                            if not eng then
                                return false
                            end
                        else
                            if not unitBeingBuilt then
                                unitBeingBuilt = eng.UnitBeingBuilt
                            end
                            if unitBeingBuilt and data.NamedUnitBuildReportCallback then
                                data.NamedUnitBuildReportCallback(unitBeingBuilt, eng)
                            end
                        end
                    until not (eng:IsUnitState('Building') or eng:IsUnitState('Repairing') or eng:IsUnitState('Moving' or eng:IsUnitState('Reclaiming')))
                    data.NamedUnitFinishedCallback(unitBeingBuilt)
                end
            end
        end
    end
    return true
end

--- Utility Function
--- Uses GroupBuildOnce and builds each thing in said group once and only once
---@param eng EngineerManager
---@param engTable table
---@param data table
---@param aiBrain AIBrain
---@return boolean
function StartBaseGroupOnceBuild(eng, engTable, data, aiBrain)
    local unitBeingBuilt
    if data.GroupBuildOnce then
        local buildGroup = ScenarioUtils.FlattenTreeGroup(aiBrain.Name, data.GroupBuildOnce)
        if not buildGroup then
            return true
        end
        for _, v in buildGroup do
            if aiBrain:CanBuildStructureAt(v.type, v.Position) then
                IssueStop({eng})
                IssueToUnitClearCommands(eng)
                local result = aiBrain:BuildStructure(eng, v.type, {v.Position[1], v.Position[3], 0}, false)
                if result then
                    unitBeingBuilt = eng.UnitBeingBuilt
                end
                repeat
                    WaitSeconds(5)
                    if eng.Dead then
                        eng, engTable = AssistOtherEngineer(eng, engTable, unitBeingBuilt)
                        if not eng then
                            return false
                        end
                    else
                        unitBeingBuilt = eng.UnitBeingBuilt
                    end
                until eng:IsIdleState()
            end
        end
    end
    return true
end

--- Utility Function
--- Uses Construction blocks in engineers using StartBaseEngineer
---@param eng EngineerManager
---@param engTable table
---@param data table
---@param aiBrain AIBrain
---@return boolean
function StartBaseConstruction(eng, engTable, data, aiBrain)
    local cons = data.Construction
    local buildingTmpl
    if cons and cons.BuildingTemplate then
        buildingTmpl = cons.BuildingTemplate
    end
    local unitBeingBuilt
    if cons and cons.BuildStructures then
        local baseTmpl = aiBrain.BaseTemplates[cons.BaseTemplate].Template
        local closeToBuilder = nil
        if cons.BuildClose then
            closeToBuilder = eng
        end
        for _, v in cons.BuildStructures do
            if string.find(v, 'T2Air') or string.find(v, 'T3Air')
                or string.find(v, 'T2Land') or string.find(v, 'T3Land')
                or string.find(v, 'T2Naval') or string.find(v, 'T3Naval') then
                v = string.gsub(v, '2', '1')
                v = string.gsub(v, '3', '1')
            end
            EngineerBuildStructure(aiBrain, eng, v, baseTmpl, buildingTmpl)
            if eng.UnitBeingBuilt then
                unitBeingBuilt = eng.UnitBeingBuilt
            end
            repeat
                WaitSeconds(7)
                if eng.Dead then
                    eng, engTable = AssistOtherEngineer(eng, engTable, unitBeingBuilt)
                    if not eng then
                        return false
                    end
                else
                    unitBeingBuilt = eng.UnitBeingBuilt
                end
            until not (eng:IsUnitState('Building') or eng:IsUnitState('Repairing') or eng:IsUnitState('Moving') or eng:IsUnitState('Reclaiming'))
        end
    end
    return true
end

--- Utility Function
--- Builds a base using BuildBaseTemplate for engineers using StartBaseEngineer
---@param eng EngineerManager
---@param engTable table
---@param data table
---@param aiBrain AIBrain
---@return boolean
function StartBaseBuildBase(eng, engTable, data, aiBrain)
    local unitBeingBuilt
    if data.BuildBaseTemplate then
        if not aiBrain.BaseTemplates[data.BuildBaseTemplate] then
            error('*SCENARIO PLATOON AI ERROR: Invalid BaseTemplate - ' .. data.BuildBaseTemplate, 2)
        else
            local allBuilt = false
            while not allBuilt do
                local busy = false
                if not eng.Dead then
                    if eng:IsUnitState('Building') or eng:IsUnitState('Repairing')
                        or eng:IsUnitState('Reclaiming') or eng:IsUnitState('Moving') then
                            busy = true
                    end
                    if not busy then
                        if AIBuildStructures.AIMaintainBuildList(eng:GetAIBrain(), eng, data.BuildingTemplate,
                                                                 aiBrain.BaseTemplates[data.BuildBaseTemplate]) then
                            if eng.UnitBeingBuilt then
                                unitBeingBuilt = eng.UnitBeingBuilt
                            end
                            busy = true
                        else
                            allBuilt = true
                        end
                    end
                end
                WaitSeconds(5)
                if eng.Dead then
                    eng, engTable = AssistOtherEngineer(eng, engTable, unitBeingBuilt)
                    if not eng then
                        return false
                    end
                else
                    unitBeingBuilt = eng.UnitBeingBuilt
                end
            end
        end
    end
    return true
end

--- Utility Function
--- Maintains a base for engs using StartBaseEngineer
---@param platoon Platoon
---@param eng EngineerManager
---@param engTable table
---@param data table
---@param aiBrain AIBrain
---@return boolean
function StartBaseMaintainBase(platoon, eng, engTable, data, aiBrain)
    local unitBeingBuilt
    if data.MaintainBaseTemplate then
        if not aiBrain.BaseTemplates[data.MaintainBaseTemplate] then
            error('*SCENARIO PLATOON AI ERROR: Invalid basename - ' .. data.MaintainBaseTemplate, 2)
        end
    end
    if not eng and aiBrain:PlatoonExists(platoon) then
        eng, engTable = AssistOtherEngineer(eng, engTable, unitBeingBuilt)
        if not eng then
            return false
        end
    end
    while data.MaintainBaseTemplate do
        local busy = false
        if eng and not eng.Dead then
            if eng:IsUnitState('Building') or eng:IsUnitState('Reclaiming') or eng:IsUnitState('Repairing') or
                              (eng:IsUnitState('Moving') and not eng:IsUnitState('Patrolling')) then
                busy = true
            elseif data.Busy then
                data.Busy = false
                data.ReassignAssist = true
            end
            if not busy then
                if AIBuildStructures.AIMaintainBuildList(eng:GetAIBrain(), eng, data.BuildingTemplate,
                                                         aiBrain.BaseTemplates[data.MaintainBaseTemplate])then
                    busy = true
                    data.Busy = true
                    BreakOffFactoryAssist(platoon, data)
                    IssueClearCommands(engTable)
                    IssueGuard(engTable, eng)
                    unitBeingBuilt = eng.UnitBeingBuilt
                end
            end
        end
        if (data.PatrolRoute or data.PatrolChain) and not busy and not (eng:IsUnitState('Moving')
                             or eng:IsUnitState('Building')or eng:IsUnitState('Repairing')
                             or eng:IsUnitState('Patrolling') or eng:IsUnitState('Reclaiming')) then
            local patrolPositions = {}
            if data.PatrolChain then
                patrolPositions = ScenarioUtils.ChainToPositions(data.PatrolChain)
            else
                for _, v in data.PatrolRoute do
                    if type(v) == 'string' then
                        table.insert(patrolPositions, ScenarioUtils.MarkerToPosition(v))
                    else
                        table.insert(patrolPositions, v)
                    end
                end
            end
            if data.RandomPatrol then
                for num, pos in GetRandomPatrolRoute(patrolPositions) do
                    IssuePatrol({eng}, pos)
                end
            else
                for num, pos in patrolPositions do
                    IssuePatrol({eng}, pos)
                end
            end
        end
        WaitSeconds(5)
        if not aiBrain:PlatoonExists(platoon) then
            return false
        end
        if eng and eng.Dead  then
            eng, engTable = AssistOtherEngineer(eng, engTable, unitBeingBuilt)
            if not eng then
                return false
            end
        elseif eng then
            unitBeingBuilt = eng.UnitBeingBuilt
        end
    end
    return true
end

--- Utility Function
--- Sends engineers on patrol for StartBaseEngineer
---@param eng EngineerManager
---@param engTable table
---@param data table
---@return boolean
function EngPatrol(eng, engTable, data)
    table.insert(engTable, eng)
    -- Patrol an area if nothing else to do
    if data.PatrolRoute or data.PatrolChain then
        local patrolPositions = {}
        if data.PatrolChain then
            patrolPositions = ScenarioUtils.ChainToPositions(data.PatrolChain)
        else
            for _, v in data.PatrolRoute do
                if type(v) == 'string' then
                    table.insert(patrolPositions, ScenarioUtils.MarkerToPosition(v))
                else
                    table.insert(patrolPositions, v)
                end
            end
        end
        if data.RandomPatrol then
            for num, pos in GetRandomPatrolRoute(patrolPositions) do
                IssuePatrol(engTable, pos)
            end
        else
            for num, pos in patrolPositions do
                IssuePatrol(engTable, pos)
            end
        end
    end
    return true
end

--- Utility Function
--- Resets main engineer and engTablef or StartBaseEngineer
---@param eng EngineerManager
---@param engTable table
---@param unitBeingBuilt Unit
---@return EngineerManager|false
---@return table
function AssistOtherEngineer(eng, engTable, unitBeingBuilt)
    if engTable and not table.empty(engTable) then
        for num, unit in engTable do
            if not unit.Dead then
                eng = table.remove(engTable, num)
                if not table.empty(engTable) then
                    IssueGuard(engTable, eng)
                end
                if unitBeingBuilt and not unitBeingBuilt.Dead then
                    IssueRepair({eng}, unitBeingBuilt)
                end
                break
            end
        end
        if eng.Dead then
            return false
        end
    end
    return eng, engTable
end

--- Utility Function
--- Has an engineer build a certain type of structure using a base template
---@param aiBrain AIBrain
---@param builder Unit
---@param building StructureUnit
---@param brainBaseTemplate any
---@param buildingTemplate any
---@return boolean
function EngineerBuildStructure(aiBrain, builder, building, brainBaseTemplate, buildingTemplate)
    local structureCategory
    if not buildingTemplate then
        buildingTemplate = StructureTemplates.BuildingTemplates[aiBrain:GetFactionIndex()]
    end
    for _, v in buildingTemplate do
        if building == v[1] then
            structureCategory = v[2]
            break
        end
    end
    if building == 'Resource' or building == 'T1HydroCarbon' then
        for l, type in brainBaseTemplate.Template do
            if type[1][1] == building.StructureType then
                for m, location in type do
                    if m > 1 then
                        if aiBrain:CanBuildStructureAt(structureCategory, {location[1], 0, location[2]}) then
                            IssueStop({builder})
                            IssueToUnitClearCommands(builder)
                            local result = aiBrain:BuildStructure(builder, structureCategory, location, false)
                            if result then
                                return true
                            end
                        end
                    end
                end
            end
        end
    else
        if aiBrain:FindPlaceToBuild(building, structureCategory, brainBaseTemplate, false, nil) then
            IssueStop({builder})
            IssueToUnitClearCommands(builder)
            if AIBuildStructures.AIExecuteBuildStructure(aiBrain, builder, building, builder, false,
                                                         buildingTemplate, brainBaseTemplate) then
                return true
            end
        end
    end
    return false
end

--- Utility Function
--- Stops factory assisting when an eng platoon is maintaining a base
---@param platoon Platoon
---@param data table
function BreakOffFactoryAssist(platoon, data)
    local aiBrain = platoon:GetBrain()
    if platoon.PlatoonData.FactoryAssistList then
        for listFacNum, listFac in platoon.PlatoonData.FactoryAssistList do
            local num = 1
            while num <= table.getn(listFac.Engineers) do
                table.remove(listFac.Engineers, num)
                listFac.NumEngs = listFac.NumEngs - 1
                for brainFacNum, brainFacData in aiBrain.FactoryAssistList do
                    if brainFacData.Factory == listFac.Factory then
                        brainFacData.NumEngs = brainFacData.NumEngs - 1
                    end
                end
            end
        end
    end
end

--- Utility Function
--- Tell engineers to assist factories in a locationType
---@param platoon Platoon
---@param locationType string
function EngineersAssistFactories(platoon, locationType)
    locationType = locationType or platoon.PlatoonData.LocationType
    local aiBrain = platoon:GetBrain()
    local location, radius
    local needReorganize = true
    local reassignEngs = false
    local firstAssign = true
    local reassignEngPool = {}
    platoon.PlatoonData.FactoryAssistList = {}

    -- Find location out of brain
    for num, locData in aiBrain.PBM.Locations do
        if locationType == locData.LocationType then
            location = locData.Location
            radius = locData.Radius
        end
    end
    if not location then
        error('*SCENARIO PLATOON AI ERROR: No LocationType found for StartBaseEngineerThread, location named- '..repr(locationType), 2)
    end

    -- Find engineers
    local engTable = {}
    for num, unit in platoon:GetPlatoonUnits() do
        if EntityCategoryContains(categories.CONSTRUCTION, unit) then
            table.insert(engTable, unit)
            table.insert(reassignEngPool, unit)
        end
    end

    -- Main loop for assisting below

    local newFactory = false
    while aiBrain:PlatoonExists(platoon) do
        if not platoon.PlatoonData.Busy then
            -- Check for dead factories
            local num = 1
            while num <= table.getn(platoon.PlatoonData.FactoryAssistList) do
                if platoon.PlatoonData.FactoryAssistList[num].Factory.Dead then
                    reassignEngs = true
                    for engNum, eng in platoon.PlatoonData.FactoryAssistList[num].Engineers do
                        table.insert(reassignEngPool, eng)
                    end
                    table.remove(platoon.PlatoonData.FactoryAssistList, num)
                else
                    num = num + 1
                end
            end

            -- Find factories in the area belonging to proper brain
            local tempFactories = aiBrain:GetUnitsAroundPoint(categories.FACTORY, location, radius, 'Ally')
            for num, factory in tempFactories do
                if factory:GetAIBrain() == aiBrain then
                    local found = false
                    for listFacNum, listFac in platoon.PlatoonData.FactoryAssistList do
                        if listFac.Factory == factory then
                            found = true
                            break
                        end
                    end
                    if not found then
                        table.insert(platoon.PlatoonData.FactoryAssistList, {Factory = factory, Engineers = {}, NumEngs = 0 })
                        needReorganize = true
                    end
                end
            end
            -- Add factory data to brain assist list if needed, update number of engs per factory
            for num, pltnFacData in platoon.PlatoonData.FactoryAssistList do
                local found = false
                local brainFacData
                for listFacNum, listFac in aiBrain.FactoryAssistList do
                    if listFac.Factory == pltnFacData.Factory then
                        brainFacData = listFac
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(aiBrain.FactoryAssistList, {Factory = pltnFacData.Factory, NumEngs = 0})
                    pltnFacData.NumEngs = 0
                else
                    pltnFacData.NumEngs = brainFacData.NumEngs
                end
            end

            -- check for dead engineers
            local engNum = 1
            while engNum < table.getn(engTable) do
                local eng = engTable[engNum]
                if eng.Dead then
                    table.remove(engTable, engNum)
                    -- Remove from platoon factory assist list
                    for facNum, facData in platoon.PlatoonData.FactoryAssistList do
                        for facEngNum, facEngData in facData.Engineers do
                            if eng == facEngData then
                                facData.NumEngs = facData.NumEngs - 1
                                table.remove(facData.Engineers, facEngNum)
                                -- reduce number in global fac list
                                for brainFacNum, brainFacData in aiBrain.FactoryAssistList do
                                    if brainFacData.Factory == facData.Factory then
                                        brainFacData.NumEngs = brainFacData.NumEngs - 1
                                        break
                                    end
                                end
                            end
                        end
                    end
                else
                    engNum = engNum + 1
                end
            end

            -- If maintain base finished, reassign all engs
            if platoon.PlatoonData.ReassignAssist then
                for num, unit in platoon:GetPlatoonUnits() do
                    if not unit.Dead and EntityCategoryContains(categories.CONSTRUCTION, unit) then
                        table.insert(reassignEngPool, unit)
                    end
                end
            end

            -- Reassign engs if needed then reevaluate balance
            if reassignEngs or platoon.PlatoonData.ReassignAssist then
                EngAssist(platoon, reassignEngPool)
            end

            -- Check if engs needs to be reorganized on factories
            if not needReorganize then
                needReorganize = CheckFactoryAssistBalance(platoon.PlatoonData.FactoryAssistList)
            end

            -- Reassign engs if factory lost; assign all engs if needed
            if firstAssign then
                EngAssist(platoon, reassignEngPool)
            elseif needReorganize then
                ReorganizeEngineers(platoon, engTable)
            end
            -- Any leftovers?
            if not table.empty(reassignEngPool) then
                EngAssist(platoon, reassignEngPool)
            end

            -- Reset locals
            needReorganize = false
            firstAssign = false
            reassignEngs = false
            platoon.PlatoonData.ReassignAssist = false
            reassignEngPool = {}
        end
        WaitSeconds(7)
    end
end

--- Utility Function
--- Reorganizes engineer assisting if there is an imbalance
---@param platoon Platoon
---@param engTable table
function ReorganizeEngineers(platoon, engTable)
    local unbalanced = true
    local aiBrain = platoon:GetBrain()
    local loopCounter = 0
    while unbalanced and loopCounter < 20 do
        loopCounter = loopCounter + 1
        unbalanced = false
        local facLowNum = -1
        local facLowData
        local facHighNum = 0
        local facHighData
        -- Finds the high and low of engs assisting a factory
        for facNum, facData in platoon.PlatoonData.FactoryAssistList do
            if facLowNum == -1 or facData.NumEngs < facLowNum then
                facLowNum = facData.NumEngs
                facLowData = facData
            end
            if facData.NumEngs > facHighNum then
                facHighNum = facData.NumEngs
                facHighData = facData
            end
        end
        -- If difference is greater than 1 across factories: reorganize
        if (facHighNum - facLowNum) > 1 and facHighData ~= facLowData and not table.empty(facHighData.Engineers) then
            unbalanced = true
            if not table.empty(facHighData.Engineers) then
                for engNum, engData in facHighData.Engineers do
                    if not engData.Dead then
                        local moveEng = table.remove(facHighData.Engineers, engNum)
                        facHighData.NumEngs = facHighData.NumEngs - 1
                        -- Decrease number in global fac list
                        for brainFacNum, brainFacData in aiBrain.FactoryAssistList do
                            if brainFacData.Factory == facHighData.Factory then
                                brainFacData.NumEngs = brainFacData.NumEngs - 1
                                break
                            end
                        end
                        facLowData.NumEngs = facLowData.NumEngs + 1
                        -- Increment number in global fac list
                        for brainFacNum, brainFacData in aiBrain.FactoryAssistList do
                            if brainFacData.Factory == facLowData.Factory then
                                brainFacData.NumEngs = brainFacData.NumEngs + 1
                            end
                        end
                        IssueToUnitClearCommands(moveEng)
                        IssueGuard({moveEng}, facLowData.Factory)
                        break
                    end
                end
            end
        end
    end
end

--- Utility Function
--- Assign engineers to factories to assist
---@param platoon Platoon
---@param engTable table
function EngAssist(platoon, engTable)
    local aiBrain = platoon:GetBrain()
    -- Have engineers assist the factories
    local engNum = 1
    while engNum <= table.getn(engTable) do
        eng = engTable[engNum]
        if not eng.Dead and not platoon.PlatoonData.Rebuilding then
            local lowNum = -1
            local lowFac = false
            for facNum, fac in platoon.PlatoonData.FactoryAssistList do
                if lowNum == -1 or fac.NumEngs < lowNum then
                    lowFac = fac
                    lowNum = fac.NumEngs
                end
            end
            -- Store eng with correct factory, update number, have engs assist
            if lowFac then
                table.insert(lowFac.Engineers, eng)
                lowFac.NumEngs = lowFac.NumEngs + 1
                for brainNumFac, brainFacData in aiBrain.FactoryAssistList do
                    if lowFac.Factory == brainFacData.Factory then
                        brainFacData.NumEngs = brainFacData.NumEngs + 1
                        break
                    end
                end
                IssueToUnitClearCommands(eng)
                IssueGuard({eng}, lowFac.Factory)
                table.remove(engTable, engNum)
            else
                engNum = engNum + 1
            end
        else
            engNum = engNum + 1
        end
    end
end

--- Utility Function
--- Check all factories in given table to see if there is imbalance
---@param factoryTable table
---@return boolean
function CheckFactoryAssistBalance(factoryTable)
    local facLowNum = -1
    local facHighNum = 0
    for facNum, facData in factoryTable do
        if facLowNum == -1 or facData.NumEngs < facLowNum then
            facLowNum = facData.NumEngs
        end
        if facData.NumEngs > facHighNum then
            facHighNum = facData.NumEngs
        end
    end
    if facHighNum - facLowNum > 1 then
        return true
    end
    return false
end

--- Utility Function
--- Set Ready Variable and wait for Wait Variable if given
---@param data table
---@return boolean
function ReadyWaitVariables(data)
    -- Set ready and check wait variable after upgraded and/or loaded on transport
    -- Just prior to moving the unit
    if data.ReadyVariable then
        ScenarioInfo.VarTable[data.ReadyVariable] = true
    end

    if data.WaitVariable then
        while not ScenarioInfo.VarTable[data.WaitVariable] do
            WaitSeconds(5)
            if not aiBrain:PlatoonExists(platoon) then
                return false
            end
        end
    end
    return true
end

--- Utility Function
--- Get and load transports with platoon units
---@param platoon Platoon
---@return boolean
function GetLoadTransports(platoon)
    local numTransports = GetTransportsThread(platoon)
    if not numTransports then
        return false
    end

    platoon:Stop()
    local aiBrain = platoon:GetBrain()

    -- Load transports
    local transportTable = {}
    local transSlotTable = {}

    local scoutUnits = platoon:GetSquadUnits('scout') or {}

    for num, unit in scoutUnits do
        local id = unit.UnitId
        if not transSlotTable[id] then
            transSlotTable[id] = GetNumTransportSlots(unit)
        end
        table.insert(transportTable,
            {
                Transport = unit,
                LargeSlots = transSlotTable[id].Large,
                MediumSlots = transSlotTable[id].Medium,
                SmallSlots = transSlotTable[id].Small,
                Units = {}
            }
       )
    end
    local shields = {}
    local remainingSize3 = {}
    local remainingSize2 = {}
    local remainingSize1 = {}
    for num, unit in platoon:GetPlatoonUnits() do
        if EntityCategoryContains(categories.url0306 + categories.DEFENSE, unit) then
            table.insert(shields, unit)
        elseif unit:GetBlueprint().Transport.TransportClass == 3 then
            table.insert(remainingSize3, unit)
        elseif unit:GetBlueprint().Transport.TransportClass == 2 then
            table.insert(remainingSize2, unit)
        elseif unit:GetBlueprint().Transport.TransportClass == 1 then
            table.insert(remainingSize1, unit)
        elseif not EntityCategoryContains(categories.TRANSPORTATION, unit) then
            table.insert(remainingSize1, unit)
        end
    end

    local needed = GetNumTransports(platoon)
    local largeHave = 0
    for num, data in transportTable do
        largeHave = largeHave + data.LargeSlots
    end
    local leftoverUnits = {}
    local currLeftovers = {}
    local leftoverShields = {}
    transportTable, leftoverShields = SortUnitsOnTransports(transportTable, shields, largeHave - needed.Large)
    transportTable, leftoverUnits = SortUnitsOnTransports(transportTable, remainingSize3, -1)
    transportTable, currLeftovers = SortUnitsOnTransports(transportTable, leftoverShields, -1)
    for _, v in currLeftovers do table.insert(leftoverUnits, v) end
    transportTable, currLeftovers = SortUnitsOnTransports(transportTable, remainingSize2, -1)
    for _, v in currLeftovers do table.insert(leftoverUnits, v) end
    transportTable, currLeftovers = SortUnitsOnTransports(transportTable, remainingSize1, -1)
    for _, v in currLeftovers do table.insert(leftoverUnits, v) end
    transportTable, currLeftovers = SortUnitsOnTransports(transportTable, currLeftovers, -1)

    -- Self-destruct any leftovers
	for k, v in currLeftovers do
		if not v.Dead then
			v:Kill()
		end
	end
    
    -- Old load transports
    local unitsToDrop = {}
    for num, data in transportTable do
        if not table.empty(data.Units) then
            IssueClearCommands(data.Units)
            IssueTransportLoad(data.Units, data.Transport)
            for _, v in data.Units do table.insert(unitsToDrop, v) end
        end
    end

    local attached = true
    repeat
        WaitSeconds(2)
        if not aiBrain:PlatoonExists(platoon) then
            return false
        end
        attached = true
        for _, v in unitsToDrop do
            if not v.Dead and not v:IsIdleState() then
                attached = false
                break
            end
        end
    until attached

    -- We actually self-destruct any leftovers for now, usually only 1-2 units get left behind, not much of a point to create a platoon for that many.
	-- I'm keeping the code around though, in case creating a copy of the original platoon from the leftovers is feasable
		-- Any units that aren't transports and aren't attached send back to pool
    local pool
    if platoon.PlatoonData.BuilderName and platoon.PlatoonData.LocationType then
        pool = aiBrain:GetPlatoonUniquelyNamed(platoon.PlatoonData.LocationType..'_LeftoverUnits')
        if not pool then
            pool = aiBrain:MakePlatoon('', '')
            pool:UniquelyNamePlatoon(platoon.PlatoonData.LocationType..'_LeftoverUnits')
            if platoon.PlatoonData.AMPlatoons then
                pool.PlatoonData.AMPlatoons = {platoon.PlatoonData.LocationType..'_LeftoverUnits'}
                pool:SetPartOfAttackForce()
            end
        end
    else
        pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
    end

    -- For now we self-destruct any leftovers
    for _, unit in unitsToDrop do
        if not unit.Dead and not unit:IsUnitState('Attached') then
            unit:Kill()
            -- aiBrain:AssignUnitsToPlatoon(pool, {unit}, 'Unassigned', 'None')
        end
    end

    return true
end

--- Utility function
--- Sorts units onto transports distributing equally
---@generic T : table
---@param transportTable T
---@param unitTable Unit[]
---@param numSlots? number defaults to 1
---@return T transportTable
---@return Unit[] unitsLeft
function SortUnitsOnTransports(transportTable, unitTable, numSlots)
    local leftoverUnits = {}
    numSlots = numSlots or -1
    for num, unit in unitTable do
        if numSlots == -1 or num <= numSlots then
            local transSlotNum = 0
            local remainingLarge = 0
            local remainingMed = 0
            local remainingSml = 0
            for tNum, tData in transportTable do
                if tData.LargeSlots > remainingLarge then
                    transSlotNum = tNum
                    remainingLarge = tData.LargeSlots
                    remainingMed = tData.MediumSlots
                    remainingSml = tData.SmallSlots
                elseif tData.LargeSlots == remainingLarge and tData.MediumSlots > remainingMed then
                    transSlotNum = tNum
                    remainingLarge = tData.LargeSlots
                    remainingMed = tData.MediumSlots
                    remainingSml = tData.SmallSlots
                elseif tData.LargeSlots == remainingLarge and tData.MediumSlots == remainingMed and tData.SmallSlots > remainingSml then
                    transSlotNum = tNum
                    remainingLarge = tData.LargeSlots
                    remainingMed = tData.MediumSlots
                    remainingSml = tData.SmallSlots
                end
            end
            if transSlotNum > 0 then
                table.insert(transportTable[transSlotNum].Units, unit)
                if unit.Blueprint.Transport.TransportClass == 3 and remainingLarge >= 1 then
                    transportTable[transSlotNum].LargeSlots = transportTable[transSlotNum].LargeSlots - 1
                    transportTable[transSlotNum].MediumSlots = transportTable[transSlotNum].MediumSlots - 2
                    transportTable[transSlotNum].SmallSlots = transportTable[transSlotNum].SmallSlots - 4
                elseif unit.Blueprint.Transport.TransportClass == 2 and remainingMed > 0 then
                    if transportTable[transSlotNum].LargeSlots > 0 then
                        transportTable[transSlotNum].LargeSlots = transportTable[transSlotNum].LargeSlots - .5
                    end
                    transportTable[transSlotNum].MediumSlots = transportTable[transSlotNum].MediumSlots - 1
                    transportTable[transSlotNum].SmallSlots = transportTable[transSlotNum].SmallSlots - 2
                elseif unit.Blueprint.Transport.TransportClass == 1 and remainingSml > 0 then
                    transportTable[transSlotNum].SmallSlots = transportTable[transSlotNum].SmallSlots - 1
                elseif remainingSml > 0 then
                    transportTable[transSlotNum].SmallSlots = transportTable[transSlotNum].SmallSlots - 1
                else
                    table.insert(leftoverUnits, unit)
                end
            else
                table.insert(leftoverUnits, unit)
            end
        end
    end
    return transportTable, leftoverUnits
end

--- Utility function
--- Generates a random patrol route for RandomPatrolThread
---@param patrol CommandCap
---@return table
function GetRandomPatrolRoute(patrol)
    local randPatrol = {}
    local tempPatrol = {}
    for _, v in patrol do
        table.insert(tempPatrol, v)
    end

    local num = table.getn(tempPatrol)
    local rand
    for i = 1, num do
        rand = Random(1, num + 1 - i)
        table.insert(randPatrol, tempPatrol[rand])
        table.remove(tempPatrol, rand)
    end

    return randPatrol
end

--- Utility Function
--- Returns location with lowest non-negative threat
---@param aiBrain AIBrain
---@param locationList Vector[]
---@param ringSize number
---@param location Vector
---@return Vector
function PlatoonChooseLowestNonNegative(aiBrain, locationList, ringSize, location)
    local bestLocation = {}
    local bestThreat = 0
    local currThreat = 0
    local locationSet = false

    for _, v in locationList do
        currThreat = aiBrain:GetThreatAtPosition(v, ringSize, true)
        WaitSeconds(0.1)
        if not location or location ~= v then
            if (currThreat < bestThreat and currThreat > 0) or not locationSet then
                locationSet = true
                bestThreat = currThreat
                bestLocation = v
            end
        end
    end
    if not locationSet then
        bestLocation = locationList[1]
    end

    return bestLocation
end

--- Utility Function
--- Returns location with lowest threat (including negative)
---@param aiBrain AIBrain
---@param locationList Vector[]
---@param ringSize number
---@param location Vector
---@return Vector
function PlatoonChooseLowest(aiBrain, locationList, ringSize, location)
    local bestLocation = {}
    local locationSet = false
    local bestThreat = 0
    local currThreat = 0

    for _, v in locationList do
        currThreat = aiBrain:GetThreatAtPosition(v, ringSize, true)
        WaitSeconds(0.1)
        if not location or location ~= v then
            if (currThreat < bestThreat) or not locationSet then
                locationSet = true
                bestThreat = currThreat
                bestLocation = v
            end
        end
    end
    if not locationSet then
        bestLocation = locationList[1]
    end

    return bestLocation
end

--- Utility Function
--- Returns location with the highest threat
---@param aiBrain AIBrain
---@param locationList string[]
---@param ringSize number
---@param location Vector[]
---@return Vector
function PlatoonChooseHighest(aiBrain, locationList, ringSize, location)
    local bestLocation = locationList[1]
    local highestThreat = 0
    local currThreat = 0

    for _, v in locationList do
        currThreat = aiBrain:GetThreatAtPosition(v, ringSize, true)
        WaitSeconds(0.1)
        if currThreat > highestThreat and (not location or location ~= v) then
            highestThreat = currThreat
            bestLocation = v
        end
    end

    return bestLocation
end

--- Utility Function
--- Returns location randomly with threat > 0
---@param aiBrain AIBrain
---@param locationList Vector[]
---@param ringSize number
---@return Vector
function PlatoonChooseRandomNonNegative(aiBrain, locationList, ringSize)
    local landingList = {}
    for _, v in locationList do
        if aiBrain:GetThreatAtPosition(v, ringSize, true) > 0 then
            WaitSeconds(0.1)
            table.insert(landingList, v)
        end
    end
    local loc = table.random(landingList)
    if not loc then
        loc = table.random(locationList)
    end
    return loc
end

--- Utility Function
--- Arranges a route from highest to lowest based on threat
---@param aiBrain AIBrain
---@param locationList Vector[]
---@param ringSize number
---@return Vector
function PlatoonChooseHighestAttackRoute(aiBrain, locationList, ringSize)
    local attackRoute = {}
    local tempRoute = {}

    for _, v in locationList do
        table.insert(tempRoute, v)
    end

    local num = table.getn(tempRoute)
    for i = 1, num do
        table.insert(attackRoute, PlatoonChooseHighest(aiBrain, tempRoute, ringSize))
        for k, v in tempRoute do
            if attackRoute[i] == v then
                table.remove(tempRoute, k)
                break
            end
        end
    end

    return attackRoute
end

--- Utility Function
--- Arranges a route from lowest to highest on threat
---@param aiBrain AIBrain
---@param locationList Vector[]
---@param ringSize number
---@return Vector
function PlatoonChooseLowestAttackRoute(aiBrain, locationList, ringSize)
    local attackRoute = {}
    local tempRoute = {}

    for _, v in locationList do
        table.insert(tempRoute, v)
    end

    local num = table.getn(tempRoute)
    for i = 1, num do
        table.insert(attackRoute, PlatoonChooseLowestNonNegative(aiBrain, tempRoute, ringSize))
        for k, v in tempRoute do
            if attackRoute[i] == v then
                table.remove(tempRoute, k)
                break
            end
        end
    end

    return attackRoute
end

--- Utility Function
--- Function that gets the correct number of transports for a platoon
--- If BaseName platoon data is specified, grabs transports from that platoon
---@param platoon Platoon
---@return number
function GetTransportsThread(platoon)
    local data = platoon.PlatoonData
    local aiBrain = platoon:GetBrain()

    -- Default transport platoon to grab from
	local poolName = 'TransportPool'
	local BaseName = data.BaseName
	
	-- If base name is specified in platoon data, use that instead
	if BaseName then 
		poolName = BaseName .. '_TransportPool'
	end

    local neededTable = GetNumTransports(platoon)
    local numTransports = 0
    local transportsNeeded = false
    if neededTable.Small > 0 or neededTable.Medium > 0 or neededTable.Large > 0 then
        transportsNeeded = true
    end
    local transSlotTable = {}

    if transportsNeeded then
        local pool = aiBrain:GetPlatoonUniquelyNamed(poolName)
        if not pool then
            pool = aiBrain:MakePlatoon('None', 'None')
            pool:UniquelyNamePlatoon(poolName)
        end
        while transportsNeeded do
            neededTable = GetNumTransports(platoon)
            -- Make sure more are needed
            local tempNeeded = {}
            tempNeeded.Small = neededTable.Small
            tempNeeded.Medium = neededTable.Medium
            tempNeeded.Large = neededTable.Large
            -- Find out how many units are needed currently
            for _, v in platoon:GetPlatoonUnits() do
                if not v.Dead then
                    if EntityCategoryContains(categories.TRANSPORTATION, v) then
                        local id = v.UnitId
                        if not transSlotTable[id] then
                            transSlotTable[id] = GetNumTransportSlots(v)
                        end
                        local tempSlots = {}
                        tempSlots.Small = transSlotTable[id].Small
                        tempSlots.Medium = transSlotTable[id].Medium
                        tempSlots.Large = transSlotTable[id].Large
                        while tempNeeded.Large > 0 and tempSlots.Large > 0 do
                            tempNeeded.Large = tempNeeded.Large - 1
                            tempSlots.Large = tempSlots.Large - 1
                            tempSlots.Medium = tempSlots.Medium - 2
                            tempSlots.Small = tempSlots.Small - 4
                        end
                        while tempNeeded.Medium > 0 and tempSlots.Medium > 0 do
                            tempNeeded.Medium = tempNeeded.Medium - 1
                            tempSlots.Medium = tempSlots.Medium - 1
                            tempSlots.Small = tempSlots.Small - 2
                        end
                        while tempNeeded.Small > 0 and tempSlots.Small > 0 do
                            tempNeeded.Small = tempNeeded.Small - 1
                            tempSlots.Small = tempSlots.Small - 1
                        end
                        if tempNeeded.Small <= 0 and tempNeeded.Medium <= 0 and tempNeeded.Large <= 0 then
                            transportsNeeded = false
                        end
                    end
                end
            end
            if transportsNeeded then
                local location = platoon:GetPlatoonPosition()
                local transports = {}
                -- Determine distance of transports from platoon
                for _, unit in pool:GetPlatoonUnits() do
                    if EntityCategoryContains(categories.TRANSPORTATION, unit) and not unit:IsUnitState('Busy') then
                        local unitPos = unit:GetPosition()
                        local curr = {Unit=unit, Distance=VDist2(unitPos[1], unitPos[3], location[1], location[3]),
                                       Id = unit.UnitId}
                        table.insert(transports, curr)
                    end
                end
                if not table.empty(transports) then
                    local sortedList = {}
                    -- Sort distances
                    for k = 1, table.getn(transports) do
                        local lowest = -1
                        local key, value
                        for j, u in transports do
                            if lowest == -1 or u.Distance < lowest then
                                lowest = u.Distance
                                value = u
                                key = j
                            end
                        end
                        sortedList[k] = value
                        -- Remove from unsorted table
                        table.remove(transports, key)
                    end
                    -- Take transports as needed
                    for i = 1, table.getn(sortedList) do
                        if transportsNeeded then
                            local id = sortedList[i].Id
                            aiBrain:AssignUnitsToPlatoon(platoon, {sortedList[i].Unit}, 'Scout', 'GrowthFormation')
                            numTransports = numTransports + 1
                            if not transSlotTable[id] then
                                transSlotTable[id] = GetNumTransportSlots(sortedList[i].Unit)
                            end
                            local tempSlots = {}
                            tempSlots.Small = transSlotTable[id].Small
                            tempSlots.Medium = transSlotTable[id].Medium
                            tempSlots.Large = transSlotTable[id].Large
                            -- Update number of slots needed
                            while tempNeeded.Large > 0 and tempSlots.Large > 0 do
                                tempNeeded.Large = tempNeeded.Large - 1
                                tempSlots.Large = tempSlots.Large - 1
                                tempSlots.Medium = tempSlots.Medium - 2
                                tempSlots.Small = tempSlots.Small - 4
                            end
                            while tempNeeded.Medium > 0 and tempSlots.Medium > 0 do
                                tempNeeded.Medium = tempNeeded.Medium - 1
                                tempSlots.Medium = tempSlots.Medium - 1
                                tempSlots.Small = tempSlots.Small - 2
                            end
                            while tempNeeded.Small > 0 and tempSlots.Small > 0 do
                                tempNeeded.Small = tempNeeded.Small - 1
                                tempSlots.Small = tempSlots.Small - 1
                            end
                            if tempNeeded.Small <= 0 and tempNeeded.Medium <= 0 and tempNeeded.Large <= 0 then
                                transportsNeeded = false
                            end
                        end
                    end
                end
            end
            if transportsNeeded then
                WaitSeconds(7)
                if not aiBrain:PlatoonExists(platoon) then
                    return false
                end
                local unitFound = false
                for _, unit in platoon:GetPlatoonUnits() do
                    if not EntityCategoryContains(categories.TRANSPORTATION, unit) then
                        unitFound = true
                        break
                    end
                end
                if not unitFound then
                    ReturnTransportsToPool(platoon, data)
                    return false
                end
            end
        end
    end
    return numTransports
end

--- Utility Function
--- Returns the number of transports required to move the platoon
---@param platoon Platoon
---@return table
function GetNumTransports(platoon)
    local transportNeeded = {
        Small = 0,
        Medium = 0,
        Large = 0,
    }
    local transportClass
    for _, v in platoon:GetPlatoonUnits() do
        transportClass = v.Blueprint.Transport.TransportClass
        if transportClass == 1 then
            transportNeeded.Small = transportNeeded.Small + 1
        elseif transportClass == 2 then
            transportNeeded.Medium = transportNeeded.Medium + 1
        elseif transportClass == 3 then
            transportNeeded.Large = transportNeeded.Large + 1
        else
            transportNeeded.Small = transportNeeded.Small + 1
        end
    end

    return transportNeeded
end

--- Utility Function
--- Returns the number of slots the transport has available
---@param unit Unit
---@return table
function GetNumTransportSlots(unit)
    local bones = {
        Large = 0,
        Medium = 0,
        Small = 0,
    }

    -- compute count based on bones
    for i = 1, unit:GetBoneCount() do
        if unit:GetBoneName(i) ~= nil then
            if string.find(unit:GetBoneName(i), 'Attachpoint_Lrg') then
                bones.Large = bones.Large + 1
            elseif string.find(unit:GetBoneName(i), 'Attachpoint_Med') then
                bones.Medium = bones.Medium + 1
            elseif string.find(unit:GetBoneName(i), 'Attachpoint') then
                bones.Small = bones.Small + 1
            end
        end
    end

    -- retrieve number of slots set by blueprint, if it is set
    local largeSlotsByBlueprint = unit.Blueprint.Transport.SlotsLarge or bones.Large 
    local mediumSlotsByBlueprint = unit.Blueprint.Transport.SlotsMedium or bones.Medium 
    local smallSlotsByBlueprint = unit.Blueprint.Transport.SlotsSmall or bones.Small 

    -- take the minimum of the two
    bones.Large = math.min(bones.Large, largeSlotsByBlueprint)
    bones.Medium = math.min(bones.Medium, mediumSlotsByBlueprint)
    bones.Small = math.min(bones.Small, smallSlotsByBlueprint)

    return bones
end

--- Utility Function
--- NOT USED - Creates a route to something
---@param platoon Platoon
---@param squad any
function GetRouteToVector(platoon, squad)
    local aiBrain = platoon:GetBrain()
    local data = platoon.PlatoonData

    -- All vectors in the table
    aiBrain:SetUpAttackVectorsToArmy()
    local vectorTable = aiBrain:GetAttackVectors()
    local lowX = 10000
    local lowZ = 10000
    local highX = -1
    local highZ = -1
    for _, vec in vectorTable do
        if vec[1] < lowX then
            lowX = vec[1]
        end
        if vec[1] > highX then
            highX = vec[1]
        end
        if vec[3] < lowZ then
            lowZ = vec[3]
        end
        if vec[3] > highZ then
            highZ = vec[3]
        end
    end

    -- Check if route needs to be generated
    local atkVector = aiBrain:PickBestAttackVector(platoon, squad, 'Enemy', data.CompareCategory, data.CompareType)
    local pltPosition = platoon:GetSquadPosition(squad)
    local moveEW, moveNS
    if lowX > pltPosition[1] and lowX < atkVector[1] then
        moveEW = true
    elseif highX < pltPosition[1] and highX > atkVector[1] then
        moveEW = true
    end
    if lowZ > pltPosition[3] and lowZ < pltPosition[3] then
        moveNS = true
    elseif highZ < pltPosition[3] and highZ > pltPosition[3] then
        moveNS = true
    end

    -- Move vector out
    if moveEW or moveNS then
        if atkVector[4] < 0 then
            moveEW = 'west'
        elseif atkVector[4] > 0 then
            moveEW = 'east'
        end
        if atkVector[6] < 0 then
            moveNS = 'north'
        elseif atkVector[6] > 0 then
            moveNS = 'south'
        end
        local route = {}
        route[1] = {atkVector[1], atkVector[2], atkVector[3]}
        local firstPoint = false
        while not firstPoint do
            route[1][1] = route[1][1] - atkVector[4]
            route[1][3] = route[1][3] - atkVector[6]
            if route[1][1] < lowX or route[1][1] > highX then
                firstPoint = true
            elseif route[1][3] < lowZ or route[1][3] > highZ then
                firstPoint = true
            end
        end
    end
end

--- Utility Function
--- Moves a platoon along a route holding up the thread until finished
---@param platoon Platoon
---@param route any
---@return boolean
function MoveAlongRoute(platoon, route)
    local cmd = false
    local aiBrain = platoon:GetBrain()

    -- Move platoon along route
    for _, v in route do
        cmd = platoon:MoveToLocation(v, false)
    end

    -- Make sure we have a command then check if commands are finished every second
    if cmd then
        while platoon:IsCommandsActive(cmd) do
            WaitSeconds(1)
            if not aiBrain:PlatoonExists(platoon) then
                return false
            end
        end
    end
    return true
end

--- Enables Stealth on platoon's units
---@param platoon Platoon
function PlatoonEnableStealth(platoon)
    for _, unit in platoon:GetPlatoonUnits() do
        if not unit.Dead and unit:TestToggleCaps('RULEUTC_StealthToggle') then
            unit:SetScriptBit('RULEUTC_StealthToggle', false)
        end
    end
end


-- kept for mod backwards compatibility

local Utilities = import("/lua/utilities.lua")
