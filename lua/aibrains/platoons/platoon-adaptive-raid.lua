
local AIPlatoon = import("/lua/aibrains/platoons/platoon-base.lua").AIPlatoon
local NavUtils = import("/lua/sim/navutils.lua")
local AIUtils = import("/lua/ai/aiutilities.lua")
local MarkerUtils = import("/lua/sim/markerutilities.lua")
local TransportUtils = import("/lua/ai/transportutilities.lua")
local AIAttackUtils = import("/lua/ai/aiattackutilities.lua")
local AIUtils = import("/lua/ai/aiutilities.lua")

-- upvalue scope for performance
local Random = Random
local IsDestroyed = IsDestroyed

local TableGetn = table.getn
local TableEmpty = table.empty

-- constants
local NavigateDistanceThresholdSquared = 25 * 25

---@class AIPlatoonAdaptiveRaidBehavior : AIPlatoon
---@field RetreatCount number 
---@field ThreatToEvade Vector | nil
---@field LocationToRaid Vector | nil
---@field OpportunityToRaid Vector | nil
AIPlatoonAdaptiveRaidBehavior = Class(AIPlatoon) {

    PlatoonName = 'AdaptiveRaidBehavior',

    Start = State {

        StateName = 'Start',

        --- Initial state of any state machine
        ---@param self AIPlatoonAdaptiveRaidBehavior
        Main = function(self)
            -- requires expansion markers
            if not import("/lua/sim/markerutilities/expansions.lua").IsGenerated() then
                self:LogWarning('requires generated expansion markers')
                self:ChangeState(self.Error)
                return
            end

            -- requires navigational mesh
            if not NavUtils.IsGenerated() then
                self:LogWarning('requires generated navigational mesh')
                self:ChangeState(self.Error)
                return
            end
            local aiBrain = self:GetBrain()
            if not aiBrain.GridPresence then
                self:LogWarning('requires grid presence class setup')
                self:ChangeState(self.Error)
                return
            end
            if not aiBrain.GridPresence then
                self:LogWarning('requires GridPresence class setup')
                self:ChangeState(self.Error)
                return
            end
            if not aiBrain.GridDeposits then
                self:LogWarning('requires GridDeposits class setup')
                self:ChangeState(self.Error)
                return
            end
            if self.PlatoonData.LocationType then
                self.LocationType = self.PlatoonData.LocationType
            else
                self.LocationType = 'MAIN'
            end
            self.MaxTransportDistance = 250
            self.MaxPlatoonCount = 25

            -- Set the movement layer for pathing, included for mods where water or air based engineers may exist
            self.MovementLayer = self:GetNavigationalLayer()

            self:ChangeState(self.Searching)
            return
        end,
    },

    Searching = State {

        StateName = 'Searching',

        --- The platoon searches for a target
        ---@param self AIPlatoonAdaptiveRaidBehavior
        Main = function(self)
            -- reset state
            self.LocationToRaid = nil
            self.OpportunityToRaid = nil
            self.ThreatToEvade = nil
            self.RetreatCount = 0
            local aiBrain = self:GetBrain()

            self:Stop()

            local position = self:GetPlatoonPosition()
            if not position then
                return
            end

            local units, unitCount = self:GetPlatoonUnits()
            local label, error = NavUtils.GetLabel(self.MovementLayer, position)

            if label then
                -- TODO
                -- this should be cached, part of the marker utilities
                local expansions, count = MarkerUtils.GetMarkersByType('Expansion Area')
                ---@type MarkerData[]
                local candidates = { }
                local unpathableCandidates = { }
                local candidateCount = 0
                local unpathableCandidateCount = 0
                for k = 1, count do
                    local expansion = expansions[k]
                    if NavUtils.GetLabel(self.MovementLayer, expansion.position) == label then
                        if aiBrain.GridPresence:GetInferredStatus(expansion.position) ~= 'Allied' then
                            candidates[candidateCount + 1] = expansion
                            candidateCount = candidateCount + 1
                        end
                    elseif not NavUtils.CanPathTo(self.MovementLayer, position, expansion.position) then
                        if aiBrain.GridPresence:GetInferredStatus(expansion.position) ~= 'Allied' then
                            unpathableCandidates[unpathableCandidateCount + 1] = expansion
                            unpathableCandidateCount = unpathableCandidateCount + 1
                        end
                    end
                end
                -- END OF TODO

                -- something odd happened: there are no expansions with a matching label
                if candidateCount == 0 and unpathableCandidateCount == 0 then
                    self:LogDebug(string.format('no expansion candidates found on label %d switch to mass points', label))
                    -- There are no expansion positions to raid, switch to mass markers
                    local massmarkers, count = MarkerUtils.GetMarkersByType('Mass')
                    for k = 1, count do
                        local masspoint = massmarkers[k]
                        if NavUtils.GetLabel(self.MovementLayer, masspoint.position) == label then
                            if aiBrain.GridPresence:GetInferredStatus(masspoint.position) ~= 'Allied' then
                                candidates[candidateCount + 1] = masspoint
                                candidateCount = candidateCount + 1
                            end
                        elseif not NavUtils.CanPathTo(self.MovementLayer, position, masspoint.position) then
                            if aiBrain.GridPresence:GetInferredStatus(masspoint.position) ~= 'Allied' then
                                unpathableCandidates[unpathableCandidateCount + 1] = masspoint
                                unpathableCandidateCount = unpathableCandidateCount + 1
                            end
                        end
                    end
                end

                if candidateCount == 0 and unpathableCandidateCount == 0 then
                    -- There are still no candidates
                    self:LogWarning(string.format('no raid candidates found on label %d', label))
                    self:LogWarning(string.format('we are going to switch to the attack platoon'))
                    local plat = aiBrain:MakePlatoon('', '')
                    aiBrain:AssignUnitsToPlatoon(plat, units, 'attack', 'None')
                    import("/lua/aibrains/platoons/platoon-adaptive-attack.lua").AssignToUnitsMachine({ LocationType = self.LocationType}, plat, units)
                    return
                end

                -- pick random expansion that we can Navigating to
                local selectionNumber
                local expansion
                if candidateCount > 0 then
                    selectionNumber = Random(1, candidateCount)
                    expansion = candidates[selectionNumber]
                elseif unpathableCandidateCount > 0 then
                    selectionNumber = Random(1, unpathableCandidateCount)
                    expansion = unpathableCandidates[selectionNumber]
                end
                if unpathableCandidateCount > 0 then
                    self:LogDebug(string.format('unpathableCandidateCount '..unpathableCandidateCount))
                    self:LogDebug(string.format('Current raid position is '..repr(expansion.position)))
                end
                self.LocationToRaid = expansion.position
                if self.LocationToRaid then
                    self:LogDebug(string.format('Location to raid is '..repr(self.LocationToRaid)))
                else
                    self:LogDebug(string.format('Location to raid is nil'))
                end
                local rx = expansion.position[1] - position[1]
                local rz = expansion.position[3] - position[3]
                if rx * rx + rz * rz > 3600 then
                    self:ChangeState(self.Navigating)
                    return
                else
                    self:ChangeState(self.RaidingTarget)
                    return
                end
            else
                -- something odd happened: try again with another unit
                self:LogWarning(string.format('no label found', label))
                WaitTicks(20)
                self:ChangeState(self.Searching)
                return
            end
        end,
    },

    Navigating = State {

        StateName = "Navigating",

        --- The platoon retreats from a threat
        ---@param self AIPlatoonAdaptiveRaidBehavior
        Main = function(self)
            self:LogDebug('Navigating')
            if IsDestroyed(self) then
                return
            end
            self.OpportunityToRaid = nil
            self.ThreatToEvade = nil
            local cache = { 0, 0, 0 }

            -- sanity check
            local destination = self.LocationToRaid
            if not destination then
                self:LogWarning(string.format('no destination to navigate to'))
                WaitTicks(20)
                self:ChangeState(self.Searching)
                return
            end

            if not self.CurrentPlatoonThreat then
                self.CurrentPlatoonThreat = self:CalculatePlatoonThreat('Surface', categories.ALLUNITS)
            end
            local origin = self:GetPlatoonPosition()
            if not origin then
                return
            end

            local brain = self:GetBrain()
            local path, reason =  NavUtils.PathToWithThreatThreshold(self.MovementLayer, origin, destination, brain, NavUtils.ThreatFunctions.AntiSurface, 200, brain.IMAPConfig.Rings)
            if not path then
                self:LogDebug(string.format('platoon is going to use transport'))
                WaitTicks(10)
                self:ChangeState(self.Transporting)
                return
            end
            local bAggroMove = self.PlatoonData.AggressiveMove
            local pathNodesCount = TableGetn(path)
            local attackFormation = false
            for i=1, pathNodesCount do
                if IsDestroyed(self) then
                    return
                end
                local distEnd
                local currentLayerSeaBed = false
                local units = self:GetPlatoonUnits()
                for _, v in units do
                    if v and not IsDestroyed(v) then
                        if v:GetCurrentLayer() ~= 'Seabed' then
                            currentLayerSeaBed = false
                            break
                        else
                            currentLayerSeaBed = true
                            break
                        end
                    end
                end
                if bAggroMove and (not currentLayerSeaBed) then
                    if distEnd and distEnd > 6400 then
                        self:SetPlatoonFormationOverride('NoFormation')
                        attackFormation = false
                    end
                    self:AggressiveMoveToLocation(path[i])
                else
                    --RNGLOG('HUNTAIPATH Attack and Guard moving non aggro')
                    if distEnd and distEnd > 6400 then
                        self:SetPlatoonFormationOverride('NoFormation')
                        attackFormation = false
                    end
                    self:MoveToLocation(path[i], false)
                end
                local Lastdist
                local dist
                local Stuck = 0
                while not IsDestroyed(self) do
                    if IsDestroyed(self) then
                        return
                    end
                    
                    local position = self:GetPlatoonPosition()
                    if not position then
                        return
                    end

                    units = self:GetPlatoonUnits()

                    local threat = brain:GetThreatAtPosition(position, 1, true, 'AntiSurface')
                    if threat > 0 then
                        local homeBasePosition = brain.BuilderManagers[self.LocationType].Position or brain.BuilderManagers['MAIN'].Position
                        local hx = position[1] - homeBasePosition[1]
                        local hz = position[3] - homeBasePosition[3]
                        if hx * hx + hz * hz > 4225 then
                            local threatTable = brain:GetThreatsAroundPosition(position, 1, true, 'AntiSurface')
                            local platoonThreat = self:CalculatePlatoonThreatAroundPosition('Surface', categories.MOBILE * categories.DIRECTFIRE - categories.SCOUT, position, 30)
                            local positionStatus = brain.GridPresence:GetInferredStatus(position)
                            if positionStatus != 'Allied' and platoonThreat * 1.5 < threat then
                                if threatTable and not TableEmpty(threatTable) then
                                    local info = threatTable[Random(1, TableGetn(threatTable))]
                                    self.ThreatToEvade = { info[1], GetSurfaceHeight(info[1], info[2]), info[2] }
                                    self:LogDebug(string.format('We are going to retreat, enemy threat '..threat..' our threat '..platoonThreat..' position status '.. tostring(positionStatus)))
                                    self:ChangeState(self.Retreating)
                                    return
                                end
                            elseif positionStatus then
                                self:LogDebug(string.format('We are going to attack, enemy threat '..threat..' our threat '..platoonThreat..' position status '.. tostring(positionStatus)))
                            end
                        end
                    end
                    -- check for opportunities
                    local oppertunity = brain:GetThreatAtPosition(position, 2, true, 'Economy')
                    if oppertunity > 0 then
                        local opportunities = brain:GetThreatsAroundPosition(position, 2, true, 'Economy')
                        if opportunities and not TableEmpty(opportunities) then
                            for k = 1, TableGetn(opportunities) do
                                local info = opportunities[k]
                                cache[1] = info[1]
                                cache[3] = info[2]

                                local threat = brain:GetThreatAtPosition(cache, 0, true, 'AntiSurface')
                                if threat == 0 then
                                    self.OpportunityToRaid = { info[1], GetSurfaceHeight(info[1], info[2]), info[2] }
                                    self:ChangeState(self.RaidingOpportunity)
                                    return
                                end
                            end
                        end
                    end
                    distEnd = VDist2Sq(path[pathNodesCount][1], path[pathNodesCount][3], position[1], position[3] )
                    if not attackFormation and distEnd < 6400 then
                        attackFormation = true
                        self:SetPlatoonFormationOverride('AttackFormation')
                    end
                    dist = VDist2Sq(path[i][1], path[i][3], position[1], position[3])
                    if dist < 400 then
                        IssueClearCommands(units)
                        break
                    end
                    
                    if Lastdist ~= dist then
                        Stuck = 0
                        Lastdist = dist
                    -- No, we are not moving, wait 100 ticks then break and use the next weaypoint
                    else
                        Stuck = Stuck + 1
                        if Stuck > 15 then
                            WaitTicks(15)
                            self:Stop()
                            break
                        end
                    end
                    coroutine.yield(15)
                end
            end
            self:ChangeState(self.Searching)
            return
        end,
    },

    Transporting = State {

        StateName = 'Transporting',

        --- The platoon avoids danger or attempts to reclaim if they are too close to avoid
        ---@param self AIPlatoonAdaptiveRaidBehavior
        Main = function(self)
            local brain = self:GetBrain()
            local usedTransports = TransportUtils.SendPlatoonWithTransports(brain, self, self.LocationToRaid, 3, false)
            if usedTransports then
                self:LogDebug(string.format('Raid Platoon used transports'))
                self:ChangeState(self.Navigating)
            else
                self:LogDebug(string.format('Raid Platoon didnt use transports'))
                if self.MaxTransportDistance < 500 then
                    self.MaxTransportDistance = self.MaxTransportDistance + 100
                end
                self:ChangeState(self.Searching)
            end
            return
        end,
    },

    RaidingTarget = State {

        StateName = 'RaidingTarget',

        --- The platoon raids the target
        ---@param self AIPlatoonAdaptiveRaidBehavior
        Main = function(self)
            local brain = self:GetBrain()

            -- sanity check
            local location = self.LocationToRaid
            if not location then
                self:LogWarning(string.format('no location to raid'))
                self:ChangeState(self.Searching)
                return
            end

            self:Stop()
            local command = self:AggressiveMoveToLocation(location)

            while not IsDestroyed(self) do
                -- check if there is something to raid
                local opportunity = brain:GetThreatAtPosition(location, 0, true, 'Economy')
                if opportunity == 0 then
                    self:ChangeState(self.Searching)
                    return
                end

                -- check for threats
                local position = self:GetPlatoonPosition()
                if not position then
                    return
                end
                local threat = brain:GetThreatAtPosition(position, 1, true, 'AntiSurface')
                if threat > 0 then
                    local threatTable = brain:GetThreatsAroundPosition(position, 1, true, 'AntiSurface')
                    if threatTable and not TableEmpty(threatTable) then
                        local info = threatTable[Random(1, TableGetn(threatTable))]
                        self.ThreatToEvade = { info[1], GetSurfaceHeight(info[1], info[2]), info[2] }
                        self:ChangeState(self.Retreating)
                        return
                    end
                end

                -- check if our command is still going
                if not self:IsCommandsActive(command) then
                    self:ChangeState(self.Searching)
                    return
                end

                WaitTicks(60)
            end
        end,
    },

    RaidingOpportunity = State {

        StateName = 'RaidingOpportunity',

        --- The platoon raids the opportunity it walked into
        ---@param self AIPlatoonAdaptiveRaidBehavior
        Main = function(self)
            local brain = self:GetBrain()

            -- sanity check
            local location = self.OpportunityToRaid
            if not location then
                self:LogWarning(string.format('no opportunity to raid'))
                self:ChangeState(self.Navigating)
                return
            end

            self:Stop()

            -- tell attack units to attack
            local attackCommand
            local attackOffset, error = NavUtils.RandomDirectionFrom('Land', location, 32, 4)       -- TODO: remove magic numbers'
            if not attackOffset then
                attackCommand = self:AggressiveMoveToLocation(location, 'Attack')
            else
                attackCommand = self:AggressiveMoveToLocation(attackOffset, 'Attack')
            end

            -- tell scout units to patrol for threats
            local scoutOffsets, countOrError = NavUtils.DirectionsFrom('Land', location, 32, 4)    -- TODO: remove magic numbers
            if not scoutOffsets then
                self:Patrol(location, 'Scout')
            else
                local scoutOffsetCount = TableGetn(scoutOffsets)
                for k = 1, 3 do
                    self:Patrol(scoutOffsets[Random(1, scoutOffsetCount)], 'Scout')
                end
            end

            while not IsDestroyed(self) do

                -- check for opportunities
                local opportunity = brain:GetThreatAtPosition(location, 0, true, 'Economy')
                if opportunity == 0 then
                    self:ChangeState(self.Navigating)
                    return
                end

                -- check for threats
                local position = self:GetPlatoonPosition()
                if not position then
                    return
                end

                local threat = brain:GetThreatAtPosition(position, 1, true, 'AntiSurface')
                if threat > 0 then
                    local threatTable = brain:GetThreatsAroundPosition(position, 1, true, 'AntiSurface')
                    local platoonThreat = self:CalculatePlatoonThreatAroundPosition('Surface', categories.MOBILE * categories.DIRECTFIRE - categories.SCOUT, position, 30)
                    local positionStatus = brain.GridPresence:GetInferredStatus(position)
                    if positionStatus != 'Allied' and platoonThreat * 2 < threat then
                        if threatTable and not TableEmpty(threatTable) then
                            local info = threatTable[Random(1, TableGetn(threatTable))]
                            self.ThreatToEvade = { info[1], GetSurfaceHeight(info[1], info[2]), info[2] }
                            self:ChangeState(self.Retreating)
                            return
                        end
                    else
                        self:LogDebug(string.format('Threat and we need to attack then since it is allied, status '.. tostring(positionStatus)))
                    end
                end

                -- check if our command is still going
                if not self:IsCommandsActive(attackCommand) then
                    -- setup attack units
                    local attackOffset, error = NavUtils.RandomDirectionFrom('Land', location, 20, 8)       -- TODO: remove magic numbers
                    if not attackOffset then
                        self:LogWarning(string.format('no alternative directions found to evade'))
                        self:ChangeState(self.Error)
                        return
                    end

                    attackCommand = self:AggressiveMoveToLocation(attackOffset, 'Attack')
                end

                WaitTicks(10)
            end
        end,
    },

    Retreating = State {

        StateName = "Retreating",

        --- The platoon retreats from a threat
        ---@param self AIPlatoonAdaptiveRaidBehavior
        Main = function(self)
            local brain = self:GetBrain()

            -- sanity check
            local location = self.ThreatToEvade
            if not location then
                self:LogWarning(string.format('no threat to evade'))
                self:ChangeState(self.Navigating)
                return
            end

            self:Stop()

            self.RetreatCount = self.RetreatCount + 1
            local platoonUnits, platoonCount = self:GetPlatoonUnits()

            while not IsDestroyed(self) do

                local position = self:GetPlatoonPosition()
                if not position then
                    return
                end

                local waypoint, error = NavUtils.RetreatDirectionFrom('Land', position, location, 40)

                if not waypoint then
                    -- do something
                    return
                end

                local wx = waypoint[1]
                local wz = waypoint[3]

                self:MoveToLocation(waypoint, false)

                while not IsDestroyed(self) do
                    local position = self:GetPlatoonPosition()
                    if not position then
                        return
                    end

                    -- check if we're near our retreat point
                    local dx = position[1] - wx
                    local dz = position[3] - wz
                    if dx * dx + dz * dz < NavigateDistanceThresholdSquared then
                        if self.RetreatCount < 3 then
                            self:ChangeState(self.Navigating)
                        else
                            if platoonCount < self.MaxPlatoonCount then
                                local merged = AIUtils.MergeWithNearbyStatePlatoons(self, 'AdaptiveRaidBehavior', 65, self.MaxPlatoonCount, true)
                                if not merged then
                                    WaitTicks(10)
                                end
                            end
                            self:ChangeState(self.Searching)
                        end
                        return
                    end

                    WaitTicks(10)
                end

                WaitTicks(1)
            end
        end,
    },

    -----------------------------------------------------------------
    -- brain events

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToAttackSquad = function(self, units)
        local cache = { false }
        local count = TableGetn(units)

        if count > 0 then
            local scouts = self:GetSquadUnits('Scout')
            if scouts then
                for k, scout in scouts do
                    cache[1] = scout
                    IssueClearCommands(cache)
                    IssueGuard(cache, units[Random(1, count)])
                end
            end
        end
    end,

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToScoutSquad = function(self, units)
        local cache = { false }
        local attacks = self:GetSquadUnits('Attack')
        local count = TableGetn(attacks)
        if attacks then
            for k, scout in units do
                cache[1] = scout
                IssueClearCommands(cache)
                IssueGuard(cache, attacks[Random(1, count)])
            end
        end

        for k, scout in units do 
            scout:SetFireState(1)
        end
    end,
}

---@param data { Behavior: 'AIPlatoonAdaptiveRaidBehavior' }
---@param units Unit[]
DebugAssignToUnits = function(data, units)
    if units and not TableEmpty(units) then

        -- meet platoon requirements
        import("/lua/sim/navutils.lua").Generate()
        import("/lua/sim/markerutilities.lua").GenerateExpansionMarkers()

        -- create the platoon
        local brain = units[1].Brain
        local platoon = brain:MakePlatoon('', '') --[[@as AIPlatoonAdaptiveRaidBehavior]]
        setmetatable(platoon, AIPlatoonAdaptiveRaidBehavior)

        -- assign units to squads
        local scouts = EntityCategoryFilterDown(categories.SCOUT, units)
        local others = EntityCategoryFilterDown(categories.ALLUNITS - categories.SCOUT, units)
        brain:AssignUnitsToPlatoon(platoon, others, 'Attack', 'None')
        brain:AssignUnitsToPlatoon(platoon, scouts, 'Scout', 'None')

        -- start the behavior
        ChangeState(platoon, platoon.Start)
    end
end

---@param data { Behavior: 'AIPlatoonAdaptiveRaidBehavior' }
---@param units Unit[]
AssignToUnitsMachine = function(data, platoon, units)
    if units and not TableEmpty(units) then

        -- meet platoon requirements
        import("/lua/sim/navutils.lua").Generate()
        import("/lua/sim/markerutilities.lua").GenerateExpansionMarkers()
        -- create the platoon
        setmetatable(platoon, AIPlatoonAdaptiveRaidBehavior)
        local count = TableGetn(platoon:GetSquadUnits('Attack'))
        local scouts = platoon:GetSquadUnits('Scout')
        if scouts then
            for k, scout in scouts do
                IssueClearCommands(scout)
                IssueGuard(scout, units[Random(1, count)])
            end
        end

        -- TODO: to be removed until we have a better system to populate the platoons
        platoon:OnUnitsAddedToPlatoon()

        -- start the behavior
        ChangeState(platoon, platoon.Start)
    end
end



