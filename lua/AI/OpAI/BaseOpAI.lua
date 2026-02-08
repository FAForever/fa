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

---@alias OpAIChildType
---| "Bombers"              # T1 Bombers
---| "Interceptors"         # T1 Interceptors
---| "LightGunships"        # T1 Gunships
---| "CombatFighters"       # T2 Fighters/bombers
---| "TorpedoBombers"       # T2 Torpedo bombers
---| "Gunships"             # T2 Gunships
---| "GuidedMissiles"       # T2 Mercy
---| "AirSuperiority"       # T3 ASF
---| "StratBombers"         # T3 Bombers
---| "HeavyGunships"        # T3 Gunships
---| "HeavyTorpedoBombers"  # T3 Torpedo bombers
---| "T1Transports"
---| "T2Transports"
---| "T3Transports"
---| "LightBots"            # T1 LABs
---| "LightTanks"           # T1 Tanks
---| "LightArtillery"       # T1 Arty
---| "MobileAntiAir"        # T1 MAA
---| "HeavyTanks"           # T2 Tanks
---| "AmphibiousTanks"      # T2 Amphibious tanks
---| "MobileShields"        # T2/T3 Mobile shield
---| "MobileStealth"        # T2 Stealth field
---| "MobileMissiles"       # T2 MML
---| "MobileFlak"           # T2 MAA
---| "MobileBombs"          # T2 Cybran bombs
---| "SiegeBots"            # T3 Harb, Loyalist, Titan, Othuum
---| "HeavyBots"            # T3 Percy, Brick, Sniper bots, T1 Mantis
---| "MobileHeavyArtillery" # T3 Arty
---| "HeavyMobileAntiAir"   # T3 MAA
---| "CombatEngineers"      # T2 Sparky
---| "T1Engineers"
---| "T2Engineers"
---| "T3Engineers"
---| "Frigates"
---| "Submarines"           # T1 Submarines
---| "Destroyers"
---| "Cruisers"
---| "Battleships"
---| "T2Submarines"         # T2 Submarines
---| "UtilityBoats"         # T2 Shield, Stealth boats
---| "Carriers"
---| "NukeSubmarines"       # T3 Nuke subs
---| "AABoats"              # T1 AA boat
---| "MissileShips"         # T3 Missile ship
---| "T3Submarines"         # T3 Sera submarine
---| "TorpedoBoats"         # T2 UEF Torpedo boat
---| "BattleCruisers"
---| "All"

---@alias OpAILockType
---| "None"       # Platoon can be rebuilt right away, no limit on number of active ones
---| "DeathTimer" # The set time needs to pass after the platoon is killed before it can be rebuild.
---| "BuildTimer" # The set time needs to pass after the platoon is built before it can be build again.
---| "DeathRatio" # Ratio of units in this platoon that will trigger rebuilding. 0.6 = rebuild when platoon's alive units < 60%.
---| "RatioTimer" # Combination of `DeathTimer` and `DeathRatio`

---@class OpAILockData
---@field Ratio number|nil Dead units ratio of the platoon that will trigger rebuild
---@field LockTimer integer|nil The platoon can be rebuild after this amount of seconds

---@class OpAIChildrenName
---@field BuilderName string
---@field ChildrenType OpAIChildType[]

---@class OpAIChildHandle
---@field ChildName string
---@field ChildBuilder table

---@class OpAI
---@field Trash TrashBag
---@field AIBrain CampaignAIBrain
---@field LocationType string Name of the base this AI belongs to
---@field MasterName string
---@field GlobalVarName string `name`_`BuilderType`
---@field BuilderType SaveFile | string Save file that is used to find child quantities
---@field MasterData table
---@field ChildrenHandles OpAIChildHandle[]
---@field ChildMonitorHandle any
---@field ChildMonitorData table
---@field ChildrenNames OpAIChildrenName[]
---@field EnabledTypes table<OpAIChildType, boolean>
---@field PreCreateFinished boolean
---@overload fun(): OpAI
OpAI = ClassSimple {
    ---Set up variables local to this OpAI instance
    ---@param self OpAI
    PreCreate = function(self)
        if self.PreCreateFinished then return end

        self.Trash = TrashBag()

        self.PreCreateFinished = true
    end,

    ---@param self OpAI
    ---@param force? boolean
    ---@return boolean
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

    ---@param self OpAI
    ---@param force? boolean
    ---@return boolean
    FindChildren = function(self, force)
        if self.ChildrenHandles and not table.empty(self.ChildrenHandles) and not force then
            return true
        end
        self.ChildrenHandles = {}
        local types = { 'Air', 'Land', 'Sea' }
        for _, currType in types do
            for name,builder in ScenarioInfo.BuilderTable[self.AIBrain.CurrentPlan][currType] do
                if self:ChildNameCheck(name) then
                    table.insert(self.ChildrenHandles, { ChildName=name, ChildBuilder=builder })
                end
            end
        end
        return true
    end,

    ---@param self OpAI
    ---@param typeTable OpAIChildType[]
    AddChildType = function(self,typeTable)
        if typeTable then
            for _, tName in typeTable do
                if self.EnabledTypes[tName] == nil then
                    self.EnabledTypes[tName] = true
                end
            end
        end
    end,

    ---@param self OpAI
    ---@param name string
    ---@return boolean
    ChildNameCheck = function(self,name)
        for _, v in self.ChildrenNames do
            local found = string.find(v.BuilderName, name .. '_', 1, true)
            if v.BuilderName == name or found then
                return true
            end
        end
        return false
    end,

    ---@param self OpAI
    ---@param number integer
    ---@param childType? any
    SetChildCount = function(self, number, childType)
        if not childType then
            ScenarioInfo.OSPlatoonCounter[self.MasterName..'_D'..ScenarioInfo.Options.Difficulty] = number
        else
            ScenarioInfo.OSPlatoonCounter[self.MasterName..'_'..childType..'_D'..ScenarioInfo.Options.Difficulty] = number
        end
    end,

    ---@param self OpAI
    ---@param diffTable integer[]
    SetChildCountDiffTable = function(self, diffTable)
        ScenarioInfo.OSPlatoonCounter[self.MasterName..'_D1'] = diffTable[1]
        ScenarioInfo.OSPlatoonCounter[self.MasterName..'_D2'] = diffTable[2]
        ScenarioInfo.OSPlatoonCounter[self.MasterName..'_D3'] = diffTable[3]
    end,

    ---@param self OpAI
    ---@param functionInfo any
    ---@param childType any
    SetChildrenPlatoonAI = function(self, functionInfo, childType)
        if not self:FindChildren() then
            error('*AI DEBUG: No children for OpAI found')
        end
        for k,v in self.ChildrenHandles do
            v.ChildBuilder.PlatoonAIFunction = functionInfo
        end
    end,

    ---Overrides the default platoon formation
    ---@param self OpAI
    ---@param formationName UnitFormations
    SetFormation = function(self, formationName)
        if not self:FindMaster() then
            return
        end
        self.MasterData.PlatoonData.OverrideFormation = formationName
    end,

    ---@param self OpAI
    ---@param funcName string
    ---@param bool boolean
    SetFunctionStatus = function(self, funcName, bool)
        ScenarioInfo.OSPlatoonCounter[self.MasterName..'_' .. funcName] = bool
    end,

    ---TODO: make a system out of this.  Derive functionality per override per OpAI type
    ---@param self OpAI
    ---@param functionData any
    MasterPlatoonFunctionalityChange = function(self, functionData)
        if functionData[2] == 'LandAssaultWithTransports' then
            self:SetFunctionStatus('Transports', true)
        end
    end,

    ---@param self OpAI
    ---@param cat any
    ---@return boolean
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

    ---@param self OpAI
    ---@param cat any
    ---@return boolean
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

    ---categories is an optional parameter specifying a subset of the platoon we wish to set target priorities for.
    ---@param self OpAI
    ---@param priTable string[]
    ---@param categories? EntityCategory
    ---@return boolean
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

    ---@param self OpAI
    ---@param childrenData any
    ---```childData = {
    ---    { 'LightTanks', 'LightBots' },
    ---    {
    ---        Function or function table,
    ---        Function or function table,
    ---        Function or function table,
    ---    },
    ---}
    AddChildrenMonitor = function(self, childrenData)
        for k,v in childrenData do
            self:AddChildMonitor(v)
        end
    end,

    ---@param self OpAI
    ---@param childData any
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

    ---@param self OpAI
    ChildMonitorThread = function(self)
        while true do
            -- Iterate through list enabling/disabling children types as needed.
            for name,data in self.ChildMonitorData do
                self:ChildMonitorCheck(name, data)
            end
            WaitSeconds(7)
        end
    end,

    ---@param self OpAI
    ---@param childName any
    ---@param childData any
    ChildMonitorCheck = function(self, childName, childData)
        for k,v in childData do
            if v.DirectFunction and not v.DirectFunction() then
                self:SetChildActive(childName, false)
                return
            elseif v.FunctionInfo then
                if v.FunctionInfo[3][1] == "default_brain" then
                    table.remove(v.FunctionInfo[3], 1)
                end
                if not import(v.FunctionInfo[1])[v.FunctionInfo[2]](self.AIBrain, unpack(v.FunctionInfo[3])) then
                    self:SetChildActive(childName, false)
                    return
                end
            end
        end
        self:SetChildActive(childName, true)
    end,

    ---@param self OpAI
    ---@param childrenType OpAIChildType[]|OpAIChildType
    ---@param quantity integer|integer[]
    SetChildQuantity = function(self, childrenType, quantity)
        if not self:FindChildren() or not self:FindMaster() then
            return
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

    ---@param self OpAI
    ---@param childrenType any
    RemoveChildren = function(self, childrenType)
        if not self:FindChildren() then
            return
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

    ---@param self OpAI
    ---@param childrenType OpAIChildType[]|OpAIChildType
    KeepChildren = function(self, childrenType)
        if not self:FindChildren() then
            return
        end
        local keepTable = {}
        if type(childrenType) == 'table' then
            keepTable = childrenType
        else
            table.insert(keepTable, childrenType)
        end

        for k, v in self.ChildrenNames do
            if v.ChildrenType then
                -- Child must have all children type to be kept
                local found
                for _, cName in v.ChildrenType do
                    found = false
                    for _, name in keepTable do
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
                    for _, name in keepTable do
                        found = false
                        for _, cName in v.ChildrenType do
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

    ---@param self OpAI
    ---@param quantity integer|integer[]
    OverrideTemplateSize = function(self, quantity)
        for _, v in self.ChildrenHandles do
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

    ---Build conditions for PBM; Attack Conditions for AM Platoons
    ---@param self OpAI
    ---@param fileName FileName
    ---@param funcName string
    ---@param parameters table Array with parameters that will be passed to the build condition function
    ---@param bName? string
    ---@return boolean
    AddBuildCondition = function(self, fileName, funcName, parameters, bName)
        if not self:FindChildren() or not self:FindMaster() then
            return false
        end
        for _, v in self.ChildrenHandles do
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

    ---@param self OpAI
    ---@param funcName string
    ---@param bName? string
    ---@return boolean
    RemoveBuildCondition = function(self, funcName, bName)
        if not self:FindChildren() or not self:FindMaster() then
            return false
        end
        for _, v in self.ChildrenHandles do
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

    ---Add Functions for PBM Platoons; FormCallbacks for AM Platoons
    ---@param self OpAI
    ---@param fileName FileName|function
    ---@param funcName? string
    ---@param bName? string
    ---@return boolean
    AddAddFunction = function(self, fileName, funcName, bName)
        if not self:FindChildren() or not self:FindMaster() then
            return false
        end
        for _, v in self.ChildrenHandles do
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

    ---Adds a function to run when the platoon is formed.
    ---@param self OpAI
    ---@param filename any
    ---@param funcName string
    ---@param builderName? string
    AddFormCallback = function(self, filename, funcName, builderName)
        builderName = builderName or self.MasterName
        self:AddAddFunction(filename, funcName, builderName)
    end,

    ---Remove Functions for PBM Platoons; FormCallbacks for AM Platoons
    ---@param self OpAI
    ---@param funcName string
    ---@param builderName? string
    ---@return boolean
    RemoveAddFunction = function(self, funcName, builderName)
        if not self:FindChildren() or not self:FindMaster() then
            return false
        end
        for k,v in self.ChildrenHandles do
            if not builderName or builderName == v.ChildBuilder.BuilderName then
                for num,bc in v.ChildBuilder.PlatoonAddFunctions do
                    if bc[2] == funcName then
                        v.ChildBuilder.PlatoonAddFunctions[num] = nil
                    end
                end
            end
        end
        if not builderName or builderName == self.MasterName then
            for num,ac in self.MasterData.FormCallbacks do
                if ac[2] == funcName then
                    self.MasterData.FormCallbacks[num] = nil
                end
            end
        end
        return true
    end,

    ---@param self OpAI
    ---@param funcName string
    ---@param builderName? string
    RemoveFormCallback = function(self, funcName, builderName)
        self:RemoveAddFunction(funcName, builderName)
    end,

    ---Add Build Callback for PBM Platoons; Death Callback for AM Platoons
    ---@param self OpAI
    ---@param fileName FileName
    ---@param funcName string
    ---@param builderName? string
    ---@return boolean
    AddBuildCallback = function(self, fileName, funcName, builderName)
        if not self:FindChildren() or not self:FindMaster() then
            return false
        end
        for k,v in self.ChildrenHandles do
            if not builderName or builderName == v.ChildBuilder.BuilderName then
                table.insert(v.ChildBuilder.PlatoonBuildCallbacks, { fileName, funcName })
            end
        end
        if not builderName or builderName == self.MasterName then
            table.insert(self.MasterData.DestroyCallbacks, { fileName, funcName })
        end
        return true
    end,

    ---@param self OpAI
    ---@param fileName FileName
    ---@param funcName string
    ---@param builderName? string
    AddDestroyCallback = function(self, fileName, funcName, builderName)
        self:AddBuildCallback(fileName, funcName, builderName)
    end,

    ---@param self OpAI
    ---@param funcName string
    ---@param builderName? string
    ---@return boolean
    RemoveBuildCallback = function(self, funcName, builderName)
        if not self:FindChildren() or not self:FindMaster() then
            return false
        end
        for k,v in self.ChildrenHandles do
            if not builderName or builderName == v.ChildBuilder.BuilderName then
                for num,bc in v.ChildBuilder.PlatoonBuildCallbacks do
                    if bc[2] == funcName then
                        v.ChildBuilder.PlatoonBuildCallbacks[num] = nil
                    end
                end
            end
        end
        if not builderName or builderName == self.MasterName then
            for num,ac in self.MasterData.FormCallbacks do
                if ac[2] == funcName then
                    self.MasterData.FormCallbacks[num] = nil
                end
            end
        end
        return true
    end,

    ---@param self OpAI
    ---@param funcName string
    ---@param builderName? string
    RemoveDestroyCallback = function(self, funcName, builderName)
        self:RemoveBuildCallback(funcName, builderName)
    end,

    ---@param self OpAI
    ---@param val boolean
    ---@return boolean
    MasterUsePool = function(self, val)
        if not self:FindMaster() then
            return false
        end
        self.MasterData.UsePool = val
        return true
    end,

    ---Changed the default (once all units die) rebuild logic for this AI
    ---@param self OpAI
    ---@param lockType OpAILockType
    ---@param lockData? OpAILockData
    SetLockingStyle = function(self, lockType, lockData)
        if not(lockType == 'None' or lockType == 'DeathTimer' or lockType == 'BuildTimer' or lockType == 'DeathRatio' or lockType == 'RatioTimer') then
            error('*AI ERROR: Error adding lock style: valid types are "DeathTimer", "BuildTimer", "DeathRatio", "RatioTimer", or "None"', 2)
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

    ---@param self OpAI
    ---@param childrenTypes OpAIChildType[]
    SetChildrenActive = function(self, childrenTypes)
        if not self:FindChildren() then
            return
        end

        for _, v in childrenTypes do
            self:SetChildActive(v, true)
        end
    end,

    ---@param self OpAI
    ---@param cType OpAIChildType
    ---@param val boolean
    SetChildActive = function(self, cType, val)
        if not self:FindChildren() then
            return
        end

        -- check against self.EnabledTypes

        if cType ~= 'All' then
            self.EnabledTypes[cType] = val
        else
            for k, _ in self.EnabledTypes do
                self.EnabledTypes[k] = val
            end
        end

        -- Loop through children
        for _, v in self.ChildrenNames do
            -- Make sure this child has children types
            if not v.ChildrenType then continue end

            -- We don't want to change by default
            local change = false
            -- if the type is 'All' or we find that this builder has this child type, we may want to change
            for _, cName in v.ChildrenType do
                if (cName == cType) or (cType == 'All') then
                    change = true
                    break
                end
            end

            -- Need to change the children here
            if not change then continue end

            -- make sure that this builder's enabled types are all active
            local changeVal = true
            for _, cName in v.ChildrenType do
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
    end,

    ---@param self OpAI
    ---@param brain CampaignAIBrain
    ---@param location string Name of the base
    ---@param builderType SaveFile | string Save file that is used to find child quantities
    ---@param name string A name set by you to allow you to retrieve the returned AI instance
    ---@param builderData AddOpAIData?
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
            if string.sub(k, 1, 10) == 'OSB_Child_' then
                local startCheck = 11
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
        if builderData and builderData.MasterPlatoonFunction then
            if self:FindMaster() then
                self.MasterData.AIThread = builderData.MasterPlatoonFunction
                self:MasterPlatoonFunctionalityChange(builderData.MasterPlatoonFunction)
            end
        end

        self:AddBuildCondition(BMBC, 'BaseActive', { location })
    end,
}
---@param brain CampaignAIBrain
---@param location string
---@param builderType SaveFile | string
---@param name string
---@param builderData AddOpAIData?
---@return OpAI
function CreateOpAI(brain, location, builderType, name, builderData)
    local opAI = OpAI()
    brain:PBMEnableRandomSamePriority()
    opAI:Create(brain, location, builderType, name, builderData)
    return opAI
end
