#***************************************************************************
#*
#**  File     :  /lua/sim/BrainConditionsMonitor.lua
#**
#**  Summary  : Monitors conditions for a brain and stores them in a keyed
#**             table
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local mathCeil = math.ceil
local stringFind = string.find
local unpack = unpack
local error = error
local next = next
local tableInsert = table.insert
local ipairs = ipairs
local KillThread = KillThread
local tableGetn = table.getn
local type = type
local GetGameTimeSeconds = GetGameTimeSeconds
local LOG = LOG
local WARN = WARN

BrainConditionsMonitor = Class {

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

    # Create the thing
    Create = function(self, brain)
        if not self.PreCreateFinished then
            self:PreCreate()
        end
        self.Brain = brain
    end,

    Destroy = function(self)
        KillThread(self.ConditionMonitor)
        self.Active = false
        self.Trash:Destroy()
    end,

    # Gets result for the keyed condition
    CheckKeyedCondition = function(self, conditionKey, reportFailure)
        if self.ResultTable[conditionKey] != nil then
            return self.ResultTable[conditionKey]:GetStatus(reportFailure)
        end
        WARN('*WARNING: No Condition found with condition key: ' .. conditionKey)
        return false
    end,

    # Checks the condition and returns the result
    CheckConditionTable = function(self, cFilename, cFunctionName, cData)
        if not cData or not type(cData) == 'table' then
            WARN('*WARNING: Invalid argumetns for build condition: ' .. cFilename .. '[' .. cFunctionName .. ']')
            return false
        end
        return import(cFilename)[cFunctionName](self.Brain, unpack(cData))
    end,

    # Runs the function and retuns the result
    CheckConditionFunction = function(self, func, params)
        return func(unpack(params))
    end,

    # Find the key for a condition or adds it to the table and checks the condition
    GetConditionKey = function(self, cFilename, cFunctionName, cData)
        if not cFunctionName then
            error('*BUILD CONDITION MONITOR: Invalid BuilderCondition - Missing function name')
        elseif not cData or type(cData) != 'table' then
            error('*BUILD CONDITION MONITOR: Invalid BuilderCondition - Missing data table')
        end

        # Key the TableConditions by filename
        if not self.ConditionData.TableConditions[cFilename] then
            self.ConditionData.TableConditions[cFilename] = {}
        end

        # Key the filenames by function name
        if not self.ConditionData.TableConditions[cFilename][cFunctionName] then
            self.ConditionData.TableConditions[cFilename][cFunctionName] = {}
        end

        # Check if the cData matches up
        for num,data in self.ConditionData.TableConditions[cFilename][cFunctionName] do
            # Check if the data is the same length
            if tableGetn(data.ConditionParameters) == tableGetn(cData) then
                local match = true
                # Check each piece of data to make sure it matches
                for k,v in data.ConditionParameters do
                    if v != cData[k] then
                        match = false
                        break
                    end
                end
                # Match found, return the key
                if match then
                    return data.Key
                end
            end
        end

        # No match found, so add the data to the table and return the key (same number as num items)
        local newCondition
        if cFilename == '/lua/editor/InstantBuildConditions.lua'
            or cFilename == '/lua/editor/UnitCountBuildConditions.lua' or cFilename == '/lua/editor/EconomyBuildConditions.lua'
            or cFilename == '/lua/editor/SorianInstantBuildConditions.lua' then
            newCondition = InstantImportCondition()
        else
            newCondition = ImportCondition()
        end
        newCondition:Create(self.Brain, tableGetn(self.ResultTable) + 1, cFilename, cFunctionName, cData)
        tableInsert(self.ResultTable, newCondition)

        # Add in a hashed table for quicker key lookup, may not be necessary
        local newTable = {
            ConditionParameters = cData,
            Key = newCondition:GetKey(),
        }
        tableInsert(self.ConditionData.TableConditions[cFilename][cFunctionName], newTable)
        return newTable.Key
    end,

    # Find the key for a condition that is a function
    GetConditionKeyFunction = function(self, func, parameters)
        # See if there is a matching function
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

        # No match, insert data into the function conditions table
        local newCondition = FunctionCondition()
        newCondition:Create(self.Brain, tableGetn(self.ResultTable) + 1, func, parameters)
        tableInsert(self.ResultTable, newCondition)

        local newTable = {
            Function = func,
            Key = newCondition:GetKey(),
            ConditionParameters = parameters,
        }
        tableInsert(self.ConditionData.FunctionConditions, newTable)
        return newTable.Key
    end,

    # Thread that will monitor conditions the brain asks for over time
    ConditionMonitorThread = function(self)
        while true do
            local checks = 0
            local numResults = 0
            local numChecks = tableGetn(self.ResultTable)
            local numPerTick = mathCeil(numChecks / (self.ThreadWaitDuration * 10))

            for k,v in self.ResultTable do
                if not v:LocationExists() then
                    #Don't remove the condition, just skip over.
                    #If the base gets rebuilt the AI will use the old keyed conditions.
                    continue
                end
                numResults = numResults + 1
                v:CheckCondition()

                # Load balance per tick here
                checks = checks + 1
                if checks >= numPerTick then
                    WaitTicks(1)
                    checks = 0
                end
            end
            #LOG('*AI DEBUG: '.. self.Brain.Nickname ..' ConditionMonitorThread checked: '..numResults)
            WaitTicks(1)
        end
    end,

    # Adds a condition to the table and returns the key
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

    # forking and storing a thread on the monitor
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

function CreateConditionsMonitor(brain)
    local cMonitor = BrainConditionsMonitor()
    cMonitor:Create(brain)
    return cMonitor
end

Condition = Class {
    # Create the thing
    Create = function(self,brain,key)
        self.Status = false
        self.Brain = brain
        self.Key = key
    end,

    CheckCondition = function(self)
        self.Status = false
        return self.Status
    end,

    GetStatus = function(self, reportFailure)
        return self.Status
    end,

    GetKey = function(self)
        return self.Key
    end
}

ImportCondition = Class(Condition) {
    Create = function(self,brain,key,filename,funcName,funcData)
        Condition.Create(self,brain,key)
        self.Filename = filename
        self.FunctionName = funcName
        self.FunctionData = funcData
        self.CheckTime = false
    end,

    CheckCondition = function(self)
        if self.CheckTime != GetGameTimeSeconds() then
            self.Status = import(self.Filename)[self.FunctionName](self.Brain, unpack(self.FunctionData))
            self.CheckTime = GetGameTimeSeconds()
        end
        return self.Status
    end,

    GetStatus = function(self, reportFailure)
        if reportFailure and not self.Status then
            LOG('*AI DEBUG: Build Condition failed - ' .. self.FunctionName .. ' - Data: ' .. repr(self.FunctionData))
        end
        return self.Status
    end,

    LocationExists = function(self)
        local found = false
        for k,v in self.FunctionData do
            if type(v) == 'string' and not (v == 'Naval Area' or v == 'Expansion Area' or v == 'Large Expansion Area') then
                if stringFind(v, 'ARMY_') or stringFind(v, 'Large Expansion') or stringFind(v, 'Expansion Area') or stringFind(v, 'EXPANSION_AREA') or stringFind(v, 'Naval Area') or stringFind(v, 'MAIN') then
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

InstantImportCondition = Class(Condition) {
    Create = function(self,brain,key,filename,funcName,funcData)
        Condition.Create(self,brain,key)
        self.Filename = filename
        self.FunctionName = funcName
        self.FunctionData = funcData
        self.CheckTime = false
    end,

    # This class doesn't change when CheckCondition is called; Only changed when requested
    CheckCondition = function(self)
        #if self.CheckTime != GetGameTimeSeconds() then
            #self.Status = import(self.Filename)[self.FunctionName](self.Brain, unpack(self.FunctionData))
            #self.CheckTime = GetGameTimeSeconds()
        #end
        return self.Status
    end,

    # This class always performs the check when getting status (basically for stat checks)
    GetStatus = function(self, reportFailure)
        if self.CheckTime != GetGameTimeSeconds() then
            self.Status = import(self.Filename)[self.FunctionName](self.Brain, unpack(self.FunctionData))
            self.CheckTime = GetGameTimeSeconds()
            #LOG('*AI LOG: Instant Check')
        end
        if reportFailure and not self.Status then
            LOG('*AI DEBUG: Build Condition failed - ' .. self.FunctionName .. ' - Data: ' .. repr(self.FunctionData))
        end
        return self.Status
    end,

    LocationExists = function(self)
        local found = false
        for k,v in self.FunctionData do
            if type(v) == 'string' and not (v == 'Naval Area' or v == 'Expansion Area' or v == 'Large Expansion Area') then
                if stringFind(v, 'ARMY_') or stringFind(v, 'Large Expansion') or stringFind(v, 'Expansion Area') or stringFind(v, 'EXPANSION_AREA') or stringFind(v, 'Naval Area') or stringFind(v, 'MAIN') then
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

FunctionCondition = Class(Condition) {
    Create = function(self,brain,key,funcHandle,funcParams)
        Condition.Create(self,brain,key)
        self.FunctionHandle = funcHandle
        self.FunctionParameters = funcParams or {}
    end,

    CheckCondition = function(self)
        self.Status = self.FunctionHandle(self.Brain, unpack(self.FunctionParameters))
        return self.Status
    end,

    LocationExists = function(self)
        local found = false
        for k,v in self.FunctionParameters do
            if type(v) == 'string' and not (v == 'Naval Area' or v == 'Expansion Area' or v == 'Large Expansion Area') then
                if stringFind(v, 'ARMY_') or stringFind(v, 'Large Expansion') or stringFind(v, 'Expansion Area') or stringFind(v, 'EXPANSION_AREA') or stringFind(v, 'Naval Area') or stringFind(v, 'MAIN') then
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
