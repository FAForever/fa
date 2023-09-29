
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

---@class AIPlatoonAdaptiveReturnToBaseBehavior : AIPlatoon
---@field RetreatCount number 
AIPlatoonAdaptiveReturnToBaseBehavior = Class(AIPlatoon) {

    PlatoonName = 'AdaptiveReturnToBaseBehavior',

    Start = State {

        StateName = 'Start',

        --- Initial state of any state machine
        ---@param self AIPlatoonAdaptiveReturnToBaseBehavior
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
        ---@param self AIPlatoonAdaptiveReturnToBaseBehavior
        Main = function(self)
            -- reset state
            self.BasePositionToReturn = nil
            self.RetreatCount = 0
            local brain = self:GetBrain()

            self:Stop()

            -- pick random unit
            local units, unitCount = self:GetPlatoonUnits()
            local unit = units[Random(1, unitCount)]

            -- determine navigational label of that unit
            local position = unit:GetPosition()

            --Guard the closest least-defended base
            local bestBase = false
            local bestDistSq

            for baseName, base in brain.BuilderManagers do
                local distSq = VDist2Sq(position[1], position[3], base.Position[1], base.Position[3])
                if not bestDistSq or distSq < bestDistSq then
                    bestBase = base
                    bestDistSq = distSq
                end
            end

            if bestBase then
                local platPos = self:GetPlatoonPosition()
                local dx = platPos[1] - bestBase.Position[1]
                local dz = platPos[3] - bestBase.Position[3]
                if dx * dx + dz * dz > 3600 then
                    self.LocationToReturn = bestBase.Position
                    self:ChangeState(self.Navigating)
                    return
                else
                    self:ExitStateMachine()
                    return
                end
            end
        end,
    },

    Navigating = State {

        StateName = 'Navigating',

        --- The platoon navigates towards a target, picking up oppertunities as it finds them
        ---@param self AIPlatoonAdaptiveReturnToBaseBehavior
        Main = function(self)

            -- sanity check
            local destination = self.LocationToReturn
            if not destination then
                self:LogWarning(string.format('no destination to navigate to'))
                self:ChangeState(self.Searching)
                return
            end

            self:Stop()

            local cache = { 0, 0, 0 }
            local brain = self:GetBrain()

            if not NavUtils.CanPathToCell(self.MovementLayer, self:GetPlatoonPosition(), destination) then
                self:LogDebug(string.format('ReturnToBase platoon is going to use transport'))
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
                local waypoint, length = NavUtils.DirectionTo('Land', origin, destination, 30)

                -- something odd happened: no direction found
                if not waypoint then
                    self:LogWarning(string.format('no path found'))
                    self:ChangeState(self.Searching)
                    return
                end

                -- we're near the destination
                if waypoint == destination then
                    self:ChangeState(self.Searching)
                    return
                end

                self:MoveToLocation(waypoint, false)

                -- check for opportunities
                local wx = waypoint[1]
                local wz = waypoint[3]
                while not IsDestroyed(self) do
                    local position = self:GetPlatoonPosition()

                    -- check if we're near our current waypoint
                    local dx = position[1] - wx
                    local dz = position[3] - wz
                    if dx * dx + dz * dz < NavigateDistanceThresholdSquared then
                        self:ChangeState(self.Searching)
                        return
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
        ---@param self AIPlatoonAdaptiveReturnToBaseBehavior
        Main = function(self)
            local brain = self:GetBrain()
            local usedTransports = TransportUtils.SendPlatoonWithTransports(brain, self, self.LocationToReturn, 1, false)
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
        ---@param self AIPlatoonAdaptiveReturnToBaseBehavior
        Main = function(self)
            local brain = self:GetBrain()

            -- sanity check
            local attackTarget = self.TargetToAttack

            if not attackTarget or IsDestroyed(attackTarget) then
                self:LogWarning(string.format('no target to attack'))
                self:ChangeState(self.Searching)
                return
            end

            self:Stop()
            local command = self:AggressiveMoveToLocation(attackTarget:GetPosition())

            while not IsDestroyed(self) do

                -- check if there is something to attack
                if not attackTarget or IsDestroyed(attackTarget) then
                    self:ChangeState(self.Searching)
                    return
                end

                -- check if our command is still going
                if not self:IsCommandsActive(command) then
                    IssueClearCommands(self:GetPlatoonUnits())
                    self:ChangeState(self.Navigating)
                    return
                end
                WaitTicks(25)
            end
        end,
    },

    Retreating = State {

        StateName = "Retreating",

        --- The platoon retreats from a threat
        ---@param self AIPlatoonAdaptiveReturnToBaseBehavior
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

---@param data { Behavior: 'AIPlatoonAdaptiveReturnToBaseBehavior' }
---@param units Unit[]
DebugAssignToUnits = function(data, units)
    if units and not TableEmpty(units) then

        -- meet platoon requirements
        import("/lua/sim/navutils.lua").Generate()

        -- create the platoon
        local brain = units[1].Brain
        local platoon = brain:MakePlatoon('', '') --[[@as AIPlatoonAdaptiveReturnToBaseBehavior]]
        setmetatable(platoon, AIPlatoonAdaptiveReturnToBaseBehavior)

        -- assign units to squads
        local scouts = EntityCategoryFilterDown(categories.SCOUT, units)
        local others = EntityCategoryFilterDown(categories.ALLUNITS - categories.SCOUT, units)
        brain:AssignUnitsToPlatoon(platoon, others, 'Attack', 'None')
        brain:AssignUnitsToPlatoon(platoon, scouts, 'Scout', 'None')

        -- start the behavior
        ChangeState(platoon, platoon.Start)
    end
end

---@param data { Behavior: 'AIPlatoonAdaptiveReturnToBaseBehavior' }
---@param units Unit[]
AssignToUnitsMachine = function(data, platoon, units)
    if units and not TableEmpty(units) then

        -- meet platoon requirements
        import("/lua/sim/navutils.lua").Generate()
        -- create the platoon
        setmetatable(platoon, AIPlatoonAdaptiveReturnToBaseBehavior)
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



