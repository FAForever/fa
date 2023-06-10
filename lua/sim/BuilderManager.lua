--***************************************************************************
--*
--**  File     :  /lua/sim/BuilderManager.lua
--**
--**  Summary  : Manage builders
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local Builder = import("/lua/sim/builder.lua")

-- upvalue scope for performance
local TableSort = table.sort
local TableInsert = table.insert

local ForkThread = ForkThread

local BuilderCache = { }

---@param a Builder
---@param b Builder
local function BuilderSortLambda(a, b)
    return a.Priority > b.Priority
end

---@class AIBuilderData--***************************************************************************
--*
--**  File     :  /lua/sim/BuilderManager.lua
--**
--**  Summary  : Manage builders
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local Builder = import("/lua/sim/builder.lua")

---@class BuilderManager
BuilderManager = ClassSimple {
    ---@param self BuilderManager
    ---@param brain AIBrain
    Create = function(self, brain)
        self.Trash = TrashBag()
        self.Brain = brain
        self.BuilderData = {}
        self.BuilderCheckInterval = 13
        self.BuilderList = false
        self.Active = false
        self.NumBuilders = 0
        self:SetEnabled(true)

        self.NumGet = 0
    end,

    ---@param self BuilderManager
    Destroy = function(self)
        for _,bType in self.BuilderData do
            for k,v in bType do
                v = nil
            end
        end
        self.Trash:Destroy()
    end,

    -- forking and storing a thread on the monitor
    ---@param self BuilderManager
    ---@param fn function
    ---@param ... any
    ---@return thread|nil
    ForkThread = function(self, fn, ...)
        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            self.Trash:Add(thread)
            return thread
        else
            return nil
        end
    end,

    ---@param self BuilderManager
    ---@param enable boolean
    SetEnabled = function(self, enable)
        if not self.BuilderThread and enable then
            self.BuilderThread = self:ForkThread(self.ManagerThread)
            self.Active = true
        else
            KillThread(self.BuilderThread)
            self.BuilderThread = nil
            self.Active = false
        end
    end,

    ---@param self BuilderManager
    ---@param bType string
    ---@return boolean
    SortBuilderList = function(self, bType)
        -- Make sure there is a type
        if not self.BuilderData[bType] then
            error('*BUILDMANAGER ERROR: Trying to sort platoons of invalid builder type - ' .. bType)
            return false
        end
        local sortedList = {}
        --Simple selection sort, this can be made faster later if we decide we need it.
        for i = 1, table.getn(self.BuilderData[bType].Builders) do
            local highest = -1
            local key, value
            for k, v in self.BuilderData[bType].Builders do
                if v.Priority > highest then
                    highest = v.Priority
                    value = v
                    key = k
                end
            end
            sortedList[i] = value
            table.remove(self.BuilderData[bType].Builders, key)
        end
        self.BuilderData[bType].Builders = sortedList
        self.BuilderData[bType].NeedSort = false
    end,

    ---@param self BuilderManager
    ---@param builderName string
    ---@param changeTable table
    AlterBuilder = function(self, builderName, changeTable)
        for k,v in self.BuilderData do
            for num,builder in v.Builders do
                if builder.BuilderName == builderName then
                    for key,change in changeTable do
                        builder.key = change
                        if key == BuilderConditions then
                            ChangeState(builder, builder.SetupState)
                        end
                    end
                end
                break
            end
        end
    end,

    ---@param self BuilderManager
    ---@param builderData number
    ---@param locationType string
    ---@param builderType string
    AddBuilder = function(self, builderData, locationType, builderType)
        local newBuilder = Builder.CreateBuilder(self.Brain, builderData, locationType)
        self:AddInstancedBuilder(newBuilder, builderType)
    end,

    ---@param self BuilderManager
    ---@param newBuilder Unit
    ---@param builderType string
    AddInstancedBuilder = function(self,newBuilder, builderType)
        builderType = builderType or newBuilder:GetBuilderType()
        if not builderType then
            -- Warn the programmer that something is wrong. We can continue, hopefully the builder is not too important for the AI ;)
            -- But good for testing, and the case that a mod has bad builders.
            -- Output: WARNING: [buildermanager.lua, line:xxx] *BUILDERMANAGER ERROR: No BuilderData for builder: T3 Air Scout
            WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] *BUILDERMANAGER ERROR: Invalid builder type: ' .. repr(builderType) .. ' - in builder: ' .. newBuilder.BuilderName)
            return
        end
        if newBuilder then
            if not self.BuilderData[builderType] then
                -- Warn the programmer that something is wrong here. Same here, we can continue.
                -- Output: WARNING: [buildermanager.lua, line:xxx] *BUILDERMANAGER ERROR: No BuilderData for builder: T3 Air Scout
                WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] *BUILDERMANAGER ERROR: No BuilderData for builder: ' .. newBuilder.BuilderName)
                return
            end
            table.insert(self.BuilderData[builderType].Builders, newBuilder)
            self.BuilderData[builderType].NeedSort = true
            self.BuilderList = true
        end
        self.NumBuilders = self.NumBuilders + 1
        if newBuilder.InstantCheck then
            self:ManagerLoopBody(newBuilder)
        end
    end,

    ---@param self BuilderManager
    ---@param builderName string
    ---@return number|false
    GetBuilderPriority = function(self, builderName)
        for _,bType in self.BuilderData do
            for _,builder in bType.Builders do
                if builder.BuilderName == builderName then
                    return builder.Priority
                end
            end
        end
        return false
    end,

    ---@param self BuilderManager
    ---@param builderName string
    ---@return number|false
    GetActivePriority = function(self, builderName)
        for _,bType in self.BuilderData do
            for _,builder in bType.Builders do
                if builder.BuilderName == builderName then
                    return builder:GetActivePriority()
                end
            end
        end
        return false
    end,

    ---@param self BuilderManager
    ---@param builderName string
    ---@param priority integer
    ---@param temporary number
    ---@param setbystrat number
    SetBuilderPriority = function(self,builderName,priority,temporary,setbystrat)
        for _,bType in self.BuilderData do
            for _,builder in bType.Builders do
                if builder.BuilderName == builderName then
                    builder:SetPriority(priority, temporary, setbystrat)
                    return
                end
            end
        end
    end,

    ---@param self BuilderManager
    ---@param builderName string
    ResetBuilderPriority = function(self,builderName)
        for _,bType in self.BuilderData do
            for _,builder in bType.Builders do
                if builder.BuilderName == builderName then
                    builder:ResetPriority()
                    return
                end
            end
        end
    end,

    ---@param self BuilderManager
    GetLocationType = function(self)
        return self.LocationType
    end,

    ---@param self BuilderManager
    GetLocationCoords = function(self)
        if not self.Location then
            return false
        end
        local height = GetTerrainHeight(self.Location[1], self.Location[3])
        if GetSurfaceHeight(self.Location[1], self.Location[3]) > height then
            height = GetSurfaceHeight(self.Location[1], self.Location[3])
        end
        return { self.Location[1], height, self.Location[3] }
    end,

    ---@param self BuilderManager
    GetLocationRadius = function(self)
       return self.Radius
    end,

    ---@param self BuilderManager
    ---@param type string
    AddBuilderType = function(self, type)
        self.BuilderData[type] = { Builders = {}, NeedSort = false }
    end,

    ---@param self BuilderManager
    ---@param interval number
    SetCheckInterval = function(self, interval)
        self.BuildCheckInterval = interval
    end,

    ---@param self BuilderManager
    ClearBuilderLists = function(self)
        for k,v in self.Builders do
            v.Builders = {}
            v.NeedSort = false
        end
        self.BuilderList = false
    end,

    ---@param self BuilderManager
    HasBuilderList = function(self)
        return self.BuilderList
    end,

    -- Function that is run in GetHighestBuilder; allows us to test if the builder is valid
    -- within a certain type of builder mananger (ie: can factories build the builder)
    ---@param self BuilderManager
    ---@param builder Unit
    ---@param params any
    ---@return boolean
    BuilderParamCheck = function(self,builder,params)
        return true
    end,

    ---@param self BuilderManager
    ---@param builderName string
    ---@return any
    GetBuilder = function(self, builderName)
        for _,bType in self.BuilderData do
            for _,builder in bType.Builders do
                if builder.BuilderName == builderName then
                    return builder
                end
            end
        end
        return false
    end,

    -- We delay buildplatoons to give engineers the time to move and start building before we call this builder again.
    ---@param self BuilderManager
    ---@param DelayEqualBuildPlattons integer
    ---@return boolean
    IsPlattonBuildDelayed = function(self, DelayEqualBuildPlattons)
        if DelayEqualBuildPlattons then
            local CheckDelayTime = GetGameTimeSeconds()
            local PlatoonName = DelayEqualBuildPlattons[1]
            if not self.Brain.DelayEqualBuildPlattons[PlatoonName] or self.Brain.DelayEqualBuildPlattons[PlatoonName] < CheckDelayTime then
                --LOG('Setting '..DelayEqualBuildPlattons[2]..' sec. delaytime for builder ['..PlatoonName..']')
                self.Brain.DelayEqualBuildPlattons[PlatoonName] = CheckDelayTime + DelayEqualBuildPlattons[2]
                return false
            else
                --LOG('Builder ['..PlatoonName..'] still delayed for '..(CheckDelayTime - self.Brain.DelayEqualBuildPlattons[PlatoonName])..' seconds.')
                return true
            end
        end
    end,

    ---@param self BuilderManager
    ---@param bType string
    ---@param params any
    ---@return boolean
    GetHighestBuilder = function(self,bType,params)
        if not self.BuilderData[bType] then
            error('*BUILDERMANAGER ERROR: Invalid builder type - ' .. bType)
        end
        if not self.Brain.BuilderManagers[self.LocationType] then
            return false
        end
        self.NumGet = self.NumGet + 1
        local found = false
        local possibleBuilders = {}
        for k,v in self.BuilderData[bType].Builders do
            if v.Priority >= 1 and self:BuilderParamCheck(v,params) and (not found or v.Priority == found) and v:GetBuilderStatus() then
                if not self:IsPlattonBuildDelayed(v.DelayEqualBuildPlattons) then
                    found = v.Priority
                    table.insert(possibleBuilders, k)
                end
            elseif found and v.Priority < found then
                break
            end
        end
        if found and found > 0 then
            local whichBuilder = Random(1,table.getn(possibleBuilders))
            return self.BuilderData[bType].Builders[ possibleBuilders[whichBuilder] ]
        end
        return false
    end,

    -- Called every 13 seconds to perform any cleanup; Provides better inheritance
    ---@param self BuilderManager
    ManagerThreadCleanup = function(self)
        for bType,bTypeData in self.BuilderData do
            if bTypeData.NeedSort then
                self:SortBuilderList(bType)
            end
        end
    end,

    ---@param self BuilderManager
    ---@param builder Unit
    ---@param bType string
    ManagerLoopBody = function(self,builder,bType)
        if builder:CalculatePriority(self) then
            self.BuilderData[bType].NeedSort = true
        end
        --builder:CheckBuilderConditions(self.Brain)
    end,

    ---@param self BuilderManager
    ManagerThread = function(self)
        while self.Active do
            self:ManagerThreadCleanup()
            local numPerTick = math.ceil(self.NumBuilders / (self.BuilderCheckInterval * 10))
            local numTicks = 0
            local numTested = 0
            for bType,bTypeData in self.BuilderData do
                for bNum,bData in bTypeData.Builders do
                    numTested = numTested + 1
                    if numTested >= numPerTick then
                        WaitTicks(1)
                        if self.NumGet > 1 then
                            --LOG('*AI STAT: NumGet = ' .. self.NumGet)
                        end
                        self.NumGet = 0
                        numTicks = numTicks + 1
                        numTest = 0
                    end
                    self:ManagerLoopBody(bData,bType)
                end
            end
            if numTicks <= (self.BuilderCheckInterval * 10) then
                WaitTicks((self.BuilderCheckInterval * 10) - numTicks)
            end
        end
    end,
    
    ---@param self, BuilderManager
    ---@param oldtable, Table
    ---@return tempTable, Table
    RebuildTable = function(self, oldtable)
        local temptable = {}
        for k, v in oldtable do
            if v ~= nil then
                if type(k) == 'string' then
                    temptable[k] = v
                else
                    table.insert(temptable, v)
                end
            end
        end
        return temptable
    end,
}


-- kept for mod backwards compatibility
local AIUtils = import("/lua/ai/aiutilities.lua")
local AIBuildUnits = import("/lua/ai/aibuildunits.lua")
---@field Builders Builder[]
---@field NeedSort boolean

--- An abstract class of the various managers. Introduces the logic to maintain
--- and find builders as the base is trying to figure out what to do
---@class BuilderManager
---@field Brain AIBrain                                     # A reference to the brain that this manager belongs to
---@field BuilderData table<BuilderType, AIBuilderData>     # List of builders that is managed by this manager
---@field BuilderCheckInterval number   # Interval (in seconds)
---@field BuilderList boolean           # Is true when there is at least one builder in this manager
---@field BuilderThread? thread         # Thread that runs the loop, does not exist when the manager is not active
---@field Active boolean                # Is true when the manager is enabled, use `SetEnabled` to toggle it
---@field Location Vector               # Tthe center of this base
--- The base name or the base identifier. It is used as an identifier in the brain
--- to be able to find the various managers that belong to a base
---
--- The name of this field does not do it any justice, it should rather be 'LocationName'
---@field LocationType LocationType
---@field NumBuilders number            # Number of builders in this manager
---@field Radius number                 # Radius of this manager
---@field Trash TrashBag                # Trashbag of this manager
BuilderManager = ClassSimple {

    ---@param self BuilderManager
    ---@param brain AIBrain
    Create = function(self, brain, locationType, location, radius)
        self.Trash = TrashBag()
        self.Brain = brain
        self.BuilderData = {}
        self.BuilderCheckInterval = 13
        self.BuilderList = false

        self.Radius = radius
        self.LocationType = locationType
        self.Location = location
        if self.Location then
            self.Location[2] = GetSurfaceHeight(self.Location[1], self.Location[3])
        end

        self.Active = false
        self.NumBuilders = 0
        self:SetEnabled(true)
        self:ForkThread(self.DebugThread)
    end,

    ---@param self BuilderManager
    Destroy = function(self)
        self.Trash:Destroy()
    end,

    --------------------------------------------------------------------------------------------
    -- builder interface

    -- This is where the majority of the magic happens. There are two main phases:
    --
    -- 1. Initialisation
    --
    -- During initialisation the builders are introduced. Usually no builders are introduced
    -- after the manager is created. Note that all builders have unique instances in memory.
    --
    -- 2. Retrieving the highest priority builder
    --
    -- Once all builders are in place we constantly look for the highest possible builder. We
    -- consider the name 'Builder' to be poorly choosen, one should rather read it as a 'Task'
    --
    -- A task has a priority. The tasks with the highest priority are evaluated first. Each
    -- task has a series of conditions attached to it. These conditions are evaluated as
    -- we are searching for a task.
    --
    -- Once a task is found it can be assigned. This abstract manager does not manage that, it
    -- is merely an abstraction to interact with the various builders.

    --- Adds a builder type to this manager
    ---@param self BuilderManager
    ---@param type BuilderType
    AddBuilderType = function(self, type)
        self.BuilderData[type] = { Builders = {}, NeedSort = false }
    end,

    --- Adds a builder to the manager, usually this function is overwritten by the managers that inherit this builder
    ---@param self BuilderManager
    ---@param builderData BuilderSpec
    ---@param locationType LocationType
    ---@param builderType BuilderType
    AddBuilder = function(self, builderData, locationType, builderType)
        local newBuilder = Builder.CreateBuilder(self.Brain, builderData, locationType)
        self:AddInstancedBuilder(newBuilder, builderType)
    end,

    --- Adds an abstract builder to the manager
    ---@param self BuilderManager
    ---@param newBuilder Builder
    ---@param builderType BuilderType
    AddInstancedBuilder = function(self, newBuilder, builderType)
        -- can't proceed without a builder
        if not newBuilder then
            WARN('[' ..
                string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1") ..
                ', line:' .. debug.getinfo(1).currentline .. '] *BUILDERMANAGER ERROR: Invalid builder!')
            return
        end

        -- can't proceed without a builder type
        builderType = builderType or newBuilder:GetBuilderType()
        if not builderType then
            WARN('[' ..
                string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1") ..
                ', line:' ..
                debug.getinfo(1).currentline ..
                '] *BUILDERMANAGER ERROR: Invalid builder type: ' ..
                repr(builderType) .. ' - in builder: ' .. newBuilder.BuilderName)
            return
        end

        -- can't proceed without a builder type that we support
        if not self.BuilderData[builderType] then
            WARN('[' ..
                string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1") ..
                ', line:' ..
                debug.getinfo(1).currentline ..
                '] *BUILDERMANAGER ERROR: No BuilderData for builder: ' .. newBuilder.BuilderName)
            return
        end

        -- register the builder
        TableInsert(self.BuilderData[builderType].Builders, newBuilder)
        self.BuilderData[builderType].NeedSort = true

        -- update internal state
        self.BuilderList = true
        self.NumBuilders = self.NumBuilders + 1

        -- process the builder
        if newBuilder.InstantCheck then
            self:ManagerLoopBody(newBuilder)
        end
    end,

    --- Retrieves the first builder with a matching `BuilderName` field
    ---@param self BuilderManager
    ---@param builderName string
    ---@return Builder?
    GetBuilder = function(self, builderName)
        for _, bType in self.BuilderData do
            for _, builder in bType.Builders do
                if builder.BuilderName == builderName then
                    return builder
                end
            end
        end
    end,

    --- Retrieves the highest builder that is valid with the given parameters
    ---@param self BuilderManager
    ---@param bType BuilderType
    ---@param params table
    ---@return Builder?
    GetHighestBuilder = function(self, bType, params)
        local builderData = self.BuilderData[bType]
        if not builderData then
            error('*BUILDERMANAGER ERROR: Invalid builder type - ' .. bType)
        end

        local candidates = BuilderCache
        local candidateNext = 1
        local candidatePriority = -1

        -- list of builders that is sorted on priority
        local builders = builderData.Builders
        for k in builders do
            local builder = builders[k] --[[@as Builder]]

            -- builders with no priority are ignored
            local priority = builder.Priority
            if priority >= 1 then
                -- break when we have found a builder and the next builder has a lower priority
                if priority < candidatePriority then
                    break
                end

                -- check if we're intentionally delaying this builder
                if not self:IsPlattonBuildDelayed(builder.DelayEqualBuildPlattons) then
                    -- check builder conditions
                    if self:BuilderParamCheck(builder, params) then
                        -- check task conditions
                        if builder:GetBuilderStatus() then
                            candidates[candidateNext] = builder
                            candidateNext = candidateNext + 1
                            candidatePriority = priority
                        end
                    end
                end
            end
        end

        -- only one candidate
        if candidateNext == 2 then
            return candidates[1]

        -- multiple candidates, choose one at random
        elseif candidateNext > 2 then
            return candidates[Random(1, candidateNext - 1)]
        end
    end,

    --- Returns true if the given builders matches the manager-specific parameters
    ---@param self BuilderManager
    ---@param builder Builder
    ---@param params table
    ---@return boolean
    BuilderParamCheck = function(self, builder, params)
        return true
    end,

    --- Retrieves the priority of a builder
    ---@param self BuilderManager
    ---@param builderName string
    ---@return number?
    GetBuilderPriority = function(self, builderName)
        local builder = self:GetBuilder(builderName)
        if builder then
            return builder.Priority
        end
    end,

    --- Defines the priority of a builder
    ---@param self BuilderManager
    ---@param builderName string
    ---@param priority integer
    ---@param temporary? boolean
    ---@param setbystrat? boolean
    SetBuilderPriority = function(self, builderName, priority, temporary, setbystrat)
        local builder = self:GetBuilder(builderName)
        if builder then
            return builder:SetPriority(priority, temporary, setbystrat)
        end
    end,

    --- Resets the priority of a builder
    ---@param self BuilderManager
    ---@param builderName string
    ResetBuilderPriority = function(self, builderName)
        local builder = self:GetBuilder(builderName)
        if builder then
            builder:ResetPriority()
        end
    end,

    --- We can delay builders / tasks to give engineers the time to move and start building. The first argument of the 
    --- specs is an idenfitier, which can be shared across several builders / tasks. This allows us to delay a group of
    --- platoons that we consider expensive
    --- 
    --- We're aware that the there is a typo in the name: we can't fix it without breaking backwards compatibility with mods
    ---@param self BuilderManager
    ---@param specs { [1]: string, [2]: number }
    ---@return boolean
    IsPlattonBuildDelayed = function(self, specs)
        if specs then
            local CheckDelayTime = GetGameTimeSeconds()
            local PlatoonName = specs[1] --[[@as string]]
            local timeThreshold = self.Brain.DelayEqualBuildPlattons[PlatoonName]
            if (not timeThreshold) or (timeThreshold < CheckDelayTime) then
                self.Brain.DelayEqualBuildPlattons[PlatoonName] = CheckDelayTime + specs[2]
                return false
            else
                return true
            end
        end

        return false
    end,

    --------------------------------------------------------------------------------------------
    -- builder list interface

    --- Clears all builders
    ---@param self BuilderManager
    ClearBuilderLists = function(self)
        for k, v in self.BuilderData do
            v.Builders = {}
            v.NeedSort = false
        end
        self.BuilderList = false
    end,

    --- Returns true if this manager has one or more builders
    ---@param self BuilderManager
    HasBuilderList = function(self)
        return self.BuilderList
    end,

    --- Sorts the builders of this manager so that high priority builders are checked first
    ---@param self BuilderManager
    ---@param bType BuilderType
    ---@return boolean
    SortBuilderList = function(self, bType)
        -- Make sure there is a type
        if not self.BuilderData[bType] then
            error('*BUILDMANAGER ERROR: Trying to sort platoons of invalid builder type - ' .. bType)
            return false
        end

        TableSort(self.BuilderData[bType].Builders, BuilderSortLambda)
        self.BuilderData[bType].NeedSort = false
    end,

    ---@param self BuilderManager
    ---@param enable boolean
    SetEnabled = function(self, enable)
        if not self.BuilderThread and enable then
            self.BuilderThread = self:ForkThread(self.ManagerThread)
            self.Active = true
        else
            KillThread(self.BuilderThread)
            self.BuilderThread = nil
            self.Active = false
        end
    end,

    --------------------------------------------------------------------------------------------
    -- manager interface

    -- Called every 13 seconds to perform any cleanup; Provides better inheritance
    ---@param self BuilderManager
    ManagerThreadCleanup = function(self)
        for bType, bTypeData in self.BuilderData do
            if bTypeData.NeedSort then
                self:SortBuilderList(bType)
            end
        end
    end,

    ---@param self BuilderManager
    ---@param builder Unit
    ---@param bType string
    ManagerLoopBody = function(self, builder, bType)
        if builder:CalculatePriority(self) then
            self.BuilderData[bType].NeedSort = true
        end
    end,

    ---@param self BuilderManager
    ManagerThread = function(self)
        while self.Active do
            self:ManagerThreadCleanup()
            local numPerTick = math.ceil(self.NumBuilders / (self.BuilderCheckInterval * 10))
            local numTicks = 0
            local numTested = 0
            for bType, bTypeData in self.BuilderData do
                for bNum, bData in bTypeData.Builders do
                    numTested = numTested + 1
                    if numTested >= numPerTick then
                        WaitTicks(1)
                        numTicks = numTicks + 1
                    end
                    self:ManagerLoopBody(bData, bType)
                end
            end
            if numTicks <= (self.BuilderCheckInterval * 10) then
                WaitTicks((self.BuilderCheckInterval * 10) - numTicks)
            end
        end
    end,

    --------------------------------------------------------------------------------------------
    -- properties

    ---@param self BuilderManager
    GetLocationCoords = function(self)
        local location = self.Location
        if not location then
            return false
        end

        return location
    end,

    ---@param self BuilderManager
    ---@return number
    GetLocationRadius = function(self)
        return self.Radius
    end,

    ---@param self BuilderManager
    ---@param interval number
    SetCheckInterval = function(self, interval)
        self.BuildCheckInterval = interval
    end,

    --------------------------------------------------------------------------------------------
    -- unit events

    --- Called by a unit as it starts being built
    ---@param self BuilderManager
    ---@param unit Unit
    OnUnitStartBeingBuilt = function(self, unit)
    end,

    --- Called by a unit as it is finished being built
    ---@param self BuilderManager
    ---@param unit Unit
    OnUnitStopBeingBuilt = function(self, unit)
    end,

    --- Called by a unit as it is destroyed
    ---@param self BuilderManager
    ---@param unit Unit
    OnUnitDestroyed = function(self, unit)
    end,

    --- Called by a unit as it starts building
    ---@param self BuilderManager
    ---@param unit Unit
    ---@param built Unit
    OnUnitStartBuilding = function(self, unit, built)
    end,

    --- Called by a unit as it stops building
    ---@param self BuilderManager
    ---@param unit Unit
    ---@param built Unit
    OnUnitStopBuilding = function(self, unit, built)
    end,

    --------------------------------------------------------------------------------------------
    --- debug functionality

    DebugThread = function(self)
    end,

    --------------------------------------------------------------------------------------------
    --- deprecated functionality

    --- This section contains functionality that is either deprecated (unmaintained) or
    --- functionality that is considered bad practice for performance

    ---@deprecated
    ---@param self BuilderManager
    ---@param builderName string
    ---@return number|false
    GetActivePriority = function(self, builderName)
        for _, bType in self.BuilderData do
            for _, builder in bType.Builders do
                if builder.BuilderName == builderName then
                    return builder:GetActivePriority()
                end
            end
        end
        return false
    end,

    --- This function should not be required
    ---@deprecated
    ---@param self BuilderManager
    ---@param oldtable table
    ---@return table
    RebuildTable = function(self, oldtable)
        local temptable = {}
        for k, v in oldtable do
            if v ~= nil then
                if type(k) == 'string' then
                    temptable[k] = v
                else
                    table.insert(temptable, v)
                end
            end
        end
        return temptable
    end,

    --- Root of all performance evil, do not use - inline the function instead
    ---@deprecated
    ---@param self BuilderManager
    ---@param fn function
    ---@param ... any
    ---@return thread|nil
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


-- kept for mod backwards compatibility
local AIUtils = import("/lua/ai/aiutilities.lua")
local AIBuildUnits = import("/lua/ai/aibuildunits.lua")
