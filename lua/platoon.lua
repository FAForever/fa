--****************************************************************************
--**
--**  File     :  /lua/platoon.lua
--**  Author(s): Drew Staltman, Robert Oates, Gautam Vasudevan, Daniel Teh?, ...?
--**
--**  Summary  :
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
----------------------------------------------------------------------------------
-- Platoon Lua Module                    --
----------------------------------------------------------------------------------
local AIUtils = import('ai/aiutilities.lua')
local Utilities = import('/lua/utilities.lua')
local AIBuildStructures = import('/lua/ai/aibuildstructures.lua')
local UnitUpgradeTemplates = import('/lua/upgradetemplates.lua').UnitUpgradeTemplates
local StructureUpgradeTemplates = import('/lua/upgradetemplates.lua').StructureUpgradeTemplates
local Behaviors = import('/lua/ai/aibehaviors.lua')
local AIAttackUtils = import('/lua/AI/aiattackutilities.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local SPAI = import('/lua/ScenarioPlatoonAI.lua')

--for sorian AI
local SUtils = import('/lua/AI/sorianutilities.lua')

Platoon = Class(moho.platoon_methods) {
    NeedCoolDown = false,
    LastAttackDestination = {},

    OnCreate = function(self, plan)
        self.Trash = TrashBag()
        if self[plan] then
            self.AIThread = self:ForkThread(self[plan])
        end
        self.PlatoonData = {}
        self.EventCallbacks = {
            OnDestroyed = {},
        }
        self.PartOfAttackForce = false
        self.CreationTime = GetGameTimeSeconds()
    end,

    SetPlatoonData = function(self, dataTable)
        self.PlatoonData = table.deepcopy(dataTable)
    end,

    SetPartOfAttackForce = function(self)
        if not self.PlatoonData then
            self.PlatoonData = {}
        end
        if self.PlatoonData.NotPartOfAttackForce then return end
        local platoonsGiven = false
        local aiBrain = self:GetBrain()
        self.PartOfAttackForce = true
        -- Because of how the PlatoonData in the editor exports table.getn will not work here
        if self.PlatoonData.AMPlatoons then
            for k,v in self.PlatoonData.AMPlatoons do
                platoonsGiven = true
                if not aiBrain.AttackData.PlatoonCount[v] then
                    aiBrain.AttackData.PlatoonCount[v] = 1
                else
                    aiBrain.AttackData.PlatoonCount[v] = aiBrain.AttackData.PlatoonCount[v] + 1
                end
            end
        end
        if not platoonsGiven then
            local testUnit = self:GetPlatoonUnits()[1]
            if testUnit then
                self.PlatoonData.AMPlatoons = {}
                if EntityCategoryContains(categories.MOBILE * categories.AIR, testUnit) then
                    aiBrain.AttackData.PlatoonCount['DefaultGroupAir'] = aiBrain.AttackData.PlatoonCount['DefaultGroupAir'] + 1
                    table.insert(self.PlatoonData.AMPlatoons, 'DefaultGroupAir')

                elseif EntityCategoryContains(categories.MOBILE * categories.LAND, testUnit) then
                    aiBrain.AttackData.PlatoonCount['DefaultGroupLand'] = aiBrain.AttackData.PlatoonCount['DefaultGroupLand'] + 1
                    table.insert(self.PlatoonData.AMPlatoons, 'DefaultGroupLand')

                elseif EntityCategoryContains(categories.MOBILE * categories.NAVAL, testUnit) then
                    aiBrain.AttackData.PlatoonCount['DefaultGroupSea'] = aiBrain.AttackData.PlatoonCount['DefaultGroupSea'] + 1
                    table.insert(self.PlatoonData.AMPlatoons, 'DefaultGroupSea')
                end
            end
        end
        self:AddDestroyCallback(aiBrain.AttackManager.DecrementCount)
    end,


    IsPartOfAttackForce = function(self)
        return self.PartOfAttackForce
    end,

    ForkAIThread = function(self, fn, ...)
        if fn then
            self.AIThread = ForkThread(fn, self, unpack(arg))
            self.Trash:Add(self.AIThread)
            return self.AIThread
        else
            return nil
        end
    end,

    StopAI = function(self)
        if self.AIThread != nil then
            self.AIThread:Destroy()
        end
    end,

    AddDestroyCallback = function(self, callbackFunction)
        if not callbackFunction then
            error('*ERROR: Tried to add an OnDestroy on a platoon callback with a nil function')
            return
        end
        table.insert(self.EventCallbacks.OnDestroyed, callbackFunction)
    end,

    DoDestroyCallbacks = function(self)
        if self.EventCallbacks.OnDestroyed then
            for k, cb in self.EventCallbacks.OnDestroyed do
                if cb then
                    cb(self:GetBrain(), self)
                end
            end
        end
    end,

    RemoveDestroyCallback = function(self, fn)
        for k,v in self.EventCallbacks.OnDestroyed do
            if v == fn then
                self.EventCallbacks.OnDestroyed[k] = nil
            end
        end
    end,

    OnDestroy = function(self)

        --DUNCAN - Added
        self:StopAI()
        self:PlatoonDisband()

        self:DoDestroyCallbacks()
        if self.Trash then
            self.Trash:Destroy()
        end
    end,

    ForkThread = function(self, fn, ...)
        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            self.Trash:Add(thread)
            return thread
        else
            return nil
        end
    end,

    SetAIPlan = function(self, plan)
        if not self[plan] then return end
        if self.AIThread then
            self.AIThread:Destroy()
        end
        self.PlanName = plan
        self:ForkAIThread(self[plan])
    end,

    GetPlan = function(self)
        if self.PlanName then
            return self.PlanName
        end
    end,

    GetThreatLevel = function(self, rings)
        local brain = self:GetBrain()
        return brain:GetThreatAtPosition(self:GetPlatoonPosition(), rings, true)
    end,

    CheckCommandsCompleted = function(self, commands)
        for k, v in commands do
            if self:IsCommandsActive(commands) then
                return false
            end
        end
        return true
    end,

    TurnOffPoolAI = function(self)
        if self.PoolAIOn then
            self.AIThread:Destroy()
            self.PoolAIOn = false
            self.AIThread = nil
        end
    end,

    TurnOnPoolAI = function(self)
        if not self.PoolAIOn and not self.AIThread then
            self.AIThread = self:ForkAIThread(self.PoolAI)
        end
    end,

    PoolAI = function(self)
    end,

    OnUnitsAddedToPlatoon = function(self)
        for k,v in self:GetPlatoonUnits() do
            if not v.Dead then
                v.PlatoonHandle = self
            end
        end
    end,

    PlatoonDisband = function(self)
        local aiBrain = self:GetBrain()
        if self.BuilderHandle then
            self.BuilderHandle:RemoveHandle(self)
        end
        for k,v in self:GetPlatoonUnits() do
            v.PlatoonHandle = nil
            if not v.Dead and v.BuilderManagerData then
                if self.CreationTime == GetGameTimeSeconds() and v.BuilderManagerData.EngineerManager then
                    if self.BuilderName then
                        --LOG('*AI DEBUG: ERROR - Platoon disbanded same tick as created - ' .. self.BuilderName .. ' - Army: ' .. aiBrain:GetArmyIndex() .. ' - Location: ' .. v.BuilderManagerData.LocationType)
                        v.BuilderManagerData.EngineerManager:AssignTimeout(v, self.BuilderName)
                    else
                        --LOG('*AI DEBUG: ERROR - Platoon disbanded same tick as created - Army: ' .. aiBrain:GetArmyIndex() .. ' - Location: ' .. v.BuilderManagerData.LocationType)
                    end
                    v.BuilderManagerData.EngineerManager:DelayAssign(v)
                elseif v.BuilderManagerData.EngineerManager then
                    v.BuilderManagerData.EngineerManager:TaskFinished(v)
                end
            end
            if not v.Dead then
                IssueStop({v})
                IssueClearCommands({v})
            end
        end
        aiBrain:DisbandPlatoon(self)
    end,

    GetPlatoonThreat = function(self, threatType, unitCategory, position, radius)
        local threat = 0
        if position then
            threat = self:CalculatePlatoonThreatAroundPosition(threatType, unitCategory, position, radius)
        else
            threat = self:CalculatePlatoonThreat(threatType, unitCategory)
        end
        return threat
    end,

    GetUnitsAroundPoint = function(self, category, point, radius)
        local units = {}
        for k,v in self:GetPlatoonUnits() do

            -- Wrong unit type
            if not EntityCategoryContains(category, v) then
                continue
            end

            -- Too far away
            if Utilities.XZDistanceTwoVectors(v:GetPosition(), point) > radius then
                continue
            end

            table.insert(units, v)
        end
        return units
    end,

    GetNumCategoryUnits = function(self, category, position, radius)
        local numUnits = 0
        if position then
            numUnits = self:PlatoonCategoryCountAroundPosition(category, position, radius)
        else
            numUnits = self:PlatoonCategoryCount(category)
        end
        return numUnits
    end,

    -- ===== AI THREADS ===== --
    BuildOnceAI = function(self)
        local aiBrain = self:GetBrain()
        for k,v in self:GetPlatoonUnits() do
            if not v.Dead then
                v.PreviousPriority = aiBrain:PBMGetPriority(self)
                v.Platoon = self
            end
        end
        aiBrain:PBMSetPriority(self, 0)
    end,

    EnhanceAI = function(self)
        local aiBrain = self:GetBrain()
        local unit
        local data = self.PlatoonData
        local lastEnhancement
        local numLoop = 0
        for k,v in self:GetPlatoonUnits() do
            unit = v
            break
        end
        if unit then
            IssueStop({unit})
            IssueClearCommands({unit})
            for k,v in data.Enhancement do
                if not unit:HasEnhancement(v) then
                    local order = {
                        TaskName = "EnhanceTask",
                        Enhancement = v
                    }
                    LOG('*AI DEBUG: '..aiBrain.Nickname..' EnhanceAI Added Enhancement: '..v)
                    IssueScript({unit}, order)
                    lastEnhancement = v
                end
            end
            WaitSeconds(data.TimeBetweenEnhancements or 1)
            repeat
                WaitSeconds(5)
                --LOG('*AI DEBUG: '..aiBrain.Nickname..' Com still upgrading ')
            until unit.Dead or unit:HasEnhancement(lastEnhancement)
            LOG('*AI DEBUG: '..aiBrain.Nickname..' Com finished upgrading ')
        end
        self:PlatoonDisband()
    end,

    HuntAI = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local armyIndex = aiBrain:GetArmyIndex()
        local target
        local blip
        while aiBrain:PlatoonExists(self) do
            if self:IsOpponentAIRunning() then
                target = self:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS - categories.WALL)
                if target then
                    blip = target:GetBlip(armyIndex)
                    self:Stop()
                    self:AggressiveMoveToLocation(table.copy(target:GetPosition()))

                    --DUNCAN - added to try and stop AI getting stuck.
                    local position = AIUtils.RandomLocation(target:GetPosition()[1],target:GetPosition()[3])
                    self:MoveToLocation(position, false)
                end
            end
            WaitSeconds(17)
        end
    end,

    TacticalAI = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local armyIndex = aiBrain:GetArmyIndex()
        local platoonUnits = self:GetPlatoonUnits()
        local unit

        if not aiBrain:PlatoonExists(self) then return end

        --GET THE Launcher OUT OF THIS PLATOON
        for k, v in platoonUnits do
            if EntityCategoryContains(categories.STRUCTURE * categories.TACTICALMISSILEPLATFORM, v) then
                unit = v
                break
            end
        end

        if not unit then return end

        local bp = unit:GetBlueprint()
        local weapon = bp.Weapon[1]
        local maxRadius = weapon.MaxRadius
        local minRadius = weapon.MinRadius
        unit:SetAutoMode(true)

        --DUNCAN - commented out
        --local atkPri = { 'COMMAND', 'STRUCTURE STRATEGIC', 'STRUCTURE DEFENSE', 'CONSTRUCTION', 'EXPERIMENTAL MOBILE LAND', 'TECH3 MOBILE LAND',
        --    'TECH2 MOBILE LAND', 'TECH1 MOBILE LAND', 'ALLUNITS' }

        --DUNCAN - added energy production, removed construction, repriotised.
        self:SetPrioritizedTargetList('Attack', {
            categories.COMMAND,
            categories.EXPERIMENTAL,
            categories.ENERGYPRODUCTION,
            categories.STRUCTURE,
            categories.TECH3 * categories.MOBILE})
        while aiBrain:PlatoonExists(self) do
            local target = false
            local blip = false
            while unit:GetTacticalSiloAmmoCount() < 1 or not target do
                WaitSeconds(7)
                target = false
                while not target do

                    --DUNCAN - Commented out
                    --if aiBrain:GetCurrentEnemy() and aiBrain:GetCurrentEnemy():IsDefeated() then
                    --    aiBrain:PickEnemyLogic()
                    --end
                    --target = AIUtils.AIFindBrainTargetInRange(aiBrain, self, 'Attack', maxRadius, atkPri, aiBrain:GetCurrentEnemy())

                    if not target then
                        target = self:FindPrioritizedUnit('Attack', 'Enemy', true, unit:GetPosition(), maxRadius)
                    end
                    if target then
                        break
                    end
                    WaitSeconds(3)
                    if not aiBrain:PlatoonExists(self) then
                        return
                    end
                end
            end
            if not target.Dead then
                --LOG('*AI DEBUG: Firing Tactical Missile at enemy swine!')
                IssueTactical({unit}, target)
            end
            WaitSeconds(3)
        end
    end,

    NukeAI = function(self)
        --self:Stop()
        local aiBrain = self:GetBrain()
        local platoonUnits = self:GetPlatoonUnits()
        local unit
        --GET THE Launcher OUT OF THIS PLATOON
        for k, v in platoonUnits do
            if EntityCategoryContains(categories.SILO * categories.NUKE, v) then
                unit = v
                break
            end
        end

        if unit then
            local nukePos
            unit:SetAutoMode(true)
            while aiBrain:PlatoonExists(self) do
                while unit:GetNukeSiloAmmoCount() < 1 do
                    WaitSeconds(11)
                    if not  aiBrain:PlatoonExists(self) then
                        return
                    end
                end

                nukePos = import('/lua/ai/aibehaviors.lua').GetHighestThreatClusterLocation(aiBrain, unit)
                if nukePos then
                   IssueNuke({unit}, nukePos)
                   WaitSeconds(10)
                   IssueClearCommands({unit})
                end
                WaitSeconds(1)
            end
        end
        self:PlatoonDisband()
    end,

    AntiNukeAI = function(self)
        self:Stop()
        local platoonUnits = self:GetPlatoonUnits()
        local aiBrain = self:GetBrain()
        local antiNuke
        --GET THE AntiNuke OUT OF THIS PLATOON
        for k, v in platoonUnits do
            if EntityCategoryContains(categories.STRUCTURE * categories.ANTIMISSILE * categories.TECH3, v) then
                antiNuke = v
                break
            end
        end
        -- Toggle on auto build
        antiNuke:SetAutoMode(true)
    end,

    PauseAI = function(self)
        local platoonUnits = self:GetPlatoonUnits()
        local aiBrain = self:GetBrain()
        for k, v in platoonUnits do
            v:SetScriptBit('RULEUTC_ProductionToggle', true)
        end
        local econ = AIUtils.AIGetEconomyNumbers(aiBrain)
        while econ.EnergyStorageRatio < 0.4 do
            WaitSeconds(2)
            econ = AIUtils.AIGetEconomyNumbers(aiBrain)
        end
        for k, v in platoonUnits do
            v:SetScriptBit('RULEUTC_ProductionToggle', false)
        end
        self:PlatoonDisband()
    end,

    -------------------------------------------------------
    --   Function: ExperimentalAIHub
    --   Args:
    --       self - the single-experimental platoon to run the AI on
    --   Description:
    --       If set as a platoon's AI function, will select an appropriate behavior based on the unit type.
    --   Returns:
    --       nil (tail calls into a behavior function)
    -------------------------------------------------------
    ExperimentalAIHub = function(self)

        local behaviors = import('/lua/ai/AIBehaviors.lua')

        local experimental = self:GetPlatoonUnits()[1]
        if not experimental then
            return
        end
        local ID = experimental:GetUnitId()
        --LOG('Starting experimental behaviour...' .. ID)
        if ID == 'uel0401' then
            return behaviors.FatBoyBehavior(self)
        elseif ID == 'uaa0310' then
            return behaviors.CzarBehavior(self)
        elseif ID == 'xsa0402' then
            return behaviors.AhwassaBehavior(self)
        elseif ID == 'ura0401' then
            return behaviors.TickBehavior(self)
        end

        return behaviors.BehemothBehavior(self)
    end,

    -------------------------------------------------------
    --   Function: GuardEngineer
    --   Args:
    --       platoon - platoon to run the AI
    --       function [opt] - AI function to run when done guarding
    --       bool [opt] - if true, forces a platoon's units to disband and guard a base forever
    --   Description:
    --       Provides logic for platoons to guard expansion areas and engineers.
    --   Returns:
    --       nil (tail calls into the nextAIFunc or itself)
    -------------------------------------------------------
    GuardEngineer = function(self, nextAIFunc, forceGuardBase)
        local aiBrain = self:GetBrain()

        if not aiBrain:PlatoonExists(self) or not self:GetPlatoonPosition() then
            return
        end

        local renderThread = false
        AIAttackUtils.GetMostRestrictiveLayer(self)

        if forceGuardBase or not self.PlatoonData.NeverGuardBases then
            --Guard the closest least-defended base
            local bestBase = false
            local bestBaseName = ""
            local bestDistSq = 999999999
            local bestDefense = 999999999

            local MAIN = aiBrain.BuilderManagers.MAIN

            local threatType = 'AntiSurface'
            for baseName, base in aiBrain.BuilderManagers do
                if baseName != 'MAIN' and (base.BaseSettings and not base.BaseSettings.NoGuards) then

                    if AIAttackUtils.GetSurfaceThreatOfUnits(self) <= 0 then
                        threatType = 'StructuresNotMex'
                    end

                    local baseDefense = aiBrain:GetThreatAtPosition(base.Position, 1, true, threatType, aiBrain:GetArmyIndex())

                    local distSq = VDist2Sq(MAIN.Position[1], MAIN.Position[3], base.Position[1], base.Position[3])

                    if baseDefense < bestDefense then
                        bestBase = base
                        bestBaseName = baseName
                        bestDistSq = distSq
                        bestDefense = baseDefense
                    elseif baseDefense == bestDefense then
                        if distSq < bestDistSq then
                            bestBase = base
                            bestBaseName = baseName
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
                local path, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, self.MovementLayer, self:GetPlatoonPosition(), bestBase.Position, 200)

                IssueClearCommands(self)

                if path then
                    local pathLength = table.getn(path)
                    for i=1, pathLength-1 do
                        self:MoveToLocation(path[i], false)
                    end
                end

                IssueGuard(self:GetPlatoonUnits(), bestBase.Position)
                --self:MoveToLocation(bestBase.Position, false)

                --Handle base guarding logic in this loop
                local guardTime = 0
                while aiBrain:PlatoonExists(self) do
                    --Is the threat of this base good enough?
                    if not forceGuardBase then
                        local rnd = Random(13,17)
                        WaitSeconds(rnd)
                        guardTime = guardTime + rnd

                        if (aiBrain:GetThreatAtPosition(bestBase.Position, 1, true, threatType, aiBrain:GetArmyIndex()) >= threshold + self:GetPlatoonThreatEx().SurfaceThreatLevel
                        or (self.PlatoonData.BaseGuardTimeLimit and guardTime > self.PlatoonData.BaseGuardTimeLimit)) then
                            --Stop guarding and guard something else.
                            break
                        end
                    else
                        --Set to permanently guard a base, and we already received our move orders.
                        return
                    end
                end
            end
        end

        if not self.PlatoonData.NeverGuardEngineers then
            --Otherwise guard an engineer until it dies or our guard timer expires
            local unitToGuard = false
            local units = aiBrain:GetListOfUnits(categories.ENGINEER - categories.COMMAND, false)
            for k,v in units do
                if v.NeedGuard and not v.BeingGuarded then
                    unitToGuard = v
                    v.BeingGuarded = true
                end
            end

            local guardTime = 0
            if unitToGuard and not unitToGuard.Dead then
                IssueGuard(self:GetPlatoonUnits(), unitToGuard)

                while aiBrain:PlatoonExists(self) and not unitToGuard.Dead do
                    guardTime = guardTime + 5
                    WaitSeconds(5)

                    if self.PlatoonData.EngineerGuardTimeLimit and guardTime >= self.PlatoonData.EngineerGuardTimeLimit
                    or (not unitToGuard.Dead and unitToGuard:GetCurrentLayer() == 'Seabed' and self.MovementLayer == 'Land') then
                        break
                    end
                end
            end

        end

        ----Tail call into the next ai function
        WaitSeconds(1)
        if type(nextAIFunc) == 'function' then
            return nextAIFunc(self)
        end

        return self:GuardEngineer(nextAIFunc, forceGuardBase)
    end,

    --DUNCAN - added
    GuardUnit = function(self)
        --LOG('GuardUnit AI started...')
        local aiBrain = self:GetBrain()
        if not aiBrain:PlatoonExists(self) or not self:GetPlatoonPosition() then
            return
        end

        AIAttackUtils.GetMostRestrictiveLayer(self)

        local unitToGuard = false
        local guardRadiusCheck = self.PlatoonData.GuardRadius or 60
        local units = aiBrain:GetListOfUnits(self.PlatoonData.GuardCategory , false)

        for k,v in units do
            if VDist3(v:GetPosition(), self:GetPlatoonPosition()) < guardRadiusCheck then
                if not v.BeingAirGuarded and self.MovementLayer == 'Air' then
                    unitToGuard = v
                    v.BeingAirGuarded = true
                end
                if not v.BeingLandGuarded and (self.MovementLayer == 'Land' or self.MovementLayer == 'Amphibious') then
                    unitToGuard = v
                    v.BeingLandGuarded = true
                end
            end
        end

        if not unitToGuard then
            --Dont know if this works...
            --unitToGuard = self:FindClosestUnit('Attack', 'Ally', true, self.PlatoonData.GuardCategory)
            local units = aiBrain:GetListOfUnits(self.PlatoonData.GuardCategory , false)
            for k,v in units do
                if VDist3(v:GetPosition(), self:GetPlatoonPosition()) < guardRadiusCheck then
                    unitToGuard = v
                end
            end
        end

        local guardTime = 0
        if unitToGuard and not unitToGuard.Dead then
            IssueGuard(self:GetPlatoonUnits(), unitToGuard)

            while aiBrain:PlatoonExists(self) and not unitToGuard.Dead do
                guardTime = guardTime + 5
                WaitSeconds(5)

                if self.PlatoonData.GuardTimeLimit and guardTime >= self.PlatoonData.GuardTimeLimit
                or (not unitToGuard.Dead and unitToGuard:GetCurrentLayer() == 'Seabed' and self.MovementLayer == 'Land') then
                    break
                end
            end
            if not unitToGuard.Dead and self.MovementLayer == 'Air' then
                unitToGuard.BeingAirGuarded = false
            end
            if not unitToGuard.Dead and (self.MovementLayer == 'Land' or self.MovementLayer == 'Amphibious') then
                unitToGuard.BeingLandGuarded = false
            end
        else
            --LOG('GuardUnit AI .. No unit found.')
            self:PlatoonDisband()
            return
        end
        WaitSeconds(1)
        return self:HuntAI()
    end,

    -------------------------------------------------------
    --   Function: GuardMarker
    --   Args:
    --       platoon - platoon to run the AI
    --   Description:
    --       Will guard the location of a marker
    --   Returns:
    --       nil
    -------------------------------------------------------
    GuardMarker = function(self)
        local aiBrain = self:GetBrain()

        local platLoc = self:GetPlatoonPosition()

        if not aiBrain:PlatoonExists(self) or not platLoc then
            return
        end

        -----------------------------------------------------------------------
        -- Platoon Data
        -----------------------------------------------------------------------
        -- type of marker to guard
        -- Start location = 'Start Location'... see MarkerTemplates.lua for other types
        local markerType = self.PlatoonData.MarkerType or 'Expansion Area'

        -- what should we look for for the first marker?  This can be 'Random',
        -- 'Threat' or 'Closest'
        local moveFirst = self.PlatoonData.MoveFirst or 'Threat'

        -- should our next move be no move be (same options as before) as well as 'None'
        -- which will cause the platoon to guard the first location they get to
        local moveNext = self.PlatoonData.MoveNext or 'None'

        -- Minimum distance when looking for closest
        local avoidClosestRadius = self.PlatoonData.AvoidClosestRadius or 0

        -- set time to wait when guarding a location with moveNext = 'None'
        local guardTimer = self.PlatoonData.GuardTimer or 0

        -- threat type to look at
        local threatType = self.PlatoonData.ThreatType or 'AntiSurface'

        -- should we look at our own threat or the enemy's
        local bSelfThreat = self.PlatoonData.SelfThreat or false

        -- if true, look to guard highest threat, otherwise,
        -- guard the lowest threat specified
        local bFindHighestThreat = self.PlatoonData.FindHighestThreat or false

        -- minimum threat to look for
        local minThreatThreshold = self.PlatoonData.MinThreatThreshold or -1
        -- maximum threat to look for
        local maxThreatThreshold = self.PlatoonData.MaxThreatThreshold  or 99999999

        -- Avoid bases (true or false)
        local bAvoidBases = self.PlatoonData.AvoidBases or false

        -- Radius around which to avoid the main base
        local avoidBasesRadius = self.PlatoonData.AvoidBasesRadius or 0

        -- Use Aggresive Moves Only
        local bAggroMove = self.PlatoonData.AggressiveMove or false

        local PlatoonFormation = self.PlatoonData.UseFormation or 'NoFormation'
        -----------------------------------------------------------------------


        AIAttackUtils.GetMostRestrictiveLayer(self)
        self:SetPlatoonFormationOverride(PlatoonFormation)
        local markerLocations = AIUtils.AIGetMarkerLocations(aiBrain, markerType)

        local bestMarker = false

        if not self.LastMarker then
            self.LastMarker = {nil,nil}
        end

        -- look for a random marker
        if moveFirst == 'Random' then
            if table.getn(markerLocations) <= 2 then
                self.LastMarker[1] = nil
                self.LastMarker[2] = nil
            end
            for _,marker in RandomIter(markerLocations) do
                if table.getn(markerLocations) <= 2 then
                    self.LastMarker[1] = nil
                    self.LastMarker[2] = nil
                end
                if self:AvoidsBases(marker.Position, bAvoidBases, avoidBasesRadius) then
                    if self.LastMarker[1] and marker.Position[1] == self.LastMarker[1][1] and marker.Position[3] == self.LastMarker[1][3] then
                        continue
                    end
                    if self.LastMarker[2] and marker.Position[1] == self.LastMarker[2][1] and marker.Position[3] == self.LastMarker[2][3] then
                        continue
                    end
                    bestMarker = marker
                    break
                end
            end
        elseif moveFirst == 'Threat' then
            --Guard the closest least-defended marker
            local bestMarkerThreat = 0
            if not bFindHighestThreat then
                bestMarkerThreat = 99999999
            end

            local bestDistSq = 99999999


            -- find best threat at the closest distance
            for _,marker in markerLocations do
                local markerThreat
                if bSelfThreat then
                    markerThreat = aiBrain:GetThreatAtPosition(marker.Position, 0, true, threatType, aiBrain:GetArmyIndex())
                else
                    markerThreat = aiBrain:GetThreatAtPosition(marker.Position, 0, true, threatType)
                end
                local distSq = VDist2Sq(marker.Position[1], marker.Position[3], platLoc[1], platLoc[3])

                if markerThreat >= minThreatThreshold and markerThreat <= maxThreatThreshold then
                    if self:AvoidsBases(marker.Position, bAvoidBases, avoidBasesRadius) then
                        if self.IsBetterThreat(bFindHighestThreat, markerThreat, bestMarkerThreat) then
                            bestDistSq = distSq
                            bestMarker = marker
                            bestMarkerThreat = markerThreat
                        elseif markerThreat == bestMarkerThreat then
                            if distSq < bestDistSq then
                                bestDistSq = distSq
                                bestMarker = marker
                                bestMarkerThreat = markerThreat
                            end
                        end
                     end
                 end
            end

        else
            -- if we didn't want random or threat, assume closest (but avoid ping-ponging)
            local bestDistSq = 99999999
            if table.getn(markerLocations) <= 2 then
                self.LastMarker[1] = nil
                self.LastMarker[2] = nil
            end
            for _,marker in markerLocations do
                local distSq = VDist2Sq(marker.Position[1], marker.Position[3], platLoc[1], platLoc[3])
                if self:AvoidsBases(marker.Position, bAvoidBases, avoidBasesRadius) and distSq > (avoidClosestRadius * avoidClosestRadius) then
                    if distSq < bestDistSq then
                        if self.LastMarker[1] and marker.Position[1] == self.LastMarker[1][1] and marker.Position[3] == self.LastMarker[1][3] then
                            continue
                        end
                        if self.LastMarker[2] and marker.Position[1] == self.LastMarker[2][1] and marker.Position[3] == self.LastMarker[2][3] then
                            continue
                        end
                        bestDistSq = distSq
                        bestMarker = marker
                    end
                end
            end
        end


        -- did we find a threat?
        local usedTransports = false
        if bestMarker then
            self.LastMarker[2] = self.LastMarker[1]
            self.LastMarker[1] = bestMarker.Position
            --LOG("GuardMarker: Attacking " .. bestMarker.Name)
            local path, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, self.MovementLayer, self:GetPlatoonPosition(), bestMarker.Position, 200)
            local success, bestGoalPos = AIAttackUtils.CheckPlatoonPathingEx(self, bestMarker.Position)
            IssueClearCommands(self:GetPlatoonUnits())
            if path then
                local position = self:GetPlatoonPosition()
                if not success or VDist2(position[1], position[3], bestMarker.Position[1], bestMarker.Position[3]) > 512 then
                    usedTransports = AIAttackUtils.SendPlatoonWithTransportsNoCheck(aiBrain, self, bestMarker.Position, true)
                elseif VDist2(position[1], position[3], bestMarker.Position[1], bestMarker.Position[3]) > 256 then
                    usedTransports = AIAttackUtils.SendPlatoonWithTransportsNoCheck(aiBrain, self, bestMarker.Position, false)
                end
                if not usedTransports then
                    local pathLength = table.getn(path)
                    for i=1, pathLength-1 do
                        if bAggroMove then
                            self:AggressiveMoveToLocation(path[i])
                        else
                            self:MoveToLocation(path[i], false)
                        end
                    end
                end
            elseif (not path and reason == 'NoPath') then
                --LOG('Guardmarker requesting transports')
                local foundTransport = AIAttackUtils.SendPlatoonWithTransportsNoCheck(aiBrain, self, bestMarker.Position, true)
                --DUNCAN - if we need a transport and we cant get one the disband
                if not foundTransport then
                    --LOG('Guardmarker no transports')
                    self:PlatoonDisband()
                    return
                end
                --LOG('Guardmarker found transports')
            else
                self:PlatoonDisband()
                return
            end

            if (not path or not success) and not usedTransports then
                self:PlatoonDisband()
                return
            end

            if moveNext == 'None' then
                -- guard
                IssueGuard(self:GetPlatoonUnits(), bestMarker.Position)
                -- guard forever
                if guardTimer <= 0 then return end
            else
                -- otherwise, we're moving to the location
                self:AggressiveMoveToLocation(bestMarker.Position)
            end

            -- wait till we get there
            local oldPlatPos = self:GetPlatoonPosition()
            local StuckCount = 0
            repeat
                WaitSeconds(5)
                platLoc = self:GetPlatoonPosition()
                if VDist3(oldPlatPos, platLoc) < 1 then
                    StuckCount = StuckCount + 1
                else
                    StuckCount = 0
                end
                if StuckCount > 5 then
                    return self:GuardMarker()
                end
                oldPlatPos = platLoc
            until VDist2Sq(platLoc[1], platLoc[3], bestMarker.Position[1], bestMarker.Position[3]) < 64 or not aiBrain:PlatoonExists(self)

            -- if we're supposed to guard for some time
            if moveNext == 'None' then
                -- this won't be 0... see above
                WaitSeconds(guardTimer)
                self:PlatoonDisband()
                return
            end

            if moveNext == 'Guard Base' then
                return self:GuardBase()
            end

            -- we're there... wait here until we're done
            local numGround = aiBrain:GetNumUnitsAroundPoint((categories.LAND + categories.NAVAL + categories.STRUCTURE), bestMarker.Position, 15, 'Enemy')
            while numGround > 0 and aiBrain:PlatoonExists(self) do
                WaitSeconds(Random(5,10))
                numGround = aiBrain:GetNumUnitsAroundPoint((categories.LAND + categories.NAVAL + categories.STRUCTURE), bestMarker.Position, 15, 'Enemy')
            end

            if not aiBrain:PlatoonExists(self) then
                return
            end

            -- set our MoveFirst to our MoveNext
            self.PlatoonData.MoveFirst = moveNext
            return self:GuardMarker()
        else
            -- no marker found, disband!
            self:PlatoonDisband()
        end
    end,

    GuardBase = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local armyIndex = aiBrain:GetArmyIndex()
        local target = false
        local basePosition = false

        if self.PlatoonData.LocationType and self.PlatoonData.LocationType != 'NOTMAIN' then
            basePosition = aiBrain.BuilderManagers[self.PlatoonData.LocationType].Position
        else
            local platoonPosition = self:GetPlatoonPosition()
            if platoonPosition then
                basePosition = aiBrain:FindClosestBuilderManagerPosition(self:GetPlatoonPosition())
            end
        end

        if not basePosition then
            return
        end

        --DUNCAN - changed from 75, added home radius
        local guardRadius = self.PlatoonData.GuardRadius or 200
        local homeRadius = self.PlatoonData.HomeRadius or 200

        while aiBrain:PlatoonExists(self) do
            if self:IsOpponentAIRunning() then
                target = self:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS - categories.WALL)

                --DUNCAN - added to target experimentals if they exist.
                local newtarget
                if AIAttackUtils.GetSurfaceThreatOfUnits(self) > 0 then
                    newtarget = self:FindClosestUnit('Attack', 'Enemy', true, categories.EXPERIMENTAL * (categories.LAND + categories.NAVAL + categories.STRUCTURE))
                elseif AIAttackUtils.GetAirThreatOfUnits(self) > 0 then
                    newtarget = self:FindClosestUnit('Attack', 'Enemy', true, categories.EXPERIMENTAL * categories.AIR)
                end
                if newtarget then
                    target = newtarget
                end

                --DUNCAN - use the base position to work out radius rather than self:GetPlatoonPosition()
                if target and not target.Dead and VDist3(target:GetPosition(), basePosition) < guardRadius then
                    self:Stop()
                    self:AggressiveMoveToLocation(target:GetPosition())
                else
                    local PlatoonPosition = self:GetPlatoonPosition()
                    if PlatoonPosition and VDist3(basePosition, PlatoonPosition) > homeRadius then
                        --DUNCAN - still try to move closer to the base if outside the radius
                        local position = AIUtils.RandomLocation(basePosition[1],basePosition[3])
                        self:Stop()
                        self:MoveToLocation(position, false)
                    end
                end
            end
            WaitSeconds(5)
        end
    end,

    -------------------------------------------------------
    --   Function: LandScoutingAI
    --   Args:
    --       platoon - platoon to run the AI
    --   Description:
    --       Handles sending land scouts to important locations.
    --   Returns:
    --       nil (loops until platoon is destroyed)
    -------------------------------------------------------
    LandScoutingAI = function(self)
        AIAttackUtils.GetMostRestrictiveLayer(self)

        local aiBrain = self:GetBrain()
        local scout = self:GetPlatoonUnits()[1]

        -- Build always BuildScoutLocations. We need this also for the Cheating AI's with Omniview.
        aiBrain:BuildScoutLocations()
        --If we have cloaking (are cybran), then turn on our cloaking
        --DUNCAN - Fixed to use same bits
        if scout:TestToggleCaps('RULEUTC_CloakToggle') then
            scout:SetScriptBit('RULEUTC_CloakToggle', false)
        end

        while not scout.Dead do
            --Head towards the the area that has not had a scout sent to it in a while
            local targetData = false

            --For every scouts we send to all opponents, send one to scout a low pri area.
            if aiBrain.IntelData.HiPriScouts < aiBrain.NumOpponents and table.getn(aiBrain.InterestList.HighPriority) > 0 then
                targetData = aiBrain.InterestList.HighPriority[1]
                aiBrain.IntelData.HiPriScouts = aiBrain.IntelData.HiPriScouts + 1
                targetData.LastScouted = GetGameTimeSeconds()

                aiBrain:SortScoutingAreas(aiBrain.InterestList.HighPriority)

            elseif table.getn(aiBrain.InterestList.LowPriority) > 0 then
                targetData = aiBrain.InterestList.LowPriority[1]
                aiBrain.IntelData.HiPriScouts = 0
                targetData.LastScouted = GetGameTimeSeconds()

                aiBrain:SortScoutingAreas(aiBrain.InterestList.LowPriority)
            else
                --Reset number of scoutings and start over
                aiBrain.IntelData.HiPriScouts = 0
            end

            --Is there someplace we should scout?
            if targetData then
                --Can we get there safely?
                local path, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, self.MovementLayer, scout:GetPosition(), targetData.Position, 400) --DUNCAN - Increase threatwieght from 100

                IssueClearCommands(self)

                if path then
                    local pathLength = table.getn(path)
                    for i=1, pathLength-1 do
                        self:MoveToLocation(path[i], false)
                    end
                end

                self:MoveToLocation(targetData.Position, false)

                --Scout until we reach our destination
                while not scout.Dead and not scout:IsIdleState() do
                    WaitSeconds(2.5)
                end
            end

            WaitSeconds(1)
        end
    end,

    -------------------------------------------------------
    --   Function: DoAirScoutVecs
    --   Args:
    --       platoon - platoon to run the AI
    --       unit - the scout
    --       targetArea - a position to scout
    --   Description:
    --       Creates an attack vector that will cause the scout to fly by the target at a distance of its visual range.
    --       Whether to fly by on the left or right is decided randomly. This whole affair should hopefully extend the
    --       life of the air scout.
    --   Returns:
    --       destination position
    -------------------------------------------------------
    DoAirScoutVecs = function(self, scout, targetArea)
        local vec = {0, 0, 0}
        vec[1] = targetArea[1] - scout:GetPosition()[1]
        vec[3] = targetArea[3] - scout:GetPosition()[3]

        --Normalize
        local length = VDist2(targetArea[1], targetArea[3], scout:GetPosition()[1], scout:GetPosition()[3])
        local norm = {vec[1]/length, 0, vec[3]/length}

        --Get negative reciprocal vector, make length of vision radius
        local dir = math.pow(-1, Random(1,2))

        local visRad = scout:GetBlueprint().Intel.VisionRadius
        local orthogonal = {norm[3]*visRad*dir, 0, -norm[1]*visRad*dir}

        --Offset the target location with an orthogonal vector and a flyby vector.
        local dest = {targetArea[1] + orthogonal[1] + norm[1]*75, 0, targetArea[3] + orthogonal[3] + norm[3]*75}

        --Clamp to map edges
        if dest[1] < 5 then dest[1] = 5
        elseif dest[1] > ScenarioInfo.size[1]-5 then dest[1] = ScenarioInfo.size[1]-5 end
        if dest[3] < 5 then dest[3] = 5
        elseif dest[3] > ScenarioInfo.size[2]-5 then dest[3] = ScenarioInfo.size[2]-5 end


        self:MoveToLocation(dest, false)
        return dest
    end,

    -------------------------------------------------------
    --   Function: AirScoutingAI
    --   Args:
    --       platoon - platoon to run the AI
    --   Description:
    --       Handles sending air scouts to important locations.
    --   Returns:
    --       nil (loops until platoon is destroyed)
    -------------------------------------------------------
    AirScoutingAI = function(self)

        local scout = self:GetPlatoonUnits()[1]
        if not scout then
            return
        end

        local aiBrain = self:GetBrain()
        -- Build always BuildScoutLocations. We need this also for the Cheating AI's with Omniview.
        aiBrain:BuildScoutLocations()

        --If we have Stealth (are cybran), then turn on our Stealth
        if scout:TestToggleCaps('RULEUTC_CloakToggle') then
            scout:EnableUnitIntel('Toggle', 'Cloak')
        end

        while not scout.Dead do
            local targetArea = false
            local highPri = false

            local mustScoutArea, mustScoutIndex = aiBrain:GetUntaggedMustScoutArea()
            local unknownThreats = aiBrain:GetThreatsAroundPosition(scout:GetPosition(), 16, true, 'Unknown')

            --1) If we have any "must scout" (manually added) locations that have not been scouted yet, then scout them
            if mustScoutArea then
                mustScoutArea.TaggedBy = scout
                targetArea = mustScoutArea.Position

            --2) Scout "unknown threat" areas with a threat higher than 25
            elseif table.getn(unknownThreats) > 0 and unknownThreats[1][3] > 25 then
                aiBrain:AddScoutArea({unknownThreats[1][1], 0, unknownThreats[1][2]})

            --3) Scout high priority locations
            elseif aiBrain.IntelData.AirHiPriScouts < aiBrain.NumOpponents and aiBrain.IntelData.AirLowPriScouts < 1
            and table.getn(aiBrain.InterestList.HighPriority) > 0 then
                aiBrain.IntelData.AirHiPriScouts = aiBrain.IntelData.AirHiPriScouts + 1

                highPri = true

                targetData = aiBrain.InterestList.HighPriority[1]
                targetData.LastScouted = GetGameTimeSeconds()
                targetArea = targetData.Position

                aiBrain:SortScoutingAreas(aiBrain.InterestList.HighPriority)

            --4) Every time we scout NumOpponents number of high priority locations, scout a low priority location
            elseif aiBrain.IntelData.AirLowPriScouts < 1 and table.getn(aiBrain.InterestList.LowPriority) > 0 then
                aiBrain.IntelData.AirHiPriScouts = 0
                aiBrain.IntelData.AirLowPriScouts = aiBrain.IntelData.AirLowPriScouts + 1

                targetData = aiBrain.InterestList.LowPriority[1]
                targetData.LastScouted = GetGameTimeSeconds()
                targetArea = targetData.Position

                aiBrain:SortScoutingAreas(aiBrain.InterestList.LowPriority)
            else
                --Reset number of scoutings and start over
                aiBrain.IntelData.AirLowPriScouts = 0
                aiBrain.IntelData.AirHiPriScouts = 0
            end

            --Air scout do scoutings.
            if targetArea then
                self:Stop()

                local vec = self:DoAirScoutVecs(scout, targetArea)

                while not scout.Dead and not scout:IsIdleState() do

                    --If we're close enough...
                    if VDist2Sq(vec[1], vec[3], scout:GetPosition()[1], scout:GetPosition()[3]) < 15625 then
                        if mustScoutArea then
                            --Untag and remove
                            for idx,loc in aiBrain.InterestList.MustScout do
                                if loc == mustScoutArea then
                                   table.remove(aiBrain.InterestList.MustScout, idx)
                                   break
                                end
                            end
                        end
                        --Break within 125 ogrids of destination so we don't decelerate trying to stop on the waypoint.
                        break
                    end

                    if VDist3(scout:GetPosition(), targetArea) < 25 then
                        break
                    end

                    WaitSeconds(5)
                end
            else
                WaitSeconds(1)
            end
            WaitTicks(1)
        end
    end,

    -------------------------------------------------------
    --   Function: ScoutingAI
    --   Args:
    --       platoon - a single-scout platoon to run the AI for
    --   Description:
    --       Switches to AirScoutingAI or LandScoutingAI depending on the unit's movement capabilities.
    --   Returns:
    --       nil. (Tail call into other AI functions)
    -------------------------------------------------------
    ScoutingAI = function(self)
        AIAttackUtils.GetMostRestrictiveLayer(self)

        if self.MovementLayer == 'Air' then
            return self:AirScoutingAI()
        else
            return self:LandScoutingAI()
        end
    end,

    PatrolBaseVectorsAI = function(self)
        self:Stop()
        self:SetPartOfAttackForce()
        local aiBrain = self:GetBrain()
        local location = self.PlatoonData.LocationType or self.PlatoonData.Position or self:GetPlatoonPosition()
        local radius = self.PlatoonData.Radius or 100
        local first = true
        local unit = false
        for k,v in self:GetPlatoonUnits() do
            if not v.Dead and EntityCategoryContains(categories.MOBILE * categories.LAND, v) then
                unit = v
                break
            end
        end
        if location and radius then
            for k,v in AIUtils.GetBasePatrolPoints(aiBrain, location, radius) do
                if not unit or AIUtils.CheckUnitPathingEx(v, unit:GetPosition(), unit) then
                    if first then
                        self:MoveToLocation(v, false)
                        first = false
                    else
                        self:Patrol(v)
                    end
                end
            end
        end
        self:PlatoonDisband()
    end,

    PlatoonCallForHelpAI = function(self)
        local aiBrain = self:GetBrain()
        local checkTime = self.PlatoonData.DistressCheckTime or 7
        local pos = self:GetPlatoonPosition()
        while aiBrain:PlatoonExists(self) and pos do
            if not self.DistressCall then
                local threat = aiBrain:GetThreatAtPosition(pos, 0, true, 'AntiSurface')
                if threat and threat > 1 then
                    --LOG('*AI DEBUG: Platoon Calling for help')
                    aiBrain:BaseMonitorPlatoonDistress(self, threat)
                    self.DistressCall = true
                end
            end
            WaitSeconds(checkTime)
        end
    end,

    DistressResponseAI = function(self)
        local aiBrain = self:GetBrain()
        while aiBrain:PlatoonExists(self) do
            -- In the loop so they may be changed by other platoon things
            local distressRange = self.PlatoonData.DistressRange or aiBrain.BaseMonitor.DefaultDistressRange
            local reactionTime = self.PlatoonData.DistressReactionTime or aiBrain.BaseMonitor.PlatoonDefaultReactionTime
            local threatThreshold = self.PlatoonData.ThreatSupport or 1
            local platoonPos = self:GetPlatoonPosition()
            if platoonPos and not self.DistressCall then
                -- Find a distress location within the platoons range
                local distressLocation = aiBrain:BaseMonitorDistressLocation(platoonPos, distressRange, threatThreshold)
                local moveLocation

                -- We found a location within our range! Activate!
                if distressLocation then
                    --LOG('*AI DEBUG: ARMY '.. aiBrain:GetArmyIndex() ..': --- DISTRESS RESPONSE AI ACTIVATION ---')

                    -- Backups old ai plan
                    local oldPlan = self:GetPlan()
                    if self.AiThread then
                        self.AIThread:Destroy()
                    end

                    -- Continue to position until the distress call wanes
                    repeat
                        moveLocation = distressLocation
                        self:Stop()
                        local cmd = self:AggressiveMoveToLocation(distressLocation)
                        repeat
                            WaitSeconds(reactionTime)
                            if not aiBrain:PlatoonExists(self) then
                                return
                            end
                        until not self:IsCommandsActive(cmd) or aiBrain:GetThreatAtPosition(moveLocation, 0, true, 'Overall') <= threatThreshold


                        platoonPos = self:GetPlatoonPosition()
                        if platoonPos then
                            -- Now that we have helped the first location, see if any other location needs the help
                            distressLocation = aiBrain:BaseMonitorDistressLocation(platoonPos, distressRange)
                            if distressLocation then
                                self:AggressiveMoveToLocation(distressLocation)
                            end
                        end
                    -- If no more calls or we are at the location; break out of the function
                    until not distressLocation or (distressLocation[1] == moveLocation[1] and distressLocation[3] == moveLocation[3])

                    --LOG('*AI DEBUG: '..aiBrain.Name..' DISTRESS RESPONSE AI DEACTIVATION - oldPlan: '..oldPlan)
                    self:SetAIPlan(oldPlan)
                end
            end
            WaitSeconds(11)
        end
    end,

    PoolDistressAI = function(self)
        local aiBrain = self:GetBrain()
        local distressRange = aiBrain.BaseMonitor.PoolDistressRange
        local reactionTime = aiBrain.BaseMonitor.PoolReactionTime
        while aiBrain:PlatoonExists(self) do
            local platoonUnits = self:GetPlatoonUnits()
            if aiBrain:PBMHasPlatoonList() then
                for locNum, locData in aiBrain.PBM.Locations do
                    if not locData.DistressCall then
                        local distressLocation = aiBrain:BaseMonitorDistressLocation(locData.Location, aiBrain.BaseMonitor.PoolDistressRange, aiBrain.BaseMonitor.PoolDistressThreshold)
                        local moveLocation
                        if distressLocation then
                            --LOG('*AI DEBUG: ARMY '.. aiBrain:GetArmyIndex() ..': --- POOL DISTRESS RESPONSE ---')
                            local group = {}
                            for k,v in platoonUnits do
                                vPos = table.copy(v:GetPosition())
                                if VDist2(vPos[1], vPos[3], locData.Location[1], locData.Location[3]) < locData.Radius then
                                    table.insert(group, v)
                                end
                            end
                            IssueClearCommands(group)
                            if distressLocation[1] <= 0 or distressLocation[3] <= 0 or distressLocation[1] >= ScenarioInfo.size[1] or
                                    distressLocation[3] >= ScenarioInfo.size[2] then
                                --LOG('*AI DEBUG: POOLDISTRESSAI SENDING UNITS TO WRONG LOCATION')
                            end
                            IssueAggressiveMove(group, distressLocation)
                            IssueMove(group, aiBrain:PBMGetLocationCoords(locData.LocationType))
                            locData.DistressCall = true
                            self:ForkThread(self.UnlockPBMDistressLocation, locData)
                        end
                    end
                end
            end
            WaitSeconds(aiBrain.BaseMonitor.PoolReactionTime)
        end
    end,

    UnlockPBMDistressLocation = function(self, locData)
        WaitSeconds(15)
        locData.DistressCall = false
    end,

    BaseManagersDistressAI = function(self)
        local aiBrain = self:GetBrain()
        while aiBrain:PlatoonExists(self) do
            local distressRange = aiBrain.BaseMonitor.PoolDistressRange
            local reactionTime = aiBrain.BaseMonitor.PoolReactionTime

            local platoonUnits = self:GetPlatoonUnits()

            for locName, locData in aiBrain.BuilderManagers do
                if not locData.BaseSettings.DistressCall then
                    local position = locData.EngineerManager:GetLocationCoords()
                    local radius = locData.EngineerManager:GetLocationRadius()
                    local distressRange = locData.BaseSettings.DistressRange or aiBrain.BaseMonitor.PoolDistressRange
                    local distressLocation = aiBrain:BaseMonitorDistressLocation(position, distressRange, aiBrain.BaseMonitor.PoolDistressThreshold)

                    -- Distress !
                    if distressLocation then
                        --LOG('*AI DEBUG: ARMY '.. aiBrain:GetArmyIndex() ..': --- POOL DISTRESS RESPONSE ---')

                        -- Grab the units at the location
                        local group = self:GetUnitsAroundPoint(categories.MOBILE, position, radius)

                        -- Move the group to the distress location and then back to the location of the base
                        IssueClearCommands(group)
                        IssueAggressiveMove(group, distressLocation)
                        IssueMove(group, position)

                        -- Set distress active for duration
                        locData.BaseSettings.DistressCall = true
                        self:ForkThread(self.UnlockBaseManagerDistressLocation, locData)
                    end
                end
            end
            WaitSeconds(aiBrain.BaseMonitor.PoolReactionTime)
        end
    end,

    UnlockBaseManagerDistressLocation = function(self, locData)
        WaitSeconds(15)
        locData.BaseSettings.DistressCall = false
    end,

    DisbandAI = function(self)
        self:Stop()
        self:PlatoonDisband()
    end,

    CaptureAI = function(self)
        local engineers = {}
        local notEngineers = {}

        for k, unit in self:GetPlatoonUnits() do
            if EntityCategoryContains(categories.ENGINEER, unit) then
                table.insert(engineers, unit)
            else
                table.insert(notEngineers, unit)
            end
        end

        self:Stop()
        local aiBrain = self:GetBrain()
        local index = aiBrain:GetArmyIndex()
        local data = self.PlatoonData
        local pos = self:GetPlatoonPosition()
        local radius = data.Radius or 100
        if not data.Categories then
            error('PLATOON.LUA ERROR- CaptureAI requires Categories field',2)
        end

        local checkThreat = false
        if data.ThreatMin and data.ThreatMax and data.ThreatRings then
            checkThreat = true
        end
        while aiBrain:PlatoonExists(self) do
            local target = AIAttackUtils.AIFindUnitRadiusThreat(aiBrain, 'Enemy', data.Categories, pos, radius, data.ThreatMin, data.ThreatMax, data.ThreatRings)
            if target and not target.Dead then
                local blip = target:GetBlip(index)
                if blip then
                    IssueClearCommands(self:GetPlatoonUnits())
                    IssueCapture(engineers, target)
                    local guardTarget

                    for i, unit in engineers do
                        if not unit.Dead then
                            IssueGuard(notEngineers, unit)
                            break
                        end
                    end

                    local allIdle
                    repeat
                        WaitSeconds(2)
                        if not aiBrain:PlatoonExists(self) then
                            return
                        end
                        allIdle = true
                        for k,v in self:GetPlatoonUnits() do
                            if not v.Dead and not v:IsIdleState() then
                                allIdle = false
                                break
                            end
                        end
                    until allIdle or blip:BeenDestroyed() or blip:IsKnownFake(index) or blip:IsMaybeDead(index)
                end
            else
                if data.TransportReturn then
                    local retPos = ScenarioUtils.MarkerToPosition(data.TransportReturn)
                    self:MoveToLocation(retPos, false)

                    local rect = {x0 = retPos[1]-10, y0 = retPos[3]-10, x1 = retPos[1]+10, y1 = retPos[3]+10}
                    while true do
                        local alive = 0
                        local cnt = 0
                        for k,unit in self:GetPlatoonUnits() do
                            if not unit.Dead then
                                alive = alive + 1

                                if ScenarioUtils.InRect(unit:GetPosition(), rect) then
                                    cnt = cnt + 1
                                end
                            end
                        end

                        if cnt >= alive then
                            break
                        end
                        WaitTicks(5)
                    end

                    self:ForkThread(SPAI.LandAssaultWithTransports, self)
                    break
                else
                    local location = AIUtils.RandomLocation(aiBrain:GetArmyStartPos())
                    self:MoveToLocation(location, false)
                    self:PlatoonDisband()
                end
            end
            WaitSeconds(1)
        end
    end,

    --DUNCAN - credit to Sorian
    ReclaimStructuresAI = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local data = self.PlatoonData
        local radius = aiBrain:PBMGetLocationRadius(data.Location)
        local categories = data.Reclaim
        local counter = 0
        while aiBrain:PlatoonExists(self) do
            local unitPos = self:GetPlatoonPosition()
            local reclaimunit = false
            local distance = false
            for num,cat in categories do
                local reclaimcat = ParseEntityCategory(cat)
                local reclaimables = aiBrain:GetListOfUnits(reclaimcat, false)
                for k,v in reclaimables do
                    if not v.Dead and (not reclaimunit or VDist3(unitPos, v:GetPosition()) < distance) and unitPos then
                        reclaimunit = v
                        distance = VDist3(unitPos, v:GetPosition())
                    end
                end
                if reclaimunit then break end
            end
            if reclaimunit and not reclaimunit.Dead then
                counter = 0
                IssueReclaim(self:GetPlatoonUnits(), reclaimunit)
                -- Set ReclaimInProgress to prevent repairing (see RepairAI)
                reclaimunit.ReclaimInProgress = true
                local allIdle
                repeat
                    WaitSeconds(2)
                    if not aiBrain:PlatoonExists(self) then
                        return
                    end
                    allIdle = true
                    for k,v in self:GetPlatoonUnits() do
                        if not v.Dead and not v:IsIdleState() then
                            allIdle = false
                            break
                        end
                    end
                until allIdle
            elseif not reclaimunit or counter >= 5 then
                self:PlatoonDisband()
            else
                counter = counter + 1
                WaitSeconds(5)
            end
        end
    end,

    ReclaimAI = function(self)
        self:Stop()
        local brain = self:GetBrain()
        local locationType = self.PlatoonData.LocationType
        local createTick = GetGameTick()
        local oldClosest
        local units = self:GetPlatoonUnits()
        local eng = units[1]
        if not eng then
            self:PlatoonDisband()
            return
        end

        eng.BadReclaimables = eng.BadReclaimables or {}

        while brain:PlatoonExists(self) do
            local ents = AIUtils.AIGetReclaimablesAroundLocation(brain, locationType) or {}
            local pos = self:GetPlatoonPosition()

            if not ents[1] or not pos then
                WaitTicks(1)
                self:PlatoonDisband()
                return
            end

            local reclaim = {}
            local needEnergy = brain:GetEconomyStoredRatio('ENERGY') < 0.5

            for k,v in ents do
                if not IsProp(v) or eng.BadReclaimables[v] then continue end
                if not needEnergy or v.MaxEnergyReclaim then
                    local rpos = v:GetCachePosition()
                    table.insert(reclaim, {entity=v, pos=rpos, distance=VDist2(pos[1], pos[3], rpos[1], rpos[3])})
                end
            end

            IssueClearCommands(units)
            table.sort(reclaim, function(a, b) return a.distance < b.distance end)

            local recPos = nil
            local closest = {}
            for i, r in reclaim do
                -- This is slowing down the whole sim when engineers start's reclaiming, and every engi is pathing with CanPathTo (r.pos)
                -- even if the engineer will run into walls, it is only reclaimig and don't justifies the huge CPU cost. (Simspeed droping from +9 to +3 !!!!)
                -- eng.BadReclaimables[r.entity] = r.distance > 10 and not eng:CanPathTo (r.pos)
                eng.BadReclaimables[r.entity] = r.distance > 20
                if not eng.BadReclaimables[r.entity] then
                    IssueReclaim(units, r.entity)
                    if i > 10 then break end
                end
            end

            local reclaiming = not eng:IsIdleState()
            local max_time = self.PlatoonData.ReclaimTime

            while reclaiming do
                WaitSeconds(5)

                if eng:IsIdleState() or (max_time and (GetGameTick() - createTick)*10 > max_time) then
                    reclaiming = false
                end
            end

            local basePosition = brain.BuilderManagers[locationType].Position
            local location = AIUtils.RandomLocation(basePosition[1],basePosition[3])
            self:MoveToLocation(location, false)
            WaitSeconds(10)
            self:PlatoonDisband()
        end
    end,

    ReclaimUnitsAI = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local index = aiBrain:GetArmyIndex()
        local data = self.PlatoonData
        local pos = self:GetPlatoonPosition()
        local radius = data.Radius or 500
        if not data.Categories then
            error('PLATOON.LUA ERROR- ReclaimUnitsAI requires Categories field',2)
        end

        local checkThreat = false
        if data.ThreatMin and data.ThreatMax and data.ThreatRings then
            checkThreat = true
        end
        while aiBrain:PlatoonExists(self) do
            local target = AIAttackUtils.AIFindUnitRadiusThreat(aiBrain, 'Enemy', data.Categories, pos, radius, data.ThreatMin, data.ThreatMax, data.ThreatRings)
            if target and not target.Dead then
                local blip = target:GetBlip(index)
                if blip then
                    IssueClearCommands(self:GetPlatoonUnits())
                    IssueReclaim(self:GetPlatoonUnits(), target)
                    local allIdle
                    repeat
                        WaitSeconds(2)
                        if not aiBrain:PlatoonExists(self) then
                            return
                        end
                        allIdle = true
                        for k,v in self:GetPlatoonUnits() do
                            if not v.Dead and not v:IsIdleState() then
                                allIdle = false
                                break
                            end
                        end
                    until allIdle or blip:BeenDestroyed() or blip:IsKnownFake(index) or blip:IsMaybeDead(index)
                else
                    WaitSeconds(2)
                end
            else
                local location = AIUtils.RandomLocation(aiBrain:GetArmyStartPos())
                self:MoveToLocation(location, false)
                self:PlatoonDisband()
            end
            WaitSeconds(1)
        end
    end,

    --DUNCAN - credit to Sorian
    RepairAI = function(self)
        if not self.PlatoonData or not self.PlatoonData.LocationType then
            self:PlatoonDisband()
        end
        local eng = self:GetPlatoonUnits()[1]
        --LOG('*AI DEBUG: Engineer Repairing')
        local aiBrain = self:GetBrain()
        local engineerManager = aiBrain.BuilderManagers[self.PlatoonData.LocationType].EngineerManager
        local Structures = AIUtils.GetOwnUnitsAroundPoint(aiBrain, categories.STRUCTURE - (categories.TECH1 - categories.FACTORY), engineerManager:GetLocationCoords(), engineerManager:GetLocationRadius())
        for k,v in Structures do
            -- prevent repairing a unit while reclaim is in progress (see ReclaimStructuresAI)
            if not v.Dead and not v.ReclaimInProgress and v:GetHealthPercent() < .8 then
                self:Stop()
                IssueRepair(self:GetPlatoonUnits(), v)
                break
            end
        end
        local count = 0
        repeat
            WaitSeconds(2)
            if not aiBrain:PlatoonExists(self) then
                return
            end
            count = count + 1
            allIdle = true
            if not eng:IsIdleState() then allIdle = false end
        until allIdle or count >= 30
        self:PlatoonDisband()
    end,

    --DUNCAN - credit to Sorian
    ManagerEngineerFindUnfinished = function(self)
        local aiBrain = self:GetBrain()
        local beingBuilt = false
        self:EconUnfinishedBody()
        WaitSeconds(20)
        local eng = self:GetPlatoonUnits()[1]
        if eng.UnitBeingBuilt then
            beingBuilt = eng.UnitBeingBuilt
        end
        if beingBuilt then
            while not beingBuilt:BeenDestroyed() and beingBuilt:GetFractionComplete() < 1 do
                WaitSeconds(5)
            end
        end
        if not aiBrain:PlatoonExists(self) then
            return
        end
        -- stop the platoon from endless assisting
        self:Stop()
        self:PlatoonDisband()
    end,

    EconUnfinishedBody = function(self)
        local eng = self:GetPlatoonUnits()[1]
        if not eng then
            self:PlatoonDisband()
            return
        end
        local aiBrain = self:GetBrain()
        local assistData = self.PlatoonData.Assist
        local assistee = false

        --eng.AssistPlatoon = self

        if not assistData.AssistLocation then
            WARN('*AI WARNING: Disbanding EconUnfinishedBody platoon that does not have either AssistLocation')
            self:PlatoonDisband()
        end

        local beingBuilt = assistData.BeingBuiltCategories or { 'ALLUNITS' }

        -- loop through different categories we are looking for
        for _,catString in beingBuilt do
            -- Track all valid units in the assist list so we can load balance for factories

            local category = ParseEntityCategory(catString)

            local assistList = SUtils.FindUnfinishedUnits(aiBrain, assistData.AssistLocation, category)

            if assistList then
                assistee = assistList
                break
            end
        end
        -- assist unit
        if assistee then
            self:Stop()
            eng.AssistSet = true
            IssueGuard({eng}, assistee)
        else
        -- stop the platoon from endless assisting
        self:Stop()
            self:PlatoonDisband()
        end
    end,

    ManagerEngineerAssistAI = function(self)
        local aiBrain = self:GetBrain()
        self:EconAssistBody()
        WaitSeconds(self.PlatoonData.AssistData.Time or 60)
        if not aiBrain:PlatoonExists(self) then
            return
        end
        self.AssistPlatoon = nil
        -- stop the platoon from endless assisting
        self:Stop()
        self:PlatoonDisband()
    end,

    EconAssistBody = function(self)
        local eng = self:GetPlatoonUnits()[1]
        if not eng then
            self:PlatoonDisband()
            return
        end

        --DUNCAN - added
        if eng:IsUnitState('Building') or eng:IsUnitState('Upgrading') or  eng:IsUnitState("Enhancing") then
           return
        end

        local aiBrain = self:GetBrain()
        local assistData = self.PlatoonData.Assist
        local assistee = false

        local assistRange = assistData.AssistRange or 80
        local platoonPos = self:GetPlatoonPosition()

        eng.AssistPlatoon = self

        if not assistData.AssistLocation or not assistData.AssisteeType then
            WARN('*AI WARNING: Disbanding Assist platoon that does not have either AssistLocation or AssisteeType')
            self:PlatoonDisband()
        end

        local beingBuilt = assistData.BeingBuiltCategories or { 'ALLUNITS' }

        local assisteeCat = assistData.AssisteeCategory or categories.ALLUNITS
        if type(assisteeCat) == 'string' then
            assisteeCat = ParseEntityCategory(assisteeCat)
        end

        -- loop through different categories we are looking for
        for _,catString in beingBuilt do
            -- Track all valid units in the assist list so we can load balance for factories

            local category = ParseEntityCategory(catString)

            local assistList = AIUtils.GetAssistees(aiBrain, assistData.AssistLocation, assistData.AssisteeType, category, assisteeCat)

            if table.getn(assistList) > 0 then
                -- only have one unit in the list; assist it
                if table.getn(assistList) == 1 then
                    assistee = assistList[1]
                    break
                else
                    -- Find the unit with the least number of assisters; assist it
                    local lowNum = false
                    local lowUnit = false

                    for k,v in assistList do
                        --DUNCAN - check unit is inside assist range
                        local unitPos = v:GetPosition()
                        if not lowNum or (table.getn(v:GetGuards()) < lowNum
                        and VDist2(platoonPos[1], platoonPos[3], unitPos[1], unitPos[3]) < assistRange) then
                            lowNum = v:GetGuards()
                            lowUnit = v
                        end
                    end
                    assistee = lowUnit
                    break
                end
            end
        end
        -- assist unit
        if assistee  then
            self:Stop()
            eng.AssistSet = true
            IssueGuard({eng}, assistee)
        else
            self.AssistPlatoon = nil
            -- stop the platoon from endless assisting
            self:Stop()
            self:PlatoonDisband()
        end
    end,

    AssistBody = function(self)
        local platoonUnits = self:GetPlatoonUnits()
        local eng = platoonUnits[1]
        eng.AssistPlatoon = self
        local aiBrain = self:GetBrain()
        local assistData = self.PlatoonData.Assist
        local platoonPos = self:GetPlatoonPosition()
        local assistee = false
        local assistingBool = false
        WaitTicks(5)
        if not aiBrain:PlatoonExists(self) then
            return
        end
        if not eng.Dead then
            local guardedUnit = eng:GetGuardedUnit()
            if guardedUnit and not guardedUnit.Dead then
                if eng.AssistSet and assistData.PermanentAssist then
                    return
                end
                eng.AssistSet = false
                if guardedUnit:IsUnitState('Building') or guardedUnit:IsUnitState('Upgrading') then
                    return
                end
            end
        end
        self:Stop()
        if assistData then
            local assistRange = assistData.AssistRange or 80
            -- Check for units being built
            if assistData.BeingBuiltCategories then
                local unitsBuilding = aiBrain:GetListOfUnits(categories.CONSTRUCTION, false)
                for catNum, buildeeCat in assistData.BeingBuiltCategories do
                    local buildCat = ParseEntityCategory(buildeeCat)
                    for unitNum, unit in unitsBuilding do
                        if not unit.Dead and (unit:IsUnitState('Building') or unit:IsUnitState('Upgrading')) then
                            local buildingUnit = unit.UnitBeingBuilt
                            if buildingUnit and not buildingUnit.Dead and EntityCategoryContains(buildCat, buildingUnit) then
                                local unitPos = unit:GetPosition()
                                if unitPos and platoonPos and VDist2(platoonPos[1], platoonPos[3], unitPos[1], unitPos[3]) < assistRange then
                                    assistee = unit
                                    break
                                end
                            end
                        end
                    end
                    if assistee then
                        break
                    end
                end
            end
            -- Check for builders
            if not assistee and assistData.BuilderCategories then
                for catNum, buildCat in assistData.BuilderCategories do
                    local unitsBuilding = aiBrain:GetListOfUnits(ParseEntityCategory(buildCat), false)
                    for unitNum, unit in unitsBuilding do
                        if not unit.Dead and unit:IsUnitState('Building') then
                            local unitPos = unit:GetPosition()
                            if unitPos and platoonPos and VDist2(platoonPos[1], platoonPos[3], unitPos[1], unitPos[3]) < assistRange then
                                assistee = unit
                                break
                            end
                        end
                    end
                end
            end
            -- If the unit to be assisted is a factory, assist whatever it is assisting or is assisting it
            -- Makes sure all factories have someone helping out to load balance better
            if assistee and not assistee.Dead and EntityCategoryContains(categories.FACTORY, assistee) then
                local guardee = assistee:GetGuardedUnit()
                if guardee and not guardee.Dead and EntityCategoryContains(categories.FACTORY, guardee) then
                    local factories = AIUtils.AIReturnAssistingFactories(guardee)
                    table.insert(factories, assistee)
                    AIUtils.AIEngineersAssistFactories(aiBrain, platoonUnits, factories)
                    assistingBool = true
                elseif table.getn(assistee:GetGuards()) > 0 then
                    local factories = AIUtils.AIReturnAssistingFactories(assistee)
                    table.insert(factories, assistee)
                    AIUtils.AIEngineersAssistFactories(aiBrain, platoonUnits, factories)
                    assistingBool = true
                end
            end
        end
        if assistee and not assistee.Dead then
            if not assistingBool then
                eng.AssistSet = true
                IssueGuard(platoonUnits, assistee)
            end
        elseif not assistee then
            if eng.BuilderManagerData then
                local emLoc = eng.BuilderManagerData.EngineerManager:GetLocationCoords()
                local dist = assistData.AssistRange or 80
                if VDist3(eng:GetPosition(), emLoc) > dist then
                    self:MoveToLocation(emLoc, false)
                    WaitSeconds(9)
                end
            end
            WaitSeconds(1)
            self.AssistPlatoon = nil
            -- stop the platoon from endless assisting
            self:Stop()
            self:PlatoonDisband()
        end
    end,

    EngineerAssistAI = function(self)
        self:ForkThread(self.AssistBody)
        local aiBrain = self:GetBrain()
        WaitSeconds(self.PlatoonData.AssistData.Time or 60)
        if not aiBrain:PlatoonExists(self) then
            return
        end
        self.AssistPlatoon = nil
        WaitTicks(1)
        -- stop the platoon from endless assisting
        self:Stop()
        self:PlatoonDisband()
    end,


    -------------------------------------------------------
    --   Function: EngineerBuildAI
    --   Args:
    --       self - the single-engineer platoon to run the AI on
    --   Description:
    --       a single-unit platoon made up of an engineer, this AI will determine
    --       what needs to be built (based on platoon data set by the calling
    --       abstraction, and then issue the build commands to the engineer
    --   Returns:
    --       nil (tail calls into a behavior function)
    -------------------------------------------------------
    EngineerBuildAI = function(self)
        --DUNCAN - removed
        --self:Stop()

        local aiBrain = self:GetBrain()
        local platoonUnits = self:GetPlatoonUnits()
        local armyIndex = aiBrain:GetArmyIndex()
        local x,z = aiBrain:GetArmyStartPos()
        local cons = self.PlatoonData.Construction
        local buildingTmpl, buildingTmplFile, baseTmpl, baseTmplFile

        local factionIndex = cons.FactionIndex or self:GetFactionIndex()

        buildingTmplFile = import(cons.BuildingTemplateFile or '/lua/BuildingTemplates.lua')
        baseTmplFile = import(cons.BaseTemplateFile or '/lua/BaseTemplates.lua')
        buildingTmpl = buildingTmplFile[(cons.BuildingTemplate or 'BuildingTemplates')][factionIndex]
        baseTmpl = baseTmplFile[(cons.BaseTemplate or 'BaseTemplates')][factionIndex]

        -- Old version of delaying the build of an experimental.
        -- This was implemended but a depricated function from sorian AI. 
        -- makes the same as the new DelayEqualBuildPlattons. Can be deleted if all platoons are rewritten to DelayEqualBuildPlattons
        -- (This is also the wrong place to do it. Should be called from Buildermanager BEFORE the builder is selected)
        if cons.T4 then
            if not aiBrain.T4Building then
                --LOG('EngineerBuildAI'..repr(cons))
                aiBrain.T4Building = true
                ForkThread(SUtils.T4Timeout, aiBrain)
                --LOG('Building T4 uinit, delaytime started')
            else
                --LOG('BLOCK building T4 unit; aiBrain.T4Building = TRUE')
                WaitTicks(1)
                self:PlatoonDisband()
                return
            end
        end

        local eng
        for k, v in platoonUnits do
            if not v.Dead and EntityCategoryContains(categories.ENGINEER, v) then --DUNCAN - was construction
                if not eng then
                    eng = v
                else
                    IssueClearCommands({v})
                    IssueGuard({v}, eng)
                end
            end
        end

        if not eng or eng.Dead then
            WaitTicks(1)
            self:PlatoonDisband()
            return
        end

        --DUNCAN - added
        if eng:IsUnitState('Building') or eng:IsUnitState('Upgrading') or  eng:IsUnitState("Enhancing") then
           return
        end

        --LOG('*AI DEBUG: EngineerBuild AI ' .. eng.Sync.id)

        if self.PlatoonData.NeedGuard then
            eng.NeedGuard = true
        end

        -------- CHOOSE APPROPRIATE BUILD FUNCTION AND SETUP BUILD VARIABLES --------
        local reference = false
        local refName = false
        local buildFunction
        local closeToBuilder
        local relative
        local baseTmplList = {}

        -- if we have nothing to build, disband!
        if not cons.BuildStructures then
            WaitTicks(1)
            self:PlatoonDisband()
            return
        end
        if cons.NearUnitCategory then
            self:SetPrioritizedTargetList('support', {ParseEntityCategory(cons.NearUnitCategory)})
            local unitNearBy = self:FindPrioritizedUnit('support', 'Ally', false, self:GetPlatoonPosition(), cons.NearUnitRadius or 50)
            --LOG("ENGINEER BUILD: " .. cons.BuildStructures[1] .." attempt near: ", cons.NearUnitCategory)
            if unitNearBy then
                reference = table.copy(unitNearBy:GetPosition())
                -- get commander home position
                --LOG("ENGINEER BUILD: " .. cons.BuildStructures[1] .." Near unit: ", cons.NearUnitCategory)
                if cons.NearUnitCategory == 'COMMAND' and unitNearBy.CDRHome then
                    reference = unitNearBy.CDRHome
                end
            else
                reference = table.copy(eng:GetPosition())
            end
            relative = false
            buildFunction = AIBuildStructures.AIExecuteBuildStructure
            table.insert(baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation(baseTmpl, reference))
        elseif cons.Wall then
            local pos = aiBrain:PBMGetLocationCoords(cons.LocationType) or cons.Position or self:GetPlatoonPosition()
            local radius = cons.LocationRadius or aiBrain:PBMGetLocationRadius(cons.LocationType) or 100
            relative = false
            reference = AIUtils.GetLocationNeedingWalls(aiBrain, 200, 4, 'STRUCTURE - WALLS', cons.ThreatMin, cons.ThreatMax, cons.ThreatRings)
            table.insert(baseTmplList, 'Blank')
            buildFunction = AIBuildStructures.WallBuilder
        elseif cons.NearBasePatrolPoints then
            relative = false
            reference = AIUtils.GetBasePatrolPoints(aiBrain, cons.Location or 'MAIN', cons.Radius or 100)
            baseTmpl = baseTmplFile['ExpansionBaseTemplates'][factionIndex]
            for k,v in reference do
                table.insert(baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation(baseTmpl, v))
            end
            -- Must use BuildBaseOrdered to start at the marker; otherwise it builds closest to the eng
            buildFunction = AIBuildStructures.AIBuildBaseTemplateOrdered
        elseif cons.FireBase and cons.FireBaseRange then
            --DUNCAN - pulled out and uses alt finder
            reference, refName = AIUtils.AIFindFirebaseLocation(aiBrain, cons.LocationType, cons.FireBaseRange, cons.NearMarkerType,
                                                cons.ThreatMin, cons.ThreatMax, cons.ThreatRings, cons.ThreatType,
                                                cons.MarkerUnitCount, cons.MarkerUnitCategory, cons.MarkerRadius)
            if not reference or not refName then
                self:PlatoonDisband()
            end

        elseif cons.NearMarkerType and cons.ExpansionBase then
            local pos = aiBrain:PBMGetLocationCoords(cons.LocationType) or cons.Position or self:GetPlatoonPosition()
            local radius = cons.LocationRadius or aiBrain:PBMGetLocationRadius(cons.LocationType) or 100

            if cons.NearMarkerType == 'Expansion Area' then
                reference, refName = AIUtils.AIFindExpansionAreaNeedsEngineer(aiBrain, cons.LocationType,
                        (cons.LocationRadius or 100), cons.ThreatMin, cons.ThreatMax, cons.ThreatRings, cons.ThreatType)
                -- didn't find a location to build at
                if not reference or not refName then
                    self:PlatoonDisband()
                end
            elseif cons.NearMarkerType == 'Naval Area' then
                reference, refName = AIUtils.AIFindNavalAreaNeedsEngineer(aiBrain, cons.LocationType,
                        (cons.LocationRadius or 100), cons.ThreatMin, cons.ThreatMax, cons.ThreatRings, cons.ThreatType)
                -- didn't find a location to build at
                if not reference or not refName then
                    self:PlatoonDisband()
                end
            else
                --DUNCAN - use my alternative expansion finder on large maps below a certain time
                local mapSizeX, mapSizeZ = GetMapSize()
                if GetGameTimeSeconds() <= 780 and mapSizeX > 512 and mapSizeZ > 512 then
                    reference, refName = AIUtils.AIFindFurthestStartLocationNeedsEngineer(aiBrain, cons.LocationType,
                        (cons.LocationRadius or 100), cons.ThreatMin, cons.ThreatMax, cons.ThreatRings, cons.ThreatType)
                    if not reference or not refName then
                        reference, refName = AIUtils.AIFindStartLocationNeedsEngineer(aiBrain, cons.LocationType,
                            (cons.LocationRadius or 100), cons.ThreatMin, cons.ThreatMax, cons.ThreatRings, cons.ThreatType)
                    end
                else
                    reference, refName = AIUtils.AIFindStartLocationNeedsEngineer(aiBrain, cons.LocationType,
                        (cons.LocationRadius or 100), cons.ThreatMin, cons.ThreatMax, cons.ThreatRings, cons.ThreatType)
                end
                -- didn't find a location to build at
                if not reference or not refName then
                    self:PlatoonDisband()
                end
            end

            -- If moving far from base, tell the assisting platoons to not go with
            if cons.FireBase or cons.ExpansionBase then
                local guards = eng:GetGuards()
                for k,v in guards do
                    if not v.Dead and v.PlatoonHandle then
                        v.PlatoonHandle:PlatoonDisband()
                    end
                end
            end

            if not cons.BaseTemplate and (cons.NearMarkerType == 'Naval Area' or cons.NearMarkerType == 'Defensive Point' or cons.NearMarkerType == 'Expansion Area') then
                baseTmpl = baseTmplFile['ExpansionBaseTemplates'][factionIndex]
            end
            if cons.ExpansionBase and refName then
                AIBuildStructures.AINewExpansionBase(aiBrain, refName, reference, eng, cons)
            end
            relative = false
            if reference and aiBrain:GetThreatAtPosition(reference , 1, true, 'AntiSurface') > 0 then
                --aiBrain:ExpansionHelp(eng, reference)
            end
            table.insert(baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation(baseTmpl, reference))
            -- Must use BuildBaseOrdered to start at the marker; otherwise it builds closest to the eng
            --buildFunction = AIBuildStructures.AIBuildBaseTemplateOrdered
            buildFunction = AIBuildStructures.AIBuildBaseTemplate
        elseif cons.NearMarkerType and cons.NearMarkerType == 'Defensive Point' then
            baseTmpl = baseTmplFile['ExpansionBaseTemplates'][factionIndex]

            relative = false
            local pos = self:GetPlatoonPosition()
            reference, refName = AIUtils.AIFindDefensivePointNeedsStructure(aiBrain, cons.LocationType, (cons.LocationRadius or 100),
                            cons.MarkerUnitCategory, cons.MarkerRadius, cons.MarkerUnitCount, (cons.ThreatMin or 0), (cons.ThreatMax or 1),
                            (cons.ThreatRings or 1), (cons.ThreatType or 'AntiSurface'))

            table.insert(baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation(baseTmpl, reference))

            buildFunction = AIBuildStructures.AIExecuteBuildStructure
        elseif cons.NearMarkerType and cons.NearMarkerType == 'Naval Defensive Point' then
            baseTmpl = baseTmplFile['ExpansionBaseTemplates'][factionIndex]

            relative = false
            local pos = self:GetPlatoonPosition()
            reference, refName = AIUtils.AIFindNavalDefensivePointNeedsStructure(aiBrain, cons.LocationType, (cons.LocationRadius or 100),
                            cons.MarkerUnitCategory, cons.MarkerRadius, cons.MarkerUnitCount, (cons.ThreatMin or 0), (cons.ThreatMax or 1),
                            (cons.ThreatRings or 1), (cons.ThreatType or 'AntiSurface'))

            table.insert(baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation(baseTmpl, reference))

            buildFunction = AIBuildStructures.AIExecuteBuildStructure
        elseif cons.NearMarkerType and (cons.NearMarkerType == 'Rally Point' or cons.NearMarkerType == 'Protected Experimental Construction') then
            --DUNCAN - add so experimentals build on maps with no markers.
            if not cons.ThreatMin or not cons.ThreatMax or not cons.ThreatRings then
                cons.ThreatMin = -1000000
                cons.ThreatMax = 1000000
                cons.ThreatRings = 0
            end
            relative = false
            local pos = self:GetPlatoonPosition()
            reference, refName = AIUtils.AIGetClosestThreatMarkerLoc(aiBrain, cons.NearMarkerType, pos[1], pos[3],
                                                            cons.ThreatMin, cons.ThreatMax, cons.ThreatRings)
            if not reference then
                reference = pos
            end
            table.insert(baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation(baseTmpl, reference))
            buildFunction = AIBuildStructures.AIExecuteBuildStructure
        elseif cons.NearMarkerType then
            --WARN('*Data weird for builder named - ' .. self.BuilderName)
            if not cons.ThreatMin or not cons.ThreatMax or not cons.ThreatRings then
                cons.ThreatMin = -1000000
                cons.ThreatMax = 1000000
                cons.ThreatRings = 0
            end
            if not cons.BaseTemplate and (cons.NearMarkerType == 'Defensive Point' or cons.NearMarkerType == 'Expansion Area') then
                baseTmpl = baseTmplFile['ExpansionBaseTemplates'][factionIndex]
            end
            relative = false
            local pos = self:GetPlatoonPosition()
            reference, refName = AIUtils.AIGetClosestThreatMarkerLoc(aiBrain, cons.NearMarkerType, pos[1], pos[3],
                                                            cons.ThreatMin, cons.ThreatMax, cons.ThreatRings)
            if cons.ExpansionBase and refName then
                AIBuildStructures.AINewExpansionBase(aiBrain, refName, reference, (cons.ExpansionRadius or 100), cons.ExpansionTypes, nil, cons)
            end
            if reference and aiBrain:GetThreatAtPosition(reference, 1, true) > 0 then
                --aiBrain:ExpansionHelp(eng, reference)
            end
            table.insert(baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation(baseTmpl, reference))
            buildFunction = AIBuildStructures.AIExecuteBuildStructure
        elseif cons.AvoidCategory then
            relative = false
            local pos = aiBrain.BuilderManagers[eng.BuilderManagerData.LocationType].EngineerManager:GetLocationCoords()
            local cat = cons.AdjacencyCategory
            -- convert text categories like 'MOBILE AIR' to 'categories.MOBILE * categories.AIR'
            if type(cat) == 'string' then
                cat = ParseEntityCategory(cat)
            end
            local avoidCat = cons.AvoidCategory
            -- convert text categories like 'MOBILE AIR' to 'categories.MOBILE * categories.AIR'
            if type(avoidCat) == 'string' then
                avoidCat = ParseEntityCategory(avoidCat)
            end
            local radius = (cons.AdjacencyDistance or 50)
            if not pos or not pos then
                WaitTicks(1)
                self:PlatoonDisband()
                return
            end
            reference  = AIUtils.FindUnclutteredArea(aiBrain, cat, pos, radius, cons.maxUnits, cons.maxRadius, avoidCat)
            buildFunction = AIBuildStructures.AIBuildAdjacency
            table.insert(baseTmplList, baseTmpl)
        elseif cons.AdjacencyCategory then
            relative = false
            local pos = aiBrain.BuilderManagers[eng.BuilderManagerData.LocationType].EngineerManager:GetLocationCoords()
            local cat = cons.AdjacencyCategory
            -- convert text categories like 'MOBILE AIR' to 'categories.MOBILE * categories.AIR'
            if type(cat) == 'string' then
                cat = ParseEntityCategory(cat)
            end
            local radius = (cons.AdjacencyDistance or 50)
            local radius = (cons.AdjacencyDistance or 50)
            if not pos or not pos then
                WaitTicks(1)
                self:PlatoonDisband()
                return
            end
            reference  = AIUtils.GetOwnUnitsAroundPoint(aiBrain, cat, pos, radius, cons.ThreatMin,
                                                        cons.ThreatMax, cons.ThreatRings)
            buildFunction = AIBuildStructures.AIBuildAdjacency
            table.insert(baseTmplList, baseTmpl)
        else
            table.insert(baseTmplList, baseTmpl)
            relative = true
            reference = true
            buildFunction = AIBuildStructures.AIExecuteBuildStructure
        end
        if cons.BuildClose then
            closeToBuilder = eng
        end
        if cons.BuildStructures[1] == 'T1Resource' or cons.BuildStructures[1] == 'T2Resource' or cons.BuildStructures[1] == 'T3Resource' then
            relative = true
            closeToBuilder = eng
            local guards = eng:GetGuards()
            for k,v in guards do
                if not v.Dead and v.PlatoonHandle and aiBrain:PlatoonExists(v.PlatoonHandle) then
                    v.PlatoonHandle:PlatoonDisband()
                end
            end
        end

        --LOG("*AI DEBUG: Setting up Callbacks for " .. eng.Sync.id)
        self.SetupEngineerCallbacks(eng)

        -------- BUILD BUILDINGS HERE --------
        for baseNum, baseListData in baseTmplList do
            for k, v in cons.BuildStructures do
                if aiBrain:PlatoonExists(self) then
                    if not eng.Dead then
                  local faction = SUtils.GetEngineerFaction(eng)
                  if aiBrain.CustomUnits[v] and aiBrain.CustomUnits[v][faction] then
                     local replacement = SUtils.GetTemplateReplacement(aiBrain, v, faction)
                     if replacement then
                        buildFunction(aiBrain, eng, v, closeToBuilder, relative, replacement, baseListData, reference, cons.NearMarkerType)
                     else
                        buildFunction(aiBrain, eng, v, closeToBuilder, relative, buildingTmpl, baseListData, reference, cons.NearMarkerType)
                     end
                  else
                     buildFunction(aiBrain, eng, v, closeToBuilder, relative, buildingTmpl, baseListData, reference, cons.NearMarkerType)
                  end
                    else
                        if aiBrain:PlatoonExists(self) then
                            WaitTicks(1)
                            self:PlatoonDisband()
                            return
                        end
                    end
                end
            end
        end

        -- wait in case we're still on a base
        if not eng.Dead then
            local count = 0
            while eng:IsUnitState('Attached') and count < 2 do
                WaitSeconds(6)
                count = count + 1
            end
        end

        if not eng:IsUnitState('Building') then
            return self.ProcessBuildCommand(eng, false)
        end
    end,

    --UpgradeAnEngineeringPlatoon
    UnitUpgradeAI = function(self)
        local aiBrain = self:GetBrain()
        local platoonUnits = self:GetPlatoonUnits()
        local factionIndex = aiBrain:GetFactionIndex()
        local FactionToIndex  = { UEF = 1, AEON = 2, CYBRAN = 3, SERAPHIM = 4, NOMADS = 5}
        local UnitBeingUpgradeFactionIndex = nil
        local upgradeIssued = false
        self:Stop()
        for k, v in platoonUnits do
            local upgradeID
            -- Get the factionindex from the unit to get the right update (in case we have captured this unit from another faction)
            UnitBeingUpgradeFactionIndex = FactionToIndex[v.factionCategory] or factionIndex
            
            if EntityCategoryContains(categories.MOBILE, v) then
                upgradeID = aiBrain:FindUpgradeBP(v:GetUnitId(), UnitUpgradeTemplates[UnitBeingUpgradeFactionIndex])
                -- if we can't find a UnitUpgradeTemplate for this unit, warn the programmer
                if not upgradeID then
                    -- Output: WARNING: [platoon.lua, line:xxx] *UnitUpgradeAI ERROR: Can\'t find UnitUpgradeTemplate for mobile unit: ABC1234
                    WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] *UnitUpgradeAI ERROR: Can\'t find UnitUpgradeTemplate for mobile unit: ' .. repr(v:GetUnitId()) )
                end
            else
                upgradeID = aiBrain:FindUpgradeBP(v:GetUnitId(), StructureUpgradeTemplates[UnitBeingUpgradeFactionIndex])
                -- if we can't find a StructureUpgradeTemplate for this unit, warn the programmer
                if not upgradeID then
                    -- Output: WARNING: [platoon.lua, line:xxx] *UnitUpgradeAI ERROR: Can\'t find StructureUpgradeTemplate for structure: ABC1234
                    WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] *UnitUpgradeAI ERROR: Can\'t find StructureUpgradeTemplate for structure: ' .. repr(v:GetUnitId()) .. '  factionIndex: ' .. repr(factionIndex) )
                end
            end
            if upgradeID and EntityCategoryContains(categories.STRUCTURE, v) and not v:CanBuild(upgradeID) then
                -- in case the unit can't upgrade with StructureUpgradeTemplate, warn the programmer
                -- Output: WARNING: [platoon.lua, line:xxx] *UnitUpgradeAI ERROR: Can\'t upgrade structure with StructureUpgradeTemplate: ABC1234
                WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] *UnitUpgradeAI ERROR: Can\'t upgrade structure with StructureUpgradeTemplate: ' .. repr(v:GetUnitId()) )
                continue
            end
            if upgradeID then
                upgradeIssued = true
                IssueUpgrade({v}, upgradeID)
            end
        end
        if not upgradeIssued then
            self:PlatoonDisband()
            return
        end
        local upgrading = true
        while aiBrain:PlatoonExists(self) and upgrading do
            WaitSeconds(3)
            upgrading = false
            for k, v in platoonUnits do
                if v and not v.Dead then
                    upgrading = true
                end
            end
        end
        if not aiBrain:PlatoonExists(self) then
            return
        end
        WaitTicks(1)
        self:PlatoonDisband()
    end,

    TransferAI = function(self)
        if not self.PlatoonData or not self.PlatoonData.LocationType then
            self:PlatoonDisband()
        end

        local aiBrain = self:GetBrain()
        if not aiBrain.BuilderManagers[self.PlatoonData.LocationType] then
            self:PlatoonDisband()
        end

        local eng = self:GetPlatoonUnits()[1]

        --LOG('*AI DEBUG: Transferring units to - ' .. self.PlatoonData.LocationType)

        eng.BuilderManagerData.EngineerManager:RemoveUnit(eng)
        aiBrain.BuilderManagers[self.PlatoonData.LocationType].EngineerManager:AddUnit(eng, true)
    end,

    RepairCDRAI = function(self)
        local aiBrain = self:GetBrain()
        local cdrUnits = aiBrain:GetListOfUnits(categories.COMMAND, false)
        for k,v in cdrUnits do
            if v:GetHealthPercent() < .8 then
                self:Stop()
                IssueRepair(self:GetPlatoonUnits(), v)
            end
        end
        self:PlatoonDisband()
    end,

    --DUNCAN - Credit to sorian, called AirHuntAI in his pack
    GunshipHuntAI = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local armyIndex = aiBrain:GetArmyIndex()
        local target
        local blip
        local hadtarget = false
        while aiBrain:PlatoonExists(self) do
            if self:IsOpponentAIRunning() then
                target = self:FindClosestUnit('Attack', 'Enemy', true, categories.EXPERIMENTAL * (categories.LAND + categories.NAVAL + categories.STRUCTURE))
                if not target then
                    target = self:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS - categories.WALL)
                end

                if target then
                    blip = target:GetBlip(armyIndex)
                    self:Stop()
                    self:AggressiveMoveToLocation(table.copy(target:GetPosition()))
                    hadtarget = true
                elseif not target and hadtarget then
                    local x,z = aiBrain:GetArmyStartPos()
                    local position = AIUtils.RandomLocation(x,z)
                    local safePath, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, 'Air', self:GetPlatoonPosition(), position, 200)
                    if safePath then
                        for _,p in safePath do
                            self:MoveToLocation(p, false)
                        end
                    else
                        self:MoveToLocation(position, false)
                    end
                    hadtarget = false
                end
            end
            WaitSeconds(17)
        end
    end,

    --DUNCAN - Credit to sorian, called FighterHuntAI in his pack
    InterceptorAI = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local armyIndex = aiBrain:GetArmyIndex()
        local target
        local blip
        local hadtarget = false
        local basePosition = false

        if self.PlatoonData.LocationType and self.PlatoonData.LocationType != 'NOTMAIN' then
            basePosition = aiBrain.BuilderManagers[self.PlatoonData.LocationType].Position
        else
            local platoonPosition = self:GetPlatoonPosition()
            if platoonPosition then
                basePosition = aiBrain:FindClosestBuilderManagerPosition(self:GetPlatoonPosition())
            end
        end

        if not basePosition then
            return
        end

        while aiBrain:PlatoonExists(self) do
            --if self:IsOpponentAIRunning() then
                target = self:FindClosestUnit('Attack', 'Enemy', true, categories.EXPERIMENTAL * categories.AIR)
                if not target then
                    target = self:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS - categories.WALL)
                end

                if target and target:GetFractionComplete() == 1 then
                    local airThreat = aiBrain:GetThreatAtPosition(table.copy(target:GetPosition()), 1, true, 'Air')
                    --LOG("Air threat: " .. airThreat)
                    local antiAirThreat = aiBrain:GetThreatAtPosition(table.copy(target:GetPosition()), 1, true, 'AntiAir') - airThreat
                    --LOG("AntiAir threat: " .. antiAirThreat)
                    if antiAirThreat < 1.5 then
                        blip = target:GetBlip(armyIndex)
                        self:Stop()
                        self:AggressiveMoveToLocation(table.copy(target:GetPosition()))
                        hadtarget = true
                    end
                elseif not target and hadtarget then
                    --DUNCAN - move back to base
                    local position = AIUtils.RandomLocation(basePosition[1],basePosition[3])
                    self:Stop()
                    self:MoveToLocation(position, false)

                    --DUNCAN - this doesnt seem to work
                    --for k,v in AIUtils.GetBasePatrolPoints(aiBrain, self.PlatoonData.Location or 'MAIN', self.PlatoonData.Radius or 100, 'Air') do
                    --      self:Patrol(v)
                    --end
                    hadtarget = false
                end
            --end
            WaitSeconds(5) --DUNCAN - was 5
        end
    end,

    StrikeForceAI = function(self)
        local aiBrain = self:GetBrain()
        local armyIndex = aiBrain:GetArmyIndex()
        local data = self.PlatoonData
        local categoryList = {}
        local atkPri = {}
        if data.PrioritizedCategories then
            for k,v in data.PrioritizedCategories do
                table.insert(atkPri, v)
                table.insert(categoryList, ParseEntityCategory(v))
            end
        end
        table.insert(atkPri, 'ALLUNITS')
        table.insert(categoryList, categories.ALLUNITS)
        self:SetPrioritizedTargetList('Attack', categoryList)
        local target
        local blip = false
        local maxRadius = data.SearchRadius or 50
        local movingToScout = false
        while aiBrain:PlatoonExists(self) do
            if not target or target.Dead then
                if aiBrain:GetCurrentEnemy() and aiBrain:GetCurrentEnemy():IsDefeated() then
                    aiBrain:PickEnemyLogic()
                end
                local mult = { 1,10,25 }
                for _,i in mult do
                    target = AIUtils.AIFindBrainTargetInRange(aiBrain, self, 'Attack', maxRadius * i, atkPri, aiBrain:GetCurrentEnemy())
                    if target then
                        break
                    end
                    WaitSeconds(1) --DUNCAN - was 3
                    if not aiBrain:PlatoonExists(self) then
                        return
                    end
                end

                --target = self:FindPrioritizedUnit('Attack', 'Enemy', true, self:GetPlatoonPosition(), maxRadius)

                --DUNCAN - added to target experimentals if they exist.
                local newtarget
                if AIAttackUtils.GetSurfaceThreatOfUnits(self) > 0 then
                    newtarget = self:FindClosestUnit('Attack', 'Enemy', true, categories.EXPERIMENTAL * (categories.LAND + categories.NAVAL + categories.STRUCTURE))
                elseif AIAttackUtils.GetAirThreatOfUnits(self) > 0 then
                    newtarget = self:FindClosestUnit('Attack', 'Enemy', true, categories.EXPERIMENTAL * categories.AIR)
                end
                if newtarget then
                    target = newtarget
                end

                if target then
                    self:Stop()
                    if not data.UseMoveOrder then
                        self:AttackTarget(target)
                    else
                        self:MoveToLocation(table.copy(target:GetPosition()), false)
                    end
                    movingToScout = false
                elseif not movingToScout then
                    movingToScout = true
                    self:Stop()
                    for k,v in AIUtils.AIGetSortedMassLocations(aiBrain, 10, nil, nil, nil, nil, self:GetPlatoonPosition()) do
                        if v[1] < 0 or v[3] < 0 or v[1] > ScenarioInfo.size[1] or v[3] > ScenarioInfo.size[2] then
                            --LOG('*AI DEBUG: STRIKE FORCE SENDING UNITS TO WRONG LOCATION - ' .. v[1] .. ', ' .. v[3])
                        end
                        self:MoveToLocation((v), false)
                    end
                end
            end
            WaitSeconds(7)
        end
    end,
    
    -------------------------------------------------------
    --   Function: CarrierAI
    --   Args:
    --       self - the carrier platoon to run the AI on
    --   Description:
    --       Uses the carrier as a sea-based powerful anti-air unit.
    --       Dispatches the carrier to a location with heavy air cover
    --       to wreck havoc on air units
    --   Returns:
    --       nil (tail calls into a behavior function)
    -------------------------------------------------------
    CarrierAI = function(self)
        local aiBrain = self:GetBrain()
        if not aiBrain then
            return
        end

        -- only works for carriers!
        for k,v in self:GetPlatoonUnits() do
            if not EntityCategoryContains(categories.CARRIER, v) then
                return
            end

            -- do something else for the experimental unit... act as a sub basically
            if EntityCategoryContains (categories.ues0401, v) then
                return NavalForceAI(self)
            end
        end

        if not self.LastAttackDestination then
            self.LastAttackDestination = {}
        end

        while aiBrain:PlatoonExists(self) do
            -- this table is sorted already from highest to lowest threat...
            local threatTable = aiBrain:GetThreatsAroundPosition(self:GetPlatoonPosition(), 16, true, 'Air')

            local attackPos = nil
            -- so go through until we find the first threat that's pathable
            for tidx,threat in threatTable do
                local foundSpot = true
                --check if we can path to the position or a position nearby
                local success, bestGoalPos = AIAttackUtils.CheckPlatoonPathingEx(self, {threat[1], 0, threat[2]})
                if not success then
                    foundSpot = false

                    local okThresholdSq = 32 * 32
                    local distSq = (threat[1] - bestGoalPos[1]) * (threat[1] - bestGoalPos[1]) + (threat[2] - bestGoalPos[3]) * (threat[2] - bestGoalPos[3])

                    if distSq < okThresholdSq then
                        threat[1] = bestGoalPos[1]
                        threat[2] = bestGoalPos[3]
                        foundSpot = true
                    end
                else
                    threat[1] = bestGoalPos[1]
                    threat[2] = bestGoalPos[3]
                end

                if foundSpot then
                    attackPos = {threat[1], 0, threat[2]}
                    break
                end
            end

            local oldPathSize = table.getn(self.LastAttackDestination)

            -- if we don't have an old path or our old destination and new destination are different
            if attackPos and oldPathSize == 0 or attackPos[1] != self.LastAttackDestination[oldPathSize][1] or attackPos[3] != self.LastAttackDestination[oldPathSize][3] then
                AIAttackUtils.GetMostRestrictiveLayer(self)
                -- check if we can path to here safely... give a large threat weight to sort by threat first
                local path, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, self.MovementLayer, self:GetPlatoonPosition(), attackPos, self.PlatoonData.NodeWeight or 10)

                -- clear command queue
                self:Stop()

                if not path then
                    if reason == 'NoStartNode' or reason == 'NoEndNode' then
                        --Couldn't find a valid pathing node. Just use shortest path.
                        self:AggressiveMoveToLocation(attackPos)
                    end
                    -- force reevaluation
                    self.LastAttackDestination = {attackPos}
                else
                    local pathSize = table.getn(path)
                    -- store path
                    self.LastAttackDestination = path
                    -- move to new location
                    for wpidx,waypointPath in path do
                        if wpidx == pathSize then
                            self:AggressiveMoveToLocation(waypointPath)
                        else
                            self:MoveToLocation(waypointPath, false)
                        end
                    end
                end
            end

            -- and loop back on the while
            WaitSeconds(20)
        end
    end,

    -------------------------------------------------------
    --   Function: DummyAI
    --   Args:
    --       self - the single platoon to run the AI on
    --   Description:
    --       Does nothing, just returns
    --   Returns:
    --       nil (tail calls into a behavior function)
    -------------------------------------------------------
    DummyAI = function(self)
    end,

    ArtilleryAI = function(self)
        local aiBrain = self:GetBrain()

        local atkPri = { 'STRUCTURE STRATEGIC', 'EXPERIMENTAL LAND', 'STRUCTURE SHIELD', 'COMMAND', 'STRUCTURE FACTORY',
            'STRUCTURE DEFENSE', 'MOBILE TECH3 LAND', 'MOBILE TECH2 LAND', 'SPECIALLOWPRI', 'ALLUNITS' }
        local atkPriTable = {}
        for k,v in atkPri do
            table.insert(atkPriTable, ParseEntityCategory(v))
        end

        --DUNCAN - changed from Attack group
        self:SetPrioritizedTargetList('Artillery', atkPriTable)

        -- Set priorities on the unit so if the target has died it will reprioritize before the platoon does
        local unit = false
        for k,v in self:GetPlatoonUnits() do
            if not v.Dead then
                unit = v
                break
            end
        end
        if not unit then
            return
        end
        unit:SetTargetPriorities(atkPriTable)
        local bp = unit:GetBlueprint()
        local weapon = bp.Weapon[1]
        local maxRadius = weapon.MaxRadius

        while aiBrain:PlatoonExists(self) do
            local target = self:FindPrioritizedUnit('Artillery', 'Enemy', true, self:GetPlatoonPosition(), maxRadius)
            if target then
                self:Stop()
                self:AttackTarget(target)
            end
            WaitSeconds(20)
        end
    end,

    -------------------------------------------------------
    --   Function: NavalForceAI
    --   Args:
    --       self - the single platoon to run the AI on
    --   Description:
    --       Basic attack logic for boats.  Searches for a good area to go attack, and will use
    --       a safe path (if available) to get there.
    --   Returns:
    --       nil (tail calls into a behavior function)
    -------------------------------------------------------
    NavalForceAI = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()

        AIAttackUtils.GetMostRestrictiveLayer(self)

        local platoonUnits = self:GetPlatoonUnits()
        local numberOfUnitsInPlatoon = table.getn(platoonUnits)
        local oldNumberOfUnitsInPlatoon = numberOfUnitsInPlatoon
        local stuckCount = 0

        self.PlatoonAttackForce = true
        -- formations have penalty for taking time to form up... not worth it here
        -- maybe worth it if we micro
        --self:SetPlatoonFormationOverride('GrowthFormation')
        local PlatoonFormation = self.PlatoonData.UseFormation or 'NoFormation'
        self:SetPlatoonFormationOverride(PlatoonFormation)

        for k,v in self:GetPlatoonUnits() do
            if v.Dead then
                continue
            end

            if v:GetCurrentLayer() != 'Sub' then
                continue
            end

            if v:TestCommandCaps('RULEUCC_Dive') then
                IssueDive({v})
            end
        end

        while aiBrain:PlatoonExists(self) do
            local pos = self:GetPlatoonPosition() -- update positions; prev position done at end of loop so not done first time

            -- if we can't get a position, then we must be dead
            if not pos then
                break
            end

            -- pick out the enemy
            if aiBrain:GetCurrentEnemy() and aiBrain:GetCurrentEnemy():IsDefeated() then
                aiBrain:PickEnemyLogic()
            end

            -- merge with nearby platoons
            self:MergeWithNearbyPlatoons('NavalForce', 20)

            -- rebuild formation
            platoonUnits = self:GetPlatoonUnits()
            numberOfUnitsInPlatoon = table.getn(platoonUnits)
            -- if we have a different number of units in our platoon, regather
            if (oldNumberOfUnitsInPlatoon != numberOfUnitsInPlatoon) then
                self:StopAttack()
                self:SetPlatoonFormationOverride(PlatoonFormation)
            end
            oldNumberOfUnitsInPlatoon = numberOfUnitsInPlatoon

            local cmdQ = {}
            -- fill cmdQ with current command queue for each unit
            for k,v in self:GetPlatoonUnits() do
                if not v.Dead then
                    local unitCmdQ = v:GetCommandQueue()
                    for cmdIdx,cmdVal in unitCmdQ do
                        table.insert(cmdQ, cmdVal)
                        break
                    end
                end
            end

            -- if we're on our final push through to the destination, and we find a unit close to our destination
            --local closestTarget = self:FindClosestUnit('attack', 'enemy', true, categories.ALLUNITS)
            local closestTarget
            local NavalPriorities = {
                'ANTINAVY - MOBILE',
                'NAVAL MOBILE',
                'NAVAL FACTORY',
                'COMMAND',
                'EXPERIMENTAL ENERGYPRODUCTION STRUCTURE',
                'EXPERIMENTAL LAND',
                'TECH3 ENERGYPRODUCTION STRUCTURE',
                'TECH2 ENERGYPRODUCTION STRUCTURE',
                'TECH3 MASSEXTRACTION STRUCTURE',
                'INTELLIGENCE STRUCTURE',
                'TECH3 SHIELD STRUCTURE',
                'TECH2 SHIELD STRUCTURE',
                'TECH2 MASSEXTRACTION STRUCTURE',
                'TECH3 FACTORY',
                'TECH2 FACTORY',
                'TECH1 FACTORY',
                'TECH1 MASSEXTRACTION STRUCTURE',
                'TECH3 STRUCTURE',
                'TECH2 STRUCTURE',
                'TECH1 STRUCTURE',
                'TECH3 MOBILE LAND',
            }

            local nearDest = false
            local oldPathSize = table.getn(self.LastAttackDestination)
            local maxRange = AIAttackUtils.GetNavalPlatoonMaxRange(aiBrain, self)
            if maxRange then maxRange = maxRange + 30 end --DUNCAN - added

            if self.LastAttackDestination then
                nearDest = oldPathSize == 0 or VDist3(self.LastAttackDestination[oldPathSize], pos) < maxRange
            end

            for _, priority in NavalPriorities do
                closestTarget = self:FindClosestUnit('attack', 'enemy', true, ParseEntityCategory(priority))
                if closestTarget and VDist3(closestTarget:GetPosition(), pos) < maxRange then
                    --LOG('*AI DEBUG: Found Naval target: ' .. priority)
                    break
                end
            end

            -- if we're near our destination and we have a unit closeby to kill, kill it
            --DUNCAN - dont worry about command queue "table.getn(cmdQ) <= 1 and"
            if closestTarget and VDist3(closestTarget:GetPosition(), pos) < maxRange and nearDest then
                self:StopAttack()
                if PlatoonFormation != 'No Formation' then
                    self:AttackTarget(closestTarget)
                    --IssueFormAttack(platoonUnits, closestTarget, PlatoonFormation, 0)
                else
                    self:AttackTarget(closestTarget)
                    --IssueAttack(platoonUnits, closestTarget)
                end
                cmdQ = {1}
            -- if we have nothing to do, try finding something to do
            elseif table.getn(cmdQ) == 0 then
                self:StopAttack()
                cmdQ = AIAttackUtils.AIPlatoonNavalAttackVector(aiBrain, self)
                stuckCount = 0
            -- if we've been stuck and unable to reach next marker? Ignore nearby stuff and pick another target
            elseif self.LastPosition and VDist2Sq(self.LastPosition[1], self.LastPosition[3], pos[1], pos[3]) < (self.PlatoonData.StuckDistance or 100) then
                stuckCount = stuckCount + 1
                if stuckCount >= 2 then
                    self:StopAttack()
                    cmdQ = AIAttackUtils.AIPlatoonNavalAttackVector(aiBrain, self)
                    stuckCount = 0
                end
            else
                stuckCount = 0
            end

            self.LastPosition = pos

            --wait a while if we're stuck so that we have a better chance to move
            WaitSeconds(Random(5,11) + 2 * stuckCount)
        end
    end,


    -------------------------------------------------------
    --   Function: AttackForceAI
    --   Args:
    --       self - the single platoon to run the AI on
    --   Description:
    --       Basic attack logic.  Searches for a good area to go attack, and will use
    --       a safe path (if available) to get there.  If the threat of the platoon
    --       drops too low, it will try and guard an engineer (to be more useful)
    --       See AIAttackUtils for the bulk of the logic
    --   Returns:
    --       nil (tail calls into a behavior function)
    -------------------------------------------------------
    AttackForceAI = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()

        -- get units together
        if not self:GatherUnits() then
            return
        end

        -- Setup the formation based on platoon functionality

        local enemy = aiBrain:GetCurrentEnemy()

        local platoonUnits = self:GetPlatoonUnits()
        local numberOfUnitsInPlatoon = table.getn(platoonUnits)
        local oldNumberOfUnitsInPlatoon = numberOfUnitsInPlatoon
        local stuckCount = 0

        self.PlatoonAttackForce = true
        -- formations have penalty for taking time to form up... not worth it here
        -- maybe worth it if we micro
        --self:SetPlatoonFormationOverride('GrowthFormation')
        local PlatoonFormation = self.PlatoonData.UseFormation or 'NoFormation'
        self:SetPlatoonFormationOverride(PlatoonFormation)

        while aiBrain:PlatoonExists(self) do
            local pos = self:GetPlatoonPosition() -- update positions; prev position done at end of loop so not done first time

            -- if we can't get a position, then we must be dead
            if not pos then
                break
            end


            -- if we're using a transport, wait for a while
            if self.UsingTransport then
                WaitSeconds(10)
                continue
            end

            -- pick out the enemy
            if aiBrain:GetCurrentEnemy() and aiBrain:GetCurrentEnemy():IsDefeated() then
                aiBrain:PickEnemyLogic()
            end

            -- merge with nearby platoons
            self:MergeWithNearbyPlatoons('AttackForceAI', 10)

            -- rebuild formation
            platoonUnits = self:GetPlatoonUnits()
            numberOfUnitsInPlatoon = table.getn(platoonUnits)
            -- if we have a different number of units in our platoon, regather
            if (oldNumberOfUnitsInPlatoon != numberOfUnitsInPlatoon) then
                self:StopAttack()
                self:SetPlatoonFormationOverride(PlatoonFormation)
            end
            oldNumberOfUnitsInPlatoon = numberOfUnitsInPlatoon

            -- deal with lost-puppy transports
            local strayTransports = {}
            for k,v in platoonUnits do
                if EntityCategoryContains(categories.TRANSPORTATION, v) then
                    table.insert(strayTransports, v)
                end
            end
            if table.getn(strayTransports) > 0 then
                local dropPoint = pos
                dropPoint[1] = dropPoint[1] + Random(-3, 3)
                dropPoint[3] = dropPoint[3] + Random(-3, 3)
                IssueTransportUnload(strayTransports, dropPoint)
                WaitSeconds(10)
                local strayTransports = {}
                for k,v in platoonUnits do
                    local parent = v:GetParent()
                    if parent and EntityCategoryContains(categories.TRANSPORTATION, parent) then
                        table.insert(strayTransports, parent)
                        break
                    end
                end
                if table.getn(strayTransports) > 0 then
                    local MAIN = aiBrain.BuilderManagers.MAIN
                    if MAIN then
                        dropPoint = MAIN.Position
                        IssueTransportUnload(strayTransports, dropPoint)
                        WaitSeconds(30)
                    end
                end
                self.UsingTransport = false
                AIUtils.ReturnTransportsToPool(strayTransports, true)
                platoonUnits = self:GetPlatoonUnits()
            end


            --Disband platoon if it's all air units, so they can be picked up by another platoon
            local mySurfaceThreat = AIAttackUtils.GetSurfaceThreatOfUnits(self)
            if mySurfaceThreat == 0 and AIAttackUtils.GetAirThreatOfUnits(self) > 0 then
                self:PlatoonDisband()
                return
            end

            local cmdQ = {}
            -- fill cmdQ with current command queue for each unit
            for k,v in platoonUnits do
                if not v.Dead then
                    local unitCmdQ = v:GetCommandQueue()
                    for cmdIdx,cmdVal in unitCmdQ do
                        table.insert(cmdQ, cmdVal)
                        break
                    end
                end
            end

            -- if we're on our final push through to the destination, and we find a unit close to our destination
            local closestTarget = self:FindClosestUnit('attack', 'enemy', true, categories.ALLUNITS)
            local nearDest = false
            local oldPathSize = table.getn(self.LastAttackDestination)
            if self.LastAttackDestination then
                nearDest = oldPathSize == 0 or VDist3(self.LastAttackDestination[oldPathSize], pos) < 20
            end

            -- if we're near our destination and we have a unit closeby to kill, kill it
            if table.getn(cmdQ) <= 1 and closestTarget and VDist3(closestTarget:GetPosition(), pos) < 20 and nearDest then
                self:StopAttack()
                if PlatoonFormation != 'No Formation' then
                    IssueFormAttack(platoonUnits, closestTarget, PlatoonFormation, 0)
                else
                    IssueAttack(platoonUnits, closestTarget)
                end
                cmdQ = {1}
            -- if we have nothing to do, try finding something to do
            elseif table.getn(cmdQ) == 0 then
                self:StopAttack()
                cmdQ = AIAttackUtils.AIPlatoonSquadAttackVector(aiBrain, self)
                stuckCount = 0
            -- if we've been stuck and unable to reach next marker? Ignore nearby stuff and pick another target
            elseif self.LastPosition and VDist2Sq(self.LastPosition[1], self.LastPosition[3], pos[1], pos[3]) < (self.PlatoonData.StuckDistance or 16) then
                stuckCount = stuckCount + 1
                if stuckCount >= 2 then
                    self:StopAttack()
                    cmdQ = AIAttackUtils.AIPlatoonSquadAttackVector(aiBrain, self)
                    stuckCount = 0
                end
            else
                stuckCount = 0
            end

            self.LastPosition = pos

            if table.getn(cmdQ) == 0 then
                -- if we have a low threat value, then go and defend an engineer or a base
                if mySurfaceThreat < 4
                    and mySurfaceThreat > 0
                    and not self.PlatoonData.NeverGuard
                    and not (self.PlatoonData.NeverGuardEngineers and self.PlatoonData.NeverGuardBases)
                then
                    --LOG('*DEBUG: Trying to guard')
                    return self:GuardEngineer(self.AttackForceAI)
                end

                -- we have nothing to do, so find the nearest base and disband
                if not self.PlatoonData.NeverMerge then
                    return self:ReturnToBaseAI()
                end
                WaitSeconds(5)
            else
                -- wait a little longer if we're stuck so that we have a better chance to move
                WaitSeconds(Random(5,11) + 2 * stuckCount)
            end
        end
    end,

    -------------------------------------------------------
    --   Function: ReturnToBaseAI
    --   Args:
    --       self - the single platoon to run the AI on
    --   Description:
    --       Finds a base to return to and disband - that way it can be used
    --       for a new platoon
    --   Returns:
    --       nil (tail calls into AttackForceAI or disbands)
    -------------------------------------------------------
    ReturnToBaseAI = function(self)
        local aiBrain = self:GetBrain()

        if not aiBrain:PlatoonExists(self) or not self:GetPlatoonPosition() then
            return
        end

        local bestBase = false
        local bestBaseName = ""
        local bestDistSq = 999999999
        local platPos = self:GetPlatoonPosition()

        for baseName, base in aiBrain.BuilderManagers do
            local distSq = VDist2Sq(platPos[1], platPos[3], base.Position[1], base.Position[3])

            if distSq < bestDistSq then
                bestBase = base
                bestBaseName = baseName
                bestDistSq = distSq
            end
        end

        if bestBase then
            AIAttackUtils.GetMostRestrictiveLayer(self)
            local path, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, self.MovementLayer, self:GetPlatoonPosition(), bestBase.Position, 200)
            IssueClearCommands(self)

            if path then
                local pathLength = table.getn(path)
                for i=1, pathLength-1 do
                    self:MoveToLocation(path[i], false)
                end
            end
            self:MoveToLocation(bestBase.Position, false)

            local oldDistSq = 0
            while aiBrain:PlatoonExists(self) do
                WaitSeconds(10)
                platPos = self:GetPlatoonPosition()
                local distSq = VDist2Sq(platPos[1], platPos[3], bestBase.Position[1], bestBase.Position[3])
                if distSq < 10 then
                    self:PlatoonDisband()
                    return
                end
                -- if we haven't moved in 10 seconds... go back to attacking
                if (distSq - oldDistSq) < 5 then
                    break
                end
                oldDistSq = distSq
            end
        end
        -- default to returning to attacking
        return self:AttackForceAI()
    end,

    -- -------------------
    --  Support Functions
    -- -------------------

    -- stop platoon and delete last attack destination so new one will be picked
    StopAttack = function(self)
        self:Stop()
        self.LastAttackDestination = {}
    end,

    -- NOTES:
    -- don't always use defensive point, use naval point for navies, etc.
    -- or gather around center
    GatherUnits = function(self)
        local pos = self:GetPlatoonPosition()
        local unitsSet = true
        for k,v in self:GetPlatoonUnits() do
            if VDist2(v:GetPosition()[1], v:GetPosition()[3], pos[1], pos[3]) > 40 then
               unitsSet = false
               break
            end
        end
        local aiBrain = self:GetBrain()
        if not unitsSet then
            AIUtils.AIGetClosestMarkerLocation(aiBrain, 'Defensive Point', pos[1], pos[3])
            local cmd = self:MoveToLocation(self:GetPlatoonPosition(), false)
            local counter = 0
            repeat
                WaitSeconds(1)
                counter = counter + 1
                if not aiBrain:PlatoonExists(self) then
                    return false
                end
            until not self:IsCommandsActive(cmd) or counter >= 30
        end

        return true
    end,

    -------------------------------------------------------
    --   Function: MergeWithNearbyPlatoons
    --   Args:
    --       self - the single platoon to run the AI on
    --       planName - AI plan to merge with
    --       radius - check to see if we should merge with platoons in this radius
    --   Description:
    --       Finds platoons nearby (when self platoon is not near a base) and merge
    --       with them if they're a good fit.
    --   Returns:
    --       nil
    -------------------------------------------------------
    MergeWithNearbyPlatoons = function(self, planName, radius)
        -- check to see we're not near an ally base
        local aiBrain = self:GetBrain()
        if not aiBrain then
            return
        end

        if self.UsingTransport then
            return
        end

        local platPos = self:GetPlatoonPosition()
        if not platPos then
            return
        end

        local radiusSq = radius*radius
        -- if we're too close to a base, forget it
        if aiBrain.BuilderManagers then
            for baseName, base in aiBrain.BuilderManagers do
                if VDist2Sq(platPos[1], platPos[3], base.Position[1], base.Position[3]) <= (3*radiusSq) then
                    return
                end
            end
        end

        AlliedPlatoons = aiBrain:GetPlatoonsList()
        local bMergedPlatoons = false
        for _,aPlat in AlliedPlatoons do
            if aPlat:GetPlan() != planName then
                continue
            end
            if aPlat == self then
                continue
            end

            if aPlat.UsingTransport then
                continue
            end

            local allyPlatPos = aPlat:GetPlatoonPosition()
            if not allyPlatPos or not aiBrain:PlatoonExists(aPlat) then
                continue
            end

            AIAttackUtils.GetMostRestrictiveLayer(self)
            AIAttackUtils.GetMostRestrictiveLayer(aPlat)

            -- make sure we're the same movement layer type to avoid hamstringing air of amphibious
            if self.MovementLayer != aPlat.MovementLayer then
                continue
            end

            if  VDist2Sq(platPos[1], platPos[3], allyPlatPos[1], allyPlatPos[3]) <= radiusSq then
                local units = aPlat:GetPlatoonUnits()
                local validUnits = {}
                local bValidUnits = false
                for _,u in units do
                    if not u.Dead and not u:IsUnitState('Attached') then
                        table.insert(validUnits, u)
                        bValidUnits = true
                    end
                end
                if not bValidUnits then
                    continue
                end
                --LOG("*AI DEBUG: Merging platoons " .. self.BuilderName .. ": (" .. platPos[1] .. ", " .. platPos[3] .. ") and " .. aPlat.BuilderName .. ": (" .. allyPlatPos[1] .. ", " .. allyPlatPos[3] .. ")")
                aiBrain:AssignUnitsToPlatoon(self, validUnits, 'Attack', 'GrowthFormation')
                bMergedPlatoons = true
            end
        end
        if bMergedPlatoons then
            self:StopAttack()
        end

    end,

    -- names units in platoon
    NameUnits = function(self)
        local units = self:GetPlatoonUnits()
        if units and table.getn(units) > 0 then
            for k, v in units do
                local bp = v:GetBlueprint().Display
                if bp.AINames then
                    local num = Random(1, table.getn(bp.AINames))
                    v:SetCustomName(bp.AINames[num])
                end
            end
        end
    end,

    --returns each type of threat for this platoon
    GetPlatoonThreatEx = function(self)
        local threat = {
            AirThreatLevel = 0,
            EconomyThreatLevel = 0,
            SubThreatLevel = 0,
            SurfaceThreatLevel = 0,
        }

        for i,unit in self:GetPlatoonUnits() do
            local bpd = unit:GetBlueprint().Defense

            threat.AirThreatLevel = threat.AirThreatLevel + (bpd.AirThreatLevel or 0)
            threat.EconomyThreatLevel = threat.EconomyThreatLevel + (bpd.EconomyThreatLevel or 0)
            threat.SubThreatLevel = threat.SubThreatLevel + (bpd.SubThreatLevel or 0)
            threat.SurfaceThreatLevel = threat.SurfaceThreatLevel + (bpd.SurfaceThreatLevel or 0)
        end

        return threat
    end,

    -- ---------------------------------------------------------------------
    -- Helper functions for GuardMarker AI

    -- Checks radius around base to see if marker is sufficiently far away
    AvoidsBases = function(self, markerPos, avoidBasesDefault, baseRadius)
        if not avoidBasesDefault then
            return true
        end

        local aiBrain = self:GetBrain()

        for baseName, base in aiBrain.BuilderManagers do
            local avoidDist = VDist2Sq(base.Position[1], base.Position[3], markerPos[1], markerPos[3])
            if avoidDist < baseRadius * baseRadius then
                return false
            end
        end
        return true
    end,

    -- greater than or less than check, based on what kind of threat order we want
    IsBetterThreat = function(findHighestThreat, newMarker, oldMarker)
        if findHighestThreat then
            return newMarker > oldMarker
        end
        return newMarker < oldMarker
    end,
    -- ---------------------------------------------------------------------



    SetupEngineerCallbacks = function(eng)
        if eng and not eng.Dead and not eng.BuildDoneCallbackSet and eng.PlatoonHandle and eng:GetAIBrain():PlatoonExists(eng.PlatoonHandle) then
            import('/lua/ScenarioTriggers.lua').CreateUnitBuiltTrigger(eng.PlatoonHandle.EngineerBuildDone, eng, categories.ALLUNITS)
            eng.BuildDoneCallbackSet = true
        end
        if eng and not eng.Dead and not eng.CaptureDoneCallbackSet and eng.PlatoonHandle and eng:GetAIBrain():PlatoonExists(eng.PlatoonHandle) then
            import('/lua/ScenarioTriggers.lua').CreateUnitStopCaptureTrigger(eng.PlatoonHandle.EngineerCaptureDone, eng)
            eng.CaptureDoneCallbackSet = true
        end
        if eng and not eng.Dead and not eng.ReclaimDoneCallbackSet and eng.PlatoonHandle and eng:GetAIBrain():PlatoonExists(eng.PlatoonHandle) then
            import('/lua/ScenarioTriggers.lua').CreateUnitStopReclaimTrigger(eng.PlatoonHandle.EngineerReclaimDone, eng)
            eng.ReclaimDoneCallbackSet = true
        end
        if eng and not eng.Dead and not eng.FailedToBuildCallbackSet and eng.PlatoonHandle and eng:GetAIBrain():PlatoonExists(eng.PlatoonHandle) then
            import('/lua/ScenarioTriggers.lua').CreateOnFailedToBuildTrigger(eng.PlatoonHandle.EngineerFailedToBuild, eng)
            eng.FailedToBuildCallbackSet = true
        end
    end,

    -- Callback functions for EngineerBuildAI
    EngineerBuildDone = function(unit, params)
        if not unit.PlatoonHandle then return end
        if not unit.PlatoonHandle.PlanName == 'EngineerBuildAI' then return end
        --LOG("*AI DEBUG: Build done " .. unit.Sync.id)
        if not unit.ProcessBuild then
            unit.ProcessBuild = unit:ForkThread(unit.PlatoonHandle.ProcessBuildCommand, true)
            unit.ProcessBuildDone = true
        end
    end,
    EngineerCaptureDone = function(unit, params)
        if not unit.PlatoonHandle then return end
        if not unit.PlatoonHandle.PlanName == 'EngineerBuildAI' then return end
        --LOG("*AI DEBUG: Capture done" .. unit.Sync.id)
        if not unit.ProcessBuild then
            unit.ProcessBuild = unit:ForkThread(unit.PlatoonHandle.ProcessBuildCommand, false)
        end
    end,
    EngineerReclaimDone = function(unit, params)
        if not unit.PlatoonHandle then return end
        if not unit.PlatoonHandle.PlanName == 'EngineerBuildAI' then return end
        --LOG("*AI DEBUG: Reclaim done" .. unit.Sync.id)
        if not unit.ProcessBuild then
            unit.ProcessBuild = unit:ForkThread(unit.PlatoonHandle.ProcessBuildCommand, false)
        end
    end,
    EngineerFailedToBuild = function(unit, params)
        if not unit.PlatoonHandle then return end
        if not unit.PlatoonHandle.PlanName == 'EngineerBuildAI' then return end
        if unit.ProcessBuildDone and unit.ProcessBuild then
            KillThread(unit.ProcessBuild)
            unit.ProcessBuild = nil
        end
        if not unit.ProcessBuild then
            unit.ProcessBuild = unit:ForkThread(unit.PlatoonHandle.ProcessBuildCommand, true)  --DUNCAN - changed to true
        end
    end,

    -------------------------------------------------------
    --   Function: WatchForNotBuilding
    --   Args:
    --       eng - the engineer that's gone through EngineerBuildAI
    --   Description:
    --       After we try to build something, watch the engineer to
    --       make sure that the build goes through.  If not,
    --       try the next thing in the queue
    --   Returns:
    --       nil
    -------------------------------------------------------
    WatchForNotBuilding = function(eng)
        WaitTicks(5)
        local aiBrain = eng:GetAIBrain()

        --DUNCAN - Trying to stop commander leaving projects, also added moving as well.
        while not eng.Dead and (eng.GoingHome or eng:IsUnitState("Building") or
                  eng:IsUnitState("Attacking") or eng:IsUnitState("Repairing") or eng:IsUnitState("Guarding") or
                  eng:IsUnitState("Reclaiming") or eng:IsUnitState("Capturing") or eng.ProcessBuild != nil
                  or eng.UnitBeingBuiltBehavior or eng:IsUnitState("Moving") or eng:IsUnitState("Upgrading") or eng:IsUnitState("Enhancing")
                 ) do
            WaitSeconds(3)

            --if eng.CDRHome then
            --  LOG('*AI DEBUG: Commander waiting for building.')
            --  eng:PrintCommandQueue()
            --end
            --if eng.GoingHome then
            --  LOG('*AI DEBUG: Commander waiting for building: return home.')
            --end
            --if eng.UnitBeingBuiltBehavior then
            --  LOG('*AI DEBUG: Commander waiting for building: unit being built.')
            --end
        end

        --if not eng.CDRHome and not eng:IsIdleState() then LOG('Error in idlestate...' .. eng.Sync.id) end
        --if eng.CDRHome then
        --  LOG('*AI DEBUG: After Commander wait for building.')
        --end

        eng.NotBuildingThread = nil
        if not eng.Dead and eng:IsIdleState() and table.getn(eng.EngineerBuildQueue) != 0 and eng.PlatoonHandle then
            eng.PlatoonHandle.SetupEngineerCallbacks(eng)
            if not eng.ProcessBuild then
                eng.ProcessBuild = eng:ForkThread(eng.PlatoonHandle.ProcessBuildCommand, true)
            end
        end
    end,

    -------------------------------------------------------
    --   Function: ProcessBuildCommand
    --   Args:
    --       eng - the engineer that's gone through EngineerBuildAI
    --   Description:
    --       Run after every build order is complete/fails.  Sets up the next
    --       build order in queue, and if the engineer has nothing left to do
    --       will return the engineer back to the army pool by disbanding the
    --       the platoon.  Support function for EngineerBuildAI
    --   Returns:
    --       nil (tail calls into a behavior function)
    -------------------------------------------------------
    ProcessBuildCommand = function(eng, removeLastBuild)
        --DUNCAN - Trying to stop commander leaving projects
        if not eng or eng.Dead or not eng.PlatoonHandle or eng.GoingHome or eng.UnitBeingBuiltBehavior or eng:IsUnitState("Upgrading") or eng:IsUnitState("Enhancing") or eng:IsUnitState("Guarding") then
            if eng then eng.ProcessBuild = nil end
            --LOG('*AI DEBUG: Commander skipping process build.')
            return
        end

        if eng.CDRHome then
            --LOG('*AI DEBUG: Commander starting process build...')
        end

        local aiBrain = eng.PlatoonHandle:GetBrain()
        if not aiBrain or eng.Dead or not eng.EngineerBuildQueue or table.getn(eng.EngineerBuildQueue) == 0 then
            if aiBrain:PlatoonExists(eng.PlatoonHandle) then
                --LOG("*AI DEBUG: Disbanding Engineer Platoon in ProcessBuildCommand top " .. eng.Sync.id)
                --if eng.CDRHome then LOG('*AI DEBUG: Commander process build platoon disband...') end
                eng.PlatoonHandle:PlatoonDisband()
            end
            if eng then eng.ProcessBuild = nil end
            return
        end

        -- it wasn't a failed build, so we just finished something
        if removeLastBuild then
            table.remove(eng.EngineerBuildQueue, 1)
        end

        function BuildToNormalLocation(location)
            return {location[1], 0, location[2]}
        end

        function NormalToBuildLocation(location)
            return {location[1], location[3], 0}
        end

        eng.ProcessBuildDone = false
        IssueClearCommands({eng})
        local commandDone = false
        while not eng.Dead and not commandDone and table.getn(eng.EngineerBuildQueue) > 0  do
            local whatToBuild = eng.EngineerBuildQueue[1][1]
            local buildLocation = BuildToNormalLocation(eng.EngineerBuildQueue[1][2])
            local buildRelative = eng.EngineerBuildQueue[1][3]
            -- see if we can move there first
            if AIUtils.EngineerMoveWithSafePath(aiBrain, eng, buildLocation) then
                if not eng or eng.Dead or not eng.PlatoonHandle or not aiBrain:PlatoonExists(eng.PlatoonHandle) then
                    if eng then eng.ProcessBuild = nil end
                    return
                end

                if not eng.NotBuildingThread then
                    eng.NotBuildingThread = eng:ForkThread(eng.PlatoonHandle.WatchForNotBuilding)
                end

                local engpos = eng:GetPosition()
                while not eng.Dead and eng:IsUnitState("Moving") and VDist2(engpos[1], engpos[3], buildLocation[1], buildLocation[3]) > 15 do
                    WaitSeconds(2)
                end

                -- check to see if we need to reclaim or capture...
                if not AIUtils.EngineerTryReclaimCaptureArea(aiBrain, eng, buildLocation) then
                    -- check to see if we can repair
                    if not AIUtils.EngineerTryRepair(aiBrain, eng, whatToBuild, buildLocation) then
                        -- otherwise, go ahead and build the next structure there
                        aiBrain:BuildStructure(eng, whatToBuild, NormalToBuildLocation(buildLocation), buildRelative)
                        if not eng.NotBuildingThread then
                            eng.NotBuildingThread = eng:ForkThread(eng.PlatoonHandle.WatchForNotBuilding)
                        end
                    end
                end
                commandDone = true
            else
                -- we can't move there, so remove it from our build queue
                table.remove(eng.EngineerBuildQueue, 1)
            end
        end

        -- final check for if we should disband
        if not eng or eng.Dead or table.getn(eng.EngineerBuildQueue) <= 0 then
            if eng.PlatoonHandle and aiBrain:PlatoonExists(eng.PlatoonHandle) then
                --LOG("*AI DEBUG: Disbanding Engineer Platoon in ProcessBuildCommand bottom " .. eng.Sync.id)
                eng.PlatoonHandle:PlatoonDisband()
            end
            if eng then eng.ProcessBuild = nil end
            return
        end
        if eng then eng.ProcessBuild = nil end
    end,

    --DUNCAN - added
    EngineerDropAI = function(self)
        LOG('*AI DEBUG:  Using Engineer Drop')
        local aiBrain = self:GetBrain()
        local cmd = false
        local landed = false
        local target = false
        local targetLocation = false

        while aiBrain:PlatoonExists(self) and not landed do
           WaitSeconds(3)

           LOG('*AI DEBUG:  Engineer select location')
           target = AIUtils.AIFindBrainTargetInRange(aiBrain, self, 'Attack', 1500, {'STRUCTURE FACTORY'},  aiBrain:GetCurrentEnemy())
           if target then
               local markerList = AIUtils.AIGetMarkerLocations(aiBrain, 'Mass')
               markers = AIUtils.AISortMarkersFromLastPos(aiBrain,markerList,7,false,false,false,false,target)
               targetLocation = markers[5]

               LOG('*AI DEBUG:  Waiting for transports....')
               while AIUtils.GetTransports(self) < 1 do
                       WaitSeconds(3)
               end
               cmd = AIUtils.UseTransports(self:GetPlatoonUnits() , self:GetSquadUnits('Scout'), targetLocation, nil)

               self:SetAIPlan('EngineerBuildAI')
               landed = true

           end
        end
   end,

   --DUNCAN - added
   GhettoAI = function(self)
       --LOG('*AI DEBUG:  Using Ghetto AI')
       local aiBrain = self:GetBrain()
       local data = self.PlatoonData
       local maxRadius = data.SearchRadius or 50
       local cmd = false

       repeat
           --LOG('*AI DEBUG:  Waiting for transports...')
           while AIUtils.GetTransports(self) < 1 do
               WaitSeconds(3)
               if not aiBrain:PlatoonExists(self) then
                       return false
               end
           end
           --LOG('*AI DEBUG:  Ghetto transport load')
           cmd = AIUtils.UseTransports(self:GetPlatoonUnits() , self:GetSquadUnits('Scout'), nil, nil)
       until cmd

       local target = false
       local atkPri = {}
       local categoryList = {}
       if data.PrioritizedCategories then
            for k,v in data.PrioritizedCategories do
                table.insert(atkPri, v)
                table.insert(categoryList, ParseEntityCategory(v))
            end
       else
            atkPri = {'STRUCTURE ANTIAIR', 'COMMAND', 'ENGINEER', 'MASSEXTRACTION','HYDROCARBON', 'ALLUNITS'}
       end

       while aiBrain:PlatoonExists(self) do
            local mult = { 1,10,25 }
            for _,i in mult do
                target = AIUtils.AIFindBrainTargetInRange(aiBrain, self, 'Attack', maxRadius * i, atkPri, aiBrain:GetCurrentEnemy())
                if target then
                    break
                end
                WaitSeconds(1)
                if not aiBrain:PlatoonExists(self) then
                    return
                end
            end
           if target then
               local antiAirThreat = aiBrain:GetThreatAtPosition(table.copy(target:GetPosition()), 1, true, 'AntiAir')
               --LOG("AntiAir threat: " .. antiAirThreat)
               if antiAirThreat < 6 then
                   while not target.Dead do
                       local targetLocation =target:GetPosition()
                       local closeLocation = {targetLocation[1] + 4, targetLocation[2] + 0.2, targetLocation[3] + 2 }
                       IssueMove(self:GetSquadUnits('Scout'), closeLocation)
                       WaitSeconds(2)
                   end
               else
                    --LOG('No Ghetto target!')
               end
           end
           WaitSeconds(2)
       end
   end,

----------------------------------------------------------
--   Below is Sorian AI stuff... there's a lot of it   ---
----------------------------------------------------------

    PlatoonDisbandNoAssign = function(self)
        if self.BuilderHandle then
            self.BuilderHandle:RemoveHandle(self)
        end
        for k,v in self:GetPlatoonUnits() do
            v.PlatoonHandle = nil
        end
        self:GetBrain():DisbandPlatoon(self)
    end,

    NukeAISAI = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local platoonUnits = self:GetPlatoonUnits()
        local unit
        --GET THE Launcher OUT OF THIS PLATOON
        for k, v in platoonUnits do
            if EntityCategoryContains(categories.SILO * categories.NUKE, v) then
                unit = v
                break
            end
        end

        if unit then
            local bp = unit:GetBlueprint()
            local weapon = bp.Weapon[1]
            local maxRadius = weapon.MaxRadius
            local nukePos, oldTargetLocation
            unit:SetAutoMode(true)
            while aiBrain:PlatoonExists(self) do
                while unit:GetNukeSiloAmmoCount() < 1 do
                    WaitSeconds(11)
                    if not  aiBrain:PlatoonExists(self) then
                        return
                    end
                end

                nukePos = import('/lua/ai/aibehaviors.lua').GetHighestThreatClusterLocation(aiBrain, unit)
                if nukePos then
                    IssueNuke({unit}, nukePos)
                    WaitSeconds(10)
                    IssueClearCommands({unit})
                end
                WaitSeconds(1)
            end
        end
        self:PlatoonDisband()
    end,

    ExperimentalAIHubSorian = function(self)
        local aiBrain = self:GetBrain()
        local behaviors = import('/lua/ai/AIBehaviors.lua')

        local experimental = self:GetPlatoonUnits()[1]
        if not experimental or experimental.Dead then
            return
        end
        if Random(1,5) == 3 and (not aiBrain.LastTaunt or GetGameTimeSeconds() - aiBrain.LastTaunt > 90) then
            local randelay = Random(60,180)
            aiBrain.LastTaunt = GetGameTimeSeconds() + randelay
            SUtils.AIDelayChat('enemies', ArmyBrains[aiBrain:GetArmyIndex()].Nickname, 't4taunt', nil, randelay)
        end
        local ID = experimental:GetUnitId()

        self:SetPlatoonFormationOverride('AttackFormation')

        if ID == 'uel0401' then
            return behaviors.FatBoyBehaviorSorian(self)
        elseif ID == 'uaa0310' then
            return behaviors.CzarBehaviorSorian(self)
        elseif ID == 'xsa0402' then
            return behaviors.AhwassaBehaviorSorian(self)
        elseif ID == 'ura0401' then
            return behaviors.TickBehaviorSorian(self)
        elseif ID == 'url0401' then
            return behaviors.ScathisBehaviorSorian(self)
        elseif ID == 'uas0401' then
            return self:NavalHuntAI(self)
        elseif ID == 'ues0401' then
            return self:NavalHuntAI(self)
        end

        return behaviors.BehemothBehaviorSorian(self)
    end,

    FighterDistributionHubSorian = function(self)
        local aiBrain = self:GetBrain()
        local location = self.PlatoonData.Location
        if not aiBrain.FightersHunting then
            aiBrain.FightersHunting = {}
        end
        if not aiBrain.FightersHunting[location] then
            aiBrain.FightersHunting[location] = 0
        end

        --Distribute fighters between guarding the base and hunting down targets 3:1
        if aiBrain.FightersHunting[location] < 4 then
            aiBrain.FightersHunting[location] = aiBrain.FightersHunting[location] + 1
            return self:FighterHuntAI(self)
        else
            aiBrain.FightersHunting[location] = 0
            return self:GuardBaseSorian(self)
        end
    end,

    PlatoonCallForHelpAISorian = function(self)
        local aiBrain = self:GetBrain()
        local checkTime = self.PlatoonData.DistressCheckTime or 7
        local pos = self:GetPlatoonPosition()
        while aiBrain:PlatoonExists(self) and pos do
            if pos and not self.DistressCall then
                local threat = aiBrain:GetThreatAtPosition(pos, 0, true, 'AntiSurface')
                local myThreat = aiBrain:GetThreatAtPosition(pos, 0, true, 'Overall', aiBrain:GetArmyIndex())
                 --LOG('*AI DEBUG: PlatoonCallForHelpAISorian threat is: '..threat..' myThreat is: '..myThreat)
                if threat and threat > (myThreat * 1.5) then
                    --LOG('*AI DEBUG: Platoon Calling for help')
                    aiBrain:BaseMonitorPlatoonDistress(self, threat)
                    self.DistressCall = true
                end
            end
            WaitSeconds(checkTime)
            pos = self:GetPlatoonPosition()
        end
    end,

    DistressResponseAISorian = function(self)
        local aiBrain = self:GetBrain()
        while aiBrain:PlatoonExists(self) do
            -- In the loop so they may be changed by other platoon things
            local distressRange = self.PlatoonData.DistressRange or aiBrain.BaseMonitor.DefaultDistressRange
            local reactionTime = self.PlatoonData.DistressReactionTime or aiBrain.BaseMonitor.PlatoonDefaultReactionTime
            local threatThreshold = self.PlatoonData.ThreatSupport or self.BaseMonitor.AlertLevel or 1
            local platoonPos = self:GetPlatoonPosition()
            local transporting = false
            units = self:GetPlatoonUnits()
            for k, v in units do
                if not v.Dead and v:IsUnitState('Attached') then
                    transporting = true
                end
                if transporting then break end
            end
            if platoonPos and not self.DistressCall and not transporting then
                -- Find a distress location within the platoons range
                local distressLocation = aiBrain:BaseMonitorDistressLocation(platoonPos, distressRange, threatThreshold)
                local moveLocation
                local threatatPos
                local myThreatatPos

                -- We found a location within our range! Activate!
                if distressLocation then
                    --LOG('*AI DEBUG: ARMY '.. aiBrain:GetArmyIndex() ..': --- DISTRESS RESPONSE AI ACTIVATION ---')

                    -- Backups old ai plan
                    local oldPlan = self:GetPlan()
                    if self.AIThread then
                        self.AIThread:Destroy()
                    end

                    -- Continue to position until the distress call wanes
                    repeat
                        moveLocation = distressLocation
                        self:Stop()
                        local cmd --= self:AggressiveMoveToLocation(distressLocation)
                        local inWater = AIAttackUtils.InWaterCheck(self)
                        if not inWater then
                            cmd = self:AggressiveMoveToLocation(distressLocation)
                        else
                            cmd = self:MoveToLocation(distressLocation, false)
                        end
                        local poscheck = self:GetPlatoonPosition()
                        local prevpos = poscheck
                        local poscounter = 0
                        local breakResponse = false
                        repeat
                            WaitSeconds(reactionTime)
                            if not aiBrain:PlatoonExists(self) then
                                return
                            end
                            poscheck = self:GetPlatoonPosition()
                            if VDist3(poscheck, prevpos) < 10 then
                                poscounter = poscounter + 1
                                if poscounter >= 3 then
                                    breakResponse = true
                                    poscounter = 0
                                end
                            elseif not SUtils.CanRespondEffectively(aiBrain, distressLocation, self) then
                                breakResponse = true
                                poscounter = 0
                            else
                                prevpos = poscheck
                                poscounter = 0
                            end
                            threatatPos = aiBrain:GetThreatAtPosition(moveLocation, 0, true, 'AntiSurface')
                            artyThreatatPos = aiBrain:GetThreatAtPosition(moveLocation, 0, true, 'Artillery')
                            myThreatatPos = aiBrain:GetThreatAtPosition(moveLocation, 0, true, 'Overall', aiBrain:GetArmyIndex())
                        until not self:IsCommandsActive(cmd) or breakResponse or ((threatatPos + artyThreatatPos) - myThreatatPos) <= threatThreshold or (inWater != AIAttackUtils.InWaterCheck(self))


                        platoonPos = self:GetPlatoonPosition()
                        if platoonPos then
                            -- Now that we have helped the first location, see if any other location needs the help
                            distressLocation = aiBrain:BaseMonitorDistressLocation(platoonPos, distressRange)
                            if distressLocation then
                                inWater = AIAttackUtils.InWaterCheck(self)
                                if not inWater then
                                    self:AggressiveMoveToLocation(distressLocation)
                                else
                                    self:MoveToLocation(distressLocation, false)
                                end
                            end
                        end
                    -- If no more calls or we are at the location; break out of the function
                    until not distressLocation or not SUtils.CanRespondEffectively(aiBrain, distressLocation, self) or (distressLocation[1] == moveLocation[1] and distressLocation[3] == moveLocation[3])

                    --LOG('*AI DEBUG: '..aiBrain.Name..' DISTRESS RESPONSE AI DEACTIVATION - oldPlan: '..oldPlan)
                    if not oldPlan then
                        units = self:GetPlatoonUnits()
                        for k, v in units do
                            if not v.Dead and EntityCategoryContains(categories.MOBILE * categories.EXPERIMENTAL, v) then
                                oldPlan = 'ExperimentalAIHubSorian'
                            elseif not v.Dead and EntityCategoryContains(categories.MOBILE * categories.LAND - categories.EXPERIMENTAL, v) then
                                oldPlan = 'AttackForceAISorian'
                            elseif not v.Dead and EntityCategoryContains(categories.AIR * categories.MOBILE * categories.ANTIAIR - categories.BOMBER - categories.TRANSPORTFOCUS - categories.EXPERIMENTAL, v) then
                                oldPlan = 'FighterHuntAI'
                            elseif not v.Dead and EntityCategoryContains(categories.AIR * categories.MOBILE * categories.BOMBER - categories.EXPERIMENTAL, v) then
                                oldPlan = 'AirHuntAI'
                            elseif not v.Dead and EntityCategoryContains(categories.MOBILE * categories.NAVAL - categories.EXPERIMENTAL, v) then
                                oldPlan = 'NavalForceAISorian'
                            end
                            if oldPlan then break end
                        end
                    end
                    self:SetAIPlan(oldPlan)
                end
            end
            WaitSeconds(11)
        end
    end,

    BaseManagersDistressAISorian = function(self)
        local aiBrain = self:GetBrain()
        while aiBrain:PlatoonExists(self) do
            local distressRange = aiBrain.BaseMonitor.PoolDistressRange
            local reactionTime = aiBrain.BaseMonitor.PoolReactionTime

            local platoonUnits = self:GetPlatoonUnits()

            for locName, locData in aiBrain.BuilderManagers do
                if not locData.BaseSettings.DistressCall then
                    local position = locData.EngineerManager:GetLocationCoords()
                    local retPos = AIUtils.RandomLocation(position[1],position[3])
                    local radius = locData.EngineerManager:GetLocationRadius()
                    local distressRange = locData.BaseSettings.DistressRange or aiBrain.BaseMonitor.PoolDistressRange
                    local distressLocation = aiBrain:BaseMonitorDistressLocation(position, distressRange, aiBrain.BaseMonitor.PoolDistressThreshold)

                    -- Distress !
                    if distressLocation then
                        --LOG('*AI DEBUG: ARMY '.. aiBrain:GetArmyIndex() ..': --- POOL DISTRESS RESPONSE ---')

                        -- Grab the units at the location
                        local group = self:GetUnitsAroundPoint(categories.MOBILE - categories.EXPERIMENTAL - categories.COMMAND - categories.ENGINEER, position, radius)

                        -- Move the group to the distress location and then back to the location of the base
                        IssueClearCommands(group)
                        IssueAggressiveMove(group, distressLocation)
                        IssueMove(group, retPos)

                        -- Set distress active for duration
                        locData.BaseSettings.DistressCall = true
                        self:ForkThread(self.UnlockBaseManagerDistressLocation, locData)
                    end
                end
            end
            WaitSeconds(aiBrain.BaseMonitor.PoolReactionTime)
        end
    end,

    EnhanceAISorian = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local unit
        for k,v in self:GetPlatoonUnits() do
            unit = v
            break
        end
        local data = self.PlatoonData
        local numLoop = 0
        local lastEnhancement
        if unit then
            unit.Upgrading = true
            IssueStop({unit})
            IssueClearCommands({unit})
            for k,v in data.Enhancement do
                if not unit:HasEnhancement(v) then
                    local order = {
                        TaskName = "EnhanceTask",
                        Enhancement = v
                    }
                    IssueScript({unit}, order)
                    lastEnhancement = v
                    --LOG('*AI DEBUG: '..aiBrain.Nickname..' EnhanceAI Added Enhancement: '..v)
                end
            end
            WaitSeconds(data.TimeBetweenEnhancements or 1)
            repeat
                WaitSeconds(5)
                if not aiBrain:PlatoonExists(self) then
                    --LOG('*AI DEBUG: '..aiBrain.Nickname..' EnhanceAI platoon dead')
                    return
                end
                if not unit:IsUnitState('Upgrading') then
                    numLoop = numLoop + 1
                else
                    numLoop = 0
                end
                --LOG('*AI DEBUG: '..aiBrain.Nickname..' EnhanceAI loop. numLoop = '..numLoop)
            until unit.Dead or numLoop > 1 or unit:HasEnhancement(lastEnhancement)
            --LOG('*AI DEBUG: '..aiBrain.Nickname..' EnhanceAI exited loop. numLoop = '..numLoop)
            unit.Upgrading = false
        end
        --LOG('*AI DEBUG: '..aiBrain.Nickname..' EnhanceAI done')
        if data.DoNotDisband then return end
        self:PlatoonDisband()
    end,


    ArtilleryAISorian = function(self)
        local aiBrain = self:GetBrain()

        local atkPri = { 'STRUCTURE STRATEGIC EXPERIMENTAL', 'EXPERIMENTAL ARTILLERY OVERLAYINDIRECTFIRE', 'STRUCTURE STRATEGIC TECH3', 'STRUCTURE NUKE TECH3', 'EXPERIMENTAL ORBITALSYSTEM', 'EXPERIMENTAL ENERGYPRODUCTION STRUCTURE', 'STRUCTURE ANTIMISSILE TECH3', 'TECH3 MASSFABRICATION', 'TECH3 ENERGYPRODUCTION', 'STRUCTURE STRATEGIC', 'STRUCTURE DEFENSE TECH3 ANTIAIR',
        'COMMAND', 'STRUCTURE DEFENSE TECH3', 'STRUCTURE DEFENSE TECH2', 'EXPERIMENTAL LAND', 'MOBILE TECH3 LAND', 'MOBILE TECH2 LAND', 'MOBILE TECH1 LAND', 'STRUCTURE FACTORY', 'SPECIALLOWPRI', 'ALLUNITS' }
        local atkPriTable = {}
        for k,v in atkPri do
            table.insert(atkPriTable, ParseEntityCategory(v))
        end
        self:SetPrioritizedTargetList('Artillery', atkPriTable)

        -- Set priorities on the unit so if the target has died it will reprioritize before the platoon does
        local unit = false
        for k,v in self:GetPlatoonUnits() do
            if not v.Dead then
                unit = v
                break
            end
        end
        if not unit then
            return
        end
        local bp = unit:GetBlueprint()
        local weapon = bp.Weapon[1]
        local maxRadius = weapon.MaxRadius
        local attacking = false
        unit:SetTargetPriorities(atkPriTable)

        while aiBrain:PlatoonExists(self) do
            if self:IsOpponentAIRunning() then
                target = AIUtils.AIFindBrainTargetInRangeSorian(aiBrain, self, 'Artillery', maxRadius, atkPri, true)
                local newtarget = false
                if aiBrain.AttackPoints and table.getn(aiBrain.AttackPoints) > 0 then
                    newtarget = AIUtils.AIFindPingTargetInRangeSorian(aiBrain, self, 'Artillery', maxRadius, atkPri, true)
                    if newtarget then
                        target = newtarget
                    end
                end
                if target and not unit.Dead then
                    --self:Stop()
                    --self:AttackTarget(target)
                    IssueClearCommands({unit})
                    IssueAttack({unit}, target)
                    attacking = true
                elseif not target and attacking then
                    --self:Stop()
                    IssueClearCommands({unit})
                    attacking = false
                end
            end
            WaitSeconds(20)
        end
    end,

    SatelliteAISorian = function(self)
        local aiBrain = self:GetBrain()
        local data = self.PlatoonData
        local atkPri = {}
        local atkPriTable = {}
        if data.PrioritizedCategories then
            for k,v in data.PrioritizedCategories do
                table.insert(atkPri, v)
                table.insert(atkPriTable, ParseEntityCategory(v))
            end
        end
        table.insert(atkPri, 'ALLUNITS')
        table.insert(atkPriTable, categories.ALLUNITS)
        self:SetPrioritizedTargetList('Attack', atkPriTable)

        local maxRadius = data.SearchRadius or 50
        local oldTarget = false
        local target = false

        while aiBrain:PlatoonExists(self) do
            self:MergeWithNearbyPlatoonsSorian('SatelliteAISorian', 50, true)
            if self:IsOpponentAIRunning() then
                target = AIUtils.AIFindUndefendedBrainTargetInRangeSorian(aiBrain, self, 'Attack', maxRadius, atkPri)
                --local newtarget = false
                --if aiBrain.AttackPoints and table.getn(aiBrain.AttackPoints) > 0 then
                --  newtarget = AIUtils.AIFindPingTargetInRangeSorian(aiBrain, self, 'Attack', maxRadius, atkPri)
                --  if newtarget then
                --      target = newtarget
                --  end
                --end
                if target and target != oldTarget and not target.Dead then
                    self:Stop()
                    self:AttackTarget(target)
                    oldTarget = target
                end
            end
            WaitSeconds(30)
        end
    end,

    TacticalAISorian = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local armyIndex = aiBrain:GetArmyIndex()
        local platoonUnits = self:GetPlatoonUnits()
        local unit

        if not aiBrain:PlatoonExists(self) then return end

        --GET THE Launcher OUT OF THIS PLATOON
        for k, v in platoonUnits do
            if EntityCategoryContains(categories.STRUCTURE * categories.TACTICALMISSILEPLATFORM, v) then
                unit = v
                break
            end
        end

        if not unit then return end

        local bp = unit:GetBlueprint()
        local weapon = bp.Weapon[1]
        local maxRadius = weapon.MaxRadius
        local minRadius = weapon.MinRadius
        unit:SetAutoMode(true)
        local atkPri = { 'STRUCTURE STRATEGIC EXPERIMENTAL', 'ARTILLERY EXPERIMENTAL', 'STRUCTURE NUKE EXPERIMENTAL', 'EXPERIMENTAL ORBITALSYSTEM', 'STRUCTURE ARTILLERY TECH3',
        'STRUCTURE NUKE TECH3', 'EXPERIMENTAL ENERGYPRODUCTION STRUCTURE', 'COMMAND', 'EXPERIMENTAL MOBILE LAND', 'TECH3 MASSFABRICATION', 'TECH3 ENERGYPRODUCTION', 'TECH3 MASSPRODUCTION', 'TECH2 ENERGYPRODUCTION', 'TECH2 MASSPRODUCTION', 'STRUCTURE SHIELD' } -- 'STRUCTURE STRATEGIC', 'STRUCTURE DEFENSE TECH3', 'STRUCTURE DEFENSE TECH2', 'STRUCTURE FACTORY', 'STRUCTURE', 'LAND, NAVAL' }
        self:SetPrioritizedTargetList('Attack', { categories.STRUCTURE * categories.ARTILLERY * categories.EXPERIMENTAL, categories.STRUCTURE * categories.NUKE * categories.EXPERIMENTAL, categories.EXPERIMENTAL * categories.ORBITALSYSTEM, categories.STRUCTURE * categories.ARTILLERY * categories.TECH3,
        categories.STRUCTURE * categories.NUKE * categories.TECH3, categories.EXPERIMENTAL * categories.ENERGYPRODUCTION * categories.STRUCTURE, categories.COMMAND, categories.EXPERIMENTAL * categories.MOBILE * categories.LAND, categories.TECH3 * categories.MASSFABRICATION,
        categories.TECH3 * categories.ENERGYPRODUCTION, categories.TECH3 * categories.MASSPRODUCTION, categories.TECH2 * categories.ENERGYPRODUCTION, categories.TECH2 * categories.MASSPRODUCTION, categories.STRUCTURE * categories.SHIELD }) -- categories.STRUCTURE * categories.STRATEGIC, categories.STRUCTURE * categories.DEFENSE * categories.TECH3, categories.STRUCTURE * categories.DEFENSE * categories.TECH2, categories.STRUCTURE * categories.FACTORY, categories.STRUCTURE, categories.LAND + categories.NAVAL })
        while aiBrain:PlatoonExists(self) do
            local target = false
            local blip = false
            while unit:GetTacticalSiloAmmoCount() < 1 or not target do
                WaitSeconds(7)
                target = false
                while not target do
                    --if aiBrain:GetCurrentEnemy() and aiBrain:GetCurrentEnemy():IsDefeated() then
                    --    aiBrain:PickEnemyLogic()
                    --end

                    target = AIUtils.AIFindBrainTargetInRangeSorian(aiBrain, self, 'Attack', maxRadius, atkPri, true)
                    local newtarget = false
                    if aiBrain.AttackPoints and table.getn(aiBrain.AttackPoints) > 0 then
                        newtarget = AIUtils.AIFindPingTargetInRangeSorian(aiBrain, self, 'Attack', maxRadius, atkPri, true)
                        if newtarget then
                            target = newtarget
                        end
                    end
                    if not target then
                        target = self:FindPrioritizedUnit('Attack', 'Enemy', true, unit:GetPosition(), maxRadius)
                    end
                    if target then
                        break
                    end
                    WaitSeconds(3)
                    if not aiBrain:PlatoonExists(self) then
                        return
                    end
                end
            end
            if not target.Dead then
                --LOG('*AI DEBUG: Firing Tactical Missile at enemy swine!')
                if EntityCategoryContains(categories.STRUCTURE, target) then
                    IssueTactical({unit}, target)
                else
                    targPos = SUtils.LeadTarget(self, target)
                    if targPos then
                        IssueTactical({unit}, targPos)
                    end
                end
            end
            WaitSeconds(3)
        end
    end,

    AirHuntAI = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local armyIndex = aiBrain:GetArmyIndex()
        local target
        local blip
        local hadtarget = false
        local atkPri = {'EXPERIMENTAL ENERGYPRODUCTION STRUCTURE', 'STRUCTURE STRATEGIC EXPERIMENTAL', 'EXPERIMENTAL ARTILLERY OVERLAYINDIRECTFIRE',
        'EXPERIMENTAL ORBITALSYSTEM', 'STRUCTURE STRATEGIC TECH3', 'ENERGYPRODUCTION DRAGBUILD', 'ENGINEER', 'MASSEXTRACTION',
        'MOBILE LAND', 'MASSFABRICATION', 'SHIELD', 'ANTIAIR STRUCTURE', 'DEFENSE STRUCTURE', 'STRUCTURE', 'COMMAND',
        'MOBILE ANTIAIR', 'ALLUNITS',
        }
        while aiBrain:PlatoonExists(self) do
            if self:IsOpponentAIRunning() then
                target = self:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS - categories.WALL)
                local newtarget = false
                if aiBrain.T4ThreatFound['Land'] or aiBrain.T4ThreatFound['Naval'] or aiBrain.T4ThreatFound['Structure'] then
                    newtarget = self:FindClosestUnit('Attack', 'Enemy', true, categories.EXPERIMENTAL * (categories.LAND + categories.NAVAL + categories.STRUCTURE + categories.ARTILLERY))
                    if newtarget then
                        target = newtarget
                    end
                elseif aiBrain.AirAttackPoints and table.getn(aiBrain.AirAttackPoints) > 0 then
                    newtarget = AIUtils.AIFindAirAttackTargetInRangeSorian(aiBrain, self, 'Attack', atkPri, self.AirAttackPoints[1].Position)
                    if newtarget then
                        target = newtarget
                    end
                end
                if target and newtarget then
                    blip = target:GetBlip(armyIndex)
                    self:Stop()
                    self:AttackTarget(target)
                    hadtarget = true
                elseif target then
                    blip = target:GetBlip(armyIndex)
                    self:Stop()
                    self:AggressiveMoveToLocation(table.copy(target:GetPosition()))
                    hadtarget = true
                elseif not target and hadtarget then
                    local x,z = aiBrain:GetArmyStartPos()
                    local position = AIUtils.RandomLocation(x,z)
                    local safePath, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, 'Air', self:GetPlatoonPosition(), position, 200)
                    if safePath then
                        for _,p in safePath do
                            self:MoveToLocation(p, false)
                        end
                    else
                        self:MoveToLocation(position, false)
                    end
                    hadtarget = false
                end
            end
            local waitLoop = 0
            repeat
                WaitSeconds(1)
                waitLoop = waitLoop + 1
            until waitLoop >= 17 or (target and (target.Dead or not target:GetPosition()))
            if aiBrain:PlatoonExists(self) and AIAttackUtils.GetSurfaceThreatOfUnits(self) <= 0 then
                return self:FighterHuntAI()
            end
        end
    end,

    ThreatStrikeSorian = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local threshold = self.PlatoonData.ThreatThreshold
        while aiBrain:PlatoonExists(self) do
            local bestDist = false
            local bestTarget = false
            local position = self:GetPlatoonPosition()
            if self.BaseMonitor.AlertSounded then
                for k,v in self.BaseMonitor.AlertsTable do
                    if v.Threat < threshold then
                        continue
                    end

                    local tempDist = Utilities.XZDistanceTwoVectors(position, v.Position)

                    if not bestDist or tempDist < bestDist then
                        bestDist = tempDist
                        local height = GetTerrainHeight(v.Position[1], v.Position[3])
                        local surfHeight = GetSurfaceHeight(v.Position[1], v.Position[3])
                        if surfHeight > height then
                            height = surfHeight
                        end
                        bestTarget = { v.Position[1], height, v.Position[3] }
                    end
                end
                if bestTarget then
                    local safePath, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, 'Air', self:GetPlatoonPosition(), bestTarget, 200)
                    if safePath then
                        local pathSize = table.getn(path)
                        for wpidx,waypointPath in path do
                            if wpidx == pathSize then
                                self:AggressiveMoveToLocation(bestTarget)
                            else
                                self:MoveToLocation(waypointPath, false)
                            end
                        end
                    else
                        self:AggressiveMoveToLocation(bestTarget)
                    end
                end
            end
            if not bestTarget then
                return self:AirHuntAI()
            end
            WaitSeconds(17)
        end
    end,

    FighterHuntAI = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local armyIndex = aiBrain:GetArmyIndex()
        local location = self.PlatoonData.LocationType or 'MAIN'
        local radius = self.PlatoonData.Radius or 100
        local target
        local blip
        local hadtarget = false
        while aiBrain:PlatoonExists(self) do
            if self:IsOpponentAIRunning() then
                target = self:FindClosestUnit('Attack', 'Enemy', true, categories.AIR - categories.POD)
                local newtarget = false
                if aiBrain.T4ThreatFound['Air'] then
                    newtarget = self:FindClosestUnit('Attack', 'Enemy', true, categories.EXPERIMENTAL * categories.AIR)
                    if newtarget then
                        target = newtarget
                    end
                end
                if target and newtarget and target:GetFractionComplete() == 1
                and SUtils.GetThreatAtPosition(aiBrain, target:GetPosition(), 1, 'AntiAir', {'Air'}) < (AIAttackUtils.GetAirThreatOfUnits(self) * .6) then
                    blip = target:GetBlip(armyIndex)
                    self:Stop()
                    self:AttackTarget(target)
                    hadtarget = true
                elseif target and target:GetFractionComplete() == 1
                and SUtils.GetThreatAtPosition(aiBrain, target:GetPosition(), 1, 'AntiAir', {'Air'}) < (AIAttackUtils.GetAirThreatOfUnits(self) * .6) then
                    blip = target:GetBlip(armyIndex)
                    self:Stop()
                    self:AggressiveMoveToLocation(table.copy(target:GetPosition()))
                    hadtarget = true
                elseif not target and hadtarget then
                    for k,v in AIUtils.GetBasePatrolPoints(aiBrain, location, radius, 'Air') do
                        self:Patrol(v)
                    end
                    hadtarget = false
                    return self:GuardExperimentalSorian(self.FighterHuntAI)
                end
            end
            local waitLoop = 0
            repeat
                WaitSeconds(1)
                waitLoop = waitLoop + 1
            until waitLoop >= 17 or (target and (target.Dead or not target:GetPosition()))
        end
    end,

    -------------------------------------------------------
    --   Function: GuardMarkerSorian
    --   Args:
    --       platoon - platoon to run the AI
    --   Description:
    --       Will guard the location of a marker
    --   Returns:
    --       nil
    -------------------------------------------------------
    GuardMarkerSorian = function(self)
        local aiBrain = self:GetBrain()

        local platLoc = self:GetPlatoonPosition()

        if not aiBrain:PlatoonExists(self) or not platLoc then
            return
        end

        -----------------------------------------------------------------------
        -- Platoon Data
        -----------------------------------------------------------------------
        -- type of marker to guard
        -- Start location = 'Start Location'... see MarkerTemplates.lua for other types
        local markerType = self.PlatoonData.MarkerType or 'Expansion Area'

        -- what should we look for for the first marker?  This can be 'Random',
        -- 'Threat' or 'Closest'
        local moveFirst = self.PlatoonData.MoveFirst or 'Threat'

        -- should our next move be no move be (same options as before) as well as 'None'
        -- which will cause the platoon to guard the first location they get to
        local moveNext = self.PlatoonData.MoveNext or 'None'

        -- Minimum distance when looking for closest
        local avoidClosestRadius = self.PlatoonData.AvoidClosestRadius or 0

        -- set time to wait when guarding a location with moveNext = 'None'
        local guardTimer = self.PlatoonData.GuardTimer or 0

        -- threat type to look at
        local threatType = self.PlatoonData.ThreatType or 'AntiSurface'

        -- should we look at our own threat or the enemy's
        local bSelfThreat = self.PlatoonData.SelfThreat or false

        -- if true, look to guard highest threat, otherwise,
        -- guard the lowest threat specified
        local bFindHighestThreat = self.PlatoonData.FindHighestThreat or false

        -- minimum threat to look for
        local minThreatThreshold = self.PlatoonData.MinThreatThreshold or -1
        -- maximum threat to look for
        local maxThreatThreshold = self.PlatoonData.MaxThreatThreshold  or 99999999

        -- Avoid bases (true or false)
        local bAvoidBases = self.PlatoonData.AvoidBases or false

        -- Radius around which to avoid the main base
        local avoidBasesRadius = self.PlatoonData.AvoidBasesRadius or 0

        -- Use Aggresive Moves Only
        local bAggroMove = self.PlatoonData.AggressiveMove or false

        local PlatoonFormation = self.PlatoonData.UseFormation or 'NoFormation'
        -----------------------------------------------------------------------


        AIAttackUtils.GetMostRestrictiveLayer(self)
        self:SetPlatoonFormationOverride(PlatoonFormation)
        local markerLocations = AIUtils.AIGetMarkerLocations(aiBrain, markerType)

        local bestMarker = false

        if not self.LastMarker then
            self.LastMarker = {nil,nil}
        end

        -- look for a random marker
        if moveFirst == 'Random' then
            if table.getn(markerLocations) <= 2 then
                self.LastMarker[1] = nil
                self.LastMarker[2] = nil
            end
            for _,marker in RandomIter(markerLocations) do
                if table.getn(markerLocations) <= 2 then
                    self.LastMarker[1] = nil
                    self.LastMarker[2] = nil
                end
                if self:AvoidsBasesSorian(marker.Position, bAvoidBases, avoidBasesRadius) then
                    if self.LastMarker[1] and marker.Position[1] == self.LastMarker[1][1] and marker.Position[3] == self.LastMarker[1][3] then
                        continue
                    end
                    if self.LastMarker[2] and marker.Position[1] == self.LastMarker[2][1] and marker.Position[3] == self.LastMarker[2][3] then
                        continue
                    end
                    bestMarker = marker
                    break
                end
            end
        elseif moveFirst == 'Threat' then
            --Guard the closest least-defended marker
            local bestMarkerThreat = 0
            if not bFindHighestThreat then
                bestMarkerThreat = 99999999
            end

            local bestDistSq = 99999999


            -- find best threat at the closest distance
            for _,marker in markerLocations do
                local markerThreat
                if bSelfThreat then
                    markerThreat = aiBrain:GetThreatAtPosition(marker.Position, 0, true, threatType, aiBrain:GetArmyIndex())
                else
                    markerThreat = aiBrain:GetThreatAtPosition(marker.Position, 0, true, threatType)
                end
                local distSq = VDist2Sq(marker.Position[1], marker.Position[3], platLoc[1], platLoc[3])

                if markerThreat >= minThreatThreshold and markerThreat <= maxThreatThreshold then
                    if self:AvoidsBasesSorian(marker.Position, bAvoidBases, avoidBasesRadius) then
                        if self.IsBetterThreat(bFindHighestThreat, markerThreat, bestMarkerThreat) then
                            bestDistSq = distSq
                            bestMarker = marker
                            bestMarkerThreat = markerThreat
                        elseif markerThreat == bestMarkerThreat then
                            if distSq < bestDistSq then
                                bestDistSq = distSq
                                bestMarker = marker
                                bestMarkerThreat = markerThreat
                            end
                        end
                     end
                 end
            end

        else
            -- if we didn't want random or threat, assume closest (but avoid ping-ponging)
            local bestDistSq = 99999999
            if table.getn(markerLocations) <= 2 then
                self.LastMarker[1] = nil
                self.LastMarker[2] = nil
            end
            for _,marker in markerLocations do
                local distSq = VDist2Sq(marker.Position[1], marker.Position[3], platLoc[1], platLoc[3])
                if self:AvoidsBasesSorian(marker.Position, bAvoidBases, avoidBasesRadius) and distSq > (avoidClosestRadius * avoidClosestRadius) then
                    if distSq < bestDistSq then
                        if self.LastMarker[1] and marker.Position[1] == self.LastMarker[1][1] and marker.Position[3] == self.LastMarker[1][3] then
                            continue
                        end
                        if self.LastMarker[2] and marker.Position[1] == self.LastMarker[2][1] and marker.Position[3] == self.LastMarker[2][3] then
                            continue
                        end
                        bestDistSq = distSq
                        bestMarker = marker
                    end
                end
            end
        end


        -- did we find a threat?
        local usedTransports = false
        if bestMarker then
            self.LastMarker[2] = self.LastMarker[1]
            self.LastMarker[1] = bestMarker.Position
            --LOG("GuardMarker: Attacking " .. bestMarker.Name)
            local path, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, self.MovementLayer, self:GetPlatoonPosition(), bestMarker.Position, 200)
            --local success, bestGoalPos = AIAttackUtils.CheckPlatoonPathingEx(self, bestMarker.Position)
            IssueClearCommands(self:GetPlatoonUnits())
            if path then
                local position = self:GetPlatoonPosition()
                if VDist2(position[1], position[3], bestMarker.Position[1], bestMarker.Position[3]) > 512 then
                    usedTransports = AIAttackUtils.SendPlatoonWithTransportsSorian(aiBrain, self, bestMarker.Position, true, false, false)
                elseif VDist2(position[1], position[3], bestMarker.Position[1], bestMarker.Position[3]) > 256 then
                    usedTransports = AIAttackUtils.SendPlatoonWithTransportsSorian(aiBrain, self, bestMarker.Position, false, false, false)
                end
                if not usedTransports then
                    local pathLength = table.getn(path)
                    for i=1, pathLength-1 do
                        if bAggroMove then
                            self:AggressiveMoveToLocation(path[i])
                        else
                            self:MoveToLocation(path[i], false)
                        end
                    end
                end
            elseif (not path and reason == 'NoPath') then
                usedTransports = AIAttackUtils.SendPlatoonWithTransportsSorian(aiBrain, self, bestMarker.Position, true, false, true)
            else
                self:PlatoonDisband()
                return
            end

            if not path and not usedTransports then
                self:PlatoonDisband()
                return
            end

            if moveNext == 'None' then
                -- guard
                IssueGuard(self:GetPlatoonUnits(), bestMarker.Position)
                -- guard forever
                if guardTimer <= 0 then return end
            else
                -- otherwise, we're moving to the location
                self:AggressiveMoveToLocation(bestMarker.Position)
            end

            -- wait till we get there
            local oldPlatPos = self:GetPlatoonPosition()
            local StuckCount = 0
            repeat
                WaitSeconds(5)
                platLoc = self:GetPlatoonPosition()
                if VDist3(oldPlatPos, platLoc) < 1 then
                    StuckCount = StuckCount + 1
                else
                    StuckCount = 0
                end
                if StuckCount > 5 then
                    return self:GuardMarkerSorian()
                end
                oldPlatPos = platLoc
            until VDist2Sq(platLoc[1], platLoc[3], bestMarker.Position[1], bestMarker.Position[3]) < 64 or not aiBrain:PlatoonExists(self)

            -- if we're supposed to guard for some time
            if moveNext == 'None' then
                -- this won't be 0... see above
                WaitSeconds(guardTimer)
                self:PlatoonDisband()
                return
            end

            if moveNext == 'Guard Base' then
                return self:GuardBaseSorian()
            end

            -- we're there... wait here until we're done
            local numGround = aiBrain:GetNumUnitsAroundPoint((categories.LAND + categories.NAVAL + categories.STRUCTURE), bestMarker.Position, 15, 'Enemy')
            while numGround > 0 and aiBrain:PlatoonExists(self) do
                WaitSeconds(Random(5,10))
                numGround = aiBrain:GetNumUnitsAroundPoint((categories.LAND + categories.NAVAL + categories.STRUCTURE), bestMarker.Position, 15, 'Enemy')
            end

            if not aiBrain:PlatoonExists(self) then
                return
            end

            -- set our MoveFirst to our MoveNext
            self.PlatoonData.MoveFirst = moveNext
            return self:GuardMarkerSorian()
        else
            -- no marker found, disband!
            self:PlatoonDisband()
        end
    end,

    -------------------------------------------------------
    --   Function: AirIntelToggle
    --   Args:
    --       self - platoon to run the AI
    --   Description:
    --       Turns on Air unit cloak/stealth.
    --   Returns:
    --       nil
    -------------------------------------------------------
    AirIntelToggle = function(self)
        --LOG('*AI DEBUG: AirIntelToggle run')
        for k,v in self:GetPlatoonUnits() do
            if v:TestToggleCaps('RULEUTC_StealthToggle') then
                v:SetScriptBit('RULEUTC_StealthToggle', false)
            end
        end
    end,

    GuardBaseSorian = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local armyIndex = aiBrain:GetArmyIndex()
        local target = false
        local basePosition = false
        local radius = self.PlatoonData.Radius or 100
        local patrolling = false

        if self.PlatoonData.LocationType and self.PlatoonData.LocationType != 'NOTMAIN' then
            basePosition = aiBrain.BuilderManagers[self.PlatoonData.LocationType].Position
        else
            local platoonPosition = self:GetPlatoonPosition()
            if platoonPosition then
                basePosition = aiBrain:FindClosestBuilderManagerPosition(self:GetPlatoonPosition())
        end
        end

        if not basePosition then
            return
        end

        local guardRadius = self.PlatoonData.GuardRadius or 200
        local mapSizeX, mapSizeZ = GetMapSize()
        local T4Radius = math.sqrt((mapSizeX * mapSizeX) + (mapSizeZ * mapSizeZ)) / 2

        while aiBrain:PlatoonExists(self) do
            if self:IsOpponentAIRunning() then
                target = self:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS - categories.WALL)
                local newtarget = false
                if aiBrain.T4ThreatFound['Air'] then
                    newtarget = self:FindClosestUnit('Attack', 'Enemy', true, categories.EXPERIMENTAL * categories.AIR)
                    if newtarget then
                        target = newtarget
                    end
                end
                if target and newtarget and not target.Dead and target:GetFractionComplete() == 1
                and SUtils.XZDistanceTwoVectorsSq(target:GetPosition(), basePosition) < T4Radius * T4Radius then
                    blip = target:GetBlip(armyIndex)
                    self:Stop()
                    self:AttackTarget(target)
                    patrolling = false
                elseif target and not target.Dead and SUtils.XZDistanceTwoVectorsSq(target:GetPosition(), basePosition) < guardRadius * guardRadius then
                    self:Stop()
                    self:AggressiveMoveToLocation(target:GetPosition())
                    patrolling = false
                elseif not patrolling then
                    local position = AIUtils.RandomLocation(basePosition[1],basePosition[3])
                    self:MoveToLocation(position, false)
                    for k,v in AIUtils.GetBasePatrolPoints(aiBrain, basePosition, radius, 'Air') do
                        self:Patrol(v)
                    end
                    patrolling = true
                end
            end
            WaitSeconds(5)
        end
    end,

    NavalForceAISorian = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()

        AIAttackUtils.GetMostRestrictiveLayer(self)

        local platoonUnits = self:GetPlatoonUnits()
        local numberOfUnitsInPlatoon = table.getn(platoonUnits)
        local oldNumberOfUnitsInPlatoon = numberOfUnitsInPlatoon
        local stuckCount = 0

        self.PlatoonAttackForce = true
        -- formations have penalty for taking time to form up... not worth it here
        -- maybe worth it if we micro
        --self:SetPlatoonFormationOverride('GrowthFormation')
        local PlatoonFormation = self.PlatoonData.UseFormation or 'No Formation'
        self:SetPlatoonFormationOverride(PlatoonFormation)

        for k,v in self:GetPlatoonUnits() do
            if v.Dead then
                continue
            end

            if v:GetCurrentLayer() == 'Sub' then
                continue
            end

            if v:TestCommandCaps('RULEUCC_Dive') then
                IssueDive({v})
            end
        end

        local maxRange, selectedWeaponArc, turretPitch = AIAttackUtils.GetNavalPlatoonMaxRangeSorian(aiBrain, self)
--      local quickReset = false

        while aiBrain:PlatoonExists(self) do
            local pos = self:GetPlatoonPosition() -- update positions; prev position done at end of loop so not done first time

            -- if we can't get a position, then we must be dead
            if not pos then
                break
            end

            -- pick out the enemy
            if aiBrain:GetCurrentEnemy() and aiBrain:GetCurrentEnemy():IsDefeated() then
                aiBrain:PickEnemyLogicSorian()
            end

            -- merge with nearby platoons
            --if aiBrain:GetThreatAtPosition(pos, 1, true, 'AntiSurface') < 1 then
                self:MergeWithNearbyPlatoonsSorian('NavalForceAISorian', 20)
            --end

            -- rebuild formation
            platoonUnits = self:GetPlatoonUnits()
            numberOfUnitsInPlatoon = table.getn(platoonUnits)
            -- if we have a different number of units in our platoon, regather
            if (oldNumberOfUnitsInPlatoon != numberOfUnitsInPlatoon) and aiBrain:GetThreatAtPosition(pos, 1, true, 'AntiSurface') < 1 then
                self:StopAttack()
                self:SetPlatoonFormationOverride(PlatoonFormation)
                oldNumberOfUnitsInPlatoon = numberOfUnitsInPlatoon
            end

            local cmdQ = {}
            -- fill cmdQ with current command queue for each unit
            for k,v in platoonUnits do
                if not v.Dead then
                    local unitCmdQ = v:GetCommandQueue()
                    for cmdIdx,cmdVal in unitCmdQ do
                        table.insert(cmdQ, cmdVal)
                        break
                    end
                end
            end

            if (oldNumberOfUnitsInPlatoon != numberOfUnitsInPlatoon) then
                maxRange, selectedWeaponArc, turretPitch = AIAttackUtils.GetNavalPlatoonMaxRangeSorian(aiBrain, self)
            end

            if not maxRange then maxRange = 180 end

            -- if we're on our final push through to the destination, and we find a unit close to our destination
            --local closestTarget = self:FindClosestUnit('attack', 'enemy', true, categories.ALLUNITS)
            local closestTarget = SUtils.FindClosestUnitPosToAttack(aiBrain, self, 'attack', maxRange + 20, categories.ALLUNITS - categories.AIR - categories.WALL, selectedWeaponArc, turretPitch)
            local nearDest = false
            local oldPathSize = table.getn(self.LastAttackDestination)

            if self.LastAttackDestination then
                nearDest = oldPathSize == 0 or VDist3(self.LastAttackDestination[oldPathSize], pos) < maxRange + 20
            end

            -- if we're near our destination and we have a unit closeby to kill, kill it
            if table.getn(cmdQ) <= 1 and closestTarget and nearDest then
                self:StopAttack()
                if PlatoonFormation != 'No Formation' then
                    self:AggressiveMoveToLocation(closestTarget:GetPosition())
                    --IssueFormAttack(platoonUnits, closestTarget, PlatoonFormation, 0)
                    --self:AttackTarget(closestTarget)
                    --IssueAttack(platoonUnits, closestTarget)
                else
                    self:AggressiveMoveToLocation(closestTarget:GetPosition())
                    --IssueFormAttack(platoonUnits, closestTarget, PlatoonFormation, 0)
                    --self:AttackTarget(closestTarget)
                    --IssueAttack(platoonUnits, closestTarget)
                end
                cmdQ = {1}
--              quickReset = true
            -- if we have a target and can attack it, attack!
            elseif closestTarget then
                self:StopAttack()
                if PlatoonFormation != 'No Formation' then
                    self:AggressiveMoveToLocation(closestTarget:GetPosition())
                    --IssueFormAttack(platoonUnits, closestTarget, PlatoonFormation, 0)
                    --self:AttackTarget(closestTarget)
                    --IssueAttack(platoonUnits, closestTarget)
                else
                    self:AggressiveMoveToLocation(closestTarget:GetPosition())
                    --IssueFormAttack(platoonUnits, closestTarget, PlatoonFormation, 0)
                    --self:AttackTarget(closestTarget)
                    --IssueAttack(platoonUnits, closestTarget)
                end
                cmdQ = {1}
--              quickReset = true
            -- if we have nothing to do, but still have a path (because of one of the above)
            elseif table.getn(cmdQ) == 0 and oldPathSize > 0 then
                self.LastAttackDestination = nil
                self:StopAttack()
                cmdQ = AIAttackUtils.AIPlatoonNavalAttackVectorSorian(aiBrain, self)
                stuckCount = 0
            -- if we have nothing to do, try finding something to do
            elseif table.getn(cmdQ) == 0 then
                self:StopAttack()
                cmdQ = AIAttackUtils.AIPlatoonNavalAttackVectorSorian(aiBrain, self)
                stuckCount = 0
            -- if we've been stuck and unable to reach next marker? Ignore nearby stuff and pick another target
            elseif self.LastPosition and VDist2Sq(self.LastPosition[1], self.LastPosition[3], pos[1], pos[3]) < (self.PlatoonData.StuckDistance or 50) then
                stuckCount = stuckCount + 1
                if stuckCount >= 2 then
                    self:StopAttack()
                    self.LastAttackDestination = nil
                    cmdQ = AIAttackUtils.AIPlatoonNavalAttackVectorSorian(aiBrain, self)
                    stuckCount = 0
                end
            else
                stuckCount = 0
            end

            self.LastPosition = pos

            --wait a while if we're stuck so that we have a better chance to move
--          if quickReset then
--              quickReset = false
--              WaitSeconds(6)
--          else
                WaitSeconds(Random(5,11) + 2 * stuckCount)
--          end
        end
    end,

    GatherUnitsSorian = function(self)
        if table.getn(self:GetPlatoonUnits()) == 1 then return true end
        local pos = self:GetPlatoonPosition()
        local unitsSet = true
        for k,v in self:GetPlatoonUnits() do
            if not v.Dead and SUtils.XZDistanceTwoVectorsSq(v:GetPosition(), pos) > 3600 then --60
               unitsSet = false
               break
            end
        end
        local aiBrain = self:GetBrain()
        if not unitsSet then
            local gatherPoint = AIUtils.AIGetClosestMarkerLocation(aiBrain, 'Rally Point', pos[1], pos[3])
            if not gatherPoint or SUtils.XZDistanceTwoVectorsSq(pos, gatherPoint) > 6400 then --80
                gatherPoint = AIUtils.AIGetClosestMarkerLocation(aiBrain, 'Defensive Point', pos[1], pos[3])
                if not gatherPoint or SUtils.XZDistanceTwoVectorsSq(pos, gatherPoint) > 6400 then --80
                    gatherPoint = self:GetPlatoonPosition()
                end
            end
            local cmd = self:MoveToLocation(gatherPoint, false)
            local counter = 0
            repeat
                WaitSeconds(1)
                counter = counter + 1
                if not aiBrain:PlatoonExists(self) then
                    return false
                end
                unitsSet = true
                for k,v in self:GetPlatoonUnits() do
                    if not v.Dead and SUtils.XZDistanceTwoVectorsSq(v:GetPosition(), gatherPoint) > 3600 then --60
                        unitsSet = false
                        break
                    end
                end
            until unitsSet or not self:IsCommandsActive(cmd) or counter >= 20
        end

        return true
    end,

    GuardExperimentalSorian = function(self, nextAIFunc)
        local aiBrain = self:GetBrain()

        if not aiBrain:PlatoonExists(self) or not self:GetPlatoonPosition() then
            return
        end

        AIAttackUtils.GetMostRestrictiveLayer(self)

        local unitToGuard = false
        local units = aiBrain:GetListOfUnits(categories.MOBILE * categories.EXPERIMENTAL - categories.url0401, false)
        for k,v in units do
            if v:GetFractionComplete() == 1 and ((self.MovementLayer == 'Air' and SUtils.GetGuardCount(aiBrain, v, categories.AIR) < 20) or ((self.MovementLayer == 'Land' or self.MovementLayer == 'Amphibious') and EntityCategoryContains(categories.LAND, v) and SUtils.GetGuardCount(aiBrain, v, categories.LAND) < 20)) then --not v.BeingGuarded then
                unitToGuard = v
                --v.BeingGuarded = true
            end
        end

        local guardTime = 0
        if unitToGuard and not unitToGuard.Dead then
            IssueGuard(self:GetPlatoonUnits(), unitToGuard)

            while aiBrain:PlatoonExists(self) and not unitToGuard.Dead do
                guardTime = guardTime + 5
                WaitSeconds(5)

                if aiBrain.T4ThreatFound['Air'] and self.MovementLayer == 'Air' then
                    local target = self:FindClosestUnit('Attack', 'Enemy', true, categories.EXPERIMENTAL * categories.AIR)
                    if target and target:GetFractionComplete() == 1 then
                        return self:FighterHuntAI()
                    end
                end

                if self.PlatoonData.T4GuardTimeLimit and guardTime >= self.PlatoonData.T4GuardTimeLimit
                or (not unitToGuard.Dead and unitToGuard:GetCurrentLayer() == 'Seabed' and self.MovementLayer == 'Land') then
                    break
                end
            end
        end

        ----Tail call into the next ai function
        WaitSeconds(1)
        if type(nextAIFunc) == 'function' then
            return nextAIFunc(self)
        end

        if not unitToGuard then
            return self:ReturnToBaseAISorian()
        end

        return self:GuardExperimentalSorian(nextAIFunc)
    end,


    SorianManagerEngineerAssistAI = function(self)
        local aiBrain = self:GetBrain()
        local assistData = self.PlatoonData.Assist
        local beingBuilt = false
        self:SorianEconAssistBody()
        WaitSeconds(assistData.Time or 60)
        local eng = self:GetPlatoonUnits()[1]
        if eng:GetGuardedUnit() then
            beingBuilt = eng:GetGuardedUnit()
        end
        if beingBuilt and assistData.AssistUntilFinished then
            while beingBuilt:IsUnitState('Building') or beingBuilt:IsUnitState('Upgrading') do
                WaitSeconds(5)
            end
        end
        if not aiBrain:PlatoonExists(self) then --or assistData.PermanentAssist then
            LOG('*AI DEBUG: Engie perma assisting')
            SUtils.AISendPing(eng:GetPosition(), 'move', aiBrain:GetArmyIndex())
            return
        end
        self.AssistPlatoon = nil
        self:PlatoonDisband()
    end,

    SorianEconAssistBody = function(self)
        local eng = self:GetPlatoonUnits()[1]
        if not eng then
            self:PlatoonDisband()
            return
        end
        local aiBrain = self:GetBrain()
        local assistData = self.PlatoonData.Assist
        local assistee = false

        eng.AssistPlatoon = self

        if not assistData.AssistLocation or not assistData.AssisteeType then
            WARN('*AI WARNING: Disbanding Assist platoon that does not have either AssistLocation or AssisteeType')
            self:PlatoonDisband()
        end

        local beingBuilt = assistData.BeingBuiltCategories or { 'ALLUNITS' }

        local assisteeCat = assistData.AssisteeCategory or categories.ALLUNITS
        if type(assisteeCat) == 'string' then
            assisteeCat = ParseEntityCategory(assisteeCat)
        end

        -- loop through different categories we are looking for
        for _,catString in beingBuilt do
            -- Track all valid units in the assist list so we can load balance for factories

            local category = ParseEntityCategory(catString)

            local assistList = AIUtils.GetAssisteesSorian(aiBrain, assistData.AssistLocation, assistData.AssisteeType, category, assisteeCat)

            if table.getn(assistList) > 0 then
                -- only have one unit in the list; assist it
                if table.getn(assistList) == 1
                and (not assistData.AssistRange or SUtils.XZDistanceTwoVectorsSq(eng:GetPosition(), assistList[1]:GetPosition()) < assistData.AssistRange) then
                    assistee = assistList[1]
                    break
                else
                    -- Find the unit with the least number of assisters; assist it
                    local lowNum = false
                    local lowUnit = false
                    for k,v in assistList do
                        if (not lowNum or table.getn(v:GetGuards()) < lowNum) and
                        (not assistData.AssistRange or SUtils.XZDistanceTwoVectorsSq(eng:GetPosition(), v:GetPosition()) < assistData.AssistRange) then
                            lowNum = v:GetGuards()
                            lowUnit = v
                        end
                    end
                    assistee = lowUnit
                    break
                end
            end
        end
        -- assist unit
        if assistee then
            self:Stop()
            eng.AssistSet = true
            IssueGuard({eng}, assistee)
        else
            self.AssistPlatoon = nil
            self:PlatoonDisband()
        end
    end,

    ManagerEngineerFindLowShield = function(self)
        local aiBrain = self:GetBrain()
        self:EconDamagedShield()
        WaitSeconds(60)
        if not aiBrain:PlatoonExists(self) then
            return
        end
        --self.AssistPlatoon = nil
        self:PlatoonDisband()
    end,

    EconDamagedShield = function(self)
        local eng = self:GetPlatoonUnits()[1]
        if not eng then
            self:PlatoonDisband()
            return
        end
        local aiBrain = self:GetBrain()
        local assistData = self.PlatoonData.Assist
        local assistee = false

        --eng.AssistPlatoon = self

        if not assistData.AssistLocation then
            WARN('*AI WARNING: Disbanding ManagerEngineerFindLowShield platoon that does not have either AssistLocation')
            self:PlatoonDisband()
        end

        local beingBuilt = assistData.BeingBuiltCategories or { 'ALLUNITS' }

        -- loop through different categories we are looking for
        for _,catString in beingBuilt do
            -- Track all valid units in the assist list so we can load balance for factories

            local category = ParseEntityCategory(catString)

            local assistList = SUtils.FindDamagedShield(aiBrain, assistData.AssistLocation, category)

            if assistList then
                assistee = assistList
                break
            end
        end
        -- assist unit
        if assistee then
            self:Stop()
            eng.AssistSet = true
            IssueGuard({eng}, assistee)
        else
            --self.AssistPlatoon = nil
            self:PlatoonDisband()
        end
    end,

    LandScoutingAISorian = function(self)
        AIAttackUtils.GetMostRestrictiveLayer(self)

        local aiBrain = self:GetBrain()
        local scout = self:GetPlatoonUnits()[1]

        aiBrain:BuildScoutLocationsSorian()

        --If we have cloaking (are cybran), then turn on our cloaking
        if self.PlatoonData.UseCloak and scout:TestToggleCaps('RULEUTC_CloakToggle') then
            scout:SetScriptBit('RULEUTC_CloakToggle', false)
        end

        while not scout.Dead do
            --Head towards the the area that has not had a scout sent to it in a while
            local targetData = false

            --For every scouts we send to all opponents, send one to scout a low pri area.
            if aiBrain.IntelData.HiPriScouts < aiBrain.NumOpponents and table.getn(aiBrain.InterestList.HighPriority) > 0 then
                targetData = aiBrain.InterestList.HighPriority[1]
                aiBrain.IntelData.HiPriScouts = aiBrain.IntelData.HiPriScouts + 1
                targetData.LastScouted = GetGameTimeSeconds()

                aiBrain:SortScoutingAreas(aiBrain.InterestList.HighPriority)

            elseif table.getn(aiBrain.InterestList.LowPriority) > 0 then
                targetData = aiBrain.InterestList.LowPriority[1]
                aiBrain.IntelData.HiPriScouts = 0
                targetData.LastScouted = GetGameTimeSeconds()

                aiBrain:SortScoutingAreas(aiBrain.InterestList.LowPriority)
            else
                --Reset number of scoutings and start over
                aiBrain.IntelData.HiPriScouts = 0
            end

            --Is there someplace we should scout?
            if targetData then
                --Can we get there safely?
                local path, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, self.MovementLayer, scout:GetPosition(), targetData.Position, 100)

                IssueClearCommands(self)

                if path then
                    local pathLength = table.getn(path)
                    for i=1, pathLength-1 do
                        self:MoveToLocation(path[i], false)
                    end
                end

                self:MoveToLocation(targetData.Position, false)

                --Scout until we reach our destination
                while not scout.Dead and not scout:IsIdleState() do
                    WaitSeconds(2.5)
                end
            end

            WaitSeconds(1)
        end
    end,

    AirScoutingAISorian = function(self)

        local aiBrain = self:GetBrain()
        local scout = self:GetPlatoonUnits()[1]
        local badScouting = false

        aiBrain:BuildScoutLocationsSorian()

        if scout:TestToggleCaps('RULEUTC_CloakToggle') then
            scout:SetScriptBit('RULEUTC_CloakToggle', false)
        end

        while not scout.Dead do
            local targetArea = false
            local highPri = false

            local mustScoutArea, mustScoutIndex = aiBrain:GetUntaggedMustScoutArea()
            local unknownThreats = aiBrain:GetThreatsAroundPosition(scout:GetPosition(), 16, true, 'Unknown')

            --1) If we have any "must scout" (manually added) locations that have not been scouted yet, then scout them
            if mustScoutArea then
                mustScoutArea.TaggedBy = scout
                targetArea = mustScoutArea.Position

            --2) Scout "unknown threat" areas with a threat higher than 25
            elseif table.getn(unknownThreats) > 0 and unknownThreats[1][3] > 25 then
                aiBrain:AddScoutArea({unknownThreats[1][1], 0, unknownThreats[1][2]})

            --3) Scout high priority locations
            elseif aiBrain.IntelData.AirHiPriScouts < aiBrain.NumOpponents and aiBrain.IntelData.AirLowPriScouts < 1
            and table.getn(aiBrain.InterestList.HighPriority) > 0 then
                aiBrain.IntelData.AirHiPriScouts = aiBrain.IntelData.AirHiPriScouts + 1

                highPri = true

                targetData = aiBrain.InterestList.HighPriority[1]
                targetData.LastScouted = GetGameTimeSeconds()
                targetArea = targetData.Position

                aiBrain:SortScoutingAreas(aiBrain.InterestList.HighPriority)

            --4) Every time we scout NumOpponents number of high priority locations, scout a low priority location
            elseif aiBrain.IntelData.AirLowPriScouts < 1 and table.getn(aiBrain.InterestList.LowPriority) > 0 then
                aiBrain.IntelData.AirHiPriScouts = 0
                aiBrain.IntelData.AirLowPriScouts = aiBrain.IntelData.AirLowPriScouts + 1

                targetData = aiBrain.InterestList.LowPriority[1]
                targetData.LastScouted = GetGameTimeSeconds()
                targetArea = targetData.Position

                aiBrain:SortScoutingAreas(aiBrain.InterestList.LowPriority)
            else
                --Reset number of scoutings and start over
                aiBrain.IntelData.AirLowPriScouts = 0
                aiBrain.IntelData.AirHiPriScouts = 0
            end

            --Air scout do scoutings.
            if targetArea then
                badScouting = false
                self:Stop()

                local vec = self:DoAirScoutVecs(scout, targetArea)

                while not scout.Dead and not scout:IsIdleState() do

                    --If we're close enough...
                    if VDist2Sq(vec[1], vec[3], scout:GetPosition()[1], scout:GetPosition()[3]) < 15625 then
                        if mustScoutArea then
                            --Untag and remove
                            for idx,loc in aiBrain.InterestList.MustScout do
                                if loc == mustScoutArea then
                                   table.remove(aiBrain.InterestList.MustScout, idx)
                                   break
                                end
                            end
                        end
                        --Break within 125 ogrids of destination so we don't decelerate trying to stop on the waypoint.
                        break
                    end

                    if VDist3(scout:GetPosition(), targetArea) < 25 then
                        break
                    end

                    WaitSeconds(5)
                end
            elseif not badScouting then
                self:Stop()
                badScouting = true
                markers = AIUtils.AIGetMarkerLocations(aiBrain, 'Combat Zone')
                if markers and table.getn(markers) > 0 then
                    local ScoutPath = {}
                    local MarkerCount = table.getn(markers)
                    for i = 1, MarkerCount do
                        rand = Random(1, MarkerCount + 1 - i)
                        table.insert(ScoutPath, markers[rand])
                        table.remove(markers, rand)
                    end
                    for k, v in ScoutPath do
                        self:Patrol(v.Position)
                    end
                end
                WaitSeconds(1)
            end
            WaitTicks(1)
        end
    end,

    ScoutingAISorian = function(self)
        AIAttackUtils.GetMostRestrictiveLayer(self)

        if self.MovementLayer == 'Air' then
            return self:AirScoutingAISorian()
        else
            return self:LandScoutingAISorian()
        end
    end,

    NavalHuntAI = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local armyIndex = aiBrain:GetArmyIndex()
        local target
        local blip
        local cmd = false
        local platoonUnits = self:GetPlatoonUnits()
        local PlatoonFormation = self.PlatoonData.UseFormation or 'NoFormation'
        self:SetPlatoonFormationOverride(PlatoonFormation)
        local atkPri = { 'SPECIALHIGHPRI', 'STRUCTURE ANTINAVY', 'MOBILE NAVAL', 'STRUCTURE NAVAL', 'COMMAND', 'EXPERIMENTAL', 'STRUCTURE STRATEGIC EXPERIMENTAL', 'ARTILLERY EXPERIMENTAL', 'STRUCTURE ARTILLERY TECH3', 'STRUCTURE NUKE TECH3', 'STRUCTURE ANTIMISSILE SILO',
                            'STRUCTURE DEFENSE DIRECTFIRE', 'TECH3 MASSFABRICATION', 'TECH3 ENERGYPRODUCTION', 'STRUCTURE STRATEGIC', 'STRUCTURE DEFENSE', 'STRUCTURE', 'MOBILE', 'SPECIALLOWPRI', 'ALLUNITS' }
        local atkPriTable = {}
        for k,v in atkPri do
            table.insert(atkPriTable, ParseEntityCategory(v))
        end
        self:SetPrioritizedTargetList('Attack', atkPriTable)
        local maxRadius = 6000
        for k,v in platoonUnits do

            if v.Dead then
                continue
            end

            if v:GetCurrentLayer() == 'Sub' then
                continue
            end

            if v:TestCommandCaps('RULEUCC_Dive') and v:GetUnitId() != 'uas0401' then
                IssueDive({v})
            end
        end
        WaitSeconds(5)
        while aiBrain:PlatoonExists(self) do
            if self:IsOpponentAIRunning() then
                target = AIUtils.AIFindBrainTargetInRangeSorian(aiBrain, self, 'Attack', maxRadius, atkPri)
                if target then
                    blip = target:GetBlip(armyIndex)
                    self:Stop()
                    cmd = self:AggressiveMoveToLocation(target:GetPosition())
                end
                WaitSeconds(1)
                if (not cmd or not self:IsCommandsActive(cmd)) then
                    target = self:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS - categories.WALL)
                    if target then
                        blip = target:GetBlip(armyIndex)
                        self:Stop()
                        cmd = self:AggressiveMoveToLocation(target:GetPosition())
                    else
                        local scoutPath = {}
                        scoutPath = AIUtils.AIGetSortedNavalLocations(self:GetBrain())
                        for k, v in scoutPath do
                            self:Patrol(v)
                        end
                    end
                end
            end
            WaitSeconds(17)
        end
    end,

    HuntAISorian = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local armyIndex = aiBrain:GetArmyIndex()
        local target
        local blip
        local platoonUnits = self:GetPlatoonUnits()
        local PlatoonFormation = self.PlatoonData.UseFormation or 'NoFormation'
        self:SetPlatoonFormationOverride(PlatoonFormation)
        while aiBrain:PlatoonExists(self) do
            local mySurfaceThreat = AIAttackUtils.GetSurfaceThreatOfUnits(self)
            local inWater = AIAttackUtils.InWaterCheck(self)
            local pos = self:GetPlatoonPosition()
            local threatatLocation = aiBrain:GetThreatAtPosition(pos, 1, true, 'AntiSurface')
            if self:IsOpponentAIRunning() then
                target = self:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS - categories.AIR - categories.NAVAL - categories.SCOUT)
                if target then
                    blip = target:GetBlip(armyIndex)
                    self:Stop()
                    if not inWater then
                        IssueAggressiveMove(platoonUnits, target:GetPosition())
                    else
                        IssueMove(platoonUnits, target:GetPosition())
                    end
                end
            end
            WaitSeconds(17)
        end
    end,

    CDRHuntAISorian = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local armyIndex = aiBrain:GetArmyIndex()
        local target
        local platoonUnits = self:GetPlatoonUnits()
        local eng
        for k, v in platoonUnits do
            if not v.Dead and EntityCategoryContains(categories.COMMAND, v) then
                eng = v
            end
        end
        local leashRange = eng.Mult * 100
        local weapBPs = eng:GetBlueprint().Weapon
        local weapon
        eng.Fighting = true
        for k,v in weapBPs do
            if v.Label == 'OverCharge' then
                weapon = v
                break
            end
        end
        local weapRange = weapon.MaxRadius
        local movingToScout = false
        local initialMove = true
        while aiBrain:PlatoonExists(self) do
            local mySurfaceThreat = eng:GetBlueprint().Defense.SurfaceThreatLevel or 75
            local pos = self:GetPlatoonPosition()
            if self:IsOpponentAIRunning() then
                local target = self:FindClosestUnit('support', 'Enemy', true, categories.ALLUNITS - categories.AIR - categories.NAVAL - categories.SCOUT)
                if target and not target.Dead and SUtils.XZDistanceTwoVectorsSq(target:GetPosition(), eng.CDRHome) < (leashRange * leashRange) and
                aiBrain:GetThreatBetweenPositions(pos, target:GetPosition(), nil, 'AntiSurface') < mySurfaceThreat then
                --aiBrain:GetThreatAtPosition(target:GetPosition(), 1, true, 'AntiSurface') < mySurfaceThreat * 1.5 then
                    movingToScout = false
                    local targetLoc = target:GetPosition()
                    self:Stop()
                    if aiBrain:GetEconomyStored('ENERGY') >= weapon.EnergyRequired and VDist2Sq(targetLoc[1], targetLoc[3], pos[1], pos[3]) <= weapRange * weapRange then
                        IssueClearCommands({eng})
                        IssueOverCharge({eng}, target)
                    else
                        IssueClearCommands({eng})
                        IssueMove({eng}, targetLoc)
                    end
                elseif not movingToScout then
                    self:Stop()
                    local DefSpots = AIUtils.AIGetSortedDefensiveLocationsFromLast(aiBrain, 10)
                    if table.getn(DefSpots) > 0 then
                        for k,v in DefSpots do
                            if SUtils.XZDistanceTwoVectorsSq(v, eng.CDRHome) < (leashRange * leashRange) and (SUtils.XZDistanceTwoVectorsSq(v, eng.CDRHome) > SUtils.XZDistanceTwoVectorsSq(pos, eng.CDRHome) and initialMove) then
                                movingToScout = true
                                self:MoveToLocation(v, false)
                            end
                        end
                        if not movingToScout then
                            initialMove = false
                        end
                    end
                end
            end
            WaitSeconds(5)
        end
        eng.Fighting = false
        eng.PlatoonHandle:PlatoonDisband()
    end,

    GhettoAISorian = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local target
        local haveTransports = false
        local counter = 0
        local units = self:GetPlatoonUnits()
        while true do
            haveTransports = AIUtils.GetTransports(platoon)
            counter = counter + 1
            if haveTransports or counter > 11 then break end
            WaitSeconds(10)
        end

        if not haveTransports then
            return self:HuntAISorian()
        end

        local transport
        for k,v in self:GetPlatoonUnits() do
            if EntityCategoryContains(categories.TRANSPORTFOCUS, v) then
                transport = v
                break
            end
        end

        AIUtils.UseTransportsGhetto(units, {transport})

        local data = self.PlatoonData
        local maxRadius = data.SearchRadius or 50
        local categoryList = {}
        local atkPri = {}
        if data.PrioritizedCategories then
            for k,v in data.PrioritizedCategories do
                table.insert(atkPri, v)
                table.insert(categoryList, ParseEntityCategory(v))
            end
        end
        table.insert(atkPri, 'ALLUNITS')
        table.insert(categoryList, categories.ALLUNITS)
        self:SetPrioritizedTargetList('Attack', categoryList)

        while aiBrain:PlatoonExists(self) do
            local pos = self:GetPlatoonPosition()
            if self:IsOpponentAIRunning() then
                target = AIUtils.AIFindBrainTargetInRange(aiBrain, self, 'Attack', maxRadius * 25, atkPri, aiBrain:GetCurrentEnemy())
                if target then
                    self:AttackTarget(target)
                end
            end
            if transport:GetHealthPercent() < .35 then
                IssueTransportUnload(transport, self:GetPlatoonPosition())
            end
            WaitSeconds(17)
        end
    end,

    AttackForceAISorian = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()

        -- get units together
        if not self:GatherUnitsSorian() then
            self:PlatoonDisband()
        end

        -- Setup the formation based on platoon functionality

        local enemy = aiBrain:GetCurrentEnemy()

        local platoonUnits = self:GetPlatoonUnits()
        local numberOfUnitsInPlatoon = table.getn(platoonUnits)
        local oldNumberOfUnitsInPlatoon = numberOfUnitsInPlatoon
        local platoonTechLevel = SUtils.GetPlatoonTechLevel(platoonUnits)
        local platoonThreatTable = {4,28,80}
        local stuckCount = 0

        self.PlatoonAttackForce = true
        -- formations have penalty for taking time to form up... not worth it here
        -- maybe worth it if we micro
        --self:SetPlatoonFormationOverride('GrowthFormation')
        local bAggro = self.PlatoonData.AggressiveMove or false
        local PlatoonFormation = self.PlatoonData.UseFormation or 'No Formation'
        self:SetPlatoonFormationOverride(PlatoonFormation)
        local maxRange, selectedWeaponArc, turretPitch = AIAttackUtils.GetLandPlatoonMaxRangeSorian(aiBrain, self)
        --local quickReset = false

        while aiBrain:PlatoonExists(self) do
            local pos = self:GetPlatoonPosition() -- update positions; prev position done at end of loop so not done first time

            -- if we can't get a position, then we must be dead
            if not pos then
                self:PlatoonDisband()
            end


            -- if we're using a transport, wait for a while
            if self.UsingTransport then
                WaitSeconds(10)
                continue
            end

            -- pick out the enemy
            if aiBrain:GetCurrentEnemy() and aiBrain:GetCurrentEnemy():IsDefeated() then
                aiBrain:PickEnemyLogicSorian()
            end

            -- merge with nearby platoons
            --if aiBrain:GetThreatAtPosition(pos, 1, true, 'AntiSurface') < 1 then
                self:MergeWithNearbyPlatoonsSorian('AttackForceAISorian', 10)
            --end

            -- rebuild formation
            platoonUnits = self:GetPlatoonUnits()
            numberOfUnitsInPlatoon = table.getn(platoonUnits)
            -- if we have a different number of units in our platoon, regather
            local threatatLocation = aiBrain:GetThreatAtPosition(pos, 1, true, 'AntiSurface')
            if (oldNumberOfUnitsInPlatoon != numberOfUnitsInPlatoon) and threatatLocation < 1 then
                self:StopAttack()
                self:SetPlatoonFormationOverride(PlatoonFormation)
                oldNumberOfUnitsInPlatoon = numberOfUnitsInPlatoon
            end

            -- deal with lost-puppy transports
            local strayTransports = {}
            for k,v in platoonUnits do
                if EntityCategoryContains(categories.TRANSPORTATION, v) then
                    table.insert(strayTransports, v)
                end
            end
            if table.getn(strayTransports) > 0 then
                local dropPoint = pos
                dropPoint[1] = dropPoint[1] + Random(-3, 3)
                dropPoint[3] = dropPoint[3] + Random(-3, 3)
                IssueTransportUnload(strayTransports, dropPoint)
                WaitSeconds(10)
                local strayTransports = {}
                for k,v in platoonUnits do
                    local parent = v:GetParent()
                    if parent and EntityCategoryContains(categories.TRANSPORTATION, parent) then
                        table.insert(strayTransports, parent)
                        break
                    end
                end
                if table.getn(strayTransports) > 0 then
                    local MAIN = aiBrain.BuilderManagers.MAIN
                    if MAIN then
                        dropPoint = MAIN.Position
                        IssueTransportUnload(strayTransports, dropPoint)
                        WaitSeconds(30)
                    end
                end
                self.UsingTransport = false
                AIUtils.ReturnTransportsToPool(strayTransports, true)
                platoonUnits = self:GetPlatoonUnits()
            end


            --Disband platoon if it's all air units, so they can be picked up by another platoon
            local mySurfaceThreat = AIAttackUtils.GetSurfaceThreatOfUnits(self)
            if mySurfaceThreat == 0 and AIAttackUtils.GetAirThreatOfUnits(self) > 0 then
                self:PlatoonDisband()
                return
            end

            local cmdQ = {}
            -- fill cmdQ with current command queue for each unit
            for k,v in platoonUnits do
                if not v.Dead then
                    local unitCmdQ = v:GetCommandQueue()
                    for cmdIdx,cmdVal in unitCmdQ do
                        table.insert(cmdQ, cmdVal)
                        break
                    end
                end
            end

            if (oldNumberOfUnitsInPlatoon != numberOfUnitsInPlatoon) then
                maxRange, selectedWeaponArc, turretPitch = AIAttackUtils.GetLandPlatoonMaxRangeSorian(aiBrain, self)
            end

            if not maxRange then maxRange = 50 end

            -- if we're on our final push through to the destination, and we find a unit close to our destination
            --local closestTarget = self:FindClosestUnit('attack', 'enemy', true, categories.ALLUNITS)
            local closestTarget = SUtils.FindClosestUnitPosToAttack(aiBrain, self, 'attack', maxRange + 20, categories.ALLUNITS - categories.AIR - categories.NAVAL - categories.SCOUT, selectedWeaponArc, turretPitch)
            local nearDest = false
            local oldPathSize = table.getn(self.LastAttackDestination)
            if self.LastAttackDestination then
                nearDest = oldPathSize == 0 or VDist3(self.LastAttackDestination[oldPathSize], pos) < 20
            end

            local inWater = AIAttackUtils.InWaterCheck(self)

        -- if we're near our destination and we have a unit closeby to kill, kill it
            if table.getn(cmdQ) <= 1 and closestTarget and nearDest then
                self:StopAttack()
                if not inWater then
                    self:AggressiveMoveToLocation(closestTarget:GetPosition())
                else
                    self:MoveToLocation(closestTarget:GetPosition(), false)
                end
                cmdQ = {1}
--              quickReset = true
            -- if we have a target and can attack it, attack!
            elseif closestTarget then
                self:StopAttack()
                if not inWater then
                    self:AggressiveMoveToLocation(closestTarget:GetPosition())
                else
                    self:MoveToLocation(closestTarget:GetPosition(), false)
                end
                cmdQ = {1}
--              quickReset = true
            -- if we have nothing to do, but still have a path (because of one of the above)
            elseif table.getn(cmdQ) == 0 and oldPathSize > 0 then
                self.LastAttackDestination = {}
                self:StopAttack()
                cmdQ = AIAttackUtils.AIPlatoonSquadAttackVectorSorian(aiBrain, self, bAggro)
                stuckCount = 0
            -- if we have nothing to do, try finding something to do
            elseif table.getn(cmdQ) == 0 then
                self:StopAttack()
                cmdQ = AIAttackUtils.AIPlatoonSquadAttackVectorSorian(aiBrain, self, bAggro)
                stuckCount = 0
            -- if we've been stuck and unable to reach next marker? Ignore nearby stuff and pick another target
            elseif self.LastPosition and VDist2Sq(self.LastPosition[1], self.LastPosition[3], pos[1], pos[3]) < (self.PlatoonData.StuckDistance or 8) then
                stuckCount = stuckCount + 1
                if stuckCount >= 2 then
                    self:StopAttack()
                    self.LastAttackDestination = {}
                    cmdQ = AIAttackUtils.AIPlatoonSquadAttackVectorSorian(aiBrain, self, bAggro)
                    stuckCount = 0
                end
            else
                stuckCount = 0
            end

            self.LastPosition = pos

--[[            if table.getn(cmdQ) == 0 then --and mySurfaceThreat < 4 then
                -- if we have a low threat value, then go and defend an engineer or a base
                if mySurfaceThreat < platoonThreatTable[platoonTechLevel]
                    and mySurfaceThreat > 0 and not self.PlatoonData.NeverGuard
                    and not (self.PlatoonData.NeverGuardEngineers and self.PlatoonData.NeverGuardBases) then
                    --LOG('*DEBUG: Trying to guard')
                    --if platoonTechLevel > 1 then
                    --  return self:GuardExperimentalSorian(self.AttackForceAISorian)
                    --else
                        return self:GuardEngineer(self.AttackForceAISorian)
                    --end
                end

                -- we have nothing to do, so find the nearest base and disband
                if not self.PlatoonData.NeverMerge then
                    return self:ReturnToBaseAISorian()
                end
                WaitSeconds(5)
            else
                -- wait a little longer if we're stuck so that we have a better chance to move
                if quickReset then
                    quickReset = false
                    WaitSeconds(6)
                else ]]--
                WaitSeconds(Random(5,11) + 2 * stuckCount)
--              end
--            end
        end
    end,

    ReturnToBaseAISorian = function(self)
        local aiBrain = self:GetBrain()

        if not aiBrain:PlatoonExists(self) or not self:GetPlatoonPosition() then
            return
        end

        local bestBase = false
        local bestBaseName = ""
        local bestDistSq = 999999999
        local platPos = self:GetPlatoonPosition()

        for baseName, base in aiBrain.BuilderManagers do
            local distSq = VDist2Sq(platPos[1], platPos[3], base.Position[1], base.Position[3])

            if distSq < bestDistSq then
                bestBase = base
                bestBaseName = baseName
                bestDistSq = distSq
            end
        end

        if bestBase then
            AIAttackUtils.GetMostRestrictiveLayer(self)
            local path, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, self.MovementLayer, self:GetPlatoonPosition(), bestBase.Position, 200)
            IssueClearCommands(self)

            if path then
                local pathLength = table.getn(path)
                for i=1, pathLength-1 do
                    self:MoveToLocation(path[i], false)
                end
            end
            self:MoveToLocation(bestBase.Position, false)

            local oldDistSq = 0
            while aiBrain:PlatoonExists(self) do
                platPos = self:GetPlatoonPosition()
                local distSq = VDist2Sq(platPos[1], platPos[3], bestBase.Position[1], bestBase.Position[3])
                if distSq < 5625 then -- 75 * 75
                    self:PlatoonDisband()
                    return
                end
                WaitSeconds(10)
                -- if we haven't moved in 10 seconds... go back to attacking
                if (distSq - oldDistSq) < 25 then -- 5 * 5
                    break
                end
                oldDistSq = distSq
            end
        end
        -- default to returning to attacking
        return self:AttackForceAISorian()
    end,

    StrikeForceAISorian = function(self)
        local aiBrain = self:GetBrain()
        local armyIndex = aiBrain:GetArmyIndex()
        local data = self.PlatoonData
        local categoryList = {}
        local atkPri = {}
        if data.PrioritizedCategories then
            for k,v in data.PrioritizedCategories do
                table.insert(atkPri, v)
                table.insert(categoryList, ParseEntityCategory(v))
            end
        end
        table.insert(atkPri, 'ALLUNITS')
        table.insert(categoryList, categories.ALLUNITS)
        self:SetPrioritizedTargetList('Attack', categoryList)
        local target = false
        local oldTarget = false
        local blip = false
        local maxRadius = data.SearchRadius or 50
        local movingToScout = false
        AIAttackUtils.GetMostRestrictiveLayer(self)
        while aiBrain:PlatoonExists(self) do
            if target then
                local targetCheck = true
                for k,v in atkPri do
                    local category = ParseEntityCategory(v)
                    if EntityCategoryContains(category, target) and v != 'ALLUNITS' then
                        targetCheck = false
                        break
                    end
                end
                if targetCheck then
                    target = false
                    oldTarget = false
                end
            end
            if not target or target.Dead or not target:GetPosition() then
                if aiBrain:GetCurrentEnemy() and aiBrain:GetCurrentEnemy():IsDefeated() then
                    aiBrain:PickEnemyLogicSorian()
                end
                --local mult = { 1,10,25 }
                --for _,i in mult do
                    target = AIUtils.AIFindBrainTargetInRange(aiBrain, self, 'Attack', maxRadius * 25, atkPri, aiBrain:GetCurrentEnemy())
                --    if target then
                --        break
                --    end
                --    WaitSeconds(3)
                --    if not aiBrain:PlatoonExists(self) then
                --        return
                --    end
                --end
                local newtarget = false
                if AIAttackUtils.GetSurfaceThreatOfUnits(self) > 0 and (aiBrain.T4ThreatFound['Land'] or aiBrain.T4ThreatFound['Naval'] or aiBrain.T4ThreatFound['Structure']) then
                    newtarget = self:FindClosestUnit('Attack', 'Enemy', true, categories.EXPERIMENTAL * (categories.LAND + categories.NAVAL + categories.STRUCTURE + categories.ARTILLERY))
                elseif AIAttackUtils.GetAirThreatOfUnits(self) > 0 and aiBrain.T4ThreatFound['Air'] then
                    newtarget = self:FindClosestUnit('Attack', 'Enemy', true, categories.EXPERIMENTAL * categories.AIR)
                end
                if newtarget then
                    target = newtarget
                end
                if target and (target != oldTarget or movingToScout) then
                    oldTarget = target
                    local path, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, self.MovementLayer, self:GetPlatoonPosition(), target:GetPosition(), 10)
                    self:Stop()
                    if not path then
                        if reason == 'NoStartNode' or reason == 'NoEndNode' then
                            if not data.UseMoveOrder then
                                self:AttackTarget(target)
                            else
                                self:MoveToLocation(table.copy(target:GetPosition()), false)
                            end
                        end
                    else
                        local pathSize = table.getn(path)
                        for wpidx,waypointPath in path do
                            if wpidx == pathSize and not data.UseMoveOrder then
                                self:AttackTarget(target)
                            else
                                self:MoveToLocation(waypointPath, false)
                            end
                        end
                    end
                    movingToScout = false
                elseif not movingToScout and not target and self.MovementLayer != 'Water' then
                    movingToScout = true
                    self:Stop()
                    local MassSpots = AIUtils.AIGetSortedMassLocations(aiBrain, 10, nil, nil, nil, nil, self:GetPlatoonPosition())
                    if table.getn(MassSpots) > 0 then
                        for k,v in MassSpots do
                            self:MoveToLocation(v, false)
                        end
                    else
                        local x,z = aiBrain:GetArmyStartPos()
                        local position = AIUtils.RandomLocation(x,z)
                        local safePath, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, 'Air', self:GetPlatoonPosition(), position, 200)
                        if safePath then
                            for _,p in safePath do
                                self:MoveToLocation(p, false)
                            end
                        else
                            self:MoveToLocation(position, false)
                        end
                    end
                elseif not movingToScout and not target and self.MovementLayer == 'Water' then
                    movingToScout = true
                    self:Stop()
                    local scoutPath = {}
                    scoutPath = AIUtils.AIGetSortedNavalLocations(self:GetBrain())
                    for k, v in scoutPath do
                        self:Patrol(v)
                    end
                end
            end
            if self.MovementLayer == 'Air' then
                local waitLoop = 0
                repeat
                    WaitSeconds(1)
                    waitLoop = waitLoop + 1
                until waitLoop >= 7 or (target and (target.Dead or not target:GetPosition()))
            else
                WaitSeconds(7)
            end
        end
    end,

    -------------------------------------------------------
    --   Function: EngineerBuildAI
    --   Args:
    --       self - the single-engineer platoon to run the AI on
    --   Description:
    --       a single-unit platoon made up of an engineer, this AI will determine
    --       what needs to be built (based on platoon data set by the calling
    --       abstraction, and then issue the build commands to the engineer
    --   Returns:
    --       nil (tail calls into a behavior function)
    -------------------------------------------------------
    EngineerBuildAISorian = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local cons = self.PlatoonData.Construction

        if cons.T4 and not aiBrain.T4Building then
            aiBrain.T4Building = true
            ForkThread(SUtils.T4Timeout, aiBrain)
        end

        local platoonUnits = self:GetPlatoonUnits()
        local armyIndex = aiBrain:GetArmyIndex()
        local x,z = aiBrain:GetArmyStartPos()
        local buildingTmpl, buildingTmplFile, baseTmpl, baseTmplFile

        local factionIndex = cons.FactionIndex or self:GetFactionIndex()

        if not SUtils.CheckForMapMarkers(aiBrain) and cons.NearMarkerType and (cons.NearMarkerType == 'Rally Point' or
        cons.NearMarkerType == 'Protected Experimental Construction') then
            cons.NearMarkerType = nil
            cons.BaseTemplate = nil
        end

        buildingTmplFile = import(cons.BuildingTemplateFile or '/lua/BuildingTemplates.lua')
        baseTmplFile = import(cons.BaseTemplateFile or '/lua/BaseTemplates.lua')
        buildingTmpl = buildingTmplFile[(cons.BuildingTemplate or 'BuildingTemplates')][factionIndex]
        baseTmpl = baseTmplFile[(cons.BaseTemplate or 'BaseTemplates')][factionIndex]

        local eng
        for k, v in platoonUnits do
            if not v.Dead and EntityCategoryContains(categories.CONSTRUCTION, v) then
                if not eng then
                    eng = v
                else
                    IssueClearCommands({v})
                    IssueGuard({v}, eng)
                end
            end
        end

        if not eng or eng.Dead then
            WaitTicks(1)
            self:PlatoonDisband()
            return
        end

        if self.PlatoonData.NeedGuard then
            eng.NeedGuard = true
        end

        -------- CHOOSE APPROPRIATE BUILD FUNCTION AND SETUP BUILD VARIABLES --------
        local reference = false
        local refName = false
        local buildFunction
        local closeToBuilder
        local relative
        local baseTmplList = {}

        -- if we have nothing to build, disband!
        if not cons.BuildStructures then
            WaitTicks(1)
            self:PlatoonDisband()
            return
        end

        if cons.NearUnitCategory then
            self:SetPrioritizedTargetList('support', {ParseEntityCategory(cons.NearUnitCategory)})
            local unitNearBy = self:FindPrioritizedUnit('support', 'Ally', false, self:GetPlatoonPosition(), cons.NearUnitRadius or 50)
            --LOG("ENGINEER BUILD: " .. cons.BuildStructures[1] .." attempt near: ", cons.NearUnitCategory)
            if unitNearBy then
                reference = table.copy(unitNearBy:GetPosition())
                -- get commander home position
                --LOG("ENGINEER BUILD: " .. cons.BuildStructures[1] .." Near unit: ", cons.NearUnitCategory)
                if cons.NearUnitCategory == 'COMMAND' and unitNearBy.CDRHome then
                    reference = unitNearBy.CDRHome
                end
            else
                reference = table.copy(eng:GetPosition())
            end
            relative = false
            buildFunction = AIBuildStructures.AIExecuteBuildStructure
            table.insert(baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation(baseTmpl, reference))
        elseif cons.Wall then
            local pos = aiBrain:PBMGetLocationCoords(cons.LocationType) or cons.Position or self:GetPlatoonPosition()
            local radius = cons.LocationRadius or aiBrain:PBMGetLocationRadius(cons.LocationType) or 100
            relative = false
            reference = AIUtils.GetLocationNeedingWalls(aiBrain, 200, 5, 'DEFENSE', cons.ThreatMin, cons.ThreatMax, cons.ThreatRings)
            table.insert(baseTmplList, 'Blank')
            buildFunction = AIBuildStructures.WallBuilder
        elseif cons.NearBasePatrolPoints then
            relative = false
            reference = AIUtils.GetBasePatrolPointsSorian(aiBrain, cons.Location or 'MAIN', cons.Radius or 100)
            baseTmpl = baseTmplFile['ExpansionBaseTemplates'][factionIndex]
            for k,v in reference do
                table.insert(baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation(baseTmpl, v))
            end
            -- Must use BuildBaseOrdered to start at the marker; otherwise it builds closest to the eng
            buildFunction = AIBuildStructures.AIBuildBaseTemplateOrdered
        elseif cons.NearMarkerType and cons.ExpansionBase then
            local pos = aiBrain:PBMGetLocationCoords(cons.LocationType) or cons.Position or self:GetPlatoonPosition()
            local radius = cons.LocationRadius or aiBrain:PBMGetLocationRadius(cons.LocationType) or 100

            if cons.FireBase and cons.FireBaseRange then
                reference, refName = AIUtils.AIFindFirebaseLocationSorian(aiBrain, cons.LocationType, cons.FireBaseRange, cons.NearMarkerType,
                                                    cons.ThreatMin, cons.ThreatMax, cons.ThreatRings, cons.ThreatType,
                                                    cons.MarkerUnitCount, cons.MarkerUnitCategory, cons.MarkerRadius)
                if not reference or not refName then
                    self:PlatoonDisband()
                end
            elseif cons.NearMarkerType == 'Expansion Area' then
                reference, refName = AIUtils.AIFindExpansionAreaNeedsEngineer(aiBrain, cons.LocationType,
                        (cons.LocationRadius or 100), cons.ThreatMin, cons.ThreatMax, cons.ThreatRings, cons.ThreatType)
                -- didn't find a location to build at
                if not reference or not refName then
                    self:PlatoonDisband()
                end
            elseif cons.NearMarkerType == 'Naval Area' then
                reference, refName = AIUtils.AIFindNavalAreaNeedsEngineer(aiBrain, cons.LocationType,
                        (cons.LocationRadius or 100), cons.ThreatMin, cons.ThreatMax, cons.ThreatRings, cons.ThreatType)
                -- didn't find a location to build at
                if not reference or not refName then
                    self:PlatoonDisband()
                end
            else
                local mapSizeX, mapSizeZ = GetMapSize()
                if mapSizeX > 512 and mapSizeZ > 512 then
                    reference, refName = AIUtils.AIFindStartLocationNeedsEngineerSorian(aiBrain, cons.LocationType,
                            (cons.LocationRadius or 100), cons.ThreatMin, cons.ThreatMax, cons.ThreatRings, cons.ThreatType)
                else
                    reference, refName = AIUtils.AIFindStartLocationNeedsEngineer(aiBrain, cons.LocationType,
                            (cons.LocationRadius or 100), cons.ThreatMin, cons.ThreatMax, cons.ThreatRings, cons.ThreatType)
                end
                -- didn't find a location to build at
                if not reference or not refName then
                    self:PlatoonDisband()
                end
            end

            -- If moving far from base, tell the assisting platoons to not go with
            if cons.FireBase or cons.ExpansionBase then
                local guards = eng:GetGuards()
                for k,v in guards do
                    if not v.Dead and v.PlatoonHandle and EntityCategoryContains(categories.CONSTRUCTION, v) then
                        v.PlatoonHandle:PlatoonDisband()
                    end
                end
            end

            if not cons.BaseTemplate and (cons.NearMarkerType == 'Naval Area' or cons.NearMarkerType == 'Defensive Point' or cons.NearMarkerType == 'Expansion Area') then
                baseTmpl = baseTmplFile['ExpansionBaseTemplates'][factionIndex]
            end
            if cons.ExpansionBase and refName then
                AIBuildStructures.AINewExpansionBase(aiBrain, refName, reference, eng, cons)
            end
            relative = false
            if reference and aiBrain:GetThreatAtPosition(reference , 1, true, 'AntiSurface') > 0 then
                --aiBrain:ExpansionHelp(eng, reference)
            end
            table.insert(baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation(baseTmpl, reference))
            -- Must use BuildBaseOrdered to start at the marker; otherwise it builds closest to the eng
            --buildFunction = AIBuildStructures.AIBuildBaseTemplateOrdered
            buildFunction = AIBuildStructures.AIBuildBaseTemplate
        elseif cons.NearMarkerType and cons.FireBase and cons.FireBaseRange then
            baseTmpl = baseTmplFile['ExpansionBaseTemplates'][factionIndex]

            relative = false
            local pos = self:GetPlatoonPosition()
            reference, refName = AIUtils.AIFindFirebaseLocationSorian(aiBrain, cons.LocationType, cons.FireBaseRange, cons.NearMarkerType,
                                                cons.ThreatMin, cons.ThreatMax, cons.ThreatRings, cons.ThreatType,
                                                cons.MarkerUnitCount, cons.MarkerUnitCategory, cons.MarkerRadius)

            table.insert(baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation(baseTmpl, reference))

            buildFunction = AIBuildStructures.AIExecuteBuildStructure
        elseif cons.NearMarkerType and cons.NearMarkerType == 'Defensive Point' then
            baseTmpl = baseTmplFile['ExpansionBaseTemplates'][factionIndex]

            relative = false
            local pos = self:GetPlatoonPosition()
            reference, refName = AIUtils.AIFindDefensivePointNeedsStructureSorian(aiBrain, cons.LocationType, (cons.LocationRadius or 100),
                            cons.MarkerUnitCategory, cons.MarkerRadius, cons.MarkerUnitCount, (cons.ThreatMin or 0), (cons.ThreatMax or 1),
                            (cons.ThreatRings or 1), (cons.ThreatType or 'AntiSurface'))

            table.insert(baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation(baseTmpl, reference))

            buildFunction = AIBuildStructures.AIExecuteBuildStructure
        elseif cons.NearMarkerType and cons.NearMarkerType == 'Naval Defensive Point' then
            baseTmpl = baseTmplFile['ExpansionBaseTemplates'][factionIndex]

            relative = false
            local pos = self:GetPlatoonPosition()
            reference, refName = AIUtils.AIFindNavalDefensivePointNeedsStructure(aiBrain, cons.LocationType, (cons.LocationRadius or 100),
                            cons.MarkerUnitCategory, cons.MarkerRadius, cons.MarkerUnitCount, (cons.ThreatMin or 0), (cons.ThreatMax or 1),
                            (cons.ThreatRings or 1), (cons.ThreatType or 'AntiSurface'))

            table.insert(baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation(baseTmpl, reference))

            buildFunction = AIBuildStructures.AIExecuteBuildStructure
        elseif cons.NearMarkerType and cons.NearMarkerType == 'Expansion Area' then
            baseTmpl = baseTmplFile['ExpansionBaseTemplates'][factionIndex]

            relative = false
            local pos = self:GetPlatoonPosition()
            reference, refName = AIUtils.AIFindExpansionPointNeedsStructure(aiBrain, cons.LocationType, (cons.LocationRadius or 100),
                            cons.MarkerUnitCategory, cons.MarkerRadius, cons.MarkerUnitCount, (cons.ThreatMin or 0), (cons.ThreatMax or 1),
                            (cons.ThreatRings or 1), (cons.ThreatType or 'AntiSurface'))

            table.insert(baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation(baseTmpl, reference))

            buildFunction = AIBuildStructures.AIExecuteBuildStructure
        elseif cons.NearMarkerType then
            --WARN('*Data weird for builder named - ' .. self.BuilderName)
            if not cons.ThreatMin or not cons.ThreatMax or not cons.ThreatRings then
                cons.ThreatMin = -1000000
                cons.ThreatMax = 1000000
                cons.ThreatRings = 0
            end
            if not cons.BaseTemplate and (cons.NearMarkerType == 'Defensive Point' or cons.NearMarkerType == 'Expansion Area') then
                baseTmpl = baseTmplFile['ExpansionBaseTemplates'][factionIndex]
            end
            relative = false
            local pos = self:GetPlatoonPosition()
            reference, refName = AIUtils.AIGetClosestThreatMarkerLoc(aiBrain, cons.NearMarkerType, pos[1], pos[3],
                                                            cons.ThreatMin, cons.ThreatMax, cons.ThreatRings)
            if cons.ExpansionBase and refName then
                AIBuildStructures.AINewExpansionBase(aiBrain, refName, reference, (cons.ExpansionRadius or 100), cons.ExpansionTypes, nil, cons)
            end
            if reference and aiBrain:GetThreatAtPosition(reference, 1, true) > 0 then
                --aiBrain:ExpansionHelp(eng, reference)
            end
            table.insert(baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation(baseTmpl, reference))
            buildFunction = AIBuildStructures.AIExecuteBuildStructure
        elseif cons.AvoidCategory then
            relative = false
            local pos = aiBrain.BuilderManagers[eng.BuilderManagerData.LocationType].EngineerManager:GetLocationCoords()
            local cat = ParseEntityCategory(cons.AdjacencyCategory)
            local avoidCat = ParseEntityCategory(cons.AvoidCategory)
            local radius = (cons.AdjacencyDistance or 50)
            if not pos or not pos then
                WaitTicks(1)
                self:PlatoonDisband()
                return
            end
            reference  = AIUtils.FindUnclutteredArea(aiBrain, cat, pos, radius, cons.maxUnits, cons.maxRadius, avoidCat)
            buildFunction = AIBuildStructures.AIBuildAdjacency
            table.insert(baseTmplList, baseTmpl)
        elseif cons.AdjacencyCategory then
            relative = false
            local pos = aiBrain.BuilderManagers[eng.BuilderManagerData.LocationType].EngineerManager:GetLocationCoords()
            local cat = ParseEntityCategory(cons.AdjacencyCategory)
            local radius = (cons.AdjacencyDistance or 50)
            if not pos or not pos then
                WaitTicks(1)
                self:PlatoonDisband()
                return
            end
            reference  = AIUtils.GetOwnUnitsAroundPointSorian(aiBrain, cat, pos, radius, cons.ThreatMin,
                                                        cons.ThreatMax, cons.ThreatRings, 'Overall', cons.MinRadius or 0)
            buildFunction = AIBuildStructures.AIBuildAdjacency
            table.insert(baseTmplList, baseTmpl)
        else
            table.insert(baseTmplList, baseTmpl)
            relative = true
            reference = true
            buildFunction = AIBuildStructures.AIExecuteBuildStructure
        end
        if cons.BuildClose then
            closeToBuilder = eng
        end
        if cons.BuildStructures[1] == 'T1Resource' or cons.BuildStructures[1] == 'T2Resource' or cons.BuildStructures[1] == 'T3Resource' then
            relative = true
            closeToBuilder = eng
            local guards = eng:GetGuards()
            for k,v in guards do
                if not v.Dead and v.PlatoonHandle and aiBrain:PlatoonExists(v.PlatoonHandle) and EntityCategoryContains(categories.CONSTRUCTION, v) then
                    v.PlatoonHandle:PlatoonDisband()
                end
            end
        end

        --LOG("*AI DEBUG: Setting up Callbacks for " .. eng.Sync.id)
        self.SetupEngineerCallbacksSorian(eng)

        -------- BUILD BUILDINGS HERE --------
        for baseNum, baseListData in baseTmplList do
            for k, v in cons.BuildStructures do
                if aiBrain:PlatoonExists(self) then
                    if not eng.Dead then
                        local faction = SUtils.GetEngineerFaction(eng)
                        if aiBrain.CustomUnits[v] and aiBrain.CustomUnits[v][faction] then
                            local replacement = SUtils.GetTemplateReplacement(aiBrain, v, faction)
                            if replacement then
                                buildFunction(aiBrain, eng, v, closeToBuilder, relative, replacement, baseListData, reference, cons.NearMarkerType)
                            else
                                buildFunction(aiBrain, eng, v, closeToBuilder, relative, buildingTmpl, baseListData, reference, cons.NearMarkerType)
                            end
                        else
                            buildFunction(aiBrain, eng, v, closeToBuilder, relative, buildingTmpl, baseListData, reference, cons.NearMarkerType)
                        end
                    else
                        if aiBrain:PlatoonExists(self) then
                            WaitTicks(1)
                            self:PlatoonDisband()
                            return
                        end
                    end
                end
            end
        end

        -- wait in case we're still on a base
        if not eng.Dead then
            local count = 0
            while eng:IsUnitState('Attached') and count < 2 do
                WaitSeconds(6)
                count = count + 1
            end
        end

        if not eng:IsUnitState('Building') then
            return self.ProcessBuildCommandSorian(eng, false)
        end
    end,

    SetupEngineerCallbacksSorian = function(eng)
        if eng and not eng.Dead and not eng.BuildDoneCallbackSet and eng.PlatoonHandle and eng:GetAIBrain():PlatoonExists(eng.PlatoonHandle) then
            import('/lua/ScenarioTriggers.lua').CreateUnitBuiltTrigger(eng.PlatoonHandle.EngineerBuildDoneSorian, eng, categories.ALLUNITS)
            eng.BuildDoneCallbackSet = true
        end
        if eng and not eng.Dead and not eng.CaptureDoneCallbackSet and eng.PlatoonHandle and eng:GetAIBrain():PlatoonExists(eng.PlatoonHandle) then
            import('/lua/ScenarioTriggers.lua').CreateUnitStopCaptureTrigger(eng.PlatoonHandle.EngineerCaptureDoneSorian, eng)
            eng.CaptureDoneCallbackSet = true
        end
        if eng and not eng.Dead and not eng.ReclaimDoneCallbackSet and eng.PlatoonHandle and eng:GetAIBrain():PlatoonExists(eng.PlatoonHandle) then
            import('/lua/ScenarioTriggers.lua').CreateUnitStopReclaimTrigger(eng.PlatoonHandle.EngineerReclaimDoneSorian, eng)
            eng.ReclaimDoneCallbackSet = true
        end
        if eng and not eng.Dead and not eng.FailedToBuildCallbackSet and eng.PlatoonHandle and eng:GetAIBrain():PlatoonExists(eng.PlatoonHandle) then
            import('/lua/ScenarioTriggers.lua').CreateOnFailedToBuildTrigger(eng.PlatoonHandle.EngineerFailedToBuildSorian, eng)
            eng.FailedToBuildCallbackSet = true
        end
    end,

    RemoveEngineerCallbacksSorian = function(eng)
        if eng.BuildDoneCallbackSet then
            import('/lua/ScenarioTriggers.lua')RemoveUnitTrigger(eng, eng.PlatoonHandle.EngineerBuildDoneSorian)
            eng.BuildDoneCallbackSet = false
        end
        if eng.CaptureDoneCallbackSet then
            import('/lua/ScenarioTriggers.lua')RemoveUnitTrigger(eng, eng.PlatoonHandle.EngineerCaptureDoneSorian)
            eng.CaptureDoneCallbackSet = false
        end
        if eng.ReclaimDoneCallbackSet then
            import('/lua/ScenarioTriggers.lua')RemoveUnitTrigger(eng, eng.PlatoonHandle.EngineerReclaimDoneSorian)
            eng.ReclaimDoneCallbackSet = false
        end
        if eng.FailedToBuildCallbackSet then
            import('/lua/ScenarioTriggers.lua')RemoveUnitTrigger(eng, eng.PlatoonHandle.EngineerFailedToBuildSorian)
            eng.FailedToBuildCallbackSet = false
        end
    end,

    -- Callback functions for EngineerBuildAI
    EngineerBuildDoneSorian = function(unit, params)
        if not unit.PlatoonHandle then return end
        if not unit.PlatoonHandle.PlanName == 'EngineerBuildAISorian' then return end
        --LOG("*AI DEBUG: Build done " .. unit.Sync.id)
        if not unit.ProcessBuild then
            unit.ProcessBuild = unit:ForkThread(unit.PlatoonHandle.ProcessBuildCommandSorian, true)
            unit.ProcessBuildDone = true
        end
    end,
    EngineerCaptureDoneSorian = function(unit, params)
        if not unit.PlatoonHandle then return end
        if not unit.PlatoonHandle.PlanName == 'EngineerBuildAISorian' then return end
        --LOG("*AI DEBUG: Capture done" .. unit.Sync.id)
        if not unit.ProcessBuild then
            unit.ProcessBuild = unit:ForkThread(unit.PlatoonHandle.ProcessBuildCommandSorian, false)
        end
    end,
    EngineerReclaimDoneSorian = function(unit, params)
        if not unit.PlatoonHandle then return end
        if not unit.PlatoonHandle.PlanName == 'EngineerBuildAISorian' then return end
        --LOG("*AI DEBUG: Reclaim done" .. unit.Sync.id)
        if not unit.ProcessBuild then
            unit.ProcessBuild = unit:ForkThread(unit.PlatoonHandle.ProcessBuildCommandSorian, false)
        end
    end,
    EngineerFailedToBuildSorian = function(unit, params)
        if not unit.PlatoonHandle then return end
        if not unit.PlatoonHandle.PlanName == 'EngineerBuildAISorian' then return end
        if unit.ProcessBuildDone and unit.ProcessBuild then
            KillThread(unit.ProcessBuild)
            unit.ProcessBuild = nil
        end
        if not unit.ProcessBuild then
            unit.ProcessBuild = unit:ForkThread(unit.PlatoonHandle.ProcessBuildCommandSorian, false)
        end
    end,

    -------------------------------------------------------
    --   Function: WatchForNotBuildingSorian
    --   Args:
    --       eng - the engineer that's gone through EngineerBuildAI
    --   Description:
    --       After we try to build something, watch the engineer to
    --       make sure that the build goes through.  If not,
    --       try the next thing in the queue
    --   Returns:
    --       nil
    -------------------------------------------------------
    WatchForNotBuildingSorian = function(eng)
        WaitTicks(5)
        local aiBrain = eng:GetAIBrain()
        local engLastPos = false
        local stuckCount = 0
        while not eng.Dead and (eng.GoingHome or eng.Upgrading or eng.Fighting or eng:IsUnitState("Building") or
                  eng:IsUnitState("Attacking") or eng:IsUnitState("Repairing") or eng:IsUnitState("WaitingForTransport") or
                  eng:IsUnitState("Reclaiming") or eng:IsUnitState("Capturing") or eng:IsUnitState("Moving") or eng:IsUnitState("Enhancing") or eng:IsUnitState("Upgrading") or eng.ProcessBuild != nil
                  or eng.UnitBeingBuiltBehavior) do

            WaitSeconds(3)
            local engPos = eng:GetPosition()
            if not eng.Dead and engLastPos and eng:IsUnitState("Building") and not eng:IsUnitState("Capturing") and not eng:IsUnitState("Reclaiming")
            and not eng:IsUnitState("Repairing") and eng:GetWorkProgress() == 0 and VDist2Sq(engLastPos[1], engLastPos[3], engPos[1], engPos[3]) < 1 then
                if stuckCount > 10 then
                    stuckCount = 0
                    eng.NotBuildingThread = nil
                    eng.ProcessBuild = eng:ForkThread(eng.PlatoonHandle.ProcessBuildCommandSorian, true)
                    return
                else
                    stuckCount = stuckCount + 1
                end
            else
                stuckCount = 0
            end
            engLastPos = engPos
            --if eng.CDRHome then eng:PrintCommandQueue() end
        end
        eng.NotBuildingThread = nil
        if not eng.Dead and eng:IsIdleState() and table.getn(eng.EngineerBuildQueue) != 0 and eng.PlatoonHandle then
            eng.PlatoonHandle.SetupEngineerCallbacksSorian(eng)
            if not eng.ProcessBuild then
                eng.ProcessBuild = eng:ForkThread(eng.PlatoonHandle.ProcessBuildCommandSorian, true)
            end
        end
    end,

    -------------------------------------------------------
    --   Function: ProcessBuildCommandSorian
    --   Args:
    --       eng - the engineer that's gone through EngineerBuildAI
    --   Description:
    --       Run after every build order is complete/fails.  Sets up the next
    --       build order in queue, and if the engineer has nothing left to do
    --       will return the engineer back to the army pool by disbanding the
    --       the platoon.  Support function for EngineerBuildAI
    --   Returns:
    --       nil (tail calls into a behavior function)
    -------------------------------------------------------
    ProcessBuildCommandSorian = function(eng, removeLastBuild)
        if not eng or eng.Dead or not eng.PlatoonHandle or eng:IsUnitState("Enhancing") or eng:IsUnitState("Upgrading") or eng.Upgrading or eng.GoingHome or eng.Fighting or eng.UnitBeingBuiltBehavior then
            if eng then eng.ProcessBuild = nil end
            return
        end
        local aiBrain = eng.PlatoonHandle:GetBrain()

        if not aiBrain or eng.Dead or not eng.EngineerBuildQueue or table.getn(eng.EngineerBuildQueue) == 0 then
            if aiBrain:PlatoonExists(eng.PlatoonHandle) then
                --LOG("*AI DEBUG: Disbanding Engineer Platoon in ProcessBuildCommand " .. eng.Sync.id)
                --if EntityCategoryContains(categories.COMMAND, eng) then
                --  LOG("*AI DEBUG: Commander Platoon Disbanded in ProcessBuildCommand")
                --end
                eng.PlatoonHandle:PlatoonDisband()
            end
            if eng then eng.ProcessBuild = nil end
            return
        end

        -- it wasn't a failed build, so we just finished something
        if removeLastBuild then
            table.remove(eng.EngineerBuildQueue, 1)
        end

        function BuildToNormalLocation(location)
            return {location[1], 0, location[2]}
        end

        function NormalToBuildLocation(location)
            return {location[1], location[3], 0}
        end

        eng.ProcessBuildDone = false
        IssueClearCommands({eng})
        local commandDone = false
        while not eng.Dead and not commandDone and table.getn(eng.EngineerBuildQueue) > 0 do
            local whatToBuild = eng.EngineerBuildQueue[1][1]
            local buildLocation = BuildToNormalLocation(eng.EngineerBuildQueue[1][2])
            local buildRelative = eng.EngineerBuildQueue[1][3]
            local threadStarted = false
            -- see if we can move there first
            if AIUtils.EngineerMoveWithSafePathSorian(aiBrain, eng, buildLocation) then
                if not eng or eng.Dead or not eng.PlatoonHandle or not aiBrain:PlatoonExists(eng.PlatoonHandle) then
                    if eng then eng.ProcessBuild = nil end
                    return
                end
                -- check to see if we need to reclaim or capture...
                if not AIUtils.EngineerTryReclaimCaptureAreaSorian(aiBrain, eng, buildLocation) then
                    -- check to see if we can repair
                    if not AIUtils.EngineerTryRepairSorian(aiBrain, eng, whatToBuild, buildLocation) then
                        -- otherwise, go ahead and build the next structure there
                        aiBrain:BuildStructure(eng, whatToBuild, NormalToBuildLocation(buildLocation), buildRelative)
                        if not eng.NotBuildingThread then
                            threadStarted = true
                            eng.NotBuildingThread = eng:ForkThread(eng.PlatoonHandle.WatchForNotBuildingSorian)
                        end
                    end
                end
                if not threadStarted and not eng.NotBuildingThread then
                    eng.NotBuildingThread = eng:ForkThread(eng.PlatoonHandle.WatchForNotBuildingSorian)
                end
                commandDone = true
            else
                -- we can't move there, so remove it from our build queue
                table.remove(eng.EngineerBuildQueue, 1)
            end
        end

        -- final check for if we should disband
        if not eng or eng.Dead or table.getn(eng.EngineerBuildQueue) == 0 then
            if eng.PlatoonHandle and aiBrain:PlatoonExists(eng.PlatoonHandle) then
                --LOG("*AI DEBUG: Disbanding Engineer Platoon in ProcessBuildCommand " .. eng.Sync.id)
                --if EntityCategoryContains(categories.COMMAND, eng) then
                --  LOG("*AI DEBUG: Commander Platoon Disbanded in ProcessBuildCommand")
                --end
                eng.PlatoonHandle:PlatoonDisband()
            end
            if eng then eng.ProcessBuild = nil end
            return
        end
        if eng then eng.ProcessBuild = nil end
    end,

    MergeWithNearbyPlatoonsSorian = function(self, planName, radius, fullrestart)
        -- check to see we're not near an ally base

        local aiBrain = self:GetBrain()
        if not aiBrain then
            return
        end

        if self.UsingTransport then
            return
        end

        local platPos = self:GetPlatoonPosition()
        if not platPos then
            return
        end

        local radiusSq = radius*radius
        -- if we're too close to a base, forget it
        if aiBrain.BuilderManagers then
            for baseName, base in aiBrain.BuilderManagers do
                local baseRadius = base.FactoryManager:GetLocationRadius()
                if VDist2Sq(platPos[1], platPos[3], base.Position[1], base.Position[3]) <= (baseRadius * baseRadius) + (3 * radiusSq) then
                    return
                end
            end
        end

        AlliedPlatoons = aiBrain:GetPlatoonsList()
        local bMergedPlatoons = false
        for _,aPlat in AlliedPlatoons do
            if aPlat:GetPlan() != planName then
                continue
            end
            if aPlat == self then
                continue
            end
            if aPlat.UsingTransport then
                continue
            end

            local allyPlatPos = aPlat:GetPlatoonPosition()
            if not allyPlatPos or not aiBrain:PlatoonExists(aPlat) then
                continue
            end

            AIAttackUtils.GetMostRestrictiveLayer(self)
            AIAttackUtils.GetMostRestrictiveLayer(aPlat)

            -- make sure we're the same movement layer type to avoid hamstringing air of amphibious
            if self.MovementLayer != aPlat.MovementLayer then
                continue
            end

            if VDist2Sq(platPos[1], platPos[3], allyPlatPos[1], allyPlatPos[3]) <= radiusSq then
                local units = aPlat:GetPlatoonUnits()
                local validUnits = {}
                local bValidUnits = false
                for _,u in units do
                    if not u.Dead and not u:IsUnitState('Attached') then
                        table.insert(validUnits, u)
                        bValidUnits = true
                    end
                end
                if not bValidUnits then
                    continue
                end
                --LOG("*AI DEBUG: Merging platoons " .. self.BuilderName .. ": (" .. platPos[1] .. ", " .. platPos[3] .. ") and " .. aPlat.BuilderName .. ": (" .. allyPlatPos[1] .. ", " .. allyPlatPos[3] .. ")")
                aiBrain:AssignUnitsToPlatoon(self, validUnits, 'Attack', 'GrowthFormation')
                bMergedPlatoons = true
            end
        end
        if bMergedPlatoons then
            if fullrestart then
                self:Stop()
                self:SetAIPlan(planName)
            else
                self:StopAttack()
            end
        end
    end,

    --Modified version of AvoidsBases() that checks for and avoids ally bases
    AvoidsBasesSorian = function(self, markerPos, avoidBasesDefault, baseRadius)
        if not avoidBasesDefault then
            return true
        end

        local aiBrain = self:GetBrain()

        for baseName, base in aiBrain.BuilderManagers do
            local avoidDist = VDist2Sq(base.Position[1], base.Position[3], markerPos[1], markerPos[3])
            if avoidDist < baseRadius * baseRadius then
                return false
            end
        end
        for k,v in ArmyBrains do
            if not v:IsDefeated() and not ArmyIsCivilian(v:GetArmyIndex()) and IsAlly(v:GetArmyIndex(), aiBrain:GetArmyIndex()) then
                local startX, startZ = v:GetArmyStartPos()
                if VDist2Sq(markerPos[1], markerPos[3], startX, startZ) < baseRadius * baseRadius then
                    return false
                end
            end
        end
        return true
    end,

    NameUnitsSorian = function(self)
        local units = self:GetPlatoonUnits()
        local AINames = import('/lua/AI/sorianlang.lua').AINames
        if units and table.getn(units) > 0 then
            for k, v in units do
                local ID = v:GetUnitId()
                if AINames[ID] then
                    local num = Random(1, table.getn(AINames[ID]))
                    v:SetCustomName(AINames[ID][num])
                end
            end
        end
    end,
}
