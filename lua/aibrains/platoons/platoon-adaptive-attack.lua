
local AIPlatoon = import("/lua/aibrains/platoons/platoon-base.lua").AIPlatoon
local NavUtils = import("/lua/sim/navutils.lua")
local MarkerUtils = import("/lua/sim/markerutilities.lua")
local TransportUtils = import("/lua/ai/transportutilities.lua")
local AIAttackUtils = import("/lua/ai/aiattackutilities.lua")

-- upvalue scope for performance
local Random = Random
local IsDestroyed = IsDestroyed

local TableGetn = table.getn
local TableEmpty = table.empty

-- constants
local NavigateDistanceThresholdSquared = 20 * 20

---@class AIPlatoonAdaptiveAttackBehavior : AIPlatoon
---@field RetreatCount number 
---@field ThreatToEvade Vector | nil
---@field LocationToAttack Vector | nil
---@field OpportunityToAttack Vector | nil
AIPlatoonAdaptiveAttackBehavior = Class(AIPlatoon) {

    PlatoonName = 'AdaptiveAttackBehavior',

    Start = State {

        StateName = 'Start',

        --- Initial state of any state machine
        ---@param self AIPlatoonAdaptiveAttackBehavior
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

            -- Set the movement layer for pathing, included for mods where water or air based engineers may exist
            self.MovementLayer = self:GetNavigationalLayer()

            self:ChangeState(self.Searching)
            return
        end,
    },

    Searching = State {

        StateName = 'Searching',

        --- The platoon searches for a target
        ---@param self AIPlatoonAdaptiveAttackBehavior
        Main = function(self)
            -- reset state
            self.LocationToAttack = nil
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
                local target = self:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS - categories.WALL - categories.AIR)
                if target then
                    self.TargetToAttack = target
                    self.LocationToAttack = table.copy(target:GetPosition())
                    IssueClearCommands(units)
                    self:ChangeState(self.Navigating)
                else
                    WaitTicks(50)
                    self:ChangeState(self.Searching)
                end
                return
            else
                -- something odd happened: try again with another unit
                self:LogWarning(string.format('no label found', label))
                self:ChangeState(self.Searching)
                return
            end
        end,
    },

    Navigating = State {

        StateName = 'Navigating',

        --- The platoon navigates towards a target, picking up oppertunities as it finds them
        ---@param self AIPlatoonAdaptiveAttackBehavior
        Main = function(self)
            -- reset state
            self.OpportunityToRaid = nil
            self.ThreatToEvade = nil

            -- sanity check
            local destination = self.LocationToAttack
            if not destination then
                self:LogWarning(string.format('no destination to navigate to'))
                self:ChangeState(self.Searching)
                return
            end

            self:Stop()

            local cache = { 0, 0, 0 }
            local brain = self:GetBrain()
            if not brain.GridPresence then
                WARN('GridPresence does not exist, unable to detect conflict line')
            end

            if not NavUtils.CanPathToCell(self.MovementLayer, self:GetPlatoonPosition(), destination) then
                self:LogDebug(string.format('Attack platoon is going to use transport'))
                self:ChangeState(self.Transporting)
                return
            end

            while not IsDestroyed(self) do
                -- pick random unit for a position on the grid
                local units = self:GetPlatoonUnits()
                local origin
                for _, v in units do
                    if v and not v.Dead then
                        origin = v:GetPosition()
                    end
                end

                -- generate a direction
                local waypoint, length = NavUtils.DirectionTo('Land', origin, destination, 60)

                -- something odd happened: no direction found
                if not waypoint then
                    self:LogWarning(string.format('no path found'))
                    self:ChangeState(self.Searching)
                    return
                end

                -- we're near the destination, better start attacking it!
                if waypoint == destination then
                    self:ChangeState(self.AttackingTarget)
                    return
                end

                -- navigate towards waypoint 
                --local dx = origin[1] - waypoint[1]
                --local dz = origin[3] - waypoint[3]
                --local d = math.sqrt(dx * dx + dz * dz)
                --self:IssueFormMoveToWaypoint(units, origin, waypoint)
                self:AggressiveMoveToLocation(waypoint)

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
                        local platoonThreat = self:CalculatePlatoonThreatAroundPosition('Surface', categories.MOBILE * categories.DIRECTFIRE - categories.SCOUT, position, 30)
                        local positionStatus = brain.GridPresence:GetInferredStatus(position)
                        if platoonThreat * 2 < threat then
                            if threatTable and not TableEmpty(threatTable) then
                                local info = threatTable[Random(1, TableGetn(threatTable))]
                                self.ThreatToEvade = { info[1], GetSurfaceHeight(info[1], info[2]), info[2] }
                                DrawCircle(self.ThreatToEvade, 5, 'ff0000')
                                self:LogDebug(string.format('We are going to retreat, enemy threat '..threat..' our threat '..platoonThreat..' position status '..positionStatus))
                                self:ChangeState(self.Retreating)
                                return
                            end
                        elseif positionStatus then
                            self:LogDebug(string.format('We are going to attack, enemy threat '..threat..' our threat '..platoonThreat..' position status '..positionStatus))
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

                    WaitTicks(10)
                end

                -- always wait
                WaitTicks(1)
            end
        end,
    },

    Transporting = State {

        StateName = 'Transporting',

        --- The platoon avoids danger or attempts to reclaim if they are too close to avoid
        ---@param self AIPlatoonAdaptiveAttackBehavior
        Main = function(self)
            local brain = self:GetBrain()
            local usedTransports = TransportUtils.SendPlatoonWithTransports(brain, self, self.LocationToAttack, 1, false)
            if usedTransports then
                self:LogDebug(string.format('Attack Platoon used transports'))
                self:ChangeState(self.Navigating)
            else
                self:LogDebug(string.format('Attack Platoon didnt use transports'))
                self:ChangeState(self.Searching)
            end
            return
        end,
    },

    AttackingTarget = State {

        StateName = 'AttackingTarget',

        --- The platoon attacks the target
        ---@param self AIPlatoonAdaptiveAttackBehavior
        Main = function(self)
            local brain = self:GetBrain()

            -- sanity check
            local location = self.LocationToAttack
            if not location then
                self:LogWarning(string.format('no location to attack'))
                self:ChangeState(self.Searching)
                return
            end

            self:Stop()
            local command = self:AggressiveMoveToLocation(location)

            while not IsDestroyed(self) do

                -- check if there is something to attack
                if not self.TargetToAttack or IsDestroyed(self.TargetToAttack) then
                    self:ChangeState(self.Searching)
                    return
                end

                -- check for threats
                local position = self:GetPlatoonPosition()
                local threat = brain:GetThreatAtPosition(position, 1, true, 'AntiSurface')
                if threat > 0 then
                    local threatTable = brain:GetThreatsAroundPosition(position, 1, true, 'AntiSurface')
                    local platoonThreat = self:CalculatePlatoonThreatAroundPosition('Surface', categories.MOBILE * categories.DIRECTFIRE - categories.SCOUT, position, 30)
                    local positionStatus = brain.GridPresence:GetInferredStatus(position)
                    if platoonThreat * 2 < threat then
                        if threatTable and not TableEmpty(threatTable) then
                            local info = threatTable[Random(1, TableGetn(threatTable))]
                            self.ThreatToEvade = { info[1], GetSurfaceHeight(info[1], info[2]), info[2] }
                            DrawCircle(self.ThreatToEvade, 5, 'ff0000')
                            self:ChangeState(self.Retreating)
                            return
                        end
                    else
                        self:LogDebug(string.format('Threat and we need to attack then since it is allied, status '..positionStatus))
                    end
                end

                -- check if our command is still going
                if not self:IsCommandsActive(command) then
                    self:ChangeState(self.Searching)
                    return
                end

                WaitTicks(10)
            end
        end,
    },

    RaidingOpportunity = State {

        StateName = 'RaidingOpportunity',

        --- The platoon raids the opportunity it walked into
        ---@param self AIPlatoonAdaptiveAttackBehavior
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
                local threat = brain:GetThreatAtPosition(position, 1, true, 'AntiSurface')
                if threat > 0 then
                    local threatTable = brain:GetThreatsAroundPosition(position, 1, true, 'AntiSurface')
                    local platoonThreat = self:CalculatePlatoonThreatAroundPosition('Surface', categories.MOBILE * categories.DIRECTFIRE - categories.SCOUT, position, 30)
                    local positionStatus = brain.GridPresence:GetInferredStatus(position)
                    if positionStatus != 'Allied' or platoonThreat * 2 < threat then
                        if threatTable and not TableEmpty(threatTable) then
                            local info = threatTable[Random(1, TableGetn(threatTable))]
                            self.ThreatToEvade = { info[1], GetSurfaceHeight(info[1], info[2]), info[2] }
                            DrawCircle(self.ThreatToEvade, 5, 'ff0000')
                            self:ChangeState(self.Retreating)
                            return
                        end
                    else
                        self:LogDebug(string.format('Threat and we need to attack then since it is allied, status '..positionStatus))
                    end
                end

                -- check if our command is still going
                if not self:IsCommandsActive(attackCommand) then
                    -- setup attack units
                    local attackOffset, error = NavUtils.RandomDirectionFrom('Land', location, 10, 8)       -- TODO: remove magic numbers
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
        ---@param self AIPlatoonAdaptiveAttackBehavior
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
                            self:ChangeState(self.Navigating)
                        else
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

---@param data { Behavior: 'AIPlatoonAdaptiveAttackBehavior' }
---@param units Unit[]
DebugAssignToUnits = function(data, units)
    if units and not TableEmpty(units) then

        -- meet platoon requirements
        import("/lua/sim/navutils.lua").Generate()

        -- create the platoon
        local brain = units[1].Brain
        local platoon = brain:MakePlatoon('', '') --[[@as AIPlatoonAdaptiveAttackBehavior]]
        setmetatable(platoon, AIPlatoonAdaptiveAttackBehavior)

        -- assign units to squads
        local scouts = EntityCategoryFilterDown(categories.SCOUT, units)
        local others = EntityCategoryFilterDown(categories.ALLUNITS - categories.SCOUT, units)
        brain:AssignUnitsToPlatoon(platoon, others, 'Attack', 'None')
        brain:AssignUnitsToPlatoon(platoon, scouts, 'Scout', 'None')

        -- start the behavior
        ChangeState(platoon, platoon.Start)
    end
end

---@param data { Behavior: 'AIPlatoonAdaptiveAttackBehavior' }
---@param units Unit[]
AssignToUnitsMachine = function(data, platoon, units)
    if units and not TableEmpty(units) then

        -- meet platoon requirements
        import("/lua/sim/navutils.lua").Generate()
        -- create the platoon
        setmetatable(platoon, AIPlatoonAdaptiveAttackBehavior)
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



