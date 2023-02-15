
local StandardBrain = import("/lua/aibrain.lua").AIBrain
AIBrain = Class(StandardBrain) {

    ---@param self AIBrain
    ---@param spec any
    BaseMonitorInitializationSorian = function(self, spec)
        ---@class AiBaseMonitor
        self.BaseMonitor = {
            BaseMonitorStatus = 'ACTIVE',
            BaseMonitorPoints = {},
            AlertSounded = false,
            AlertsTable = {},
            AlertLocation = false,
            AlertSoundedThreat = 0,
            ActiveAlerts = 0,

            PoolDistressRange = 75,
            PoolReactionTime = 7,

            -- Variables for checking a radius for enemy units
            UnitRadiusThreshold = spec.UnitRadiusThreshold or 3,
            UnitCategoryCheck = spec.UnitCategoryCheck or (categories.MOBILE - (categories.SCOUT + categories.ENGINEER)),
            UnitCheckRadius = spec.UnitCheckRadius or 40,

            -- Threat level must be greater than this number to sound a base alert
            AlertLevel = spec.AlertLevel or 0,

            -- Delay time for checking base
            BaseMonitorTime = spec.BaseMonitorTime or 11,

            -- Default distance a platoon will travel to help around the base
            DefaultDistressRange = spec.DefaultDistressRange or 75,

            -- Default how often platoons will check if the base is under duress
            PlatoonDefaultReactionTime = spec.PlatoonDefaultReactionTime or 5,

            -- Default duration for an alert to time out
            DefaultAlertTimeout = spec.DefaultAlertTimeout or 10,

            PoolDistressThreshold = 1,

            -- Monitor platoons for help
            PlatoonDistressTable = {},
            PlatoonDistressThread = false,
            PlatoonAlertSounded = false,
        }
        ---@class AiSelfMonitor
        self.SelfMonitor = {
            CheckRadius = spec.SelfCheckRadius or 150,
            ArtyCheckRadius = spec.SelfArtyCheckRadius or 300,
            ThreatRadiusThreshold = spec.SelfThreatRadiusThreshold or 8,
        }
        self:ForkThread(self.BaseMonitorThreadSorian)
    end,

    ---@param self AIBrain
    BaseMonitorThreadSorian = function(self)
        while true do
            if self.BaseMonitor.BaseMonitorStatus == 'ACTIVE' then
                self:SelfMonitorCheck()
                self:BaseMonitorCheck()
            end
            WaitSeconds(self.BaseMonitor.BaseMonitorTime)
        end
    end,

    ---@param self AIBrain
    SelfMonitorCheck = function(self)
        if not self.BaseMonitor.AlertSounded then
            local startlocx, startlocz = self:GetArmyStartPos()
            local threatTable = self:GetThreatsAroundPosition({startlocx, 0, startlocz}, 16, true, 'AntiSurface')
            local artyThreatTable = self:GetThreatsAroundPosition({startlocx, 0, startlocz}, 16, true, 'Artillery')
            local highThreat = false
            local highThreatPos = false
            local radius = self.SelfMonitor.CheckRadius * self.SelfMonitor.CheckRadius
            local artyRadius = self.SelfMonitor.ArtyCheckRadius * self.SelfMonitor.ArtyCheckRadius

            for tIndex, threat in threatTable do
                local enemyThreat = self:GetThreatAtPosition({threat[1], 0, threat[2]}, 0, true, 'AntiSurface')
                local dist = VDist2Sq(threat[1], threat[2], startlocx, startlocz)
                if (not highThreat or enemyThreat > highThreat) and enemyThreat > self.SelfMonitor.ThreatRadiusThreshold and dist < radius then
                    highThreat = enemyThreat
                    highThreatPos = {threat[1], 0, threat[2]}
                end
            end

            if highThreat then
                table.insert(self.BaseMonitor.AlertsTable,
                    {
                    Position = highThreatPos,
                    Threat = highThreat,
                   }
                )
                self:ForkThread(self.BaseMonitorAlertTimeout, highThreatPos)
                self.BaseMonitor.ActiveAlerts = self.BaseMonitor.ActiveAlerts + 1
                self.BaseMonitor.AlertSounded = true
            end

            highThreat = false
            highThreatPos = false
            for tIndex, threat in artyThreatTable do
                local enemyThreat = self:GetThreatAtPosition({threat[1], 0, threat[2]}, 0, true, 'Artillery')
                local dist = VDist2Sq(threat[1], threat[2], startlocx, startlocz)
                if (not highThreat or enemyThreat > highThreat) and enemyThreat > self.SelfMonitor.ThreatRadiusThreshold and dist < artyRadius then
                    highThreat = enemyThreat
                    highThreatPos = {threat[1], 0, threat[2]}
                end
            end

            if highThreat then
                table.insert(self.BaseMonitor.AlertsTable,
                    {
                        Position = highThreatPos,
                        Threat = highThreat,
                    }
                )
                self:ForkThread(self.BaseMonitorAlertTimeout, highThreatPos, 'Artillery')
                self.BaseMonitor.ActiveAlerts = self.BaseMonitor.ActiveAlerts + 1
                self.BaseMonitor.AlertSounded = true
            end
        end
    end,

    ---@param self AIBrain
    ---@param amount number
    ---@param decay number
    ---@param threatType string
    AddInitialEnemyThreatSorian = function(self, amount, decay, threatType)
        local aiBrain = self
        local myArmy = ScenarioInfo.ArmySetup[self.Name]

        if ScenarioInfo.Options.TeamSpawn == 'fixed' then
            -- Spawn locations were fixed. We know exactly where our opponents are.
            for i = 1, 16 do
                local token = 'ARMY_' .. i
                local army = ScenarioInfo.ArmySetup[token]

                if army then
                    if army.ArmyIndex ~= myArmy.ArmyIndex and (army.Team ~= myArmy.Team or army.Team == 1) then
                        local startPos = ScenarioUtils.GetMarker('ARMY_' .. i).position
                        if startPos then
                            self:AssignThreatAtPosition(startPos, amount, decay, threatType or 'Overall')
                        end
                    end
                end
            end
        end
    end,

    ---@param self AIBrain
    ---@param threshold number
    SetupUnderEnergyStatTriggerSorian = function(self, threshold)
        import("/lua/scenariotriggers.lua").CreateArmyStatTrigger(self.UnderEnergyThresholdSorian, self, 'SkirmishUnderEnergyThresholdSorian',
            {
                {
                    StatType = 'Economy_Ratio_Energy',
                    CompareType = 'LessThanOrEqual',
                    Value = threshold,
                },
            }
        )
    end,

    ---@param self AIBrain
    ---@param threshold number
    SetupOverEnergyStatTriggerSorian = function(self, threshold)
        import("/lua/scenariotriggers.lua").CreateArmyStatTrigger(self.OverEnergyThresholdSorian, self, 'SkirmishOverEnergyThresholdSorian',
            {
                {
                    StatType = 'Economy_Ratio_Energy',
                    CompareType = 'GreaterThanOrEqual',
                    Value = threshold,
                },
            }
        )
    end,

    ---@param self AIBrain
    ---@param threshold number
    SetupUnderMassStatTriggerSorian = function(self, threshold)
        import("/lua/scenariotriggers.lua").CreateArmyStatTrigger(self.UnderMassThresholdSorian, self, 'SkirmishUnderMassThresholdSorian',
            {
                {
                    StatType = 'Economy_Ratio_Mass',
                    CompareType = 'LessThanOrEqual',
                    Value = threshold,
                },
            }
        )
    end,

    ---@param self AIBrain
    ---@param threshold number
    SetupOverMassStatTriggerSorian = function(self, threshold)
        import("/lua/scenariotriggers.lua").CreateArmyStatTrigger(self.OverMassThresholdSorian, self, 'SkirmishOverMassThresholdSorian',
            {
                {
                    StatType = 'Economy_Ratio_Mass',
                    CompareType = 'GreaterThanOrEqual',
                    Value = threshold,
                },
            }
        )
    end,

    ---@param self AIBrain
    ParseIntelThreadSorian = function(self)
        if not self.InterestList or not self.InterestList.MustScout then
            error('Scouting areas must be initialized before calling AIBrain:ParseIntelThread.', 2)
        end
        if not self.T4ThreatFound then
            self.T4ThreatFound = {}
        end
        if not self.AttackPoints then
            self.AttackPoints = {}
        end
        if not self.AirAttackPoints then
            self.AirAttackPoints = {}
        end
        if not self.TacticalBases then
            self.TacticalBases = {}
        end

        local intelChecks = {
            -- ThreatType    = {max dist to merge points, threat minimum, timeout (-1 = never timeout), try for exact pos, category to use for exact pos}
            StructuresNotMex = {100, 0, 60, true, categories.STRUCTURE - categories.MASSEXTRACTION},
            Commander = {50, 0, 120, true, categories.COMMAND},
            Experimental = {50, 0, 120, true, categories.EXPERIMENTAL},
            Artillery = {50, 1150, 120, true, categories.ARTILLERY * categories.TECH3},
            Land = {100, 50, 120, false, nil},
        }

        local numchecks = 0
        local checkspertick = 5
        while true do
            local changed = false
            for threatType, v in intelChecks do
                local threats = self:GetThreatsAroundPosition(self.BuilderManagers.MAIN.Position, 16, true, threatType)
                for _, threat in threats do
                    local dupe = false
                    local newPos = {threat[1], 0, threat[2]}
                    numchecks = numchecks + 1
                    for _, loc in self.InterestList.HighPriority do
                        if loc.Type == threatType and VDist2Sq(newPos[1], newPos[3], loc.Position[1], loc.Position[3]) < v[1] * v[1] then
                            dupe = true
                            loc.LastUpdate = GetGameTimeSeconds()
                            break
                        end
                    end

                    if not dupe then
                        -- Is it in the low priority list?
                        for i = 1, TableGetn(self.InterestList.LowPriority) do
                            local loc = self.InterestList.LowPriority[i]
                            if VDist2Sq(newPos[1], newPos[3], loc.Position[1], loc.Position[3]) < v[1] * v[1] and threat[3] > v[2] then
                                -- Found it in the low pri list. Remove it so we can add it to the high priority list.
                                table.remove(self.InterestList.LowPriority, i)
                                break
                            end
                        end
                        -- Check for exact position?
                        if threat[3] > v[2] and v[4] and v[5] then
                            local nearUnits = self:GetUnitsAroundPoint(v[5], newPos, v[1], 'Enemy')
                            if not table.empty(nearUnits) then
                                local unitPos = nearUnits[1]:GetPosition()
                                if unitPos then
                                    newPos = {unitPos[1], 0, unitPos[3]}
                                end
                            end
                        end
                        -- Threat high enough?
                        if threat[3] > v[2] then
                            changed = true
                            table.insert(self.InterestList.HighPriority,
                                {
                                    Position = newPos,
                                    Type = threatType,
                                    Threat = threat[3],
                                    LastUpdate = GetGameTimeSeconds(),
                                    LastScouted = GetGameTimeSeconds(),
                                }
                            )
                        end
                    end
                    -- Reduce load on game
                    if numchecks > checkspertick then
                        WaitTicks(1)
                        numchecks = 0
                    end
                end
            end
            numchecks = 0

            -- Get rid of outdated intel
            for k, v in self.InterestList.HighPriority do
                if not v.Permanent and intelChecks[v.Type][3] > 0 and v.LastUpdate + intelChecks[v.Type][3] < GetGameTimeSeconds() then
                    self.InterestList.HighPriority[k] = nil
                    changed = true
                end
            end

            -- Rebuild intel table if there was a change
            if changed then
                self.InterestList.HighPriority = self:RebuildTable(self.InterestList.HighPriority)
            end

            -- Sort the list based on low long it has been since it was scouted
            table.sort(self.InterestList.HighPriority, function(a, b)
                if a.LastScouted == b.LastScouted then
                    local MainPos = self.BuilderManagers.MAIN.Position
                    local distA = VDist2(MainPos[1], MainPos[3], a.Position[1], a.Position[3])
                    local distB = VDist2(MainPos[1], MainPos[3], b.Position[1], b.Position[3])

                    return distA < distB
                else
                    return a.LastScouted < b.LastScouted
                end
            end)

            -- Draw intel data on map
            -- if not self.IntelDebugThread then
            --   self.IntelDebugThread = self:ForkThread(SUtils.DrawIntel)
            -- end
            -- Handle intel data if there was a change
            if changed then
                SUtils.AIHandleIntelData(self)
            end
            SUtils.AICheckForWeakEnemyBase(self)

            WaitSeconds(5)
        end
    end,

    ---@param self AIBrain
    BuildScoutLocationsSorian = function(self)
        local aiBrain = self
        local opponentStarts = {}
        local allyStarts = {}
        if not aiBrain.InterestList then
            aiBrain.InterestList = {}
            aiBrain.IntelData.HiPriScouts = 0
            aiBrain.IntelData.AirHiPriScouts = 0
            aiBrain.IntelData.AirLowPriScouts = 0

            -- Add each enemy's start location to the InterestList as a new sub table
            aiBrain.InterestList.HighPriority = {}
            aiBrain.InterestList.LowPriority = {}
            aiBrain.InterestList.MustScout = {}

            local myArmy = ScenarioInfo.ArmySetup[self.Name]

            if ScenarioInfo.Options.TeamSpawn == 'fixed' then
                -- Spawn locations were fixed. We know exactly where our opponents are.
                -- Don't scout areas owned by us or our allies.
                local numOpponents = 0
                for i = 1, 16 do
                    local army = ScenarioInfo.ArmySetup['ARMY_' .. i]
                    local startPos = ScenarioUtils.GetMarker('ARMY_' .. i).position

                    if army and startPos then
                        if army.ArmyIndex ~= myArmy.ArmyIndex and (army.Team ~= myArmy.Team or army.Team == 1) then
                            -- Add the army start location to the list of interesting spots.
                            opponentStarts['ARMY_' .. i] = startPos
                            numOpponents = numOpponents + 1
                            table.insert(aiBrain.InterestList.HighPriority,
                                {
                                    Position = startPos,
                                    Type = 'StructuresNotMex',
                                    LastScouted = 0,
                                    LastUpdate = 0,
                                    Threat = 75,
                                    Permanent = true,
                                }
                            )
                        else
                            allyStarts['ARMY_' .. i] = startPos
                        end
                    end
                end
                aiBrain.NumOpponents = numOpponents

                -- For each vacant starting location, check if it is closer to allied or enemy start locations (within 100 ogrids)
                -- If it is closer to enemy territory, flag it as high priority to scout.
                local starts = AIUtils.AIGetMarkerLocations(aiBrain, 'Start Location')
                for _, loc in starts do
                    -- If vacant
                    if not opponentStarts[loc.Name] and not allyStarts[loc.Name] then
                        local closestDistSq = 999999999
                        local closeToEnemy = false

                        for _, pos in opponentStarts do
                            local distSq = VDist2Sq(pos[1], pos[3], loc.Position[1], loc.Position[3])
                            -- Make sure to scout for bases that are near equidistant by giving the enemies 100 ogrids
                            if distSq-10000 < closestDistSq then
                                closestDistSq = distSq-10000
                                closeToEnemy = true
                            end
                        end

                        for _, pos in allyStarts do
                            local distSq = VDist2Sq(pos[1], pos[3], loc.Position[1], loc.Position[3])
                            if distSq < closestDistSq then
                                closestDistSq = distSq
                                closeToEnemy = false
                                break
                            end
                        end

                        if closeToEnemy then
                            table.insert(aiBrain.InterestList.LowPriority,
                                {
                                    Position = loc.Position,
                                    Type = 'StructuresNotMex',
                                    LastScouted = 0,
                                    LastUpdate = 0,
                                    Threat = 0,
                                    Permanent = true,
                                }
                            )
                        end
                    end
                end
            else -- Spawn locations were random. We don't know where our opponents are. Add all non-ally start locations to the scout list
                local numOpponents = 0
                for i = 1, 16 do
                    local army = ScenarioInfo.ArmySetup['ARMY_' .. i]
                    local startPos = ScenarioUtils.GetMarker('ARMY_' .. i).position

                    if army and startPos then
                        if army.ArmyIndex == myArmy.ArmyIndex or (army.Team == myArmy.Team and army.Team ~= 1) then
                            allyStarts['ARMY_' .. i] = startPos
                        else
                            numOpponents = numOpponents + 1
                        end
                    end
                end
                aiBrain.NumOpponents = numOpponents

                -- If the start location is not ours or an ally's, it is suspicious
                local starts = AIUtils.AIGetMarkerLocations(aiBrain, 'Start Location')
                for _, loc in starts do
                    -- If vacant
                    if not allyStarts[loc.Name] then
                        table.insert(aiBrain.InterestList.LowPriority,
                            {
                                Position = loc.Position,
                                LastScouted = 0,
                                LastUpdate = 0,
                                Threat = 0,
                                Permanent = true,
                            }
                        )
                    end
                end
            end

            aiBrain:ForkThread(self.ParseIntelThreadSorian)
        end
    end,

    ---@param self AIBrain
    PickEnemySorian = function(self)
        self.targetoveride = false
        while true do
            self:PickEnemyLogicSorian(true)
            WaitSeconds(120)
        end
    end,

    ---@param self AIBrain
    ---@param brainbool boolean
    PickEnemyLogicSorian = function(self, brainbool)
        local armyStrengthTable = {}
        local selfIndex = self:GetArmyIndex()
        for _, v in ArmyBrains do
            local insertTable = {
                Enemy = true,
                Strength = 0,
                Position = false,
                Brain = v,
            }
            -- Share resources with friends but don't regard their strength
            if IsAlly(selfIndex, v:GetArmyIndex()) then
                self:SetResourceSharing(true)
                insertTable.Enemy = false
            elseif not IsEnemy(selfIndex, v:GetArmyIndex()) then
                insertTable.Enemy = false
            end

            insertTable.Position, insertTable.Strength = self:GetHighestThreatPosition(2, true, 'Structures', v:GetArmyIndex())
            armyStrengthTable[v:GetArmyIndex()] = insertTable
        end

        local allyEnemy = self:GetAllianceEnemy(armyStrengthTable)
        if allyEnemy and not self.targetoveride then
            self:SetCurrentEnemy(allyEnemy)
        else
            local findEnemy = false
            if (not self:GetCurrentEnemy() or brainbool) and not self.targetoveride then
                findEnemy = true
            elseif self:GetCurrentEnemy() then
                local cIndex = self:GetCurrentEnemy():GetArmyIndex()
                -- If our enemy has been defeated or has less than 20 strength, we need a new enemy
                if self:GetCurrentEnemy():IsDefeated() or armyStrengthTable[cIndex].Strength < 20 then
                    findEnemy = true
                end
            end
            if findEnemy then
                local enemyStrength = false
                local enemy = false

                for k, v in armyStrengthTable do
                    -- Dont' target self
                    if k == selfIndex then
                        continue
                    end

                    -- Ignore allies
                    if not v.Enemy then
                        continue
                    end

                    -- If we have a better candidate; ignore really weak enemies
                    if enemy and v.Strength < 20 then
                        continue
                    end

                    -- The closer targets are worth more because then we get their mass spots
                    local distanceWeight = 0.1
                    local distance = VDist3(self:GetStartVector3f(), v.Position)
                    local threatWeight = (1 / (distance * distanceWeight)) * v.Strength
                    if not enemy or threatWeight > enemyStrength then
                        enemyStrength = threatWeight
                        enemy = v.Brain
                    end
                end

                if enemy then
                    if not self:GetCurrentEnemy() or self:GetCurrentEnemy() ~= enemy then
                        SUtils.AISendChat('allies', ArmyBrains[self:GetArmyIndex()].Nickname, 'targetchat', ArmyBrains[enemy:GetArmyIndex()].Nickname)
                    end
                    self:SetCurrentEnemy(enemy)
                end
            end
        end
    end,

    ---@param self AIBrain
    UnderEnergyThresholdSorian = function(self)
        self:SetupOverEnergyStatTriggerSorian(0.15)
        self.LowEnergyMode = true
    end,

    ---@param self AIBrain
    OverEnergyThresholdSorian = function(self)
        self:SetupUnderEnergyStatTriggerSorian(0.1)
        self.LowEnergyMode = false
    end,

    ---@param self AIBrain
    UnderMassThresholdSorian = function(self)
        self:SetupOverMassStatTriggerSorian(0.15)
        self.LowMassMode = true
    end,

    ---@param self AIBrain
    OverMassThresholdSorian = function(self)
        self:SetupUnderMassStatTriggerSorian(0.1)
        self.LowMassMode = false
    end,

}