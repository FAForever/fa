#****************************************************************************
#**
#**  File     :  /lua/ai/ScenarioPlatoonAI.lua
#**  Author(s):  Drew Staltman
#**
#**  Summary  :  Houses a number of AI threads that are used in operations
#**
#**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local Utilities = import('/lua/utilities.lua')
local AIBuildStructures = import('/lua/ai/aibuildstructures.lua')
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local BuildingTemplates = import('/lua/BuildingTemplates.lua').BuildingTemplates
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')

####################################################################
### PlatoonAttackClosestUnit
###     - Attacks Closest Unit the AI Brain knows about
### PlatoonData -
####################################################################
##############################################################################################################
# function: PlatoonAttackClosestUnit = AddFunction	doc = "Please work function docs."
#
# parameter 0: string	platoon         = "default_platoon"
#
##############################################################################################################
function PlatoonAttackClosestUnit(platoon)
    local aiBrain = platoon:GetBrain()
    local target

    while not target do
        target = platoon:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS)
        WaitSeconds(3)
    end

    platoon:Stop()

    local cmd = platoon:AggressiveMoveToLocation( target:GetPosition() )
    while aiBrain:PlatoonExists(platoon) do
        if target ~= nil then
            if target:IsDead() or not platoon:IsCommandsActive(cmd) then
                target = platoon:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS-categories.WALL)
                if target and not target:IsDead() then
                    platoon:Stop()
                    cmd = platoon:AggressiveMoveToLocation( target:GetPosition() )
                end
            end
        else
            target = platoon:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS)
        end
        WaitSeconds(17)
    end
end

####################################################
# function: BuildOnce = AddFunction     doc = ""
#
# parameter 0: string    platoon = "default_platoon"
#
####################################################
function BuildOnce(platoon)
    local aiBrain = platoon:GetBrain()
    if aiBrain:PBMHasPlatoonList() then
        aiBrain:PBMSetPriority(platoon, 0)
    else
        platoon.BuilderHandle:SetPriority(0)
    end
end

##############################################################################################################
# function: DefaultOSBasePatrol = AddFunction   doc = "Please work function docs."
#
# parameter 0: string   platoon     = "default_platoon"
#
##############################################################################################################
function DefaultOSBasePatrol(platoon)
    local aiBrain = platoon:GetBrain()
    local master = string.sub(platoon.PlatoonData.BuilderName, 11)
    local facIndex = aiBrain:GetFactionIndex()
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

####################################################################
### PlatoonAssignOrders
###     - Assigns orders from the editor to a platoon
### PlatoonData -
###     OrderName - Name of the Order from the editor
###     Target - Handle to Unit used in orders that require a target (OPTIONAL)
####################################################################
##############################################################################################################
# function: PlatoonAssignOrders = AddFunction	doc = "Please work function docs."
#
# parameter 0: string	platoon         = "default_platoon"
#
##############################################################################################################
function PlatoonAssignOrders(platoon)
    platoon:Stop()
    local data = platoon.PlatoonData
    if not data.OrderName then
        error('*SCENARIO PLATOON AI ERROR: No OrderName given to PlatoonAssignOrders AI Function', 2)
        return false
    end
    ScenarioUtils.AssignOrders( data.OrderName, platoon, data.Target)
end

####################################################################
### PlatoonAttackHighestThreat
###     - Attacks Location on the map with the highest threat
### PlatoonData -
####################################################################
##############################################################################################################
# function: PlatoonAttackHighestThreat = AddFunction	doc = "Please work function docs."
#
# parameter 0: string	platoon         = "default_platoon"
#
##############################################################################################################
function PlatoonAttackHighestThreat(platoon)
    local patrol = false
    local aiBrain = platoon:GetBrain()
    local location,threat = aiBrain:GetHighestThreatPosition(1, true)
    platoon:Stop()
    local cmd = platoon:AggressiveMoveToLocation(location)
    while aiBrain:PlatoonExists(platoon) do
        if not platoon:IsCommandsActive(cmd) then
            location,threat = aiBrain:GetHighestThreatPosition(1, true)
            if threat > 0 then
                platoon:Stop()
                cmd = platoon:AggressiveMoveToLocation(location)
            end
        end
        WaitSeconds(13)
    end
end

####################################################################
### PlatoonAttackLocation
###     - Attack moves to a specific location on the map
###     - After reaching location will attack highest threat
### PlatoonData -
###     Location - (REQUIRED) location on the map to attack move to
####################################################################
##############################################################################################################
# function: PlatoonAttackLocation = AddFunction	doc = "Please work function docs."
#
# parameter 0: string	platoon         = "default_platoon"
#
##############################################################################################################
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

####################################################################
### PlatoonAttackLocationList
###     - Attack moves to a location chosen from a list
###     - Location can be the highest threat or the lowest non-negative threat
###     - After reaching location will attack next location from the list
### PlatoonData -
###     LocationList - (REQUIRED) location on the map to attack move to
###     LocationChain - (REQUIRED) Chain on the map to attack move to
###     High - true will attack highest threats first, false lowest - defaults to false/lowest
####################################################################
##############################################################################################################
# function: PlatoonAttackLocationList = AddFunction	doc = "Please work function docs."
#
# parameter 0: string	platoon         = "default_platoon"
#
##############################################################################################################
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
        for k,v in data.LocationList do
            if type(v) == 'string' then
                table.insert(positions, ScenarioUtils.MarkerToPosition(v))
            else
                table.insert(positions, v)
            end
        end
    end
    if data.High then
        location = PlatoonChooseHighest( platoon:GetBrain(), positions, 1)
    else
        location = PlatoonChooseLowestNonNegative( platoon:GetBrain(), positions, 1)
    end
    local cmd
    if location then
        cmd = platoon:AggressiveMoveToLocation(location)
    end
    while aiBrain:PlatoonExists(platoon) do
        if not location or not platoon:IsCommandsActive(cmd) then
            if data.High then
                location = PlatoonChooseHighest( platoon:GetBrain(), positions, 1, location )
            else
                location = PlatoonChooseLowestNonNegative( platoon:GetBrain(), positions, 1, location )
            end
            if location then
                platoon:Stop()
                cmd = platoon:AggressiveMoveToLocation(location)
            end
        end
        WaitSeconds(13)
    end
end

####################################################################
### TransportPool
###     - Moves unit to location if specified
###     - Assigns units in platoon to TransportPool platoon for other platoons to use
### PlatoonData -
###     TransportMoveLocation - Location to move transport to before assigning to transport pool
####################################################################
##############################################################################################################
# function: TransportPool = AddFunction	doc = "Please work function docs."
#
# parameter 0: string	platoon         = "default_platoon"
#
##############################################################################################################
function TransportPool(platoon)
    local aiBrain = platoon:GetBrain()
    local tPool = aiBrain:GetPlatoonUniquelyNamed('TransportPool')
    local location = false
    local data = platoon.PlatoonData
    if platoon.PlatoonData then
        if data.TransportMoveLocation then
            if type(data.TransportMoveLocation) == 'string' then
                location = ScenarioUtils.MarkerToPosition(data.TransportMoveLocation)
            else
                location = data.TransportMoveLocation
            end
        end
    end
    if not tPool then
        tPool = aiBrain:MakePlatoon( 'None', 'None' )
        tPool:UniquelyNamePlatoon('TransportPool')
    end
    for k,unit in platoon:GetPlatoonUnits() do
        aiBrain:AssignUnitsToPlatoon('TransportPool', {unit}, 'Scout', 'GrowthFormation' )
        if location then
            IssueMove( {unit}, location )
        end
    end
end

####################################################################
### LandAssaultWithTransports
###     - Grabs a specific number of transports from the TransportPool platoon
###     - Loads units onto transports
###     - Sets a ready variable if required
###     - Waits while another variable has not been set if needed
###     - Flys to lowest threat in a list of locations and unloads land units
###     - Transports return to a location and are re-added to transport pool
###     - Attacks a list of locations starting with highest threat from a list
###
### PlatoonData -
###     ReadyVariable - ScenarioInfo.VarTable[ReadyVariable] Variable set when units are on transports
###     WaitVariable - ScenarioInfo.VarTable[WaitVariable] Variable checked before transports leave
###     LandingList - (REQUIRED or LandingChain) List of possible locations for transports to unload units
###     LandingChain - (REQUIRED or LandingList) Chain of possible landing locations
###     TransportReturn - Location for transports to return to (they will attack with land units if this isn't set)
###     AttackPoints - (REQUIRED or AttackChain or PatrolChain) List of locations to attack.
###                                              The platoon attacks the highest threat first
###     AttackChain - (REQUIRED or AttackPoints or PatrolChain) Marker Chain of postitions to attack
###     PatrolChain - (REQUIRED or AttackChain or AttackPoints) Chain of patrolling
###     RandomPatrol - Bool if you want the patrol things to be random rather than in order
####################################################################
##############################################################################################################
# function: LandAssaultWithTransports = AddFunction	doc = "Please work function docs."
#
# parameter 0: string	platoon         = "default_platoon"
#
##############################################################################################################
function LandAssaultWithTransports(platoon)
    local aiBrain = platoon:GetBrain()
    local data = platoon.PlatoonData

    for varName, varData in data do
        if not(varName == 'ReadyVariable' or varName == 'WaitVariable' or varName == 'LandingList' or
               varName == 'LandingChain' or varName == 'TransportReturn' or varName == 'AttackPoints' or
               varName == 'AttackChain' or varName == 'AMPlatoons' or varName == 'PlatoonName'
               or varName == 'AMMasterPlatoon' or varName == 'UsePool' or varName == 'LocationType'
               or varName == 'BuilderName' or varName == 'LockTimer' or varName == 'DiffLockTimerD1'
               or varName == 'DiffLockTimerD2' or varName == 'DiffLockTimerD3' or varName == 'AssaultChains'
               or varName == 'Ratio' or varName == 'LockTimer' or varName == 'MovePath' or varName == 'PatrolChain'
               or varName == 'RandomPatrol' ) and varName ~= 'Categories' then
            error('*SCENARIO PLATOON AI ERROR: LandAssaultWithTransports does not accept variable named-'..varName,2)
        end
    end

    if not data.AttackPoints and not data.AttackChain and not data.AssaultChains then
        error('*SCENARIO PLATOON AI ERROR: LandAssaultWithTransports requires AttackPoints in PlatoonData to operate', 2)
    elseif not data.LandingList and not data.LandingChain and not data.AssaultChains then
        error('*SCENARIO PLATOON AI ERROR: LandAssaultWithTransports requires LandingList in PlatoonData to operate', 2)
    end

    local assaultAttackChain, assaultLandingChain
    if data.AssaultChains then
        local tempChains = {}
        local tempNum = 0
        for landingChain, attackChain in data.AssaultChains do
            for num, pos in ScenarioUtils.ChainToPositions( attackChain ) do
                if aiBrain:GetThreatAtPosition( pos, 1, true ) > 0 then
                    tempChains[landingChain] = attackChain
                    tempNum = tempNum + 1
                    break
                end
            end
        end
        local pickNum = Random(1,tempNum)
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

    # Make attack positions out of chain, markers, or marker names
    local attackPositions = {}
    if data.AttackChain then
        attackPositions = ScenarioUtils.ChainToPositions(data.AttackChain)
    elseif assaultAttackChain then
        attackPositions = ScenarioUtils.ChainToPositions(assaultAttackChain)
    else
        for k,v in data.AttackPoints do
            if type(v) == 'string' then
                table.insert(attackPositions, ScenarioUtils.MarkerToPosition(v))
            else
                table.insert(attackPositions, v)
            end
        end
    end

    # make landing positions out of chain, markers, or marker names
    local landingPositions = {}
    if data.LandingChain then
        landingPositions = ScenarioUtils.ChainToPositions(data.LandingChain)
    elseif assaultLandingChain then
        landingPositions = ScenarioUtils.ChainToPositions(assaultLandingChain)
    else
        for k,v in data.LandingList do
            if type(v) == 'string' then
                table.insert(landingPositions, ScenarioUtils.MarkerToPosition(v))
            else
                table.insert(landingPositions, v)
            end
        end
    end

    platoon:Stop()

    # Load transports
    if not GetLoadTransports(platoon) then
        return
    end

    if not ReadyWaitVariables(data) then
        return
    end

    if data.MovePath and not MoveAlongRoute(platoon, ScenarioUtils.ChainToPositions(data.MovePath)) then
        return
    end

    # Find landing location and unload units at right spot
    local landingLocation
    if ScenarioInfo.Options.Difficulty and ScenarioInfo.Options.Difficulty == 3 then
        landingLocation = PlatoonChooseRandomNonNegative(aiBrain, landingPositions, 1)
    else
        landingLocation = PlatoonChooseRandomNonNegative(aiBrain, landingPositions, 1)
    end
    cmd = platoon:UnloadAllAtLocation(landingLocation)
    local attached = true
    while attached do
        attached = false
        WaitSeconds(3)
        if not aiBrain:PlatoonExists(platoon) then
            return
        end
        for num, unit in platoon:GetPlatoonUnits() do
            if not unit:IsDead() and not EntityCategoryContains(categories.TRANSPORTATION, unit) and unit:IsUnitState('Attached') then
                attached = true
                break
            end
        end
    end

    if data.PatrolChain then
        if data.RandomPatrol then
            ScenarioFramework.PlatoonPatrolRoute( platoon, GetRandomPatrolRoute(ScenarioUtils.ChainToPositions(data.PatrolChain)))
        else
            ScenarioFramework.PlatoonPatrolChain( platoon, data.PatrolChain )
        end
    else
        # Patrol attack route by creating attack route
        local attackRoute = {}
        attackRoute = PlatoonChooseHighestAttackRoute(aiBrain, attackPositions, 1)
        # Send transports back to base if desired
        if(platoon.PlatoonData.TransportReturn) then
            ReturnTransportsToPool(platoon,data)
        end

        for k,v in attackRoute do
            platoon:Patrol(v)
        end
    end

    for num, unit in platoon:GetPlatoonUnits() do
        if EntityCategoryContains(categories.ENGINEER, unit) then
            platoon:CaptureAI()
            break
        end
    end

end


####################################################################################################################
### MoveToThread
###     - Moves to a set of locations
###
### PlatoonData
###     - MoveToRoute - List of locations to move to
###     - MoveChain - Chain of locations to move
###     - UseTransports - boolean, if true, use transports to move
###
####################################################################################################################
##############################################################################################################
# function: MoveToThread = AddFunction	doc = "Please work function docs."
#
# parameter 0: string	platoon         = "default_platoon"
#
##############################################################################################################
function MoveToThread(platoon)
    local data = platoon.PlatoonData

    if(data) then
        if(data.MoveRoute or data.MoveChain) then
            local movePositions = {}
            if data.MoveChain then
                movePositions = ScenarioUtils.ChainToPositions(data.MoveChain)
            else
                for k, v in data.MoveRoute do
                    if type(v) == 'string' then
                        table.insert(movePositions, ScenarioUtils.MarkerToPosition(v))
                    else
                        table.insert(movePositions, v)
                    end
                end
            end
            if(data.UseTransports) then
                for k, v in movePositions do
                    platoon:MoveToLocation(v, data.UseTransports)
                end
            else
                for k, v in movePositions do
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


####################################################################################################################
### PatrolThread
###     - Patrols a set of locations
###
### PlatoonData
###     - PatrolRoute - List of locations to patrol
###     - PatrolChain - Chain of locations to patrol
###
####################################################################################################################
##############################################################################################################
# function: PatrolThread = AddFunction	doc = "Please work function docs."
#
# parameter 0: string	platoon         = "default_platoon"
#
##############################################################################################################
function PatrolThread(platoon)
    local data = platoon.PlatoonData
    platoon:Stop()
    if(data) then
        if(data.PatrolRoute or data.PatrolChain) then
            if data.PatrolChain then
                ScenarioFramework.PlatoonPatrolRoute(platoon, ScenarioUtils.ChainToPositions(data.PatrolChain))
            else
                for k,v in data.PatrolRoute do
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


####################################################################################################################
### RandomPatrolThread
###     - Gives a platoon a random patrol path from a set of locations
###
### PlatoonData
###     - PatrolRoute - List of locations to patrol
###     - PatrolChain - Chain of locations to patrol
###
####################################################################################################################
##############################################################################################################
# function: RandomPatrolThread = AddFunction	doc = "Please work function docs."
#
# parameter 0: string	platoon         = "default_platoon"
#
##############################################################################################################
function RandomPatrolThread(platoon)
    local data = platoon.PlatoonData
    platoon:Stop()
    if(data) then
        if(data.PatrolRoute or data.PatrolChain) then
            if data.PatrolChain then
                ScenarioFramework.PlatoonPatrolRoute(platoon,
                                  GetRandomPatrolRoute(ScenarioUtils.ChainToPositions(data.PatrolChain)))
            else
                local route = {}
                for k,v in data.PatrolRoute do
                    if type(v) == 'string' then
                        table.insert(route, ScenarioUtils.MarkerToPosition(v))
                    else
                        table.insert(route,v)
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


####################################################################################################################
### RandomDefensePatrolThread
###     - Gives a platoon a random patrol path from a set of locations
###
### PlatoonData
###     - PatrolChain - Chain of locations to patrol
###
####################################################################################################################
##############################################################################################################
# function: RandomDefensePatrolThread = AddFunction	doc = "Please work function docs."
#
# parameter 0: string	platoon         = "default_platoon"
#
##############################################################################################################
function RandomDefensePatrolThread(platoon)
    local data = platoon.PlatoonData
    platoon:Stop()
    if(data) then
        if(data.PatrolChain) then
            for k, v in platoon:GetPlatoonUnits() do
                ScenarioFramework.GroupPatrolRoute({v}, GetRandomPatrolRoute(ScenarioUtils.ChainToPositions(data.PatrolChain)))
            end
        else
            error('*SCENARIO PLATOON AI ERROR: PatrolChain not defined', 2)
        end
    else
        error('*SCENARIO PLATOON AI ERROR: PlatoonData not defined', 2)
    end
end

####################################################################################################################
### PatrolChainPickerThread
###     - Gives a platoon a random patrol chain from a set of chains
###
### PlatoonData
###     - PatrolChains - List of chains to choose from
###
####################################################################################################################
##############################################################################################################
# function: PatrolChainPickerThread = AddFunction	doc = "Please work function docs."
#
# parameter 0: string	platoon         = "default_platoon"
#
##############################################################################################################
function PatrolChainPickerThread(platoon)
    local data = platoon.PlatoonData
    platoon:Stop()
    if(data) then
        if(data.PatrolChains) then
            local chain = Random(1, table.getn(data.PatrolChains))
            ScenarioFramework.PlatoonPatrolRoute(platoon, ScenarioUtils.ChainToPositions(data.PatrolChains[chain]))
            #LOG('Picked chain number ', chain)
        else
            error('*SCENARIO PLATOON AI ERROR: PatrolChains not defined', 2)
        end
    else
        error('*SCENARIO PLATOON AI ERROR: PlatoonData not defined', 2)
    end
end

##############################################################################################################
# function: EngineersBuildPlatoon = AddFunction	doc = "Please work function docs."
#
# parameter 0: string	platoon         = "default_platoon"
#
##############################################################################################################
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
    local buildingTemplate = BuildingTemplates[aiBrain:GetFactionIndex()]

    if not data.PlatoonsTable then
        error('*SCENARIO PLATOON AI ERROR: EngineersBuildPlatoon requires PlatoonsTable', 2)
    end

    # Find all engineers in platoon
    for k, v in platoonUnits do
        if EntityCategoryContains(categories.CONSTRUCTION, v) then
            if not eng then
                eng = v
            else
                table.insert(engTable, v)
            end
        end
    end
    if not eng then
        error('*SCENARIO PLATOON AI ERROR: No Engineers found in platoon using EngineersBuildPlatoon',2)
    end
    # Wait for eng to stop moving
    while eng:IsUnitState('Moving') do
        WaitSeconds(3)
        if not aiBrain:PlatoonExists(platoon) then
            return
        end
    end

    #=== Have all engineers guard main engineer
    if table.getn(engTable) > 0 then
        if eng:IsDead() then # Must check if a death occured since platoon was forked
            for num, unit in engTable do
                if not unit:IsDead() then
                    eng = table.remove(engTable, num)
                    if table.getn(engTable) > 0 then
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
        # Set new primary eng
        if eng:IsDead() then
            return
        end
        if not buildingPlatoon then
            for k,v in data.PlatoonsTable do
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
        if not eng:IsUnitState('Patrolling') and
            (eng:IsUnitState('Reclaiming') or eng:IsUnitState('Building') or eng:IsUnitState('Upgrading') or eng:IsUnitState('Repairing')) then
            busy = true
        end
        if not busy and buildingPlatoon then
            local newPlatoonUnits = {}
            local unitGroup = ScenarioUtils.FlattenTreeGroup( aiBrain.Name, buildingPlatoon )
            local plat
            for strName, tblData in unitGroup do
                if eng and aiBrain:CanBuildStructureAt( tblData.type, tblData.Position ) then
                    IssueStop({eng})
                    IssueClearCommands({eng})
                    local result = aiBrain:BuildStructure(eng, tblData.type, {tblData.Position[1], tblData.Position[3], 0}, false)
                    unitBeingBuilt = false

                    repeat
                        WaitSeconds(5)
                        if eng:IsDead() then
                            eng, engTable = AssistOtherEngineer(eng, engTable, unitBeingBuilt)
                        else
                            if not unitBeingBuilt then
                                unitBeingBuilt = eng:GetUnitBeingBuilt()
                                if unitBeingBuilt then
                                    table.insert( newPlatoonUnits, unitBeingBuilt )
                                end
                            end
                        end
                    until not eng or eng:IsDead() or eng:IsIdleState() #not (eng:IsUnitState('Building') or eng:IsUnitState('Repairing') or eng:IsUnitState('Moving'))
                    if not aiBrain.EngBuiltPlatoonList[buildingPlatoon] then
                        plat = aiBrain:MakePlatoon('', '')
                        aiBrain.EngBuiltPlatoonList[buildingPlatoon] = plat
                        plat.EngBuildName = buildingPlatoon
                        plat:AddDestroyCallback( function(aiBrain, plat)
                                                     aiBrain.EngBuiltPlatoonList[plat.EngBuildName] = false
                                                 end
                        )
                    end
                    aiBrain:AssignUnitsToPlatoon( aiBrain.EngBuiltPlatoonList[buildingPlatoon], {unitBeingBuilt}, 'Attack', 'NoFormation')
                end
            end
            buildingPlatoon = false
            if table.getn( plat:GetPlatoonUnits() ) > 0 then
                if buildingData.PlatoonData then
                    plat.PlatoonData = buildingData.PlatoonData
                end
                if plat.PlatoonData.AMPlatoons then
                    for k,v in plat.PlatoonData.AMPlatoons do
                        plat:SetPartOfAttackForce()
                        break
                    end
                end
                if buildingData.ScenPlatoonAI then
                    plat:ForkAIThread( import('/lua/ScenarioPlatoonAI.lua')[buildingData.ScenPlatoonAI] )
                elseif buildingData.PlatoonAI then
                    plat:ForkAIThread( import('/lua/platoon.lua')[buildingData.PlatoonAI] )
                elseif buildingData.LocalFunction and buildingData.ScenName then
                    plat:ForkAIThread( import('/maps/'..buildingData.ScenName..'/'..buildingData.ScenName..'_script.lua')[LocalFunction] )
                end
            end
            newPlatoonUnits = {}

            ### Disband if desired
            if aiBrain:PlatoonExists(platoon) and data.DisbandAfterBuilding then
                aiBrain:DisbandPlatoon(platoon)
            end
        end
        if not eng:IsUnitState('Patrolling') and data.PatrolChain then
            for k,v in ScenarioUtils.ChainToPositions( data.PatrolChain ) do
                platoon:Patrol(v)
            end
        end
        WaitSeconds(11)
    end
end


####################################################################################################################
### CategoryHunterPlatoonAI
###    -- Sends out units to hunt and attack Experimental Air units (Soul Ripper, Czar, etc)
###    -- It cheats to find the air units.  This should *NOT* ever be used in skirmish.
###    -- This platoon only seeks out PLAYER experimentals.  It will never find any other army's
###
### PlatoonData -
###    -- CategoryList : The categories we are going to find and attack
##################################################################################################################
##############################################################################################################
# function: CategoryHunterPlatoonAI = AddFunction	doc = "Please work function docs."
#
# parameter 0: string	platoon         = "default_platoon"
#
##############################################################################################################
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
        for catNum,category in platoon.PlatoonData.CategoryList do
            -- interate over all armies
            local tblArmy = ListArmies()
            for iArmy, strArmy in pairs(tblArmy) do
                if ScenarioInfo.ArmySetup[strArmy].Human then
                    local brain = GetArmyBrain(strArmy)
                    local unitList = brain:GetListOfUnits( category, false, false )
                    if table.getn(unitList) > 0 then
                        local distance = 100000
                        for k,v in unitList do
                            if not v:IsDead() then
                                local currDist = VDist3( platPos, v:GetPosition() )
                                if currDist < distance then
                                    newTarget = v
                                    distance = currDist
                                end
                            end
                        end
                        -- If the target has changed, attack new target
                        if newTarget != target then
                            platoon:Stop()
                            platoon:AttackTarget( newTarget )
                        end
                    end
                    if newTarget then
                        break
                    end
                end
            end
        end

        -- If there are no targets, seek out and fight nearest enemy the platoon can find; no cheeting here
        if not newTarget then
            target = platoon:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS-categories.WALL)
            if target and not target:IsDead() then
                platoon:Stop()
                platoon:AggressiveMoveToLocation( target:GetPosition() )

            -- If we still cant find a target, go to the highest threat position on the map
            else
                platoon:Stop()
                platoon:AggressiveMoveToLocation( aiBrain:GetHighestThreatPosition(1, true) )
            end
        end
        WaitSeconds(Random(73,181) * .1)
    end
end


####################################################################################################################
### StartBaseEngineerThread
###     - Upgrades engineer to desired tech level
###     - Moves an engineer to a location with either transports or using a transport beacon
###     - Builds specific buildings found in PlatoonData.Construction
###     - Can maintain a base found in PlatoonData
###     - Can patrol a route either while maintaining a base or just prior to disbanding back into the PoolPlatoon
###
### PlatoonData -
###     ReadyVariable - ScenarioInfo.VarTable[ReadyVariable] Variable set when units are on transports
###     WaitVariable - ScenarioInfo.VarTable[WaitVariable] Variable checked before transports leave
###     LandingLocation - Location for transports to drop engineers
###     MoveBeacon - TransportBeacon to use to move engineer to location
###     Construction - Table that holds data for a specific building order
###                  - only the buildings specified in BuildStructures be built
###         -> BuildingTemplate - building template found in BaseTemplates.lua
###                               (only required if trying to build different factions buildings )
###         -> BaseTemplate - Name of base template to use.  This template is generated from bases made in the editor
###         -> BuildClose - Bool if you want to have unit pick closest of next building to build
###         -> BuildStructures - List of buildings to build in order, ex:T1AirFactory, T2ShieldDefense, etc
###
###     BuildBaseTemplate - BaseTemplate of the base to build once
###     MaintainBaseTemplate - BaseTemplate of base to build any non-existing buildings for.
###     AssistFactories - Bool; will assist factories in a Location Type when set true; break off and rebuild if maintain
###     LocationType - PBM Location Type to have the engineers assist build factories in
###     BuildingTemplate - building template found in BaseTemplates.lua
###                        (only required if trying to build different factions buildings )
###     PatrolRoute - Route of locations to patrol while maintaining or after platoon disbanded
###     PatrolChain - Chain of locations to patrol while maintaining or after platoon disbanded
###     TransportRoute - List of locations for the transport to use to get to the location
###     TransportChain - Chain of locations for the transport to use to get to landing location
###     DisbandAfterPatrol - bool, if true, platoon will disband if its not maintaining a base and given a patrol order
###     RandomPatrol - bool, if true, platoon will sort PatrolRoute randomly
###     UseTransports - bool, if true, platoons will use transports to move
###     NamedUnitBuild - table of unit names; platoon will build these specific units and only build them once
###     GroupBuildOnce - name of a group to build each thing in the group only once
###
### Order of events:
###     Grab transports, set ready variable, wait for wait variable, travel using transports,
###         travel using beacon, build structures in Construction block, build base using BuildBaseTemplate,
###         the platoon will assist factories if assigned to do so, they will break off and rebuild if Maintain is set,
###         maintain a base using MaintainBaseTemplate (will patrol here if PatrolRoute given),
###         patrol using PatrolRoute, platoon can disband if given a patrol and is not maintaining a base
##################################################################################################################
##############################################################################################################
# function: StartBaseEngineerThread = AddFunction	doc = "Please work function docs."
#
# parameter 0: string	platoon         = "default_platoon"
#
##############################################################################################################
function StartBaseEngineerThread(platoon)
    local aiBrain = platoon:GetBrain()
    local platoonUnits = platoon:GetPlatoonUnits()
    local data = platoon.PlatoonData
    local baseName
    # Check for bad variables
    for varName, varData in data do
        if not(varName == 'ReadyVariable' or varName == 'WaitVariable' or varName == 'LandingLocation' or
               varName == 'MoveBeacon' or varName == 'Construction' or varName == 'BuildBaseTemplate' or
               varName == 'MaintainBaseTemplate' or varName == 'BuildingTemplate' or varName == 'PatrolRoute' or
               varName == 'PatrolChain'  or varName == 'TransportRoute' or varName == 'TransportChain' or
               varName == 'DisbandAfterPatrol' or varName == 'RandomPatrol' or varName == 'UseTransports' or
               varName == 'LocationType' or varName == 'AssistFactories' or varName == 'Busy' or
               varName == 'ReassignAssist' or varName == 'FactoryAssistList' or varName == 'BuilderName' or
               varName == 'NamedUnitBuild' or varName == 'LocationType' or varName == 'MaintainDiffLevel'
               or varName == 'LockTimer' or varName == 'DiffLockTimerD1' or varName == 'DiffLockTimerD2'
               or varName == 'DiffLockTimerD3' or varName == 'GroupBuildOnce' or varName == 'NamedUnitFinishedCallback'
               or varName == 'NamedUnitBuildReportCallback' ) then
            error('*SCENARIO PLATOON AI ERROR: StartBaseEngineerThread does not accept variable named-'..varName,2)
        end
    end
    # Check Construction table for bad variables
    if data.Construction then
        for varName, varData in data.Construction do
            if not(varName == 'BuildingTemplate' or varName == 'BaseTemplate' or varName == 'BuildClose' or
                   varName == 'BuildStructures' ) then
                error('*SCENARIO PLATOON AI ERROR: StartBaseEngineerThread does not accept Construction Table variable named-'..varName,2)
            end
        end
    end

    # Set BaseTemplats in brain if not existing already
    if data then
        baseName = data.MaintainBaseTemplate
        if baseName then
            if not aiBrain.BaseTemplates[baseName] then
                AIBuildStructures.CreateBuildingTemplate( aiBrain, aiBrain.Name, baseName)
            end
        end
        if data.BuildBaseTemplate then
            if not aiBrain.BaseTemplates[data.BuildBaseTemplate] then
                AIBuildStructures.CreateBuildingTemplate( aiBrain, aiBrain.Name, data.BuildBaseTemplate)
            end
        end
        if data.Construction then
            if data.Construction.BaseTemplate then
                if not aiBrain.BaseTemplates[data.Construction.BaseTemplate] then
                    AIBuildStructures.CreateBuildingTemplate( aiBrain, aiBrain.Name, data.Construction.BaseTemplate )
                end
            end
        end
    end
    local eng = false
    local engTable = {}
    local cmd
    local unitBeingBuilt

    # Find all engineers in platoon
    for k, v in platoonUnits do
        if EntityCategoryContains(categories.CONSTRUCTION, v) then
            if not eng then
                eng = v
            else
                table.insert(engTable, v)
            end
        end
    end
    if not eng then
        error('*SCENARIO PLATOON AI ERROR: No Engineers found in platoon using StartBaseEngineer',2)
    end
    # Wait for eng to stop moving
    while not eng:IsDead() and  eng:IsUnitState('Moving') do
        WaitSeconds(3)
        if not aiBrain:PlatoonExists(platoon) then
            return
        end
    end
    platoon:Stop()

    # if platoon needs transports get em
    if data.UseTransports then
        if not GetLoadTransports(platoon) then
            return
        end
    end

    # Set Ready and hold for Wait variable
    if not ReadyWaitVariables(data) then
        return
    end

    # Move and unload units
    if not StartBaseTransports(platoon, data, aiBrain) then
        return
    end

    #=== Have all engineers guard main engineer
    if table.getn(engTable) > 0 then
        if eng:IsDead() then # Must check if a death occured since platoon was forked
            for num, unit in engTable do
                if not unit:IsDead() then
                    eng = table.remove(engTable, num)
                    if table.getn(engTable) > 0 then
                        IssueGuard(engTable, eng)
                    end
                    break
                end
            end
        else
            IssueGuard(engTable, eng)
        end
    end

    # Construction Block building
    if not StartBaseConstruction(eng, engTable, data, aiBrain) then
        return
    end

    # Build specific units
    if not StartBaseBuildUnits(eng, engTable, data, aiBrain) then
        return
    end

    # Build group unit once thing
    if not StartBaseGroupOnceBuild( eng, engTable, data, aiBrain) then
        return
    end

    # BuildBaseTemplate building
    if not StartBaseBuildBase(eng, engTable, data, aiBrain) then
        return
    end

    # Factory assisting
    if data.LocationType and data.AssistFactories then
        ForkThread(EngineersAssistFactories,platoon, data.LocationType)
    end

    # MaintainBaseTemplate
    if ScenarioInfo.Options.Difficulty >= (data.MaintainDiffLevel or 2) then
        if not StartBaseMaintainBase(platoon, eng, engTable, data, aiBrain) then
            return
        end
    end

    # Send engineers on patrol
    if aiBrain:PlatoonExists(platoon) then
        EngPatrol(eng, engTable, data)
    end

    ## Disband if desired
    if aiBrain:PlatoonExists(platoon) and data.DisbandAfterPatrol then
        aiBrain:DisbandPlatoon(platoon)
    end
end



# -----------------
# UTILITY FUNCTIONS
# -----------------

# ---------------------------------------------------------
# Utility Function
# Gets engineers using StartBaseEngineers to their location
# ---------------------------------------------------------
function StartBaseTransports(platoon, data, aiBrain)
    ## Move the unit using transports
    if data.UseTransports then
        if data.TransportRoute then
            for k, v in data.TransportRoute do
                if type(v) == 'string' then
                    platoon:MoveToLocation( ScenarioUtils.MarkerToPosition(v), false, 'Scout' )
                else
                    platoon:MoveToLocation( v, false, 'Scout' )
                end
            end
        elseif data.TransportChain then
            local transPositionChain = {}
            transPositionChain = ScenarioUtils.ChainToPositions(data.TransportChain)
            for k,v in transPositionChain do
                platoon:MoveToLocation( v, false, 'Scout' )
            end
        end

        # Unload transports
        if type(data.LandingLocation) == 'string' then
            cmd = platoon:UnloadAllAtLocation( ScenarioUtils.MarkerToPosition(data.LandingLocation))
        else
            cmd = platoon:UnloadAllAtLocation( data.LandingLocation)
        end
        # Wait for unload to end
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

    #### Move unit if needed - USING FERRYS
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


# ------------------------------------------------------------------------------------
# Utility Function
# Takes transports in platoon, returns them to pool, flys them back to return location
# ------------------------------------------------------------------------------------
function ReturnTransportsToPool(platoon, data)
    # Put transports back in TPool
    local aiBrain = platoon:GetBrain()
    for k,unit in platoon:GetPlatoonUnits() do
        if EntityCategoryContains( categories.TRANSPORTATION, unit ) then
            # If a route was given, reverse the route on return
            if data.TransportRoute then
                aiBrain:AssignUnitsToPlatoon( 'TransportPool', {unit}, 'Scout', 'None' )
                for i=table.getn(data.TransportRoute),1,-1 do
                    if type(data.TransportRoute[1]) == 'string' then
                        IssueMove( {unit}, ScenarioUtils.MarkerToPosition(data.TransportRoute[i]) )
                    else
                        IssueMove( {unit}, data.TransportRoute[i])
                    end
                end
                if data.TransportReturn then
                    if type(data.TransportReturn) == 'string' then
                        IssueMove( {unit}, ScenarioUtils.MarkerToPosition(data.TransportReturn) )
                    else
                        IssueMove( {unit}, data.TransportReturn)
                    end
                end
                # If a route chain was given, reverse the route on return
            elseif data.TransportChain then
                local transPositionChain = {}
                transPositionChain = ScenarioUtils.ChainToPositions(data.TransportChain)
                aiBrain:AssignUnitsToPlatoon( 'TransportPool', {unit}, 'Scout', 'None' )
                for i=table.getn(transPositionChain),1,-1 do
                    IssueMove( {unit}, transPositionChain[i] )
                end
                if data.TransportReturn then
                    if type(data.TransportReturn) == 'string' then
                        IssueMove( {unit}, ScenarioUtils.MarkerToPosition(data.TransportReturn) )
                    else
                        IssueMove( {unit}, data.TransportReturn)
                    end
                end
                # return to Transport Return if no route
            else
                if data.TransportReturn then
                    aiBrain:AssignUnitsToPlatoon( 'TransportPool', {unit}, 'Scout', 'None' )
                    if type(data.TransportReturn) == 'string' then
                        IssueMove( {unit}, ScenarioUtils.MarkerToPosition(data.TransportReturn) )
                    else
                        IssueMove( {unit}, data.TransportReturn)
                    end
                end
            end
        end
    end
end

# -------------------------------------------------------------------------------
# Utility Function
# Uses UnitBuild block to build specific units on the map using StartBaseEngineer
# -------------------------------------------------------------------------------
function StartBaseBuildUnits(eng, engTable, data, aiBrain)
    local unitBeingBuilt
    local unitTable = data.NamedUnitBuild
    if unitTable then
        for num, unitName in unitTable do
            local unit = ScenarioUtils.FindUnit(unitName, Scenario.Armies[aiBrain.Name].Units)
            if unit then
                if aiBrain:CanBuildStructureAt(unit.type, unit.Position) then
                    IssueStop({eng})
                    IssueClearCommands({eng})
                    local result = aiBrain:BuildStructure(eng, unit.type, {unit.Position[1], unit.Position[3], 0}, false)
                    if result then
                        unitBeingBuilt = eng:GetUnitBeingBuilt()
                    end
                    repeat
                        WaitSeconds(5)
                        if eng:IsDead() then
                            eng, engTable = AssistOtherEngineer(eng, engTable, unitBeingBuilt)
                            if not eng then
                                return false
                            end
                        else
                            if not unitBeingBuilt then
                                unitBeingBuilt = eng:GetUnitBeingBuilt()
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

# --------------------------------------------------------------------------
# Utility Function
# Uses GroupBuildOnce and builds each thing in said group once and only once
# --------------------------------------------------------------------------
function StartBaseGroupOnceBuild( eng, engTable, data, aiBrain)
    local unitBeingBuilt
    if data.GroupBuildOnce then
        local buildGroup = ScenarioUtils.FlattenTreeGroup( aiBrain.Name, data.GroupBuildOnce )
        if not buildGroup then
            return true
        end
        for k,v in buildGroup do
            if aiBrain:CanBuildStructureAt( v.type, v.Position ) then
                IssueStop({eng})
                IssueClearCommands({eng})
                local result = aiBrain:BuildStructure( eng, v.type, { v.Position[1], v.Position[3], 0}, false)
                if result then
                    unitBeingBuilt = eng:GetUnitBeingBuilt()
                end
                repeat
                    WaitSeconds(5)
                    if eng:IsDead() then
                        eng, engTable = AssistOtherEngineer(eng, engTable, unitBeingBuilt)
                        if not eng then
                            return false
                        end
                    else
                        unitBeingBuilt = eng:GetUnitBeingBuilt()
                    end
                until eng:IsIdleState()
            end
        end
    end
    return true
end


# -------------------------------------------------------------
# Utility Function
# Uses Construction blocks in engineers using StartBaseEngineer
# -------------------------------------------------------------
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
        for k, v in cons.BuildStructures do
            if(string.find(v, 'T2Air') or string.find(v, 'T3Air')
                or string.find(v, 'T2Land') or string.find(v, 'T3Land')
                or string.find(v, 'T2Naval') or string.find(v, 'T3Naval')) then
                v = string.gsub(v, '2', '1')
                v = string.gsub(v, '3', '1')
            end
            #platoon:Stop()
            EngineerBuildStructure(aiBrain, eng, v, baseTmpl, buildingTmpl )
            if eng:GetUnitBeingBuilt() then
                unitBeingBuilt = eng:GetUnitBeingBuilt()
            end
            repeat
                WaitSeconds(7)
                if eng:IsDead() then
                    eng, engTable = AssistOtherEngineer(eng, engTable, unitBeingBuilt)
                    if not eng then
                        return false
                    end
                else
                    unitBeingBuilt = eng:GetUnitBeingBuilt()
                end
            until not ( eng:IsUnitState('Building') or eng:IsUnitState('Repairing') or eng:IsUnitState('Moving') or eng:IsUnitState('Reclaiming') )
        end
    end
    return true
end


# ---------------------------------------------------------------------------
# Utility Function
# Builds a base using BuildBaseTemplate for engineers using StartBaseEngineer
# ---------------------------------------------------------------------------
function StartBaseBuildBase(eng, engTable, data, aiBrain)
    local unitBeingBuilt
    if data.BuildBaseTemplate then
        if not aiBrain.BaseTemplates[data.BuildBaseTemplate] then
            error('*SCENARIO PLATOON AI ERROR: Invalid BaseTemplate - ' .. data.BuildBaseTemplate, 2)
        else
            local allBuilt = false
            while not allBuilt do
                local busy = false
                if not eng:IsDead() then
                    if eng:IsUnitState('Building') or eng:IsUnitState('Repairing')
                        or eng:IsUnitState('Reclaiming') or eng:IsUnitState('Moving') then
                            busy = true
                    end
                    if not busy then
                        if AIBuildStructures.AIMaintainBuildList(eng:GetAIBrain(), eng, data.BuildingTemplate,
                                                                 aiBrain.BaseTemplates[data.BuildBaseTemplate]) then
                            if eng:GetUnitBeingBuilt() then
                                unitBeingBuilt = eng:GetUnitBeingBuilt()
                            end
                            busy = true
                        else
                            allBuilt = true
                        end
                    end
                end
                WaitSeconds(5)
                if eng:IsDead() then
                    eng, engTable = AssistOtherEngineer(eng, engTable, unitBeingBuilt)
                    if not eng then
                        return false
                    end
                else
                    unitBeingBuilt = eng:GetUnitBeingBuilt()
                end
            end
        end
    end
    return true
end


# -------------------------------------------------
# Utility Function
# Maintains a base for engs using StartBaseEngineer
# -------------------------------------------------
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
        if eng and not eng:IsDead() then
            if eng:IsUnitState('Building') or eng:IsUnitState('Reclaiming') or eng:IsUnitState('Repairing') or
                              (eng:IsUnitState('Moving') and not eng:IsUnitState('Patrolling')) then
                busy = true
            elseif data.Busy then
                data.Busy = false
                data.ReassignAssist = true
            end
            if not busy then
                if AIBuildStructures.AIMaintainBuildList(eng:GetAIBrain(), eng, data.BuildingTemplate,
                                                         aiBrain.BaseTemplates[data.MaintainBaseTemplate] )then
                    busy = true
                    data.Busy = true
                    BreakOffFactoryAssist(platoon, data)
                    IssueClearCommands(engTable)
                    IssueGuard(engTable, eng)
                    unitBeingBuilt = eng:GetUnitBeingBuilt()
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
                for k,v in data.PatrolRoute do
                    if type(v) == 'string' then
                        table.insert(patrolPositions, ScenarioUtils.MarkerToPosition(v))
                    else
                        table.insert(patrolPositions, v)
                    end
                end
            end
            if(data.RandomPatrol) then
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
        if eng and eng:IsDead()  then
            eng, engTable = AssistOtherEngineer(eng, engTable, unitBeingBuilt)
            if not eng then
                return false
            end
        elseif eng then
            unitBeingBuilt = eng:GetUnitBeingBuilt()
        end
    end
    return true
end


# -----------------------------------------------
# Utility Function
# Sends engineers on patrol for StartBaseEngineer
# -----------------------------------------------
function EngPatrol(eng, engTable, data)
    table.insert(engTable, eng)
    ## Patrol an area if nothing else to do
    if data.PatrolRoute or data.PatrolChain then
        local patrolPositions = {}
        if data.PatrolChain then
            patrolPositions = ScenarioUtils.ChainToPositions(data.PatrolChain)
        else
            for k,v in data.PatrolRoute do
                if type(v) == 'string' then
                    table.insert(patrolPositions, ScenarioUtils.MarkerToPosition(v))
                else
                    table.insert(patrolPositions, v)
                end
            end
        end
        if(data.RandomPatrol) then
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

# -------------------------------------------------------
# Utility Function
# Resets main engineer and engTablef or StartBaseEngineer
# -------------------------------------------------------
function AssistOtherEngineer(eng, engTable, unitBeingBuilt)
    if engTable and table.getn(engTable) > 0 then
        for num, unit in engTable do
            if not unit:IsDead() then
                eng = table.remove(engTable, num)
                if table.getn(engTable) > 0 then
                    IssueGuard(engTable, eng)
                end
                if unitBeingBuilt and not unitBeingBuilt:IsDead() then
                    IssueRepair({eng}, unitBeingBuilt)
                end
                break
            end
        end
        if eng:IsDead() then
            return false
        end
    end
    return eng, engTable
end


# -----------------------------------------------------------------------
# Utility Function
# Has an engineer build a certain type of structure using a base template
# -----------------------------------------------------------------------
function EngineerBuildStructure(aiBrain, builder, building, brainBaseTemplate, buildingTemplate)
    local structureCategory
    if not buildingTemplate then
        buildingTemplate = BuildingTemplates[aiBrain:GetFactionIndex()]
    end
    for k,v in buildingTemplate do
        if building == v[1] then
            structureCategory = v[2]
            break
        end
    end
    if building == 'Resource' or building == 'T1HydroCarbon' then
        for l,type in brainBaseTemplate.Template do
            if type[1][1] == building.StructureType then
                for m,location in type do
                    if m > 1 then
                        if aiBrain:CanBuildStructureAt(structureCategory, {location[1], 0, location[2]}) then
                            IssueStop({builder})
                            IssueClearCommands({builder})
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
        if aiBrain:FindPlaceToBuild( building, structureCategory, brainBaseTemplate, false, nil ) then
            IssueStop({builder})
            IssueClearCommands({builder})
            if AIBuildStructures.AIExecuteBuildStructure(aiBrain, builder, building, builder, false,
                                                         buildingTemplate, brainBaseTemplate) then
                return true
            end
        end
    end
    return false
end

# -----------------------------------------------------------------
# Utility Function
# Stops factory assisting when an eng platoon is maintaining a base
# -----------------------------------------------------------------
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


# ----------------------------------------------------
# Utility Function
# Tell engineers to assist factories in a locationType
# ----------------------------------------------------
function EngineersAssistFactories(platoon, locationType)
    locationType = locationType or platoon.PlatoonData.LocationType
    local aiBrain = platoon:GetBrain()
    local location, radius
    local needReorganize = true
    local reassignEngs = false
    local firstAssign = true
    local reassignEngPool = {}
    platoon.PlatoonData.FactoryAssistList = {}

    # Find location out of brain
    for num,locData in aiBrain.PBM.Locations do
        if locationType == locData.LocationType then
            location = locData.Location
            radius = locData.Radius
        end
    end
    if not location then
        error('*SCENARIO PLATOON AI ERROR: No LocationType found for StartBaseEngineerThread, location named- '..repr(locationType),2)
    end

    # Find engineers
    local engTable = {}
    for num,unit in platoon:GetPlatoonUnits() do
        if EntityCategoryContains(categories.CONSTRUCTION, unit) then
            table.insert(engTable, unit)
            table.insert(reassignEngPool,unit)
        end
    end

    #### Main loop for assisting below

    local newFactory = false
    while aiBrain:PlatoonExists(platoon) do
        if not platoon.PlatoonData.Busy then
            # check for dead factories
            local num = 1
            while num <= table.getn(platoon.PlatoonData.FactoryAssistList) do
                if platoon.PlatoonData.FactoryAssistList[num].Factory:IsDead() then
                    reassignEngs = true
                    for engNum, eng in platoon.PlatoonData.FactoryAssistList[num].Engineers do
                        table.insert(reassignEngPool, eng)
                    end
                    table.remove(platoon.PlatoonData.FactoryAssistList, num)
                else
                    num = num + 1
                end
            end

            # Find factories in the area belonging to proper brain
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
            # Add factory data to brain assist list if needed, update number of engs per factory
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
                    table.insert(aiBrain.FactoryAssistList, { Factory = pltnFacData.Factory, NumEngs = 0, })
                    pltnFacData.NumEngs = 0
                else
                    pltnFacData.NumEngs = brainFacData.NumEngs
                end
            end

            # check for dead engineers
            local engNum = 1
            while engNum < table.getn(engTable) do
                local eng = engTable[engNum]
                if eng:IsDead() then
                    table.remove(engTable, engNum)
                    # Remove from platoon factory assist list
                    for facNum, facData in platoon.PlatoonData.FactoryAssistList do
                        for facEngNum, facEngData in facData.Engineers do
                            if eng == facEngData then
                                facData.NumEngs = facData.NumEngs - 1
                                table.remove(facData.Engineers, facEngNum)
                                # reduce number in global fac list
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

            # if maintain base finished, reassign all engs
            if platoon.PlatoonData.ReassignAssist then
                for num,unit in platoon:GetPlatoonUnits() do
                    if not unit:IsDead() and EntityCategoryContains(categories.CONSTRUCTION, unit) then
                        table.insert(reassignEngPool,unit)
                    end
                end
            end

            # Reassign engs if needed then reevaluate balance
            if reassignEngs or platoon.PlatoonData.ReassignAssist then
                EngAssist(platoon, reassignEngPool)
            end

            # Check if engs needs to be reorganized on factories
            if not needReorganize then
                needReorganize = CheckFactoryAssistBalance(platoon.PlatoonData.FactoryAssistList)
            end

            # reassign engs if factory lost; assign all engs if needed
            if firstAssign then
                EngAssist(platoon, reassignEngPool)
            elseif needReorganize then
                ReorganizeEngineers(platoon, engTable)
            end
            # any leftovers?
            if table.getn(reassignEngPool) > 0 then
                EngAssist(platoon, reassignEngPool)
            end

            # reset locals
            needReorganize = false
            firstAssign = false
            reassignEngs = false
            platoon.PlatoonData.ReassignAssist = false
            reassignEngPool = {}
        end
        WaitSeconds(7)
    end
end


# -------------------------------------------------------
# Utility Function
# Reorganizes engineer assisting if there is an imbalance
# -------------------------------------------------------
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
        # Finds the high and low of engs assisting a factory
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
        # If difference is greater than 1 across factories: reorganize
        if (facHighNum - facLowNum) > 1 and facHighData ~= facLowData and table.getn(facHighData.Engineers) > 0 then
            unbalanced = true
            if table.getn(facHighData.Engineers) > 0 then
                for engNum, engData in facHighData.Engineers do
                    if not engData:IsDead() then
                        local moveEng = table.remove(facHighData.Engineers, engNum)
                        facHighData.NumEngs = facHighData.NumEngs - 1
                        # decrease number in global fac list
                        for brainFacNum, brainFacData in aiBrain.FactoryAssistList do
                            if brainFacData.Factory == facHighData.Factory then
                                brainFacData.NumEngs = brainFacData.NumEngs - 1
                                break
                            end
                        end
                        facLowData.NumEngs = facLowData.NumEngs + 1
                        # increment number in global fac list
                        for brainFacNum, brainFacData in aiBrain.FactoryAssistList do
                            if brainFacData.Factory == facLowData.Factory then
                                brainFacData.NumEngs = brainFacData.NumEngs + 1
                            end
                        end
                        IssueClearCommands({moveEng})
                        IssueGuard({moveEng}, facLowData.Factory)
                        break
                    end
                end
            end
        end
    end
end


# ---------------------------------------
# Utility Function
# Assign engineers to factories to assist
# ---------------------------------------
function EngAssist(platoon, engTable)
    local aiBrain = platoon:GetBrain()
    # Have engineers assist the factories
    local engNum = 1
    while engNum <= table.getn(engTable) do
        eng = engTable[engNum]
        if not eng:IsDead() and not platoon.PlatoonData.Rebuilding then
            local lowNum = -1
            local lowFac = false
            for facNum, fac in platoon.PlatoonData.FactoryAssistList do
                if lowNum == -1 or fac.NumEngs < lowNum then
                    lowFac = fac
                    lowNum = fac.NumEngs
                end
            end
            # Store eng with correct factory, update number, have engs assist
            if lowFac then
                table.insert(lowFac.Engineers, eng)
                lowFac.NumEngs = lowFac.NumEngs + 1
                for brainNumFac, brainFacData in aiBrain.FactoryAssistList do
                    if lowFac.Factory == brainFacData.Factory then
                        brainFacData.NumEngs = brainFacData.NumEngs + 1
                        break
                    end
                end
                IssueClearCommands({eng})
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


# ---------------------------------------------------------------
# Utility Function
# Check all factories in given table to see if there is imbalance
# ---------------------------------------------------------------
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
    if (facHighNum - facLowNum) > 1 then
        return true
    end
    return false
end


# ------------------------------------------------------
# Utility Function
# Set Ready Variable and wait for Wait Variable if given
# ------------------------------------------------------
function ReadyWaitVariables(data)
    ## Set ready and check wait variable after upgraded and/or loaded on transport
    ## Just prior to moving the unit
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

# ------------------------------------------
# Utility Function
# Get and load transports with platoon units
# ------------------------------------------
function GetLoadTransports(platoon)
    local numTransports = GetTransportsThread(platoon)
    if not numTransports then
        return false
    end

    platoon:Stop()
    local aiBrain = platoon:GetBrain()


        # Load transports
    local transportTable = {}
    local transSlotTable = {}

    local scoutUnits = platoon:GetSquadUnits('scout') or {}

    for num,unit in scoutUnits do
        local id = unit:GetUnitId()
        if not transSlotTable[id] then
            transSlotTable[id] = GetNumTransportSlots(unit)
        end
        table.insert( transportTable,
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
        if EntityCategoryContains( categories.url0306 + categories.DEFENSE, unit ) then
            table.insert( shields, unit )
        elseif unit:GetBlueprint().Transport.TransportClass == 3 then
            table.insert( remainingSize3, unit )
        elseif unit:GetBlueprint().Transport.TransportClass == 2 then
            table.insert( remainingSize2, unit )
        elseif unit:GetBlueprint().Transport.TransportClass == 1 then
            table.insert( remainingSize1, unit )
        else
            table.insert( remainingSize1, unit )
        end
    end
#    LOG( '*AI DEBUG: NUM SHIELDS= ', table.getn( shields ) )
#    LOG( '*AI DEBUG: NUM LARGE = ', table.getn( remainingSize3 ) )
#    LOG( '*AI DEBUG: NUM MEDIUM = ', table.getn( remainingSize2 ) )
#    LOG( '*AI DEBUG: NUM SMALL = ', table.getn( remainingSize1 ) )
    local needed = GetNumTransports(platoon)
    local largeHave = 0
    for num, data in transportTable do
        largeHave = largeHave + data.LargeSlots
    end
    local leftoverUnits = {}
    local currLeftovers = {}
    local leftoverShields = {}
    transportTable, leftoverShields = SortUnitsOnTransports( transportTable, shields, largeHave - needed.Large )
#    LOG('*AI DEBUG: NUM LEFTOVER SHIELDS = ', table.getn( leftoverShields ) )
    transportTable, leftoverUnits = SortUnitsOnTransports( transportTable, remainingSize3, -1 )
#    LOG('*AI DEBUG: NUM LEFTOVER LARGE = ', table.getn( leftoverUnits ) )
    transportTable, currLeftovers = SortUnitsOnTransports( transportTable, leftoverShields, -1 )
#    LOG('*AI DEBUG: NUM LEFTOVER SHIELDS SHIELDS = ', table.getn( currLeftovers ) )
    for k,v in currLeftovers do table.insert(leftoverUnits, v) end
    transportTable, currLeftovers = SortUnitsOnTransports( transportTable, remainingSize2, -1 )
#    LOG('*AI DEBUG: NUM LEFTOVER MEDIUM = ', table.getn( currLeftovers ) )
    for k,v in currLeftovers do table.insert(leftoverUnits, v) end
    transportTable, currLeftovers = SortUnitsOnTransports( transportTable, remainingSize1, -1 )
#    LOG('*AI DEBUG: NUM LEFTOVER SMALL = ', table.getn( currLeftovers ) )
    for k,v in currLeftovers do table.insert(leftoverUnits, v) end
    transportTable, currLeftovers = SortUnitsOnTransports( transportTable, currLeftovers, -1 )
#    LOG('*AI DEBUG: NUM LEFTOVER FINAL = ', table.getn( currLeftovers ) )


        # Old load transports
    local monitorUnits = {}
    for num, data in transportTable do
        if table.getn( data.Units ) > 0 then
            IssueClearCommands( data.Units )
            IssueTransportLoad( data.Units, data.Transport )
            for k,v in data.Units do table.insert( monitorUnits, v) end
        end
    end
#    LOG('*AI DEBUG: NUM LEFTOVER UNITS = ', table.getn(leftoverUnits) )
#    LOG('*AI DEBUG: NUM UNITS MONITORED = ', table.getn(monitorUnits) + table.getn(transportTable) )
#    LOG('*AI DEBUG: NUM UNITS OMGZ = ', table.getn(platoon:GetPlatoonUnits()) )
#    cmd = platoon:LoadUnits(categories.ALLUNITS)
    local attached = true
    repeat
        WaitSeconds(2)
        if not aiBrain:PlatoonExists(platoon) then
            return false
        end
        attached = true
        for k,v in monitorUnits do
            if not v:IsDead() and not v:IsIdleState() then
                attached = false
                break
            end
        end
    until attached
    # Any units that aren't transports and aren't attached send back to pool
    local pool
    if platoon.PlatoonData.BuilderName and platoon.PlatoonData.LocationType then
        pool = aiBrain:GetPlatoonUniquelyNamed(platoon.PlatoonData.LocationType..'_LeftoverUnits')
        if not pool then
            pool = aiBrain:MakePlatoon('', '')
            pool:UniquelyNamePlatoon(platoon.PlatoonData.LocationType..'_LeftoverUnits')
            if platoon.PlatoonData.AMPlatoons then
                pool.PlatoonData.AMPlatoons = { platoon.PlatoonData.LocationType..'_LeftoverUnits' }
                pool:SetPartOfAttackForce()
            end
        end
    else
        pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
    end
    for k,unit in platoon:GetPlatoonUnits() do
        if not EntityCategoryContains( categories.TRANSPORTATION, unit ) then
            if not unit:IsUnitState('Attached') then
                aiBrain:AssignUnitsToPlatoon( pool, {unit}, 'Unassigned', 'None' )
                #LOG('*DEBUG: ADDING UNIT TO LEFTOVER POOL')
            end
        end
    end
    return true
end


# ------------------------------------------------
# Utility function
# Sorts units onto transports distributing equally
# ------------------------------------------------
function SortUnitsOnTransports( transportTable, unitTable, numSlots )
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
                table.insert( transportTable[transSlotNum].Units, unit )
                if unit:GetBlueprint().Transport.TransportClass == 3 and remainingLarge >= 1 then
                    transportTable[transSlotNum].LargeSlots = transportTable[transSlotNum].LargeSlots - 1
                    transportTable[transSlotNum].MediumSlots = transportTable[transSlotNum].MediumSlots - 2
                    transportTable[transSlotNum].SmallSlots = transportTable[transSlotNum].SmallSlots - 4
                elseif unit:GetBlueprint().Transport.TransportClass == 2 and remainingMed > 0 then
                    if transportTable[transSlotNum].LargeSlots > 0 then
                        transportTable[transSlotNum].LargeSlots = transportTable[transSlotNum].LargeSlots - .5
                    end
                    transportTable[transSlotNum].MediumSlots = transportTable[transSlotNum].MediumSlots - 1
                    transportTable[transSlotNum].SmallSlots = transportTable[transSlotNum].SmallSlots - 2
                elseif unit:GetBlueprint().Transport.TransportClass == 1 and remainingSml > 0 then
                    transportTable[transSlotNum].SmallSlots = transportTable[transSlotNum].SmallSlots - 1
                elseif remainingSml > 0 then
                    transportTable[transSlotNum].SmallSlots = transportTable[transSlotNum].SmallSlots - 1
                else
                    #LOG('*AI DEBUG: FOUND TRANSPORT NOT ENOUGH SLOTS')
                    table.insert(leftoverUnits, unit)
                end
            else
                #LOG('*AI DEBUG: NO TRANSPORT FOUND')
                table.insert(leftoverUnits, unit)
            end
        end
    end
    return transportTable, leftoverUnits
end


# ------------------------------------------------------
# Utility function
# Generates a random patrol route for RandomPatrolThread
# ------------------------------------------------------
function GetRandomPatrolRoute(patrol)
    local randPatrol = {}
    local tempPatrol = {}
    for k, v in patrol do
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


# ------------------------------------------------
# Utility Function
# Returns location with lowest non-negative threat
# ------------------------------------------------
function PlatoonChooseLowestNonNegative( aiBrain, locationList, ringSize, location )
    local bestLocation = {}
    local bestThreat = 0
    local currThreat = 0
    local locationSet = false

    for k, v in locationList do
        currThreat = aiBrain:GetThreatAtPosition( v, ringSize, true )
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

# --------------------------------------------------------
# Utility Function
# Returns location with lowest threat (including negative)
# --------------------------------------------------------
function PlatoonChooseLowest(aiBrain, locationList, ringSize, location)
    local bestLocation = {}
    local locationSet = false
    local bestThreat = 0
    local currThreat = 0

    for k, v in locationList do
        currThreat = aiBrain:GetThreatAtPosition(v, ringSize, true)
		WaitSeconds(0.1)
        if not location or location ~= v then
            if (currThreat < bestThreat ) or not locationSet then
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

# ----------------------------------------
# Utility Function
# Returns location with the highest threat
# ----------------------------------------
function PlatoonChooseHighest( aiBrain, locationList, ringSize, location )
    local bestLocation = locationList[1]
    local highestThreat = 0
    local currThreat = 0

    for k, v in locationList do
        currThreat = aiBrain:GetThreatAtPosition( v, ringSize, true )
		WaitSeconds(0.1)
        if(currThreat > highestThreat) and (not location or location ~= v) then
            highestThreat = currThreat
            bestLocation = v
        end
    end

    return bestLocation
end

# -----------------------------------------
# Utility Function
# Returns location randomly with threat > 0
# -----------------------------------------
function PlatoonChooseRandomNonNegative( aiBrain, locationList, ringSize )
    local landingList = {}
    for k, v in locationList do
        if aiBrain:GetThreatAtPosition( v, ringSize, true ) > 0 then
			WaitSeconds(0.1)
            table.insert(landingList, v)
        end
    end
    local loc = landingList[Random(1,table.getn(landingList))]
    if not loc then
        loc = locationList[Random(1,table.getn(locationList))]
    end
    return loc
end

# -------------------------------------------------------
# Utility Function
# Arranges a route from highest to lowest based on threat
# -------------------------------------------------------
function PlatoonChooseHighestAttackRoute(aiBrain, locationList, ringSize)
    local attackRoute = {}
    local tempRoute = {}

    for k, v in locationList do
        table.insert(tempRoute, v)
    end

    local num = table.getn(tempRoute)
    for i = 1, num do
        table.insert(attackRoute, PlatoonChooseHighest(aiBrain, tempRoute, ringSize))
        for k, v in tempRoute do
            if(attackRoute[i] == v) then
                table.remove(tempRoute, k)
                break
            end
        end
    end

    return attackRoute
end

# -------------------------------------------------
# Utility Function
# Arranges a route from lowest to highest on threat
# -------------------------------------------------
function PlatoonChooseLowestAttackRoute(aiBrain, locationList, ringSize)
    local attackRoute = {}
    local tempRoute = {}

    for k, v in locationList do
        table.insert(tempRoute, v)
    end

    local num = table.getn(tempRoute)
    for i = 1, num do
        table.insert(attackRoute, PlatoonChooseLowestNonNegative(aiBrain, tempRoute, ringSize))
        for k, v in tempRoute do
            if(attackRoute[i] == v) then
                table.remove(tempRoute, k)
                break
            end
        end
    end

    return attackRoute
end


# -----------------------------------------------------------------
# Utility Function
# Function that gets the correct number of transports for a platoon
# -----------------------------------------------------------------
function GetTransportsThread(platoon)
    local data = platoon.PlatoonData
    local aiBrain = platoon:GetBrain()

    local neededTable = GetNumTransports(platoon)
    local numTransports = 0
    local transportsNeeded = false
    if neededTable.Small > 0 or neededTable.Medium > 0 or neededTable.Large > 0 then
        transportsNeeded = true
    end
    local transSlotTable = {}

    if transportsNeeded then
        local pool = aiBrain:GetPlatoonUniquelyNamed( 'TransportPool' )
        if not pool then
            pool = aiBrain:MakePlatoon('None', 'None')
            pool:UniquelyNamePlatoon('TransportPool')
        end
        while transportsNeeded do
            neededTable = GetNumTransports(platoon)
            # make sure more are needed
            local tempNeeded = {}
            tempNeeded.Small = neededTable.Small
            tempNeeded.Medium = neededTable.Medium
            tempNeeded.Large = neededTable.Large
            # Find out how many units are needed currently
            for k,v in platoon:GetPlatoonUnits() do
                if not v:IsDead() then
                    if EntityCategoryContains( categories.TRANSPORTATION, v ) then
                        local id = v:GetUnitId()
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
                # Determine distance of transports from platoon
                for k,unit in pool:GetPlatoonUnits() do
                    if EntityCategoryContains( categories.TRANSPORTATION, unit ) and not unit:IsUnitState('Busy') then
                        local unitPos = unit:GetPosition()
                        local curr = { Unit=unit, Distance=VDist2( unitPos[1], unitPos[3], location[1], location[3] ),
                                       Id = unit:GetUnitId() }
                        table.insert( transports, curr )
                    end
                end
                if table.getn(transports) > 0 then
                    local sortedList = {}
                    # Sort distances
                    for k = 1,table.getn(transports) do
                        local lowest = -1
                        local key, value
                        for j,u in transports do
                            if lowest == -1 or u.Distance < lowest then
                                lowest = u.Distance
                                value = u
                                key = j
                            end
                        end
                        sortedList[k] = value
                        # remove from unsorted table
                        table.remove( transports, key )
                    end
                    # Take transports as needed
                    for i=1,table.getn(sortedList) do
                        if transportsNeeded then
                            local id = sortedList[i].Id
                            aiBrain:AssignUnitsToPlatoon(platoon, {sortedList[i].Unit}, 'Scout', 'GrowthFormation')
                            numTransports = numTransports + 1
                            #IssueMove( {sortedList[i].Unit}, platoon:GetPlatoonPosition() )
                            if not transSlotTable[id] then
                                transSlotTable[id] = GetNumTransportSlots(sortedList[i].Unit)
                            end
                            local tempSlots = {}
                            tempSlots.Small = transSlotTable[id].Small
                            tempSlots.Medium = transSlotTable[id].Medium
                            tempSlots.Large = transSlotTable[id].Large
                            # update number of slots needed
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
                for k,unit in platoon:GetPlatoonUnits() do
                    if not EntityCategoryContains( categories.TRANSPORTATION, unit ) then
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

# -------------------------------------------------------------
# Utility Function
# Returns the number of transports required to move the platoon
# -------------------------------------------------------------
function GetNumTransports(platoon)
    local transportNeeded = {
        Small = 0,
        Medium = 0,
        Large = 0,
    }
    local transportClass
    for k, v in platoon:GetPlatoonUnits() do
        transportClass = v:GetBlueprint().Transport.TransportClass
        if(transportClass == 1) then
            transportNeeded.Small = transportNeeded.Small + 1
        elseif(transportClass == 2) then
            transportNeeded.Medium = transportNeeded.Medium + 1
        elseif(transportClass == 3) then
            transportNeeded.Large = transportNeeded.Large + 1
        else
            transportNeeded.Small = transportNeeded.Small + 1
        end
    end

    return transportNeeded
end

# -------------------------------------------------------
# Utility Function
# Returns the number of slots the transport has available
# -------------------------------------------------------
function GetNumTransportSlots(unit)
    local bones = {
        Large = 0,
        Medium = 0,
        Small = 0,
    }
    for i=1,unit:GetBoneCount() do
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
    return bones
end

# ---------------------------------------
# Utility Function
# NOT USED - Creates a route to something
# ---------------------------------------
function GetRouteToVector(platoon, squad)
    local aiBrain = platoon:GetBrain()
    local data = platoon.PlatoonData

    # All vectors in the table
    aiBrain:SetUpAttackVectorsToArmy()
    local vectorTable = aiBrain:GetAttackVectors()
    local lowX = 10000
    local lowZ = 10000
    local highX = -1
    local highZ = -1
    for k, vec in vectorTable do
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

    # Check if route needs to be generated
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

    #### Move vector out
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
        route[1] = { atkVector[1], atkVector[2], atkVector[3] }
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

# ------------------------------------------------------------------
# Utility Function
# Moves a platoon along a route holding up the thread until finished
# ------------------------------------------------------------------
function MoveAlongRoute(platoon, route)
    local cmd = false
    local aiBrain = platoon:GetBrain()

    # move platoon along route
    for k,v in route do
        cmd = platoon:MoveToLocation(v, false)
    end

    # make sure we have a command then check if commands are finished every second
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