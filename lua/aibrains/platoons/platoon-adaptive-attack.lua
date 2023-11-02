
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
local NavigateDistanceThresholdSquared = 35 * 35

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
            if self.PlatoonData.LocationType then
                self.LocationType = self.PlatoonData.LocationType
            else
                self.LocationType = 'MAIN'
            end
            self.MaxTransportDistance = 250
            self.MaxPlatoonCount = 35

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
            self.TargetToAttack = nil
            self.OpportunityToRaid = nil
            self.ThreatToEvade = nil
            self.RetreatCount = 0

            self:Stop()

            local position = self:GetPlatoonPosition()
            if not position then
                return
            end

            local units, unitCount = self:GetPlatoonUnits()
            local label, error = NavUtils.GetLabel('Land', position)

            if label then
                local target = self:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS - categories.WALL - categories.AIR - categories.INSIGNIFICANTUNIT)
                if target and not IsDestroyed(target) then
                    self.TargetToAttack = target
                    local targetPosition = table.copy(target:GetPosition())
                    self.LocationToAttack = targetPosition
                    IssueClearCommands(units)
                    local dx = position[1] - targetPosition[1]
                    local dz = position[3] - targetPosition[3]
                    if dx * dx + dz * dz > 3600 then
                        self:ChangeState(self.Navigating)
                        return
                    else
                        self:ChangeState(self.AttackingTarget)
                        return
                    end
                else
                    WaitTicks(50)
                    self:ChangeState(self.Searching)
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

        StateName = 'Navigating',

        --- The platoon retreats from a threat
        ---@param self AIPlatoonAdaptiveAttackBehavior
        Main = function(self)
            self:LogDebug('Navigating')
            if IsDestroyed(self) then
                return
            end
            self.OpportunityToRaid = nil
            self.ThreatToEvade = nil
            local cache = { 0, 0, 0 }

            -- sanity check
            local destination = self.LocationToAttack
            if not destination then
                self:LogWarning(string.format('no destination to navigate to'))
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
                    if v and not v.Dead then
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
                    coroutine.yield(1)
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
                            if positionStatus != 'Allied' and platoonThreat < threat then
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
            self:ChangeState(self.Searching)
            return
        end,
    },

    Transporting = State {

        StateName = 'Transporting',

        --- The platoon avoids danger or attempts to reclaim if they are too close to avoid
        ---@param self AIPlatoonAdaptiveAttackBehavior
        Main = function(self)
            local brain = self:GetBrain()
            local usedTransports = TransportUtils.SendPlatoonWithTransports(brain, self, self.LocationToAttack, 3, false)
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
                if not position then
                    return
                end

                local threat = brain:GetThreatAtPosition(position, 1, true, 'AntiSurface')
                if threat > 0 then
                    local threatTable = brain:GetThreatsAroundPosition(position, 1, true, 'AntiSurface')
                    local platoonThreat = self:CalculatePlatoonThreatAroundPosition('Surface', categories.MOBILE * categories.DIRECTFIRE - categories.SCOUT, position, 30)
                    local positionStatus = brain.GridPresence:GetInferredStatus(position)
                    if platoonThreat * 2 < threat then
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
                    local index = Random(1, scoutOffsetCount)
                    self:Patrol(scoutOffsets[index], 'Scout')
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
            local platoonUnits, platoonCount = self:GetPlatoonUnits()

            while not IsDestroyed(self) do
                local position = self:GetPlatoonPosition()
                if not position then
                    return
                end

                local waypoint, error = NavUtils.RetreatDirectionFrom('Land', position, location, 40)

                if not waypoint then
                    LOG("Stuck, nowhere to retreat to!")
                    self:ChangeState(self.Error)
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
                                local merged = AIUtils.MergeWithNearbyStatePlatoons(self, 'AdaptiveAttackBehavior', 65, self.MaxPlatoonCount, true)
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



