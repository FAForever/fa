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
local AIUtils = import("/lua/ai/aiutilities.lua")
local TransportUtils = import("/lua/ai/transportutilities.lua")
local Utilities = import("/lua/utilities.lua")
local AIBuildStructures = import("/lua/ai/aibuildstructures.lua")
local UpgradeTemplates = import("/lua/upgradetemplates.lua")
local Behaviors = import("/lua/ai/aibehaviors.lua")
local AIAttackUtils = import("/lua/ai/aiattackutilities.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local SPAI = import("/lua/scenarioplatoonai.lua")

--for sorian AI
local SUtils = import("/lua/ai/sorianutilities.lua")

---@alias PlatoonSquads 'Attack' | 'Artillery' | 'Guard' | 'Scout' | 'Support' | 'Unassigned'

---@class Platoon : moho.platoon_methods
---@field PlatoonData table
Platoon = Class(moho.platoon_methods) {
    NeedCoolDown = false,
    LastAttackDestination = {},

    ---@param self Platoon
    ---@param plan table
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

    ---@param self Platoon
    ---@param dataTable table
    SetPlatoonData = function(self, dataTable)
        self.PlatoonData = table.deepcopy(dataTable)
    end,

    ---@param self Platoon
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

    ---@param self Platoon
    ---@return boolean
    IsPartOfAttackForce = function(self)
        return self.PartOfAttackForce
    end,

    ---@param self Platoon
    ---@param fn function
    ---@param ... any
    ---@return thread
    ForkAIThread = function(self, fn, ...)
        if fn then
            self.AIThread = ForkThread(fn, self, unpack(arg))
            self.Trash:Add(self.AIThread)
            return self.AIThread
        else
            return nil
        end
    end,

    ---@param self Platoon
    StopAI = function(self)
        if self.AIThread != nil then
            self.AIThread:Destroy()
        end
    end,

    ---@param self Platoon
    ---@param callbackFunction function
    AddDestroyCallback = function(self, callbackFunction)
        if not callbackFunction then
            error('*ERROR: Tried to add an OnDestroy on a platoon callback with a nil function')
            return
        end
        table.insert(self.EventCallbacks.OnDestroyed, callbackFunction)
    end,

    ---@param self Platoon
    DoDestroyCallbacks = function(self)
        if self.EventCallbacks.OnDestroyed then
            for k, cb in self.EventCallbacks.OnDestroyed do
                if cb then
                    cb(self:GetBrain(), self)
                end
            end
        end
    end,

    ---@param self Platoon
    ---@param fn function
    RemoveDestroyCallback = function(self, fn)
        for k,v in self.EventCallbacks.OnDestroyed do
            if v == fn then
                self.EventCallbacks.OnDestroyed[k] = nil
            end
        end
    end,

    ---@param self Platoon
    OnDestroy = function(self)

        --DUNCAN - Added
        self:StopAI()

        self:DoDestroyCallbacks()
        if self.Trash then
            self.Trash:Destroy()
        end
    end,

    ---@param self Platoon
    ---@param fn function
    ---@param ... any
    ---@return thread
    ForkThread = function(self, fn, ...)
        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            self.Trash:Add(thread)
            return thread
        else
            return nil
        end
    end,

    ---@param self Platoon
    ---@param plan table
    SetAIPlan = function(self, plan)
        if not self[plan] then return end
        if self.AIThread then
            self.AIThread:Destroy()
        end
        self.PlanName = plan
        self:ForkAIThread(self[plan])
    end,

    ---@param self Platoon
    ---@return string|nil
    GetPlan = function(self)
        if self.PlanName then
            return self.PlanName
        end
    end,

    ---@param self Platoon
    ---@param rings number
    ---@return number
    GetThreatLevel = function(self, rings)
        local brain = self:GetBrain()
        return brain:GetThreatAtPosition(self:GetPlatoonPosition(), rings, true)
    end,

    ---@param self Platoon
    ---@param commands PlatoonCommand[]
    ---@return boolean 
    CheckCommandsCompleted = function(self, commands)
        for k, v in commands do
            if self:IsCommandsActive(v) then
                return false
            end
        end
        return true
    end,

    ---@param self Platoon
    TurnOffPoolAI = function(self)
        if self.PoolAIOn then
            self.AIThread:Destroy()
            self.PoolAIOn = false
            self.AIThread = nil
        end
    end,

    ---@param self Platoon
    TurnOnPoolAI = function(self)
        if not self.PoolAIOn and not self.AIThread then
            self.AIThread = self:ForkAIThread(self.PoolAI)
        end
    end,

    ---@param self Platoon
    PoolAI = function(self)
    end,

    ---@param self Platoon
    OnUnitsAddedToPlatoon = function(self)
        for k,v in self:GetPlatoonUnits() do
            if not v.Dead then
                v.PlatoonHandle = self
            end
        end
    end,

    ---@param self Platoon
    PlatoonDisband = function(self)
        if self.ArmyPool then
            --WARN('AI WARNING: Platoon trying to disband ArmyPool')
            --LOG(reprsl(debug.traceback()))
            return
        end
        local aiBrain = self:GetBrain()
        if self.BuilderHandle then
            self.BuilderHandle:RemoveHandle(self)
        end
        for k,v in self:GetPlatoonUnits() do
            v.PlatoonHandle = nil
            v.AssistSet = nil
            v.AssistPlatoon = nil
            v.UnitBeingAssist = nil
            v.ReclaimInProgress = nil
            v.CaptureInProgress = nil
            if v:IsPaused() then
                v:SetPaused( false )
            end
            if not v.Dead and v.BuilderManagerData then
                if self.CreationTime == GetGameTimeSeconds() and v.BuilderManagerData.EngineerManager then
                    if self.BuilderName then
                        --LOG('*PlatoonDisband: ERROR - Platoon disbanded same tick as created - ' .. self.BuilderName .. ' - Army: ' .. aiBrain:GetArmyIndex() .. ' - Location: ' .. repr(v.BuilderManagerData.LocationType))
                        v.BuilderManagerData.EngineerManager:AssignTimeout(v, self.BuilderName)
                    else
                        --LOG('*PlatoonDisband: ERROR - Platoon disbanded same tick as created - Army: ' .. aiBrain:GetArmyIndex() .. ' - Location: ' .. repr(v.BuilderManagerData.LocationType))
                    end
                    v.BuilderManagerData.EngineerManager:DelayAssign(v)
                elseif v.BuilderManagerData.EngineerManager then
                    v.BuilderManagerData.EngineerManager:TaskFinished(v)
                end
            end
            if not v.Dead then
                IssueStop({v})
                IssueToUnitClearCommands(v)
            end
        end
        if self.AIThread then
            self.AIThread:Destroy()
        end
        aiBrain:DisbandPlatoon(self)
    end,

    ---@param self Platoon
    ---@param threatType BrainThreatType
    ---@param unitCategory EntityCategory
    ---@param position Vector
    ---@param radius number
    ---@return number|nil
    GetPlatoonThreat = function(self, threatType, unitCategory, position, radius)
        local threat = 0
        if position then
            threat = self:CalculatePlatoonThreatAroundPosition(threatType, unitCategory, position, radius)
        else
            threat = self:CalculatePlatoonThreat(threatType, unitCategory)
        end
        return threat
    end,

    ---@param self Platoon
    ---@param category EntityCategory
    ---@param point Vector
    ---@param radius number
    ---@return Unit[]
    GetPlatoonUnitsAroundPoint = function(self, category, point, radius)
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

    ---@param self Platoon
    ---@param category EntityCategory
    ---@param position Vector
    ---@param radius number
    ---@return nil 
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
    ---@param self Platoon
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

    ---@param self Platoon
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
            IssueToUnitClearCommands(unit)
            for k,v in data.Enhancement do
                if not unit:HasEnhancement(v) then
                    local order = {
                        TaskName = "EnhanceTask",
                        Enhancement = v
                    }
                    --LOG('*AI DEBUG: '..aiBrain.Nickname..' EnhanceAI Added Enhancement: '..v)
                    IssueScript({unit}, order)
                    lastEnhancement = v
                end
            end
            WaitSeconds(data.TimeBetweenEnhancements or 1)
            repeat
                WaitSeconds(5)
                --LOG('*AI DEBUG: '..aiBrain.Nickname..' Com still upgrading ')
            until unit.Dead or unit:HasEnhancement(lastEnhancement)
            --LOG('*AI DEBUG: '..aiBrain.Nickname..' Com finished upgrading ')
        end
        self:PlatoonDisband()
    end,

    ---@param self Platoon
    HuntAI = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local armyIndex = aiBrain:GetArmyIndex()
        local target
        local blip
        while aiBrain:PlatoonExists(self) do
            target = self:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS - categories.WALL)
            if target then
                blip = target:GetBlip(armyIndex)
                self:Stop()
                self:AggressiveMoveToLocation(table.copy(target:GetPosition()))
                --DUNCAN - added to try and stop AI getting stuck.
                local position = AIUtils.RandomLocation(target:GetPosition()[1],target:GetPosition()[3])
                self:MoveToLocation(position, false)
            end
            WaitSeconds(17)
        end
    end,

    ---@param self Platoon
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

    ---@param self Platoon
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

                nukePos = import("/lua/ai/aibehaviors.lua").GetHighestThreatClusterLocation(aiBrain, unit)
                if nukePos then
                   IssueNuke({unit}, nukePos)
                   WaitSeconds(12)
                   IssueToUnitClearCommands(unit)
                end
                WaitSeconds(1)
            end
        end
        self:PlatoonDisband()
    end,

    ---@param self Platoon
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

    ---@param self Platoon
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

    ---## Function: ExperimentalAIHub
    --- If set as a platoon's AI function, will select an appropriate behavior based on the unit type.
    ---@param self Platoon
    ---@return nil
    ExperimentalAIHub = function(self)

        local behaviors = import("/lua/ai/aibehaviors.lua")

        local experimental = self:GetPlatoonUnits()[1]
        if not experimental then
            return
        end
        local ID = experimental.UnitId
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

    ---## Function: GuardEngineer
    --- Provides logic for platoons to guard expansion areas and engineers.
    ---@param self Platoon
    ---@param nextAIFunc? function
    ---@param forceGuardBase? boolean
    ---@return nil
    GuardEngineer = function(self, nextAIFunc, forceGuardBase)
        local aiBrain = self:GetBrain()

        if not aiBrain:PlatoonExists(self) or not self:GetPlatoonPosition() then
            return
        end
        local NavUtils = import("/lua/sim/navutils.lua")
        local renderThread = false
        self.PlatoonSurfaceThreat = self:GetPlatoonThreat('Surface', categories.ALLUNITS)
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
                local path, reason = NavUtils.PathToWithThreatThreshold(self.MovementLayer, self:GetPlatoonPosition(), bestBase.Position, aiBrain, NavUtils.ThreatFunctions.AntiSurface, self.PlatoonSurfaceThreat * 10, aiBrain.IMAPConfig.Rings)

                IssueClearCommands(self:GetPlatoonUnits())

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
                    or (not unitToGuard.Dead and unitToGuard.Layer == 'Seabed' and self.MovementLayer == 'Land') then
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

    ---@param self Platoon
    ---@return AIBrain|nil
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
                or (not unitToGuard.Dead and unitToGuard.Layer == 'Seabed' and self.MovementLayer == 'Land') then
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

    ---## Function: GuardMarker
    --- Will guard the location of a marker
    ---@param self Platoon
    ---@return nil
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




        
        local markerLocations = import("/lua/sim/markerutilities.lua").GetMarkersByType(markerType)
        local NavUtils = import("/lua/sim/navutils.lua")
        AIAttackUtils.GetMostRestrictiveLayer(self)
        self:SetPlatoonFormationOverride(PlatoonFormation)
        self.PlatoonSurfaceThreat = self:GetPlatoonThreat('Surface', categories.ALLUNITS)

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
                if (self.MovementLayer == 'Land' and marker.NavLayer ~= 'Amphibious') or (self.MovementLayer == 'Water' and marker.NavLayer == 'Amphibious') then
                    if table.getn(markerLocations) <= 2 then
                        self.LastMarker[1] = nil
                        self.LastMarker[2] = nil
                    end
                    if self:AvoidsBases(marker.position, bAvoidBases, avoidBasesRadius) then
                        if self.LastMarker[1] and marker.position[1] == self.LastMarker[1][1] and marker.position[3] == self.LastMarker[1][3] then
                            continue
                        end
                        if self.LastMarker[2] and marker.position[1] == self.LastMarker[2][1] and marker.position[3] == self.LastMarker[2][3] then
                            continue
                        end
                        bestMarker = marker
                        break
                    end
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
                if (self.MovementLayer == 'Land' and marker.NavLayer ~= 'Amphibious') or (self.MovementLayer == 'Water' and marker.NavLayer == 'Amphibious') then
                    local markerThreat
                    if bSelfThreat then
                        markerThreat = aiBrain:GetThreatAtPosition(marker.position, 0, true, threatType, aiBrain:GetArmyIndex())
                    else
                        markerThreat = aiBrain:GetThreatAtPosition(marker.position, 0, true, threatType)
                    end
                    local distSq = VDist2Sq(marker.position[1], marker.position[3], platLoc[1], platLoc[3])

                    if markerThreat >= minThreatThreshold and markerThreat <= maxThreatThreshold then
                        if self:AvoidsBases(marker.position, bAvoidBases, avoidBasesRadius) then
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
            end

        else
            -- if we didn't want random or threat, assume closest (but avoid ping-ponging)
            local bestDistSq = 99999999
            if table.getn(markerLocations) <= 2 then
                self.LastMarker[1] = nil
                self.LastMarker[2] = nil
            end
            for _,marker in markerLocations do
                if (self.MovementLayer == 'Land' and marker.NavLayer ~= 'Amphibious') or (self.MovementLayer == 'Water' and marker.NavLayer == 'Amphibious') then
                    local distSq = VDist2Sq(marker.position[1], marker.position[3], platLoc[1], platLoc[3])
                    if self:AvoidsBases(marker.position, bAvoidBases, avoidBasesRadius) and distSq > (avoidClosestRadius * avoidClosestRadius) then
                        if distSq < bestDistSq then
                            if self.LastMarker[1] and marker.position[1] == self.LastMarker[1][1] and marker.position[3] == self.LastMarker[1][3] then
                                continue
                            end
                            if self.LastMarker[2] and marker.position[1] == self.LastMarker[2][1] and marker.position[3] == self.LastMarker[2][3] then
                                continue
                            end
                            bestDistSq = distSq
                            bestMarker = marker
                        end
                    end
                end
            end
        end


        -- did we find a threat?
        local usedTransports = false
        if bestMarker then
            self.LastMarker[2] = self.LastMarker[1]
            self.LastMarker[1] = bestMarker.position
            --LOG("GuardMarker: Attacking " .. bestMarker.Name)
            local path, reason = NavUtils.PathToWithThreatThreshold(self.MovementLayer, self:GetPlatoonPosition(), bestMarker.position, aiBrain, NavUtils.ThreatFunctions.AntiSurface, self.PlatoonSurfaceThreat * 10, aiBrain.IMAPConfig.Rings)
            local success, bestGoalPos = AIAttackUtils.CheckPlatoonPathingEx(self, bestMarker.position)
            IssueClearCommands(self:GetPlatoonUnits())
            if path then
                local position = self:GetPlatoonPosition()
                if not success or VDist2(position[1], position[3], bestMarker.position[1], bestMarker.position[3]) > 512 then
                    usedTransports = TransportUtils.SendPlatoonWithTransports(aiBrain, self, bestMarker.position, 2, true)
                elseif VDist2(position[1], position[3], bestMarker.position[1], bestMarker.position[3]) > 256 then
                    usedTransports = TransportUtils.SendPlatoonWithTransports(aiBrain, self, bestMarker.position, 1, false)
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
            elseif (not path and reason == 'NoPath') and self.MovementLayer ~= 'Water' then
                --LOG('Guardmarker requesting transports')
                local foundTransport = TransportUtils.SendPlatoonWithTransports(aiBrain, self, bestMarker.position, 3, true)
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
                IssueGuard(self:GetPlatoonUnits(), bestMarker.position)
                -- guard forever
                if guardTimer <= 0 then return end
            else
                -- otherwise, we're moving to the location
                self:AggressiveMoveToLocation(bestMarker.position)
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
            until VDist2Sq(platLoc[1], platLoc[3], bestMarker.position[1], bestMarker.position[3]) < 64 or not aiBrain:PlatoonExists(self)

            -- if we're supposed to guard for some time
            if moveNext == 'None' then
                -- this won't be 0... see above
                WaitSeconds(guardTimer)
                return self:ReturnToBaseAI()
            end

            if moveNext == 'Guard Base' then
                return self:GuardBase()
            end

            -- we're there... wait here until we're done
            local numGround = aiBrain:GetNumUnitsAroundPoint((categories.LAND + categories.NAVAL + categories.STRUCTURE), bestMarker.position, 15, 'Enemy')
            while numGround > 0 and aiBrain:PlatoonExists(self) do
                WaitSeconds(Random(5,10))
                numGround = aiBrain:GetNumUnitsAroundPoint((categories.LAND + categories.NAVAL + categories.STRUCTURE), bestMarker.position, 15, 'Enemy')
            end

            if not aiBrain:PlatoonExists(self) then
                return
            end

            -- set our MoveFirst to our MoveNext
            self.PlatoonData.MoveFirst = moveNext
            return self:GuardMarker()
        else
            -- no marker found, return to base!
            WaitTicks(20)
            return self:ReturnToBaseAI()
        end
    end,

    ---@param self Platoon
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
            WaitSeconds(5)
        end
    end,

    ---## Function: LandScoutingAI
    --- Handles sending land scouts to important locations.
    ---@param self Platoon
    ---@return nil
    LandScoutingAI = function(self)
        local NavUtils = import("/lua/sim/navutils.lua")
        AIAttackUtils.GetMostRestrictiveLayer(self)

        local aiBrain = self:GetBrain()
        local scout = self:GetPlatoonUnits()[1]

        -- build scoutlocations if not already done.
        if not aiBrain.InterestList then
            aiBrain:BuildScoutLocations()
        end

        --If we have cloaking (are cybran), then turn on our cloaking
        --DUNCAN - Fixed to use same bits
        if scout:TestToggleCaps('RULEUTC_CloakToggle') then
            scout:SetScriptBit('RULEUTC_CloakToggle', false)
        end

        while not scout.Dead do
            --Head towards the the area that has not had a scout sent to it in a while
            local targetData = false

            --For every scouts we send to all opponents, send one to scout a low pri area.
            if aiBrain.IntelData.HiPriScouts < aiBrain.NumOpponents and not table.empty(aiBrain.InterestList.HighPriority) then
                targetData = aiBrain.InterestList.HighPriority[1]
                aiBrain.IntelData.HiPriScouts = aiBrain.IntelData.HiPriScouts + 1
                targetData.LastScouted = GetGameTimeSeconds()

                aiBrain:SortScoutingAreas(aiBrain.InterestList.HighPriority)

            elseif not table.empty(aiBrain.InterestList.LowPriority) then
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
                local path, reason = NavUtils.PathToWithThreatThreshold(self.MovementLayer, scout:GetPosition(), targetData.Position, aiBrain, NavUtils.ThreatFunctions.AntiSurface, 400, aiBrain.IMAPConfig.Rings)

                IssueClearCommands(self:GetPlatoonUnits())

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

    ---## Function: DoAirScoutVecs
    --- Creates an attack vector that will cause the scout to fly by the target at a distance of its visual range.
    --- Whether to fly by on the left or right is decided randomly. This whole affair should hopefully extend the
    --- life of the air scout.
    ---@param self Platoon
    ---@param scout Unit
    ---@param targetArea Vector
    ---@return Vector
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

    ---## Function: AirScoutingAI
    --- Handles sending air scouts to important locations.
    ---@param self Platoon
    AirScoutingAI = function(self)

        local scout = self:GetPlatoonUnits()[1]
        if not scout then
            return
        end

        local aiBrain = self:GetBrain()

        -- build scoutlocations if not already done.
        if not aiBrain.InterestList then
            aiBrain:BuildScoutLocations()
        end

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
            elseif not table.empty(unknownThreats) and unknownThreats[1][3] > 25 then
                aiBrain:AddScoutArea({unknownThreats[1][1], 0, unknownThreats[1][2]})

            --3) Scout high priority locations
            elseif aiBrain.IntelData.AirHiPriScouts < aiBrain.NumOpponents and aiBrain.IntelData.AirLowPriScouts < 1
            and not table.empty(aiBrain.InterestList.HighPriority) then
                aiBrain.IntelData.AirHiPriScouts = aiBrain.IntelData.AirHiPriScouts + 1

                highPri = true

                targetData = aiBrain.InterestList.HighPriority[1]
                targetData.LastScouted = GetGameTimeSeconds()
                targetArea = targetData.Position

                aiBrain:SortScoutingAreas(aiBrain.InterestList.HighPriority)

            --4) Every time we scout NumOpponents number of high priority locations, scout a low priority location
            elseif aiBrain.IntelData.AirLowPriScouts < 1 and not table.empty(aiBrain.InterestList.LowPriority) then
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

    ---## Function: ScoutingAI
    --- Switches to AirScoutingAI or LandScoutingAI depending on the unit's movement capabilities.
    ---@param self Platoon
    ---@return nil
    ScoutingAI = function(self)
        AIAttackUtils.GetMostRestrictiveLayer(self)

        if self.MovementLayer == 'Air' then
            return self:AirScoutingAI()
        else
            return self:LandScoutingAI()
        end
    end,

    ---@param self Platoon
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

    ---@param self Platoon
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

    ---@param self Platoon
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

    ---@param self Platoon
    PoolDistressAI = function(self)
        local aiBrain = self:GetBrain()
        local distressRange = aiBrain.BaseMonitor.PoolDistressRange
        local reactionTime = aiBrain.BaseMonitor.PoolReactionTime
        while aiBrain:PlatoonExists(self) do
            local platoonUnits = self:GetPlatoonUnits()
            if aiBrain.HasPlatoonList then
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

    ---@param self Platoon
    ---@param locData table
    UnlockPBMDistressLocation = function(self, locData)
        WaitSeconds(15)
        locData.DistressCall = false
    end,

    ---@param self Platoon
    BaseManagersDistressAI = function(self)
        local aiBrain = self:GetBrain()
        while aiBrain:PlatoonExists(self) do
            local distressRange = aiBrain.BaseMonitor.PoolDistressRange
            local reactionTime = aiBrain.BaseMonitor.PoolReactionTime

            local platoonUnits = self:GetPlatoonUnits()

            for locName, locData in aiBrain.BuilderManagers do
                if not locData.DistressCall then
                    local position = locData.EngineerManager:GetLocationCoords()
                    local radius = locData.EngineerManager.Radius
                    local distressRange = locData.BaseSettings.DistressRange or aiBrain.BaseMonitor.PoolDistressRange
                    local distressLocation = aiBrain:BaseMonitorDistressLocation(position, distressRange, aiBrain.BaseMonitor.PoolDistressThreshold)

                    -- Distress !
                    if distressLocation then
                        --LOG('*AI DEBUG: ARMY '.. aiBrain:GetArmyIndex() ..': --- POOL DISTRESS RESPONSE ---')

                        -- Grab the units at the location
                        local group = self:GetPlatoonUnitsAroundPoint(categories.MOBILE, position, radius)

                        -- Move the group to the distress location and then back to the location of the base
                        IssueClearCommands(group)
                        IssueAggressiveMove(group, distressLocation)
                        IssueMove(group, position)

                        -- Set distress active for duration
                        locData.DistressCall = true
                        self:ForkThread(self.UnlockBaseManagerDistressLocation, locData)
                    end
                end
            end
            WaitSeconds(aiBrain.BaseMonitor.PoolReactionTime)
        end
    end,

    ---@param self Platoon
    ---@param locData table
    UnlockBaseManagerDistressLocation = function(self, locData)
        WaitSeconds(15)
        locData.DistressCall = false
    end,

    ---@param self Platoon
    DisbandAI = function(self)
        self:Stop()
        self:PlatoonDisband()
    end,

    ---@param self Platoon
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
                    -- Set CaptureInProgress to prevent attacking
                    target.CaptureInProgress = true
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
                    target.CaptureInProgress = nil
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

                    self:ForkThread(SPAI.LandAssaultWithTransports)
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

    ---@param self Platoon
    ReclaimStructuresAI = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local data = self.PlatoonData
        local categories = data.Reclaim
        local counter = 0
        local reclaimcat
        local reclaimables
        local unitPos
        local reclaimunit
        local distance
        local allIdle
        while aiBrain:PlatoonExists(self) do
            unitPos = self:GetPlatoonPosition()
            reclaimunit = false
            distance = false
            for num,cat in categories do
                if type(cat) == 'string' then
                    reclaimcat = ParseEntityCategory(cat)
                else
                    reclaimcat = cat
                end
                reclaimables = aiBrain:GetListOfUnits(reclaimcat, false)
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
                -- Set ReclaimInProgress to prevent repairing (see RepairAI)
                reclaimunit.ReclaimInProgress = true
                IssueReclaim(self:GetPlatoonUnits(), reclaimunit)
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
                return
            else
                counter = counter + 1
                WaitSeconds(5)
            end
        end
    end,

    ---@param self Platoon
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
                    local rpos = v:GetPosition()
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

    ---@param self Platoon
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
                    -- Set ReclaimInProgress to prevent repairing (see RepairAI)
                    target.ReclaimInProgress = true
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

    ---@param self Platoon
    RepairAI = function(self)
        local aiBrain = self:GetBrain()
        if not self.PlatoonData or not self.PlatoonData.LocationType then
            self:PlatoonDisband()
            return
        end
        local eng = self:GetPlatoonUnits()[1]
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
            if eng:IsIdleState() then break end
        until count >= 30
        self:PlatoonDisband()
    end,

    ---@param self Platoon
    ManagerEngineerFindUnfinished = function(self)
        local aiBrain = self:GetBrain()
        local eng = self:GetPlatoonUnits()[1]
        local guardedUnit
        self:EconUnfinishedBody()
        WaitTicks(10)
        -- do we assist until the building is finished ?
        if self.PlatoonData.Assist.AssistUntilFinished then
            local guardedUnit
            if eng.UnitBeingAssist then
                guardedUnit = eng.UnitBeingAssist
            else
                guardedUnit = eng:GetGuardedUnit()
            end
            -- loop as long as we are not dead and not idle
            while eng and not eng.Dead and aiBrain:PlatoonExists(self) and not eng:IsIdleState() do
                if not guardedUnit or guardedUnit.Dead or guardedUnit:BeenDestroyed() then
                    break
                end
                -- stop if our target is finished
                if guardedUnit:GetFractionComplete() == 1 and not guardedUnit:IsUnitState('Upgrading') then
                    --LOG('* ManagerEngineerAssistAI: Engineer Builder ['..self.BuilderName..'] - ['..self.PlatoonData.Assist.AssisteeType..'] - Target unit ['..guardedUnit:GetBlueprint().BlueprintId..'] ('..guardedUnit:GetBlueprint().Description..') is finished')
                    break
                end
                -- wait 1.5 seconds until we loop again
                WaitTicks(15)
            end
        else
            WaitSeconds(self.PlatoonData.Assist.Time or 60)
        end
        if not aiBrain:PlatoonExists(self) then
            return
        end
        eng.AssistPlatoon = nil
        eng.UnitBeingAssist = nil
        self:Stop()
        self:PlatoonDisband()
    end,

    ---@param self Platoon
    EconUnfinishedBody = function(self)
        local aiBrain = self:GetBrain()
        local eng = self:GetPlatoonUnits()[1]
        if not eng then
            self:PlatoonDisband()
            return
        end
        local assistData = self.PlatoonData.Assist
        local assistee = false

        eng.AssistPlatoon = self

        if not assistData.AssistLocation then
            WARN('*AI WARNING: Disbanding EconUnfinishedBody platoon that does not AssistLocation')
            self:PlatoonDisband()
            return
        end

        local beingBuilt = assistData.BeingBuiltCategories or { 'ALLUNITS' }

        -- loop through different categories we are looking for
        for _,catString in beingBuilt do

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
            eng.UnitBeingAssist = assistee.UnitBeingBuilt or assistee.UnitBeingAssist or assistee
            --LOG('* EconUnfinishedBody: Assisting now: ['..eng.UnitBeingBuilt:GetBlueprint().BlueprintId..'] ('..eng.UnitBeingBuilt:GetBlueprint().Description..')')
            IssueGuard({eng}, assistee)
        else
            self.AssistPlatoon = nil
            eng.UnitBeingAssist = nil
            -- stop the platoon from endless assisting
            self:PlatoonDisband()
        end
    end,

    ---@param self Platoon
    ManagerEngineerAssistAI = function(self)
        local aiBrain = self:GetBrain()
        local eng = self:GetPlatoonUnits()[1]
        self:EconAssistBody()
        WaitTicks(10)
        -- do we assist until the building is finished ?
        if self.PlatoonData.Assist.AssistUntilFinished then
            local guardedUnit
            if eng.UnitBeingAssist then
                guardedUnit = eng.UnitBeingAssist
            else
                guardedUnit = eng:GetGuardedUnit()
            end
            -- loop as long as we are not dead and not idle
            while eng and not eng.Dead and aiBrain:PlatoonExists(self) and not eng:IsIdleState() do
                if not guardedUnit or guardedUnit.Dead or guardedUnit:BeenDestroyed() then
                    break
                end
                -- stop if our target is finished
                if guardedUnit:GetFractionComplete() == 1 and not guardedUnit:IsUnitState('Upgrading') then
                    --LOG('* ManagerEngineerAssistAI: Engineer Builder ['..self.BuilderName..'] - ['..self.PlatoonData.Assist.AssisteeType..'] - Target unit ['..guardedUnit:GetBlueprint().BlueprintId..'] ('..guardedUnit:GetBlueprint().Description..') is finished')
                    break
                end
                -- wait 1.5 seconds until we loop again
                WaitTicks(15)
            end
        else
            WaitSeconds(self.PlatoonData.Assist.Time or 60)
        end
        if not aiBrain:PlatoonExists(self) then
            return
        end
        self.AssistPlatoon = nil
        eng.UnitBeingAssist = nil
        self:Stop()
        self:PlatoonDisband()
    end,

    ---@param self Platoon
    EconAssistBody = function(self)
        local aiBrain = self:GetBrain()
        local eng = self:GetPlatoonUnits()[1]
        if not eng or eng:IsUnitState('Building') or eng:IsUnitState('Upgrading') or eng:IsUnitState("Enhancing") then
           return
        end
        local assistData = self.PlatoonData.Assist
        if not assistData.AssistLocation then
            WARN('*AI WARNING: Builder '..repr(self.BuilderName)..' is missing AssistLocation')
            return
        end
        if not assistData.AssisteeType then
            WARN('*AI WARNING: Builder '..repr(self.BuilderName)..' is missing AssisteeType')
            return
        end
        eng.AssistPlatoon = self
        local assistee = false
        local assistRange = assistData.AssistRange or 80
        local platoonPos = self:GetPlatoonPosition()
        local beingBuilt = assistData.BeingBuiltCategories or { 'ALLUNITS' }
        local assisteeCat = assistData.AssisteeCategory or categories.ALLUNITS
        if type(assisteeCat) == 'string' then
            assisteeCat = ParseEntityCategory(assisteeCat)
        end

        -- loop through different categories we are looking for
        for _,catString in beingBuilt do
            -- Track all valid units in the assist list so we can load balance for builders
            local category = ParseEntityCategory(catString)
            local assistList = AIUtils.GetAssistees(aiBrain, assistData.AssistLocation, assistData.AssisteeType, category, assisteeCat)
            if not table.empty(assistList) then
                -- only have one unit in the list; assist it
                local low = false
                local bestUnit = false
                for k,v in assistList do
                    --DUNCAN - check unit is inside assist range
                    local unitPos = v:GetPosition()
                    local UnitAssist = v.UnitBeingBuilt or v.UnitBeingAssist or v
                    local NumAssist = table.getn(UnitAssist:GetGuards())
                    local dist = VDist2(platoonPos[1], platoonPos[3], unitPos[1], unitPos[3])
                    -- Find the closest unit to assist
                    if assistData.AssistClosestUnit then
                        if (not low or dist < low) and NumAssist < 20 and dist < assistRange then
                            low = dist
                            bestUnit = v
                        end
                    -- Find the unit with the least number of assisters; assist it
                    else
                        if (not low or NumAssist < low) and NumAssist < 20 and dist < assistRange then
                            low = NumAssist
                            bestUnit = v
                        end
                    end
                end
                assistee = bestUnit
                break
            end
        end
        -- assist unit
        if assistee  then
            self:Stop()
            eng.AssistSet = true
            eng.UnitBeingAssist = assistee.UnitBeingBuilt or assistee.UnitBeingAssist or assistee
            --LOG('* EconAssistBody: Assisting now: ['..eng.UnitBeingAssist:GetBlueprint().BlueprintId..'] ('..eng.UnitBeingAssist:GetBlueprint().Description..')')
            IssueGuard({eng}, eng.UnitBeingAssist)
        else
            self.AssistPlatoon = nil
            eng.UnitBeingAssist = nil
            -- stop the platoon from endless assisting
            self:PlatoonDisband()
        end
    end,

    ---@param self Platoon
    AssistBody = function(self)
        local aiBrain = self:GetBrain()
        WaitTicks(5)
        if not aiBrain:PlatoonExists(self) then
            return
        end
        local platoonUnits = self:GetPlatoonUnits()
        local eng = platoonUnits[1]
        eng.AssistPlatoon = self
        local assistData = self.PlatoonData.Assist
        local platoonPos = self:GetPlatoonPosition()
        local assistee = false
        local assistingBool = false
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
                elseif not table.empty(assistee:GetGuards()) then
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
        end
    end,

    ---@param self Platoon
    EngineerAssistAI = function(self)
        self:ForkThread(self.AssistBody)
        local aiBrain = self:GetBrain()
        WaitSeconds(self.PlatoonData.Assist.Time or 60)
        if not aiBrain:PlatoonExists(self) then
            return
        end
        WaitTicks(1)
        -- stop the platoon from endless assisting
        self:Stop()
        self:PlatoonDisband()
    end,

    ---## Function: EngineerBuildAI
    --- a single-unit platoon made up of an engineer, this AI will determine
    --- what needs to be built based on platoon data set by the calling
    --- abstraction, and then issue the build commands to the engineer
    ---@param self Platoon
    ---@return nil
    EngineerBuildAI = function(self)
        local aiBrain = self:GetBrain()
        local platoonUnits = self:GetPlatoonUnits()
        local armyIndex = aiBrain:GetArmyIndex()
        local x,z = aiBrain:GetArmyStartPos()
        local cons = self.PlatoonData.Construction
        local buildingTmpl, buildingTmplFile, baseTmpl, baseTmplFile
        local eng
        for k, v in platoonUnits do
            if not v.Dead and EntityCategoryContains(categories.ENGINEER - categories.STATIONASSISTPOD, v) then --DUNCAN - was construction
                IssueToUnitClearCommands(v)
                if not eng then
                    eng = v
                else
                    IssueGuard({v}, eng)
                end
            end
        end

        if not eng or eng.Dead then
            coroutine.yield(1)
            self:PlatoonDisband()
            return
        end

        --DUNCAN - added
        if eng:IsUnitState('Building') or eng:IsUnitState('Upgrading') or eng:IsUnitState("Enhancing") then
           return
        end

        local FactionToIndex  = { UEF = 1, AEON = 2, CYBRAN = 3, SERAPHIM = 4, NOMADS = 5}
        local factionIndex = cons.FactionIndex or FactionToIndex[eng.Blueprint.FactionCategory]

        buildingTmplFile = import(cons.BuildingTemplateFile or '/lua/BuildingTemplates.lua')
        baseTmplFile = import(cons.BaseTemplateFile or '/lua/BaseTemplates.lua')
        buildingTmpl = buildingTmplFile[(cons.BuildingTemplate or 'BuildingTemplates')][factionIndex]
        baseTmpl = baseTmplFile[(cons.BaseTemplate or 'BaseTemplates')][factionIndex]

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
            coroutine.yield(1)
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
            local radius = cons.LocationRadius or aiBrain.BuilderManagers[cons.LocationType].EngineerManager.Radius or 100
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
                return
            end

        elseif cons.NearMarkerType and cons.ExpansionBase then
            local pos = aiBrain:PBMGetLocationCoords(cons.LocationType) or cons.Position or self:GetPlatoonPosition()
            local radius = cons.LocationRadius or aiBrain.BuilderManagers[cons.LocationType].EngineerManager.Radius or 100

            if cons.NearMarkerType == 'Expansion Area' then
                reference, refName = AIUtils.AIFindExpansionAreaNeedsEngineer(aiBrain, cons.LocationType,
                        (cons.LocationRadius or 100), cons.ThreatMin, cons.ThreatMax, cons.ThreatRings, cons.ThreatType)
                -- didn't find a location to build at
                if not reference or not refName then
                    self:PlatoonDisband()
                    return
                end
            elseif cons.NearMarkerType == 'Naval Area' then
                reference, refName = AIUtils.AIFindNavalAreaNeedsEngineer(aiBrain, cons.LocationType,
                        (cons.LocationRadius or 100), cons.ThreatMin, cons.ThreatMax, cons.ThreatRings, cons.ThreatType)
                -- didn't find a location to build at
                if not reference or not refName then
                    self:PlatoonDisband()
                    return
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
                    return
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
            local pos = aiBrain.BuilderManagers[eng.BuilderManagerData.LocationType].EngineerManager.Location
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
                coroutine.yield(1)
                self:PlatoonDisband()
                return
            end
            reference  = AIUtils.FindUnclutteredArea(aiBrain, cat, pos, radius, cons.maxUnits, cons.maxRadius, avoidCat)
            buildFunction = AIBuildStructures.AIBuildAdjacency
            table.insert(baseTmplList, baseTmpl)
        elseif cons.AdjacencyCategory then
            relative = false
            local pos = aiBrain.BuilderManagers[eng.BuilderManagerData.LocationType].EngineerManager.Location
            local cat = cons.AdjacencyCategory
            -- convert text categories like 'MOBILE AIR' to 'categories.MOBILE * categories.AIR'
            if type(cat) == 'string' then
                cat = ParseEntityCategory(cat)
            end
            local radius = (cons.AdjacencyDistance or 50)
            local radius = (cons.AdjacencyDistance or 50)
            if not pos or not pos then
                coroutine.yield(1)
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
                    if v.PlatoonHandle.PlatoonDisband then
                        v.PlatoonHandle:PlatoonDisband()
                    elseif not v.PlatoonHandle.ExitGuard then
                        v.PlatoonHandle.ExitGuard = true
                    end
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
                            local replacement = SUtils.GetTemplateReplacement(aiBrain, v, faction, buildingTmpl)
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
                            coroutine.yield(1)
                            self:PlatoonDisband()
                            return
                        end
                    end
                end
            end
        end

        -- wait in case we're still on a base
        local count = 0
        while not eng.Dead and eng:IsUnitState('Attached') and count < 2 do
            coroutine.yield(60)
            count = count + 1
        end

        if not eng.Dead and not eng:IsUnitState('Building') then
            return self.ProcessBuildCommand(eng, false)
        end
    end,

    --UpgradeAnEngineeringPlatoon
    ---@param self Platoon
    UnitUpgradeAI = function(self)
        local aiBrain = self:GetBrain()
        local platoonUnits = self:GetPlatoonUnits()
        local factionIndex = aiBrain:GetFactionIndex()
        local FactionToIndex  = { UEF = 1, AEON = 2, CYBRAN = 3, SERAPHIM = 4, NOMADS = 5}
        local UnitBeingUpgradeFactionIndex = nil
        local upgradeIssued = false
        self:Stop()
        --LOG('* UnitUpgradeAI: PlatoonName:'..repr(self.BuilderName))
        for k, v in platoonUnits do
            --LOG('* UnitUpgradeAI: Upgrading unit '..v.UnitId..' ('..v.Blueprint.FactionCategory..')')
            local upgradeID
            -- Get the factionindex from the unit to get the right update (in case we have captured this unit from another faction)
            UnitBeingUpgradeFactionIndex = FactionToIndex[v.Blueprint.FactionCategory] or factionIndex
            --LOG('* UnitUpgradeAI: UnitBeingUpgradeFactionIndex '..UnitBeingUpgradeFactionIndex)
            if self.PlatoonData.OverideUpgradeBlueprint then
                local tempUpgradeID = self.PlatoonData.OverideUpgradeBlueprint[UnitBeingUpgradeFactionIndex]
                if not tempUpgradeID then
                    --WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] *UnitUpgradeAI WARNING: OverideUpgradeBlueprint ' .. repr(v.UnitId) .. ' failed. (Override unitID is empty' )
                elseif type(tempUpgradeID) ~= 'string' then
                    WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] *UnitUpgradeAI WARNING: OverideUpgradeBlueprint ' .. repr(v.UnitId) .. ' failed. (Override unit not present.)' )
                elseif v:CanBuild(tempUpgradeID) then
                    upgradeID = tempUpgradeID
                else
                    -- in case the unit can't upgrade with OverideUpgradeBlueprint, warn the programmer
                    -- this can happen if the AI relcaimed a factory and tries to upgrade to a support factory without having a HQ factory from the reclaimed factory faction.
                    -- in this case we fall back to HQ upgrade template and upgrade to a HQ factory instead of support.
                    -- Output: WARNING: [platoon.lua, line:xxx] *UnitUpgradeAI WARNING: OverideUpgradeBlueprint UnitId:CanBuild(tempUpgradeID) failed. (Override tree not available, upgrading to default instead.)
                    WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] *UnitUpgradeAI WARNING: OverideUpgradeBlueprint ' .. repr(v.UnitId) .. ':CanBuild( '..tempUpgradeID..' ) failed. (Override tree not available, upgrading to default instead.)' )
                end
            end
            if not upgradeID and EntityCategoryContains(categories.MOBILE, v) then
                upgradeID = aiBrain:FindUpgradeBP(v.UnitId, UpgradeTemplates.UnitUpgradeTemplates[UnitBeingUpgradeFactionIndex])
                -- if we can't find a UnitUpgradeTemplate for this unit, warn the programmer
                if not upgradeID then
                    -- Output: WARNING: [platoon.lua, line:xxx] *UnitUpgradeAI ERROR: Can\'t find UnitUpgradeTemplate for mobile unit: ABC1234
                    WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] *UnitUpgradeAI ERROR: Can\'t find UnitUpgradeTemplate for mobile unit: ' .. repr(v.UnitId) )
                end
            elseif not upgradeID then
                upgradeID = aiBrain:FindUpgradeBP(v.UnitId, UpgradeTemplates.StructureUpgradeTemplates[UnitBeingUpgradeFactionIndex])
                -- if we can't find a StructureUpgradeTemplate for this unit, warn the programmer
                if not upgradeID then
                    -- Output: WARNING: [platoon.lua, line:xxx] *UnitUpgradeAI ERROR: Can\'t find StructureUpgradeTemplate for structure: ABC1234
                    WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] *UnitUpgradeAI ERROR: Can\'t find StructureUpgradeTemplate for structure: ' .. repr(v.UnitId) .. '  faction: ' .. repr(v.Blueprint.FactionCategory) )
                end
            end
            if upgradeID and EntityCategoryContains(categories.STRUCTURE, v) and not v:CanBuild(upgradeID) then
                -- in case the unit can't upgrade with upgradeID, warn the programmer
                -- Output: WARNING: [platoon.lua, line:xxx] *UnitUpgradeAI ERROR: ABC1234:CanBuild(upgradeID) failed!
                WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] *UnitUpgradeAI ERROR: ' .. repr(v.UnitId) .. ':CanBuild( '..upgradeID..' ) failed!' )
                continue
            end
            if upgradeID then
                upgradeIssued = true
                IssueUpgrade({v}, upgradeID)
                --LOG('-- Upgrading unit '..v.UnitId..' ('..v.Blueprint.FactionCategory..') with '..upgradeID)
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

    ---@param self Platoon
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

    ---@param self Platoon
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
    ---@param self Platoon
    GunshipHuntAI = function(self)
        local NavUtils = import("/lua/sim/navutils.lua")
        AIAttackUtils.GetMostRestrictiveLayer(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local armyIndex = aiBrain:GetArmyIndex()
        local target
        local blip
        local hadtarget = false
        while aiBrain:PlatoonExists(self) do
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
                local safePath, reason = NavUtils.PathToWithThreatThreshold(self.MovementLayer, self:GetPlatoonPosition(), position, aiBrain, NavUtils.ThreatFunctions.AntiAir, 200, aiBrain.IMAPConfig.Rings)
                if safePath then
                    for _,p in safePath do
                        self:MoveToLocation(p, false)
                    end
                else
                    self:MoveToLocation(position, false)
                end
                hadtarget = false
            end
            WaitSeconds(17)
        end
    end,

    --DUNCAN - Credit to sorian, called FighterHuntAI in his pack
    ---@param self Platoon
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
                hadtarget = false
            end
            WaitSeconds(5) --DUNCAN - was 5
        end
    end,

    ---@param self Platoon
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

    ---## Function: CarrierAI
    --- Uses the carrier as a sea-based powerful anti-air unit.
    --- Dispatches the carrier to a location with heavy air cover
    --- to wreck havoc on air units
    ---@param self Platoon
    CarrierAI = function(self)
        local NavUtils = import("/lua/sim/navutils.lua")
        local aiBrain = self:GetBrain()
        if not aiBrain then
            return
        end
        self.PlatoonAirThreat = self:GetPlatoonThreat('Air', categories.ALLUNITS)

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
                local path, reason = NavUtils.PathToWithThreatThreshold(self.MovementLayer, self:GetPlatoonPosition(), attackPos, aiBrain, NavUtils.ThreatFunctions.AntiSurface, self.PlatoonAirThreat * 10, aiBrain.IMAPConfig.Rings)
                -- clear command queue
                self:Stop()

                if not path then
                    -- Need to understand the reason for this in navmesh
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

    ---## Function: DummyAI
    --- Does nothing, just returns
    ---@param self Platoon
    DummyAI = function(self)
    end,

    ---@param self Platoon
    ArtilleryAI = function(self)
        local aiBrain = self:GetBrain()

        local atkPri = { 'STRUCTURE STRATEGIC', 'EXPERIMENTAL LAND', 'STRUCTURE SHIELD', 'COMMAND', 'STRUCTURE FACTORY',
            'STRUCTURE DEFENSE', 'MOBILE TECH3 LAND', 'MOBILE TECH2 LAND', 'ALLUNITS' }
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

    ---##   Function: NavalForceAI
    --- Basic attack logic for boats.  Searches for a good area to go attack, and will use
    --- a safe path (if available) to get there.
    ---@param self Platoon
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

            if v.Layer != 'Sub' then
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
            elseif table.empty(cmdQ) then
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

    ---## Function: AttackForceAI
    --- Basic attack logic.  Searches for a good area to go attack, and will use
    --- a safe path (if available) to get there.  If the threat of the platoon
    --- drops too low, it will try and guard an engineer (to be more useful)
    --- See AIAttackUtils for the bulk of the logic
    ---@param self Platoon
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
        local maxPlatoonSize = self.PlatoonData.MaxPlatoonSize or 40

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
            if numberOfUnitsInPlatoon < self.PlatoonData.MaxPlatoonSize then
                self.PlatoonFull = false
                self:MergeWithNearbyPlatoons('AttackForceAI', 10, maxPlatoonSize)
            else
                self.PlatoonFull = true
            end

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
            if not table.empty(strayTransports) then
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
                if not table.empty(strayTransports) then
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
            elseif table.empty(cmdQ) then
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

            if table.empty(cmdQ) then
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

    ---## Function: ReturnToBaseAI
    --- Finds a base to return to and disband - that way it can be used
    --- for a new platoon
    ---@param self Platoon
    ReturnToBaseAI = function(self)
        if IsDestroyed(self) then
            return
        end
        local NavUtils = import("/lua/sim/navutils.lua")
        local aiBrain = self:GetBrain()
        if not aiBrain:PlatoonExists(self) or not self:GetPlatoonPosition() then
            return
        end

        local NavUtils = import("/lua/sim/navutils.lua")
        if not self.MovementLayer then
            AIAttackUtils.GetMostRestrictiveLayer(self)
        end
    
        local bestBase = false
        local bestBaseName
        local bestDistSq
        local platPos = self:GetPlatoonPosition()
        local returnPos
        for baseName, base in aiBrain.BuilderManagers do
            if (self.MovementLayer == 'Water' and base.Layer ~= 'Water') or (self.MovementLayer == 'Land' and base.Layer == 'Water') then
                continue
            end
            local distSq = VDist2Sq(platPos[1], platPos[3], base.Position[1], base.Position[3])

            if not bestDistSq or distSq < bestDistSq then
                bestBase = base
                bestBaseName = baseName
                bestDistSq = distSq
            end
        end

        if bestBase then
            if bestBase.FactoryManager.RallyPoint then
                returnPos = bestBase.FactoryManager.RallyPoint
            else
                returnPos = bestBase.Position
            end
            local path, reason =  NavUtils.PathToWithThreatThreshold(self.MovementLayer, self:GetPlatoonPosition(), returnPos, aiBrain, NavUtils.ThreatFunctions.AntiSurface, 200, aiBrain.IMAPConfig.Rings)
            -- remove any formation settings to ensure a quick return to base.
            self:SetPlatoonFormationOverride('NoFormation')
            self:Stop()

            if path then
                local pathLength = table.getn(path)
                for i=1, pathLength-1 do
                    self:MoveToLocation(path[i], false)
                end
            end
            self:MoveToLocation(returnPos, false)

            local oldDistSq = 0
            while aiBrain:PlatoonExists(self) do
                
                WaitTicks(100)
                platPos = self:GetPlatoonPosition()
                local distSq = VDist2Sq(platPos[1], platPos[3], returnPos[1], returnPos[3])
                if distSq < 100 then
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
    end,

    -- -------------------
    --  Support Functions
    -- -------------------

    --- stop platoon and delete last attack destination so new one will be picked
    ---@param self Platoon
    StopAttack = function(self)
        self:Stop()
        self.LastAttackDestination = {}
    end,

    ---## NOTES:
    --- don't always use defensive point, use naval point for navies, etc.
    --- or gather around center
    ---@param self Platoon
    ---@return boolean
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

    ---## Function: MergeWithNearbyPlatoons
    --- Finds platoons nearby (when self platoon is not near a base) and merge
    --- with them if they're a good fit.
    ---@param self Platoon
    ---@param planName string
    ---@param radius number
    ---@return nil
    MergeWithNearbyPlatoons = function(self, planName, radius, maxPlatoonCount)
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

        -- Count platoon units so that we have adhere to maximums to avoid platoons that are too big to move correctly
        local platUnits = self:GetPlatoonUnits()
        local platCount = 0
        for _, u in platUnits do
            if not u.Dead then
                platCount = platCount + 1
            end
        end
        if (maxPlatoonCount and platCount > maxPlatoonCount) or platCount < 1 then
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
            if aPlat.GetPlan and aPlat:GetPlan() != planName then
                continue
            end
            if aPlat == self then
                continue
            end

            if aPlat.UsingTransport then
                continue
            end

            if aPlat.PlatoonFull then
                continue
            end

            local allyPlatPos = aPlat:GetPlatoonPosition()
            if not allyPlatPos or not aiBrain:PlatoonExists(aPlat) then
                continue
            end

            if not self.MovementLayer then
                AIAttackUtils.GetMostRestrictiveLayer(self)
            end
            if not aPlat.MovementLayer then
                AIAttackUtils.GetMostRestrictiveLayer(aPlat)
            end

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

    --- names units in platoon
    ---@param self Platoon
    NameUnits = function(self)
        local units = self:GetPlatoonUnits()
        if units and not table.empty(units) then
            for k, v in units do
                local bp = v:GetBlueprint().Display
                if bp.AINames then
                    local num = Random(1, table.getn(bp.AINames))
                    v:SetCustomName(bp.AINames[num])
                end
            end
        end
    end,

    ---returns each type of threat for this platoon
    ---@param self Platoon
    ---@return table
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

    --- Checks radius around base to see if marker is sufficiently far away
    ---@param self Platoon
    ---@param markerPos Vector
    ---@param avoidBasesDefault any
    ---@param baseRadius number
    ---@return boolean
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

    --- greater than or less than check, based on what kind of threat order we want
    ---@param findHighestThreat number[]
    ---@param newMarker number
    ---@param oldMarker number
    ---@return boolean
    IsBetterThreat = function(findHighestThreat, newMarker, oldMarker)
        if findHighestThreat then
            return newMarker > oldMarker
        end
        return newMarker < oldMarker
    end,

    ---@param eng EngineerBuilder
    SetupEngineerCallbacks = function(eng)
        if eng and not eng.Dead and not eng.BuildDoneCallbackSet and eng.PlatoonHandle and eng:GetAIBrain():PlatoonExists(eng.PlatoonHandle) then
            import("/lua/scenariotriggers.lua").CreateUnitBuiltTrigger(eng.PlatoonHandle.EngineerBuildDone, eng, categories.ALLUNITS)
            eng.BuildDoneCallbackSet = true
        end
        if eng and not eng.Dead and not eng.CaptureDoneCallbackSet and eng.PlatoonHandle and eng:GetAIBrain():PlatoonExists(eng.PlatoonHandle) then
            import("/lua/scenariotriggers.lua").CreateUnitStopCaptureTrigger(eng.PlatoonHandle.EngineerCaptureDone, eng)
            eng.CaptureDoneCallbackSet = true
        end
        if eng and not eng.Dead and not eng.FailedToBuildCallbackSet and eng.PlatoonHandle and eng:GetAIBrain():PlatoonExists(eng.PlatoonHandle) then
            import("/lua/scenariotriggers.lua").CreateOnFailedToBuildTrigger(eng.PlatoonHandle.EngineerFailedToBuild, eng)
            eng.FailedToBuildCallbackSet = true
        end
    end,

    -- Callback functions for EngineerBuildAI
    ---@param unit Unit
    ---@param params any
    EngineerBuildDone = function(unit, params)
        if not unit.PlatoonHandle then return end
        if not unit.PlatoonHandle.PlanName == 'EngineerBuildAI' then return end
        --LOG("*AI DEBUG: Build done " .. unit.Sync.id)
        if not unit.ProcessBuild then
            unit.ProcessBuild = unit:ForkThread(unit.PlatoonHandle.ProcessBuildCommand, true)
            unit.ProcessBuildDone = true
        end
    end,
    ---@param unit Unit
    ---@param params any
    EngineerCaptureDone = function(unit, params)
        if not unit.PlatoonHandle then return end
        if not unit.PlatoonHandle.PlanName == 'EngineerBuildAI' then return end
        --LOG("*AI DEBUG: Capture done" .. unit.Sync.id)
        if not unit.ProcessBuild then
            unit.ProcessBuild = unit:ForkThread(unit.PlatoonHandle.ProcessBuildCommand, false)
        end
    end,
    ---@param unit Unit
    ---@param params any
    EngineerReclaimDone = function(unit, params)
        if not unit.PlatoonHandle then return end
        if not unit.PlatoonHandle.PlanName == 'EngineerBuildAI' then return end
        --LOG("*AI DEBUG: Reclaim done" .. unit.Sync.id)
        if not unit.ProcessBuild then
            unit.ProcessBuild = unit:ForkThread(unit.PlatoonHandle.ProcessBuildCommand, false)
        end
    end,
    ---@param unit Unit
    ---@param params any
    EngineerFailedToBuild = function(unit, params)
        if not unit.PlatoonHandle then return end
        if not unit.PlatoonHandle.PlanName == 'EngineerBuildAI' then return end
        if unit.UnitBeingBuiltBehavior then
            if unit.ProcessBuild then
                KillThread(unit.ProcessBuild)
                unit.ProcessBuild = nil
            end
            return
        end
        if unit.ProcessBuildDone and unit.ProcessBuild then
            KillThread(unit.ProcessBuild)
            unit.ProcessBuild = nil
        end
        if not unit.ProcessBuild then
            --LOG("*AI DEBUG: Failed to build" .. unit.Sync.id)
            unit.ProcessBuild = unit:ForkThread(unit.PlatoonHandle.ProcessBuildCommand, false) 
        end
    end,

    ---## Function: WatchForNotBuilding
    --- After we try to build something, watch the engineer to
    --- make sure that the build goes through.  If not,
    --- try the next thing in the queue
    ---@param eng EngineerBuilder
    WatchForNotBuilding = function(eng)
        coroutine.yield(10)
        local aiBrain = eng:GetAIBrain()

        while not eng.Dead and not eng.PlatoonHandle.UsingTransport and (eng.GoingHome or eng.UnitBeingBuiltBehavior or eng.ProcessBuild != nil or not eng:IsIdleState()) do
            coroutine.yield(30)
        end

        eng.NotBuildingThread = nil
        if not eng.Dead and eng:IsIdleState() and not table.empty(eng.EngineerBuildQueue) and eng.PlatoonHandle then
            eng.PlatoonHandle.SetupEngineerCallbacks(eng)
            if not eng.ProcessBuild then
                eng.ProcessBuild = eng:ForkThread(eng.PlatoonHandle.ProcessBuildCommand, true)
            end
        end
    end,

    ---## Function: ProcessBuildCommand
    --- Run after every build order is complete/fails.  Sets up the next
    --- build order in queue, and if the engineer has nothing left to do
    --- will return the engineer back to the army pool by disbanding the
    --- the platoon.  Support function for EngineerBuildAI
    ---@param eng any
    ---@param removeLastBuild boolean
    ProcessBuildCommand = function(eng, removeLastBuild)
        if not eng or eng.Dead or not eng.PlatoonHandle then
            return
        end
        local aiBrain = eng.PlatoonHandle:GetBrain()
        if not aiBrain or eng.Dead or not eng.EngineerBuildQueue or table.empty(eng.EngineerBuildQueue) then
            if aiBrain:PlatoonExists(eng.PlatoonHandle) then
                if not eng.AssistSet and not eng.AssistPlatoon and not eng.UnitBeingAssist and not eng.UnitBeingBuiltBehavior then
                    eng.PlatoonHandle:PlatoonDisband()
                end
            end
            if eng then eng.ProcessBuild = nil end
            return
        end

        -- it wasn't a failed build, so we just finished something
        if removeLastBuild then
            table.remove(eng.EngineerBuildQueue, 1)
        end

        eng.ProcessBuildDone = false
        IssueToUnitClearCommands(eng)
        local commandDone = false
        local PlatoonPos
        local whatToBuild
        local buildLocation
        local buildRelative
        while not eng.Dead and not commandDone and not table.empty(eng.EngineerBuildQueue)  do
            whatToBuild = eng.EngineerBuildQueue[1][1]
            buildLocation = {eng.EngineerBuildQueue[1][2][1], 0, eng.EngineerBuildQueue[1][2][2]}
            if GetTerrainHeight(buildLocation[1], buildLocation[3]) > GetSurfaceHeight(buildLocation[1], buildLocation[3]) then
                --land
                buildLocation[2] = GetTerrainHeight(buildLocation[1], buildLocation[3])
            else
                --water
                buildLocation[2] = GetSurfaceHeight(buildLocation[1], buildLocation[3])
            end
            buildRelative = eng.EngineerBuildQueue[1][3]
            if not eng.NotBuildingThread then
                eng.NotBuildingThread = eng:ForkThread(eng.PlatoonHandle.WatchForNotBuilding)
            end
            -- see if we can move there first
            if AIUtils.EngineerMoveWithSafePath(aiBrain, eng, buildLocation) then
                if not eng or eng.Dead or not eng.PlatoonHandle or not aiBrain:PlatoonExists(eng.PlatoonHandle) then
                    return
                end
                PlatoonPos = eng:GetPosition()
                if VDist2(PlatoonPos[1] or 0, PlatoonPos[3] or 0, buildLocation[1] or 0, buildLocation[3] or 0) >= 30 then
                    -- issue buildcommand to block other engineers from caping mex/hydros or to reserve the buildplace
                    aiBrain:BuildStructure(eng, whatToBuild, {buildLocation[1], buildLocation[3], 0}, buildRelative)
                    coroutine.yield(3)
                    -- wait until we are close to the buildplace so we have intel
                    while not eng.Dead do
                        PlatoonPos = eng:GetPosition()
                        if VDist2(PlatoonPos[1] or 0, PlatoonPos[3] or 0, buildLocation[1] or 0, buildLocation[3] or 0) < 12 then
                            break
                        end
                        -- check if we are already building in close range
                        -- (ACU can build at higher range than engineers)
                        if eng:IsUnitState("Building") then
                            break
                        end
                        coroutine.yield(1)
                    end
                end
                if not eng or eng.Dead or not eng.PlatoonHandle or not aiBrain:PlatoonExists(eng.PlatoonHandle) then
                    if eng then eng.ProcessBuild = nil end
                    return
                end
                -- if we are already building then we don't need to reclaim, repair or issue the BuildStructure again
                if not eng:IsUnitState("Building") then
                    -- cancel all commands, also the buildcommand for blocking mex to check for reclaim or capture
                    eng.PlatoonHandle:Stop()
                    -- check to see if we need to reclaim or capture...
                    AIUtils.EngineerTryReclaimCaptureArea(aiBrain, eng, buildLocation)
                    -- check to see if we can repair
                    AIUtils.EngineerTryRepair(aiBrain, eng, whatToBuild, buildLocation)
                    -- otherwise, go ahead and build the next structure there
                    aiBrain:BuildStructure(eng, whatToBuild, {buildLocation[1], buildLocation[3], 0}, buildRelative)
                end
                if not eng.NotBuildingThread then
                    eng.NotBuildingThread = eng:ForkThread(eng.PlatoonHandle.WatchForNotBuilding)
                end
                commandDone = true
            else
                -- we can't move there, so remove it from our build queue
                table.remove(eng.EngineerBuildQueue, 1)
            end
        end

        -- final check for if we should disband
        if not eng or eng.Dead or table.empty(eng.EngineerBuildQueue) then
            if eng.PlatoonHandle and aiBrain:PlatoonExists(eng.PlatoonHandle) and not eng.PlatoonHandle.UsingTransport and eng.PlatoonHandle.PlatoonDisband then
                eng.PlatoonHandle:PlatoonDisband()
            end
        end
        if eng then eng.ProcessBuild = nil end
    end,    

    ---@param self Platoon
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

   ---@param self Platoon
   ---@return boolean
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

    ---@param self Platoon
    PlatoonDisbandNoAssign = function(self)
        if self.BuilderHandle then
            self.BuilderHandle:RemoveHandle(self)
        end
        for k,v in self:GetPlatoonUnits() do
            v.PlatoonHandle = nil
        end
        self:GetBrain():DisbandPlatoon(self)
    end,

    ---@param self Platoon
    ---@return nil
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
        self.PlatoonAirThreat = self:GetPlatoonThreat('Air', categories.ALLUNITS)
        while aiBrain:PlatoonExists(self) do
            target = self:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS - categories.WALL)
            local newtarget = false
            if aiBrain.T4ThreatFound['Land'] or aiBrain.T4ThreatFound['Naval'] or aiBrain.T4ThreatFound['Structure'] then
                newtarget = self:FindClosestUnit('Attack', 'Enemy', true, categories.EXPERIMENTAL * (categories.LAND + categories.NAVAL + categories.STRUCTURE + categories.ARTILLERY))
                if newtarget then
                    target = newtarget
                end
            elseif aiBrain.AirAttackPoints and not table.empty(aiBrain.AirAttackPoints) then
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
                local NavUtils = import("/lua/sim/navutils.lua")
                local x,z = aiBrain:GetArmyStartPos()
                local position = AIUtils.RandomLocation(x,z)
                local safePath, reason = NavUtils.PathToWithThreatThreshold(self.MovementLayer, self:GetPlatoonPosition(), position, aiBrain, NavUtils.ThreatFunctions.AntiAir, self.PlatoonAirThreat * 10, aiBrain.IMAPConfig.Rings)
                if safePath then
                    for _,p in safePath do
                        self:MoveToLocation(p, false)
                    end
                else
                    self:MoveToLocation(position, false)
                end
                hadtarget = false
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

    ---## Function: AirIntelToggle
    --- Turns on Air unit cloak/stealth.
    ---@param self any
    ---@return nil
    AirIntelToggle = function(self)
        --LOG('*AI DEBUG: AirIntelToggle run')
        for k,v in self:GetPlatoonUnits() do
            if v:TestToggleCaps('RULEUTC_StealthToggle') then
                v:SetScriptBit('RULEUTC_StealthToggle', false)
            end
        end
    end,

    ---@param self Platoon
    ManagerEngineerFindLowShield = function(self)
        local aiBrain = self:GetBrain()
        self:EconDamagedShield()
        WaitSeconds(60)
        if not aiBrain:PlatoonExists(self) then
            return
        end
        self:PlatoonDisband()
    end,

    ---@param self Platoon
    EconDamagedShield = function(self)
        local eng = self:GetPlatoonUnits()[1]
        if not eng then
            self:PlatoonDisband()
            return
        end
        local aiBrain = self:GetBrain()
        local assistData = self.PlatoonData.Assist
        local assistee = false

        eng.AssistPlatoon = self

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
            self:PlatoonDisband()
        end
    end,

    ---@param self Platoon
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
        local atkPri = { 'STRUCTURE ANTINAVY', 'MOBILE NAVAL', 'STRUCTURE NAVAL', 'COMMAND', 'EXPERIMENTAL', 'STRUCTURE STRATEGIC EXPERIMENTAL', 'ARTILLERY EXPERIMENTAL', 'STRUCTURE ARTILLERY TECH3', 'STRUCTURE NUKE TECH3', 'STRUCTURE ANTIMISSILE SILO',
                            'STRUCTURE DEFENSE DIRECTFIRE', 'TECH3 MASSFABRICATION', 'TECH3 ENERGYPRODUCTION', 'STRUCTURE STRATEGIC', 'STRUCTURE DEFENSE', 'STRUCTURE', 'MOBILE', 'ALLUNITS' }
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

            if v.Layer == 'Sub' then
                continue
            end

            if v:TestCommandCaps('RULEUCC_Dive') and v.UnitId != 'uas0401' then
                IssueDive({v})
            end
        end
        WaitSeconds(5)
        while aiBrain:PlatoonExists(self) do
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
            WaitSeconds(17)
        end
    end,

    --- Patrols the platoon along the path, orientating at each node to match the line from the previous node to the current node.
    ---@param self Platoon
    ---@param path Vector[] path A table of positions, preferably of type Vector. Converted otherwise.
    ---@param formation? UnitFormations self.PlatoonData.UseFormation The formation to apply, such as GrowthFormation, AttackFormation or NoFormation.
    ---@return PlatoonCommand[]
    IssuePatrolAlongRoute = function(self, path, formation)

        -- check for optional / default values
        local formation = formation or self.PlatoonData.UseFormation or 'NoFormation'

        -- check if the parameters are correct
        if not path or not (type(path) == 'table') then
            error("IssuePatrolAlongRoute: The path is not a table. For paths with only one node, use { node } as the path.")
            return { }
        end

        if table.empty(path) then
            error("IssuePatrolAlongRoute: The path is empty.");
            return { }
        end

        -- keep track of all the commands we issued
        local commands = { }

        -- we have no formation, further computations are not required. We use this
        -- shortcut because calling IssueFormPatrol() with no formation causes them
        -- to not move at all.
        if formation == 'NoFormation' then
            local units = self:GetPlatoonUnits()
            for k, node in path do
                local command = IssuePatrol(units, node)
                table.insert(commands, command)
            end

            return commands
        end

        -- check if we have a path of tables, instead to a path of vectors. A lot of the functionality provided by
        -- this library generates lists of tables instead of lists of vectors. Functionality in this file requires
        -- a list of vectors. Convert it if neccesary.
        if not path[1].x then
            local oldPath = path
            path = {}
            for k, node in oldPath do
                table.insert(path, Vector(node[1], node[2], node[3]))
            end
        end

        -- store locally for better performance
        local count = table.getn(path)
        local GetAngleCCW = Utilities.GetAngleCCW
        local GetDirectionVector = Utilities.GetDirectionVector

        -- pre-compute the angles
        local angles = { }
        for k = 1, count do

            local curr = path[k - 1]
            local next = path[k]

            -- if we're trying to look before the first node of the path, use the last node instead
            if k - 1 < 1 then
                curr = path[count]
            end

            -- base orientation when the angle is 0 for the function IssueFormMove
            local base = Vector( 0, 0, 1 )
            local direction = GetDirectionVector(next, curr)
            local angle = GetAngleCCW(base, direction)
            angles[k] = angle
        end

        -- move over the path in formation
        local units = self:GetPlatoonUnits()

        for k = 1, count do
            local point = path[k]
            local angle = angles[k]
            local command = IssueFormPatrol(units, point, formation, angle)
            table.insert(commands, command)
        end

        return commands
    end,

    --- Aggressive-moves the platoon along the path, orientating at each node to match the line from the previous node to the current node.
    ---@param self Platoon
    ---@param path Vector[]
    ---@param formation? UnitFormations
    ---@return PlatoonCommand[]
    IssueAggressiveMoveAlongRoute = function(self, path, formation)
        -- check for optional / default values
        local formation = formation or self.PlatoonData.UseFormation or 'NoFormation'

        -- check if the parameters are correct
        if not path or not (type(path) == 'table') then
            error("IssueAggressiveMoveAlongRoute: The path is not a table. For paths with only one node, use { node } as the path.")
            return { }
        end

        if table.empty(path) then
            error("IssueAggressiveMoveAlongRoute: The path is empty.");
            return { }
        end

        -- keep track of all the commands we issued
        local commands = { }

        -- we have no formation, further computations are not required. We use this
        -- shortcut because calling IssueFormAggressiveMove() with no formation causes
        -- them to not move at all.
        if formation == 'NoFormation' then
            -- store the commands / orders
            local units = self:GetPlatoonUnits()

            for k, node in path do
                local command = IssueAggressiveMove(units, node)
                table.insert(commands, command)
            end

            return commands
        end

        -- check if we have a path of tables, instead of a path of vectors. A lot of the functionality provided by
        -- this library generates lists of tables instead of lists of vectors. Functionality in this file requires
        -- a list of vectors. Convert it if neccesary.
        if not path[1].x then
            local oldPath = path
            path = {}
            for k, node in oldPath do
                table.insert(path, Vector(node[1], node[2], node[3]))
            end
        end

        -- store locally for better performance
        local count = table.getn(path)
        local GetAngleCCW = Utilities.GetAngleCCW
        local GetDirectionVector = Utilities.GetDirectionVector

        -- pre-compute the angles
        local angles = { }
        for k = 1, count do

            local curr = path[k - 1]
            local next = path[k]

            -- if we're trying to look before the first node of the path, use the platoons current position instead
            if k - 1 < 1 then
                local pos = self:GetPlatoonPosition()
                curr = Vector(pos[1], pos[2], pos[3])
            end

            -- base orientation when the angle is 0
            local base = Vector( 0, 0, 1 )
            local direction = GetDirectionVector(next, curr)
            local angle = GetAngleCCW(base, direction)
            angles[k] = angle
        end

        -- move over the path, store the commands
        local units = self:GetPlatoonUnits()

        for k = 1, count do
            local point = path[k]
            local angle = angles[k]
            local command = IssueFormAggressiveMove(units, point, formation, angle)
            table.insert(commands, command)
        end

        return commands
    end,

    --- Moves the platoon along the path, orientating at each node to match the line from the previous node to the current node.
    ---@param self Platoon
    ---@param path Vector[] A table of positions, preferably of type Vector. Converted otherwise.
    ---@param formation? UnitFormations self.PlatoonData.UseFormation The formation to apply, such as GrowthFormation, AttackFormation or NoFormation.
    ---@return PlatoonCommand[]
    IssueMoveAlongRoute = function(self, path, formation)
        -- check for optional / default values
        local formation = formation or self.PlatoonData.UseFormation or 'NoFormation'

        -- check if the parameters are correct
        if not path or not (type(path) == 'table') then
            error("IssueMoveAlongRoute: The path is not a table. For paths with only one node, use { node } as the path.")
            return { }
        end

        if table.empty(path) then
            error("IssueMoveAlongRoute: The path is empty.");
            return { }
        end

        -- keep track of all the commands we issued
        local commands = { }

        -- we have no formation, further computations are not required. We use this
        -- shortcut because calling IssueFormMove() with no formation causes them
        -- to not move at all.
        if formation == 'NoFormation' then
            -- store the commands / orders
            local units = self:GetPlatoonUnits()
            for k, node in path do
                local command = IssueMove(units, node)
                table.insert(commands, command)
            end

            return commands
        end

        -- check if we have a path of tables, instead of a path of vectors. A lot of the functionality provided by
        -- this library generates lists of tables instead of lists of vectors. Functionality in this file requires
        -- a list of vectors. Convert it if neccesary.
        if not path[1].x then
            local oldPath = path
            path = {}
            for k, node in oldPath do
                table.insert(path, Vector(node[1], node[2], node[3]))
            end
        end

        -- store locally for better performance
        local count = table.getn(path)
        local GetAngleCCW = Utilities.GetAngleCCW
        local GetDirectionVector = Utilities.GetDirectionVector

        -- pre-compute the angles
        local angles = { }
        for k = 1, count do

            local curr = path[k - 1]
            local next = path[k]

            -- if we're trying to look before the first node of the path, use the platoons current position instead
            if k - 1 < 1 then
                local pos = self:GetPlatoonPosition()
                curr = Vector(pos[1], pos[2], pos[3])
            end

            -- base orientation when the angle is 0
            local base = Vector( 0, 0, 1 )
            local direction = GetDirectionVector(next, curr)
            local angle = GetAngleCCW(base, direction)
            angles[k] = angle
        end

        -- move over the path, store the commands
        local units = self:GetPlatoonUnits()

        for k = 1, count -1 do
            local point = path[k]
            local angle = angles[k]
            local command = IssueFormMove(units, point, formation, angle)
            table.insert(commands, command)
        end

        -- aggressive move for the final path node
        table.insert(commands, IssueFormAggressiveMove(units, path[count], formation, angles[count]))

        return commands
    end,

    ---@param self Platoon
    ReclaimGridAI = function(self)
        -- note ReclaimEngineerAssigned is currently disabled as we need a method of assigning engineers to the reclaim grid.
        -- Waiting a few days to see if Jip has ideas to making this possible via the gridinstance. If not then I can design a method.
        -- Note where state machine actions would happen.
        AIAttackUtils.GetMostRestrictiveLayer(self)
        local locationType = self.PlatoonData.LocationType

        local aiBrain = self:GetBrain()
        local reclaimGridInstance = aiBrain.GridReclaim
        local brainGridInstance = aiBrain.GridBrain
        local eng = self:GetPlatoonUnits()[1]

        -- we don't have the datastructures to run this platoon
        if not (reclaimGridInstance and brainGridInstance) then
            return
        end
        -- @Jip this is the callback I think I can use for removal of assignment on death.
        local deathFunction = function(unit)
            if unit.CellAssigned then
                -- Brain is assigned on unit create, if issues use eng:GetAIBrain()
                local brainGridInstance = unit.Brain.GridBrain
                local brainCell = brainGridInstance:ToCellFromGridSpace(unit.CellAssigned[1], unit.CellAssigned[2])
                -- confirm engineer is removed from cell during debug
                brainGridInstance:RemoveReclaimingEngineer(brainCell, unit)
            end
        end

        import("/lua/scenariotriggers.lua").CreateUnitDestroyedTrigger(deathFunction, eng)

        local gridSize = reclaimGridInstance.CellSize * reclaimGridInstance.CellSize
        local searchType = self.PlatoonData.SearchType
            -- Placeholders this part is temporary until the ReclaimGrid defines the playable area min and max grid sizes

        eng.CellAssigned = false
        -- Combat is added to stop the engineer manager from doing anything with the engineer
        eng.Combat = true
        while aiBrain:PlatoonExists(self) do
            WaitTicks(10)
            IssueToUnitClearCommands(eng)
            -- Find a cell we want to reclaim from
            local reclaimTargetX, reclaimTargetZ = AIUtils.EngFindReclaimCell(aiBrain, eng, self.MovementLayer, searchType)
            if reclaimTargetX and reclaimTargetZ then
                local brainCell = brainGridInstance:ToCellFromGridSpace(reclaimTargetX, reclaimTargetZ)
                -- Assign engineer to cell
                eng.CellAssigned = {reclaimTargetX, reclaimTargetZ}
                brainGridInstance:AddReclaimingEngineer(brainCell, eng)
                local moveLocation = reclaimGridInstance:ToWorldSpace(reclaimTargetX, reclaimTargetZ)
                IssueToUnitMove(eng, moveLocation)
                local engStuckCount = 0
                local Lastdist
                local dist = VDist3Sq(eng:GetPosition(), moveLocation)

                -- Statemachine switch for engineer moving to location
                while not IsDestroyed(eng) and dist > gridSize do
                    WaitTicks(25)
                    if aiBrain:GetNumUnitsAroundPoint(categories.LAND * categories.MOBILE, eng:GetPosition(), 45, 'Enemy') > 0 then
                        -- Statemachine switch to avoiding/reclaiming danger
                        local actionTaken = AIUtils.EngAvoidLocalDanger(aiBrain, eng)
                        if actionTaken then
                            -- Statemachine switch to evaluating next action to take
                            IssueToUnitMove(eng, moveLocation)
                        end
                    else
                        -- Jip discussed potentially getting navmesh to return mass points along the path rather than this.
                        -- Potential Statemachine switch to building extractors
                        if not eng:IsUnitState('Reclaiming') then
                            local reclaimAction = AIUtils.EngPerformReclaim(eng, 10)
                            if reclaimAction then
                                WaitTicks(45)
                                -- Statemachine switch to evaluating next action to take
                                IssueToUnitMove(eng, moveLocation)
                            end
                        end
                        local extractorAction = AIUtils.EngLocalExtractorBuild(aiBrain, eng)
                        if extractorAction then
                            -- Statemachine switch to evaluating next action to take
                            IssueToUnitMove(eng, moveLocation)
                        end
                    end
                    dist = VDist3Sq(eng:GetPosition(), moveLocation)
                    if Lastdist ~= dist then
                        engStuckCount = 0
                        Lastdist = dist
                    elseif not eng:IsUnitState('Reclaiming') then
                        engStuckCount = engStuckCount + 1
                        if engStuckCount > 15 then
                            break
                        end
                    end
                end
                if IsDestroyed(eng) then
                    return
                end
                if dist <= gridSize then
                    -- Statemachine switch to reclaiming state
                    local time = 0
                    IssueToUnitClearCommands(eng)
                    while time < 30 do
                        IssueAggressiveMove({eng}, moveLocation)
                        time = time + 1
                        WaitTicks(50)
                        local engPos = eng:GetPosition()
                        if aiBrain:GetNumUnitsAroundPoint(categories.LAND * categories.MOBILE, engPos, 45, 'Enemy') > 0 then
                            -- Statemachine switch to avoiding/reclaiming danger
                            local actionTaken = AIUtils.EngAvoidLocalDanger(aiBrain, eng)
                            if actionTaken then
                                -- Statemachine switch to evaluating next action to take
                                IssueAggressiveMove({eng}, moveLocation)
                            end
                        end
                        if reclaimGridInstance.Cells[reclaimTargetX][reclaimTargetZ].TotalMass < 10  or aiBrain:GetEconomyStoredRatio('MASS') > 0.95 then
                            break
                        end
                        if VDist3Sq(engPos, moveLocation) < 4 and reclaimGridInstance.Cells[reclaimTargetX][reclaimTargetZ].TotalMass > 5 then
                            for _, v in reclaimGridInstance.Cells[reclaimTargetX][reclaimTargetZ].Reclaim do
                                if IsProp(v) and v.MaxMassReclaim > 0 then
                                    moveLocation = v:GetPosition()
                                    IssueToUnitClearCommands(eng)
                                    break
                                end
                            end
                        end
                    end
                end
            end

            if reclaimTargetX and reclaimTargetZ then
                local brainCell = brainGridInstance:ToCellFromGridSpace(eng.CellAssigned[1], eng.CellAssigned[2])
                brainGridInstance:RemoveReclaimingEngineer(brainCell, eng)
                eng.CellAssigned = false
            end

            if aiBrain:GetEconomyStoredRatio('MASS') > 0.95 then
                -- Combat is back to false so the engineer manager can assign things to the engineer
                eng.Combat = false
                self:PlatoonDisband()
            end

            WaitTicks(100)
        end
    end,

    CommanderInitialBOAI = function(self)
        -- This is an adaptive initial build order function for the ACU
        -- Fully scripted with decision points
        -- Takes into account maps where the spawn location is very close to the map border (think theta passage)

        -- The small build logic code loop should be put into a utility function rather than repeating it.

        local aiBrain = self:GetBrain()
        local buildingTmpl, buildingTmplFile, baseTmplFile, baseTmplDefault, templateKey
        local whatToBuild
        local hydroPresent = false
        local buildLocation = false
        local buildMassPoints = {}
        local buildMassDistantPoints = {}
        local playableArea = ScenarioInfo.PlayableArea or {0, 0, ScenarioInfo.size[1], ScenarioInfo.size[2]}
        local borderWarning = false
        local factionIndex = aiBrain:GetFactionIndex()
        local platoonUnits = self:GetPlatoonUnits()
        local eng
        for _, v in platoonUnits do
            if not v.Dead and EntityCategoryContains(categories.ENGINEER, v) then
                IssueToUnitClearCommands(v)
                if not eng then
                    eng = v
                end
            end
        end
        -- Setting flags on the ACU to stop other threads from disbanding its platoon
        eng.Combat = true
        eng.Initializing = true
        -- Small note on the base template file. This is using a custom one so the acu doesnt try to select 
        -- a build location that causes it to move from its spawn position. But there are maps where it wont quite work and he'll move.
        if factionIndex < 5 then
            templateKey = 'ACUBaseTemplate'
            baseTmplFile = import(self.PlatoonData.Construction.BaseTemplateFile or '/lua/BaseTemplates.lua')
        else
            templateKey = 'BaseTemplates'
            baseTmplFile = import('/lua/BaseTemplates.lua')
        end
        baseTmplDefault = import('/lua/BaseTemplates.lua')
        buildingTmplFile = import(self.PlatoonData.Construction.BuildingTemplateFile or '/lua/BuildingTemplates.lua')
        buildingTmpl = buildingTmplFile[('BuildingTemplates')][factionIndex]
        -- This is where we would want to have personality modifiers being setup.
        -- Putting the acu into a statemachine after this would allow some interesting personality based long term build outs.
        -- For now we'll just use the personality that the FirstBaseFunction might spit out (check AIBaseTemplates for more info).
        local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        local NavUtils = import("/lua/sim/navutils.lua")
        local engPos = eng:GetPosition()
        local massMarkers = import("/lua/sim/markerutilities.lua").GetMarkersByType('Mass')
        local closeMarkers = 0
        local distantMarkers = 0
        -- Create mass point tables for points within build range and points outside of build range.
        for _, marker in massMarkers do
            if VDist2Sq(marker.position[1], marker.position[3],engPos[1], engPos[3]) < 165 and NavUtils.CanPathTo('Amphibious', engPos, marker.position) then
                closeMarkers = closeMarkers + 1
                table.insert(buildMassPoints, marker)
                if closeMarkers > 3 then
                    break
                end
            elseif VDist2Sq(marker.position[1], marker.position[3],engPos[1], engPos[3]) < 484 and NavUtils.CanPathTo('Amphibious', engPos, marker.position) then
                distantMarkers = distantMarkers + 1
                table.insert(buildMassDistantPoints, marker)
                if distantMarkers > 3 then
                    break
                end
            end
        end
        -- Check if there is a hydrocarbon marker within 65 units. The distance is based on the open palms hydro distance from spawn if your wondering.
        -- 65 units can be far if the hydro is behind the spawn point, we could check angles if we are thinking of alternatives.
        local closestHydro = AIUtils.GetResourceMarkerWithinRadius(aiBrain, engPos, 'Hydrocarbon', 65, false, false, false)
        if closestHydro and NavUtils.CanPathTo('Amphibious', engPos, closestHydro.Position) then
            hydroPresent = true
        end
        -- Check if we spawned in water. In which case we want a naval factory first up, and hope for the best.
        local inWater = GetTerrainHeight(engPos[1], engPos[3]) < GetSurfaceHeight(engPos[1], engPos[3])
        if inWater then
            buildLocation, whatToBuild, borderWarning = AIUtils.GetBuildLocation(aiBrain, buildingTmpl, baseTmplFile[templateKey][factionIndex], 'T1SeaFactory', eng, false, nil, nil, true)
        else
            -- If our personality is rushair then we will go air first else land.
            if personality ==  'rushair' then
                buildLocation, whatToBuild, borderWarning = AIUtils.GetBuildLocation(aiBrain, buildingTmpl, baseTmplFile[templateKey][factionIndex], 'T1AirFactory', eng, false, nil, nil, true)
            else
                buildLocation, whatToBuild, borderWarning = AIUtils.GetBuildLocation(aiBrain, buildingTmpl, baseTmplFile[templateKey][factionIndex], 'T1LandFactory', eng, false, nil, nil, true)
            end
        end
        if borderWarning and buildLocation and whatToBuild then
            IssueBuildMobile({eng}, {buildLocation[1],GetTerrainHeight(buildLocation[1], buildLocation[2]),buildLocation[2]}, whatToBuild, {})
            borderWarning = false
        elseif buildLocation and whatToBuild then
            aiBrain:BuildStructure(eng, whatToBuild, buildLocation, false)
        else
            WARN('No buildLocation or whatToBuild during ACU initialization')
        end
        -- First factory is up, now we queue any close mass points, there is an upper limit of 4 so we don't stall our power
        -- if we have no close mass points we will look at more distant ones (22 units max)
        if next(buildMassPoints) then
            whatToBuild = aiBrain:DecideWhatToBuild(eng, 'T1Resource', buildingTmpl)
            for k, v in buildMassPoints do
                if v.position[1] - playableArea[1] <= 8 or v.position[1] >= playableArea[3] - 8 or v.position[3] - playableArea[2] <= 8 or v.position[3] >= playableArea[4] - 8 then
                    borderWarning = true
                end
                if borderWarning and v.position and whatToBuild then
                    IssueBuildMobile({eng}, v.position, whatToBuild, {})
                    borderWarning = false
                elseif buildLocation and whatToBuild then
                    aiBrain:BuildStructure(eng, whatToBuild, {v.position[1], v.position[3], 0}, false)
                else
                    WARN('No buildLocation or whatToBuild during ACU initialization')
                end
                aiBrain:BuildStructure(eng, whatToBuild, {v.position[1], v.position[3], 0}, false)
                buildMassPoints[k] = nil
                break
            end
            buildMassPoints = aiBrain:RebuildTable(buildMassPoints)
        elseif next(buildMassDistantPoints) then
            whatToBuild = aiBrain:DecideWhatToBuild(eng, 'T1Resource', buildingTmpl)
            for k, v in buildMassDistantPoints do
                IssueToUnitMove(eng, v.position )
                while VDist2Sq(engPos[1],engPos[3],v.position[1],v.position[3]) > 165 do
                    coroutine.yield(5)
                    engPos = eng:GetPosition()
                    if eng:IsIdleState() and VDist2Sq(engPos[1],engPos[3],v.position[1],v.position[3]) > 165 then
                        break
                    end
                end
                IssueToUnitClearCommands(eng)
                if v.position[1] - playableArea[1] <= 8 or v.position[1] >= playableArea[3] - 8 or v.position[3] - playableArea[2] <= 8 or v.position[3] >= playableArea[4] - 8 then
                    borderWarning = true
                end
                if borderWarning and v.position and whatToBuild then
                    IssueBuildMobile({eng}, v.position, whatToBuild, {})
                    borderWarning = false
                elseif buildLocation and whatToBuild then
                    aiBrain:BuildStructure(eng, whatToBuild, {v.position[1], v.position[3], 0}, false)
                else
                    WARN('No buildLocation or whatToBuild during ACU initialization')
                end
                buildMassDistantPoints[k] = nil
                break
            end
            buildMassDistantPoints = aiBrain:RebuildTable(buildMassDistantPoints)
        end
        -- Wait for everything to be built
        coroutine.yield(5)
        while eng:IsUnitState('Building') or 0<table.getn(eng:GetCommandQueue()) do
            coroutine.yield(5)
        end
        -- If we found a hydro marker then we are going to just queue a few pgens
        -- mainly incase something goes wrong and no engineer goes to build a hydro
        if hydroPresent then
            buildLocation, whatToBuild, borderWarning = AIUtils.GetBuildLocation(aiBrain, buildingTmpl, baseTmplDefault['BaseTemplates'][factionIndex], 'T1EnergyProduction', eng, true, categories.STRUCTURE * categories.FACTORY, 12, true)
            if borderWarning and buildLocation and whatToBuild then
                IssueBuildMobile({eng}, {buildLocation[1],GetTerrainHeight(buildLocation[1], buildLocation[2]),buildLocation[2]}, whatToBuild, {})
                borderWarning = false
            elseif buildLocation and whatToBuild then
                aiBrain:BuildStructure(eng, whatToBuild, buildLocation, false)
            else
                WARN('No buildLocation or whatToBuild during ACU initialization')
            end
        else
            for i=1, 2 do
                buildLocation, whatToBuild, borderWarning = AIUtils.GetBuildLocation(aiBrain, buildingTmpl, baseTmplDefault['BaseTemplates'][factionIndex], 'T1EnergyProduction', eng, true, categories.STRUCTURE * categories.FACTORY, 12, true)
                if borderWarning and buildLocation and whatToBuild then
                    IssueBuildMobile({eng}, {buildLocation[1],GetTerrainHeight(buildLocation[1], buildLocation[2]),buildLocation[2]}, whatToBuild, {})
                    borderWarning = false
                elseif buildLocation and whatToBuild then
                    aiBrain:BuildStructure(eng, whatToBuild, buildLocation, false)
                else
                    WARN('No buildLocation or whatToBuild during ACU initialization')
                end
            end
        end
        -- queue the rest of the mass points, if there are more than 2 close mass points we will only do a couple
        -- so that we can build more power should we have no hydro available, if they are distant then
        -- we won't build pgens during this phase as we don't know how long it might take to build the extractors
        if next(buildMassPoints) then
            whatToBuild = aiBrain:DecideWhatToBuild(eng, 'T1Resource', buildingTmpl)
            if table.getn(buildMassPoints) < 3 then
                for k, v in buildMassPoints do
                    if v.position[1] - playableArea[1] <= 8 or v.position[1] >= playableArea[3] - 8 or v.position[3] - playableArea[2] <= 8 or v.position[3] >= playableArea[4] - 8 then
                        borderWarning = true
                    end
                    if borderWarning and v.position and whatToBuild then
                        IssueBuildMobile({eng}, v.position, whatToBuild, {})
                        borderWarning = false
                    elseif buildLocation and whatToBuild then
                        aiBrain:BuildStructure(eng, whatToBuild, {v.position[1], v.position[3], 0}, false)
                    else
                        WARN('No buildLocation or whatToBuild during ACU initialization')
                    end
                    buildMassPoints[k] = nil
                end
                buildMassPoints = aiBrain:RebuildTable(buildMassPoints)
            else
                for i=1, 2 do
                    if buildMassPoints[i].position[1] - playableArea[1] <= 8 or buildMassPoints[i].position[1] >= playableArea[3] - 8 or buildMassPoints[i].position[3] - playableArea[2] <= 8 or buildMassPoints[i].position[3] >= playableArea[4] - 8 then
                        borderWarning = true
                    end
                    if borderWarning and buildMassPoints[i].position and whatToBuild then
                        IssueBuildMobile({eng}, buildMassPoints[i].position, whatToBuild, {})
                        borderWarning = false
                    elseif buildMassPoints[i].Position and whatToBuild then
                        aiBrain:BuildStructure(eng, whatToBuild, {buildMassPoints[i].position[1], buildMassPoints[i].position[3], 0}, false)
                    else
                        WARN('No buildLocation or whatToBuild during ACU initialization')
                    end
                    aiBrain:BuildStructure(eng, whatToBuild, {buildMassPoints[i].position[1], buildMassPoints[i].position[3], 0}, false)
                    buildMassPoints[i] = nil
                end
                buildMassPoints = aiBrain:RebuildTable(buildMassPoints)
                buildLocation, whatToBuild, borderWarning = AIUtils.GetBuildLocation(aiBrain, buildingTmpl, baseTmplDefault['BaseTemplates'][factionIndex], 'T1EnergyProduction', eng, true, categories.STRUCTURE * categories.FACTORY, 12, true)
                if borderWarning and buildLocation and whatToBuild then
                    IssueBuildMobile({eng}, {buildLocation[1],GetTerrainHeight(buildLocation[1], buildLocation[2]),buildLocation[2]}, whatToBuild, {})
                    borderWarning = false
                elseif buildLocation and whatToBuild then
                    aiBrain:BuildStructure(eng, whatToBuild, buildLocation, false)
                else
                    WARN('No buildLocation or whatToBuild during ACU initialization')
                end
                if table.getn(buildMassPoints) < 2 then
                    whatToBuild = aiBrain:DecideWhatToBuild(eng, 'T1Resource', buildingTmpl)
                    for k, v in buildMassPoints do
                        if v.position[1] - playableArea[1] <= 8 or v.position[1] >= playableArea[3] - 8 or v.position[3] - playableArea[2] <= 8 or v.position[3] >= playableArea[4] - 8 then
                            borderWarning = true
                        end
                        if borderWarning and v.position and whatToBuild then
                            IssueBuildMobile({eng}, v.position, whatToBuild, {})
                            borderWarning = false
                        elseif v.position and whatToBuild then
                            aiBrain:BuildStructure(eng, whatToBuild, {v.position[1], v.position[3], 0}, false)
                        else
                            WARN('No buildLocation or whatToBuild during ACU initialization')
                        end
                        buildMassPoints[k] = nil
                    end
                    buildMassPoints = aiBrain:RebuildTable(buildMassPoints)
                end
            end
        elseif table.getn(buildMassDistantPoints) > 0 then
            whatToBuild = aiBrain:DecideWhatToBuild(eng, 'T1Resource', buildingTmpl)
            if table.getn(buildMassDistantPoints) < 3 then
                for k, v in buildMassDistantPoints do
                    if aiBrain:CanBuildStructureAt('ueb1103', v.position) then
                        IssueToUnitMove(eng, v.position )
                        while VDist2Sq(engPos[1],engPos[3],v.position[1],v.position[3]) > 165 do
                            coroutine.yield(5)
                            engPos = eng:GetPosition()
                            if eng:IsIdleState() and VDist2Sq(engPos[1],engPos[3],v.position[1],v.position[3]) > 165 then
                                break
                            end
                        end
                        IssueToUnitClearCommands(eng)
                        if v.position[1] - playableArea[1] <= 8 or v.position[1] >= playableArea[3] - 8 or v.position[3] - playableArea[2] <= 8 or v.position[3] >= playableArea[4] - 8 then
                            borderWarning = true
                        end
                        if borderWarning and v.position and whatToBuild then
                            IssueBuildMobile({eng}, v.position, whatToBuild, {})
                            borderWarning = false
                        elseif v.position and whatToBuild then
                            aiBrain:BuildStructure(eng, whatToBuild, {v.position[1], v.position[3], 0}, false)
                        else
                            WARN('No buildLocation or whatToBuild during ACU initialization')
                        end
                        coroutine.yield(5)
                        while eng:IsUnitState('Building') or 0<table.getn(eng:GetCommandQueue()) do
                            coroutine.yield(5)
                        end
                    end
                    buildMassDistantPoints[k] = nil
                end
                buildMassDistantPoints = aiBrain:RebuildTable(buildMassDistantPoints)
            end
        end
        -- wait for the build queue to complete
        coroutine.yield(5)
        while eng:IsUnitState('Building') or 0<table.getn(eng:GetCommandQueue()) do
            coroutine.yield(5)
        end
        -- if we still have close mass points to build then we'll queue them.
        -- Then we try to work out how many pgens we'll need to not stall anything if a hydro isnt present and queue them up.
        if next(buildMassPoints) then
            whatToBuild = aiBrain:DecideWhatToBuild(eng, 'T1Resource', buildingTmpl)
            for k, v in buildMassPoints do
                if v.position[1] - playableArea[1] <= 8 or v.position[1] >= playableArea[3] - 8 or v.position[3] - playableArea[2] <= 8 or v.position[3] >= playableArea[4] - 8 then
                    borderWarning = true
                end
                if borderWarning and v.position and whatToBuild then
                    IssueBuildMobile({eng}, v.position, whatToBuild, {})
                    borderWarning = false
                elseif v.position and whatToBuild then
                    aiBrain:BuildStructure(eng, whatToBuild, {v.position[1], v.position[3], 0}, false)
                else
                    WARN('No buildLocation or whatToBuild during ACU initialization')
                end
                buildMassPoints[k] = nil
            end
            coroutine.yield(5)
            while eng:IsUnitState('Building') or 0<table.getn(eng:GetCommandQueue()) do
                coroutine.yield(5)
            end
        end
        local energyCount = 3
        if not hydroPresent then
            IssueToUnitClearCommands(eng)
            if closeMarkers > 0 then
                if closeMarkers < 4 then
                    if closeMarkers < 4 and distantMarkers > 1 then
                        energyCount = 3
                    else
                        energyCount = 2
                    end
                else
                    energyCount = 3
                end
                
            end
            for i=1, energyCount do
                buildLocation, whatToBuild, borderWarning = AIUtils.GetBuildLocation(aiBrain, buildingTmpl, baseTmplDefault['BaseTemplates'][factionIndex], 'T1EnergyProduction', eng, true, categories.STRUCTURE * categories.FACTORY, 12, true)
                if buildLocation and whatToBuild then
                    if borderWarning and buildLocation and whatToBuild then
                        IssueBuildMobile({eng}, {buildLocation[1],GetTerrainHeight(buildLocation[1], buildLocation[2]),buildLocation[2]}, whatToBuild, {})
                        borderWarning = false
                    elseif buildLocation and whatToBuild then
                        aiBrain:BuildStructure(eng, whatToBuild, buildLocation, false)
                    else
                        WARN('No buildLocation or whatToBuild during ACU initialization')
                    end
                else
                    -- This is a backup to avoid a power stall should the GetBuildLocation fail with adjacency
                    buildLocation, whatToBuild, borderWarning = AIUtils.GetBuildLocation(aiBrain, buildingTmpl, baseTmplDefault['BaseTemplates'][factionIndex], 'T1EnergyProduction', eng, false, categories.STRUCTURE * categories.FACTORY, 12, true)
                    if borderWarning and buildLocation and whatToBuild then
                        IssueBuildMobile({eng}, {buildLocation[1],GetTerrainHeight(buildLocation[1], buildLocation[2]),buildLocation[2]}, whatToBuild, {})
                        borderWarning = false
                    elseif buildLocation and whatToBuild then
                        aiBrain:BuildStructure(eng, whatToBuild, buildLocation, false)
                    else
                        WARN('No buildLocation or whatToBuild during ACU initialization')
                    end
                end
            end
        end
        -- If there is no hydro and we had enough mass points to support a second land factory this is where we build it
        if not hydroPresent and closeMarkers > 3 then
            buildLocation, whatToBuild, borderWarning = AIUtils.GetBuildLocation(aiBrain, buildingTmpl, baseTmplDefault['BaseTemplates'][factionIndex], 'T1LandFactory', eng, true, categories.MASSEXTRACTION, 15, true)
            if borderWarning and buildLocation and whatToBuild then
                IssueBuildMobile({eng}, {buildLocation[1],GetTerrainHeight(buildLocation[1], buildLocation[2]),buildLocation[2]}, whatToBuild, {})
                borderWarning = false
            elseif buildLocation and whatToBuild then
                aiBrain:BuildStructure(eng, whatToBuild, buildLocation, false)
            else
                WARN('No buildLocation or whatToBuild during ACU initialization')
            end
        end
        -- wait for the build to complete
        if not hydroPresent then
            while eng:IsUnitState('Building') or 0<table.getn(eng:GetCommandQueue()) do
                coroutine.yield(5)
            end
        end
        -- if we had a hydro and we also had mass points we will walk to it then try find an engineer that might be building it
        -- we will assist that engineer until the hydro is finished
        -- If no engineer is building a hydro the acu will wait for a while to give an engineer a chance.
        -- Note the builder manager that the engineer came from must be called MAIN
        if hydroPresent and (closeMarkers > 0 or distantMarkers > 0) then
            engPos = eng:GetPosition()
            if VDist3Sq(engPos,closestHydro.Position) > 144 then
                IssueToUnitMove(eng, closestHydro.Position )
                while VDist3Sq(engPos,closestHydro.Position) > 100 do
                    coroutine.yield(5)
                    engPos = eng:GetPosition()
                    if eng:IsIdleState() and VDist3Sq(engPos,closestHydro.Position) > 100 then
                        break
                    end
                end
            end
            IssueToUnitClearCommands(eng)
            local assistList = AIUtils.GetAssistees(aiBrain, 'MAIN', 'Engineer', categories.HYDROCARBON, categories.ALLUNITS)
            local assistee = false
            local assistListCount = 0
            while not next(assistList) do
                coroutine.yield( 15 )
                assistList = AIUtils.GetAssistees(aiBrain, 'MAIN', 'Engineer', categories.HYDROCARBON, categories.ALLUNITS)
                assistListCount = assistListCount + 1
                if assistListCount > 10 then
                    break
                end
            end
            if next(assistList) then
                -- we have something in the assistList
                local low = false
                local bestUnit = false
                for k,v in assistList do
                    local unitPos = v:GetPosition()
                    local UnitAssist = v.UnitBeingBuilt or v.UnitBeingAssist or v
                    local NumAssist = table.getn(UnitAssist:GetGuards())
                    local dist = VDist2Sq(engPos[1], engPos[3], unitPos[1], unitPos[3])
                    -- Find the closest unit to assist
                    if (not low or dist < low) and NumAssist < 20 and dist < 225 then
                        low = dist
                        bestUnit = v
                    end
                end
                assistee = bestUnit
            end
            if assistee  then
                IssueToUnitClearCommands(eng)
                eng.UnitBeingAssist = assistee.UnitBeingBuilt or assistee.UnitBeingAssist or assistee
                IssueGuard({eng}, eng.UnitBeingAssist)
                coroutine.yield(30)
                while eng and not eng.Dead and not eng:IsIdleState() do
                    if not eng.UnitBeingAssist or eng.UnitBeingAssist.Dead or eng.UnitBeingAssist:BeenDestroyed() then
                        break
                    end
                    -- stop if our target is finished
                    if eng.UnitBeingAssist:GetFractionComplete() == 1 and not eng.UnitBeingAssist:IsUnitState('Upgrading') then
                        IssueToUnitClearCommands(eng)
                        break
                    end
                    coroutine.yield(30)
                end
                -- the hydro should be finished, now we will try build an adjacent air factory if the map is 20km or larger or this is the rush air personality.
                -- otherwise build another land first then an air factory, try to make them adjacent but it gets a little tricky here without having the move the acu
                -- we do a quick storage check to make sure we can afford at least half a factory if we had a low count of mass markers.
                if ((closeMarkers + distantMarkers > 2) or (closeMarkers + distantMarkers > 1 and aiBrain:GetEconomyStored('MASS') > 120)) and eng.UnitBeingAssist:GetFractionComplete() == 1 then
                    if (playableArea[3] > 512 or playableArea[4] > 512) or personality == 'rushair' then
                        buildLocation, whatToBuild, borderWarning = AIUtils.GetBuildLocation(aiBrain, buildingTmpl, baseTmplDefault['BaseTemplates'][factionIndex], 'T1AirFactory', eng, true, categories.HYDROCARBON, 15, true)
                        if borderWarning and buildLocation and whatToBuild then
                            IssueBuildMobile({eng}, {buildLocation[1],GetTerrainHeight(buildLocation[1], buildLocation[2]),buildLocation[2]}, whatToBuild, {})
                            borderWarning = false
                        elseif buildLocation and whatToBuild then
                            aiBrain:BuildStructure(eng, whatToBuild, buildLocation, false)
                        else
                            WARN('No buildLocation or whatToBuild during ACU initialization')
                        end
                    else
                        buildLocation, whatToBuild, borderWarning = AIUtils.GetBuildLocation(aiBrain, buildingTmpl, baseTmplDefault['BaseTemplates'][factionIndex], 'T1LandFactory', eng, true, categories.HYDROCARBON, 15, true)
                        if borderWarning and buildLocation and whatToBuild then
                            IssueBuildMobile({eng}, {buildLocation[1],GetTerrainHeight(buildLocation[1], buildLocation[2]),buildLocation[2]}, whatToBuild, {})
                            borderWarning = false
                        elseif buildLocation and whatToBuild then
                            aiBrain:BuildStructure(eng, whatToBuild, buildLocation, false)
                        else
                            WARN('No buildLocation or whatToBuild during ACU initialization')
                        end
                        if playableArea[3] > 256 or playableArea[4] > 256 and aiBrain:GetEngineerManagerUnitsBeingBuilt(categories.FACTORY * categories.AIR) < 1 and aiBrain:GetCurrentUnits(categories.FACTORY * categories.AIR) < 1 then
                            buildLocation, whatToBuild, borderWarning = AIUtils.GetBuildLocation(aiBrain, buildingTmpl, baseTmplDefault['BaseTemplates'][factionIndex], 'T1AirFactory', eng, true, categories.HYDROCARBON, 25, true)
                            if borderWarning and buildLocation and whatToBuild then
                                IssueBuildMobile({eng}, {buildLocation[1],GetTerrainHeight(buildLocation[1], buildLocation[2]),buildLocation[2]}, whatToBuild, {})
                                borderWarning = false
                            elseif buildLocation and whatToBuild then
                                aiBrain:BuildStructure(eng, whatToBuild, buildLocation, false)
                            else
                                WARN('No buildLocation or whatToBuild during ACU initialization')
                            end
                        end
                    end
                    while eng:IsUnitState('Building') or 0<table.getn(eng:GetCommandQueue()) do
                        coroutine.yield(5)
                    end
                end
            end
        end
        eng.Combat = false
        eng.Initializing = false
        self:PlatoonDisband()
    end,

    StateMachineAI = function(self)
        local machineType = self.PlatoonData.StateMachine

        if machineType == 'AIPlatoonAdaptiveRaidBehavior' then
            import("/lua/aibrains/platoons/platoon-adaptive-raid.lua").AssignToUnitsMachine({ }, self, self:GetPlatoonUnits())
        elseif machineType == 'AIPlatoonAdaptiveReclaimBehavior' then
            import("/lua/aibrains/platoons/platoon-adaptive-reclaim.lua").AssignToUnitsMachine({ }, self, self:GetPlatoonUnits())
        elseif machineType == 'AIPlatoonAdaptiveAttackBehavior' then
            import("/lua/aibrains/platoons/platoon-adaptive-attack.lua").AssignToUnitsMachine({ }, self, self:GetPlatoonUnits())
        elseif machineType == 'AIPlatoonAdaptiveGuardBehavior' then
            import("/lua/aibrains/platoons/platoon-adaptive-guard.lua").AssignToUnitsMachine({ }, self, self:GetPlatoonUnits())
        end

        WaitTicks(50)

    end,
}

-- backwards compatibility with mods

local UnitUpgradeTemplates = UpgradeTemplates.UnitUpgradeTemplates
local StructureUpgradeTemplates = UpgradeTemplates.StructureUpgradeTemplates