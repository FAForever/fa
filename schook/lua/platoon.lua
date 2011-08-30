#****************************************************************************
#**
#**  File     :  /lua/platoon.lua
#**  Author(s): Drew Staltman, Robert Oates, Gautam Vasudevan, Daniel Teh?, ...?
#**
#**  Summary  :
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
#########################################
# Platoon Lua Module                    #
#########################################
local AIUtils = import('ai/aiutilities.lua')
local Utilities = import('/lua/utilities.lua')
local AIBuildStructures = import('/lua/ai/aibuildstructures.lua')
local UnitUpgradeTemplates = import('/lua/upgradetemplates.lua').UnitUpgradeTemplates
local StructureUpgradeTemplates = import('/lua/upgradetemplates.lua').StructureUpgradeTemplates
local Behaviors = import('/lua/ai/aibehaviors.lua')
local AIAttackUtils = import('/lua/AI/aiattackutilities.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local SPAI = import('/lua/ScenarioPlatoonAI.lua')

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
        # Because of how the PlatoonData in the editor exports table.getn will not work here
        if self.PlatoonData.AMPlatoons then
            for k,v in self.PlatoonData.AMPlatoons do
                platoonsGiven = true
                if not aiBrain.AttackData.AMPlatoonCount[v] then
                    aiBrain.AttackData.AMPlatoonCount[v] = 1
                else
                    aiBrain.AttackData.AMPlatoonCount[v] = aiBrain.AttackData.AMPlatoonCount[v] + 1
                end
            end
        end
        if not platoonsGiven then
            local testUnit = self:GetPlatoonUnits()[1]
            if testUnit then
                self.PlatoonData.AMPlatoons = {}
                if EntityCategoryContains( categories.MOBILE * categories.AIR, testUnit ) then
                    aiBrain.AttackData.AMPlatoonCount['DefaultGroupAir'] = aiBrain.AttackData.AMPlatoonCount['DefaultGroupAir'] + 1
                    table.insert( self.PlatoonData.AMPlatoons, 'DefaultGroupAir' )

                elseif EntityCategoryContains( categories.MOBILE * categories.LAND, testUnit ) then
                    aiBrain.AttackData.AMPlatoonCount['DefaultGroupLand'] = aiBrain.AttackData.AMPlatoonCount['DefaultGroupLand'] + 1
                    table.insert( self.PlatoonData.AMPlatoons, 'DefaultGroupLand' )

                elseif EntityCategoryContains( categories.MOBILE * categories.NAVAL, testUnit ) then
                    aiBrain.AttackData.AMPlatoonCount['DefaultGroupSea'] = aiBrain.AttackData.AMPlatoonCount['DefaultGroupSea'] + 1
                    table.insert( self.PlatoonData.AMPlatoons, 'DefaultGroupSea' )
                end
            end
        end
        self:AddDestroyCallback(aiBrain.AMDecrementCount)
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
        if self.AIThread ~= nil then
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
            if not v:IsDead() then
                v.PlatoonHandle = self
            end 
        end
    end,
    
    PlatoonDisband = function(self)
        #LOG('*AI DEBUG: Platoon Disbanding - ' .. self.BuilderName )
        if self.BuilderHandle then
            self.BuilderHandle:RemoveHandle(self)
        end
        for k,v in self:GetPlatoonUnits() do
            v.PlatoonHandle = nil
            if not v:IsDead() and v.BuilderManagerData then
                if self.CreationTime == GetGameTimeSeconds() and v.BuilderManagerData.EngineerManager then
                    if self.BuilderName then
                        #LOG('*AI DEBUG: ERROR - Platoon disbanded same tick as created - ' .. self.BuilderName .. ' - Army: ' .. self:GetBrain():GetArmyIndex() .. ' - Location: ' .. v.BuilderManagerData.LocationType )
                        v.BuilderManagerData.EngineerManager:AssignTimeout(v, self.BuilderName)
                    else
                        #LOG('*AI DEBUG: ERROR - Platoon disbanded same tick as created - Army: ' .. self:GetBrain():GetArmyIndex() .. ' - Location: ' .. v.BuilderManagerData.LocationType )
                    end
                    v.BuilderManagerData.EngineerManager:DelayAssign(v)
                elseif v.BuilderManagerData.EngineerManager then
                    v.BuilderManagerData.EngineerManager:TaskFinished(v)
                end
            end
        end
        self:GetBrain():DisbandPlatoon(self)
    end,
    
    GetPlatoonThreat = function(self, threatType, unitCategory, position, radius)
        local threat = 0
        if position then
            threat = self:CalculatePlatoonThreatAroundPosition( threatType, unitCategory, position, radius )
        else
            threat = self:CalculatePlatoonThreat( threatType, unitCategory )
        end
        return threat
    end,
    
    GetUnitsAroundPoint = function(self, category, point, radius)
        local units = {}
        for k,v in self:GetPlatoonUnits() do
        
            # Wrong unit type
            if not EntityCategoryContains( category, v ) then
                continue
            end
            
            # Too far away
            if Utilities.XZDistanceTwoVectors( v:GetPosition(), point ) > radius then
                continue
            end
            
            table.insert( units, v )
        end
        return units
    end,
    
    GetNumCategoryUnits = function(self, category, position, radius)
        local numUnits = 0
        if position then
            numUnits = self:PlatoonCategoryCountAroundPosition( category, position, radius )
        else
            numUnits = self:PlatoonCategoryCount( category )
        end
        return numUnits
    end,

    # ===== AI THREADS ===== #
    BuildOnceAI = function(self)
        local aiBrain = self:GetBrain()
        for k,v in self:GetPlatoonUnits() do
            if not v:IsDead() then
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
        for k,v in self:GetPlatoonUnits() do
            unit = v
            break
        end
        if unit then
            IssueStop({unit})
            IssueClearCommands({unit})
            for k,v in data.Enhancement do
                local order = {
                    TaskName = "EnhanceTask",
                    Enhancement = v
                }
                IssueScript({unit}, order)
            end
            WaitSeconds(data.TimeBetweenEnhancements or 1)
            repeat
                WaitSeconds(5)
                if not aiBrain:PlatoonExists(self) then
                    return
                end
            until unit:IsDead() or not unit:IsUnitState('Upgrading')
        end
        if data.DoNotDisband then return end
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
                    self:AggressiveMoveToLocation( table.copy(target:GetPosition()) )
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
        
        #GET THE Launcher OUT OF THIS PLATOON
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
        local atkPri = { 'COMMAND', 'STRUCTURE STRATEGIC', 'STRUCTURE DEFENSE', 'CONSTRUCTION', 'EXPERIMENTAL MOBILE LAND', 'TECH3 MOBILE LAND',
            'TECH2 MOBILE LAND', 'TECH1 MOBILE LAND', 'ALLUNITS' }
        self:SetPrioritizedTargetList( 'Attack', { categories.COMMAND, categories.CONSTRUCTION, categories.STRUCTURE * categories.DEFENSE,
            categories.EXPERIMENTAL * categories.MOBILE, categories.TECH3 * categories.MOBILE, categories.TECH2 * categories.MOBILE,
            categories.TECH1 * categories.MOBILE, categories.ALLUNITS } )
        while aiBrain:PlatoonExists(self) do
            local target = false
            local blip = false
            while unit:GetTacticalSiloAmmoCount() < 1 or not target do
                WaitSeconds(7)
                target = false
                while not target do
                    if aiBrain:GetCurrentEnemy() and aiBrain:GetCurrentEnemy():IsDefeated() then
                        aiBrain:PickEnemyLogic()
                    end

                    target = AIUtils.AIFindBrainTargetInRange( aiBrain, self, 'Attack', maxRadius, atkPri, aiBrain:GetCurrentEnemy() )

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
            if not target:IsDead() then
                #LOG('*AI DEBUG: Firing Tactical Missile at enemy swine!')
                IssueTactical({unit}, target)
            end
            WaitSeconds(3)
        end
    end,

    NukeAI = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local platoonUnits = self:GetPlatoonUnits()
        local unit
        #GET THE Launcher OUT OF THIS PLATOON
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
                    WaitSeconds( 11 )
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
        #GET THE AntiNuke OUT OF THIS PLATOON
        for k, v in platoonUnits do
            if EntityCategoryContains(categories.STRUCTURE * categories.ANTIMISSILE * categories.TECH3, v) then
                antiNuke = v
                break
            end
        end
        # Toggle on auto build
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
    
   
    #-----------------------------------------------------
    #   Function: ExperimentalAIHub
    #   Args:
    #       self - the single-experimental platoon to run the AI on
    #   Description:
    #       If set as a platoon's AI function, will select an appropriate behavior based on the unit type.
    #   Returns:  
    #       nil (tail calls into a behavior function)
    #-----------------------------------------------------
    ExperimentalAIHub = function(self)
	    local behaviors = import('/lua/ai/AIBehaviors.lua')
	    
	    local experimental = self:GetPlatoonUnits()[1]
	    if not experimental then
		    return
	    end
        local ID = experimental:GetUnitId()
        
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
    
    #-----------------------------------------------------
    #   Function: GuardEngineer
    #   Args:
    #       platoon - platoon to run the AI
    #       function [opt] - AI function to run when done guarding
    #       bool [opt] - if true, forces a platoon's units to disband and guard a base forever
    #   Description:
    #       Provides logic for platoons to guard expansion areas and engineers.
    #   Returns:  
    #       nil (tail calls into the nextAIFunc or itself)
    #-----------------------------------------------------
    GuardEngineer = function(self, nextAIFunc, forceGuardBase)
        local aiBrain = self:GetBrain()
        
        if not aiBrain:PlatoonExists(self) or not self:GetPlatoonPosition() then
            return
        end
        
        local renderThread = false
        AIAttackUtils.GetMostRestrictiveLayer(self)
        
        if forceGuardBase or not self.PlatoonData.NeverGuardBases then    
            #Guard the closest least-defended base
            local bestBase = false
            local bestBaseName = ""
            local bestDistSq = 999999999
            local bestDefense = 999999999
            
            local MAIN = aiBrain.BuilderManagers.MAIN
            
            local threatType = 'AntiSurface'
            for baseName, base in aiBrain.BuilderManagers do
                if baseName ~= 'MAIN' and (base.BaseSettings and not base.BaseSettings.NoGuards) then
                    
                    if AIAttackUtils.GetSurfaceThreatOfUnits(self) <= 0 then
                        threatType = 'StructuresNotMex'
                    end
                    
                    local baseDefense = aiBrain:GetThreatAtPosition( base.Position, 1, true, threatType, aiBrain:GetArmyIndex() )
                    
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

                IssueGuard( self:GetPlatoonUnits(), bestBase.Position )
                #self:MoveToLocation(bestBase.Position, false)  
                
                #Handle base guarding logic in this loop
                local guardTime = 0
                while aiBrain:PlatoonExists(self) do
                    #Is the threat of this base good enough?
                    if not forceGuardBase then
                        local rnd = Random(13,17)
                        WaitSeconds(rnd)
                        guardTime = guardTime + rnd
                        
                        if (aiBrain:GetThreatAtPosition( bestBase.Position, 1, true, threatType, aiBrain:GetArmyIndex() ) >= threshold + self:GetPlatoonThreatEx().SurfaceThreatLevel 
                        or (self.PlatoonData.BaseGuardTimeLimit and guardTime > self.PlatoonData.BaseGuardTimeLimit)) then    
                            #Stop guarding and guard something else.
                            break
                        end
                    else
                        #Set to permanently guard a base, and we already received our move orders.
                        return
                    end
                end
            end
        end
               
        if not self.PlatoonData.NeverGuardEngineers then
            #Otherwise guard an engineer until it dies or our guard timer expires
            local unitToGuard = false
            local units = aiBrain:GetListOfUnits( categories.ENGINEER - categories.COMMAND, false )
            for k,v in units do
                if v.NeedGuard and not v.BeingGuarded then
                    unitToGuard = v
                    v.BeingGuarded = true
                end
            end
            
            local guardTime = 0
            if unitToGuard and not unitToGuard:IsDead() then
                IssueGuard(self:GetPlatoonUnits(), unitToGuard)
                
                while aiBrain:PlatoonExists(self) and not unitToGuard:IsDead() do
                    guardTime = guardTime + 5
                    WaitSeconds(5)
                    
                    if self.PlatoonData.EngineerGuardTimeLimit and guardTime >= self.PlatoonData.EngineerGuardTimeLimit 
                    or (not unitToGuard:IsDead() and unitToGuard:GetCurrentLayer() == 'Seabed' and self.MovementLayer == 'Land') then
                        break
                    end
                end
            end
                        
        end
        
        ##Tail call into the next ai function
        WaitSeconds(1)
        if type(nextAIFunc) == 'function' then
            return nextAIFunc(self)
        end
        
        return self:GuardEngineer(nextAIFunc, forceGuardBase)
    end,
    
          
    #-----------------------------------------------------
    #   Function: GuardMarker
    #   Args:
    #       platoon - platoon to run the AI
    #   Description:
    #       Will guard the location of a marker
    #   Returns:  
    #       nil
    #-----------------------------------------------------
    GuardMarker = function(self)
        local aiBrain = self:GetBrain()
        
        local platLoc = self:GetPlatoonPosition()        
        
        if not aiBrain:PlatoonExists(self) or not platLoc then
            return
        end
        
        #---------------------------------------------------------------------
        # Platoon Data
        #---------------------------------------------------------------------
        # type of marker to guard
        # Start location = 'Start Location'... see MarkerTemplates.lua for other types
        local markerType = self.PlatoonData.MarkerType or 'Expansion Area'

        # what should we look for for the first marker?  This can be 'Random',
        # 'Threat' or 'Closest'
        local moveFirst = self.PlatoonData.MoveFirst or 'Threat'
        
        # should our next move be no move be (same options as before) as well as 'None'
        # which will cause the platoon to guard the first location they get to
        local moveNext = self.PlatoonData.MoveNext or 'None'         

        # Minimum distance when looking for closest
        local avoidClosestRadius = self.PlatoonData.AvoidClosestRadius or 0        
        
        # set time to wait when guarding a location with moveNext = 'None'
        local guardTimer = self.PlatoonData.GuardTimer or 0
        
        # threat type to look at      
        local threatType = self.PlatoonData.ThreatType or 'AntiSurface'
        
        # should we look at our own threat or the enemy's
        local bSelfThreat = self.PlatoonData.SelfThreat or false
        
        # if true, look to guard highest threat, otherwise, 
        # guard the lowest threat specified                 
        local bFindHighestThreat = self.PlatoonData.FindHighestThreat or false 
        
        # minimum threat to look for
        local minThreatThreshold = self.PlatoonData.MinThreatThreshold or -1
        # maximum threat to look for
        local maxThreatThreshold = self.PlatoonData.MaxThreatThreshold  or 99999999
  
        # Avoid bases (true or false)
        local bAvoidBases = self.PlatoonData.AvoidBases or false
             
        # Radius around which to avoid the main base
        local avoidBasesRadius = self.PlatoonData.AvoidBasesRadius or 0
        
        # Use Aggresive Moves Only
        local bAggroMove = self.PlatoonData.AggressiveMove or false
        
        local PlatoonFormation = self.PlatoonData.UseFormation or 'NoFormation'
        #---------------------------------------------------------------------
         
           
        AIAttackUtils.GetMostRestrictiveLayer(self)
        self:SetPlatoonFormationOverride(PlatoonFormation)
        local markerLocations = AIUtils.AIGetMarkerLocations(aiBrain, markerType)
        
        local bestMarker = false
        
        if not self.LastMarker then
            self.LastMarker = {nil,nil}
        end
            
        # look for a random marker
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
            #Guard the closest least-defended marker
            local bestMarkerThreat = 0
            if not bFindHighestThreat then
                bestMarkerThreat = 99999999
            end
            
            local bestDistSq = 99999999
                      
             
            # find best threat at the closest distance
            for _,marker in markerLocations do
                local markerThreat
                if bSelfThreat then
                    markerThreat = aiBrain:GetThreatAtPosition( marker.Position, 0, true, threatType, aiBrain:GetArmyIndex())
                else
                    markerThreat = aiBrain:GetThreatAtPosition( marker.Position, 0, true, threatType)
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
            # if we didn't want random or threat, assume closest (but avoid ping-ponging)
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
        
        
        # did we find a threat?
        if bestMarker then
        	self.LastMarker[2] = self.LastMarker[1]
            self.LastMarker[1] = bestMarker.Position
            #LOG("GuardMarker: Attacking " .. bestMarker.Name)
            local path, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, self.MovementLayer, self:GetPlatoonPosition(), bestMarker.Position, 200)
            IssueClearCommands(self:GetPlatoonUnits())
            if path then
                local pathLength = table.getn(path)
                for i=1, pathLength-1 do
                	if bAggroMove then
                		self:AggressiveMoveToLocation(path[i])
            		else
                        self:MoveToLocation(path[i], false)
                    end
                end 
            elseif (not path and reason == 'NoPath') then
                AIAttackUtils.SendPlatoonWithTransports(aiBrain, self, bestMarker.Position, true)
            else
                self:PlatoonDisband()
                return
            end
            
            if moveNext == 'None' then
                # guard
                IssueGuard( self:GetPlatoonUnits(), bestMarker.Position )
                # guard forever
                if guardTimer <= 0 then return end
            else
                # otherwise, we're moving to the location
                self:AggressiveMoveToLocation(bestMarker.Position)
            end
            
            # wait till we get there
            repeat
                WaitSeconds(5)    
                platLoc = self:GetPlatoonPosition() 
            until VDist2Sq(platLoc[1], platLoc[3], bestMarker.Position[1], bestMarker.Position[3]) < 64 or not aiBrain:PlatoonExists(self)
            
            # if we're supposed to guard for some time
            if moveNext == 'None' then
                # this won't be 0... see above
                WaitSeconds(guardTimer)
                self:PlatoonDisband()
                return
            end
            
            if moveNext == 'Guard Base' then
                return self:GuardBase()
            end
            
            # we're there... wait here until we're done
            local numGround = aiBrain:GetNumUnitsAroundPoint( ( categories.LAND + categories.NAVAL + categories.STRUCTURE ), bestMarker.Position, 15, 'Enemy' )
            while numGround > 0 and aiBrain:PlatoonExists(self) do
                WaitSeconds(Random(5,10))
                numGround = aiBrain:GetNumUnitsAroundPoint( ( categories.LAND + categories.NAVAL + categories.STRUCTURE ), bestMarker.Position, 15, 'Enemy' )    
            end
            
            if not aiBrain:PlatoonExists(self) then
                return
            end
            
            # set our MoveFirst to our MoveNext
            self.PlatoonData.MoveFirst = moveNext
            return self:GuardMarker()
        else
            # no marker found, disband!
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
            basePosition = aiBrain:FindClosestBuilderManagerPosition(self:GetPlatoonPosition())
        end
        
        local guardRadius = self.PlatoonData.GuardRadius or 75
        
        while aiBrain:PlatoonExists(self) do
            if self:IsOpponentAIRunning() then
                target = self:FindClosestUnit('Attack', 'Enemy', true, categories.ALLUNITS - categories.WALL)
								if target and not target:IsDead() and VDist3( target:GetPosition(), self:GetPlatoonPosition() ) < guardRadius then                
                    self:Stop()
                    self:AggressiveMoveToLocation( target:GetPosition() )
                else
                    self:Stop()
                    self:MoveToLocation( basePosition, false )
                end
            end
            WaitSeconds(5)
        end
    end,
    
    #-----------------------------------------------------
    #   Function: LandScoutingAI
    #   Args:
    #       platoon - platoon to run the AI
    #   Description:
    #       Handles sending land scouts to important locations.
    #   Returns:  
    #       nil (loops until platoon is destroyed)
    #-----------------------------------------------------
    LandScoutingAI = function(self)
        AIAttackUtils.GetMostRestrictiveLayer(self)
        
        local aiBrain = self:GetBrain()
        local scout = self:GetPlatoonUnits()[1]
        
        #If we have cloaking (are cybran), then turn on our cloaking
        if scout:TestToggleCaps('RULEUTC_CloakToggle') then
            scout:EnableUnitIntel('Cloak')
        end
               
        while not scout:IsDead() do
            #Head towards the the area that has not had a scout sent to it in a while           
            local targetData = false
            
            #For every scouts we send to all opponents, send one to scout a low pri area.
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
                #Reset number of scoutings and start over
                aiBrain.IntelData.HiPriScouts = 0
            end
            
            #Is there someplace we should scout?
            if targetData then
                #Can we get there safely?
                local path, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, self.MovementLayer, scout:GetPosition(), targetData.Position, 100)
                
                IssueClearCommands(self)

                if path then
                    local pathLength = table.getn(path)
                    for i=1, pathLength-1 do
                        self:MoveToLocation(path[i], false)
                    end 
                end

                self:MoveToLocation(targetData.Position, false)  
                
                #Scout until we reach our destination
                while not scout:IsDead() and not scout:IsIdleState() do                                       
                    WaitSeconds(2.5)
                end
            end
            
            WaitSeconds(1)
        end
    end,
    
    #-----------------------------------------------------
    #   Function: DoAirScoutVecs
    #   Args:
    #       platoon - platoon to run the AI
    #       unit - the scout
    #       targetArea - a position to scout
    #   Description:
    #       Creates an attack vector that will cause the scout to fly by the target at a distance of its visual range.
    #       Whether to fly by on the left or right is decided randomly. This whole affair should hopefully extend the 
    #       life of the air scout.
    #   Returns:  
    #       destination position
    #-----------------------------------------------------    
    DoAirScoutVecs = function(self, scout, targetArea)
        local vec = {0, 0, 0}
        vec[1] = targetArea[1] - scout:GetPosition()[1]
        vec[3] = targetArea[3] - scout:GetPosition()[3]
        
        #Normalize
        local length = VDist2(targetArea[1], targetArea[3], scout:GetPosition()[1], scout:GetPosition()[3])
        local norm = {vec[1]/length, 0, vec[3]/length}
        
        #Get negative reciprocal vector, make length of vision radius
        local dir = math.pow(-1, Random(1,2))
        
        local visRad = scout:GetBlueprint().Intel.VisionRadius
        local orthogonal = {norm[3]*visRad*dir, 0, -norm[1]*visRad*dir}
        
        #Offset the target location with an orthogonal vector and a flyby vector.
        local dest = {targetArea[1] + orthogonal[1] + norm[1]*75, 0, targetArea[3] + orthogonal[3] + norm[3]*75}
        
        #Clamp to map edges
        if dest[1] < 5 then dest[1] = 5 
        elseif dest[1] > ScenarioInfo.size[1]-5 then dest[1] = ScenarioInfo.size[1]-5 end
        if dest[3] < 5 then dest[3] = 5 
        elseif dest[3] > ScenarioInfo.size[2]-5 then dest[3] = ScenarioInfo.size[2]-5 end
        
        
        self:MoveToLocation(dest, false)
        return dest
    end,
    
    #-----------------------------------------------------
    #   Function: AirScoutingAI
    #   Args:
    #       platoon - platoon to run the AI
    #   Description:
    #       Handles sending air scouts to important locations.
    #   Returns:  
    #       nil (loops until platoon is destroyed)
    #-----------------------------------------------------
    AirScoutingAI = function(self)
        
        local aiBrain = self:GetBrain()
        local scout = self:GetPlatoonUnits()[1]
        
        if scout:TestToggleCaps('RULEUTC_CloakToggle') then
            scout:EnableUnitIntel('Cloak')
        end
        
        while not scout:IsDead() do
            local targetArea = false
            local highPri = false
            
            local mustScoutArea, mustScoutIndex = aiBrain:GetUntaggedMustScoutArea()
            local unknownThreats = aiBrain:GetThreatsAroundPosition(scout:GetPosition(), 16, true, 'Unknown')
            
            #1) If we have any "must scout" (manually added) locations that have not been scouted yet, then scout them
            if mustScoutArea then
                mustScoutArea.TaggedBy = scout
                targetArea = mustScoutArea.Position
            
            #2) Scout "unknown threat" areas with a threat higher than 25
            elseif table.getn(unknownThreats) > 0 and unknownThreats[1][3] > 25 then
                aiBrain:AddScoutArea({unknownThreats[1][1], 0, unknownThreats[1][2]})
            
            #3) Scout high priority locations    
            elseif aiBrain.IntelData.AirHiPriScouts < aiBrain.NumOpponents and aiBrain.IntelData.AirLowPriScouts < 1 
            and table.getn(aiBrain.InterestList.HighPriority) > 0 then
                aiBrain.IntelData.AirHiPriScouts = aiBrain.IntelData.AirHiPriScouts + 1
                
                highPri = true
                
                targetData = aiBrain.InterestList.HighPriority[1]
                targetData.LastScouted = GetGameTimeSeconds()
                targetArea = targetData.Position
                
                aiBrain:SortScoutingAreas(aiBrain.InterestList.HighPriority)
                
            #4) Every time we scout NumOpponents number of high priority locations, scout a low priority location               
            elseif aiBrain.IntelData.AirLowPriScouts < 1 and table.getn(aiBrain.InterestList.LowPriority) > 0 then
                aiBrain.IntelData.AirHiPriScouts = 0
                aiBrain.IntelData.AirLowPriScouts = aiBrain.IntelData.AirLowPriScouts + 1
                
                targetData = aiBrain.InterestList.LowPriority[1]
                targetData.LastScouted = GetGameTimeSeconds()
                targetArea = targetData.Position
                
                aiBrain:SortScoutingAreas(aiBrain.InterestList.LowPriority)
            else
                #Reset number of scoutings and start over
                aiBrain.IntelData.AirLowPriScouts = 0
                aiBrain.IntelData.AirHiPriScouts = 0
            end
            
            #Air scout do scoutings.
            if targetArea then
                self:Stop()
                
                local vec = self:DoAirScoutVecs(scout, targetArea)
                
                while not scout:IsDead() and not scout:IsIdleState() do                   
                    
                    #If we're close enough...
                    if VDist2Sq(vec[1], vec[3], scout:GetPosition()[1], scout:GetPosition()[3]) < 15625 then
                        if mustScoutArea then
                            #Untag and remove
                            for idx,loc in aiBrain.InterestList.MustScout do
                                if loc == mustScoutArea then
                                   table.remove(aiBrain.InterestList.MustScout, idx)
                                   break 
                                end
                            end
                        end
                        #Break within 125 ogrids of destination so we don't decelerate trying to stop on the waypoint.
                        break
                    end
                    
                    if VDist3( scout:GetPosition(), targetArea ) < 25 then
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

    #-----------------------------------------------------
    #   Function: ScoutingAI
    #   Args:
    #       platoon - a single-scout platoon to run the AI for
    #   Description:
    #       Switches to AirScoutingAI or LandScoutingAI depending on the unit's movement capabilities.
    #   Returns:  
    #       nil. (Tail call into other AI functions)
    #-----------------------------------------------------
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
            if not v:IsDead() and EntityCategoryContains( categories.MOBILE * categories.LAND, v ) then
                unit = v
                break
            end
        end
        if location and radius then
            for k,v in AIUtils.GetBasePatrolPoints(aiBrain, location, radius) do
                if not unit or AIUtils.CheckUnitPathingEx( v, unit:GetPosition(), unit ) then
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
                local threat = aiBrain:GetThreatAtPosition( pos, 0, true, 'AntiSurface' )
                if threat and threat > 1 then
                    #LOG('*AI DEBUG: Platoon Calling for help')
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
            # In the loop so they may be changed by other platoon things
            local distressRange = self.PlatoonData.DistressRange or aiBrain.BaseMonitor.DefaultDistressRange
            local reactionTime = self.PlatoonData.DistressReactionTime or aiBrain.BaseMonitor.PlatoonDefaultReactionTime
            local threatThreshold = self.PlatoonData.ThreatSupport or 1
            local platoonPos = self:GetPlatoonPosition()
            if platoonPos and not self.DistressCall then
                # Find a distress location within the platoons range
                local distressLocation = aiBrain:BaseMonitorDistressLocation(platoonPos, distressRange, threatThreshold)
                local moveLocation
                
                # We found a location within our range! Activate!
                if distressLocation then
                    #LOG('*AI DEBUG: ARMY '.. aiBrain:GetArmyIndex() ..': --- DISTRESS RESPONSE AI ACTIVATION ---')
                    
                    # Backups old ai plan
                    local oldPlan = self:GetPlan()
                    if self.AiThread then
                        self.AIThread:Destroy()
                    end
                    
                    # Continue to position until the distress call wanes
                    repeat
                        moveLocation = distressLocation
                        self:Stop()
                        local cmd = self:AggressiveMoveToLocation( distressLocation )
                        repeat
                            WaitSeconds(reactionTime)
                            if not aiBrain:PlatoonExists(self) then
                                return
                            end
                        until not self:IsCommandsActive(cmd) or aiBrain:GetThreatAtPosition(moveLocation, 0, true, 'Overall') <= threatThreshold
                        
                        
                        platoonPos = self:GetPlatoonPosition()
                        if platoonPos then
                            # Now that we have helped the first location, see if any other location needs the help
                            distressLocation = aiBrain:BaseMonitorDistressLocation(platoonPos, distressRange)
                            if distressLocation then
                                self:AggressiveMoveToLocation( distressLocation )
                            end
                        end
                    # If no more calls or we are at the location; break out of the function
                    until not distressLocation or ( distressLocation[1] == moveLocation[1] and distressLocation[3] == moveLocation[3] )
                    
                    #LOG('*AI DEBUG: '..aiBrain.Name..' DISTRESS RESPONSE AI DEACTIVATION - oldPlan: '..oldPlan)
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
                        local distressLocation = aiBrain:BaseMonitorDistressLocation( locData.Location, aiBrain.BaseMonitor.PoolDistressRange, aiBrain.BaseMonitor.PoolDistressThreshold )
                        local moveLocation
                        if distressLocation then
                            #LOG('*AI DEBUG: ARMY '.. aiBrain:GetArmyIndex() ..': --- POOL DISTRESS RESPONSE ---')
                            local group = {}
                            for k,v in platoonUnits do
                                vPos = table.copy(v:GetPosition())
                                if VDist2( vPos[1], vPos[3], locData.Location[1], locData.Location[3] ) < locData.Radius then
                                    table.insert(group, v)
                                end
                            end
                            IssueClearCommands( group )
                            if distressLocation[1] <= 0 or distressLocation[3] <= 0 or distressLocation[1] >= ScenarioInfo.size[1] or
                                    distressLocation[3] >= ScenarioInfo.size[2] then
                                #LOG('*AI DEBUG: POOLDISTRESSAI SENDING UNITS TO WRONG LOCATION')
                            end
                            IssueAggressiveMove( group, distressLocation )
                            IssueMove( group, aiBrain:PBMGetLocationCoords( locData.LocationType ) )
                            locData.DistressCall = true
                            self:ForkThread( self.UnlockPBMDistressLocation, locData )
                        end
                    end
                end
            end
            WaitSeconds( aiBrain.BaseMonitor.PoolReactionTime )
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
                    local distressLocation = aiBrain:BaseMonitorDistressLocation( position, distressRange, aiBrain.BaseMonitor.PoolDistressThreshold )
                    
                    # Distress !
                    if distressLocation then
                        #LOG('*AI DEBUG: ARMY '.. aiBrain:GetArmyIndex() ..': --- POOL DISTRESS RESPONSE ---')
                        
                        # Grab the units at the location
                        local group = self:GetUnitsAroundPoint( categories.MOBILE, position, radius )

                        # Move the group to the distress location and then back to the location of the base
                        IssueClearCommands( group )
                        IssueAggressiveMove( group, distressLocation )
                        IssueMove( group, position )
                        
                        # Set distress active for duration
                        locData.BaseSettings.DistressCall = true
                        self:ForkThread( self.UnlockBaseManagerDistressLocation, locData )
                    end
                end
            end
            WaitSeconds( aiBrain.BaseMonitor.PoolReactionTime )
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
            error( 'PLATOON.LUA ERROR- CaptureAI requires Categories field',2)
        end

        local checkThreat = false
        if data.ThreatMin and data.ThreatMax and data.ThreatRings then
            checkThreat = true
        end
        while aiBrain:PlatoonExists( self ) do
            local target = AIAttackUtils.AIFindUnitRadiusThreat( aiBrain, 'Enemy', data.Categories, pos, radius, data.ThreatMin, data.ThreatMax, data.ThreatRings )
            if target and not target:IsDead() then
                local blip = target:GetBlip(index)
                if blip then
                    IssueClearCommands( self:GetPlatoonUnits() )
                    IssueCapture( engineers, target )                   
                    local guardTarget
                    
                    for i, unit in engineers do
                        if not unit:IsDead() then
                            IssueGuard( notEngineers, unit)
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
                            if not v:IsDead() and not v:IsIdleState() then
                                allIdle = false
                                break
                            end
                        end
                    until allIdle or blip:BeenDestroyed() or blip:IsKnownFake(index) or blip:IsMaybeDead(index)
                end
            else
                if data.TransportReturn then
                    local retPos = ScenarioUtils.MarkerToPosition(data.TransportReturn)
                    self:MoveToLocation( retPos, false )
                    
                    local rect = {x0 = retPos[1]-10, y0 = retPos[3]-10, x1 = retPos[1]+10, y1 = retPos[3]+10}
                    while true do
                        local alive = 0
                        local cnt = 0
                        for k,unit in self:GetPlatoonUnits() do
                            if not unit:IsDead() then
                                alive = alive + 1
                                
                                if ScenarioUtils.InRect( unit:GetPosition(), rect ) then
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
                    self:MoveToLocation( location, false )
                    self:PlatoonDisband()
                end
            end
            WaitSeconds(1)
        end
    end,

    ReclaimAI = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        local locationType = self.PlatoonData.LocationType
        local timeAlive = 0
        local closest, entType, closeDist, farthest, farDist
        local oldClosest, oldFarthest
        while aiBrain:PlatoonExists(self) do
            local massRatio = aiBrain:GetEconomyStoredRatio('MASS')
            local energyRatio = aiBrain:GetEconomyStoredRatio('ENERGY')
            local massFirst = true
            if energyRatio < massRatio then
                massFirst = false
            end

            local ents = AIUtils.AIGetReclaimablesAroundLocation( aiBrain, locationType )
            if not ents or table.getn( ents ) == 0 then
                LOG('*AI DEBUG: No reclaimables found')
                WaitTicks(1)
                self:PlatoonDisband()
            end
            
            local unitPos = self:GetPlatoonPosition()
            if not unitPos then break end
            local recPos = nil
            closest = false
            farthest = false
            for k, v in ents do
                recPos = v:GetPosition()
                if not recPos then 
                    WaitTicks(1)
                    self:PlatoonDisband()
                end
                if not (unitPos[1] and unitPos[3] and recPos[1] and recPos[3]) then return end
                local tempDist = VDist2( unitPos[1], unitPos[3], recPos[1], recPos[3] )
                # We don't want any reclaimables super close to us
                if ( ( not closest or tempDist < closeDist ) and tempDist > 2 and ( not oldClosest or closest != oldClosest ) ) then
                    closest = recPos
                    closeDist = tempDist
                end
                if ( ( not farthest or tempDist > farDist ) and tempDist > 2 and ( not oldFarthest or farthest != oldFarthest )) then
                    farthest = recPos
                    farDist = tempDist
                end
            end

            if closest and farthest and ( massRatio < .9 or energyRatio < .9 ) then
                closest = table.copy(closest)
                farthest = table.copy(farthest)
                oldFarthest = farthest
                oldClosest = closest
                self:Stop()
                self:Patrol( closest )
                self:Patrol( farthest )
                local count = 0
                repeat
                    WaitSeconds(5)
                    if not aiBrain:PlatoonExists(self) then
                        return
                    end
                    timeAlive = timeAlive + 5
                    count = count + 1
                    if self.PlatoonData.ReclaimTime and timeAlive >= self.PlatoonData.ReclaimTime then
                        self:PlatoonDisband()
                        return
                    end
                until VDist3( self:GetPlatoonPosition(), farthest ) < 10 or count >= 7
            else
                self:PlatoonDisband()
            end
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
            error( 'PLATOON.LUA ERROR- ReclaimUnitsAI requires Categories field',2)
        end

        local checkThreat = false
        if data.ThreatMin and data.ThreatMax and data.ThreatRings then
            checkThreat = true
        end
        while aiBrain:PlatoonExists(self) do
            local target = AIAttackUtils.AIFindUnitRadiusThreat( aiBrain, 'Enemy', data.Categories, pos, radius, data.ThreatMin, data.ThreatMax, data.ThreatRings )
            if target and not target:IsDead() then
                local blip = target:GetBlip(index)
                if blip then
                    IssueClearCommands( self:GetPlatoonUnits() )
                    IssueReclaim( self:GetPlatoonUnits(), target )
                    local allIdle
                    repeat
                        WaitSeconds(2)
                        if not aiBrain:PlatoonExists(self) then
                            return
                        end
                        allIdle = true
                        for k,v in self:GetPlatoonUnits() do
                            if not v:IsDead() and not v:IsIdleState() then
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
                self:MoveToLocation( location, false )
                self:PlatoonDisband()
            end
            WaitSeconds(1)
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
        self:PlatoonDisband()
    end,
    
    EconAssistBody = function(self)
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
            assisteeCat = ParseEntityCategory( assisteeCat )
        end

        # loop through different categories we are looking for
        for _,catString in beingBuilt do
            # Track all valid units in the assist list so we can load balance for factories
            
            local category = ParseEntityCategory( catString )
        
            local assistList = AIUtils.GetAssistees( aiBrain, assistData.AssistLocation, assistData.AssisteeType, category, assisteeCat )

            if table.getn(assistList) > 0 then
                # only have one unit in the list; assist it
                if table.getn(assistList) == 1 then
                    assistee = assistList[1]
                    break
                else
                    # Find the unit with the least number of assisters; assist it
                    local lowNum = false
                    local lowUnit = false
                    for k,v in assistList do
                        if not lowNum or table.getn( v:GetGuards() ) < lowNum then
                            lowNum = v:GetGuards()
                            lowUnit = v
                        end
                    end
                    assistee = lowUnit
                    break
                end
            end
        end
        # assist unit
        if assistee  then
            self:Stop()
            eng.AssistSet = true
            IssueGuard( {eng}, assistee )
        else
            self.AssistPlatoon = nil
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
        if not eng:IsDead() then
            local guardedUnit = eng:GetGuardedUnit()
            if guardedUnit and not guardedUnit:IsDead() then
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
            # Check for units being built
            if assistData.BeingBuiltCategories then
                local unitsBuilding = aiBrain:GetListOfUnits( categories.CONSTRUCTION, false )
                for catNum, buildeeCat in assistData.BeingBuiltCategories do
                    local buildCat = ParseEntityCategory(buildeeCat)
                    for unitNum, unit in unitsBuilding do
                        if not unit:IsDead() and ( unit:IsUnitState('Building') or unit:IsUnitState('Upgrading') ) then
                            local buildingUnit = unit:GetUnitBeingBuilt()
                            if buildingUnit and not buildingUnit:IsDead() and EntityCategoryContains( buildCat, buildingUnit ) then
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
            # Check for builders
            if not assistee and assistData.BuilderCategories then
                for catNum, buildCat in assistData.BuilderCategories do
                    local unitsBuilding = aiBrain:GetListOfUnits( ParseEntityCategory(buildCat), false )
                    for unitNum, unit in unitsBuilding do
                        if not unit:IsDead() and unit:IsUnitState('Building') then
                            local unitPos = unit:GetPosition()
                            if unitPos and platoonPos and VDist2(platoonPos[1], platoonPos[3], unitPos[1], unitPos[3]) < assistRange then
                                assistee = unit
                                break
                            end
                        end
                    end
                end
            end
            # If the unit to be assisted is a factory, assist whatever it is assisting or is assisting it
            # Makes sure all factories have someone helping out to load balance better
            if assistee and not assistee:IsDead() and EntityCategoryContains( categories.FACTORY, assistee ) then
                local guardee = assistee:GetGuardedUnit()
                if guardee and not guardee:IsDead() and EntityCategoryContains( categories.FACTORY, guardee ) then
                    local factories = AIUtils.AIReturnAssistingFactories( guardee )
                    table.insert(factories, assistee)
                    AIUtils.AIEngineersAssistFactories( aiBrain, platoonUnits, factories )
                    assistingBool = true
                elseif table.getn(assistee:GetGuards()) > 0 then
                    local factories = AIUtils.AIReturnAssistingFactories( assistee )
                    table.insert(factories, assistee)
                    AIUtils.AIEngineersAssistFactories( aiBrain, platoonUnits, factories )
                    assistingBool = true
                end
            end
        end
        if assistee and not assistee:IsDead() then
            if not assistingBool then
                eng.AssistSet = true
                IssueGuard( platoonUnits, assistee )
            end
        elseif not assistee then
            if eng.BuilderManagerData then
                local emLoc = eng.BuilderManagerData.EngineerManager:GetLocationCoords()
                local dist = assistData.AssistRange or 80
                if VDist3( eng:GetPosition(), emLoc ) > dist then
                    self:MoveToLocation( emLoc, false )
                    WaitSeconds(9)
                end
            end
            WaitSeconds(1)
            self.AssistPlatoon = nil
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
        self:PlatoonDisband()
    end,


    #-----------------------------------------------------
    #   Function: EngineerBuildAI
    #   Args:
    #       self - the single-engineer platoon to run the AI on
    #   Description:
    #       a single-unit platoon made up of an engineer, this AI will determine
    #       what needs to be built (based on platoon data set by the calling
    #       abstraction, and then issue the build commands to the engineer
    #   Returns:  
    #       nil (tail calls into a behavior function)
    #-----------------------------------------------------
    EngineerBuildAI = function(self)
        self:Stop()
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

        local eng
        for k, v in platoonUnits do
            if not v:IsDead() and EntityCategoryContains(categories.CONSTRUCTION, v ) then
                if not eng then
                    eng = v
                else
                    IssueClearCommands( {v} )
                    IssueGuard({v}, eng)
                end
            end
        end

        if not eng or eng:IsDead() then
            WaitTicks(1)
            self:PlatoonDisband()
            return
        end

        if self.PlatoonData.NeedGuard then
            eng.NeedGuard = true
        end

        #### CHOOSE APPROPRIATE BUILD FUNCTION AND SETUP BUILD VARIABLES ####
        local reference = false
        local refName = false
        local buildFunction
        local closeToBuilder
        local relative
        local baseTmplList = {}
        
        # if we have nothing to build, disband!
        if not cons.BuildStructures then
            WaitTicks(1)
            self:PlatoonDisband()
            return
        end
        
        if cons.NearUnitCategory then
            self:SetPrioritizedTargetList('support', {ParseEntityCategory(cons.NearUnitCategory)})
            local unitNearBy = self:FindPrioritizedUnit('support', 'Ally', false, self:GetPlatoonPosition(), cons.NearUnitRadius or 50)
            #LOG("ENGINEER BUILD: " .. cons.BuildStructures[1] .." attempt near: ", cons.NearUnitCategory)
            if unitNearBy then
                reference = table.copy( unitNearBy:GetPosition() )
                # get commander home position
                #LOG("ENGINEER BUILD: " .. cons.BuildStructures[1] .." Near unit: ", cons.NearUnitCategory)
                if cons.NearUnitCategory == 'COMMAND' and unitNearBy.CDRHome then
                    reference = unitNearBy.CDRHome
                end
            else
                reference = table.copy( eng:GetPosition() )
            end
            relative = false
            buildFunction = AIBuildStructures.AIExecuteBuildStructure
            table.insert( baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation( baseTmpl, reference ) )
        elseif cons.Wall then
            local pos = aiBrain:PBMGetLocationCoords(cons.LocationType) or cons.Position or self:GetPlatoonPosition()
            local radius = cons.LocationRadius or aiBrain:PBMGetLocationRadius(cons.LocationType) or 100
            relative = false
            reference = AIUtils.GetLocationNeedingWalls( aiBrain, 200, 4, 'STRUCTURE - WALLS', cons.ThreatMin, cons.ThreatMax, cons.ThreatRings )
            table.insert( baseTmplList, 'Blank' )
            buildFunction = AIBuildStructures.WallBuilder
        elseif cons.NearBasePatrolPoints then
            relative = false
            reference = AIUtils.GetBasePatrolPoints(aiBrain, cons.Location or 'MAIN', cons.Radius or 100)
            baseTmpl = baseTmplFile['ExpansionBaseTemplates'][factionIndex]
            for k,v in reference do
                table.insert( baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation( baseTmpl, v ) )
            end
            # Must use BuildBaseOrdered to start at the marker; otherwise it builds closest to the eng
            buildFunction = AIBuildStructures.AIBuildBaseTemplateOrdered
        elseif cons.NearMarkerType and cons.ExpansionBase then
            local pos = aiBrain:PBMGetLocationCoords(cons.LocationType) or cons.Position or self:GetPlatoonPosition()
            local radius = cons.LocationRadius or aiBrain:PBMGetLocationRadius(cons.LocationType) or 100
            
            if cons.FireBase and cons.FireBaseRange then
                reference, refName = AIUtils.AIFindFirebaseLocation(aiBrain, cons.LocationType, cons.FireBaseRange, cons.NearMarkerType,
                                                    cons.ThreatMin, cons.ThreatMax, cons.ThreatRings, cons.ThreatType, 
                                                    cons.MarkerUnitCount, cons.MarkerUnitCategory, cons.MarkerRadius)
                if not reference or not refName then
                    self:PlatoonDisband()
                end
            elseif cons.NearMarkerType == 'Expansion Area' then
                reference, refName = AIUtils.AIFindExpansionAreaNeedsEngineer( aiBrain, cons.LocationType, 
                        (cons.LocationRadius or 100), cons.ThreatMin, cons.ThreatMax, cons.ThreatRings, cons.ThreatType )
                # didn't find a location to build at
                if not reference or not refName then
                    self:PlatoonDisband()
                end
            elseif cons.NearMarkerType == 'Naval Area' then
                reference, refName = AIUtils.AIFindNavalAreaNeedsEngineer( aiBrain, cons.LocationType, 
                        (cons.LocationRadius or 100), cons.ThreatMin, cons.ThreatMax, cons.ThreatRings, cons.ThreatType )
                # didn't find a location to build at
                if not reference or not refName then
                    self:PlatoonDisband()
                end
            else
                reference, refName = AIUtils.AIFindStartLocationNeedsEngineer( aiBrain, cons.LocationType, 
                        (cons.LocationRadius or 100), cons.ThreatMin, cons.ThreatMax, cons.ThreatRings, cons.ThreatType )
                # didn't find a location to build at
                if not reference or not refName then
                    self:PlatoonDisband()
                end
            end
            
            # If moving far from base, tell the assisting platoons to not go with
            if cons.FireBase or cons.ExpansionBase then
                local guards = eng:GetGuards()
                for k,v in guards do
                    if not v:IsDead() and v.PlatoonHandle then
                        v.PlatoonHandle:PlatoonDisband()
                    end
                end
            end
                    
            if not cons.BaseTemplate and ( cons.NearMarkerType == 'Naval Area' or cons.NearMarkerType == 'Defensive Point' or cons.NearMarkerType == 'Expansion Area' ) then
                baseTmpl = baseTmplFile['ExpansionBaseTemplates'][factionIndex]
            end
            if cons.ExpansionBase and refName then
                AIBuildStructures.AINewExpansionBase( aiBrain, refName, reference, eng, cons)
            end
            relative = false
            if reference and aiBrain:GetThreatAtPosition( reference , 1, true, 'AntiSurface' ) > 0 then
                #aiBrain:ExpansionHelp( eng, reference )
            end
            table.insert( baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation( baseTmpl, reference ) )
            # Must use BuildBaseOrdered to start at the marker; otherwise it builds closest to the eng
            #buildFunction = AIBuildStructures.AIBuildBaseTemplateOrdered
            buildFunction = AIBuildStructures.AIBuildBaseTemplate
        elseif cons.NearMarkerType and cons.NearMarkerType == 'Defensive Point' then
            baseTmpl = baseTmplFile['ExpansionBaseTemplates'][factionIndex]

            relative = false
            local pos = self:GetPlatoonPosition()
            reference, refName = AIUtils.AIFindDefensivePointNeedsStructure( aiBrain, cons.LocationType, (cons.LocationRadius or 100), 
                            cons.MarkerUnitCategory, cons.MarkerRadius, cons.MarkerUnitCount, (cons.ThreatMin or 0), (cons.ThreatMax or 1), 
                            (cons.ThreatRings or 1), (cons.ThreatType or 'AntiSurface') )

            table.insert( baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation( baseTmpl, reference ) )

            buildFunction = AIBuildStructures.AIExecuteBuildStructure
        elseif cons.NearMarkerType and cons.NearMarkerType == 'Naval Defensive Point' then
            baseTmpl = baseTmplFile['ExpansionBaseTemplates'][factionIndex]

            relative = false
            local pos = self:GetPlatoonPosition()
            reference, refName = AIUtils.AIFindNavalDefensivePointNeedsStructure( aiBrain, cons.LocationType, (cons.LocationRadius or 100), 
                            cons.MarkerUnitCategory, cons.MarkerRadius, cons.MarkerUnitCount, (cons.ThreatMin or 0), (cons.ThreatMax or 1), 
                            (cons.ThreatRings or 1), (cons.ThreatType or 'AntiSurface') )

            table.insert( baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation( baseTmpl, reference ) )

            buildFunction = AIBuildStructures.AIExecuteBuildStructure
        elseif cons.NearMarkerType then
            #WARN('*Data weird for builder named - ' .. self.BuilderName )
            if not cons.ThreatMin or not cons.ThreatMax or not cons.ThreatRings then
                cons.ThreatMin = -1000000
                cons.ThreatMax = 1000000
                cons.ThreatRings = 0
            end
            if not cons.BaseTemplate and ( cons.NearMarkerType == 'Defensive Point' or cons.NearMarkerType == 'Expansion Area' ) then
                baseTmpl = baseTmplFile['ExpansionBaseTemplates'][factionIndex]
            end
            relative = false
            local pos = self:GetPlatoonPosition()
            reference, refName = AIUtils.AIGetClosestThreatMarkerLoc(aiBrain, cons.NearMarkerType, pos[1], pos[3],
                                                            cons.ThreatMin, cons.ThreatMax, cons.ThreatRings)
            if cons.ExpansionBase and refName then
                AIBuildStructures.AINewExpansionBase( aiBrain, refName, reference, (cons.ExpansionRadius or 100), cons.ExpansionTypes, nil, cons )
            end
            if reference and aiBrain:GetThreatAtPosition( reference, 1, true ) > 0 then
                #aiBrain:ExpansionHelp( eng, reference )
            end
            table.insert( baseTmplList, AIBuildStructures.AIBuildBaseTemplateFromLocation( baseTmpl, reference ) )
            buildFunction = AIBuildStructures.AIExecuteBuildStructure
        elseif cons.AdjacencyCategory then
            relative = false
            local pos = aiBrain.BuilderManagers[eng.BuilderManagerData.LocationType].EngineerManager:GetLocationCoords()
            local cat = ParseEntityCategory(cons.AdjacencyCategory)
            local radius = ( cons.AdjacencyDistance or 50 )
            if not pos or not pos then
                WaitTicks(1)
                self:PlatoonDisband()
                return
            end
            reference  = AIUtils.GetOwnUnitsAroundPoint( aiBrain, cat, pos, radius, cons.ThreatMin,
                                                        cons.ThreatMax, cons.ThreatRings)
            buildFunction = AIBuildStructures.AIBuildAdjacency
            table.insert( baseTmplList, baseTmpl )
        else
            table.insert( baseTmplList, baseTmpl )
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
                if not v:IsDead() and v.PlatoonHandle and aiBrain:PlatoonExists(v.PlatoonHandle) then
                    #WaitTicks(1)
                    v.PlatoonHandle:PlatoonDisband()
                end
            end
        end                   

        #LOG("*AI DEBUG: Setting up Callbacks for " .. eng.Sync.id)
        self.SetupEngineerCallbacks(eng)
              
        #### BUILD BUILDINGS HERE ####
        for baseNum, baseListData in baseTmplList do
            for k, v in cons.BuildStructures do
                if aiBrain:PlatoonExists(self) then
                    if not eng:IsDead() then
                        buildFunction(aiBrain, eng, v, closeToBuilder, relative, buildingTmpl, baseListData, reference, cons.NearMarkerType)
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
        
        # wait in case we're still on a base
        if not eng:IsDead() then
            local count = 0
            while eng:IsUnitState( 'Attached' ) and count < 2 do
                WaitSeconds(6)
                count = count + 1
            end
        end

        if not eng:IsUnitState('Building') then
            return self.ProcessBuildCommand(eng, false)
        end
    end,

    #UpgradeAnEngineeringPlatoon
    UnitUpgradeAI = function(self)
        local aiBrain = self:GetBrain()
        local platoonUnits = self:GetPlatoonUnits()
        local factionIndex = aiBrain:GetFactionIndex()
        self:Stop()
        for k, v in platoonUnits do
            local upgradeID
            if EntityCategoryContains(categories.MOBILE, v ) then
                upgradeID = aiBrain:FindUpgradeBP(v:GetUnitId(), UnitUpgradeTemplates[factionIndex])
            else
                upgradeID = aiBrain:FindUpgradeBP(v:GetUnitId(), StructureUpgradeTemplates[factionIndex])
            end
            if upgradeID then
                IssueUpgrade({v}, upgradeID)
            end
        end
        local upgrading = true
        while aiBrain:PlatoonExists(self) and upgrading do
            WaitSeconds(3)
            upgrading = false
            for k, v in platoonUnits do
                if v and not v:IsDead() then
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

        LOG('*AI DEBUG: Transferring units to - ' .. self.PlatoonData.LocationType)

        eng.BuilderManagerData.EngineerManager:RemoveUnit(eng)
        aiBrain.BuilderManagers[self.PlatoonData.LocationType].EngineerManager:AddUnit(eng, true)
    end,

    RepairCDRAI = function(self)
        local aiBrain = self:GetBrain()
        local cdrUnits = aiBrain:GetListOfUnits( categories.COMMAND, false )
        for k,v in cdrUnits do
            if v:GetHealthPercent() < .8 then
                self:Stop()
                IssueRepair( self:GetPlatoonUnits(), v )
            end
        end
        self:PlatoonDisband()
    end,

    StrikeForceAI = function(self)
        local aiBrain = self:GetBrain()
        local armyIndex = aiBrain:GetArmyIndex()
        local data = self.PlatoonData
        local categoryList = {}
        local atkPri = {}
        if data.PrioritizedCategories then
            for k,v in data.PrioritizedCategories do
                table.insert( atkPri, v )
                table.insert( categoryList, ParseEntityCategory( v ) )
            end
        end
        table.insert( atkPri, 'ALLUNITS' )
        table.insert( categoryList, categories.ALLUNITS )
        self:SetPrioritizedTargetList( 'Attack', categoryList )
        local target
        local blip = false
        local maxRadius = data.SearchRadius or 50
        local movingToScout = false
        while aiBrain:PlatoonExists(self) do
            if not target or target:IsDead() then
                if aiBrain:GetCurrentEnemy() and aiBrain:GetCurrentEnemy():IsDefeated() then
                    aiBrain:PickEnemyLogic()
                end
                local mult = { 1,10,25 }
                for _,i in mult do
                    target = AIUtils.AIFindBrainTargetInRange( aiBrain, self, 'Attack', maxRadius * i, atkPri, aiBrain:GetCurrentEnemy() )
                    if target then
                        break
                    end
                    WaitSeconds(3)
                    if not aiBrain:PlatoonExists(self) then
                        return
                    end
                end
                #target = self:FindPrioritizedUnit('Attack', 'Enemy', true, self:GetPlatoonPosition(), maxRadius)
                if target then
                    self:Stop()
                    if not data.UseMoveOrder then
                        self:AttackTarget( target )
                    else
                        self:MoveToLocation( table.copy( target:GetPosition() ), false)
                    end
                    movingToScout = false
                elseif not movingToScout then
                    movingToScout = true
                    self:Stop()
                    for k,v in AIUtils.AIGetSortedMassLocations(aiBrain, 10, nil, nil, nil, nil, self:GetPlatoonPosition()) do
                        if v[1] < 0 or v[3] < 0 or v[1] > ScenarioInfo.size[1] or v[3] > ScenarioInfo.size[2] then
                            #LOG('*AI DEBUG: STRIKE FORCE SENDING UNITS TO WRONG LOCATION - ' .. v[1] .. ', ' .. v[3] )
                        end
                        self:MoveToLocation( (v), false )
                    end
                end
            end
            WaitSeconds( 7 )
        end
    end,

    #-----------------------------------------------------
    #   Function: CarrierAI
    #   Args:
    #       self - the carrier platoon to run the AI on
    #   Description:
    #       Uses the carrier as a sea-based powerful anti-air unit.
    #       Dispatches the carrier to a location with heavy air cover
    #       to wreck havoc on air units
    #   Returns:  
    #       nil (tail calls into a behavior function)
    #-----------------------------------------------------
    CarrierAI = function(self)
        local aiBrain = self:GetBrain()
        if not aiBrain then 
            return 
        end
        
        # only works for carriers!
        for k,v in self:GetPlatoonUnits() do
            if not EntityCategoryContains( categories.CARRIER, v ) then
                return
            end
            
            # do something else for the experimental unit... act as a sub basically
            if EntityCategoryContains (categories.ues0401, v) then
                return NavalForceAI(self)
            end
        end    

        if not self.LastAttackDestination then
            self.LastAttackDestination = {}
        end
        
        while aiBrain:PlatoonExists(self) do
            # this table is sorted already from highest to lowest threat...
            local threatTable = aiBrain:GetThreatsAroundPosition(self:GetPlatoonPosition(), 16, true, 'Air')
            
            local attackPos = nil
            # so go through until we find the first threat that's pathable
            for tidx,threat in threatTable do
                local foundSpot = true
                #check if we can path to the position or a position nearby
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
    
            # if we don't have an old path or our old destination and new destination are different
            if attackPos and oldPathSize == 0 or attackPos[1] != self.LastAttackDestination[oldPathSize][1] or attackPos[3] != self.LastAttackDestination[oldPathSize][3] then
                AIAttackUtils.GetMostRestrictiveLayer(self)
                # check if we can path to here safely... give a large threat weight to sort by threat first
                local path, reason = AIAttackUtils.PlatoonGenerateSafePathTo(aiBrain, self.MovementLayer, self:GetPlatoonPosition(), attackPos, self.PlatoonData.NodeWeight or 10 )
    
                # clear command queue
                self:Stop()
                
                if not path then
                    if reason == 'NoStartNode' or reason == 'NoEndNode' then
                        --Couldn't find a valid pathing node. Just use shortest path.
                        self:AggressiveMoveToLocation(attackPos)
                    end
                    # force reevaluation
                    self.LastAttackDestination = {attackPos}
                else
                    local pathSize = table.getn(path)
                    # store path
                    self.LastAttackDestination = path
                    # move to new location
                    for wpidx,waypointPath in path do
                        if wpidx == pathSize then
                            self:AggressiveMoveToLocation(waypointPath)
                        else
                            self:MoveToLocation(waypointPath, false)
                        end
                    end   
                end                    
            end
            
            # and loop back on the while
            WaitSeconds(20)
        end
    end,

    #-----------------------------------------------------
    #   Function: DummyAI
    #   Args:
    #       self - the single platoon to run the AI on
    #   Description:
    #       Does nothing, just returns
    #   Returns:  
    #       nil (tail calls into a behavior function)
    #-----------------------------------------------------
    DummyAI = function(self)
    end,

    ArtilleryAI = function(self)
        local aiBrain = self:GetBrain()

        local atkPri = { 'SPECIALHIGHPRI', 'STRUCTURE STRATEGIC', 'EXPERIMENTAL LAND', 'STRUCTURE SHIELD', 'COMMAND', 'STRUCTURE FACTORY', 
            'STRUCTURE DEFENSE', 'MOBILE TECH3 LAND', 'MOBILE TECH2 LAND', 'MOBILE TECH1 LAND', 'SPECIALLOWPRI', 'ALLUNITS' }
        local atkPriTable = {}
        for k,v in atkPri do
            table.insert( atkPriTable, ParseEntityCategory( v ) )
        end
        self:SetPrioritizedTargetList( 'Attack', atkPriTable )

        # Set priorities on the unit so if the target has died it will reprioritize before the platoon does
        local unit = false
        for k,v in self:GetPlatoonUnits() do
            if not v:IsDead() then
                unit = v
                break
            end
        end
        if not unit then
            return
        end
        unit:SetTargetPriorities( atkPriTable )
        
        while aiBrain:PlatoonExists(self) do
            local target = self:FindPrioritizedUnit()
            if target then
                self:Stop()
                self:AttackTarget(target)
            end
            WaitSeconds(20)
        end
    end,

    #-----------------------------------------------------
    #   Function: NavalForceAI
    #   Args:
    #       self - the single platoon to run the AI on
    #   Description:
    #       Basic attack logic for boats.  Searches for a good area to go attack, and will use
    #       a safe path (if available) to get there.  
    #   Returns:  
    #       nil (tail calls into a behavior function)
    #-----------------------------------------------------
    NavalForceAI = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        
        AIAttackUtils.GetMostRestrictiveLayer(self)
        
        local platoonUnits = self:GetPlatoonUnits()
        local numberOfUnitsInPlatoon = table.getn(platoonUnits)
        local oldNumberOfUnitsInPlatoon = numberOfUnitsInPlatoon
        local stuckCount = 0
        
        self.PlatoonAttackForce = true
        # formations have penalty for taking time to form up... not worth it here
        # maybe worth it if we micro
        #self:SetPlatoonFormationOverride('GrowthFormation')
        local PlatoonFormation = self.PlatoonData.UseFormation or 'NoFormation'
        self:SetPlatoonFormationOverride(PlatoonFormation)
        
        for k,v in self:GetPlatoonUnits() do
            if v:IsDead() then
                continue
            end
            
            if v:GetCurrentLayer() != 'Sub' then
                continue
            end
            
            if v:TestCommandCaps('RULEUCC_Dive') then
                IssueDive( {v} )
            end
        end

        while aiBrain:PlatoonExists(self) do
            local pos = self:GetPlatoonPosition() # update positions; prev position done at end of loop so not done first time  
            
            # if we can't get a position, then we must be dead
            if not pos then
                break
            end
            
            # pick out the enemy
            if aiBrain:GetCurrentEnemy() and aiBrain:GetCurrentEnemy():IsDefeated() then
                aiBrain:PickEnemyLogic()
            end

            # merge with nearby platoons
            self:MergeWithNearbyPlatoons('NavalForce', 20)

            # rebuild formation
            platoonUnits = self:GetPlatoonUnits()
            numberOfUnitsInPlatoon = table.getn(platoonUnits)
            # if we have a different number of units in our platoon, regather
            if (oldNumberOfUnitsInPlatoon != numberOfUnitsInPlatoon) then
                self:StopAttack()
                self:SetPlatoonFormationOverride(PlatoonFormation)
            end
            oldNumberOfUnitsInPlatoon = numberOfUnitsInPlatoon

            local cmdQ = {} 
            # fill cmdQ with current command queue for each unit
            for k,v in self:GetPlatoonUnits() do
                if not v:IsDead() then
                    local unitCmdQ = v:GetCommandQueue()
                    for cmdIdx,cmdVal in unitCmdQ do
                        table.insert(cmdQ, cmdVal)
                        break
                    end
                end
            end            
            
            # if we're on our final push through to the destination, and we find a unit close to our destination
            local closestTarget = self:FindClosestUnit( 'attack', 'enemy', true, categories.ALLUNITS )
            local nearDest = false
            local oldPathSize = table.getn(self.LastAttackDestination)
            local maxRange = AIAttackUtils.GetNavalPlatoonMaxRange(aiBrain, self)
            if self.LastAttackDestination then
                nearDest = oldPathSize == 0 or VDist3(self.LastAttackDestination[oldPathSize], pos) < maxRange
            end
            
            # if we're near our destination and we have a unit closeby to kill, kill it
            if table.getn(cmdQ) <= 1 and closestTarget and VDist3( closestTarget:GetPosition(), pos ) < maxRange and nearDest then
                self:StopAttack()
                if PlatoonFormation != 'No Formation' then
                    self:AttackTarget(closestTarget)
                    #IssueFormAttack(platoonUnits, closestTarget, PlatoonFormation, 0)
                else
                    self:AttackTarget(closestTarget)
                    #IssueAttack(platoonUnits, closestTarget)
                end
                cmdQ = {1}
            # if we have nothing to do, try finding something to do        
            elseif table.getn(cmdQ) == 0 then
                self:StopAttack()
                cmdQ = AIAttackUtils.AIPlatoonNavalAttackVector( aiBrain, self )
                stuckCount = 0
            # if we've been stuck and unable to reach next marker? Ignore nearby stuff and pick another target  
            elseif self.LastPosition and VDist2Sq(self.LastPosition[1], self.LastPosition[3], pos[1], pos[3]) < ( self.PlatoonData.StuckDistance or 100) then
                stuckCount = stuckCount + 1
                if stuckCount >= 2 then               
                    self:StopAttack()
                    cmdQ = AIAttackUtils.AIPlatoonNavalAttackVector( aiBrain, self )
                    stuckCount = 0
                end
            else
                stuckCount = 0
            end
            
            self.LastPosition = pos
            
            #wait a while if we're stuck so that we have a better chance to move
            WaitSeconds(Random(5,11) + 2 * stuckCount)
        end
    end,


    #-----------------------------------------------------
    #   Function: AttackForceAI
    #   Args:
    #       self - the single platoon to run the AI on
    #   Description:
    #       Basic attack logic.  Searches for a good area to go attack, and will use
    #       a safe path (if available) to get there.  If the threat of the platoon
    #       drops too low, it will try and guard an engineer (to be more useful)
    #       See AIAttackUtils for the bulk of the logic
    #   Returns:  
    #       nil (tail calls into a behavior function)
    #-----------------------------------------------------
    AttackForceAI = function(self)
        self:Stop()
        local aiBrain = self:GetBrain()
        
        # get units together
        if not self:GatherUnits() then
            return
        end
        
        # Setup the formation based on platoon functionality
        
        local enemy = aiBrain:GetCurrentEnemy()

        local platoonUnits = self:GetPlatoonUnits()
        local numberOfUnitsInPlatoon = table.getn(platoonUnits)
        local oldNumberOfUnitsInPlatoon = numberOfUnitsInPlatoon
        local stuckCount = 0
        
        self.PlatoonAttackForce = true
        # formations have penalty for taking time to form up... not worth it here
        # maybe worth it if we micro
        #self:SetPlatoonFormationOverride('GrowthFormation')
        local PlatoonFormation = self.PlatoonData.UseFormation or 'NoFormation'
        self:SetPlatoonFormationOverride(PlatoonFormation)
        
        while aiBrain:PlatoonExists(self) do
            local pos = self:GetPlatoonPosition() # update positions; prev position done at end of loop so not done first time  
            
            # if we can't get a position, then we must be dead
            if not pos then
                break
            end
            
            
            # if we're using a transport, wait for a while
            if self.UsingTransport then
                WaitSeconds(10)
                continue
            end
                        
            # pick out the enemy
            if aiBrain:GetCurrentEnemy() and aiBrain:GetCurrentEnemy():IsDefeated() then
                aiBrain:PickEnemyLogic()
            end

            # merge with nearby platoons
            self:MergeWithNearbyPlatoons('AttackForceAI', 10)

            # rebuild formation
            platoonUnits = self:GetPlatoonUnits()
            numberOfUnitsInPlatoon = table.getn(platoonUnits)
            # if we have a different number of units in our platoon, regather
            if (oldNumberOfUnitsInPlatoon != numberOfUnitsInPlatoon) then
                self:StopAttack()
                self:SetPlatoonFormationOverride(PlatoonFormation)
            end
            oldNumberOfUnitsInPlatoon = numberOfUnitsInPlatoon

            # deal with lost-puppy transports
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
                IssueTransportUnload( strayTransports, dropPoint )
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
                        IssueTransportUnload( strayTransports, dropPoint )
                        WaitSeconds(30)
                    end
                end
                self.UsingTransport = false
                AIUtils.ReturnTransportsToPool( strayTransports, true )
                platoonUnits = self:GetPlatoonUnits()
            end    
    

        	#Disband platoon if it's all air units, so they can be picked up by another platoon
            local mySurfaceThreat = AIAttackUtils.GetSurfaceThreatOfUnits(self)
            if mySurfaceThreat == 0 and AIAttackUtils.GetAirThreatOfUnits(self) > 0 then
                self:PlatoonDisband()
                return
            end
                        
            local cmdQ = {} 
            # fill cmdQ with current command queue for each unit
            for k,v in platoonUnits do
                if not v:IsDead() then
                    local unitCmdQ = v:GetCommandQueue()
                    for cmdIdx,cmdVal in unitCmdQ do
                        table.insert(cmdQ, cmdVal)
                        break
                    end
                end
            end            
            
            # if we're on our final push through to the destination, and we find a unit close to our destination
            local closestTarget = self:FindClosestUnit( 'attack', 'enemy', true, categories.ALLUNITS )
            local nearDest = false
            local oldPathSize = table.getn(self.LastAttackDestination)
            if self.LastAttackDestination then
                nearDest = oldPathSize == 0 or VDist3(self.LastAttackDestination[oldPathSize], pos) < 20
            end
            
            # if we're near our destination and we have a unit closeby to kill, kill it
            if table.getn(cmdQ) <= 1 and closestTarget and VDist3( closestTarget:GetPosition(), pos ) < 20 and nearDest then
                self:StopAttack()
                if PlatoonFormation != 'No Formation' then
                    IssueFormAttack(platoonUnits, closestTarget, PlatoonFormation, 0)
                else
                    IssueAttack(platoonUnits, closestTarget)
                end
                cmdQ = {1}
            # if we have nothing to do, try finding something to do        
            elseif table.getn(cmdQ) == 0 then
                self:StopAttack()
                cmdQ = AIAttackUtils.AIPlatoonSquadAttackVector( aiBrain, self )
                stuckCount = 0
            # if we've been stuck and unable to reach next marker? Ignore nearby stuff and pick another target  
            elseif self.LastPosition and VDist2Sq(self.LastPosition[1], self.LastPosition[3], pos[1], pos[3]) < ( self.PlatoonData.StuckDistance or 16) then
                stuckCount = stuckCount + 1
                if stuckCount >= 2 then               
                    self:StopAttack()
                    cmdQ = AIAttackUtils.AIPlatoonSquadAttackVector( aiBrain, self )
                    stuckCount = 0
                end
            else
                stuckCount = 0
            end
            
            self.LastPosition = pos
            
            if table.getn(cmdQ) == 0 then
                # if we have a low threat value, then go and defend an engineer or a base
                if mySurfaceThreat < 4  
                    and mySurfaceThreat > 0 
                    and not self.PlatoonData.NeverGuard 
                    and not (self.PlatoonData.NeverGuardEngineers and self.PlatoonData.NeverGuardBases)
                then
                    #LOG('*DEBUG: Trying to guard')
                    return self:GuardEngineer(self.AttackForceAI)
                end
                
                # we have nothing to do, so find the nearest base and disband
                if not self.PlatoonData.NeverMerge then
                    return self:ReturnToBaseAI()
                end
                WaitSeconds(5)
            else
                # wait a little longer if we're stuck so that we have a better chance to move
                WaitSeconds(Random(5,11) + 2 * stuckCount)
            end
        end
    end,
    
    #-----------------------------------------------------
    #   Function: ReturnToBaseAI
    #   Args:
    #       self - the single platoon to run the AI on
    #   Description:
    #       Finds a base to return to and disband - that way it can be used
    #       for a new platoon
    #   Returns:  
    #       nil (tail calls into AttackForceAI or disbands)
    #-----------------------------------------------------    
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
                # if we haven't moved in 10 seconds... go back to attacking
                if (distSq - oldDistSq) < 5 then
                    break
                end
                oldDistSq = distSq      
            end
        end
        # default to returning to attacking    
        return self:AttackForceAI()
    end,

    # -------------------
    #  Support Functions
    # -------------------
    
    # stop platoon and delete last attack destination so new one will be picked
    StopAttack = function(self)
        self:Stop()
        self.LastAttackDestination = {}
    end,
    
    # NOTES:
    # don't always use defensive point, use naval point for navies, etc.
    # or gather around center
    GatherUnits = function(self)
        local pos = self:GetPlatoonPosition()
        local unitsSet = true
        for k,v in self:GetPlatoonUnits() do
            if VDist2( v:GetPosition()[1], v:GetPosition()[3], pos[1], pos[3] ) > 40 then
               unitsSet = false
               break
            end
        end
        local aiBrain = self:GetBrain()
        if not unitsSet then
            AIUtils.AIGetClosestMarkerLocation(aiBrain, 'Defensive Point', pos[1], pos[3])
            local cmd = self:MoveToLocation( self:GetPlatoonPosition(), false )
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
    
    #-----------------------------------------------------
    #   Function: MergeWithNearbyPlatoons
    #   Args:
    #       self - the single platoon to run the AI on
    #       planName - AI plan to merge with
    #       radius - check to see if we should merge with platoons in this radius
    #   Description:
    #       Finds platoons nearby (when self platoon is not near a base) and merge
    #       with them if they're a good fit.
    #   Returns:  
    #       nil
    #-----------------------------------------------------   
    MergeWithNearbyPlatoons = function(self, planName, radius)
        # check to see we're not near an ally base
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
        # if we're too close to a base, forget it
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
            
            # make sure we're the same movement layer type to avoid hamstringing air of amphibious
            if self.MovementLayer != aPlat.MovementLayer then
                continue
            end
            
            if  VDist2Sq(platPos[1], platPos[3], allyPlatPos[1], allyPlatPos[3]) <= radiusSq then
                local units = aPlat:GetPlatoonUnits()
                local validUnits = {}
                local bValidUnits = false
                for _,u in units do
                    if not u:IsDead() and not u:IsUnitState( 'Attached' ) then
                        table.insert(validUnits, u)
                        bValidUnits = true
                    end
                end
                if not bValidUnits then
                    continue
                end
                #LOG("*AI DEBUG: Merging platoons " .. self.BuilderName .. ": (" .. platPos[1] .. ", " .. platPos[3] .. ") and " .. aPlat.BuilderName .. ": (" .. allyPlatPos[1] .. ", " .. allyPlatPos[3] .. ")")
                aiBrain:AssignUnitsToPlatoon( self, validUnits, 'Attack', 'GrowthFormation' )
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
    
    # ---------------------------------------------------------------------
    # Helper functions for GuardMarker AI
    
    # Checks radius around base to see if marker is sufficiently far away
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
    
    # greater than or less than check, based on what kind of threat order we want
    IsBetterThreat = function(findHighestThreat, newMarker, oldMarker)
        if findHighestThreat then
            return newMarker > oldMarker
        end         
        return newMarker < oldMarker
    end,     
    # ---------------------------------------------------------------------
    
    
    
    SetupEngineerCallbacks = function(eng)
        if eng and not eng:IsDead() and not eng.BuildDoneCallbackSet and eng.PlatoonHandle and eng:GetAIBrain():PlatoonExists(eng.PlatoonHandle) then                
            import('/lua/ScenarioTriggers.lua').CreateUnitBuiltTrigger(eng.PlatoonHandle.EngineerBuildDone, eng, categories.ALLUNITS)
            eng.BuildDoneCallbackSet = true
        end
        if eng and not eng:IsDead() and not eng.CaptureDoneCallbackSet and eng.PlatoonHandle and eng:GetAIBrain():PlatoonExists(eng.PlatoonHandle) then
            import('/lua/ScenarioTriggers.lua').CreateUnitStopCaptureTrigger(eng.PlatoonHandle.EngineerCaptureDone, eng )
            eng.CaptureDoneCallbackSet = true
        end
        if eng and not eng:IsDead() and not eng.ReclaimDoneCallbackSet and eng.PlatoonHandle and eng:GetAIBrain():PlatoonExists(eng.PlatoonHandle) then
            import('/lua/ScenarioTriggers.lua').CreateUnitStopReclaimTrigger(eng.PlatoonHandle.EngineerReclaimDone, eng )
            eng.ReclaimDoneCallbackSet = true
        end
        if eng and not eng:IsDead() and not eng.FailedToBuildCallbackSet and eng.PlatoonHandle and eng:GetAIBrain():PlatoonExists(eng.PlatoonHandle) then
            import('/lua/ScenarioTriggers.lua').CreateOnFailedToBuildTrigger(eng.PlatoonHandle.EngineerFailedToBuild, eng )
            eng.FailedToBuildCallbackSet = true
        end      
    end,
    
    # Callback functions for EngineerBuildAI
    EngineerBuildDone = function(unit, params)
        if not unit.PlatoonHandle then return end
        if not unit.PlatoonHandle.PlanName == 'EngineerBuildAI' then return end
        #LOG("*AI DEBUG: Build done " .. unit.Sync.id)
        if not unit.ProcessBuild then
            unit.ProcessBuild = unit:ForkThread(unit.PlatoonHandle.ProcessBuildCommand, true)
            unit.ProcessBuildDone = true
        end
    end,
    EngineerCaptureDone = function(unit, params)
        if not unit.PlatoonHandle then return end
        if not unit.PlatoonHandle.PlanName == 'EngineerBuildAI' then return end
        #LOG("*AI DEBUG: Capture done" .. unit.Sync.id)
        if not unit.ProcessBuild then
            unit.ProcessBuild = unit:ForkThread(unit.PlatoonHandle.ProcessBuildCommand, false)
        end
    end,
    EngineerReclaimDone = function(unit, params)
        if not unit.PlatoonHandle then return end
        if not unit.PlatoonHandle.PlanName == 'EngineerBuildAI' then return end
        #LOG("*AI DEBUG: Reclaim done" .. unit.Sync.id)
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
            unit.ProcessBuild = unit:ForkThread(unit.PlatoonHandle.ProcessBuildCommand, false)
        end   
    end,

    #-----------------------------------------------------
    #   Function: WatchForNotBuilding
    #   Args:
    #       eng - the engineer that's gone through EngineerBuildAI
    #   Description:
    #       After we try to build something, watch the engineer to
    #       make sure that the build goes through.  If not,
    #       try the next thing in the queue
    #   Returns:  
    #       nil
    #-----------------------------------------------------
    WatchForNotBuilding = function(eng)
        WaitTicks(5)
        local aiBrain = eng:GetAIBrain()
        while not eng:IsDead() and eng.GoingHome or eng:IsUnitState("Building") or 
                  eng:IsUnitState("Attacking") or eng:IsUnitState("Repairing") or 
                  eng:IsUnitState("Reclaiming") or eng:IsUnitState("Capturing") or eng.ProcessBuild != nil do
                  
            WaitSeconds(3)
            #if eng.CDRHome then eng:PrintCommandQueue() end
        end
        eng.NotBuildingThread = nil
        if not eng:IsDead() and eng:IsIdleState() and table.getn(eng.EngineerBuildQueue) != 0 and eng.PlatoonHandle then
            eng.PlatoonHandle.SetupEngineerCallbacks(eng)
            if not eng.ProcessBuild then
                eng.ProcessBuild = eng:ForkThread(eng.PlatoonHandle.ProcessBuildCommand, true)
            end
        end  
    end,
    
    #-----------------------------------------------------
    #   Function: ProcessBuildCommand
    #   Args:
    #       eng - the engineer that's gone through EngineerBuildAI
    #   Description:
    #       Run after every build order is complete/fails.  Sets up the next
    #       build order in queue, and if the engineer has nothing left to do
    #       will return the engineer back to the army pool by disbanding the
    #       the platoon.  Support function for EngineerBuildAI
    #   Returns:  
    #       nil (tail calls into a behavior function)
    #-----------------------------------------------------
    ProcessBuildCommand = function(eng, removeLastBuild)
        if not eng or eng:IsDead() or not eng.PlatoonHandle then
            if eng then eng.ProcessBuild = nil end
            return
        end
        
        local aiBrain = eng.PlatoonHandle:GetBrain()            
        if not aiBrain or eng:IsDead() or not eng.EngineerBuildQueue or table.getn(eng.EngineerBuildQueue) == 0 then
            if aiBrain:PlatoonExists(eng.PlatoonHandle) then
                #LOG("*AI DEBUG: Disbanding Engineer Platoon in ProcessBuildCommand " .. eng.Sync.id)
                eng.PlatoonHandle:PlatoonDisband()
            end
            if eng then eng.ProcessBuild = nil end
            return
        end
         
        # it wasn't a failed build, so we just finished something
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
        while not eng:IsDead() and not commandDone and table.getn(eng.EngineerBuildQueue) > 0  do
            local whatToBuild = eng.EngineerBuildQueue[1][1]
            local buildLocation = BuildToNormalLocation(eng.EngineerBuildQueue[1][2])
            local buildRelative = eng.EngineerBuildQueue[1][3]
            # see if we can move there first        
            if AIUtils.EngineerMoveWithSafePath(aiBrain, eng, buildLocation) then
                if not eng or eng:IsDead() or not eng.PlatoonHandle or not aiBrain:PlatoonExists(eng.PlatoonHandle) then
                    if eng then eng.ProcessBuild = nil end
                    return
                end
                # check to see if we need to reclaim or capture...
                if not AIUtils.EngineerTryReclaimCaptureArea(aiBrain, eng, buildLocation) then
                    # check to see if we can repair
                    if not AIUtils.EngineerTryRepair(aiBrain, eng, whatToBuild, buildLocation) then
                        # otherwise, go ahead and build the next structure there
                        aiBrain:BuildStructure( eng, whatToBuild, NormalToBuildLocation(buildLocation), buildRelative )
                        if not eng.NotBuildingThread then
                            eng.NotBuildingThread = eng:ForkThread(eng.PlatoonHandle.WatchForNotBuilding)
                        end
                    end
                end
                commandDone = true             
            else
                # we can't move there, so remove it from our build queue
                table.remove(eng.EngineerBuildQueue, 1)
            end
        end
        
        # final check for if we should disband
        if not eng or eng:IsDead() or table.getn(eng.EngineerBuildQueue) == 0 then
            if eng.PlatoonHandle and aiBrain:PlatoonExists(eng.PlatoonHandle) then
                #LOG("*AI DEBUG: Disbanding Engineer Platoon in ProcessBuildCommand " .. eng.Sync.id)
                eng.PlatoonHandle:PlatoonDisband()
            end
            if eng then eng.ProcessBuild = nil end
            return
        end
        if eng then eng.ProcessBuild = nil end       
    end,       
}
