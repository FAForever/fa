------------------------------------------------------------------
--  File     :  /data/lua/scenariotriggers.lua
--  Author(s):  John Comes
--  Summary  :  Generalized trigger functions for scenarios.
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')

---@alias TriggerCallback
---| fun()
---| fun(manager: TriggerManager, name: string)
---@alias UnitTriggerCallback
---| fun(trigger: Unit)
---| fun(manager: TriggerManager, name: string, trigger: Unit)
---@alias UnitInstigatorTriggerCallback
---| fun(unit: Unit, inst: Unit)
---| fun(manager: TriggerManager, name: string, unit: Unit, inst: Unit)
---@alias OnDamagedCallback fun(unit: Unit, instigator: Unit)

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



--- This will create an area trigger around `rectangle`. It will fire when `category` is met of `aiBrain`.
---@param callback UnitTriggerCallback
---@param rectangle Rectangle
---@param category EntityCategory
---@param onceOnly boolean means it will not continue to run after the first time it fires
---@param invert boolean means it will fire when there are less than `unitCount` units in the area. Useful for testing if someone has defeated a base.
---@param aiBrain AIBrain
---@param unitCount number number of units it will take to fire
---@param requireBuilt boolean
---@return thread
function CreateAreaTrigger(callback, rectangle, category, onceOnly, invert, aiBrain, unitCount, requireBuilt)
    return ForkThread(AreaTriggerThread, callback, {rectangle}, category, onceOnly, invert, aiBrain, unitCount, requireBuilt)
end

--- Same as `CreateAreaTrigger` except you can supply the function with a table of Rectangles for if
--- you have an odd shaped area for an area trigger
---@param callback UnitTriggerCallback
---@param rectangles Rectangle[]
---@param category EntityCategory
---@param onceOnly boolean
---@param invert boolean
---@param aiBrain AIBrain
---@param unitCount number
---@param requireBuilt boolean
---@return thread
function CreateMultipleAreaTrigger(callback, rectangles, category, onceOnly, invert, aiBrain, unitCount, requireBuilt)
    return ForkThread(AreaTriggerThread, callback, rectangles, category, onceOnly, invert, aiBrain, unitCount, requireBuilt)
end

function AreaTriggerThread(callback, rectangles, category, onceOnly, invert, aiBrain, unitCount, requireBuilt, name)
    local recTable = {}
    for i, rect in rectangles do
        if type(rect) == 'string' then
            recTable[i] = ScenarioUtils.AreaToRect(rect)
        else
            recTable[i] = rect
        end
    end

    while true do
        local amount = 0
        local totalEntities = {}
        local totalEntityCount = 0
        for _, rect in recTable do
            local entities = GetUnitsInRect(rect)
            if entities then
                for _, entity in entities do
                    totalEntityCount = totalEntityCount + 1
                    totalEntities[totalEntityCount] = entity
                end
            end
        end
        local triggered = false
        local triggeringEntity
        if totalEntityCount > 0 then
            for _, entity in totalEntities do
                local contains = EntityCategoryContains(category, entity)
                if contains and (aiBrain and entity:GetAIBrain() == aiBrain) and (not requireBuilt or (requireBuilt and not entity:IsBeingBuilt())) then
                    amount = amount + 1
                    -- If we want to trigger as soon as one of a type is in there, kick out immediately.
                    if not unitCount then
                        triggeringEntity = entity
                        triggered = true
                        break
                    -- If we want to trigger on an amount, then add the entity into the triggeringEntity table
                    -- so we can pass that table back to the callback function.
                    else
                        if not triggeringEntity then
                            triggeringEntity = {}
                        end
                        table.insert(triggeringEntity, entity)
                    end
                end
            end
        end
        -- Check to see if we have a triggering amount inside in the area.
        if number and ((amount >= number and not invert) or (amount < number and invert)) then
            triggered = true
        end
        -- TRIGGER IF:
        -- You don't want a specific amount and the correct unit category entered
        -- You don't want a specific amount, there are no longer the category inside and you wanted the test inverted
        -- You want a specific amount and we have enough.
        if (triggered and not invert and not number) or (not triggered and invert and not number) or (triggered and number) then
            if name then
                callback(TriggerManager, name, triggeringEntity)
            else
                callback(triggeringEntity)
            end
            if onceOnly then
                return
            end
        end
        WaitTicks(1)
    end
end

---
---@param callback TriggerCallback
---@param aiBrain AIBrain
---@param unit Unit
---@param rings boolean
---@param onceOnly boolean
---@param value number
---@param greater boolean
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

---
---@param callback TriggerCallback
---@param aiBrain AIBrain
---@param pos Marker | Vector
---@param rings boolean
---@param onceOnly boolean
---@param value number
---@param greater boolean
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

--- Fires the `callback` function after `seconds`.
--- You can have the function repeat `repeatNum` times which will fire every `seconds`.
---@param callback function
---@param seconds number
---@param name? string
---@param display? boolean
---@param onTickSecond? fun(seconds: number) display needs to be `true` to be called
---@return thread
function CreateTimerTrigger(callback, seconds, name, display, onTickSecond)
    return ForkThread(TimerTriggerThread, callback, seconds, name, display, onTickSecond)
end
function TimerTriggerThread(callback, seconds, name, display, onTickSecond)
    if display then
        local targetTime = math.floor(GetGameTimeSeconds()) + seconds
        onTickSecond(seconds)

        while true do
            WaitSeconds(1)
            local time = targetTime - math.floor(GetGameTimeSeconds())
            onTickSecond(time)
            if time < 0 then
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

---
---@param callback TriggerCallback
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

---
---@param callback TriggerCallback
---@param units Unit[]
---@param num number
---@param name? string
---@return thread
function CreateSubGroupDeathTrigger(callback, units, num, name)
    return ForkThread(SubGroupDeathTriggerThread, callback, units, num, name)
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

---
---@param callback fun()
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

---
---@param callback UnitTriggerCallback
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

---
---@param callback UnitInstigatorTriggerCallback
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
            for _, catUnit in brain:GetListOfUnits(category, false) do
                if VDist3(position, catUnit:GetPosition()) < distance and not catUnit:IsBeingBuilt() then
                    if name then
                        callback(TriggerManager, name, unit, catUnit)
                    else
                        callback(unit, catUnit)
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
---@param callback fun(self: Unit, builder: Unit)
---@param unit Unit
---@param category EntityCategory
function CreateUnitBuiltTrigger(callback, unit, category)
    unit:AddOnUnitBuiltCallback(callback, category)
end

---
---@param callback OnDamagedCallback
---@param unit Unit
---@param amount? number defaults to -1
---@param repeatNum? number defaults to 1
function CreateUnitDamagedTrigger(callback, unit, amount, repeatNum)
    unit:AddOnDamagedCallback(callback, amount, repeatNum)
end

---
---@param callback fun(self: Unit)
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

---@param callback fun(self: Unit)
---@param unit Unit
function CreateUnitVeterancyTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnVeteran')
end

function RemoveUnitTrigger(unit, callback)
    unit:RemoveCallback(callback)
end

---
---@param callback fun(self: Unit, source: Entity)
---@param unit Unit
function CreateUnitReclaimedTrigger(callback, unit)
   unit:AddUnitCallback(callback, 'OnReclaimed')
end

---
---@param callback fun(self: Unit, target: Unit)
---@param unit Unit
function CreateUnitStartReclaimTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnStartReclaim')
end

---
---@param callback fun(self: Unit, target: Entity)
---@param unit Unit
function CreateUnitStopReclaimTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnStopReclaim')
end

---
---@param cbOldUnit fun(oldUnit: Unit, captor: Unit) | nil
---@param cbNewUnit fun(newUnit: Unit, captor: Unit) | nil
---@param unit Unit
function CreateUnitCapturedTrigger(cbOldUnit, cbNewUnit, unit)
    unit:AddOnCapturedCallback(cbOldUnit, cbNewUnit)
end

---
---@param callback fun(self: Unit, target: Unit)
---@param unit Unit
function CreateUnitStartCaptureTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnStartCapture')
end

---
---@param callback fun(self: Unit, target: Unit)
---@param unit Unit
function CreateUnitStopCaptureTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnStopCapture')
end

---
---@param callback fun(self: Unit, captor: Unit)
---@param unit Unit
function CreateUnitStartBeingCapturedTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnStartBeingCaptured')
end

---
---@param callback fun(self: Unit, captor: Unit)
---@param unit Unit
function CreateUnitStopBeingCapturedTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnStopBeingCaptured')
end

---
---@param callback fun(self: Unit, captor: Unit)
---@param unit Unit
function CreateUnitFailedBeingCapturedTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnFailedBeingCaptured')
end

---
---@param callback fun(self: Unit, target: Unit)
---@param unit Unit
function CreateUnitFailedCaptureTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnFailedCapture')
end

function CreateUnitStopBeingBuiltTrigger(callback, unit)
    unit:AddUnitCallback(callback, 'OnStopBeingBuilt')
end

---
---@param callback fun(self: Unit, newUnit: Unit)
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
