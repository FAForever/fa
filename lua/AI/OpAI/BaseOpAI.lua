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

local pairs, ipairs = pairs, ipairs
local type, unpack = type, unpack
local mathFloor = math.floor
local stringFind = string.find
local stringLen = string.len
local stringSub = string.sub
local tableInsert = table.insert
local tableRemove = table.remove
local tableEmpty = table.empty
local tableGetn = table.getn

-- Used by the build conditions that dont need any args
local emptyTable = {}
local platoonTypes = {'Air', 'Land', 'Sea'}
local targetCommanderLastPriorities = {
    categories.EXPERIMENTAL,
    categories.STRUCTURE * categories.DEFENSE,
    categories.STRUCTURE * categories.ECONOMIC,
    categories.MOBILE - categories.COMMAND,
    categories.ALLUNITS - categories.COMMAND,
    categories.COMMAND,
}
local targetCommanderNeverPriorities = {
    categories.EXPERIMENTAL,
    categories.STRUCTURE * categories.DEFENSE,
    categories.STRUCTURE * categories.ECONOMIC,
    categories.MOBILE - categories.COMMAND,
    categories.ALLUNITS - categories.COMMAND,
}
local defTargetPriorities = {'COMMAND', 'MOBILE', 'STRUCTURE DEFENSE', 'ALLUNITS'}

---Platoon template file with pre-generated platoon templates and builders
---@alias OpAIPlatoonTpFile
---| "AirAttacks"
---| "AirScout"
---| "BasicLandAttack"
---| "BomberEscort"
---| "HeavyLandAttack"
---| "LandAssualt"
---| "LeftoverCleanup"
---| "LightAirAttack"
---| "NavalAttacks"
---| "NavalFleet"

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
---| "RangeBots"            # T2 Cybran/UEF bots
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
---| "T1"                   # T1 ships in NavalOpAI from generated templates 
---| "T2"                   # T2 ships in NavalOpAI from generated templates 
---| "T3"                   # T3 ships in NavalOpAI from generated templates 
---| "All"

---@alias OpAILockType
---| "None"       # Platoon can be rebuilt right away, no limit on number of active ones
---| "DeathTimer" # The set time needs to pass after the platoon is killed before it can be rebuild.
---| "BuildTimer" # The set time needs to pass after the platoon is built before it can be build again.
---| "DeathRatio" # Ratio of units in this platoon that will trigger rebuilding. 0.6 = rebuild when platoon's alive units < 60%.
---| "RatioTimer" # Combination of `DeathTimer` and `DeathRatio`

---@class OpAILockData
---@field Ratio? number Dead units ratio of the platoon that will trigger rebuild
---@field LockTimer? integer The platoon can be rebuild after this amount of seconds

---@class OpAIChildrenName
---@field BuilderName string
---@field ChildrenType OpAIChildType[]

---@class OpAIChildHandle
---@field ChildName string Builder name
---@field ChildBuilder PBMPlatoonBuilder

---@class ChildMonitorFnData: FileFunctionRef
---@field [3] table

---@class OpAINewChildMonitorData
---@field DirectFunction? fun(): boolean Return `false` to disable the child
---@field FunctionInfo? ChildMonitorFnData `fun(aiBrain, ...): boolean` Return `false` to disable the child

---@class OpAI
---@field Trash TrashBag
---@field AIBrain CampaignAIBrain
---@field LocationType string Name of the base this AI belongs to
---@field MasterName string
---@field GlobalVarName string `name`_`BuilderType`
---@field BuilderType OpAIPlatoonTpFile | GeneratedScenario Save file that is used to find child quantities
---@field MasterData AMBuilder
---@field ChildrenHandles OpAIChildHandle[]
---Periodically runs functions in `OpAI.ChildMonitorData` to toggle children
---
---Childrens are enabled by default, unless one of the functions return `false`
---@field ChildMonitorHandle? thread
---@field ChildMonitorData? table<OpAIChildType, OpAINewChildMonitorData[]>
---@field ChildrenNames OpAIChildrenName[]
---@field EnabledTypes table<OpAIChildType, boolean> ChildType is enabled by default when added.
---@field private PreCreateFinished boolean
---@overload fun(): OpAI
local BaseOpAI = {}
---Set up variables local to this OpAI instance
---@private
function BaseOpAI:PreCreate()
    if self.PreCreateFinished then return end

    self.Trash = TrashBag()
    self.PreCreateFinished = true
end
---@private
---@param force? boolean
---@return boolean
function BaseOpAI:FindMaster(force)
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
end
---@private
---@param force? boolean
---@return boolean
function BaseOpAI:FindChildren(force)
    if self.ChildrenHandles and not tableEmpty(self.ChildrenHandles) and not force then
        return true
    end
    self.ChildrenHandles = {}
    local builderTable = ScenarioInfo.BuilderTable[self.AIBrain.CurrentPlan]
    for _, currType in platoonTypes do
        for name,builder in builderTable[currType] do
            if self:ChildNameCheck(name) then
                tableInsert(self.ChildrenHandles, { ChildName=name, ChildBuilder=builder })
            end
        end
    end
    return true
end
---@private
---@param typeTable OpAIChildType[]
function BaseOpAI:AddChildType(typeTable)
    if not typeTable then return end

    for _, tName in typeTable do
        if self.EnabledTypes[tName] == nil then
            self.EnabledTypes[tName] = true
        end
    end
end
---@private
---@param name string
---@return boolean
function BaseOpAI:ChildNameCheck(name)
    local searchFor = name .. '_'
    for _, v in self.ChildrenNames do
        local found = stringFind(v.BuilderName, searchFor, 1, true)
        if v.BuilderName == name or found then
            return true
        end
    end
    return false
end
---Sets the number of child platoons to build.
---
---Once the desired amount it reached, they are combined into a master platoon.
---@param number integer
---@param childType? any
function BaseOpAI:SetChildCount(number, childType)
    if not childType then
        ScenarioInfo.OSPlatoonCounter[self.MasterName..'_D'..ScenarioInfo.Options.Difficulty] = number
    else
        ScenarioInfo.OSPlatoonCounter[self.MasterName..'_'..childType..'_D'..ScenarioInfo.Options.Difficulty] = number
    end
end
---Sets the number of child platoons to build.
---
---Once the desired amount it reached, they are combined into a master platoon.
---@param diffTable {[1]: integer, [2]: integer, [3]: integer} count to set for Easy, Medium, Hard difficulty
function BaseOpAI:SetChildCountDiffTable(diffTable)
    local platoonCounter = ScenarioInfo.OSPlatoonCounter
    platoonCounter[self.MasterName..'_D1'] = diffTable[1]
    platoonCounter[self.MasterName..'_D2'] = diffTable[2]
    platoonCounter[self.MasterName..'_D3'] = diffTable[3]
end
---Changes the children platoons' AI function
---@param functionInfo FileFunctionRef
---@param childType any Unused
function BaseOpAI:SetChildrenPlatoonAI(functionInfo, childType)
    if not self:FindChildren() then
        error('*AI DEBUG: No children for OpAI found')
    end
    for k,v in self.ChildrenHandles do
        v.ChildBuilder.PlatoonAIFunction = functionInfo
    end
end
---Overrides the default platoon formation
---@param formationName UnitFormations
function BaseOpAI:SetFormation(formationName)
    if not self:FindMaster() then return end
    self.MasterData.PlatoonData.OverrideFormation = formationName
end
---@private
---@param funcName string
---@param bool boolean
function BaseOpAI:SetFunctionStatus(funcName, bool)
    ScenarioInfo.OSPlatoonCounter[self.MasterName..'_' .. funcName] = bool
end
---TODO: make a system out of this.  Derive functionality per override per OpAI type
---@private
---@param functionData any
function BaseOpAI:MasterPlatoonFunctionalityChange(functionData)
    if functionData[2] == 'LandAssaultWithTransports' then
        self:SetFunctionStatus('Transports', true)
    end
end
---Sets the the whole platoon or only units matching categories to target commanders after all other units.
---@param cat? EntityCategory Specifies a subset of the platoon to set target priorities for
---@return boolean
function BaseOpAI:TargetCommanderLast(cat)
    return self:SetTargettingPriorities(targetCommanderLastPriorities, cat)
end
---Sets the the whole platoon or only units matching categories to not target commanders.
---@param cat? EntityCategory Specifies a subset of the platoon to set target priorities for
---@return boolean
function BaseOpAI:TargetCommanderNever(cat)
    return self:SetTargettingPriorities(targetCommanderNeverPriorities, cat)
end
---Sets the target priorities for the whole platoon or only units matching categories
---@param priTable string[]|EntityCategory[]
---@param cat? EntityCategory specifying a subset of the platoon we wish to set target priorities for
---@return boolean
function BaseOpAI:SetTargettingPriorities(priTable, cat)
    if not self:FindMaster() then return false end

    local priList = { unpack(priTable) }

    if cat then
        --save the priorities for this category.
        if not self.MasterData.PlatoonData.CategoryPriorities then self.MasterData.PlatoonData.CategoryPriorities = {} end

        --NOTE: This should probably be a table.deepcopy if we're going to alter the original table in the future.
        self.MasterData.PlatoonData.CategoryPriorities[cat] = priList
    else
        for _, v in ipairs(defTargetPriorities) do
            tableInsert(priList, v)
        end

        local priorities = {}
        for _, v in ipairs(priList) do
            tableInsert(priorities, v)
        end

        self.MasterData.PlatoonData.TargetPriorities = priorities
    end

    tableInsert(self.MasterData.PlatoonAddFunctions, {BMPT, 'PlatoonSetTargetPriorities'})

    return true
end

---@class OpAINewChildMonitorData
---@field [1] OpAIChildType[]
---@field [2] (ChildMonitorFnData|fun(): boolean)[]

---@param childrenData OpAINewChildMonitorData[]
---```
---childData = {
---    { 'LightTanks', 'LightBots' },
---    {
---        Function or function table,
---        Function or function table,
---        Function or function table,
---    },
---}
function BaseOpAI:AddChildrenMonitor(childrenData)
    for _, v in childrenData do
        self:AddChildMonitor(v)
    end
end

---Adds a function that will be run periodically to toggle the child.
---
---The child stays enabled, unless the function returns `false`.
---@param childData OpAINewChildMonitorData[]
function BaseOpAI:AddChildMonitor(childData)
    -- add children and functions to the child table in self
    -- ChildMonitorData
    ---@type OpAIChildType[]
    local children = childData[1]
    ---@type (fun(): boolean | ChildMonitorFnData)[]
    local functions = childData[2]
    for _, childName in children do
        if self.EnabledTypes[childName] == nil then
            error('*AI DEBUG: Invalid child type - ' .. childName .. ' - in OpAI type - ' .. self.BuilderType, 2)
        end

        local monitorData = self.ChildMonitorData[childName]
        if not monitorData then
            monitorData = {}
            self.ChildMonitorData[childName] = monitorData
        end

        for _, fnData in functions do
            if type(fnData) == 'table' then
                if fnData[3][1] == "default_brain" then
                    tableRemove(fnData[3], 1)
                end
                tableInsert(monitorData, { FunctionInfo = fnData })
            elseif type(fnData) == 'function' then
                tableInsert(monitorData, { DirectFunction = fnData })
            end
        end

        -- run the check once and enable/disable as needed
        self:ChildMonitorCheck(childName, monitorData)
    end

    -- start thread if not already started
    if not self.ChildMonitorHandle then
        self.ChildMonitorHandle = ForkThread(self.ChildMonitorThread, self)
        self.Trash:Add(self.ChildMonitorHandle)
    end
end

---Runs periodically to toggle children enabled.
---
---Children are enabled unless one of the conditions return `false`.
---@private
function BaseOpAI:ChildMonitorThread()
    local monitorData = self.ChildMonitorData
    ---@cast monitorData -nil
    while true do
        -- Iterate through list enabling/disabling children types as needed.
        for name, data in pairs(monitorData) do
            self:ChildMonitorCheck(name, data)
        end
        WaitSeconds(7)
    end
end
---@private
---@param name OpAIChildType
---@param data OpAINewChildMonitorData[]
function BaseOpAI:ChildMonitorCheck(name, data)
    for _, v in data do
        local fn = v.DirectFunction
        local fnInfo = v.FunctionInfo
        if fn and not fn() then
            self:SetChildActive(name, false)
            return
        elseif fnInfo then
            if not import(fnInfo[1])[fnInfo[2]](self.AIBrain, unpack(fnInfo[3])) then
                self:SetChildActive(name, false)
                return
            end
        end
    end
    self:SetChildActive(name, true)
end
---Overrides the the template size of `childrenType` to `quantity` and disables all other childs.
---
---Child platoon template **has to match all** `childrenType` to be set.
---
---Possible combinations are:
--- - `'HeavyTanks', 6` - Sets the tanks count to 6
--- - `{'HeavyTanks', 'LightTanks', 'LightArtillery'}, 9` - Sets each to 3
--- - `{'HeavyTanks', 'LightArtillery'}, {10, 2}` - Sets tanks count to 10, art to 2
---@param childrenType OpAIChildType[]|OpAIChildType
---@param quantity integer|integer[]
function BaseOpAI:SetChildQuantity(childrenType, quantity)
    if not self:FindChildren() or not self:FindMaster() then return end

    self:SetChildActive('All', false)
    if type(childrenType) == 'table' then
        self:SetChildrenActive(childrenType)
    else
        self:SetChildActive(childrenType, true)
    end
    self:SetChildCount(1)
    self:KeepChildren(childrenType)
    self:OverrideTemplateSize(quantity)
end
---@param childrenType OpAIChildType|OpAIChildType[]
function BaseOpAI:RemoveChildren(childrenType)
    if not self:FindChildren() then return end

    local removeTable = {}
    if type(childrenType) == 'table' then
        removeTable = childrenType
    else
        tableInsert(removeTable, childrenType)
    end

    local childrenNames = self.ChildrenNames
    local childrenHandles = self.ChildrenHandles
    for k,v in childrenNames do
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
                for num,child in childrenHandles do
                    if child.ChildBuilder.BuilderName == v.BuilderName then
                        childrenHandles[num] = nil
                    end
                end
                childrenNames[k] = nil
            end
        end
    end
end
---@param childrenType OpAIChildType[]|OpAIChildType
function BaseOpAI:KeepChildren(childrenType)
    if not self:FindChildren() then return end

    ---@type OpAIChildType[]
    local keepTable
    if type(childrenType) == 'table' then
        keepTable = childrenType
    else
        keepTable = {}
        tableInsert(keepTable, childrenType)
    end

    local childrenNames = self.ChildrenNames
    local childrenHandles = self.ChildrenHandles
    for k, v in childrenNames do
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
                for num,child in childrenHandles do
                    if child.ChildBuilder.BuilderName == v.BuilderName then
                        childrenHandles[num] = nil
                    end
                end
                childrenNames[k] = nil
            end
        end
    end
end
---@protected
---@param quantity integer|integer[]
function BaseOpAI:OverrideTemplateSize(quantity)
    local quantityType = type(quantity)
    for _, v in self.ChildrenHandles do
        if quantityType == 'table' then
            for sNum,sData in v.ChildBuilder.PlatoonTemplate do
                if sNum >= 3 then
                    sData[2] = 1
                    sData[3] = quantity[sNum - 2] or 1
                end
            end
        else
            local overrideNum = mathFloor(quantity / (tableGetn(v.ChildBuilder.PlatoonTemplate) - 2))
            for sNum,sData in v.ChildBuilder.PlatoonTemplate do
                if sNum >= 3 then
                    sData[2] = 1
                    sData[3] = overrideNum
                end
            end
        end
    end
end
---Build conditions for PBM; Attack Conditions for AM Platoons
---@param fileName FileName
---@param funcName string
---@param parameters table Array with parameters that will be passed to the build condition function
---@param bName? string
---@return boolean
function BaseOpAI:AddBuildCondition(fileName, funcName, parameters, bName)
    if not self:FindChildren() or not self:FindMaster() then return false end

    -- Remove `"default_brain"` param from the condition. It's a remnant of GPG code that got refactored,
    -- as the AIBrain is always the first param passed to the build condition
    if parameters[1] == "default_brain" then
        tableRemove(parameters, 1)
    end
    for _, v in self.ChildrenHandles do
        local found

        if bName and v.ChildBuilder.BuilderName then
            found = stringFind(bName, v.ChildBuilder.BuilderName .. '_', 1, true)
        end

        if not bName or bName == v.ChildBuilder.BuilderName or found then
            tableInsert(v.ChildBuilder.BuildConditions, { fileName, funcName, parameters })
        end
    end
    if not bName or bName == self.MasterName then
        tableInsert(self.MasterData.AttackConditions, { fileName, funcName, parameters })
    end
    return true
end
---@param funcName string
---@param bName? string
---@return boolean
function BaseOpAI:RemoveBuildCondition(funcName, bName)
    if not self:FindChildren() or not self:FindMaster() then return false end

    for _, v in self.ChildrenHandles do
        local builder = v.ChildBuilder
        if not bName or bName == builder.BuilderName then
            local buildConditions = builder.BuildConditions
            if not buildConditions then continue end
            -- remove all entries with this fn name
            for i = tableGetn(buildConditions), 1, -1 do
                local bc = buildConditions[i]
                if bc[2] == funcName then
                    tableRemove(buildConditions, i)
                end
            end
        end
    end
    if not bName or bName == self.MasterName then
        local attackConditions = self.MasterData.AttackConditions
        -- remove all entries with this fn name
        for i = tableGetn(attackConditions), 1, -1 do
            local ac = attackConditions[i]
            if ac[2] == funcName then
                tableRemove(attackConditions, i)
            end
        end
    end
    return true
end
---Add Functions for PBM Platoons; FormCallbacks for AM Platoons
---@protected
---@param fileName fun(self: Platoon) | FileName
---@param funcName? string
---@param bName? string
---@return boolean
function BaseOpAI:AddAddFunction(fileName, funcName, bName)
    if not self:FindChildren() or not self:FindMaster() then return false end

    for _, v in self.ChildrenHandles do
        if not bName or bName == v.ChildBuilder.BuilderName then
            tableInsert(v.ChildBuilder.PlatoonAddFunctions, { fileName, funcName })
        end
    end
    if not bName or bName == self.MasterName then
        if type(fileName) == 'function' then
            tableInsert(self.MasterData.FormCallbacks, fileName)
        else
            tableInsert(self.MasterData.FormCallbacks, { fileName, funcName })
        end
    end
    return true
end
---Adds a function to run when the platoon is formed.
---@param filename fun(self: Platoon) | FileName
---@param funcName? string
---@param builderName? string
function BaseOpAI:AddFormCallback(filename, funcName, builderName)
    builderName = builderName or self.MasterName
    self:AddAddFunction(filename, funcName, builderName)
end
---Remove Functions for PBM Platoons; FormCallbacks for AM Platoons
---@protected
---@param funcName string
---@param builderName? string
---@return boolean
function BaseOpAI:RemoveAddFunction(funcName, builderName)
    if not self:FindChildren() or not self:FindMaster() then return false end

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
end
---@param funcName string
---@param builderName? string
function BaseOpAI:RemoveFormCallback(funcName, builderName)
    self:RemoveAddFunction(funcName, builderName)
end
---Add Build Callback for PBM Platoons; Death Callback for AM Platoons
---@param fileName FileName
---@param funcName string
---@param builderName? string
---@return boolean
function BaseOpAI:AddBuildCallback(fileName, funcName, builderName)
    if not self:FindChildren() or not self:FindMaster() then return false end

    for k,v in self.ChildrenHandles do
        if not builderName or builderName == v.ChildBuilder.BuilderName then
            tableInsert(v.ChildBuilder.PlatoonBuildCallbacks, { fileName, funcName })
        end
    end
    if not builderName or builderName == self.MasterName then
        tableInsert(self.MasterData.DestroyCallbacks, { fileName, funcName })
    end
    return true
end
---@param fileName FileName
---@param funcName string
---@param builderName? string
function BaseOpAI:AddDestroyCallback(fileName, funcName, builderName)
    self:AddBuildCallback(fileName, funcName, builderName)
end
---@param funcName string
---@param builderName? string
---@return boolean
function BaseOpAI:RemoveBuildCallback(funcName, builderName)
    if not self:FindChildren() or not self:FindMaster() then return false end

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
end
---@param funcName string
---@param builderName? string
function BaseOpAI:RemoveDestroyCallback(funcName, builderName)
    self:RemoveBuildCallback(funcName, builderName)
end
---@param val boolean
---@return boolean
function BaseOpAI:MasterUsePool(val)
    if not self:FindMaster() then return false end

    self.MasterData.UsePool = val
    return true
end
---Changes the default (once all units die) rebuild condition for this AI platoon.
---@param lockType OpAILockType
---@param lockData? OpAILockData
function BaseOpAI:SetLockingStyle(lockType, lockData)
    if not(lockType == 'None' or lockType == 'DeathTimer' or lockType == 'BuildTimer' or lockType == 'DeathRatio' or lockType == 'RatioTimer') then
        error('*AI ERROR: Error adding lock style: valid types are "DeathTimer", "BuildTimer", "DeathRatio", "RatioTimer", or "None"', 2)
    end
    self:RemoveBuildCondition('AMCheckPlatoonLock')
    if lockType == 'None' then return end

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
            error('*AI DEBUG: RatioTimer unlocking requires the data "Ratio" and "LockTimer"', 2)
        end
        self:AddFormCallback(BMPT, 'AMUnlockRatioTimer', self.MasterName)
        self.MasterData.PlatoonData.LockTimer = lockData.LockTimer
        self.MasterData.PlatoonData.Ratio = lockData.Ratio
    end
end
---@param childrenTypes OpAIChildType[]
function BaseOpAI:SetChildrenActive(childrenTypes)
    if not self:FindChildren() then return end

    for _, v in childrenTypes do
        self:SetChildActive(v, true)
    end
end
---@param cType OpAIChildType
---@param val boolean
function BaseOpAI:SetChildActive(cType, val)
    if not self:FindChildren() then return end

    -- check against self.EnabledTypes
    local enabledTypes = self.EnabledTypes

    if cType ~= 'All' then
        enabledTypes[cType] = val
    else
        for k, _ in enabledTypes do
            enabledTypes[k] = val
        end
    end

    -- Loop through children
    for _, v in self.ChildrenNames do
        -- Make sure this child has children types
        local childrenType = v.ChildrenType
        if not childrenType then continue end

        -- We don't want to change by default
        local change = false
        -- if the type is 'All' or we find that this builder has this child type, we may want to change
        for _, cName in childrenType do
            if (cName == cType) or (cType == 'All') then
                change = true
                break
            end
        end

        -- Need to change the children here
        if not change then continue end

        -- make sure that this builder's enabled types are all active
        local changeVal = true
        for _, cName in childrenType do
            -- This child type is not enabled, we'll want to disable this child type
            if not enabledTypes[cName] then
                changeVal = false
                break
            end
        end
        if changeVal then
            if not self:AddBuildCondition(MIBC, 'True', emptyTable, v.BuilderName) or
                not self:RemoveBuildCondition('False', v.BuilderName) then
                error('*AI ERROR: Error Adding build condition',2)
            end
        else
            if not self:AddBuildCondition(MIBC, 'False', emptyTable, v.BuilderName) or
                not self:RemoveBuildCondition('True', v.BuilderName) then
                error('*AI ERROR: Error Adding build condition',2)
            end
        end
    end
end
---Sets up all the variables and loads platoon builders.
---
---**This function is called automatically if the OpAI is added through BaseManager**
---@see BaseManager.AddOpAI
---@param brain CampaignAIBrain
---@param location string Name of the base
---@param builderType OpAIPlatoonTpFile | GeneratedScenario Save file that is used to find child quantities
---@param name string A name set by you to allow you to retrieve the returned AI instance
---@param builderData AddOpAIData?
function BaseOpAI:Create(brain, location, builderType, name, builderData)
    if not self.PreCreateFinished then self:PreCreate() end
    -- local tables to this class instance
    self.ChildMonitorData = {}
    self.ChildrenNames = {}
    self.EnabledTypes = {}

    -- Store off local instances of some variables
    self.AIBrain = brain
    self.LocationType = location
    self.BuilderType = builderType
    ---@type string
    local builderTypeName
    if type(self.BuilderType) == 'string' then
        self.GlobalVarName = name .. '_' .. self.BuilderType
        builderTypeName = self.BuilderType--[[@as string]]
    else
        self.GlobalVarName = name .. '_' .. self.BuilderType.Name
        builderTypeName = self.BuilderType.Name
    end

    -- Load all the platoon data info in the formation desired
    local data = {}
    if not builderData then
        data.Priority = 0
        data.PlatoonData = {}
    else
        -- Set PlatoonData
        if builderData.PlatoonData then
            data.PlatoonData = builderData.PlatoonData
        else
            data.PlatoonData = {}
        end
        -- Set priority
        if builderData.Priority then
            data.Priority = builderData.Priority
        else
            data.Priority = 0
        end
    end
    data.LocationType = location

    ---@type table<ScenarioBuilderName, PBMPlatoonBuilder>?
    local builders
    ---@type {Scenario: Scenario}
    local saveFile

    if type(self.BuilderType) == "string" then --BuilderType is old-school
        ScenarioUtils.LoadOSB('OSB_' .. builderTypeName .. '_' .. name, brain.Name, data)

        local fileName = '/lua/ai/OpAI/' .. builderTypeName .. '_save.lua'
        saveFile = import(fileName)

        self.MasterName = 'OSB_Master_' .. builderTypeName .. '_' .. brain.Name .. '_' .. name
    else --If BuilderType is a table (was pregenerated)

        ScenarioUtils.LoadOSB(builderType, brain.Name, data)
        saveFile = {Scenario = builderType--[[@as GeneratedScenario]]}

        --self.MasterName = 'OSB_Master_' .. saveFile.Scenario.Name .. '_' .. brain.Name .. '_' .. name
        self.MasterName = 'OSB_Master_' .. saveFile.Scenario.Name--[[@as string]] .. '_' .. brain.Name
    end

    builders = saveFile.Scenario.Armies['ARMY_1'].PlatoonBuilders.Builders

    if not builders then
        error('*OpAI ERROR: No OpAI Global named: '..builderTypeName, 2)
    end
    for k,v in builders do
        if stringSub(k, 1, 10) == 'OSB_Child_' then
            local startCheck = 11
            if type(self.BuilderType) == "string" then
                startCheck = startCheck + 1 + stringLen(builderTypeName--[[@as string]])
            else
                startCheck = startCheck + 1 + stringLen(builderTypeName)
            end
            local cType = stringSub(k,startCheck)

            tableInsert(self.ChildrenNames, { BuilderName = k..'_'..brain.Name..'_'..name, ChildrenType = v.ChildrenType })
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
end

OpAI = ClassSimple(BaseOpAI)

---@param brain CampaignAIBrain
---@param location string
---@param builderType OpAIPlatoonTpFile | string
---@param name string
---@param builderData AddOpAIData?
---@return OpAI
function CreateOpAI(brain, location, builderType, name, builderData)
    local opAI = OpAI()
    brain:PBMEnableRandomSamePriority()
    opAI:Create(brain, location, builderType, name, builderData)
    return opAI
end
