------------------------------------------------------------------
--  File     :  /data/lua/scenariotriggers.lua
--  Author(s):  John Comes
--  Summary  :  Generalized trigger functions for scenarios.
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")

---@alias NamedTriggerCallback            fun(manager: TriggerManager, name: string)
---@alias NamedUnitTriggerCallback        fun(manager: TriggerManager, name: string, trigger: Unit)
---@alias NamedGroupTriggerCallback       fun(manager: TriggerManager, name: string, group: Unit[])
---@alias NamedAreaTriggerCallback        fun(manager: TriggerManager, name: string, group: Unit | Unit[])
---@alias NamedInstigatorTriggerCallback  fun(manager: TriggerManager, name: string, unit: Unit, instigator: Unit)
---@alias TriggerCallback            fun()
---@alias UnitTriggerCallback        fun(trigger: Unit)
---@alias GroupTriggerCallback       fun(group: Unit[])
---@alias AreaTriggerCallback        fun(group: Unit | Unit[])
---@alias InstigatorTriggerCallback  fun(unit: Unit, instigator: Unit)

---@alias ArmyStateCompareType "GreaterThan" | "GreaterThanOrEqual" | "LessThan" | "LessThanOrEqual"

---@alias ArmyStatType
---| "Units_Active"
---| "Units_Killed"
---| "Units_History"
---| "Enemies_Killed"
---| "Economy_TotalProduced_Energy"
---| "Economy_TotalConsumed_Energy"
---| "Economy_Income_Energy"
---| "Economy_Output_Energy"
---| "Economy_Stored_Energy"
---| "Economy_Reclaimed_Energy"
---| "Economy_MaxStorage_Energy"
---| "Economy_PeakStorage_Energy"
---| "Economy_TotalProduced_Mass"
---| "Economy_TotalConsumed_Mass"
---| "Economy_Income_Mass"
---| "Economy_Output_Mass"
---| "Economy_Stored_Mass"
---| "Economy_Reclaimed_Mass"
---| "Economy_MaxStorage_Mass"
---| "Economy_PeakStorage_Mass"

---@class ArmyStatTrigger
---@field StatType ArmyStatType
---@field CompareType ArmyStateCompareType
---@field Value number
---@field Category EntityCategory



--- Creates an area trigger around `area` that fires `callback` when there are `unitCount`
--- units of type `category` (optionally belonging to `aiBrain`) in it. The triggering units
--- are passed as an argument to the callback.
--- If it `unitCount` is absent, then the callback will receive only the first triggering unit
--- (or `nil` if none, due to `lessThan`).
--- If `name` is supplied, then the callback is called with TriggerManager and the name as arguments
--- before the triggering unit / group.
---@see CreateMutlipleAreaTrigger() to pass in multiple areas
---@param callback NamedAreaTriggerCallback | AreaTriggerCallback
---@param area Area | Rectangle
---@param category EntityCategory
---@param onceOnly? boolean
---@param lessThan? boolean
---@param aiBrain? AIBrain
---@param unitCount? number defaults to any (or none with `lessThan` set)
---@param requireBuilt? boolean
---@param name? string
---@return thread
function CreateAreaTrigger(callback, area, category, onceOnly, lessThan, aiBrain, unitCount, requireBuilt, name)
    return ForkThread(AreaTriggerThread, callback, {area}, category, onceOnly, lessThan, aiBrain, unitCount, requireBuilt, name)
end

--- Same as `CreateAreaTrigger` except you supply the function with a table of areas for if
--- you have an odd shaped area as an area trigger
---@see CreateAreaTrigger() to pass in a single area and information regarding arguments
---@param callback NamedAreaTriggerCallback | AreaTriggerCallback
---@param areas (Area | Rectangle)[]
---@param category EntityCategory
---@param onceOnly? boolean
---@param lessThan? boolean
---@param aiBrain? AIBrain
---@param unitCount? number defaults to any (or none with `lessThan` set)
---@param requireBuilt? boolean
---@param name? string
---@return thread
function CreateMultipleAreaTrigger(callback, areas, category, onceOnly, lessThan, aiBrain, unitCount, requireBuilt, name)
    return ForkThread(AreaTriggerThread, callback, areas, category, onceOnly, lessThan, aiBrain, unitCount, requireBuilt, name)
end

function AreaTriggerThread(callback, areas, category, onceOnly, lessThan, aiBrain, unitCount, requireBuilt, name)
    local recTable = ScenarioUtils.MultiAreaToMultiRect(areas)
    while true do
        local triggered = lessThan
        local trigger
        if unitCount then
            local amount
            trigger, amount = ScenarioUtils.GetUnitsInArea(recTable, category, aiBrain, requireBuilt)
            if unitCount >= amount then
                triggered = not triggered
            end
        else
            trigger = ScenarioUtils.FindUnitInArea(recTable, category, aiBrain, requireBuilt)
            if trigger then
                triggered = not triggered
            end
        end
        if triggered then
            if name then
                callback(TriggerManager, name, trigger)
            else
                callback(trigger)
            end
            if onceOnly then
                return
            end
        end
        WaitTicks(1)
    end
end

--- Creates a threat trigger that fires `callback` when the threat level to an `aiBrain` around
--- a `unit` exceeds or falls below `value`, depending on `greater` (but it always fires when equal).
--- If `name` is supplied, the callback is called with TriggerManager and the name as arguments.
---@param callback TriggerCallback | NamedTriggerCallback
---@param aiBrain AIBrain
---@param unit Unit
---@param rings boolean
---@param onceOnly boolean
---@param value number
---@param greater? boolean
---@param name? string
---@return thread
function CreateThreatTriggerAroundUnit(callback, aiBrain, unit, rings, onceOnly, value, greater, name)
    return ForkThread(ThreatTriggerAroundUnitThread, callback, aiBrain, unit, rings, onceOnly, value, greater, name)
end
function ThreatTriggerAroundUnitThread(callback, aiBrain, unit, rings, onceOnly, value, greater, name)
    while not unit.Dead do
        local threat = aiBrain:GetThreatAtPosition(unit:GetPosition(), rings, true)
        if (greater and threat >= value) or (not greater and threat <= value) then
            if name then
                callback(TriggerManager, name)
            else
                callback()
            end
            if onceOnly then
                return
            end
        end
        WaitSeconds(0.5)
    end
end

--- Creates a threat trigger that fires `callback` when the threat level to an `aiBrain` at a `pos`
--- exceeds or falls below `value`, depending on `greater` (but it always fires when equal).
--- If `name` is supplied, the callback is called with TriggerManager and the name as arguments.
---@param callback TriggerCallback | NamedTriggerCallback
---@param aiBrain AIBrain
---@param pos Marker | Vector
---@param rings boolean
---@param onceOnly boolean
---@param value number
---@param greater? boolean
---@param name? string
---@return thread
function CreateThreatTriggerAroundPosition(callback, aiBrain, pos, rings, onceOnly, value, greater, name)
    return ForkThread(ThreatTriggerAroundPositionThread, callback, aiBrain, pos, rings, onceOnly, value, greater, name)
end
function ThreatTriggerAroundPositionThread(callback, aiBrain, pos, rings, onceOnly, value, greater, name)
    if type(pos) == 'string' then
        pos = ScenarioUtils.MarkerToPosition(pos)
    end
    while true do
        local threat = aiBrain:GetThreatAtPosition(pos, rings, true)
        if (greater and threat >= value) or (not greater and threat <= value) then
            if name then
                callback(TriggerManager, name)
            else
                callback()
            end
            if onceOnly then
                return
            end
        end
        WaitSeconds(0.5)
    end
end

--- Creates a timer that fires `callback` after `seconds` have passed, calling `onTickSecond` with
--- the current number of seconds left on the timer if `doOnTickSecond` is set. This includes the
--- starting duration, but also 0--note that this adds an extra second.
--- If `name` is supplied, the callback is called with TriggerManager and the name as arguments.
---@param callback TriggerCallback | NamedTriggerCallback
---@param seconds number
---@param name? string
---@param doOnTickSecond? boolean
---@param onTickSecond? fun(seconds: number)
---@return thread
function CreateTimerTrigger(callback, seconds, name, doOnTickSecond, onTickSecond)
    return ForkThread(TimerTriggerThread, callback, seconds, name, doOnTickSecond, onTickSecond)
end
function TimerTriggerThread(callback, seconds, name, doOnTickSecond, onTickSecond)
    if doOnTickSecond then
        while true do
            onTickSecond(seconds)
            -- we should break here instead to not add an extra second...
            WaitSeconds(1)
            seconds = seconds - 1
            if seconds < 0 then
                break
            end
        end
    else
        WaitSeconds(seconds)
    end

    if name then
        callback(TriggerManager, name)
    else
        callback()
    end
end

--- Creates a trigger that fires `callback` when all `units` are dead.
--- If `name` is supplied, then the callback is called with TriggerManager and the name as arguments.
---@param callback TriggerCallback | NamedTriggerCallback
---@param units Unit[]
---@param name? string
---@return thread
function CreateGroupDeathTrigger(callback, units, name)
    return ForkThread(GroupDeathTriggerThread, callback, units, name)
end
function GroupDeathTriggerThread(callback, units, name)
    local allDead = false
    while not allDead do
        allDead = true
        for _, unit in units do
            if not unit.Dead then
                allDead = false
                break
            end
        end
        if allDead then
            if name then
                callback(TriggerManager, name)
            else
                callback()
            end
        end
        WaitSeconds(0.5)
    end
end

--- Creates a trigger that fires `callback` when there are `deadCount` units dead.
--- If `name` is supplied, then the callback is called with TriggerManager and the name as arguments.
---@param callback TriggerCallback | NamedTriggerCallback
---@param units Unit[]
---@param deadCount number
---@param name? string
---@return thread
function CreateSubGroupDeathTrigger(callback, units, deadCount, name)
    return ForkThread(SubGroupDeathTriggerThread, callback, units, deadCount, name)
end
function SubGroupDeathTriggerThread(callback, units, num, name)
    local numDead = 0
    while numDead < num do
        numDead = 0
        for _, unit in units do
            if unit.Dead then
                numDead = numDead + 1
            end
            if numDead == num then
                if name then
                    callback(TriggerManager, name)
                else
                    callback()
                end
                break
            end
        end
        WaitSeconds(0.5)
    end
end

---
---@param callback fun(brain: AIBrain) 
---@param aiBrain AIBrain
---@param name string
---@param triggers ArmyStatTrigger[]
function CreateArmyStatTrigger(callback, aiBrain, name, triggers)
    local spec = {
        Name = name,
        CallbackFunction = callback,
    }
    for _, trigger in aiBrain.TriggerList do
        if name == trigger.Name then
            error('*TRIGGER ERROR: Must use unique names for new triggers- Supplied name: '..trigger.Name, 2)
            return
        end
    end
    for _, trigger in triggers do
        aiBrain:GetArmyStat(trigger.StatType, 0)
        local cat = trigger.Category
        if cat then
            aiBrain:SetArmyStatsTrigger(trigger.StatType, name, trigger.CompareType, trigger.Value, cat)
        else
            aiBrain:SetArmyStatsTrigger(trigger.StatType, name, trigger.CompareType, trigger.Value)
        end
    end
    table.insert(aiBrain.TriggerList, spec)
end

---
---@param callback fun(blip: Blip)
---@param aiBrain AIBrain
---@param reconType string
---@param blip Blip
---@param value boolean
---@param category EntityCategory
---@param onceOnly boolean
---@param targetAIBrain AIBrain
function CreateArmyIntelTrigger(callback, aiBrain, reconType, blip, value, category, onceOnly, targetAIBrain)
    local spec = {
        CallbackFunction = callback,
        Type = reconType,
        Category = category,
        Blip = blip,
        Value = value,
        OnceOnly = onceOnly,
        TargetAIBrain = targetAIBrain,
    }
    aiBrain:SetupArmyIntelTrigger(spec)
end

---
---@param callback fun(unit: Unit)
---@param aiBrain AIBrain
---@param category EntityCategory
---@param level number
function CreateArmyUnitCategoryVeterancyTrigger(callback, aiBrain, category, level)
    local spec = {
        CallbackFunction = callback,
        Category = category,
        Level = level,
    }
    aiBrain:SetupBrainVeterancyTrigger(spec)
end

--- Creates a trigger that fires `callback` when the two units are farther apart than `distance`
---@param callback TriggerCallback
---@param unitOne Unit
---@param unitTwo Unit
---@param distance number
---@return thread
function CreateUnitDistanceTrigger(callback, unitOne, unitTwo, distance)
    return ForkThread(UnitDistanceTriggerThread, callback, unitOne, unitTwo, distance)
end
function UnitDistanceTriggerThread(callback, unitOne, unitTwo, distance)
    while VDist3(unitOne:GetPosition(), unitTwo:GetPosition()) >= distance do
        WaitSeconds(0.5)
    end
    callback()
end

--- Creates a unit trigger that fires `callback` with the unit it's closer than `distance` to a `marker`.
--- If `name` is supplied, then the callback is called with TriggerManager and the name as arguments
--- before the unit.
---@param callback UnitTriggerCallback | NamedUnitTriggerCallback
---@param unit Unit
---@param marker Marker
---@param distance number
---@param name? string
---@return thread
function CreateUnitToPositionDistanceTrigger(callback, unit, marker, distance, name)
    return ForkThread(UnitToPositionDistanceTriggerThread, callback, unit, marker, distance, name)
end
function UnitToPositionDistanceTriggerThread(callback, unit, marker, distance, name)
    if type(marker) == 'string' then
        marker = ScenarioUtils.MarkerToPosition(marker)
    end
    while true do
        if unit.Dead then
            return
        else
            local position = unit:GetPosition()
            local value = VDist2(position[1], position[3], marker[1], marker[3])
            if value <= distance then
                if name then
                    callback(TriggerManager, name, unit)
                else
                    callback(unit)
                end
                return
            end
        end
        WaitSeconds(0.5)
    end
end

--- Creates a trigger that fires `callback` when a unit of type `category` is closer than `distance`
--- to `unit`. The callback function recieves the original unit and trigger unit as arguments.
--- If `name` is supplied, then the callback is called with TriggerManager and the name as arguments
--- before the original and trigger unit.
---@param callback InstigatorTriggerCallback | NamedInstigatorTriggerCallback
---@param unit Unit
---@param brain AIBrain
---@param category EntityCategory
---@param distance number
---@param name? string
---@return thread
function CreateUnitNearTypeTrigger(callback, unit, brain, category, distance, name)
    return ForkThread(CreateUnitNearTypeTriggerThread, callback, unit, brain, category, distance, name)
end
function CreateUnitNearTypeTriggerThread(callback, unit, brain, category, distance, name)
    while true do
        if unit.Dead then
            return
        else
            local position = unit:GetPosition()
            for _, triggerUnit in brain:GetListOfUnits(category, false) do
                if VDist3(position, catUnit:GetPosition()) < distance and not triggerUnit:IsBeingBuilt() then
                    if name then
                        callback(TriggerManager, name, unit, triggerUnit)
                    else
                        callback(unit, triggerUnit)
                    end
                    return
                end
            end
        end
        WaitSeconds(0.5)
    end
end

-- Unit Triggers
function CreateStartBuildTrigger(callback, unit, category)
    unit:AddOnStartBuildCallback(callback, category)
end

function CreateOnFailedToBuildTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnFailedToBuild')
end

---
---@param callback InstigatorTriggerCallback
---@param unit Unit
---@param category EntityCategory
function CreateUnitBuiltTrigger(callback, unit, category)
    unit:AddOnUnitBuiltCallback(callback, category)
end

---
---@param callback InstigatorTriggerCallback
---@param unit Unit
---@param amount? number defaults to `-1`
---@param repeatNum? number defaults to `1`
function CreateUnitDamagedTrigger(callback, unit, amount, repeatNum)
    unit:AddOnDamagedCallback(callback, amount, repeatNum)
end

---
---@param callback UnitTriggerCallback
---@param unit Unit
function CreateUnitDeathTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnKilled')
end

function CreateUnitDestroyedTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnReclaimed')
    unit:AddUnitCallback(callback, 'OnCaptured')
    unit:AddUnitCallback(callback, 'OnKilled')
end

function CreateUnitPercentageBuiltTrigger(callback, aiBrain, category, percent)
    aiBrain:AddUnitBuiltPercentageCallback(callback, category, percent)
end

---@param callback UnitTriggerCallback
---@param unit Unit
function CreateUnitVeterancyTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnVeteran')
end

function RemoveUnitTrigger(unit, callback)
    unit:RemoveCallback(callback)
end

---
---@param callback InstigatorTriggerCallback
---@param unit Unit
function CreateUnitReclaimedTrigger(callback, unit)
   unit:AddUnitCallback(callback, 'OnReclaimed')
end

---
---@param callback InstigatorTriggerCallback
---@param unit Unit
function CreateUnitStartReclaimTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnStartReclaim')
end

---
---@param callback InstigatorTriggerCallback
---@param unit Unit
function CreateUnitStopReclaimTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnStopReclaim')
end

---
---@param cbOldUnit InstigatorTriggerCallback | nil
---@param cbNewUnit InstigatorTriggerCallback | nil
---@param unit Unit
function CreateUnitCapturedTrigger(cbOldUnit, cbNewUnit, unit)
    unit:AddOnCapturedCallback(cbOldUnit, cbNewUnit)
end

---
---@param callback InstigatorTriggerCallback
---@param unit Unit
function CreateUnitStartCaptureTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnStartCapture')
end

---
---@param callback InstigatorTriggerCallback
---@param unit Unit
function CreateUnitStopCaptureTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnStopCapture')
end

---
---@param callback InstigatorTriggerCallback
---@param unit Unit
function CreateUnitStartBeingCapturedTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnStartBeingCaptured')
end

---
---@param callback InstigatorTriggerCallback
---@param unit Unit
function CreateUnitStopBeingCapturedTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnStopBeingCaptured')
end

---
---@param callback InstigatorTriggerCallback
---@param unit Unit
function CreateUnitFailedBeingCapturedTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnFailedBeingCaptured')
end

---
---@param callback InstigatorTriggerCallback
---@param unit Unit
function CreateUnitFailedCaptureTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnFailedCapture')
end

function CreateUnitStopBeingBuiltTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnStopBeingBuilt')
end

---
---@param callback InstigatorTriggerCallback
---@param unit Unit
function CreateUnitGivenTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnGiven')
end

function VariableBoolCheckThread(callback, varName, invert, name)
    if invert then
        while not ScenarioInfo.VarTable[varName] do
            WaitSeconds(.5)
        end
    else
        while ScenarioInfo.VarTable[varName] do
            WaitSeconds(.5)
        end
    end
    callback(TriggerManager, name)
end

function MissionNumberTriggerThread(callback, value, name)
    if value then
        while ScenarioInfo.VarTable['Mission Number'] ~= value do
            WaitSeconds(.5)
        end
        callback(TriggerManager, name)
    end
end

-- Prop Triggers
function CreatePropKilledTrigger(callback, prop)
   prop:AddPropCallback(callback, 'OnKilled')
end

function CreatePropReclaimedTrigger(callback, prop)
   prop:AddPropCallback(callback, 'OnReclaimed')
end
