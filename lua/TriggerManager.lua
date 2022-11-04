--****************************************************************************
--**
--**  File     :  /lua/TriggerManager.lua
--**  Author(s):  Dru Staltman
--**
--**  Summary  : The trigger manager.
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TriggerFile = import("/lua/scenariotriggers.lua")
local ScenarioFramework = import("/lua/scenarioframework.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")

---@class TriggerManager
Manager = {

    TriggerList = {},
    TriggerActions = {},

    --==================================================================================================
    -- Adding data functions below.
    --    Functions that add triggers and actions to the TM.
    --==================================================================================================

    OnCreate = function(self)
        self.Trash = TrashBag()
    end,

    OnDestroy = function(self)
        if self.Trash then
            self.Trash:Destroy()
        end
    end,

    -- Add a table of trigger specs
    AddTriggerTable = function(self, specTable)
        if specTable then
            for num, spec in specTable do
                self:AddTrigger(spec)
            end
        else
            error('TRIGGER MANAGER ERROR: No Trigger Specifications table supplied', 2)
            return false
        end
    end,

    -- Add a single trigger to the TM
    AddTrigger = function(self, spec)
        if not self.Trash then
            self.Trash = TrashBag()
        end
        if not spec.Name then
            error('TRIGGER MANAGER ERROR: No name defined in trigger spec', 2)
            return false
        end
        for name, tempTrigger in self.TriggerList do
            if name == spec.Name then
                error('TRIGGER MANAGER ERROR: Duplicate name exists in trigger manager- ' .. spec.Name, 2)
                return false
            end
        end
        if not spec.Type then
            error('TRIGGER MANAGER ERROR: No type defined in trigger named- ' .. spec.Name, 2)
            return false
        end
        if not spec.Parameters then
            error('TRIGGER MANAGER ERROR: No parameters defined in trigger named-' .. spec.Name, 2)
            return false
        end
        if spec.Active == nil then
            spec.Active = true
        end
        spec.WhichActions = {}
        ------ Checks if there is an action that relies on this trigger and adds to list of actions for this trigger
        for numAction, action in self.TriggerActions do
            local inserted = false
            for numTable, conditionTable in action.ActionConditions do
                if inserted then
                    break
                end
                for numCond, cond in conditionTable do
                    if cond == spec.Name then
                        inserted = true
                        table.insert(spec.WhichActions, action.Name)
                        break
                    end
                end
            end
        end
        spec.Status = false
        spec.CallbackParameters = {}
        self.TriggerList[spec.Name] = spec
        if spec.Active then
            local triggerHandle = self:TriggerStarter(spec)
            spec.Handle = triggerHandle
        else
            spec.Handle = false
        end
    end,

    AddActionTable = function(self, specTable)
        if specTable then
            for num, spec in specTable do
                self:AddAction(spec)
            end
        else
            error('TRIGGER MANAGER ERROR: No table of actions specified', 2)
            return
        end
    end,

    -- Add a single action to the TM
    AddAction = function(self, spec)
        if not self.Trash then
            self.Trash = TrashBag()
        end
        if not spec.Name then
            error('TRIGGER MANAGER ERROR: No named defined in action spec', 2)
            return false
        end
        for name, currTrigger in self.TriggerActions do
            if name == spec.Name then
                error('TRIGGER MANAGER ERROR: Duplicate name exists in action specs- ' .. spec.Name, 2)
                return false
            end
        end
        if not spec.Actions then
            error('TRIGGER MANAGER ERROR: No Actions defined in action named- ' .. spec.Name, 2)
            return false
        end
        if not spec.ActionConditions then
            error('TRIGGER MANAGER ERROR: No ActionConditions defined in action named- ' .. spec.Name, 2)
            return false
        end
        ---- checks if there are any triggers that are conditions of this action and adds to that triggers list
        for numTable, conditionTable in spec.ActionConditions do
            for numCond, cond in conditionTable do
                local shouldInsert = true
                if self.TriggerList[cond] then
                    for numAction, action in self.TriggerList[cond].WhichActions do
                        if action == spec.Name then
                            shouldInsert = false
                        end
                    end
                else
                    shouldInsert = false
                end
                if shouldInsert then
                    table.insert(self.TriggerList[cond].WhichActions, spec.Name)
                end
            end
        end
        if not spec.RunNum then
            spec.RunNum = 1
        end
        spec.ActionReady = true
        self.TriggerActions[spec.Name] = spec
    end,

    --==============================================================================
    -- Misc Trigger Functions below.
    --     Functions that enable/disable triggers and actions.  Used internally
    --     as well as by external scripts.
    --==============================================================================
    EnableTrigger = function(self, name)
        local trigger = self.TriggerList[name]
        if not trigger then
            error('TRIGGER MANAGER ERROR: Invalid trigger to activate named- ' .. name, 2)
            return false
        end
        if not trigger.Active then
            trigger.Active = true
            if trigger.Handle then
                trigger.OldHandle = trigger.Handle
                trigger.Handle = self:TriggerStarter(trigger)
            else
                trigger.Handle = self:TriggerStarter(trigger)
            end
            if not trigger.Handle then
                error('TRIGGER MANAGER ERROR: Could not enable trigger named- ' .. name, 2)
                return false
            end
        end
    end,

    DisableTrigger = function(self, name)
        local trigger = self.TriggerList[name]
        if not trigger then
            error('TRIGGER MANAGER ERROR: Invalid trigger to deactivate named- ' .. name, 2)
            return false
        end
        trigger.Active = false
        if trigger.Handle then
            trigger.Handle:Destroy()
            trigger.Handle = false
        end
    end,

    EnableAction = function(self, name, runNum)
        local action = self.TriggerActions[name]
        if action then
            action.ActionReady = true
            if runNum then
                action.RunNum = runNum
            end
        else
            error('TRIGGER MANAGER ERROR: Invalid action to enable named- ' .. name, 2)
            return false
        end
    end,

    DisableAction = function(self, name)
        local action = self.TriggerActions[name]
        if action then
            action.ActionReady = false
        else
            error('TRIGGER MANAGER ERROR: Invalid action to disable named- ' .. name, 2)
            return false
        end
    end,

    SetTriggerStatus = function(self, name, val)
        local trigger = self.TriggerList[name]
        if not trigger then
            error('TRIGGER MANAGER ERROR: Invalid trigger name to set status- ' .. name, 2)
            return false
        end
        trigger.Status = val
    end,

    TriggerStarter = function(self, trigger)
        if trigger.Type == 'Area' then
            return self:Area(trigger)
        elseif trigger.Type == 'Army Intel' then
            return self:ArmyIntel(trigger)
        elseif trigger.Type == 'Army Stats' then
            return self:ArmyStats(trigger)
        elseif trigger.Type == 'Econ Stats' then
            return self:EconStats(trigger)
        elseif trigger.Type == 'Group Death' then
            return self:GroupDeath(trigger)
        elseif trigger.Type == 'Mission Number' then
            return self:MissionNumber(trigger)
        elseif trigger.Type == 'Platoon Death' then
            return self:PlatoonDeath(trigger)
        elseif trigger.Type == 'Sub Group Death' then
            return self:SubGroupDeath(trigger)
        elseif trigger.Type == 'Threat Around Position' then
            return self:ThreatAroundPosition(trigger)
        elseif trigger.Type == 'Threat Around Unit' then
            return self:ThreatAroundUnit(trigger)
        elseif trigger.Type == 'Timer' then
            return self:Timer(trigger)
        elseif trigger.Type == 'Unit Built' then
            return self:UnitBuilt(trigger)
        elseif trigger.Type == 'Unit Captured' then
            return self:UnitCaptured(trigger)
        elseif trigger.Type == 'Unit Damaged' then
            return self:UnitDamaged(trigger)
        elseif trigger.Type == 'Unit Death' then
            return self:UnitDeath(trigger)
        elseif trigger.Type == 'Unit Failed Being Captured' then
            return self:UnitFailedBeingCaptured(trigger)
        elseif trigger.Type == 'Unit Failed Capture' then
            return self:UnitFailedCapture(trigger)
        elseif trigger.Type == 'Unit Near Type' then
            return self:UnitNearType(trigger)
        elseif trigger.Type == 'Unit Reclaimed' then
            return self:UnitReclaimed(trigger)
        elseif trigger.Type == 'Unit Start Being Captured' then
            return self:UnitStartBeingCaptured(trigger)
        elseif trigger.Type == 'Unit Start Capture' then
            return self:UnitStartCapture(trigger)
        elseif trigger.Type == 'Unit Start Reclaim' then
            return self:UnitStartReclaim(trigger)
        elseif trigger.Type == 'Unit Stop Being Captured' then
            return self:UnitStopBeingCaptured(trigger)
        elseif trigger.Type == 'Unit Stop Capture' then
            return self:UnitStopCapture(trigger)
        elseif trigger.Type == 'Unit Stop Reclaim' then
            return self:UnitStopReclaim(trigger)
        elseif trigger.Type == 'Unit To Position Distance' then
            return self:UnitToPositionDistance(trigger)
        elseif trigger.Type == 'Unit Veterancy' then
            return self:UnitVeterancy(trigger)
        elseif trigger.Type == 'Variable Bool Check' then
            return self:VariableBoolCheck(trigger)
        else
            error('TRIGGER MANAGER ERROR: Invalid Trigger type- "' .. trigger.Type .. '" in trigger named- '
                  .. trigger.Name, 2)
            return
        end
    end,

    --=======================================================================
    -- Trigger calling functions below.
    --     These are the functions that start the triggers for the manager
    --=======================================================================
    Area = function(self, spec)
        local params = spec.Parameters
        if not params.Rectangle or table.getn(params.Rectangle) <= 0 then
            error('TRIGGER MANAGER ERROR: No area defined for area trigger named-' .. spec.Name, 2)
            return false
        elseif not params.Category then
            error('TRIGGER MANAGER ERROR: No category defined for area trigger named-' .. spec.Name, 2)
            return false
        elseif not params.Brain then
            error('TRIGGER MANAGER ERROR: No Brain defined for area trigger named-' .. spec.Name, 2)
            return false
        end
        if params.RunOnce == nil then
            params.RunOnce = true
        end
        if params.Invert == nil then
            params.Invert = false
        end
        if not params.Number then
            if params.Invert then
                params.Number = 0
            else
                params.Number = 1
            end
        end
        if params.RequireBuilt == nil then
            params.RequireBuilt = true
        end
        local thread = ForkThread( TriggerFile.AreaTriggerThread, self.TriggerFire, params.Rectangle, params.Category,
                          params.RunOnce, params.Invert, params.Brain, params.Number,
                          params.RequireBuilt, spec.Name)
        self.Trash:Add(thread)
        return thread
    end,

    ArmyIntel = function(self, spec)
        local params = spec.Parameters
        if not params.ReconType then
            error('TRIGGER MANAGER ERROR: No ReconType for ArmyIntel trigger named- ' .. spec.Name, 2)
            return false
        elseif not params.Category then
            error('TRIGGER MANAGER ERROR: No Category for ArmyIntel trigger named- ' .. spec.Name, 2)
            return false
        elseif not params.TargetBrain then
            error('TRIGGER MANAGER ERROR: No TargetBrain for ArmyIntel trigger named- ' .. spec.Name, 2)
            return false
        elseif not params.Brain then
            error('TRIGGER MANAGER ERROR: No Brain for ArmyIntel trigger named- ' .. spec.Name, 2)
            return false
        end
        if not (params.ReconType == 'LOSNow' or params.ReconType == 'Radar' or params.ReconType == 'Sonar' or
                params.ReconType == 'Omni') then
            error('TRIGGER MANAGER ERROR: Invalid ReconType- "' .. params.ReconType .. '" for ArmyIntel trigger named- '
                  .. spec.Name, 2)
            return false
        end
        if not params.Blip then
            params.Blip = false
        end
        if not params.OnSight then
            params.OnSight = true
        end
        if not params.OnceOnly then
            params.OnceOnly = true
        end
        local callback = function()
                             TriggerManager:TriggerFire(spec.Name)
                         end
        TriggerFile.CreateArmyIntelTrigger(callback, params.Brain, params.ReconType, params.Blip, params.OnSight,
                                           params.Category, params.OnceOnly, params.TargetBrain)
        return true
    end,

    ArmyStats = function(self, spec)
        local params = spec.Parameters
        if not params.CompareType then
            params.CompareType = 'GreaterThanOrEqual'
        end
        local callback = function()
                             TriggerManager:TriggerFire(spec.Name)
                         end
        local brainSpec = { Name = spec.Name, CallbackFunction = callback, }
        local found = false
        for k,v in params.Brain.TriggerList do
            if v.Name == spec.Name then
                found = true
                break
            end
        end
        if not found then
            table.insert(params.Brain.TriggerList, brainSpec)
        end
        params.Brain:SetArmyStatsTrigger(params.StatName, spec.Name,
                                         params.CompareType,
                                         params.Number, params.Category )
        return true
    end,

    EconStats = function(self, spec)
        local params = spec.Parameters
        if not params.ResourceType then
            error('TRIGGER MANAGER ERROR: No StatName defined for EconStats trigger named- ' .. spec.Name, 2)
            return false
        elseif not params.EconType then
            error('TRIGGER MANAGER ERROR: No EconType defined for EconStats trigger named- ' .. spec.Name, 2)
            return false
        elseif not params.Number then
            error('TRIGGER MANAGER ERROR: No Number defined for EconStats trigger named- ' .. spec.Name, 2)
            return false
        elseif not params.Brain then
            error('TRIGGER MANAGER ERROR: No Brain defined for EconStats trigger named- ' .. spec.Name, 2)
            return false
        end
        if params.ResourceType ~= 'Mass' and params.ResourceType ~= 'Energy' then
            error('TRIGGER MANAGER ERROR: Invalid ResourceType- "' .. params.ResourceType ..
                  '" in EconStats trigger named- ' .. spec.Name, 2)
            return false
        end
        if not(params.EconType == 'TotalProduced' or params.EconType == 'TotalConsumed' or params.EconType == 'Income'
               or params.EconType == 'Output' or params.EconType == 'Stored' or params.EconType == 'Reclaimed'
               or params.EconType == 'Ratio' or params.EconType == 'MaxStorage' or params.EconType == 'PeakStorage'
               or params.EconType == 'Trend' ) then
            error('TRIGGER MANAGER ERROR: Invalid EconType- "' .. params.EconType .. '" in EconStats trigger named- '
                  .. spec.Name, 2)
        end

        if not params.CompareType then
            params.CompareType = 'GreaterThanOrEqual'
        end
        local callback = function()
                             TriggerManager:TriggerFire(spec.Name)
                         end
        local brainSpec = { Name = spec.Name, CallbackFunction = callback, }
        local found = false
        for k,v in params.Brain.TriggerList do
            if v.Name == spec.Name then
                found = true
                break
            end
        end
        if not found then
            table.insert(params.Brain.TriggerList, brainSpec)
        end
        local statName = 'Economy_' .. params.EconType .. '_' .. params.ResourceType
        params.Brain:SetArmyStatsTrigger(statName, spec.Name, params.CompareType, params.Number)
        return true
    end,

    GroupDeath = function(self, spec)
        local params = spec.Parameters
        if not params.Group then
            error('TRIGGER MANAGER ERROR: No Group defined for group death trigger named- ' .. spec.Name, 2)
            return false
        end
        local thread = ForkThread(TriggerFile.GroupDeathTriggerThread, self.TriggerFire, params.Group, spec.Name)
        self.Trash:Add(thread)
        return thread
    end,

    MissionNumber = function(self, spec)
        local params = spec.Parameters
        if not params.Value then
            error('TRIGGER MANAGER ERROR: No Value defined for Mission Number trigger named- ' .. spec.Name, 2)
            return false
        end
        local thread = ForkThread(TriggerFile.MissionNumberTriggerThread, self.TriggerFire, params.Value, spec.Name)
        self.Trash:Add(thread)
        return thread
    end,

    PlatoonDeath = function(self, spec)
        local params = spec.Parameters
        if not params.Platoon then
            error('TRIGGER MANAGER ERROR: No Platoon defined for Platoon Death trigger named- ' .. spec.Name, 2)
            return false
        end
        local callback = function(brain, platoon)
                             TriggerManager:TriggerFire(spec.Name, brain, platoon)
                         end
        params.Platoon:AddDestroyCallback(callback)
        return true
    end,

    SubGroupDeath = function(self, spec)
        local params = spec.Parameters
        if not params.Group then
            error('TRIGGER MANAGER ERROR: No Group defined for sub-group death trigger named- ' .. spec.Name, 2)
            return false
        elseif not params.Number then
            error('TRIGGER MANAGER ERROR: No Number defined for sub-group death trigger named- ' .. spec.Name, 2)
            return false
        end
        local thread = ForkThread(TriggerFile.SubGroupDeathTriggerThread, self.TriggerFire, params.Group, params.Number, spec.Name)
        self.Trash:Add(thread)
        return thread
    end,

    ThreatAroundPosition = function(self, spec)
        local params = spec.Parameters
        if not params.Position then
            error('TRIGGER MANAGER ERROR: No Position defined for ThreatAroundPosition trigger named- ' .. spec.Name, 2)
            return false
        elseif not params.Rings then
            error('TRIGGER MANAGER ERROR: No Rings defined for ThreatAroundPosition trigger named- ' .. spec.Name, 2)
            return false
        elseif not params.Number then
            error('TRIGGER MANAGER ERROR: No Number defined for ThreatAroundPosition trigger named- ' .. spec.Name, 2)
            return false
        elseif not params.Brain then
            error('TRIGGER MANAGER ERROR: No Brain defined for ThreatAroundPosition trigger named- ' .. spec.Name, 2)
            return false
        end
        if not params.Greater then
            params.Greater = true
        end
        if not params.OnceOnly then
            params.OnceOnly = true
        end
        local thread = ForkThread(TriggerFile.ThreatTriggerAroundPositionThread, self.TriggerFire, params.Brain,
                                 params.Position, params.Rings, params.OnceOnly, params.Number, params.Greater, spec.Name)
        self.Trash:Add(thread)
        return thread
    end,

    ThreatAroundUnit = function(self, spec)
        local params = spec.Parameters
        if not params.Unit then
            error('TRIGGER MANAGER ERROR: No Unit defined for ThreatAroundUnit trigger named- ' .. spec.Name, 2)
            return false
        elseif not params.Rings then
            error('TRIGGER MANAGER ERROR: No Rings defined for ThreatAroundUnit trigger named- ' .. spec.Name, 2)
            return false
        elseif not params.Number then
            error('TRIGGER MANAGER ERROR: No Number defined for ThreatAroundUnit trigger named- ' .. spec.Name, 2)
            return false
        elseif not params.Brain then
            error('TRIGGER MANAGER ERROR: No Brain defined for ThreatAroundUnit trigger named- ' .. spec.Name, 2)
            return false
        end
        if not params.Greater then
            params.Greater = true
        end
        if not params.OnceOnly then
            params.OnceOnly = true
        end
        local thread = ForkThread(TriggerFile.ThreatTriggerAroundUnitThread, self.TriggerFire, params.Brain, params.Unit,
                                  params.Rings, params.OnceOnly, params.Number, params.Greater, spec.Name)
        self.Trash:Add(thread)
        return thread
    end,

    Timer = function(self, spec)
        local params = spec.Parameters
        if not params.Duration then
            error('TRIGGER MANAGER ERROR: No durations defined for timer trigger named=' .. spec.Name, 2)
            return false
        end
        local thread = ForkThread(TriggerFile.TimerTriggerThread, self.TriggerFire, params.Duration, spec.Name)
        self.Trash:Add(thread)
        return thread
    end,

    UnitBuilt = function(self, spec)
        local params = spec.Parameters
        if not params.Unit then
            error('TRIGGER MANAGER ERROR: No Unit specified for UnitBuilt trigger named- ' .. spec.Name, 2)
            return false
        elseif not params.Category then
            error('TRIGGER MANAGER ERROR: No BuiltId specified for UnitBuilt trigger named- ' .. spec.Name, 2)
            return false
        end
        local callback = function(unit, builtUnit)
                             TriggerManager:TriggerFire(spec.Name, unit, builtUnit)
                         end
        TriggerFile.CreateUnitBuiltTrigger(callback, params.Unit, params.Category)
        return true
    end,

    UnitCaptured = function(self, spec)
        local params = spec.Parameters
        if not params.Unit then
            error('TRIGGER MANAGER ERROR: No Unit specified for unit trigger named- ' .. spec.Name, 2)
            return false
        end
        local callback = function(unit, affectingUnit)
                             TriggerManager:TriggerFire(spec.Name, unit, affectingUnit)
                         end
        TriggerFile.CreateUnitCapturedTrigger( callback, nil, params.Unit )
        return true
    end,

    UnitDamaged = function(self, spec)
        local params = spec.Parameters
        if not params.Unit then
            error('TRIGGER MANAGER ERROR: No Unit specified for unit trigger named- ' .. spec.Name, 2)
            return false
        end
        if not params.Amount then
            params.Amount = -1
        end
        if not params.RepeatNum then
            params.RepeatNum = 1
        end
        local callback = function(unit, instigator)
                             TriggerManager:TriggerFire(spec.name, unit, instigator)
                         end
        TriggerFile.CreateUnitDamagedTrigger( callback, params.Unit, params.Amount, params.RepeatNum )
        return true
    end,

    UnitDeath = function(self, spec)
        local params = spec.Parameters
        if not params.Unit then
            error('TRIGGER MANAGER ERROR: No Unit specified for unit death trigger named- ' .. spec.Name, 2)
            return false
        end
        local callback = function(unit)
                             TriggerManager:TriggerFire(spec.Name, params.Unit)
                         end
        TriggerFile.CreateUnitDeathTrigger(callback, params.Unit)
        return true
    end,

    UnitFailedBeingCaptured = function(self, spec)
        local params = spec.Parameters
        if not params.Unit then
            error('TRIGGER MANAGER ERROR: No Unit specified for unit trigger named- ' .. spec.Name, 2)
            return false
        end
        local callback = function(unit, affectingUnit)
                             TriggerManager:TriggerFire(spec.Name, unit, affectingUnit)
                         end
        TriggerFile.CreateUnitFailedBeingCapturedTrigger( callback, params.Unit )
        return true
    end,

    UnitFailedCapture = function(self, spec)
        local params = spec.Parameters
        if not params.Unit then
            error('TRIGGER MANAGER ERROR: No Unit specified for unit trigger named- ' .. spec.Name, 2)
            return false
        end
        local callback = function(unit, affectingUnit)
                             TriggerManager:TriggerFire(spec.Name, unit, affectingUnit)
                         end
        TriggerFile.CreateUnitFailedBeingCapturedTrigger( callback, params.Unit )
        return true
    end,

    UnitNearType = function(self, spec)
        local params = spec.Parameters
        if not params.Unit then
            error('TRIGGER MANAGER ERROR: No Unit specified for UnitNearType trigger named- ' .. spec.Name, 2)
            return false
        elseif not params.Category then
            error('TRIGGER MANAGER ERROR: No Category specified for UnitNearType trigger named- ' .. spec.Name, 2)
            return false
        elseif not params.TargetBrain then
            error('TRIGGER MANAGER ERROR: No TargetBrain specified for UnitNearType trigger named- ' .. spec.Name, 2)
            return false
        elseif not params.Distance then
            error('TRIGGER MANAGER ERROR: No Distance specified for UnitNearType trigger named- ' .. spec.Name, 2)
            return false
        end
        local thread = ForkThread(TriggerFile.CreateUnitNearTypeTriggerThread, self.TriggerFire, params.Unit,
                                  params.TargetBrain, params.Category, params.Distance, spec.Name)
        self.Trash:Add(thread)
        return thread
    end,

    UnitReclaimed = function(self, spec)
        local params = spec.Parameters
        if not params.Unit then
            error('TRIGGER MANAGER ERROR: No Unit specified for unit trigger named- ' .. spec.Name, 2)
            return false
        end
        local callback = function(unit, affectingUnit)
                             TriggerManager:TriggerFire(spec.Name, unit, affectingUnit)
                         end
        TriggerFile.CreateUnitReclaimedTrigger( callback, params.Unit )
        return true
    end,

    UnitStartBeingCaptured = function(self, spec)
        local params = spec.Parameters
        if not params.Unit then
            error('TRIGGER MANAGER ERROR: No Unit specified for unit trigger named- ' .. spec.Name, 2)
            return false
        end
        local callback = function(unit, affectingUnit)
                             TriggerManager:TriggerFire(spec.Name, unit, affectingUnit)
                         end
        TriggerFile.CreateUnitStartBeingCapturedTrigger( callback, params.Unit )
        return true
    end,

    UnitStartCapture = function(self, spec)
        local params = spec.Parameters
        if not params.Unit then
            error('TRIGGER MANAGER ERROR: No Unit specified for unit trigger named- ' .. spec.Name, 2)
            return false
        end
        local callback = function(unit, affectingUnit)
                             TriggerManager:TriggerFire(spec.Name, unit, affectingUnit)
                         end
        TriggerFile.CreateUnitStartCaptureTrigger( callback, params.Unit )
        return true
    end,

    UnitStartReclaim = function(self, spec)
        local params = spec.Parameters
        if not params.Unit then
            error('TRIGGER MANAGER ERROR: No Unit specified for unit trigger named- ' .. spec.Name, 2)
            return false
        end
        local callback = function(unit, affectingUnit)
                             TriggerManager:TriggerFire(spec.Name, unit, affectingUnit)
                         end
        TriggerFile.CreateUnitStartReclaimTrigger( callback, params.Unit )
        return true
    end,

    UnitStopBeingCaptured = function(self, spec)
        local params = spec.Parameters
        if not params.Unit then
            error('TRIGGER MANAGER ERROR: No Unit specified for unit trigger named- ' .. spec.Name, 2)
            return false
        end
        local callback = function(unit, affectingUnit)
                             TriggerManager:TriggerFire(spec.Name, unit, affectingUnit)
                         end
        TriggerFile.CreateUnitStopBeingCapturedTrigger( callback, params.Unit )
        return true
    end,

    UnitStopCapture = function(self, spec)
        local params = spec.Parameters
        if not params.Unit then
            error('TRIGGER MANAGER ERROR: No Unit specified for unit trigger named- ' .. spec.Name, 2)
            return false
        end
        local callback = function(unit, affectingUnit)
                             TriggerManager:TriggerFire(spec.Name, unit, affectingUnit)
                         end
        TriggerFile.CreateUnitStopCaptureTrigger( callback, params.Unit )
        return true
    end,

    UnitStopReclaim = function(self, spec)
        local params = spec.Parameters
        if not params.Unit then
            error('TRIGGER MANAGER ERROR: No Unit specified for unit trigger named- ' .. spec.Name, 2)
            return false
        end
        local callback = function(unit, affectingUnit)
                             TriggerManager:TriggerFire(spec.Name, unit, affectingUnit)
                         end
        TriggerFile.CreateUnitStopReclaimTrigger( callback, params.Unit )
        return true
    end,

    UnitToPositionDistance = function(self, spec)
        local params = spec.Parameters
        if not params.Unit then
            error('TRIGGER MANAGER ERROR: No Unit Specified for UnitToPositionDistance trigger named- ' .. spec.Name, 2)
            return false
        elseif not params.Position then
            error('TRIGGER MANAGER ERROR: No Position Specified for UnitToPositionDistance trigger named- '.. spec.Name,2)
            return false
        elseif not params.Distance then
            error('TRIGGER MANAGER ERROR: No Distance specified for UnitToPositionDistance trigger named- '.. spec.name,2)
            return false
        end
        local thread = ForkThread(TriggerFile.UnitToPositionDistanceTriggerThread, self.TriggerFire, params.Unit,
                                  params.Position, params.Distance, spec.Name)
        self.Trash:Add(thread)
        return thread
    end,

    UnitVeterancy = function(self, spec)
        local params = spec.Parameters
        if not params.Unit then
            error('TRIGGER MANAGER ERROR: No Unit specified for unit veterancy trigger named- ' .. spec.Name, 2)
            return false
        end
        local callback = function(unit, level)
                             TriggerManager:TriggerFire(spec.Name, unit, level)
                         end
        TriggerFile.CreateUnitVeterancyTrigger(callback, params.Unit)
        return true
    end,

    VariableBoolCheck = function(self, spec)
        local params = spec.Parameters
        if not params.VariableName then
            error('TRIGGER MANAGER ERROR: No VariableName specifiec for Variable Bool Check trigger named- '
                  .. spec.Name, 2)
            return false
        end
        if not params.Value then
            params.Value = true
        end
        local thread = ForkThread(TriggerFile.VariableBoolCheckThread, self.TriggerFire, params.VariableName,
                                  params.Value, spec.Name)
        self.Trash:Add(thread)
        return thread
    end,

    VariableCheck = function(self, spec)
        local params = spec.Parameters
        if not params.VariableName then
            error('TRIGGER MANAGER ERROR: No VariableName specifiec for Variable Check trigger named- ' .. spec.Name, 2)
            return false
        elseif not params.Value then
            error('TRIGGER MANAGER ERROR: No Value specified for Variable Check trigger named- ' .. spec.Name, 2)
            return false
        end
        local thread = ForkThread(TriggerFile.VariableCheckThread, self.TriggerFire, params.VariableName,
                                  params.Value, spec.Name)
        self.Trash:Add(thread)
        return thread
    end,



    --==========================================================================
    -- Trigger action functions below.
    --     These are the functions that perform specific actions defined in
    --     Trigger actions.
    --=========================================================================
    ChangeArmyAlliance = function(self, action, conditionList)
        local params = action.Parameters
        if not params.ArmyName then
            error('TRIGGER MANAGER ERROR: No ArmyName given to Change Army Alliance action named- ' .. action.Name, 2)
            return false
        elseif not params.TargetArmyName then
            error('TRIGGER MANAGER ERROR: No TargetArmyName given to Change Army Alliance action named- '
                  .. action.Name, 2)
            return false
        elseif not params.Relationship then
            error('TRIGGER MANAGER ERROR: No Relationship given to Change Army Alliance action named- ' .. action.Name, 2)
            return false
        elseif not( params.Relationship == 'Ally' or params.Relationship == 'Enemy'
                   or params.Relationship == 'Neutral' ) then
            error('TRIGGER MANAGER ERROR: Invalid Relationship "' .. params.Relationship ..
                  '" given to Change Army Alliance action named- ' .. action.Name, 2)
            return false
        end
        if not params.Reflexive then
            params.Reflexive = false
        end
        local firstBrain = GetArmy(params.ArmyName)
        local secondBrain = GetArmy(params.TargetArmyName)
        SetAlliance(params.ArmyName, params.TargetArmyName, params.RelationShip)
        if params.Reflexive then
            SetAlliance(secondBrain, firstBrain, params.RelationShip)
        end
    end,

    ChangeArmyColor = function(self, action, conditionList)
        local params = action.Parameters
        if not params.ArmyName then
            error('TRIGGER MANAGER ERROR: No ArmyName given to Change Army Color action named- ' .. action.Name, 2)
            return false
        elseif not params.Red then
            error('TRIGGER MANAGER ERROR: No Color given to Change Army Color action named- ' .. action.Name, 2)
            return false
        elseif not params.Green then
            error('TRIGGER MANAGER ERROR: No Color given to Change Army Color action named- ' .. action.Name, 2)
            return false
        elseif not params.Blue then
            error('TRIGGER MANAGER ERROR: No Color given to Change Army Color action named- ' .. action.Name, 2)
            return false
        end
        SetArmyColor(params.ArmyName, params.Red, params.Green, params.Blue)
    end,

    ChangePlatoonAI = function(self, action, conditionList)
        local params = action.Parameters
        if not params.Platoon and not params.PlatoonName then
            error('TRIGGER MANAGER ERROR: No Platoon or PlatoonName given to Change Platoon AI action named- '
                  .. action.Name, 2)
            return false
        elseif params.PlatoonName and not params.ArmyName then
            error('TRIGGER MANAGER ERROR: No ArmyName given with PlatoonName to Change Platoon AI action named- '
                  .. action.Name, 2)
            return false
        elseif not params.AIName and not params.AIFunction then
            error('TRIGGER MANAGER ERROR: No AIName or AIFunction given to ChangePlatoon AI action named- '
                  .. action. Name, 2)
            return false
        end
        local armyIndex = GetArmyBrain(params.ArmyName):GetArmyIndex()
        if params.PlatoonName and params.ArmyName then
            params.Platoon = ScenarioInfo.PlatoonHandles[armyIndex][params.PlatoonName]
        end
        if params.PlatoonData then
            params.Platoon.PlatoonData = params.PlatoonData
        end
        if params.AIName then
            params.AIFunction = params.Platoon[params.AIName]
        end
        params.Platoon:StopAI()
        params.Platoon:ForkAIThread(params.AIFunction)
    end,

    DamageUnits = function(self, action, conditionList)
        local params = action.Parameters
        if not params.Group and not params.GroupName and not params.Unit and not params.UnitName then
            error('TRIGGER MANAGER ERROR: No Group, GroupName, Unit, or UnitName given to Damage Units action named- '
                  .. action.Name, 2)
            return false
        elseif ( params.GroupName or params.UnitName ) and not params.ArmyName then
            error('TRIGGER MANAGER ERROR: No ArmyName given to Damage Units action named- ' .. action.Name, 2)
            return false
        elseif not (params.DamageAmountMin and params.DamageAmountMax) and
            not (params.DamagePercentMin and params.DamagePercentMax) then
            error('TRIGGER MANAGER ERROR: Missing DamageAmountMix/Max or DamagePercentMin/Max in Damage Units action named- ' .. action.Name, 2)
            return false
        elseif ((params.DamageAmountMin and params.DamageAmountMax) and (params.DamagePercentMin or params.DamagePercentMax))
            or((params.DamagePercentMin and params.DamagePercentMax)and(params.DamageAmountMin or params.DamageAmountMax))then
            error('TRIGGER MANAGER ERROR: Both DamageAmount and DamagePercent provided to Damage Units action named- ' ..
                  action.Name .. ': Only one of the two is allowed.', 2)
            return false
        end
        local armyIndex
        if params.ArmyName then
            armyIndex = GetArmyBrain(params.StartArmyName):GetArmyIndex()
        end
        if not params.Group then
            params.Group = {}
        end
        if params.Unit then
            table.insert(params.Group, params.Unit)
        end
        if params.GroupName then
            if ScenarioInfo.UnitGroups[armyIndex][params.GroupName] then
                for unitNum, unit in ScenarioInfo.UnitGroups[armyIndex][params.GroupName] do
                    table.insert(params.Group, params.Unit)
                end
            else
                error('TRIGGER MANAGER ERROR: GroupName "' .. params.GroupName .. '" does not exist for ArmyName "'
                      .. params.ArmyName .. '" in Damage Units action named- ' .. action.Name, 2)
                return false
            end
        end
        if params.UnitName then
            if ScenarioInfo.UnitNames[armyIndex][params.UnitName] then
                table.insert(params.Group, ScenarioInfo.UnitNames[armyIndex][params.UnitName])
            else
                error('TRIGGER MANAGER ERROR: UnitName "' .. params.UnitName .. '" does not exist for ArmyName "'
                      .. params.ArmyName .. '" in DamageUnits action named- ' .. action.Name, 2)
                return false
            end
        end
        if params.DamageAmountMin then
            for numUnit, unit in params.Group do
                unit:AdjustHealth(unit, Random(params.DamageAmountMin, params.DamageAmountMax))
            end
        else
            for numUnit, unit in params.Group do
                local health = unit:GetBlueprint().Defense.MaxHealth
                unit:AdjustHealth(unit, Random(params.DamagePercentMin * health, params.DamagePercentMax * health))
            end
        end
    end,

    DestroyUnits = function(self, action, conditionList)
        local params = action.Parameters
        if not params.Group and not params.GroupName and not params.Unit and not params.UnitName then
            error('TRIGGER MANAGER ERROR: No Group, GroupName, Unit, or UnitName given to Destroy Units action named- '
                  .. action.Name, 2)
            return false
        elseif ( params.GroupName or params.UnitName ) and not params.ArmyName then
            error('TRIGGER MANAGER ERROR: No ArmyName given to Destroy Units action named- ' .. action.Name, 2)
            return false
        end
        if not params.Group then
            params.Group = {}
        end
        if params.Unit then
            table.insert(params.Group, params.Unit)
        end
        if params.GroupName then
            if ScenarioInfo.UnitGroups[armyIndex][params.GroupName] then
                for unitNum, unit in ScenarioInfo.UnitGroups[armyIndex][params.GroupName] do
                    table.insert(params.Group, params.Unit)
                end
            else
                error('TRIGGER MANAGER ERROR: GroupName "' .. params.GroupName .. '" does not exist for ArmyName "'
                      .. params.ArmyName .. '" in Destroy Units action named- ' .. action.Name, 2)
                return false
            end
        end
        if params.UnitName then
            if ScenarioInfo.UnitNames[armyIndex][params.UnitName] then
                table.insert(params.Group, ScenarioInfo.UnitNames[armyIndex][params.UnitName])
            else
                error('TRIGGER MANAGER ERROR: UnitName "' .. params.UnitName .. '" does not exist for ArmyName "'
                      .. params.ArmyName .. '" in Destroy Units action named- ' .. action.Name, 2)
                return false
            end
        end
        for numUnit, unit in params.Group do
            unit:Destroy()
        end
    end,

    FunctionCall = function(self, action, conditionList)
        local paramTable = {}
        for condNum, condName in conditionList do
            for pNum, param in self.TriggerList[condName].CallbackParameters do
                table.insert( paramTable, param )
            end
        end
        for paramNum, parameter in action.Parameters.Functions do
            local thread = ForkThread(parameter, unpack(paramTable))
            self.Trash:Add(thread)
        end
    end,

    GiveArmyUnits = function(self, action, conditionList)
        local params = action.Parameters
        if not params.TargetArmyName then
            error('TRIGGER MANAGER ERROR: No TargetArmyName given to Give Army Units action named- ' .. action.Name, 2)
            return false
        elseif not params.Group and not params.GroupName and not params.Unit and not params.UnitName then
            error('TRIGGER MANAGER ERROR: No Group, GroupName, Unit, or UnitName given to Give Army Units action named- '
                  .. action.Name, 2)
            return false
        elseif ( params.GroupName or params.UnitName ) and not params.StartArmyName then
            error('TRIGGER MANAGER ERROR: No StartArmyName given to Give Army Units action named- ' .. action.Name, 2)
            return false
        end
        local armyIndex
        if params.ArmyName then
            armyIndex = GetArmyBrain(params.StartArmyName):GetArmyIndex()
        end
        local targetIndex = GetArmyBrain(params.TargetArmyName):GetArmyIndex()
        if params.GroupName then
            if ScenarioInfo.UnitGroups[armyIndex][params.GroupName] then
                local group = ScenarioInfo.UnitGroups[armyIndex][params.GroupName]
                for unitNum, unit in group do
                    ScenarioFramework.GiveUnitToArmy(unit, targetIndex)
                end
            else
                error('TRIGGER MANAGER ERROR: GroupName "' .. params.GroupName .. '" does not exist for GroupArmyName "'
                      .. params.StartArmyName .. '" in Give Army Units action named- ' .. action.Name, 2)
                return false
            end
        end
        if params.UnitName then
            if ScenarioInfo.UnitNames[armyIndex][params.UnitName] then
                ScenarioFramework.GiveUnitToArmy(ScenarioInfo.UnitNames[armyIndex][params.UnitName], targetIndex)
            else
                error('TRIGGER MANAGER ERROR: UnitName "' .. params.UnitName .. '" does not exist for GroupArmyName "'
                      .. params.StartArmyName .. '" in Give Army Units action named- ' .. action.Name, 2)
                return false
            end
        end
        if params.Unit then
            ScenarioFramework.GiveUnitToArmy(params.Unit, targetIndex)
        end
        if params.Group then
            for unitNum, unit in params.Group do
                ScenarioFramework.GiveUnitToArmy(unit, GetArmyBrain(params.TargetArmyName):GetArmyIndex())
            end
        end
    end,

    GiveOrders = function(self, action, conditionList)
        local params = action.Parameters
        if not params.Unit and not params.Group then
            error('TRIGGER MANAGER ERROR: No Unit or Group given to Give Orders action named- ' .. action.Name, 2)
            return false
        elseif not params.Order then
            error('TRIGGER MANAGER ERROR: No Order given to Give Orders action named- ' .. action.Name, 2)
            return false
        end
        if params.Unit then
            params.Group = {params.Unit}
        end
        if params.Target then
            ScenarioUtils.AssignOrders(params.Order, params.Group, params.Target)
        else
            ScenarioUtils.AssignOrders(params.Order, params.Group)
        end
    end,

    KillUnits = function(self, action, conditionList)
        local params = action.Parameters
        if not params.Group and not params.GroupName and not params.Unit and not params.UnitName then
            error('TRIGGER MANAGER ERROR: No Group, GroupName, Unit, or UnitName given to Kill Units action named- '
                  .. action.Name, 2)
            return false
        elseif ( params.GroupName or params.UnitName ) and not params.ArmyName then
            error('TRIGGER MANAGER ERROR: No ArmyName given to Kill Units action named- ' .. action.Name, 2)
            return false
        end
        if not params.Group then
            params.Group = {}
        end
        if params.Unit then
            table.insert(params.Group, params.Unit)
        end
        if params.GroupName then
            if ScenarioInfo.UnitGroups[armyIndex][params.GroupName] then
                for unitNum, unit in ScenarioInfo.UnitGroups[armyIndex][params.GroupName] do
                    table.insert(params.Group, params.Unit)
                end
            else
                error('TRIGGER MANAGER ERROR: GroupName "' .. params.GroupName .. '" does not exist for ArmyName "'
                      .. params.ArmyName .. '" in Kill Units action named- ' .. action.Name, 2)
                return false
            end
        end
        if params.UnitName then
            if ScenarioInfo.UnitNames[armyIndex][params.UnitName] then
                table.insert(params.Group, ScenarioInfo.UnitNames[armyIndex][params.UnitName])
            else
                error('TRIGGER MANAGER ERROR: UnitName "' .. params.UnitName .. '" does not exist for ArmyName "'
                      .. params.ArmyName .. '" in Kill Units action named- ' .. action.Name, 2)
                return false
            end
        end
        for numUnit, unit in params.Group do
            unit:Kill()
        end
    end,

    LogText = function(self, action, conditionList)
        local params = action.Parameters
        if not params.Text then
            error('TRIGGER MANAGER ERROR: No Text provided for Log Text action named- ' .. action.Name, 2)
            return false
        end
        LOG('TRIGGER MANAGER LOG: ' .. params.Text)
    end,

    PlayableArea = function(self, action, conditionList)
        if action.Parameters.Area then
            ScenarioFramework.SetPlayableArea(action.Parameters.Area)
        else
            error('TRIGGER MANAGER ERROR: No Parameters given to Playable Area Action named- ' .. action.Name, 2)
            return false
        end
    end,

    PlayVO = function(self, action, conditionList)
        if action.Parameters then
            for pNum, pDialogue in action.Parameters.Dialogues do
                ScenarioFramework.Dialogue(pDialogue)
            end
        end
    end,

    PrintText = function(self, action, conditionList)
        local params = action.Parameters
        if not params.Text then
            error('TRIGGER MANAGER ERROR: No Text given to Print Text action named- ' .. action.Name, 2)
            return false
        end
        print(params.Text)
    end,

    SpawnGroup = function(self, action, conditionList)
        local params = action.Parameters
        if not params.GroupName then
            error('TRIGGER MANAGER ERROR: No GroupName given to Spawn Group action named- ' .. action.Name, 2)
            return false
        elseif not params.ArmyName then
            error('TRIGGER MANAGER ERROR: No ArmyName given to Spawn Group action named- ' .. action.Name, 2)
            return false
        end
        if not params.StoreName then
            params.StoreName = params.GroupName
        end
        local group, unitTree, platoonList = ScenarioUtils.CreateArmyGroup(params.ArmyName, params.GroupName)
        local armyIndex = GetArmyBrain(params.ArmyName):GetArmyIndex()
        ScenarioInfo.UnitGroups[armyIndex][params.StoreName] = group
        for platName, platoon in platoonList do
            ScenarioInfo.PlatoonHandles[armyIndex][platName] = platoon
        end
    end,

    SpawnSubGroup = function(self, action, conditionList)
        local params = action.Parameters
        if not params.ArmyName then
            error('TRIGGER MANAGER ERROR: No ArmyName given to Spawn Sub Group action named- ' .. action.Name, 2)
            return false
        elseif not params.Groups then
            error('TRIGGER MANAGER ERROR: No Groups given to Spawn Sub Group action named- ' .. action.Name, 2)
            return false
        elseif not params.StoreName then
            error('TRIGGER MANAGER ERROR: No StoreName given to Spawn Sub Group action named- ' .. action.Name, 2)
            return false
        end
        local group, unitTree, platoonList = ScenarioUtils.CreateArmySubGroup(params.ArmyName, unpack(params.Groups))
        local armyIndex = GetArmyBrain(params.ArmyName):GetArmyIndex()
        ScenarioInfo.UnitGroups[armyIndex][params.StoreName] = group
        for platName, platoon in platoonList do
            ScenarioInfo.PlatoonHandles[armyIndex][platName] = platoon
        end
    end,

    SpawnUnit = function(self, action, conditionList)
        local params = action.Parameters
        if not params.ArmyName then
            error('TRIGGER MANAGER ERROR: No ArmyName given to Spawn Unit action named- ' .. action.Name, 2)
            return false
        elseif not params.UnitName then
            error('TRIGGER MANAGER ERROR: No UnitName given to Spawn Unit action named- ' .. action.Name, 2)
            return false
        end
        if not params.StoreName then
            params.StoreName = params.UnitName
        end
        local unit, platoon, platoonName = ScenarioUtils.CreateArmyUnit(params.ArmyName, params.UnitName)
        local armyIndex = GetArmyBrain(params.ArmyName):GetArmyIndex()
        ScenarioInfo.UnitNames[armyIndex][params.StoreName] = unit
        if platoon and platoonName then
            ScenarioInfo.PlatoonHandles[armyIndex][platoonName] = platoon
        end
    end,




    --============================================================================
    -- Trigger evaluation functions below.
    --    Functions that are run when a trigger is fired. Determines what actions,
    --    if any, need to be run when a trigger fires
    --============================================================================
    TriggerFire = function(self, name, ...)
        local trigger = self.TriggerList[name]
        if trigger.Active then
            trigger.Active = false
            trigger.Status = true
            if arg['n'] > 0 then
                local i = 1
                while i <= arg['n'] do
                    table.insert( trigger.CallbackParameters, arg[i])
                    i = i + 1
                end
            end
            for num, action in trigger.WhichActions do
                self:EvaluateTriggerAction(action)
            end
        end
    end,

    EvaluateTriggerAction = function(self, actionName)
        if not self.TriggerActions[actionName] then
            error('TRIGGER MANAGER ERROR: No action named-' .. actionName, 2)
            return false
        end
        -- Iterates through conditions on the actions and checks if they are all met
        for listNum, conditionList in self.TriggerActions[actionName].ActionConditions do
            local fireTrigger = true
            for condNum, condName in conditionList do
                if not self.TriggerList[condName].Status then
                    fireTrigger = false
                end
            end
            if fireTrigger then
                if self.TriggerActions[actionName].ActionReady then
                    self:DoTriggerActions(actionName, conditionList)
                    break
                end
            end
        end
    end,

    DoTriggerActions = function(self, actionName, conditionList)
        local actionTable = self.TriggerActions[actionName].Actions
        for actNum, action in actionTable do
            if action.ActionType == 'Enable Trigger' then
                for pNum, pName in action.Parameters.Triggers do
                    self:EnableTrigger(pName)
                end
            elseif action.ActionType == 'Disable Trigger' then
                for pNum, pName in action.Parameters.Triggers do
                    self:DisableTrigger(pName)
                end
            elseif action.ActionType == 'Enable Action' then
                for pNum, pName in action.Parameters.Actions do
                    self:EnableAction(pName)
                end
            elseif action.ActionType == 'Disable Action' then
                for pNum, pName in action.Parameters.Actions do
                    self:DisableAction(pName)
                end
            elseif action.ActionType == 'Function Call' then
                self:FunctionCall(action, conditionList)
            elseif action.ActionType == 'Play VO' then
                self:PlayVO(action, conditionList)
            elseif action.ActionType == 'Playable Area' then
                self:PlayableArea(action, conditionList)
            elseif action.ActionType == 'Spawn Group' then
                self:SpawnGroup(action, conditionList)
            elseif action.ActionType == 'Spawn Sub Group' then
                self:SpawnSubGroup(action, conditionList)
            elseif action.ActionType == 'Spawn Unit' then
                self:SpawnUnit(action, conditionList)
            elseif action.ActionType == 'Give Orders' then
                self:GiveUnitOrder(action, conditionList)
            elseif action.ActionType == 'Change Platoon AI' then
                self:ChangePlatoonAI(action, conditionList)
            elseif action.ActionType == 'Change Army Alliance' then
                self:ChangeArmyAlliance(action, conditionList)
            elseif action.ActionType == 'Change Army Color' then
                self:ChangeArmyColor(action, conditionList)
            elseif action.ActionType == 'Give Army Units' then
                self:GiveArmyUnits(action, conditionList)
            elseif action.ActionType == 'Damage Units' then
                self:DamageUnits(action, conditionList)
            elseif action.ActionType == 'Kill Units' then
                self:KillUnits(action, conditionList)
            elseif action.ActionType == 'Destroy Units' then
                self:DestroyUnits(action, conditionList)
            elseif action.ActionType == 'Log Text' then
                self:LogText(action, conditionList)
            elseif action.ActionType == 'Print Text' then
                self:PrintText(action, conditionList)
            elseif action.ActionType == 'Give Mass' then
                for pNum, pVars in action.Parameters do
                    GetArmyBrain[pVars.ArmyName]:GiveResource('MASS', pVars.Amount)
                end
            elseif action.ActionType == 'Give Energy' then
                for pNum, pVars in action.Parameters do
                    GetArmyBrain[pVars.ArmyName]:GiveResource('ENERGY', pVars.Amount)
                end
            elseif action.ActionType == 'Set Variable' then
                for pNum, pVars in action.Parameters do
                    ScenarioInfo.VarTable[pVars.Name] = pVars.Value
                end
            elseif action.ActionType == 'Set Mission Number' then
                ScenarioInfo.VarTable['Mission Number'] = action.Parameters.Value
            else
                error('TRIGGER MANAGER ERROR: Invalid Action Type- "' .. action.ActionType
                      .. '"  in Action named- ' .. actionName, 2)
                return false
            end
        end
        if self.TriggerActions[actionName].RunNum == 1 then
            self.TriggerActions[actionName].ActionReady = false
        elseif self.TriggerActions[actionName].RunNum ~= -1 then
            self.TriggerActions[actionName].RunNum = self.TriggerActions[actionName].RunNum - 1
        end
    end,

}

