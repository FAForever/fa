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
local TableInsert =

local ForkThread = ForkThread

---@alias LocationType
--- can only be applied to the main base
--- | 'MAIN'
--- can be applied by any base
--- | 'LocationType'
--- name of expansion marker of the base
--- | string

---@param a Builder
---@param b Builder
local function BuilderSortLambda(a, b)
    return a.Priority > b.Priority
end

--- Abstract manager that contains shared logic between the various managers that inherit from it
---@class BuilderManager
---@field Brain AIBrain
---@field BuilderData table
---@field BuilderCheckInterval number
---@field BuilderList boolean
---@field BuilderThread? thread             # is defined when manager is enabled
---@field Active boolean                    # true when manager is enabled
---@field Location Vector
---@field LocationType LocationType
---@field NumBuilders number
---@field Trash TrashBag
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
    end,

    ---@param self BuilderManager
    Destroy = function(self)
        self.Trash:Destroy()
    end,

    -----------------------
    -- builder interface --

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

    --- Retrieves the highest builder that is valid with the given parameters, or false if there is none
    ---@param self BuilderManager
    ---@param bType BuilderType
    ---@param params any
    ---@return Builder | false
    GetHighestBuilder = function(self, bType, params)
        if not self.BuilderData[bType] then
            error('*BUILDERMANAGER ERROR: Invalid builder type - ' .. bType)
        end
        if not self.Brain.BuilderManagers[self.LocationType] then
            return false
        end

        local found = false
        local possibleBuilders = {}
        for k, v in self.BuilderData[bType].Builders do
            if v.Priority >= 1 and self:BuilderParamCheck(v, params) and (not found or v.Priority == found) and
                v:GetBuilderStatus() then
                if not self:IsPlattonBuildDelayed(v.DelayEqualBuildPlattons) then
                    found = v.Priority
                    TableInsert(possibleBuilders, k)
                end
            elseif found and v.Priority < found then
                break
            end
        end

        if found and found > 0 then
            local whichBuilder = Random(1, table.getn(possibleBuilders))
            return self.BuilderData[bType].Builders[ possibleBuilders[whichBuilder] ]
        end
        return false
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

    --------------------------------
    -- builder list interface --

    --- Clears all builders
    ---@param self BuilderManager
    ClearBuilderLists = function(self)
        for k, v in self.Builders do
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
        local
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

    -- We delay buildplatoons to give engineers the time to move and start building before we call this builder again.
    ---@param self BuilderManager
    ---@param DelayEqualBuildPlattons integer
    ---@return boolean
    IsPlattonBuildDelayed = function(self, DelayEqualBuildPlattons)
        if DelayEqualBuildPlattons then
            local CheckDelayTime = GetGameTimeSeconds()
            local PlatoonName = DelayEqualBuildPlattons[1]
            if not self.Brain.DelayEqualBuildPlattons[PlatoonName] or
                self.Brain.DelayEqualBuildPlattons[PlatoonName] < CheckDelayTime then
                --LOG('Setting '..DelayEqualBuildPlattons[2]..' sec. delaytime for builder ['..PlatoonName..']')
                self.Brain.DelayEqualBuildPlattons[PlatoonName] = CheckDelayTime + DelayEqualBuildPlattons[2]
                return false
            else
                --LOG('Builder ['..PlatoonName..'] still delayed for '..(CheckDelayTime - self.Brain.DelayEqualBuildPlattons[PlatoonName])..' seconds.')
                return true
            end
        end
    end,

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
        --builder:CheckBuilderConditions(self.Brain)
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

    ----------------
    -- properties --

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
    ---@return number
    GetLocationRadius = function(self)
        return self.Radius
    end,

    ---@param self BuilderManager
    ---@param interval number
    SetCheckInterval = function(self, interval)
        self.BuildCheckInterval = interval
    end,

    ------------------------------
    -- deprecated functionality --

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


    -- Root of all performance evil, do not use - inline the function instead
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
