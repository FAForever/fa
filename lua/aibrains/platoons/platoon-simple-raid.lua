
local AIPlatoon = import("/lua/aibrains/platoons/platoon-base.lua").AIPlatoon
local NavUtils = import("/lua/sim/navutils.lua")
local MarkerUtils = import("/lua/sim/markerutilities.lua")

-- upvalue scope for performance
local Random = Random
local IsDestroyed = IsDestroyed

local TableGetn = table.getn
local TableEmpty = table.empty

-- constants
local NavigateDistanceThresholdSquared = 20 * 20

---@class AIPlatoonSimpleRaidBehavior : AIPlatoon
---@field RetreatCount number 
---@field ThreatToEvade Vector | nil
---@field LocationToRaid Vector | nil
---@field OpportunityToRaid Vector | nil
AIPlatoonSimpleRaidBehavior = Class(AIPlatoon) {

    Start = State {
        --- Initial state of any state machine
        ---@param self AIPlatoonSimpleRaidBehavior
        Main = function(self)
            -- requires expansion markers
            if not import("/lua/sim/markerutilities/expansions.lua").IsGenerated() then
                WARN("AI simple raid behavior requires generated expansion markers")
                self:ChangeState('Error')
                return
            end

            -- requires navigational mesh
            if not NavUtils.IsGenerated() then
                WARN("AI simple raid behavior requires navigational mesh")
                self:ChangeState('Error')
                return
            end

            self:ChangeState('Searching')
            return
        end,
    },

    Searching = State {
        --- The platoon searches for a target
        ---@param self AIPlatoonSimpleRaidBehavior
        Main = function(self)
            -- reset state
            self.LocationToRaid = nil
            self.OpportunityToRaid = nil
            self.ThreatToEvade = nil
            self.RetreatCount = 0

            self:Stop()

            -- pick random unit
            local units, unitCount = self:GetPlatoonUnits()
            local unit = units[Random(1, unitCount)]

            -- determine navigational label of that unit
            local position = unit:GetPosition()
            local label, error = NavUtils.GetLabel('Land', position)

            if label then
                
                -- TODO
                -- this should be cached, part of the marker utilities
                local expansions, count = MarkerUtils.GetMarkersByType('Expansion Area')
                ---@type MarkerData[]
                local candidates = { }
                local candidateCount = 0
                for k = 1, count do
                    local expansion = expansions[k]
                    if expansion.NavLabel == label then
                        candidates[candidateCount + 1] = expansion
                        candidateCount = candidateCount + 1
                    end
                end
                -- END OF TODO

                -- something odd happened: there are no expansions with a matching label
                if candidateCount == 0 then
                    WARN(string.format("AI simple raid behavior expansion error: no expansion markers on navigational label (%d)", label))
                    self:ChangeState('Error')
                    return
                end

                -- pick random expansion that we can Navigating to
                local selectionNumber = Random(1, count)
                local expansion = candidates[selectionNumber]
                self.LocationToRaid = expansion.position
                if self.LocationToRaid then
                    LOG('Location to raid is '..repr(self.LocationToRaid))
                else
                    LOG('Location to raid is nil')
                    LOG(repr(expansion))
                    LOG('Selection was '..selectionNumber)
                    LOG('candidates '..repr(candidates))
                end
                self:ChangeState('Navigating')
                return
            else
                -- something odd happened: try again with another unit
                WARN(string.format("AI simple raid behavior label error: %s", error))
                self:ChangeState('Searching')
                return
            end
        end,
    },

    Navigating = State {
        --- The platoon navigates towards a target, picking up oppertunities as it finds them
        ---@param self AIPlatoonSimpleRaidBehavior
        Main = function(self)
            -- reset state
            self.OpportunityToRaid = nil
            self.ThreatToEvade = nil

            -- sanity check
            local destination = self.LocationToRaid
            if not destination then
                WARN(string.format("AI simple raid behavior Navigating error: no location defined to Navigating to"))
                self:ChangeState('Searching')
                return
            end

            self:Stop()

            local cache = { 0, 0, 0 }
            local brain = self:GetBrain()

            while not IsDestroyed(self) do
                -- pick random unit for a position on the grid
                local units, unitCount = self:GetPlatoonUnits()
                local origin = self:GetPlatoonPosition()

                -- generate a direction
                local waypoint, length = NavUtils.DirectionTo('Land', origin, destination, 60)

                -- something odd happened: no direction found
                if not waypoint then
                    WARN(string.format("AI simple raid behavior error: unable to find a path"))
                    self:ChangeState('Searching')
                    return
                end

                -- we're near the destination, better start raiding it!
                if waypoint == destination then
                    self:ChangeState('RaidingTarget')
                    return
                end

                -- navigate towards waypoint 
                local dx = origin[1] - waypoint[1]
                local dz = origin[3] - waypoint[3]
                local d = math.sqrt(dx * dx + dz * dz)
                self:IssueFormMoveToWaypoint(units, origin, waypoint)

                -- check for opportunities
                local wx = waypoint[1]
                local wz = waypoint[3]
                while not IsDestroyed(self) do
                    local position = self:GetPlatoonPosition()

                    -- check if we're near our current waypoint
                    local dx = position[1] - wx
                    local dz = position[3] - wz
                    if dx * dx + dz * dz < NavigateDistanceThresholdSquared then
                        break
                    end

                    -- check for threats
                    local threat = brain:GetThreatAtPosition(position, 1, true, 'AntiSurface')
                    if threat > 0 then
                        local threatTable = brain:GetThreatsAroundPosition(position, 1, true, 'AntiSurface')
                        if threatTable and not TableEmpty(threatTable) then
                            local info = threatTable[Random(1, TableGetn(threatTable))]
                            self.ThreatToEvade = { info[1], GetSurfaceHeight(info[1], info[2]), info[2] }
                            DrawCircle(self.ThreatToEvade, 5, 'ff0000')
                            self:ChangeState('Retreating')
                            return
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
                                    self:ChangeState('RaidingOpportunity')
                                    return
                                end
                            end
                        end
                    end

                    WaitTicks(10)
                end

                -- always wait
                WaitTicks(1)
            end
        end,
    },

    RaidingTarget = State {
        --- The platoon raids the target
        ---@param self AIPlatoonSimpleRaidBehavior
        Main = function(self)
            local brain = self:GetBrain()

            -- sanity check
            local location = self.LocationToRaid
            if not location then
                WARN(string.format("AI simple raid behavior error: no location to raid"))
                self:ChangeState('Searching')
                return
            end

            self:Stop()
            local command = self:AggressiveMoveToLocation(location)

            while not IsDestroyed(self) do

                -- check if there is something to raid
                local opportunity = brain:GetThreatAtPosition(location, 0, true, 'Economy')
                if opportunity == 0 then
                    self:ChangeState('Searching')
                    return
                end

                -- check for threats
                local position = self:GetPlatoonPosition()
                local threat = brain:GetThreatAtPosition(position, 1, true, 'AntiSurface')
                if threat > 0 then
                    local threatTable = brain:GetThreatsAroundPosition(position, 1, true, 'AntiSurface')
                    if threatTable and not TableEmpty(threatTable) then
                        local info = threatTable[Random(1, TableGetn(threatTable))]
                        self.ThreatToEvade = { info[1], GetSurfaceHeight(info[1], info[2]), info[2] }
                        self:ChangeState('Retreating')
                        return
                    end
                end

                -- check if our command is still going
                if not self:IsCommandsActive(command) then

                    return
                end

                WaitTicks(10)
            end
        end,
    },

    RaidingOpportunity = State {
        --- The platoon raids the opportunity it walked into
        ---@param self AIPlatoonSimpleRaidBehavior
        Main = function(self)
            local brain = self:GetBrain()

            -- sanity check
            local location = self.OpportunityToRaid
            if not location then
                WARN(string.format("AI simple raid behavior error: no opportunity to raid"))
                self:ChangeState('Navigating')
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
                    self:ChangeState('Navigating')
                    return
                end

                -- check for threats
                local position = self:GetPlatoonPosition()
                local threat = brain:GetThreatAtPosition(position, 1, true, 'AntiSurface')
                if threat > 0 then
                    local threatTable = brain:GetThreatsAroundPosition(position, 1, true, 'AntiSurface')
                    if threatTable and not TableEmpty(threatTable) then
                        local info = threatTable[Random(1, TableGetn(threatTable))]
                        self.ThreatToEvade = { info[1], GetSurfaceHeight(info[1], info[2]), info[2] }
                        self:ChangeState('Retreating')
                        return
                    end
                end

                -- check if our command is still going
                if not self:IsCommandsActive(attackCommand) then
                    -- setup attack units
                    local attackOffset, error = NavUtils.RandomDirectionFrom('Land', location, 10, 8)       -- TODO: remove magic numbers
                    if not attackOffset then
                        WARN(string.format("AI simple raid behavior error: no alternative directions found because of %s", tostring(error)))
                        self:ChangeState('Error')
                        return
                    end

                    attackCommand = self:AggressiveMoveToLocation(attackOffset, 'Attack')
                end

                WaitTicks(10)
            end
        end,
    },

    Retreating = State {
        --- The platoon retreats from a threat
        ---@param self AIPlatoonSimpleRaidBehavior
        Main = function(self)
            local brain = self:GetBrain()

            -- sanity check
            local location = self.ThreatToEvade
            if not location then
                WARN(string.format("AI simple raid behavior error: no opportunity to raid"))
                self:ChangeState('Navigating')
                return
            end

            self:Stop()

            self.RetreatCount = self.RetreatCount + 1

            while not IsDestroyed(self) do

                local position = self:GetPlatoonPosition()
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

                    -- check if we're near our retreat point
                    local dx = position[1] - wx
                    local dz = position[3] - wz
                    if dx * dx + dz * dz < NavigateDistanceThresholdSquared then
                        if self.RetreatCount < 3 then
                            self:ChangeState('Navigating')
                        else
                            self:ChangeState('Searching')
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
        LOG("OnUnitsAddedToAttackSquad")
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
        LOG("OnUnitsAddedToScoutSquad")
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

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToArtillerySquad = function(self, units)
        WARN("AI simple raid behavior error: artillery squad is unsupported")
    end,

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToSupportSquad = function(self, units)
        WARN("AI simple raid behavior error: support squad is unsupported")
    end,

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToGuardSquad = function(self, units)
        WARN("AI simple raid behavior error: guard squad is unsupported")
    end,
}

---@param data { Behavior: 'AIBehaviorTacticalSimple' }
---@param units Unit[]
DebugAssignToUnits = function(data, units)
    if units and not TableEmpty(units) then
        LOG('Assigning Units to new platoon')

        -- meet platoon requirements
        import("/lua/sim/navutils.lua").Generate()
        import("/lua/sim/markerutilities.lua").GenerateExpansionMarkers()

        -- create the platoon
        local brain = units[1].Brain
        local platoon = brain:MakePlatoon('', '') --[[@as AIPlatoonSimpleRaidBehavior]]
        setmetatable(platoon, AIPlatoonSimpleRaidBehavior)

        -- assign units to squads
        local scouts = EntityCategoryFilterDown(categories.SCOUT, units)
        local others = EntityCategoryFilterDown(categories.ALLUNITS - categories.SCOUT, units)
        brain:AssignUnitsToPlatoon(platoon, others, 'Attack', 'None')
        brain:AssignUnitsToPlatoon(platoon, scouts, 'Scout', 'None')

        -- start the behavior
        ChangeState(platoon, platoon.Start)
    end
end

---@param data { Behavior: 'AIBehaviorTacticalSimple' }
---@param units Unit[]
AssignToUnitsMachine = function(data, platoon, units)
    if units and not TableEmpty(units) then
        LOG('Assigning Units to new platoon')

        -- meet platoon requirements
        import("/lua/sim/navutils.lua").Generate()
        import("/lua/sim/markerutilities.lua").GenerateExpansionMarkers()
        -- create the platoon
        setmetatable(platoon, AIPlatoonSimpleRaidBehavior)
        local count = TableGetn(platoon:GetSquadUnits('Attack'))
        local scouts = platoon:GetSquadUnits('Scout')
        if scouts then
            for k, scout in scouts do
                IssueClearCommands(scout)
                IssueGuard(scout, units[Random(1, count)])
            end
        end

        -- start the behavior
        ChangeState(platoon, platoon.Start)
    end
end



