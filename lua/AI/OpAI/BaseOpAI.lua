--***************************************************************************
--*
--**  File     :  /lua/ai/OpAI/BaseOpAI.lua
--**  Author(s): Dru Staltman
--**
--**  Summary  : Base manager for operations
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")

local UCBC = '/lua/editor/unitcountbuildconditions.lua'
local BMBC = '/lua/editor/basemanagerbuildconditions.lua'
local MIBC = '/lua/editor/miscbuildconditions.lua'
local BMPT = '/lua/ai/opai/basemanagerplatoonthreads.lua'

---@class OpAI
OpAI = ClassSimple {
        -- Set up variables local to this OpAI instance
        PreCreate = function(self)
            if self.PreCreateFinished then
                return true
            end
            self.Trash = TrashBag()

            self.AIBrain = false
            self.LocationType = false

            self.MasterName = false
            self.GlobalVarName = false
            self.BuilderType = false

            self.MasterData = false -- Set to builder later
            self.ChildrenHandles = false -- Set to table later

            self.ChildMonitorHandle = false
            self.PreCreateFinished = true
        end,

        FindMaster = function(self, force)
            if self.MasterData and not force then
                return true
            end
            for k,v in self.AIBrain.AttackData.Platoons do
                if v.PlatoonName == self.MasterName then
                    self.MasterData = v
                    return true
                end
            end
            return false
        end,

        FindChildren = function(self, force)
            if self.ChildrenHandles and not table.empty(self.ChildrenHandles) and not force then
                return true
            end
            self.ChildrenHandles = {}
            local types = { 'Air', 'Land', 'Sea' }
            for tNum,currType in types do
                for name,builder in ScenarioInfo.BuilderTable[self.AIBrain.CurrentPlan][currType] do
                    if self:ChildNameCheck(name) then
                        table.insert(self.ChildrenHandles, { ChildName=name, ChildBuilder=builder })
                    end
                end
            end
            return true
        end,

        AddChildType = function(self,typeTable)
            if typeTable then
                for tNum, tName in typeTable do
                    if self.EnabledTypes[tName] == nil then
                        self.EnabledTypes[tName] = true
                    end
                end
            end
        end,

        ChildNameCheck = function(self,name)
            for k,v in self.ChildrenNames do
                local found = string.find(v.BuilderName, name .. '_', 1, true)
                if v.BuilderName == name or found then
                    return true
                end
            end
            return false
        end,

        SetChildCount = function(self,number, childType)
            if not childType then
                ScenarioInfo.OSPlatoonCounter[self.MasterName..'_D'..ScenarioInfo.Options.Difficulty] = number
            else
                ScenarioInfo.OSPlatoonCounter[self.MasterName..'_'..childType..'_D'..ScenarioInfo.Options.Difficulty] = number
            end
        end,

        SetChildCountDiffTable = function(self,diffTable)
            ScenarioInfo.OSPlatoonCounter[self.MasterName..'_D1'] = diffTable[1]
            ScenarioInfo.OSPlatoonCounter[self.MasterName..'_D2'] = diffTable[2]
            ScenarioInfo.OSPlatoonCounter[self.MasterName..'_D3'] = diffTable[3]
        end,

        SetChildrenPlatoonAI = function(self, functionInfo, childType)
            if not self:FindChildren() then
                error('*AI DEBUG: No children for OpAI found')
            end
            for k,v in self.ChildrenHandles do
                v.ChildBuilder.PlatoonAIFunction = functionInfo
            end
        end,

        SetFormation = function(self, formationName)
            if not self:FindMaster() then
                return false
            end
            self.MasterData.PlatoonData.OverrideFormation = formationName
            return true
        end,

        SetFunctionStatus = function(self,funcName,bool)
            ScenarioInfo.OSPlatoonCounter[self.MasterName..'_' .. funcName] = bool
        end,

        -- TODO: make a system out of this.  Derive functionality per override per OpAI type
        MasterPlatoonFunctionalityChange = function(self, functionData)
            if functionData[2] == 'LandAssaultWithTransports' then
                self:SetFunctionStatus('Transports', true)
            end
        end,

        TargetCommanderLast = function(self, cat)
            return self:SetTargettingPriorities(
            {
                categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.DEFENSE,
                categories.STRUCTURE * categories.ECONOMIC,
                categories.MOBILE - categories.COMMAND,
                categories.ALLUNITS - categories.COMMAND,
                categories.COMMAND,

            }
            , cat)
        end,

        TargetCommanderNever = function(self, cat)
            return self:SetTargettingPriorities(
            {
                categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.DEFENSE,
                categories.STRUCTURE * categories.ECONOMIC,
                categories.MOBILE - categories.COMMAND,
                categories.ALLUNITS - categories.COMMAND,
            }
            , cat)
        end,

        --categories is an optional parameter specifying a subset of the platoon we wish to set target priorities for.
        SetTargettingPriorities = function(self, priTable, categories)
            if not self:FindMaster() then
                return false
            end

            local priList = { unpack(priTable) }
            local defList = { 'COMMAND', 'MOBILE', 'STRUCTURE DEFENSE', 'ALLUNITS',}

            if categories then
                --save the priorities for this category.
                if not self.MasterData.PlatoonData.CategoryPriorities then self.MasterData.PlatoonData.CategoryPriorities = {} end

                --NOTE: This should probably be a table.deepcopy if we're going to alter the original table in the future.

                self.MasterData.PlatoonData.CategoryPriorities[categories] = priList

            else
                for i,v in defList do
                    table.insert(priList, v)
                end

                self.MasterData.PlatoonData.TargetPriorities = {}

                for i,v in priList do
                    table.insert(self.MasterData.PlatoonData.TargetPriorities, v)
                end

                --for k,v in priTable do
                --    table.insert(self.MasterData.PlatoonData.TargetPriorities, v)
                --end
                --for k,v in defaultPri do
                --    table.insert(self.MasterData.PlatoonData.TargetPriorities, v)
                --end

            end

            table.insert(self.MasterData.PlatoonAddFunctions, { '/lua/ai/opai/BaseManagerPlatoonThreads.lua', 'PlatoonSetTargetPriorities' })

            return true
        end,

        -- childData = {
        --     { 'LightTanks', 'LightBots' },
        --     {
        --         Function or function table,
        --         Function or function table,
        --         Function or function table,
        --     },
        -- }
        AddChildrenMonitor = function(self, childrenData)
            for k,v in childrenData do
                self:AddChildMonitor(v)
            end
        end,

        AddChildMonitor = function(self, childData)
            -- add children and functions to the child table in self
            -- ChildMonitorData
            for tNum,tName in childData[1] do
                if self.EnabledTypes[tName] == nil then
                    error('*AI DEBUG: Invalid child type - ' .. tName .. ' - in OpAI type - ' .. self.BuilderType, 2)
                end
                if not self.ChildMonitorData[tName] then
                    self.ChildMonitorData[tName] = {}
                end
            end
            for fNum,fData in childData[2] do
                if type(fData) == 'table' then
                    -- Check function data
                    for tNum,tName in childData[1] do
                        table.insert(self.ChildMonitorData[tName], { FunctionInfo = fData })
                    end
                elseif type(fData) == 'function' then
                    for tNum,tName in childData[1] do
                        table.insert(self.ChildMonitorData[tName], { DirectFunction = fData })
                    end
                end
            end

            -- run the check once and enable/disable as needed
            for tNum,tName in childData[1] do
                self:ChildMonitorCheck(tName, self.ChildMonitorData[tName])
            end

            -- start thread if not already started
            if not self.ChildMonitorHandle then
                self.ChildMonitorHandle = ForkThread(self.ChildMonitorThread, self)
                self.Trash:Add(self.ChildMonitorHandle)
            end
        end,

        ChildMonitorThread = function(self)
            while true do
                -- Iterate through list enabling/disabling children types as needed.
                for name,data in self.ChildMonitorData do
                    self:ChildMonitorCheck(name, data)
                end
                WaitSeconds(7)
            end
        end,

        ChildMonitorCheck = function(self, childName, childData)
            for k,v in childData do
                if v.DirectFunction and not v.DirectFunction() then
                    self:SetChildActive(childName, false)
                    return false
                elseif v.FunctionInfo then
                    if v.FunctionInfo[3][1] == "default_brain" then
                        table.remove(v.FunctionInfo[3], 1)
                    end
                    if not import(v.FunctionInfo[1])[v.FunctionInfo[2]](self.AIBrain, unpack(v.FunctionInfo[3])) then
                        self:SetChildActive(childName, false)
                        return false
                    end
                end
            end
            self:SetChildActive(childName, true)
            return true
        end,

        SetChildQuantity = function(self, childrenType, quantity)
            if not self:FindChildren() or not self:FindMaster() then
                return false
            end
            self:SetChildActive('All', false)
            if type(childrenType) == 'table' then
                self:SetChildrenActive(childrenType)
            else
                self:SetChildActive(childrenType, true)
            end
            self:SetChildCount(1)
            self:KeepChildren(childrenType)
            self:OverrideTemplateSize(quantity)
        end,

        RemoveChildren = function(self, childrenType)
            if not self:FindChildren() then
                return false
            end
            local removeTable = {}
            if type(childrenType) == 'table' then
                removeTable = childrenType
            else
                table.insert(removeTable, childrenType)
            end

            for k,v in self.ChildrenNames do
                if v.ChildrenType then
                    local found = false
                    for cNum, cName in v.ChildrenType do
                        for num,name in removeTable do
                            if (cName == name) then
                                found = true
                                break
                            end
                        end
                        if found then
                            break
                        end
                    end

                    -- Remove the builder
                    if found then
                        for num,child in self.ChildrenHandles do
                            if child.ChildBuilder.BuilderName == v.BuilderName then
                                self.ChildrenHandles[num] = nil
                            end
                        end
                        self.ChildrenNames[k] = nil
                    end
               end
            end
        end,

        KeepChildren = function(self, childrenType)
            if not self:FindChildren() then
                return false
            end
            local keepTable = {}
            if type(childrenType) == 'table' then
                keepTable = childrenType
            else
                table.insert(keepTable, childrenType)
            end

            for k,v in self.ChildrenNames do
                if v.ChildrenType then
                    -- Child must have all children type to be kept
                    local found
                    for cNum, cName in v.ChildrenType do
                        found = false
                        for num,name in keepTable do
                            if (cName == name) then
                                found = true
                                break
                            end
                        end

                        -- This child was not found; break out so we can remove
                        if not found then
                            break
                        end
                    end

                    -- All keeptable children must be found to be kept as well.
                    if found then
                        for num,name in keepTable do
                            found = false
                            for cNun,cName in v.ChildrenType do
                                -- child name found; move to the next
                                if cName == name then
                                    found = true
                                    break
                                end
                            end

                            -- Child not found; break to remove
                            if not found then
                                break
                            end
                        end
                    end

                    -- Remove the builder
                    if not found then
                        self.AIBrain:PBMRemoveBuilder(v.BuilderName)
                        for num,child in self.ChildrenHandles do
                            if child.ChildBuilder.BuilderName == v.BuilderName then
                                self.ChildrenHandles[num] = nil
                            end
                        end
                        self.ChildrenNames[k] = nil
                    end
               end
            end
        end,

        OverrideTemplateSize = function(self, quantity)
            for k,v in self.ChildrenHandles do
                if type(quantity) == 'table' then
                    for sNum,sData in v.ChildBuilder.PlatoonTemplate do
                        if sNum >= 3 then
                            sData[2] = 1
                            sData[3] = quantity[sNum - 2] or 1
                        end
                    end
                else
                    local overrideNum = math.floor(quantity / (table.getn(v.ChildBuilder.PlatoonTemplate) - 2))
                    for sNum,sData in v.ChildBuilder.PlatoonTemplate do
                        if sNum >= 3 then
                            sData[2] = 1
                            sData[3] = overrideNum
                        end
                    end
                end
            end
        end,

        -- Build conditions for PBM; Attack Conditions for AM Platoons
        AddBuildCondition = function(self, fileName, funcName, parameters, bName)
            if not self:FindChildren() or not self:FindMaster() then
                return false
            end
            for k,v in self.ChildrenHandles do
                local found

                if bName and v.ChildBuilder.BuilderName then
                    found = string.find(bName, v.ChildBuilder.BuilderName .. '_', 1, true)
                end

                if not bName or bName == v.ChildBuilder.BuilderName or found then
                    table.insert(v.ChildBuilder.BuildConditions, { fileName, funcName, parameters })
                end
            end
            if not bName or bName == self.MasterName then
                table.insert(self.MasterData.AttackConditions, { fileName, funcName, parameters })
            end
            return true
        end,

        RemoveBuildCondition = function(self, funcName, bName)
            if not self:FindChildren() or not self:FindMaster() then
                return false
            end
            for k,v in self.ChildrenHandles do
                if not bName or bName == v.ChildBuilder.BuilderName then
                    for num,bc in v.ChildBuilder.BuildConditions do
                        if bc[2] == funcName then
                            v.ChildBuilder.BuildConditions[num] = nil
                        end
                    end
                end
            end
            if not bName or bName == self.MasterName then
                for num,ac in self.MasterData.AttackConditions do
                    if ac[2] == funcName then
                        self.MasterData.AttackConditions[num] = nil
                    end
                end
            end
            return true
        end,

        -- Add Functions for PBM Platoons; FormCallbacks for AM Platoons
        AddAddFunction = function(self, fileName, funcName, bName)
            if not self:FindChildren() or not self:FindMaster() then
                return false
            end
            for k,v in self.ChildrenHandles do
                if not bName or bName == v.ChildBuilder.BuilderName then
                    table.insert(v.ChildBuilder.PlatoonAddFunctions, { fileName, funcName })
                end
            end
            if not bName or bName == self.MasterName then
                if type(fileName) == 'function' then
                    table.insert(self.MasterData.FormCallbacks, fileName)
                else
                    table.insert(self.MasterData.FormCallbacks, { fileName, funcName })
                end
            end
            return true
        end,

        AddFormCallback = function(self,filename,funcName,bName)
            self:AddAddFunction(filename,funcName,self.MasterName)
        end,

        RemoveAddFunction = function(self, funcName, bName)
            if not self:FindChildren() or not self:FindMaster() then
                return false
            end
            for k,v in self.ChildrenHandles do
                if not bName or bName == v.ChildBuilder.BuilderName then
                    for num,bc in v.ChildBuilder.PlatoonAddFunctions do
                        if bc[2] == funcName then
                            v.ChildBuilder.PlatoonAddFunctions[num] = nil
                        end
                    end
                end
            end
            if not bName or bName == self.MasterName then
                for num,ac in self.MasterData.FormCallbacks do
                    if ac[2] == funcName then
                        self.MasterData.FormCallbacks[num] = nil
                    end
                end
            end
            return true
        end,

        RemoveFormCallback = function(self,filename,funcName,bName)
            self:RemoveAddFunction(filename,funcName,bName)
        end,

        -- Add Build Callback for PBM Platoons; Death Callback for AM Platoons
        AddBuildCallback = function(self, fileName, funcName, bName)
            if not self:FindChildren() or not self:FindMaster() then
                return false
            end
            for k,v in self.ChildrenHandles do
                if not bName or bName == v.ChildBuilder.BuilderName then
                    table.insert(v.ChildBuilder.PlatoonBuildCallbacks, { fileName, funcName })
                end
            end
            if not bName or bName == self.MasterName then
                table.insert(self.MasterData.DestroyCallbacks, { fileName, funcName })
            end
            return true
        end,

        AddDestroyCallback = function(self,fileName,funcName,bName)
            self:AddBuildCallback(fileName,funcName,bName)
        end,

        RemoveBuildCallback = function(self, funcName, bName)
            if not self:FindChildren() or not self:FindMaster() then
                return false
            end
            for k,v in self.ChildrenHandles do
                if not bName or bName == v.ChildBuilder.BuilderName then
                    for num,bc in v.ChildBuilder.PlatoonBuildCallbacks do
                        if bc[2] == funcName then
                            v.ChildBuilder.PlatoonBuildCallbacks[num] = nil
                        end
                    end
                end
            end
            if not bName or bName == self.MasterName then
                for num,ac in self.MasterData.FormCallbacks do
                    if ac[2] == funcName then
                        self.MasterData.FormCallbacks[num] = nil
                    end
                end
            end
            return true
        end,

        RemoveDestroyCallback = function(self,fileName,funcName,bName)
            self:RemoveBuildCallback(fileName,funcName,bName)
        end,

        MasterUsePool = function(self, val)
            if not self:FindMaster() then
                return false
            end
            self.MasterData.UsePool = val
            return true
        end,

        SetLockingStyle = function(self,lockType, lockData)
            if not(lockType == 'None' or lockType == 'DeathTimer' or lockType == 'BuildTimer' or lockType == 'DeathRatio' or lockType == 'RatioTimer') then
                error('*AI ERROR: Error adding lock style: valid types are "DeathTimer", "BuildTimer", "DeathRatio", or "None"', 2)
            end
            self:RemoveBuildCondition('AMCheckPlatoonLock')
            if lockType ~= 'None' then
                self:AddBuildCondition('/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock', {self.MasterName})
                self:RemoveDestroyCallback('AMUnlockPlatoon', self.MasterName)
                self:RemoveFormCallback('AMUnlockBuildTimer', self.MasterName)
                self:RemoveFormCallback('AMUnlockRatio', self.MasterName)
                if lockType == 'DeathTimer' then
                    if not lockData or not lockData.LockTimer then
                        error('*AI DEBUG: Death Timers require the data LockTimer', 2)
                    end
                    self:AddDestroyCallback('/lua/editor/amplatoonhelperfunctions.lua', 'AMUnlockPlatoon', self.MasterName)
                    self.MasterData.PlatoonData.LockTimer = lockData.LockTimer
                elseif lockType == 'BuildTimer' then
                    if not lockData or not lockData.LockTimer then
                        error('*AI DEBUG: Build Timers require the data LockTimer', 2)
                    end
                    self:AddFormCallback(BMPT, 'AMUnlockBuildTimer', self.MasterName)
                    self.MasterData.PlatoonData.LockTimer = lockData.LockTimer
                elseif lockType == 'DeathRatio' then
                    if not lockData or not lockData.Ratio then
                        error('*AI DEBUG: Death Ratio unlocking requires the data Ratio', 2)
                    end
                    self:AddFormCallback(BMPT, 'AMUnlockRatio', self.MasterName)
                    self.MasterData.PlatoonData.Ratio = lockData.Ratio
                elseif lockType == 'RatioTimer' then
                    if not lockData or not lockData.Ratio or not lockData.LockTimer then
                        error('*AI DEBUG: RatioTimer unlocking requires the data "Ratio" and "LockTimer"',2)
                    end
                    self:AddFormCallback(BMPT, 'AMUnlockRatioTimer', self.MasterName)
                    self.MasterData.PlatoonData.LockTimer = lockData.LockTimer
                    self.MasterData.PlatoonData.Ratio = lockData.Ratio
                end
            end
        end,

        SetChildrenActive = function(self, childrenTypes)
            if not self:FindChildren() then
                return false
            end

            for k,v in childrenTypes do
                self:SetChildActive(v, true)
            end
        end,

        SetChildActive = function(self,cType,val)
            if not self:FindChildren() then
                return false
            end

            -- check against self.EnabledTypes

            if cType ~= 'All' then
                self.EnabledTypes[cType] = val
            else
                for k,v in self.EnabledTypes do
                    self.EnabledTypes[k] = val
                end
            end

            -- Loop through children
            for k,v in self.ChildrenNames do
                -- Make sure this child has children types
                if v.ChildrenType then

                    -- We don't want to change by default
                    local change = false
                    -- if the type is 'All' or we find that this builder has this child type, we may want to change
                    for cNum, cName in v.ChildrenType do
                        if (cName == cType) or (cType == 'All') then
                            change = true
                        end
                    end

                    -- Need to change the children here
                    if change then
                        -- make sure that this builder's enabled types are all active
                        local changeVal = true
                        for cNum,cName in v.ChildrenType do
                            -- This child type is not enabled, we'll want to disable this child type
                            if not self.EnabledTypes[cName] then
                                changeVal = false
                                break
                            end
                        end
                        if changeVal then
                            if not self:AddBuildCondition(MIBC, 'True', {}, v.BuilderName) or
                                not self:RemoveBuildCondition('False', v.BuilderName) then
                                error('*AI ERROR: Error Adding build condition',2)
                            end
                        else
                            if not self:AddBuildCondition(MIBC, 'False', {}, v.BuilderName) or
                                not self:RemoveBuildCondition('True', v.BuilderName) then
                                error('*AI ERROR: Error Adding build condition',2)
                            end
                        end
                    end
               end
            end
        end,

        Create = function(self, brain, location, builderType, name, builderData)
            if not self.PreCreateFinished then
                self:PreCreate()
            end
            -- local tables to this class instance
            self.ChildMonitorData = {}
            self.ChildrenNames = {}
            self.EnabledTypes = {}

            -- Store off local instances of some variables
            self.AIBrain = brain
            self.LocationType = location
            self.BuilderType = builderType
            if type(self.BuilderType) == 'string' then
                self.GlobalVarName = name .. '_' .. self.BuilderType
            else
                self.GlobalVarName = name .. '_' .. self.BuilderType.Name
            end

            -- Load all the platoon data info in the formation desired
            local platoonData = {}
            if not builderData then
                platoonData.Priority = 0
                platoonData.PlatoonData = {}
            else
                -- Set PlatoonData
                if builderData.PlatoonData then
                    platoonData.PlatoonData = builderData.PlatoonData
                else
                    platoonData.PlatoonData = {}
                end
                -- Set priority
                if builderData.Priority then
                    platoonData.Priority = builderData.Priority
                else
                    platoonData.Priority = 0
                end
            end
            platoonData.LocationType = location

            local builders = false
            local saveFile

            if type(self.BuilderType) == "string" then --BuilderType is old-school
                ScenarioUtils.LoadOSB('OSB_' .. self.BuilderType .. '_' .. name, brain.Name, platoonData)

                local fileName = '/lua/ai/OpAI/' .. self.BuilderType .. '_save.lua'
                saveFile = import(fileName)

                builders = saveFile.Scenario.Armies['ARMY_1'].PlatoonBuilders.Builders
                self.MasterName = 'OSB_Master_' .. self.BuilderType .. '_' .. brain.Name .. '_' .. name
            else --If BuilderType is a table (was pregenerated)

                ScenarioUtils.LoadOSB(builderType, brain.Name, platoonData)
                saveFile = {Scenario = builderType}

                --self.MasterName = 'OSB_Master_' .. saveFile.Scenario.Name .. '_' .. brain.Name .. '_' .. name
                self.MasterName = 'OSB_Master_' .. saveFile.Scenario.Name .. '_' .. brain.Name
            end

            builders = saveFile.Scenario.Armies['ARMY_1'].PlatoonBuilders.Builders

            if not builders then
                error('*OpAI ERROR: No OpAI Global named: '..self.BuilderType, 2)
            end
            for k,v in builders do
                local startCheck = false
                if string.sub(k, 1, 10) == 'OSB_Child_' then
                    startCheck = 11
                end
                if startCheck then
                    if type(self.BuilderType) == "string" then
                        startCheck = startCheck + 1 + string.len(self.BuilderType)
                    else
                        startCheck = startCheck + 1 + string.len(self.BuilderType.Name)
                    end
                    local cType = string.sub(k,startCheck)

                    table.insert(self.ChildrenNames, { BuilderName = k..'_'..brain.Name..'_'..name, ChildrenType = v.ChildrenType })
                    self:AddChildType(v.ChildrenType)
                end
            end
            if builderData.MasterPlatoonFunction then
                if self:FindMaster() then
                    self.MasterData.AIThread = builderData.MasterPlatoonFunction
                    self:MasterPlatoonFunctionalityChange(builderData.MasterPlatoonFunction)
                end
            end

            self:AddBuildCondition(BMBC, 'BaseActive', { location })
        end,
    }

function CreateOpAI(brain, location, builderType, name, builderData)
    local opAI = OpAI()
    brain:PBMEnableRandomSamePriority()
    opAI:Create(brain, location, builderType, name, builderData)
    return opAI
end
