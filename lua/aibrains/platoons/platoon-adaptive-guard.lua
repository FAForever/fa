
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
local NavigateDistanceThresholdSquared = 25 * 25

---@class AIPlatoonAdaptiveGuardBehavior : AIPlatoon
---@field RetreatCount number 
---@field ThreatToEvade Vector | nil
---@field LocationToAttack Vector | nil
---@field OpportunityToAttack Vector | nil
AIPlatoonAdaptiveGuardBehavior = Class(AIPlatoon) {

    PlatoonName = 'AdaptiveGuardBehavior',

    Start = State {

        StateName = 'Start',

        --- Initial state of any state machine
        ---@param self AIPlatoonAdaptiveGuardBehavior
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

            if self.PlatoonData.LocationType then
                self.LocationType = self.PlatoonData.LocationType
            else
                self.LocationType = 'MAIN'
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
        ---@param self AIPlatoonAdaptiveGuardBehavior
        Main = function(self)
            -- reset state
            self.LocationToAttack = nil
            self.OpportunityToRaid = nil
            self.ThreatToEvade = nil
            self.RetreatCount = 0
            local brain = self:GetBrain()

            self:Stop()

            -- determine navigational label of that unit
            local position = self:GetPlatoonPosition()
            if not position then
                return
            end

            local label, error = NavUtils.GetLabel('Land', position)

            if label then
                if not self.PlatoonData.NeverGuardBases then
                    --Guard the closest least-defended base
                    local bestBase = false
                    local bestDistSq = 999999999
                    local bestDefense = 999999999
        
                    local MAIN = brain.BuilderManagers.MAIN
        
                    local threatType = 'AntiSurface'
                    for baseName, base in brain.BuilderManagers do
                        if baseName != 'MAIN' and (base.BaseSettings and not base.BaseSettings.NoGuards) then
        
                            if AIAttackUtils.GetSurfaceThreatOfUnits(self) <= 0 then
                                threatType = 'StructuresNotMex'
                            end
        
                            local defStructures = brain:GetUnitsAroundPoint(categories.STRUCTURE * categories.DEFENSE,  base.Position, 120, 'Ally')
                            local defThreat = 0
                            for _, v in defStructures do
                                defThreat = defThreat + v.Blueprint.Defense.SurfaceThreatLevel
                            end
        
                            local distSq = VDist2Sq(MAIN.Position[1], MAIN.Position[3], base.Position[1], base.Position[3])
        
                            if baseDefense < bestDefense then
                                bestBase = base
                                bestDistSq = distSq
                                bestDefense = baseDefense
                            elseif baseDefense == bestDefense then
                                if distSq < bestDistSq then
                                    bestBase = base
                                    bestDistSq = distSq
                                end
                            end
                        end
                    end
        
                    local threshold = 10
                    if bestBase.BaseSettings then
                        threshold = bestBase.BaseSettings.DesiredGuardThreat or 10
                    end
        
                    if bestBase and bestDefense < threshold then
                        self.LocationToGuard = bestBase.Position
                        local platPos = self:GetPlatoonPosition()
                        if not platPos then
                            return
                        end


                        local guardPos = unitToGuard:GetPosition()
                        local dx = platPos[1] - guardPos[1]
                        local dz = platPos[3] - guardPos[3]
                        if dx * dx + dz * dz > 3600 then
                            self.UnitToGuard = unitToGuard
                            self.LocationToGuard = bestBase.Position
                            self:ChangeState(self.Navigating)
                            return
                        else
                            self.LocationToGuard = bestBase.Position
                            self:ChangeState(self.GuardBase)
                            return
                        end
                    end
                end
        
                if not self.PlatoonData.NeverGuardEngineers then
                    --Otherwise guard an engineer until it dies or our guard timer expires
                    local unitToGuard = false
                    local units = brain:GetListOfUnits(categories.ENGINEER - categories.COMMAND, false)
                    for k,v in units do
                        if v and not v.Dead then
                            if v.NeedGuard and not v.BeingGuarded and NavUtils.CanPathTo(self.MovementLayer, position, v:GetPosition())then
                                unitToGuard = v
                                v.BeingGuarded = true
                            end
                        end
                    end
        
                    if unitToGuard and not unitToGuard.Dead then
                        local platPos = self:GetPlatoonPosition()
                        if not platPos then
                            return
                        end

                        local guardPos = unitToGuard:GetPosition()
                        local dx = platPos[1] - guardPos[1]
                        local dz = platPos[3] - guardPos[3]
                        if dx * dx + dz * dz > 3600 then
                            self.UnitToGuard = unitToGuard
                            self.LocationToGuard = unitToGuard:GetPosition()
                            self:ChangeState(self.Navigating)
                            return
                        else
                            self.UnitToGuard = unitToGuard
                            self:ChangeState(self.GuardUnit)
                            return
                        end
                    end
        
                end
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
        ---@param self AIPlatoonAdaptiveGuardBehavior
        Main = function(self)

            -- sanity check
            local unitToGuard = self.UnitToGuard
            local destination = self.LocationToGuard
            if not destination then
                self:LogWarning(string.format('no destination to navigate to'))
                self:ChangeState(self.Searching)
                return
            end

            self:Stop()

            local brain = self:GetBrain()
            if not brain.GridPresence then
                WARN('GridPresence does not exist, unable to detect conflict line')
            end

            local position = self:GetPlatoonPosition()
            if not position then
                return
            end

            if not NavUtils.CanPathToCell(self.MovementLayer, position, destination) then
                self:LogDebug(string.format('Attack platoon is going to use transport'))
                self:ChangeState(self.Transporting)
                return
            end

            while not IsDestroyed(self) do
                local origin = self:GetPlatoonPosition()
                if not origin then
                    return
                end

                if unitToGuard and not IsDestroyed(unitToGuard) then
                    destination = unitToGuard:GetPosition()
                end

                -- generate a direction
                local waypoint, length = NavUtils.DirectionTo('Land', origin, destination, 60)

                -- something odd happened: no direction found
                if not waypoint then
                    self:LogWarning(string.format('no path found'))
                    self:ChangeState(self.Searching)
                    return
                end

                -- we're near the destination
                if waypoint == destination then
                    self:ChangeState(self.AttackingTarget)
                    return
                end

                self:AggressiveMoveToLocation(waypoint)

                -- check for opportunities
                local wx = waypoint[1]
                local wz = waypoint[3]
                while not IsDestroyed(self) do
                    local position = self:GetPlatoonPosition()
                    if not position then
                        return
                    end

                    -- check if we're near our current waypoint
                    local dx = position[1] - wx
                    local dz = position[3] - wz
                    if dx * dx + dz * dz < NavigateDistanceThresholdSquared then
                        break
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
        ---@param self AIPlatoonAdaptiveGuardBehavior
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
        ---@param self AIPlatoonAdaptiveGuardBehavior
        Main = function(self)
            local brain = self:GetBrain()

            -- sanity check
            local attackTarget = self.TargetToAttack
            local unitToGuard = self.UnitToGuard
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

                if not unitToGuard or IsDestroyed(unitToGuard) then
                    self:ChangeState(self.Searching)
                    return
                end
                local enemyUnitPos = attackTarget:GetPosition()
                local guardUnitPos = unitToGuard:GetPosition()
                local dx = guardUnitPos[1] - enemyUnitPos[1]
                local dz = guardUnitPos[3] - enemyUnitPos[3]
                if dx * dx + dz * dz > 3025 then
                    local units, unitCount = self:GetPlatoonUnits()
                    IssueClearCommands(units)
                    IssueMove(units, guardUnitPos)
                    coroutine.yield(30)
                    if not IsDestroyed(unitToGuard) then
                        self:ChangeState(self.GuardUnit)
                        return
                    else
                        self:ChangeState(self.Searching)
                        return
                    end
                end
                -- check if our command is still going
                if not self:IsCommandsActive(command) then
                    if not IsDestroyed(unitToGuard) then
                        coroutine.yield(10)
                        self:ChangeState(self.GuardUnit)
                        return
                    else
                        coroutine.yield(10)
                        self:ChangeState(self.Searching)
                        return
                    end
                end
                WaitTicks(10)
            end
        end,
    },

    GuardUnit = State {

        StateName = 'GuardUnit',

        --- The platoon raids the opportunity it walked into
        ---@param self AIPlatoonAdaptiveGuardBehavior
        Main = function(self)
            local brain = self:GetBrain()
            local unitToGuard = self.UnitToGuard
            if unitToGuard and not unitToGuard.Dead then

                -- sanity check
                local units = self:GetPlatoonUnits()
                IssueGuard(units, unitToGuard)
                local guardTime = 0
                while brain:PlatoonExists(self) and not unitToGuard.Dead do
                    local guardUnitPos = unitToGuard:GetPosition()
                    local enemyCount = brain:GetNumUnitsAroundPoint(categories.LAND * categories.MOBILE, guardUnitPos, 45, 'Enemy')
                    if enemyCount > 0 then
                        local enemyUnits = brain:GetUnitsAroundPoint(categories.LAND * categories.MOBILE, guardUnitPos, 45, 'Enemy')
                        local closestUnit
                        local closestDistance
                        for _, eunit in enemyUnits do
                            if eunit and not eunit.Dead then
                                local ePos = eunit:GetPosition()
                                local dx = guardUnitPos[1] - ePos[1]
                                local dz = guardUnitPos[3] - ePos[3]
                                local distance = dx * dx + dz * dz
                                if not closestDistance or distance < closestDistance then
                                    closestDistance = distance
                                    closestUnit = eunit
                                end
                            end
                        end
                        if closestUnit and not closestUnit.Dead then
                            self.TargetToAttack = closestUnit
                            self:ChangeState(self.AttackingTarget)
                            return
                        end
                        
                    end
                    guardTime = guardTime + 5
                    WaitTicks(50)
                    
                    if self.PlatoonData.EngineerGuardTimeLimit and guardTime >= self.PlatoonData.EngineerGuardTimeLimit
                    or (not unitToGuard.Dead and unitToGuard.Layer == 'Seabed' and self.MovementLayer == 'Land') then
                        local units, unitCount = self:GetPlatoonUnits()
                        IssueClearCommands(units)
                        coroutine.yield(10)
                        self:ChangeState(self.Searching)
                        return
                    end
                    if self.ExitGuard then
                        local plat = brain:MakePlatoon('', '')
                        local units = self:GetPlatoonUnits()
                        brain:AssignUnitsToPlatoon(plat, units, 'attack', 'None')
                        import("/lua/aibrains/platoons/platoon-adaptive-returntobase.lua").AssignToUnitsMachine({ LocationType = self.LocationType}, plat, units)
                        return
                    end
                end
            else
                local units, unitCount = self:GetPlatoonUnits()
                IssueClearCommands(units)
                coroutine.yield(10)
                self:ChangeState(self.Searching)
                return
            end
        end,
    },

    GuardBase = State {

        StateName = 'GuardBase',

        --- The platoon raids the opportunity it walked into
        ---@param self AIPlatoonAdaptiveGuardBehavior
        Main = function(self)
            local brain = self:GetBrain()
            local baseToGuardPos = self.LocationToGuard
            if baseToGuardPos then
                -- sanity check
                local units, unitCount = self:GetPlatoonUnits()
                IssueGuard(units, baseToGuardPos)
                local guardTime = 0
                local rnd = Random(13,17)
                WaitSeconds(rnd)
                guardTime = guardTime + rnd
                while brain:PlatoonExists(self) do
                    local enemyCount = brain:GetNumUnitsAroundPoint(categories.LAND * categories.MOBILE, baseToGuardPos, 120, 'Enemy')
                    if enemyCount > 0 then
                        local enemyUnits = brain:GetUnitsAroundPoint(categories.LAND * categories.MOBILE, baseToGuardPos, 120, 'Enemy')
                        local closestUnit
                        local closestDistance
                        for _, eunit in enemyUnits do
                            if eunit and not eunit.Dead then
                                local ePos = eunit:GetPosition()
                                local dx = baseToGuardPos[1] - ePos[1]
                                local dz = baseToGuardPos[3] - ePos[3]
                                local distance = dx * dx + dz * dz
                                if not closestDistance or distance < closestDistance then
                                    closestDistance = distance
                                    closestUnit = eunit
                                end
                            end
                        end
                        if closestUnit and not closestUnit.Dead then
                            self.TargetToAttack = closestUnit
                            self:ChangeState(self.AttackingTarget)
                            return
                        end
                        
                    end
                    if self:CalculatePlatoonThreatAroundPosition('Surface', categories.ALLUNITS, baseToGuardPos, 120)
                    or (self.PlatoonData.BaseGuardTimeLimit and guardTime > self.PlatoonData.BaseGuardTimeLimit) then
                        coroutine.yield(10)
                        self:ChangeState(self.Searching)
                        return
                    end
                    guardTime = guardTime + 5
                    WaitTicks(50)
                end
            else
                local units, count = self:GetPlatoonUnits()
                IssueClearCommands(units)
                coroutine.yield(10)
                self:ChangeState(self.Searching)
                return
            end
        end,
    },

    Retreating = State {

        StateName = "Retreating",

        --- The platoon retreats from a threat
        ---@param self AIPlatoonAdaptiveGuardBehavior
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

---@param data { Behavior: 'AIPlatoonAdaptiveGuardBehavior' }
---@param units Unit[]
DebugAssignToUnits = function(data, units)
    if units and not TableEmpty(units) then

        -- meet platoon requirements
        import("/lua/sim/navutils.lua").Generate()

        -- create the platoon
        local brain = units[1].Brain
        local platoon = brain:MakePlatoon('', '') --[[@as AIPlatoonAdaptiveGuardBehavior]]
        setmetatable(platoon, AIPlatoonAdaptiveGuardBehavior)

        -- assign units to squads
        local scouts = EntityCategoryFilterDown(categories.SCOUT, units)
        local others = EntityCategoryFilterDown(categories.ALLUNITS - categories.SCOUT, units)
        brain:AssignUnitsToPlatoon(platoon, others, 'Attack', 'None')
        brain:AssignUnitsToPlatoon(platoon, scouts, 'Scout', 'None')

        -- start the behavior
        ChangeState(platoon, platoon.Start)
    end
end

---@param data { Behavior: 'AIPlatoonAdaptiveGuardBehavior' }
---@param units Unit[]
AssignToUnitsMachine = function(data, platoon, units)
    if units and not TableEmpty(units) then

        -- meet platoon requirements
        import("/lua/sim/navutils.lua").Generate()
        -- create the platoon
        setmetatable(platoon, AIPlatoonAdaptiveGuardBehavior)
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



