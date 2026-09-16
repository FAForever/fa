--******************************************************************************************************************
--*
--*  File     :  /lua/ai/OpAI/GenerateNaval.lua
--*
--*  Summary  : Generates naval platoon templates and builders based on the supplied parameters
--*
--*  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--******************************************************************************************************************

local ScenarioFramework = import("/lua/scenarioframework.lua")

local SPAI = '/lua/ScenarioPlatoonAI.lua'

local unpack = unpack
local mathFloor = math.floor
local mathMod = math.mod
local tableInsert = table.insert
local tableFind = table.find

---Generated data with platoon templates and builders for OpAI
---@class GeneratedScenario: Scenario
---@field Name string

---@alias NavalOpAIChildType
---| 'Frigate'
---| 'Destroyer'
---| 'Battleship'
---| 'T3Submarine'
---| 'T2Submarine'
---| 'Submarine'
---| 'Cruiser'
---| 'LightBoat'     # Aeon AA boat
---| 'Utility'       # Shield, stealth boats
---| 'Fatty'         # T3 Battlecruiser / Missile ship
---| 'Carrier'       # Aircraft carriers
---| 'NukeSubmarine'

---@alias NavalOpAIGenType
---| 'CORE'     # Firagates, Destroyers, Battleships
---| 'SUBS'     # T1 subs, T2 sub-hunters
---| 'LIGHT'    # Aeon AA boat
---| 'CRUISERS' # Cruisers
---| 'UTILITY'  # Shield, stealth boats
---| 'CARRIERS' # Aircraft carriers
---| 'FATTIES'  # T3 Battlecruiser / Missile ship
---| 'NUKESUBS' # T3 nuke subs

---@alias NavalOpAIGenConversion
---| 'FRIGATES_PER_DESTROYER'    # How many ships must exist before we converting to next tier. Defaults to `5`
---| 'DESTROYERS_PER_BATTLESHIP' # How many ships must exist before we converting to next tier. Defaults to `5`
---| 'CORE_TO_SUBS'              # How many core ships must be places before we convert to this type. Defaults to `2`.
---| 'CORE_TO_CRUISERS'          # How many core ships must be places before we convert to this type. Defaults to `4`.
---| 'CORE_TO_FATTIES'           # How many core ships must be places before we convert to this type. Defaults to `3`.
---| 'CORE_TO_CARRIERS'          # How many core ships must be places before we convert to this type. Defaults to `3`.
---| 'CORE_TO_LIGHT'             # How many core ships must be places before we convert to this type. Defaults to `2`.
---| 'CORE_TO_UTILITY'           # How many core ships must be places before we convert to this type. Defaults to `2`.
---| 'CORE_TO_NUKESUBS'          # How many core ships must be places before we convert to this type. Defaults to `3`.

---@class NavalOpAIGeneratorData
---The starting number of virtual frigate units allocated to the very first platoon template (Tier 1, Wave 1)
---
---Sets the baseline strength and size for the weakest naval wave. Higher values result in larger starting fleets
---
---If not provided, it will be calculated from the number of naval factories in the base
---@field MaxFrigates? integer
---The target number of virtual frigate units allocated to the final platoon template (Tier 3, final wave)
---
---Controls the maximum overall scaling and final size of the endgame naval force
---
---If not provided, it will be calculated from the number of naval factories in the base
---@field MinFrigates? integer
---Used to calculate `MaxFrigates` based on number of naval factories in the base.
---
---Used only if `MaxFrigates` is not specified.
---
---Defaults to `1`
---@field MaxMultiplier? integer
---Used to calculate `MinFrigates` based on number of naval factories in the base.
---
---Used only if `MinFrigates` is not specified.
---
---Defaults to `MaxMultiplier`
---@field MinMultiplier? integer
---The number of distinct platoon build waves generated within each of the 3 tech tiers (T1, T2, and T3)
---
---Determines total progression steps Nx3.
---It controls the growth smooth steps: higher values create more granular progression with smaller unit increments
---between waves,while lower values cause steeper jumps in fleet composition
---
---Defaults to `1`
---@field NumLevels? integer
---If specified, only these types will be used to generate the template
---
---`Frigates` can't be disabled.
---@field EnabledTypes? NavalOpAIChildType[]
---Disables certain childs from being added during during template generation.
---
---Core ships can't be disabled.
---@field DisableTypes? table<NavalOpAIChildType, true>
---Overrides default conversions for generating the platoon.
---
---@see NavalOpAIGenConversion
---@field Overrides? table<NavalOpAIGenConversion, number>

--To make life easier with factions not having identical naval units and such.
local TIERS = {
    --Tier 1 naval units
    { --              UEF        AEON       CYBRAN     SERA
        CORE =      {'ues0103', 'uas0103', 'urs0103', 'xss0103'},
        SUBS =      {'ues0203', 'uas0203', 'urs0203', 'xss0203'},
        LIGHT =     { nil     , 'uas0102',  nil     ,  nil     },
    },

    --Tier 2 naval units
    {
        CORE =      {'ues0201', 'uas0201', 'urs0201', 'xss0201'},
        SUBS =      {'xes0102', 'xas0204', 'xrs0204', 'xss0203'},   --note seraphim have no T2 sub hunter
        CRUISERS =  {'ues0202', 'uas0202', 'urs0202', 'xss0202'},
        UTILITY =   {'xes0205',  nil     , 'xrs0205',  nil     },
    },

    --Tier 3 naval units
    {
        CORE =      {'ues0302', 'uas0302', 'urs0302', 'xss0302'},
        SUBS =      {'xes0102', 'xas0204', 'xrs0204', 'xss0304'},
        CRUISERS =  {'ues0202', 'uas0202', 'urs0202', 'xss0202'},
        CARRIERS =  { nil     , 'uas0303', 'urs0303', 'xss0303'},
        FATTIES =   {'xes0307', 'xas0306',  nil     ,  nil     },
        UTILITY =   {'xes0205',  nil     , 'xrs0205',  nil     },
        NUKESUBS =  {'ues0304', 'uas0304', 'urs0304',  nil     },
    },
}

local BasePriority = 700

---How many ships must exist before we convert them to one of the next-tier core ship
---
---How many core ships (frigates, destroyers, battleships) must be in a platoon before we include one of these unit types.
local Conversions = {
    FRIGATES_PER_DESTROYER = 5,
    DESTROYERS_PER_BATTLESHIP = 5,
    CORE_TO_SUBS = 2,
    CORE_TO_CRUISERS = 4,
    CORE_TO_FATTIES = 3,
    CORE_TO_CARRIERS = 3,
    CORE_TO_LIGHT = 2,
    CORE_TO_UTILITY = 2,
    CORE_TO_NUKESUBS = 3,
}

---Returns true if `enabledTypes` is not specified or when it contains `unitType`
---@param unitType NavalOpAIChildType
---@param enabledTypes? NavalOpAIChildType[]
---@return boolean
local function isEnabledType(unitType, enabledTypes)
    -- Everything is enabled by default
    if not enabledTypes then return true end
    return tableFind(enabledTypes, unitType) ~= nil
end

---@param name NavalOpAIGenConversion
---@param overrides? table<NavalOpAIGenConversion, number>
---@return number
local function getConversion(name, overrides)
    return (overrides and overrides[name]) or Conversions[name]
end

---@param name string
---@param levelsPerTier integer
---@param minFrigates integer
---@param maxFrigates integer
---@param faction integer 1=UEF, 2=Aeon, 3=Cybran, 4=Seraphim
---@param data NavalOpAIGeneratorData
---@return GeneratedScenario
function GenerateNavalOSB(name, levelsPerTier, minFrigates, maxFrigates, faction, data)
    local enabledTypes = data.EnabledTypes
    local overrides = data.Overrides

    local builders = {}
    local Scenario = {
        Name = name,
        Platoons = {
            OST_BLANK_TEMPLATE = {'OST_BLANK_TEMPLATE', ''},
        },
        Armies = {
            ARMY_1 = {
                PlatoonBuilders = {
                    Builders = builders,
                },
            },
        },
    }
    local masterPlatoonName = 'OSB_Master_' .. name

    local levels = levelsPerTier * 3

    --Frigate increment per level
    local frigInc = (maxFrigates-minFrigates)/(levels-1)

    --Accumulators
    local frigAcc = minFrigates
    local destAcc = 0
    local battAcc = 0

    local TIER1, TIER2, TIER3 = TIERS[1], TIERS[2], TIERS[3]

    --Build the stuff
    for level = 1, levels do
        --Types of naval units in the platoon
        local tier = mathFloor((level-1)/levelsPerTier) + 1
        local waveLevel = mathMod(level-1, levelsPerTier) + 1
        local tpName = 'OST_' .. name .. '_' .. tier .. '-' .. waveLevel .. '_Template'

        ---@type OpAIChildType[]
        local children = {'T' .. tier} --, 'L' .. tostring(level)}

        local template = {tpName, ''}
        Scenario.Platoons[tpName] = template

        --------------------------------
        -- Generate the platoon template
        --------------------------------

        --If we're tier 2 or higher, convert frigates to destroyers at the going rate
        while tier >= 2 and frigAcc >= getConversion('FRIGATES_PER_DESTROYER', overrides) do
            frigAcc = frigAcc - getConversion('FRIGATES_PER_DESTROYER', overrides)
            destAcc = destAcc + 1
        end

        --If we're tier 3 or higher, convert destroyers to battleships at the going rate
        while tier >= 3 and destAcc >= getConversion('DESTROYERS_PER_BATTLESHIP', overrides) do
            destAcc = destAcc - getConversion('DESTROYERS_PER_BATTLESHIP', overrides)
            battAcc = battAcc + 1
        end

        local numFrigates = mathFloor(frigAcc)
        local numDestroyers = mathFloor(destAcc)
        local numBattleships = mathFloor(battAcc)

        if numFrigates > 0 then
            tableInsert(template, {TIER1.CORE[faction], 1, numFrigates, 'Attack', 'None'})
            tableInsert(children, 'Frigate')
        end
        if isEnabledType('Destroyer', enabledTypes) and numDestroyers > 0 then
            tableInsert(template, {TIER2.CORE[faction], 1, numDestroyers, 'Attack', 'None'})
            tableInsert(children, 'Destroyer')
        end
        if isEnabledType('Battleship', enabledTypes) and numBattleships > 0 then
            tableInsert(template, {TIER3.CORE[faction], 1, numBattleships, 'Attack', 'None'})
            tableInsert(children, 'Battleship')
        end

        -- Do submarines.
        if isEnabledType('Submarine', enabledTypes) then
            local numSubmarines = 0
            if tier >= 3 then
                numSubmarines = mathFloor(numBattleships / getConversion('CORE_TO_SUBS', overrides))
            elseif tier >= 2 then
                numSubmarines = mathFloor(numDestroyers / getConversion('CORE_TO_SUBS', overrides))
            else
                numSubmarines = mathFloor(numFrigates / getConversion('CORE_TO_SUBS', overrides))
            end

            if numSubmarines > 0 then
                local placed = false
                if tier == 3 and not data.DisableTypes['T3Submarine'] then
                    tableInsert(template, {TIER3.SUBS[faction], 1, numSubmarines, 'Guard', 'None'})
                    tableInsert(children, 'T3Submarine')
                    placed = true
                elseif tier >= 2 and not placed and not data.DisableTypes['T2Submarine'] then
                    tableInsert(template, {TIER2.SUBS[faction], 1, numSubmarines, 'Guard', 'None'})
                    tableInsert(children, 'T2Submarine')
                elseif not placed and not data.DisableTypes['Submarine'] then
                    tableInsert(template, {TIER1.SUBS[faction], 1, numSubmarines, 'Guard', 'None'})
                    tableInsert(children, 'Submarine')
                end
            end
        end

        -- Do cruisers.
        if isEnabledType('Cruiser', enabledTypes) then
            local numCruisers = 0
            if tier == 2 then
                numCruisers = mathFloor(numDestroyers / getConversion('CORE_TO_CRUISERS', overrides))
            elseif tier >= 3 then
                numCruisers = mathFloor(numBattleships / getConversion('CORE_TO_CRUISERS', overrides))
            end

            if numCruisers > 0 then
                tableInsert(template, {TIERS[tier].CRUISERS[faction], 1, numCruisers, 'Guard', 'None'})
                tableInsert(children, 'Cruiser')
            end
        end

        -- Do light T1 boats only at T1. Note not every faction has light T1 boats
        if isEnabledType('LightBoat', enabledTypes) then
            local numLight = 0
            if tier == 1 and TIER1.LIGHT[faction] then
                numLight = mathFloor(numFrigates / getConversion('CORE_TO_LIGHT', overrides))
            end

            if numLight > 0 then
                tableInsert(template, {TIER1.LIGHT[faction], 1, numLight, 'Guard', 'None'})
                tableInsert(children, 'LightBoat')
            end
        end

        -- Do T2 utility boats. Cybran = stealth boat, UEF = shields. Note not every faction has a T2 utility boat.
        if isEnabledType('Utility', enabledTypes) then
            local numUtility = 0
            if tier == 2 and TIER2.UTILITY[faction] then
                numUtility = mathFloor(numDestroyers / getConversion('CORE_TO_UTILITY', overrides))
            elseif tier >= 3 and TIER3.UTILITY[faction] then
                numUtility = mathFloor(numBattleships / getConversion('CORE_TO_UTILITY', overrides))
            end

            if numUtility > 0 then
                tableInsert(template, {TIER3.UTILITY[faction], 1, numUtility, 'Guard', 'None'})
                tableInsert(children, 'Utility')
            end
        end

        -- Do T3 fatties. battlecruiser, missile ship. Note Aeon and Cybran have no fatties.
        if isEnabledType('Fatty', enabledTypes) then
            local numFatties = 0
            if tier >= 3 and TIER3.FATTIES[faction] then
                numFatties = mathFloor(numBattleships / getConversion('CORE_TO_FATTIES', overrides))
            end

            if numFatties > 0 then
                tableInsert(template, {TIER3.FATTIES[faction], 1, numFatties, 'Guard', 'None'})
                tableInsert(children, 'Fatty')
            end
        end

        -- Do T3 carriers. Note UEF has no T3 carrier.
        if isEnabledType('Carrier', enabledTypes) then
            local numCarriers = 0
            if tier >= 3 and TIER3.CARRIERS[faction] then
                numCarriers = mathFloor(numBattleships / getConversion('CORE_TO_CARRIERS', overrides))
            end

            if numCarriers > 0 then
                tableInsert(template, {TIER3.CARRIERS[faction], 1, numCarriers, 'Guard', 'None'})
                tableInsert(children, 'Carrier')
            end
        end

        -- Do nuke subs, only if allowed. Note Seraphim has no nuke sub.
        if (enabledTypes and isEnabledType('NukeSubmarine', enabledTypes)) then
            local numNukeSubs = 0
            if tier >= 3 and TIER3.NUKESUBS[faction] then
                numNukeSubs = mathFloor(numBattleships / getConversion('CORE_TO_NUKESUBS', overrides))
            end

            if numNukeSubs > 0 then
                tableInsert(template, {TIER3.NUKESUBS[faction], 1, numNukeSubs, 'Guard', 'None'})
                tableInsert(children, 'NukeSubmarine')
            end
        end

        -- Create the child platoon builder
        builders['OSB_Child_' .. name .. '_' .. tier .. '-' .. waveLevel] = {
            PlatoonAIFunction = {SPAI, 'DefaultOSBasePatrol', {'default_platoon'}, {'default_platoon'}},
            PlatoonTemplate = tpName,
            Priority = BasePriority + tier,
            InstanceCount = 1,
            LocationType = 'MAIN',
            BuildTimeOut = -1,
            PlatoonType = 'Sea',
            RequiresConstruction = true,
            BuildConditions = {
                {
                    '/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                    {'default_master'},
                    {'default_master'}
                },
                {
                    '/lua/ai/opai/GenerateNaval.lua', 'ChildShouldBuild',
                    {'default_master'},
                    {'default_master'},
                },
            },
            PlatoonData = {
                {
                    type = 5, name = 'AMPlatoons', value = {
                        {type = 2, name = 'String_0',  value = masterPlatoonName},
                        {type = 2, name = 'APPEND_FleetChildren',  value = masterPlatoonName},
                    }
                },
            },

            ChildrenType = { unpack(children) },
        }

        --Increment the number of frigates and continue

        frigAcc = frigAcc + frigInc
    end

    -- Create the master platoon builder

    builders[masterPlatoonName] = {
        PlatoonTemplate = 'OST_BLANK_TEMPLATE',
        Priority = BasePriority + 1 + levels,
        InstanceCount = 1,
        LocationType = 'MAIN',
        BuildTimeOut = -1,
        PlatoonType = 'Sea',
        RequiresConstruction = false,
        PlatoonAIFunction = {SPAI, 'DefaultOSBasePatrol', {'default_platoon'}, {'default_platoon'}},
        BuildConditions = {
            {
                '/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                {'default_master'},
                {'default_master'}
            },
            {
                '/lua/ai/opai/generatenaval.lua', 'FleetIsBuilt',
                {'default_master'},
                {'default_master'},
            },
        },
        PlatoonBuildCallbacks = {
            {
                '/lua/editor/amplatoonhelperfunctions.lua', 'AMUnlockPlatoon',
                {'default_platoon'},
                {'default_platoon'}
            },
        },
        PlatoonAddFunctions = {
            {
                '/lua/editor/amplatoonhelperfunctions.lua', 'AMLockPlatoon',
                {'default_platoon'},
                {'default_platoon'}
            },
        },
        PlatoonData = {
            {type = 3, name = 'AMMasterPlatoon',  value = true},
            {type = 3, name = 'UsePool', value = false},
        },
    }

    return Scenario
end

---@param aiBrain CampaignAIBrain
---@param master string
---@return boolean
function FleetIsBuilt(aiBrain, master)
    local fleetCounter = ScenarioFramework.AMPlatoonCounter(aiBrain, master..'_FleetChildren')

    return fleetCounter >= 1
end

---@param aiBrain CampaignAIBrain
---@param master string
---@return boolean
function ChildShouldBuild(aiBrain, master)
    local fleetCounter = ScenarioFramework.AMPlatoonCounter(aiBrain, master..'_FleetChildren')

    return fleetCounter < 1
end
