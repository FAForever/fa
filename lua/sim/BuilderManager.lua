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
local ForkThread = ForkThread

---@class BuilderManager
---@field Trash TrashBag
---@field Brain AIBrain
---@field BuilderData table
---@field BuilderCheckInterval number
---@field BuilderList boolean
---@field BuilderThread? thread             # Is defined when manager is enabled
---@field Active boolean                    # True when manager is enabled
---@field NumBuilders number
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

        -- TODO: use the built-in sort
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
    ---@param builderData BuilderSpec
    ---@param locationType string
    ---@param builderType string
    AddBuilder = function(self, builderData, locationType, builderType)
        local newBuilder = Builder.CreateBuilder(self.Brain, builderData, locationType)
        self:AddInstancedBuilder(newBuilder, builderType)
    end,

    ---@param self BuilderManager
    ---@param newBuilder Builder
    ---@param builderType string
    AddInstancedBuilder = function(self, newBuilder, builderType)
        -- can't proceed without a builder
        if not newBuilder then
            WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] *BUILDERMANAGER ERROR: Invalid builder!')
            return
        end

        -- can't proceed without a builder type
        builderType = builderType or newBuilder:GetBuilderType()
        if not builderType then
            WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] *BUILDERMANAGER ERROR: Invalid builder type: ' .. repr(builderType) .. ' - in builder: ' .. newBuilder.BuilderName)
            return
        end

        -- can't proceed without a valid builder type
        if not self.BuilderData[builderType] then
            WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] *BUILDERMANAGER ERROR: No BuilderData for builder: ' .. newBuilder.BuilderName)
            return
        end

        -- register the builder
        table.insert(self.BuilderData[builderType].Builders, newBuilder)
        self.BuilderData[builderType].NeedSort = true

        -- update internal state
        self.BuilderList = true
        self.NumBuilders = self.NumBuilders + 1

        -- process the builder
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
                        numTicks = numTicks + 1
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
        LOG("RebuildTable")
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

    -- forking and storing a thread on the monitor
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