------------------------------------------------------------------
-- File     :  /lua/ai/OpAI/ReactiveAI.lua
-- Summary  : OpAI that reacts to certain defaulted events
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local OpAI = import("/lua/ai/opai/baseopai.lua").OpAI

local UCBC = '/lua/editor/unitcountbuildconditions.lua'
local BMBC = '/lua/editor/basemanagerbuildconditions.lua'
local MIBC = '/lua/editor/miscbuildconditions.lua'
local BMPT = '/lua/ai/opai/basemanagerplatoonthreads.lua'

--[[
Types usable in ReactiveAI

ReactionTypes:
    AirRetaliation
    
    ** Following not implemented yet **
    Horde
    Combined
    Pinpoint
    

TriggeringEventType
    ExperimentalLand
    ExperimentalAir
    ExperimentalNaval
    Nuke
    HLRA
    MassedAir

]]--

    
TrackingCategories = {
    ExperimentalAir = { categories.EXPERIMENTAL * categories.AIR, },
    ExperimentalLand = { categories.uel0401, (categories.EXPERIMENTAL * categories.LAND * categories.MOBILE) },
    ExperimentalNaval = { categories.EXPERIMENTAL * categories.NAVAL, },
    Nuke = { categories.NUKE, },
    HLRA = { categories.ueb2401, (categories.STRATEGIC * categories.TECH3) + (categories.EXPERIMENTAL * categories.STRUCTURE), },
    MassedAir = { categories.AIR * categories.MOBILE * ( categories.TECH2 + categories.TECH3 ), },
}

---@class ReactiveAI : OpAI
ReactiveAI = Class(OpAI) {

    ---@param self OpAI
    ---@param brain AIBrain
    ---@param location Vector
    ---@param triggeringEventType any
    ---@param reactionType any
    ---@param name string
    ---@param data any
    Create = function(self, brain, location, triggeringEventType, reactionType, name, data)
        -- With the actionType and responseType, we must create a builderType with proper builderData to create
        --   the OpAI

        -- We figure out what type of builder to add based on our action and response
        local builderType = self:GetBuilderType( triggeringEventType, reactionType )

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
        for k,v in builderType.Children do 
            self:SetChildActive(v, true) 
        end
        for k,v in builderType.TriggeringBuildConditions do
            self:AddBuildCondition( unpack(v) )
        end
    end,

    ReactionData = {
        -- This uses purely air to respond.  It is the easiest to implement and has the least chance of breaking
        AirRetaliation = {
            ExperimentalAir = { 
                OpAI = 'AirAttacks', 
                Children = { 'AirSuperiority', 'CombatFighters', 'Interceptors', },
                Priority = 1200,
                ChildCount = 4,
                PlatoonAIFunction = { '/lua/ScenarioPlatoonAI.lua', 'CategoryHunterPlatoonAI' },
                PlatoonData = {
                    CategoryList = TrackingCategories.ExperimentalAir,
                },
                TriggeringBuildConditions = {
                    { '/lua/editor/OtherArmyUnitCountBuildConditions.lua', 'FocusBrainBeingBuiltOrActiveCategoryCompare',
                        { 1, TrackingCategories.ExperimentalAir, '>=' } },
                },
            },
            ExperimentalLand = { 
                OpAI = 'AirAttacks', 
                Children = { 'HeavyGunships', 'Gunships', 'Bombers', 'CombatFighters', },
                Priority = 1200,
                ChildCount = 3,
                PlatoonAIFunction = { '/lua/ScenarioPlatoonAI.lua', 'CategoryHunterPlatoonAI' },
                PlatoonData = {
                    CategoryList = TrackingCategories.ExperimentalLand,
                },
                TriggeringBuildConditions = {
                    { '/lua/editor/OtherArmyUnitCountBuildConditions.lua', 'FocusBrainBeingBuiltOrActiveCategoryCompare',
                        { 1, TrackingCategories.ExperimentalLand, '>=' } },
                },
            },
            ExperimentalNaval = { 
                OpAI = 'AirAttacks', 
                Children = { 'TorpedoBombers', 'HeavyTorpedoBombers', },
                Priority = 1200,
                ChildCount = 3,
                PlatoonAIFunction = { '/lua/ScenarioPlatoonAI.lua', 'CategoryHunterPlatoonAI' },
                PlatoonData = {
                    CategoryList = TrackingCategories.ExperimentalNaval,
                },
                TriggeringBuildConditions = {
                    { '/lua/editor/OtherArmyUnitCountBuildConditions.lua', 'FocusBrainBeingBuiltOrActiveCategoryCompare',
                        { 1, TrackingCategories.ExperimentalNaval, '>=' } },
                },
            },
            Nuke = { 
                OpAI = 'AirAttacks', 
                Children = { 'StrategicBombers', 'HeavyGunships', 'Gunships', 'Bombers', },
                ChildCount = 1,
                Priority = 1200,
                PlatoonAIFunction = { '/lua/ScenarioPlatoonAI.lua', 'CategoryHunterPlatoonAI' },
                PlatoonData = {
                    CategoryList = TrackingCategories.Nuke,
                },
                TriggeringBuildConditions = {
                    { '/lua/editor/OtherArmyUnitCountBuildConditions.lua', 'FocusBrainBeingBuiltOrActiveCategoryCompare',
                        { 1, TrackingCategories.Nuke, '>=' } },
                },
            },
            HLRA = { 
                OpAI = 'AirAttacks', 
                Children = { 'StrategicBombers', 'HeavyGunships', 'Gunships', 'Bombers', },
                ChildCount = 1,
                Priority = 1200,
                PlatoonAIFunction = { '/lua/ScenarioPlatoonAI.lua', 'CategoryHunterPlatoonAI' },
                PlatoonData = {
                    CategoryList = TrackingCategories.HLRA,
                },
                TriggeringBuildConditions = {
                    { '/lua/editor/OtherArmyUnitCountBuildConditions.lua', 'FocusBrainBeingBuiltOrActiveCategoryCompare',
                        { 1, TrackingCategories.HLRA, '>=' } },
                },
           },
            MassedAir = { 
                OpAI = 'AirAttacks', 
                Children = { 'AirSuperiority', 'CombatFighters', 'Interceptors', },
                ChildCount = 4,
                Priority = 1200,
                PlatoonAIFunction = { '/lua/ScenarioPlatoonAI.lua', 'CategoryHunterPlatoonAI' },
                PlatoonData = {
                    CategoryList = TrackingCategories.MassedAir,
                },
                TriggeringBuildConditions = {
                    { '/lua/editor/OtherArmyUnitCountBuildConditions.lua', 'FocusBrainBeingBuiltOrActiveCategoryCompare',
                        { 40, TrackingCategories.MassedAir, '>=' } },
                },
            },
        },
        -- End of AirRetaliation block
    },

    ---@param self OpAI
    ---@param builderData any
    ---@param typeData any
    ---@param builderType any
    ---@param triggeringEventType any
    ---@param reactionType any
    GetBuilderData = function( self, builderData, typeData, builderType, triggeringEventType, reactionType )
    end,

    ---@param self OpAI
    ---@param triggeringEventType any
    ---@param reactionType any
    ---@return any
    GetBuilderType = function( self, triggeringEventType, reactionType )
        local retData = self.ReactionData[reactionType][triggeringEventType]
        if not retData then
            if not self.ReactionData[reactionType] then
                error( '*AI ERROR: Invalid reaction Type for ReactiveAI - ' .. reactionType, 2 )
            end
            error( '*AI ERROR: Invalid triggeringEventType for ReactiveAI - ' .. triggeringEventType, 2 )
        end
        return retData
    end,

    ReactionDatas = {},
}

---@param brain AIBrain
---@param location Vector
---@param triggeringEventType any
---@param reactionType any
---@param name string
---@param data any
---@return any
function CreateReactiveAI(brain, location, triggeringEventType, reactionType, name, data)
    local reactAI = ReactiveAI()
    reactAI:Create(brain, location, triggeringEventType, reactionType, name, data)
    return reactAI
end
