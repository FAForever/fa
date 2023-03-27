--***************************************************************************
--*
--**  File     :  /lua/sim/BrainConditionsMonitor.lua
--**
--**  Summary  : Monitors conditions for a brain and stores them in a keyed
--**             table
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local instantBuildConditionsUpperCase = { }
instantBuildConditionsUpperCase['/lua/editor/InstantBuildConditions.lua'] = true
instantBuildConditionsUpperCase['/lua/editor/UnitCountBuildConditions.lua'] = true
instantBuildConditionsUpperCase['/lua/editor/EconomyBuildConditions.lua'] = true

---@type table<FileReference, boolean>
local instantBuildConditions = { }
for file, _ in instantBuildConditionsUpperCase do
    instantBuildConditions[file] = true
    instantBuildConditions[file:lower()] = true
end

---@class BrainConditionsMonitor
BrainConditionsMonitor = ClassSimple {

    ---@param self BrainConditionsMonitor
    ---@return boolean
    PreCreate = function(self)
        if self.PreCreateFinished then
            return true
        end

        self.Trash = TrashBag()

        self.ThreadWaitDuration = 7

        self.Brain = false
        self.Active = false

        self.ResultTable = {}
        self.ConditionData = {
            TableConditions = {},
            FunctionConditions = {},
        }
        self.ConditionsTable = {}

        self.PreCreateFinished = true
    end,

    -- Create the thing
    ---@param self BrainConditionsMonitor
    ---@param brain AIBrain
    Create = function(self, brain)
        if not self.PreCreateFinished then
            self:PreCreate()
        end
        self.Brain = brain
    end,

    ---@param self BrainConditionsMonitor
    Destroy = function(self)
        KillThread(self.ConditionMonitor)
        self.Active = false
        self.Trash:Destroy()
    end,

    -- Gets result for the keyed condition
    ---@param self BrainConditionsMonitor
    ---@param conditionKey any
    ---@param reportFailure any
    ---@return boolean
    CheckKeyedCondition = function(self, conditionKey, reportFailure)
        if self.ResultTable[conditionKey] != nil then
            return self.ResultTable[conditionKey]:GetStatus(reportFailure)
        end
        WARN('*WARNING: No Condition found with condition key: ' .. conditionKey)
        return false
    end,

    -- Checks the condition and returns the result
    ---@param self BrainConditionsMonitor
    ---@param cFilename FileName
    ---@param cFunctionName FunctionName
    ---@param cData any[]
    ---@return boolean
    CheckConditionTable = function(self, cFilename, cFunctionName, cData)
        if not cData or not type(cData) == 'table' then
            WARN('*WARNING: Invalid argumetns for build condition: ' .. cFilename .. '[' .. cFunctionName .. ']')
            return false
        end
        return import(cFilename)[cFunctionName](self.Brain, unpack(cData))
    end,

    -- Runs the function and retuns the result
    ---@param self BrainConditionsMonitor
    ---@param func function
    ---@param params any[]
    ---@return any
    CheckConditionFunction = function(self, func, params)
        return func(unpack(params))
    end,

    -- Find the key for a condition or adds it to the table and checks the condition
    ---@param self BrainConditionsMonitor
    ---@param cFilename FileName
    ---@param cFunctionName FunctionName
    ---@param cData any[]
    ---@return string
    GetConditionKey = function(self, cFilename, cFunctionName, cData)
        if not cFunctionName then
            error('*BUILD CONDITION MONITOR: Invalid BuilderCondition - Missing function name')
        elseif not cData or type(cData) != 'table' then
            error('*BUILD CONDITION MONITOR: Invalid BuilderCondition - Missing data table')
        end

        -- Key the TableConditions by filename
        if not self.ConditionData.TableConditions[cFilename] then
            self.ConditionData.TableConditions[cFilename] = {}
        end

        -- Key the filenames by function name
        if not self.ConditionData.TableConditions[cFilename][cFunctionName] then
            self.ConditionData.TableConditions[cFilename][cFunctionName] = {}
        end

        -- Check if the cData matches up
        for num,data in self.ConditionData.TableConditions[cFilename][cFunctionName] do
            -- Check if the data is the same length
            if table.getn(data.ConditionParameters) == table.getn(cData) then
                local match = true
                -- Check each piece of data to make sure it matches
                for k,v in data.ConditionParameters do
                    if v != cData[k] then
                        match = false
                        break
                    end
                end
                -- Match found, return the key
                if match then
                    return data.Key
                end
            end
        end

        -- No match found, so add the data to the table and return the key (same number as num items)
        local newCondition
        if instantBuildConditions[cFilename] then
            newCondition = InstantImportCondition()
        else
            newCondition = ImportCondition()
        end
        newCondition:Create(self.Brain, table.getn(self.ResultTable) + 1, cFilename, cFunctionName, cData)
        table.insert(self.ResultTable, newCondition)

        -- Add in a hashed table for quicker key lookup, may not be necessary
        local newTable = {
            ConditionParameters = cData,
            Key = newCondition:GetKey(),
        }
        table.insert(self.ConditionData.TableConditions[cFilename][cFunctionName], newTable)
        return newTable.Key
    end,

    -- Find the key for a condition that is a function
    ---@param self BrainConditionsMonitor
    ---@param func function
    ---@param parameters any
    ---@return any
    GetConditionKeyFunction = function(self, func, parameters)
        -- See if there is a matching function
        for k,v in self.ConditionData.FunctionConditions do
            if v.Function == func then
                local found = true
                for num,data in v.ConditionParameters do
                    if data != parameters[num] then
                        found = false
                        break
                    end
                end
                if found then
                    return v.Key
                end
            end
        end

        -- No match, insert data into the function conditions table
        local newCondition = FunctionCondition()
        newCondition:Create(self.Brain, table.getn(self.ResultTable) + 1, func, parameters)
        table.insert(self.ResultTable, newCondition)

        local newTable = {
            Function = func,
            Key = newCondition:GetKey(),
            ConditionParameters = parameters,
        }
        table.insert(self.ConditionData.FunctionConditions, newTable)
        return newTable.Key
    end,

    -- Thread that will monitor conditions the brain asks for over time
    ---@param self BrainConditionsMonitor
    ConditionMonitorThread = function(self)
        while true do
            local checks = 0
            local numResults = 0
            local numChecks = table.getn(self.ResultTable)
            local numPerTick = math.ceil(numChecks / (self.ThreadWaitDuration * 10))

            for k,v in self.ResultTable do
                if not v:LocationExists() then
                    --Don't remove the condition, just skip over.
                    --If the base gets rebuilt the AI will use the old keyed conditions.
                    continue
                end
                numResults = numResults + 1
                v:CheckCondition()

                -- Load balance per tick here
                checks = checks + 1
                if checks >= numPerTick then
                    WaitTicks(1)
                    checks = 0
                end
            end
            --LOG('*AI DEBUG: '.. self.Brain.Nickname ..' ConditionMonitorThread checked: '..numResults)
            WaitTicks(1)
        end
    end,

    -- Adds a condition to the table and returns the key
    ---@param self BrainConditionsMonitor
    ---@param cFilename FileName
    ---@param cFunctionName FunctionName
    ---@param cData any[]
    ---@return any
    AddCondition = function(self, cFilename, cFunctionName, cData)
        if not self.Active then
            self.Active = true
            self.ConditionMonitor = self:ForkThread(self.ConditionMonitorThread)
        end
        if type(cFilename) == 'function' then
            return self:GetConditionKeyFunction(cFilename, cFunctionName)
        end
        return self:GetConditionKey(cFilename, cFunctionName, cData)
    end,

    -- forking and storing a thread on the monitor
    ---@param self BrainConditionsMonitor
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
}

---@param brain AIBrain
---@return BrainConditionsMonitor
function CreateConditionsMonitor(brain)
    local cMonitor = BrainConditionsMonitor()
    cMonitor:Create(brain)
    return cMonitor
end

---@class Condition
Condition = ClassSimple {
    -- Create the thing

    ---@param self Condition
    ---@param brain AIBrain
    ---@param key string
    Create = function(self,brain,key)
        self.Status = false
        self.Brain = brain
        self.Key = key
    end,

    ---@param self Condition
    ---@return boolean
    CheckCondition = function(self)
        self.Status = false
        return self.Status
    end,

    ---@param self Condition
    ---@param reportFailure boolean
    ---@return boolean
    GetStatus = function(self, reportFailure)
        return self.Status
    end,

    ---@param self Condition
    ---@return string
    GetKey = function(self)
        return self.Key
    end
}

---@class ImportCondition : Condition
ImportCondition = Class(Condition) {

    ---@param self ImportCondition
    ---@param brain AIBrain
    ---@param key string
    ---@param filename FileName
    ---@param funcName FunctionName
    ---@param funcData any[]
    Create = function(self,brain,key,filename,funcName,funcData)
        Condition.Create(self,brain,key)
        self.Filename = filename
        self.FunctionName = funcName
        self.FunctionData = funcData
        self.CheckTime = false
    end,

    ---@param self ImportCondition
    ---@return boolean
    CheckCondition = function(self)
        if self.CheckTime != GetGameTimeSeconds() then
            self.Status = import(self.Filename)[self.FunctionName](self.Brain, unpack(self.FunctionData))
            self.CheckTime = GetGameTimeSeconds()
        end
        return self.Status
    end,

    ---@param self ImportCondition
    ---@param reportFailure boolean
    ---@return string
    GetStatus = function(self, reportFailure)
        if reportFailure and not self.Status then
            LOG('*AI DEBUG: Build Condition failed - ' .. self.FunctionName .. ' - Data: ' .. repr(self.FunctionData))
        end
        return self.Status
    end,

    ---@param self ImportCondition
    ---@return boolean
    LocationExists = function(self)
        local found = false
        for k,v in self.FunctionData do
            if type(v) == 'string' and not (v == 'Naval Area' or v == 'Expansion Area' or v == 'Large Expansion Area') then
                if string.find(v, 'ARMY_') or string.find(v, 'Large Expansion') or string.find(v, 'Expansion Area') or string.find(v, 'EXPANSION_AREA') or string.find(v, 'Naval Area') or string.find(v, 'MAIN') then
                    found = true
                    if self.Brain.BuilderManagers[v] then
                        return true
                    end
                end
            end
        end
        if not found then return true end
        self.Status = false
        return false
    end,
}

---@class InstantImportCondition : Condition
InstantImportCondition = Class(Condition) {

    ---@param self InstantImportCondition
    ---@param brain AIBrain
    ---@param key string
    ---@param filename FileName
    ---@param funcName FunctionName
    ---@param funcData any[]
    Create = function(self,brain,key,filename,funcName,funcData)
        Condition.Create(self,brain,key)
        self.Filename = filename
        self.FunctionName = funcName
        self.FunctionData = funcData
        self.CheckTime = false
    end,

    -- This class doesn't change when CheckCondition is called; Only changed when requested
    ---@param self InstantImportCondition
    ---@return string
    CheckCondition = function(self)
        --if self.CheckTime != GetGameTimeSeconds() then
            --self.Status = import(self.Filename)[self.FunctionName](self.Brain, unpack(self.FunctionData))
            --self.CheckTime = GetGameTimeSeconds()
        --end
        return self.Status
    end,

    -- This class always performs the check when getting status (basically for stat checks)
    ---@param self InstantImportCondition
    ---@param reportFailure boolean
    ---@return string
    GetStatus = function(self, reportFailure)
        if self.CheckTime != GetGameTimeSeconds() then
            self.Status = import(self.Filename)[self.FunctionName](self.Brain, unpack(self.FunctionData))
            self.CheckTime = GetGameTimeSeconds()
            --LOG('*AI LOG: Instant Check')
        end
        if reportFailure and not self.Status then
            LOG('*AI DEBUG: Build Condition failed - ' .. self.FunctionName .. ' - Data: ' .. repr(self.FunctionData))
        end
        return self.Status
    end,

    ---@param self InstantImportCondition
    ---@return boolean
    LocationExists = function(self)
        local found = false
        for k,v in self.FunctionData do
            if type(v) == 'string' and not (v == 'Naval Area' or v == 'Expansion Area' or v == 'Large Expansion Area') then
                if string.find(v, 'ARMY_') or string.find(v, 'Large Expansion') or string.find(v, 'Expansion Area') or string.find(v, 'EXPANSION_AREA') or string.find(v, 'Naval Area') or string.find(v, 'MAIN') then
                    found = true
                    if self.Brain.BuilderManagers[v] then
                        return true
                    end
                end
            end
        end
        if not found then return true end
        self.Status = false
        return false
    end,
}

---@class FunctionCondition : Condition
FunctionCondition = Class(Condition) {

    ---@param self FunctionCondition
    ---@param brain AIBrain
    ---@param key number
    ---@param funcHandle any
    ---@param funcParams any
    Create = function(self,brain,key,funcHandle,funcParams)
        Condition.Create(self,brain,key)
        self.FunctionHandle = funcHandle
        self.FunctionParameters = funcParams or {}
    end,

    ---@param self FunctionCondition
    ---@return string
    CheckCondition = function(self)
        self.Status = self.FunctionHandle(self.Brain, unpack(self.FunctionParameters))
        return self.Status
    end,

    ---@param self FunctionCondition
    ---@return boolean
    LocationExists = function(self)
        local found = false
        for k,v in self.FunctionParameters do
            if type(v) == 'string' and not (v == 'Naval Area' or v == 'Expansion Area' or v == 'Large Expansion Area') then
                if string.find(v, 'ARMY_') or string.find(v, 'Large Expansion') or string.find(v, 'Expansion Area') or string.find(v, 'EXPANSION_AREA') or string.find(v, 'Naval Area') or string.find(v, 'MAIN') then
                    found = true
                    if self.Brain.BuilderManagers[v] then
                        return true
                    end
                end
            end
        end
        if not found then return true end
        self.Status = false
        return false
    end,
}
