------------------------------------------------------------------
--  File     :  /data/lua/scenariotriggers.lua
--  Author(s):  John Comes
--  Summary  :  Generalized trigger functions for scenarios.
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')

function CreateAreaTrigger(callbackFunction, rectangle, category, onceOnly, invert, aiBrain, number, requireBuilt)
    return ForkThread(AreaTriggerThread, callbackFunction, {rectangle}, category, onceOnly, invert, aiBrain, number, requireBuilt)
end

function CreateMultipleAreaTrigger(callbackFunction, rectangleTable, category, onceOnly, invert, aiBrain, number, requireBuilt)
    return ForkThread(AreaTriggerThread, callbackFunction, rectangleTable, category, onceOnly, invert, aiBrain, number, requireBuilt)
end

function AreaTriggerThread(callbackFunction, rectangleTable, category, onceOnly, invert, aiBrain, number, requireBuilt, name)
    local recTable = {}
    for _, v in rectangleTable do
        if type(v) == 'string' then
            table.insert(recTable, ScenarioUtils.AreaToRect(v))
        else
            table.insert(recTable, v)
        end
    end

    while true do
        local amount = 0
        local totalEntities = {}
        for _, v in recTable do
            local entities = GetUnitsInRect(v)
            if entities then
                for ke, ve in entities do
                    totalEntities[table.getn(totalEntities) + 1] = ve
                end
            end
        end
        local triggered = false
        local triggeringEntity
        local numEntities = table.getn(totalEntities)
        if numEntities > 0 then
            for _, v in totalEntities do
                local contains = EntityCategoryContains(category, v)
                if contains and (aiBrain and v:GetAIBrain() == aiBrain) and (not requireBuilt or (requireBuilt and not v:IsBeingBuilt())) then
                    amount = amount + 1
                    -- If we want to trigger as soon as one of a type is in there, kick out immediately.
                    if not number then
                        triggeringEntity = v
                        triggered = true
                        break
                    -- If we want to trigger on an amount, then add the entity into the triggeringEntity table
                    -- so we can pass that table back to the callback function.
                    else
                        if not triggeringEntity then
                            triggeringEntity = {}
                        end
                        table.insert(triggeringEntity, v)
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
                callbackFunction(TriggerManager, name, triggeringEntity)
            else
                callbackFunction(triggeringEntity)
            end
            if onceOnly then
                return
            end
        end
        WaitTicks(1)
    end
end

function CreateThreatTriggerAroundUnit(callbackFunction, aiBrain, unit, rings, onceOnly, value, greater)
    return ForkThread(ThreatTriggerAroundUnitThread, callbackFunction, aiBrain, unit, rings, onceOnly, value, greater)
end

function ThreatTriggerAroundUnitThread(callbackFunction, aiBrain, unit, rings, onceOnly, value, greater, name)
    while not unit.Dead do
        local threat = aiBrain:GetThreatAtPosition(unit:GetPosition(), rings, true)
        if greater and threat >= value then
            if name then
                callbackFunction(TriggerManager, name)
            else
                callbackFunction()
            end
            if onceOnly then
                return
            end
        elseif not greater and threat <= value then
            if name then
                callbackFunction(TriggerManager, name)
            else
                callbackFunction()
            end
            if onceOnly then
                return
            end
        end
        WaitSeconds(0.5)
    end
end

function CreateThreatTriggerAroundPosition(callbackFunction, aiBrain, posVector, rings, onceOnly, value, greater)
    return ForkThread(ThreatTriggerAroundPositionThread, callbackFunction, aiBrain, posVector, rings, onceOnly, value, greater)
end

function ThreatTriggerAroundPositionThread(callbackFunction, aiBrain, posVector, rings, onceOnly, value, greater, name)
    if type(posVector) == 'string' then
        posVector = ScenarioUtils.MarkerToPosition(posVector)
    end
    while true do
        local threat = aiBrain:GetThreatAtPosition(posVector, rings, true)
        if greater and threat >= value then
            if name then
                callbackFunction(TriggerManager, name)
            else
                callbackFunction()
            end
            if onceOnly then
                return
            end
        elseif not greater and threat <= value then
            if name then
                callbackFunction(TriggerManager, name)
            else
                callbackFunction()
            end
            if onceOnly then
                return
            end
        end
        WaitSeconds(0.5)
    end
end

function CreateTimerTrigger(callbackFunction, seconds, name, displayBool, onTickFunc)
    return ForkThread(TimerTriggerThread, callbackFunction, seconds, name, displayBool, onTickFunc)
end

function TimerTriggerThread(callbackFunction, seconds, name, displayBool, onTickFunc)
    if displayBool then
        local ticking = true
        local targetTime = math.floor(GetGameTimeSeconds()) + seconds

        while ticking do
            onTickFunc(targetTime - math.floor(GetGameTimeSeconds()))

            if targetTime - math.floor(GetGameTimeSeconds()) < 0 then
                ticking = false
            end

            WaitSeconds(1)
        end
    else
        WaitSeconds(seconds)
    end

    if name then
        callbackFunction(TriggerManager, name)
    else
        callbackFunction()
    end
end

function CreateGroupDeathTrigger(callbackFunction, group)
    return ForkThread(GroupDeathTriggerThread, callbackFunction, group)
end

function GroupDeathTriggerThread(callbackFunction, group, name)
    local allDead = false
    while not allDead do
        allDead = true
        for _, v in group do
            if not v.Dead then
                allDead = false
                break
            end
        end
        if allDead then
            if name then
                callbackFunction(TriggerManager, name)
            else
                callbackFunction()
            end
        end
        WaitSeconds(0.5)
    end
end

function CreateSubGroupDeathTrigger(callbackFunction, group, num)
    return ForkThread(SubGroupDeathTriggerThread, callbackFunction, group, num)
end

function SubGroupDeathTriggerThread(callbackFunction, group, num, name)
    local numDead = 0
    while numDead < num do
        numDead = 0
        for _, v in group do
            if v.Dead then
                numDead = numDead + 1
            end
            if numDead == num then
                if name then
                    callbackFunction(TriggerManager, name)
                else
                    callbackFunction()
                end
                break
            end
        end
        WaitSeconds(0.5)
    end
end

function CreateArmyStatTrigger(callbackFunction, aiBrain, name, triggerTable)
    local spec = {
        Name = name,
        CallbackFunction = callbackFunction,
    }
    for num, trigger in aiBrain.TriggerList do
        if name == trigger.Name then
            error('*TRIGGER ERROR: Must use unique names for new triggers- Supplied name: '..trigger.Name, 2)
            return
        end
    end
    for num, triggerData in triggerTable do
        if string.find (triggerData.StatType, "Economy_") then
            aiBrain:GetArmyStat(triggerData.StatType, 0.0)
        else
            aiBrain:GetArmyStat(triggerData.StatType, 0)
        end
        if triggerData.Category then
            aiBrain:SetArmyStatsTrigger(triggerData.StatType, name, triggerData.CompareType, triggerData.Value, triggerData.Category)
        else
            aiBrain:SetArmyStatsTrigger(triggerData.StatType, name, triggerData.CompareType, triggerData.Value)
        end
    end
    table.insert(aiBrain.TriggerList, spec)
end

function CreateArmyIntelTrigger(callbackFunction, aiBrain, reconType, blip, value, category, onceOnly, targetAIBrain)
    local spec = {
        CallbackFunction = callbackFunction,
        Type = reconType,
        Category = category,
        Blip = blip,
        Value = value,
        OnceOnly = onceOnly,
        TargetAIBrain = targetAIBrain,
    }
    aiBrain:SetupArmyIntelTrigger(spec)
end

function CreateArmyUnitCategoryVeterancyTrigger(callbackFunction, aiBrain, category, level)
    local spec = {
        CallbackFunction = callbackFunction,
        Category = category,
        Level = level,
    }
    aiBrain:SetupBrainVeterancyTrigger(spec)
end

function CreateUnitDistanceTrigger(callbackFunction, unitOne, unitTwo, distance)
    ForkThread(UnitDistanceTriggerThread, callbackFunction, unitOne, unitTwo, distance)
end

function UnitDistanceTriggerThread(callbackFunction, unitOne, unitTwo, distance)
    while not (VDist3(unitOne:GetPosition(), unitTwo:GetPosition()) < distance) do
        WaitSeconds(0.5)
    end
    callbackFunction()
end

function CreateUnitToPositionDistanceTrigger(callbackFunction, unit, marker, distance)
    ForkThread(UnitToPositionDistanceTriggerThread, callbackFunction, unit, marker, distance)
end

function UnitToPositionDistanceTriggerThread(cb, unit, marker, distance, name)
    if type(marker) == 'string' then
        marker = ScenarioUtils.MarkerToPosition(marker)
    end
    local fired = false
    while not fired do
        if unit.Dead then
            return
        else
            local position = unit:GetPosition()
            local value = VDist2(position[1], position[3], marker[1], marker[3])
            if value <= distance then
                fired = true
                if name then
                    cb(TriggerManager, name, unit)
                    return
                else
                    cb(unit)
                    return
                end
            end
        end
        WaitSeconds(.5)
    end
end

function CreateUnitNearTypeTrigger(callbackFunction, unit, brain, category, distance)
    return ForkThread(CreateUnitNearTypeTriggerThread, callbackFunction, unit, brain, category, distance)
end

function CreateUnitNearTypeTriggerThread(callbackFunction, unit, brain, category, distance, name)
    local fired = false
    while not fired do
        if unit.Dead then
            return
        else
            local position = unit:GetPosition()
            for k, catUnit in brain:GetListOfUnits(category, false) do
                if VDist3(position, catUnit:GetPosition()) < distance and not catUnit:IsBeingBuilt() then
                    fired = true
                    if name then
                        callbackFunction(TriggerManager, name, unit, catUnit)
                        return
                    else
                        callbackFunction(unit, catUnit)
                        return
                    end
                end
            end
        end
        WaitSeconds(.5)
    end
end

-- Unit Triggers
function CreateStartBuildTrigger(callbackFunction, unit, category)
    unit:AddOnStartBuildCallback(callbackFunction, category)
end

function CreateOnFailedToBuildTrigger(callbackFunction, unit)
    unit:AddUnitCallback(callbackFunction, 'OnFailedToBuild')
end

function CreateUnitBuiltTrigger(callbackFunction, unit, category)
    unit:AddOnUnitBuiltCallback(callbackFunction, category)
end

function CreateUnitDamagedTrigger(callbackFunction, unit, amount, repeatNum)
    unit:AddOnDamagedCallback(callbackFunction, amount, repeatNum)
end

function CreateUnitDeathTrigger(callbackFunction, unit)
    unit:AddUnitCallback(callbackFunction, 'OnKilled')
end

function CreateUnitDestroyedTrigger(callbackFunction, unit)
    unit:AddUnitCallback(callbackFunction, 'OnReclaimed')
    unit:AddUnitCallback(callbackFunction, 'OnCaptured')
    unit:AddUnitCallback(callbackFunction, 'OnKilled')
end

function CreateUnitPercentageBuiltTrigger(callbackFunction, aiBrain, category, percent)
    aiBrain:AddUnitBuiltPercentageCallback(callbackFunction, category, percent)
end

function CreateUnitVeterancyTrigger(callbackFunction, unit)
    unit:AddUnitCallback(callbackFunction, 'OnVeteran')
end

function RemoveUnitTrigger(unit, callbackFunction)
    unit:RemoveCallback(callbackFunction)
end

function CreateUnitReclaimedTrigger(cb, unit)
   unit:AddUnitCallback(cb, 'OnReclaimed')
end

function CreateUnitStartReclaimTrigger(cb, unit)
    unit:AddUnitCallback(cb, 'OnStartReclaim')
end

function CreateUnitStopReclaimTrigger(cb, unit)
    unit:AddUnitCallback(cb, 'OnStopReclaim')
end

function CreateUnitCapturedTrigger(cbOldUnit, cbNewUnit, unit)
    if cbOldUnit then
        unit:AddUnitCallback(cbOldUnit, 'OnCaptured')
    end
    if cbNewUnit then
        unit:AddUnitCallback(cbNewUnit, 'OnCapturedNewUnit')
    end
end

function CreateUnitStartCaptureTrigger(cb, unit)
    unit:AddUnitCallback(cb, 'OnStartCapture')
end

function CreateUnitStopCaptureTrigger(cb, unit)
    unit:AddUnitCallback(cb, 'OnStopCapture')
end

function CreateUnitStartBeingCapturedTrigger(cb, unit)
    unit:AddUnitCallback(cb, 'OnStartBeingCaptured')
end

function CreateUnitStopBeingCapturedTrigger(cb, unit)
    unit:AddUnitCallback(cb, 'OnStopBeingCaptured')
end

function CreateUnitFailedBeingCapturedTrigger(cb, unit)
    unit:AddUnitCallback(cb, 'OnFailedBeingCaptured')
end

function CreateUnitFailedCaptureTrigger(cb, unit)
    unit:AddUnitCallback(cb, 'OnFailedCapture')
end

function CreateUnitStopBeingBuiltTrigger(cb, unit)
    unit:AddUnitCallback(cb, 'OnStopBeingBuilt')
end

function CreateUnitGivenTrigger(cb, unit)
    unit:AddUnitCallback(cb, 'OnGiven')
end

function VariableBoolCheckThread(cb, varName, value, name)
    if value then
        while not ScenarioInfo.VarTable[varName] do
            WaitSeconds(.5)
        end
        cb(TriggerManager, name)
    else
        while ScenarioInfo.VarTable[varName] do
            WaitSeconds(.5)
        end
        cb(TriggerManager, name)
    end
end

function MissionNumberTriggerThread(cb, value, name)
    if value then
        while not ScenarioInfo.VarTable['Mission Number'] == value do
            WaitSeconds(.5)
        end
        cb(TriggerManager, name)
    end
end

-- Prop Triggers
function CreatePropKilledTrigger(cb, prop)
   prop:AddPropCallback(cb, 'OnKilled')
end

function CreatePropReclaimedTrigger(cb, prop)
   prop:AddPropCallback(cb, 'OnReclaimed')
end
