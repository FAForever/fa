local DebugNames = false -- Display next building Platoonn inside LOG

#***************************************************************************
#*
#**  File     :  /lua/sim/BuilderManager.lua
#**
#**  Summary  : Manage builders
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AIUtils = import('/lua/ai/aiutilities.lua')
local Builder = import('/lua/sim/Builder.lua')
local AIBuildUnits = import('/lua/ai/aibuildunits.lua')

-- AI DEBUG
local AntiSpamList = {}
local AntiSpamCounter = 0
local LastBuilder = ''

BuilderManager = Class {
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

    Destroy = function(self)
        for _,bType in self.BuilderData do
            for k,v in bType do
                v = nil
            end
        end
        self.Trash:Destroy()
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

    SortBuilderList = function(self, bType)
        # Make sure there is a type
        if not self.BuilderData[bType] then
            error('*BUILDMANAGER ERROR: Trying to sort platoons of invalid builder type - ' .. bType)
            return false
        end
        local sortedList = {}
        #Simple selection sort, this can be made faster later if we decide we need it.
        for i = 1, table.getn(self.BuilderData[bType].Builders) do
            local highest = 0
            local key, value
            for k, v in self.BuilderData[bType].Builders do
                if v:GetPriority() > highest then
                    highest = v:GetPriority()
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

    AddBuilder = function(self, builderData, locationType, builderType)
        local newBuilder = Builder.CreateBuilder(self.Brain, builderData, locationType)
        self:AddInstancedBuilder(newBuilder, builderType)
    end,

    AddInstancedBuilder = function(self,newBuilder, builderType)
        builderType = builderType or newBuilder:GetBuilderType()
        if not builderType then
            -- Warn the programmer that something is wrong. We can continue, hopefully the builder is not too important for the AI ;)
            -- But god for testing, and the case that a mod has bad builders.
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

    GetBuilderPriority = function(self, builderName)
        for _,bType in self.BuilderData do
            for _,builder in bType.Builders do
                if builder:GetBuilderName() == builderName then
                    return builder:GetPriority()
                end
            end
        end
        return false
    end,

    GetActivePriority = function(self, builderName)
        for _,bType in self.BuilderData do
            for _,builder in bType.Builders do
                if builder:GetBuilderName() == builderName then
                    return builder:GetActivePriority()
                end
            end
        end
        return false
    end,

    SetBuilderPriority = function(self,builderName,priority,temporary,setbystrat)
        for _,bType in self.BuilderData do
            for _,builder in bType.Builders do
                if builder:GetBuilderName() == builderName then
                    builder:SetPriority(priority, temporary, setbystrat)
                    return
                end
            end
        end
    end,

    ResetBuilderPriority = function(self,builderName)
        for _,bType in self.BuilderData do
            for _,builder in bType.Builders do
                if builder:GetBuilderName() == builderName then
                    builder:ResetPriority()
                    return
                end
            end
        end
    end,

    GetLocationType = function(self)
        return self.LocationType
    end,

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

    GetLocationRadius = function(self)
       return self.Radius
    end,

    AddBuilderType = function(self, type)
        self.BuilderData[type] = { Builders = {}, NeedSort = false }
    end,

    SetCheckInterval = function(self, interval)
        self.BuildCheckInterval = interval
    end,

    ClearBuilderLists = function(self)
        for k,v in self.Builders do
            v.Builders = {}
            v.NeedSort = false
        end
        self.BuilderList = false
    end,

    HasBuilderList = function(self)
        return self.BuilderList
    end,

    # Function that is run in GetHighestBuilder; allows us to test if the builder is valid
    # within a certain type of builder mananger (ie: can factories build the builder)
    BuilderParamCheck = function(self,builder,params)
        return true
    end,

    GetBuilder = function(self, builderName)
        for _,bType in self.BuilderData do
            for _,builder in bType.Builders do
                if builder:GetBuilderName() == builderName then
                    return builder
                end
            end
        end
        return false
    end,
    
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
            if v:GetPriority() >= 1 and self:BuilderParamCheck(v,params) and (not found or v:GetPriority() == found) and v:GetBuilderStatus() then
                if not self:IsPlattonBuildDelayed(v:GetBuildDelay()) then
                    found = v:GetPriority()
                    table.insert(possibleBuilders, k)
                    if DebugNames and (string.find(v.BuilderName,'U1') or string.find(v.BuilderName,'U2') or string.find(v.BuilderName,'U3')) then
                        LOG('* AI DEBUG: GetHighestBuilder: Priority = '..found..' - possibleBuilders = '..repr(v.BuilderName))
                    end
                end
            elseif found and v:GetPriority() < found then
                break
            end
        end
        if found and found > 0 then
            local whichBuilder = Random(1,table.getn(possibleBuilders))
            -- DEBUG - Start
            -- If we have a builder that is repeating (Happens when buildconditions are true, but the builder can't find something to build/assist etc.)
            local BuilderName = self.BuilderData[bType].Builders[ possibleBuilders[whichBuilder] ].BuilderName
            if BuilderName ~= LastBuilder then
                LastBuilder = BuilderName
                AntiSpamCounter = 0
            elseif not AntiSpamList[BuilderName] then
                AntiSpamCounter = AntiSpamCounter + 1
                if AntiSpamCounter > 6 then
                    -- Warn the programmer that something is going wrong.
                    WARN('* AI DEBUG: GetHighestBuilder: Builder is spaming. Maybe wrong Buildconditions for Builder = '..repr(self.BuilderData[bType].Builders[ possibleBuilders[whichBuilder] ].BuilderName)..' ???')
                    AntiSpamCounter = 0
                    AntiSpamList[BuilderName] = true
                end                
            end
            -- DEBUG - End
            if DebugNames and (string.find(BuilderName,'U1') or string.find(BuilderName,'U2') or string.find(BuilderName,'U3')) then
                LOG('* AI DEBUG: GetHighestBuilder: SelectedBuilder = '..repr(self.BuilderData[bType].Builders[ possibleBuilders[whichBuilder] ].BuilderName))
            end
            return self.BuilderData[bType].Builders[ possibleBuilders[whichBuilder] ]
        end
        return false
    end,

    # Called every 13 seconds to perform any cleanup; Provides better inheritance
    ManagerThreadCleanup = function(self)
        for bType,bTypeData in self.BuilderData do
            if bTypeData.NeedSort then
                self:SortBuilderList(bType)
            end
        end
    end,

    ManagerLoopBody = function(self,builder,bType)
        if builder:CalculatePriority(self) then
            self.BuilderData[bType].NeedSort = true
        end
        #builder:CheckBuilderConditions(self.Brain)
    end,

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
                            #LOG('*AI STAT: NumGet = ' .. self.NumGet)
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
}
