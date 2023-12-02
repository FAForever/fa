
local AIPlatoon = import("/lua/aibrains/platoons/platoon-base.lua").AIPlatoon
local NavUtils = import("/lua/sim/navutils.lua")
local MarkerUtils = import("/lua/sim/markerutilities.lua")
local TransportUtils = import("/lua/ai/transportutilities.lua")

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

            -- determine navigational label of that unit
            local position = self:GetPlatoonPosition()
            if not position then
                return
            end

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
                if not platPos then
                    return
                end

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
                WaitTicks(20)
                self:ChangeState(self.Searching)
                return
            end

            self:Stop()

            if not self.CurrentPlatoonThreat then
                self.CurrentPlatoonThreat = self:CalculatePlatoonThreat('Surface', categories.ALLUNITS)
            end
            local units = self:GetPlatoonUnits()
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
            local pathNodesCount = TableGetn(path)
            local attackFormation = false
            for i=1, pathNodesCount do
                if self.Dead then
                    return
                end
                local distEnd
                self:MoveToLocation(path[i], false)
                local Lastdist
                local dist
                local Stuck = 0
                while not IsDestroyed(self) do
                    coroutine.yield(1)
                    if self.Dead then
                        return
                    end
                    local position = self:GetPlatoonPosition()
                    if not position then
                        return
                    end

                    units = self:GetPlatoonUnits()

                    -- check for opportunities
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
                    -- No, we are not moving, wait 15 ticks then break and use the next weaypoint
                    else
                        Stuck = Stuck + 1
                        if Stuck > 15 then
                            WaitTicks(15)
                            self:Stop()
                            break
                        end
                    end
                    --LOG('Lastdist '..Lastdist..' dist '..dist)
                    coroutine.yield(15)
                end
            end
            local position = self:GetPlatoonPosition()
            if not position then
                return
            end

            units = self:GetPlatoonUnits()
            local hx = position[1] - destination[1]
            local hz = position[3] - destination[3]
            if hx * hx + hz * hz < 3600 then
                self:ExitStateMachine()
                return
            end
            self:ChangeState(self.Searching)
            return
        end,
    },

    Transporting = State {

        StateName = 'Transporting',

        --- The platoon avoids danger or attempts to reclaim if they are too close to avoid
        ---@param self AIPlatoonAdaptiveReturnToBaseBehavior
        Main = function(self)
            local brain = self:GetBrain()
            local usedTransports = TransportUtils.SendPlatoonWithTransports(brain, self, self.LocationToReturn, 3, false)
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
                    WaitTicks(10)
                    self:ChangeState(self.Searching)
                    return
                end

                -- check if our command is still going
                if not self:IsCommandsActive(command) then
                    local units, unitCount = self:GetPlatoonUnits()
                    IssueClearCommands(units)
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



