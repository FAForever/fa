------------------------------------------------------------------
-- File     :  /lua/ai/OpAI/ReactiveAI.lua
-- Summary  : OpAI that reacts to certain defaulted events
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local OpAI = import("/lua/ai/opai/baseopai.lua").OpAI

local UCBC = '/lua/editor/unitcountbuildconditions.lua'
local BMBC = '/lua/editor/basemanagerbuildconditions.lua'
local MIBC = '/lua/editor/miscbuildconditions.lua'
local OAUCBC = '/lua/editor/otherarmyunitcountbuildconditions.lua'
local BMPT = '/lua/ai/opai/basemanagerplatoonthreads.lua'

local unpack = unpack

---@class ReactAIBuilderTypeBase
---@field OpAI OpAIPlatoonTpFile
---@field Children OpAIChildType[]
---@field Priority integer Higher number = Higher priority, 0 gets never built
---@field ChildCount integer How many child platoons to build and combine
---@field PlatoonAIFunction FileFunctionRef
---@field PlatoonData table Any data required for the PlatoonAIFunction
---@field TriggeringBuildConditions BuildCondition[]

---@alias ReactAITriggerEvent #What triggers this AI from being built and dispatched
---| 'ExperimentalLand'  # Land experimental was detected
---| 'ExperimentalAir'   # Air experimental was detected
---| 'ExperimentalNaval' # Naval experimental was detected
---| 'Nuke'              # Nuke was detected
---| 'HLRA'              # Heavy long range artillery, nukes, satellites, experimental structures
---| 'MassedAir'         # Mass of T2 and T3 air units was detected

---@alias ReactAIReactionType #How the AI reacts when the conditions are met
---| 'AirRetaliation'    # Send air units

-- ** Following not implemented yet **
-- | 'Horde'
-- | 'Combined'
-- | 'Pinpoint'

TrackingCategories = {
    ExperimentalAir = { categories.EXPERIMENTAL * categories.AIR},
    ExperimentalLand = { categories.uel0401, (categories.EXPERIMENTAL * categories.LAND * categories.MOBILE) },
    ExperimentalNaval = { categories.EXPERIMENTAL * categories.NAVAL},
    Nuke = { categories.NUKE},
    HLRA = { categories.ueb2401, (categories.STRATEGIC * categories.TECH3) + (categories.EXPERIMENTAL * categories.STRUCTURE)},
    MassedAir = { categories.AIR * categories.MOBILE * ( categories.TECH2 + categories.TECH3 )},
}

---AI that is built with a predefined platoon template as response to the provided trigger type
---
---@see ReactAITriggerEvent for list of available events
---@see ReactAIReactionType for the types of reactive AIs
---@see OpAI.SetChildActive to disable certain children
---@class ReactiveAI : OpAI
---@field ReactionData table<ReactAIReactionType, table<ReactAITriggerEvent, ReactAIBuilderTypeBase>>
---@overload fun(): ReactiveAI
local ReactOpAI = {
    ReactionData = {
        AirRetaliation = {
            ExperimentalAir = {
                OpAI = 'AirAttacks',
                Children = {'AirSuperiority', 'CombatFighters', 'Interceptors'},
                Priority = 1200,
                ChildCount = 4,
                PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'CategoryHunterPlatoonAI'},
                PlatoonData = {
                    CategoryList = TrackingCategories.ExperimentalAir,
                },
                TriggeringBuildConditions = {
                    {OAUCBC, 'FocusBrainBeingBuiltOrActiveCategoryCompare', {1, TrackingCategories.ExperimentalAir, '>='}},
                },
            },
            ExperimentalLand = {
                OpAI = 'AirAttacks',
                Children = {'HeavyGunships', 'Gunships', 'Bombers', 'CombatFighters'},
                Priority = 1200,
                ChildCount = 3,
                PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'CategoryHunterPlatoonAI'},
                PlatoonData = {
                    CategoryList = TrackingCategories.ExperimentalLand,
                },
                TriggeringBuildConditions = {
                    {OAUCBC, 'FocusBrainBeingBuiltOrActiveCategoryCompare', {1, TrackingCategories.ExperimentalLand, '>='}},
                },
            },
            ExperimentalNaval = {
                OpAI = 'AirAttacks',
                Children = {'TorpedoBombers', 'HeavyTorpedoBombers'},
                Priority = 1200,
                ChildCount = 3,
                PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'CategoryHunterPlatoonAI'},
                PlatoonData = {
                    CategoryList = TrackingCategories.ExperimentalNaval,
                },
                TriggeringBuildConditions = {
                    {OAUCBC, 'FocusBrainBeingBuiltOrActiveCategoryCompare', {1, TrackingCategories.ExperimentalNaval, '>='}},
                },
            },
            Nuke = {
                OpAI = 'AirAttacks',
                Children = {'StratBombers', 'HeavyGunships', 'Gunships', 'Bombers'},
                ChildCount = 1,
                Priority = 1200,
                PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'CategoryHunterPlatoonAI'},
                PlatoonData = {
                    CategoryList = TrackingCategories.Nuke,
                },
                TriggeringBuildConditions = {
                    {OAUCBC, 'FocusBrainBeingBuiltOrActiveCategoryCompare', {1, TrackingCategories.Nuke, '>='}},
                },
            },
            HLRA = {
                OpAI = 'AirAttacks',
                Children = {'StratBombers', 'HeavyGunships', 'Gunships', 'Bombers'},
                ChildCount = 1,
                Priority = 1200,
                PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'CategoryHunterPlatoonAI'},
                PlatoonData = {
                    CategoryList = TrackingCategories.HLRA,
                },
                TriggeringBuildConditions = {
                    {OAUCBC, 'FocusBrainBeingBuiltOrActiveCategoryCompare', {1, TrackingCategories.HLRA, '>='}},
                },
            },
            MassedAir = {
                OpAI = 'AirAttacks',
                Children = {'AirSuperiority', 'CombatFighters', 'Interceptors'},
                ChildCount = 4,
                Priority = 1200,
                PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'CategoryHunterPlatoonAI'},
                PlatoonData = {
                    CategoryList = TrackingCategories.MassedAir,
                },
                TriggeringBuildConditions = {
                    {OAUCBC, 'FocusBrainBeingBuiltOrActiveCategoryCompare', {40, TrackingCategories.MassedAir, '>='}},
                },
            },
        },
    },
}
---@param brain CampaignAIBrain
---@param location string Name of the base
---@param trigger ReactAITriggerEvent
---@param reaction ReactAIReactionType
---@param name string Unique name of the AI platoon
---@param data? table Optional data to overrite the default platoon builder values
function ReactOpAI:Create(brain, location, trigger, reaction, name, data)
    -- With the actionType and responseType, we must create a builderType with proper builderData to create
    --   the OpAI

    -- We figure out what type of builder to add based on our action and response
    local builderType = self:GetBuilderType(trigger, reaction)

    -- At this point we need to combine the passed in data with our own data to create the OpAI
    local builderData = {
        MasterPlatoonFunction = builderType.PlatoonAIFunction,
        PlatoonData = builderType.PlatoonData,
        Priority = builderType.Priority,
    }
    if data then
        for k,v in data do
            builderData[k] = v
        end
    end

    -- Create the actual OpAI thing here passing in the rebuilt data
    OpAI.Create(self, brain, location, builderType.OpAI, name .. '_' .. location .. '_ReactiveAI', builderData)

    -- add in children count, child locks, etc
    self:SetChildCount(builderType.ChildCount)

    -- Activate only the children listed
    self:SetChildActive('All', false)
    for _, v in builderType.Children do
        self:SetChildActive(v, true)
    end

    for _, v in builderType.TriggeringBuildConditions do
        self:AddBuildCondition(unpack(v))
    end
end
---@protected
---@param trigger ReactAITriggerEvent
---@param reaction ReactAIReactionType
---@return ReactAIBuilderTypeBase
function ReactOpAI:GetBuilderType(trigger, reaction)
    local retData = self.ReactionData[reaction][trigger]
    if not retData then
        if not self.ReactionData[reaction] then
            error('*AI ERROR: Invalid reaction Type for ReactiveAI - ' .. reaction, 2)
        end
        error('*AI ERROR: Invalid triggeringEvent for ReactiveAI - ' .. trigger, 2)
    end
    return retData
end

ReactiveAI = Class(OpAI--[[@as fa-class]])(ReactOpAI)

---@param brain CampaignAIBrain
---@param location string Name of the base
---@param trigger ReactAITriggerEvent
---@param reaction ReactAIReactionType
---@param name string Unique name of the AI platoon
---@param data? table Optional data to overrite the default platoon builder values
---@return ReactiveAI
function CreateReactiveAI(brain, location, trigger, reaction, name, data)
    local reactAI = ReactiveAI()
    reactAI:Create(brain, location, trigger, reaction, name, data)
    return reactAI
end
