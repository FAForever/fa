
local AIPlatoon = import("/lua/aibrains/platoons/platoon-base.lua").AIPlatoon
local NavUtils = import("/lua/sim/navutils.lua")
local MarkerUtils = import("/lua/sim/markerutilities.lua")

-- upvalue scope for performance
local Random = Random
local TableGetn = table.getn
local TableEmpty = table.empty

-- constants
local valuableCategories = categories.MASSEXTRACTION + categories.ENERGYPRODUCTION + (categories.ENGINEER - categories.COMMAND) + categories.MASSFABRICATION 
local RaidDistanceThreshold = 30 
local NavigateDistanceThresholdSquared = 20 * 20

---@class AIPlatoonRaid : AIPlatoon
---@field LocationToRaid Vector | nil
---@field OpportunityToRaid Vector | nil
AIPlatoonRaid = Class(AIPlatoon) {

    Start = State {
        --- Initial state of any state machine
        ---@param self AIPlatoonRaid
        Main = function(self)
            LOG(tostring(self) .. " - Start")

            -- requires expansion markers
            if not import("/lua/sim/markerutilities/expansions.lua").IsGenerated() then
                WARN("AI raid behavior requires generated expansion markers")
                self:ChangeState('Error')
                return
            end

            -- requires navigational mesh
            if not NavUtils.IsGenerated() then
                WARN("AI raid behavior requires navigational mesh")
                self:ChangeState('Error')
                return
            end

            self:ChangeState('Searching')
        end,
    },

    Searching = State {
        --- The platoon searches for a target
        ---@param self AIPlatoonRaid
        Main = function(self)
            LOG(tostring(self) .. " - Searching")

            -- reset state
            self.LocationToRaid = nil
            self.OpportunityToRaid = nil

            -- pick random unit
            local units = self:GetPlatoonUnits()
            local unit = units[Random(1, TableGetn(units))]

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
                    WARN(string.format("AI raid behavior expansion error: no expansion markers on navigational label (%d)", label))
                    self:ChangeState('Error')
                end

                -- pick random expansion that we can Navigating to
                local expansion = candidates[Random(1, count)]
                self.LocationToRaid = expansion.position
                self:ChangeState('Navigating')
            else
                -- something odd happened: try again with another unit
                WARN(string.format("AI raid behavior label error: %s", error))
                self:ChangeState('Searching')
            end
        end,
    },

    Navigating = State {
        --- The platoon navigates towards a target, picking up oppertunities as it finds them
        ---@param self AIPlatoonRaid
        Main = function(self)
            LOG(tostring(self) .. " - Navigating")

            -- reset state
            self.OpportunityToRaid = nil

            -- sanity check
            local destination = self.LocationToRaid
            if not destination then
                WARN(string.format("AI raid behavior Navigating error: no location defined to Navigating to"))
                self:ChangeState('Searching')
                return
            end

            local brain = self:GetBrain()

            while not IsDestroyed(self) do
                -- pick random unit for a position on the grid
                local units = self:GetPlatoonUnits()
                local unit = units[Random(1, TableGetn(units))]
                local origin = unit:GetPosition()

                -- generate a path
                local path, n, distance = NavUtils.PathTo('Land', origin, destination)

                if not path then
                    WARN(string.format("AI simple raid behavior error: unable to find a path"))
                    self:ChangeState('Searching')
                    return
                end

                -- threshold to start the raid
                if distance < RaidDistanceThreshold then
                    self:ChangeState('RaidingTarget')
                    return
                end

                -- determine waypoint
                local waypoint = path[2] or path[1]
                if not waypoint then
                    self:ChangeState('RaidingTarget')
                    return
                end

                -- TODO
                -- use the pathing introduced by #3134
                self:MoveToLocation(waypoint, false, 'Attack')
                -- END OF TODO

                -- check for opportunities
                local wx = waypoint[1]
                local wz = waypoint[3]
                while not IsDestroyed(self) do
                    local position = self:GetPlatoonPosition()
                    local dx = position[1] - wx
                    local dz = position[3] - wz
                    if dx * dx + dz * dz < NavigateDistanceThresholdSquared then
                        break
                    end

                    -- check for opportunities
                    local position = self:GetPlatoonPosition()
                    local opportunities = brain:GetUnitsAroundPoint(valuableCategories, position, 20, 'Enemy')
                    if opportunities and not TableEmpty(opportunities) then

                        -- pick random opportunity and raid it
                        local opportunity = opportunities[Random(1, TableGetn(opportunities))]
                        self.OpportunityToRaid = opportunity:GetPosition()
                        self:ChangeState('Raiding')
                    end

                    -- check for threats
                    local threat = brain:GetThreatAtPosition(position, 1, true, 'AntiSurface')
                    if threat > 0 then
                        local threatTable = brain:GetThreatsAroundPosition(position, 1, true, 'AntiSurface')
                        if not table.empty(threatTable) then
                            reprsl(threatTable)
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
        ---@param self AIPlatoonRaid
        Main = function(self)
            LOG(tostring(self) .. " - RaidingTarget")

            local brain = self:GetBrain()

            -- sanity check
            local location = self.LocationToRaid
            if not location then
                WARN(string.format("AI raid behavior error: no location to raid"))
                self:ChangeState('Searching')
                return
            end

            while not IsDestroyed(self) do


                WaitSeconds(2.0)
            end
        end,
    },

    RaidingOpportunity = State {
        --- The platoon raids the opportunity it walked into
        ---@param self AIPlatoonRaid
        Main = function(self)
            LOG(tostring(self) .. " - RaidingOpportunity")

            local brain = self:GetBrain()

            -- sanity check
            local location = self.OpportunityToRaid
            if not location then
                WARN(string.format("AI raid behavior error: no opportunity to raid"))
                self:ChangeState('Navigating')
            end

            while not IsDestroyed(self) do



                WaitSeconds(2.0)
            end
        end,
    },

    Retreating = State {

        --- The platoon retreats from a threat
        ---@param self AIPlatoonRaid
        Main = function(self)
            LOG(tostring(self) .. " - Retreating")

            local brain = self:GetBrain()

            -- sanity check
            local location = self.OpportunityToRaid
            if not location then
                WARN(string.format("AI raid behavior error: no opportunity to raid"))
                self:ChangeState('Navigating')
            end

            while not IsDestroyed(self) do



                WaitSeconds(2.0)
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
        local scouts = self:GetSquadUnits('Scout')
        if scouts then
            for k, scout in scouts do
                cache[1] = scout
                IssueClearCommands(cache)
                IssueGuard(cache, units[Random(1, count)])
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
        -- create the platoon
        local brain = units[1].Brain
        local platoon = brain:MakePlatoon('', '') --[[@as AIPlatoonRaid]]
        setmetatable(platoon, AIPlatoonRaid)

        -- assign units to squads
        local scouts = EntityCategoryFilterDown(categories.SCOUT, units)
        local others = EntityCategoryFilterDown(categories.ALLUNITS - categories.SCOUT, units)
        brain:AssignUnitsToPlatoon(platoon, others, 'Attack', 'None')
        brain:AssignUnitsToPlatoon(platoon, scouts, 'Scout', 'None')

        -- start the behavior
        ChangeState(platoon, platoon.Start)
    end
end



