--******************************************************************************************************************
--*
--*  File     :  /lua/ai/OpAI/GenerateNaval.lua
--*
--*  Summary  : Generates naval platoon templates and builders based on the supplied parameters
--*
--*  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--******************************************************************************************************************

local ScenarioFramework = import("/lua/scenarioframework.lua")

--To make life easier with factions not having identical naval units and such.
local TIERS =
{
    --Tier 1 naval units
    {
        CORE =      {U='ues0103', C='urs0103', A='uas0103', S='xss0103'},
        SUBS =      {U='ues0203', C='urs0203', A='uas0203', S='xss0203'},
        LIGHT =     {                          A='uas0102',            },
    },

    --Tier 2 naval units
    {
        CORE =      {U='ues0201', C='urs0201', A='uas0201', S='xss0201'},
        SUBS =      {U='xes0102', C='xrs0204', A='xas0204', S='xss0203'},   --note seraphim have no T2 sub hunter
        CRUISERS =  {U='ues0202', C='urs0202', A='uas0202', S='xss0202'},
        UTILITY =   {U='xes0205', C='xrs0205',                         },
    },

    --Tier 3 naval units
    {
        CORE =      {U='ues0302', C='urs0302', A='uas0302', S='xss0302'},
        SUBS =      {U='xes0102', C='xrs0204', A='xas0204', S='xss0304'},
        CRUISERS =  {U='ues0202', C='urs0202', A='uas0202', S='xss0202'},
        CARRIERS =  {             C='urs0303', A='uas0303', S='xss0303'},
        FATTIES =   {U='xes0307',              A='xas0306',            },
        UTILITY =   {U='xes0205', C='xrs0205',                         },
        NUKESUBS =  {U='ues0304', C='urs0304', A='uas0304',            },
    },
}

local BasePriority = 700

local Conversions =
{
--How many ships must exist before we convert them to one of the next-tier core ship
    FRIGATES_PER_DESTROYER = 5,
    DESTROYERS_PER_BATTLESHIP = 5,

--How many core ships (frigates, destroyers, battleships) must be in a platoon before we include one of these unit types.
    CORE_TO_SUBS = 2,
    CORE_TO_CRUISERS = 4,
    CORE_TO_FATTIES = 3,
    CORE_TO_CARRIERS = 3,
    CORE_TO_LIGHT = 0.5,
    CORE_TO_UTILITY = 2,
    CORE_TO_NUKESUBS = 3,
}

function IsEnabledType(unitType, data)
    for _, v in data.EnabledTypes do
        if unitType == v then
            return true
        end
    end
    return false
end

function GenerateNavalOSB(name, levelsPerTier, minFrigates, maxFrigates, faction, data)
    if data.Overrides then
        for k, v in data.Overrides do
            Conversions[k] = v
        end
    end

    local allEnabled = true
    if data.EnabledTypes then
        allEnabled = false
    end

    local Scenario = { Platoons = {}, Armies = { ARMY_1 = { PlatoonBuilders = { Builders = { } } } }, Name = name }
    local levels = levelsPerTier * 3

    --Frigate increment per level
    local frigInc = (maxFrigates-minFrigates)/(levels-1)

    --Accumulators
    local frigAcc = minFrigates
    local destAcc = 0
    local battAcc = 0

    Scenario.Platoons['OST_BLANK_TEMPLATE'] = {'OST_BLANK_TEMPLATE', ''}

    --Build the stuff
    for level = 1, levels do
        --Types of naval units in the platoon
        local tier = math.floor((level-1)/levelsPerTier) + 1
        local waveLevel = math.mod(level-1, levelsPerTier) + 1
        local template = 'OST_' .. name .. '_' .. tostring(tier) .. '-' .. tostring(waveLevel) .. '_Template'

        local children = {'T' .. tostring(tier)} --, 'L' .. tostring(level)}

        Scenario.Platoons[template] = {template, ''}

        --------------------------------------------
        -- Generate the platoon template
        --------------------------------------------

        --If we're tier 2 or higher, convert frigates to destroyers at the going rate
        while tier >= 2 and frigAcc >= Conversions.FRIGATES_PER_DESTROYER do
            frigAcc = frigAcc - Conversions.FRIGATES_PER_DESTROYER
            destAcc = destAcc + 1
        end

        --If we're tier 3 or higher, convert destroyers to battleships at the going rate
        while tier >= 3 and destAcc >= Conversions.DESTROYERS_PER_BATTLESHIP do
            destAcc = destAcc - Conversions.DESTROYERS_PER_BATTLESHIP
            battAcc = battAcc + 1
        end

        local numFrigates = math.floor(frigAcc)
        local numDestroyers = math.floor(destAcc)
        local numBattleships = math.floor(battAcc)

        if numFrigates > 0 then
            table.insert(Scenario.Platoons[template], {TIERS[1].CORE[faction], 1, numFrigates, 'attack', 'None'})
            table.insert(children, 'Frigate')
        end
        if (allEnabled or IsEnabledType('Destroyer', data)) and numDestroyers > 0 then
            table.insert(Scenario.Platoons[template], {TIERS[2].CORE[faction], 1, numDestroyers, 'attack', 'None'})
            table.insert(children, 'Destroyer')
        end
        if (allEnabled or IsEnabledType('Battleship', data)) and numBattleships > 0 then
            table.insert(Scenario.Platoons[template], {TIERS[3].CORE[faction], 1, numBattleships, 'attack', 'None'})
            table.insert(children, 'Battleship')
        end

        -- Do submarines.
        local numSubmarines = 0
        if (allEnabled or IsEnabledType('Submarine', data)) then
            if tier == 1 then numSubmarines = math.floor(numFrigates / Conversions.CORE_TO_SUBS)
            elseif tier >= 2 then numSubmarines = math.floor(numDestroyers / Conversions.CORE_TO_SUBS)
            elseif tier >= 3 then numSubmarines = math.floor(numBattleships / Conversions.CORE_TO_SUBS) end
            if numSubmarines > 0 then

                local placed = false
                if tier == 3 and not data.DisableTypes['T3Submarine'] then
                    table.insert(Scenario.Platoons[template], {TIERS[3].SUBS[faction], 1, numSubmarines, 'guard', 'None'})
                    table.insert(children, 'T3Submarine')
                    placed = true
                elseif tier >= 2 and not placed and not data.DisableTypes['T2Submarine'] then
                    table.insert(Scenario.Platoons[template], {TIERS[2].SUBS[faction], 1, numSubmarines, 'guard', 'None'})
                    table.insert(children, 'T2Submarine')
                elseif not placed and not data.DisableTypes['Submarine'] then
                    table.insert(Scenario.Platoons[template], {TIERS[1].SUBS[faction], 1, numSubmarines, 'guard', 'None'})
                    table.insert(children, 'Submarine')
                end
            end
        end

        -- Do cruisers.
        local numCruisers = 0
        if (allEnabled or IsEnabledType('Cruiser', data)) then
            if tier == 2 then numCruisers = math.floor(numDestroyers / Conversions.CORE_TO_CRUISERS)
            elseif tier >= 3 then numCruisers = math.floor(numBattleships / Conversions.CORE_TO_CRUISERS) end
            if numCruisers > 0 then
                table.insert(Scenario.Platoons[template], {TIERS[tier].CRUISERS[faction], 1, numCruisers, 'guard', 'None'})
                table.insert(children, 'Cruiser')
            end
        end

        -- Do light T1 boats only at T1. Note not every faction has light T1 boats
        local numLight = 0
        if (allEnabled or IsEnabledType('LightBoat', data)) then
            if tier == 1 and TIERS[1].LIGHT[faction] then numLight = math.floor(numFrigates / Conversions.CORE_TO_LIGHT) end
            if numLight > 0 then
                table.insert(Scenario.Platoons[template], {TIERS[1].LIGHT[faction], 1, numLight, 'guard', 'None'})
                table.insert(children, 'LightBoat')
            end
        end

        -- Do T2 utility boats. Cybran = stealth boat, UEF = shields. Note not every faction has a T2 utility boat.
        local numUtility = 0
        if (allEnabled or IsEnabledType('Utility', data)) then
            if tier == 2 and TIERS[2].UTILITY[faction] then numUtility = math.floor(numDestroyers / Conversions.CORE_TO_UTILITY)
            elseif tier >= 3 and TIERS[3].UTILITY[faction] then numUtility = math.floor(numBattleships / Conversions.CORE_TO_UTILITY) end
            if numUtility > 0 then
                table.insert(Scenario.Platoons[template], {TIERS[3].UTILITY[faction], 1, numUtility, 'guard', 'None'})
                table.insert(children, 'Utility')
            end
        end

        -- Do T3 fatties. battlecruiser, missile ship. Note Aeon and Cybran have no fatties.
        local numFatties = 0
        if (allEnabled or IsEnabledType('Fatty', data)) then
            if tier >= 3 and TIERS[3].FATTIES[faction] then numFatties = math.floor(numBattleships / Conversions.CORE_TO_FATTIES) end
            if numFatties > 0 then
                table.insert(Scenario.Platoons[template], {TIERS[3].FATTIES[faction], 1, numFatties, 'guard', 'None'})
                table.insert(children, 'Fatty')
            end
        end

        -- Do T3 carriers. Note UEF has no T3 carrier.
        local numCarriers = 0
        if (allEnabled or IsEnabledType('Carrier', data)) then
            if tier >= 3 and TIERS[3].CARRIERS[faction] then numCarriers = math.floor(numBattleships / Conversions.CORE_TO_CARRIERS) end
            if numCarriers > 0 then
                table.insert(Scenario.Platoons[template], {TIERS[3].CARRIERS[faction], 1, numCarriers, 'guard', 'None'})
                table.insert(children, 'Carrier')
            end
        end

        -- Do nuke subs, only if allowed. Note Seraphim has no nuke sub.
        local numNukeSubs = 0
        if (not allEnabled and IsEnabledType('NukeSubmarine', data)) then
            if tier >= 3 and TIERS[3].NUKESUBS[faction] then numNukeSubs = math.floor(numBattleships / Conversions.CORE_TO_NUKESUBS) end
            if numNukeSubs > 0 then
                table.insert(Scenario.Platoons[template], {TIERS[3].NUKESUBS[faction], 1, numNukeSubs, 'guard', 'None'})
                table.insert(children, 'NukeSubmarine')
            end
        end

        --------------------------------------------
        -- Create the child platoon builder
        --------------------------------------------

        Scenario.Armies.ARMY_1.PlatoonBuilders.Builders['OSB_Child_' .. name .. '_' .. tostring(tier) .. '-' .. tostring(waveLevel)] =
        {
            PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua','DefaultOSBasePatrol',{'default_platoon'},{'default_platoon'}},
            PlatoonTemplate = template,
            --Priority = nPriority+level,
            Priority = BasePriority + tier,
            InstanceCount = 1,
            LocationType = 'MAIN',
            BuildTimeOut = -1,
            PlatoonType = 'Sea',
            RequiresConstruction = true,
            BuildConditions = {
                {
                    '/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                    {'default_brain','default_master'},
                    {'default_brain','default_master'}
                },
                {
                    '/lua/ai/opai/GenerateNaval.lua', 'ChildShouldBuild',
                    {'default_brain','default_master'},
                    {'default_brain','default_master'},
                },
            },
            PlatoonData = {
                {
                    type = 5, name = 'AMPlatoons', value = {
                        {type = 2, name = 'String_0',  value = 'OSB_Master_' .. name},
                        {type = 2, name = 'APPEND_FleetChildren',  value = 'OSB_Master_' .. name},
                    }
                },
            },

            ChildrenType = { unpack(children) },
        }

        --------------------------------------------
        --Increment the number of frigates and continue
        --------------------------------------------

        frigAcc = frigAcc + frigInc
    end

    --------------------------------------------
    -- Create the master platoon builder
    --------------------------------------------
    Scenario.Armies.ARMY_1.PlatoonBuilders.Builders['OSB_Master_' .. name] =
    {
        PlatoonTemplate = 'OST_BLANK_TEMPLATE',
        Priority = BasePriority + 1 + levels,
        InstanceCount = 1,
        LocationType = 'MAIN',
        BuildTimeOut = -1,
        PlatoonType = 'Sea',
        RequiresConstruction = true,
        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua','DefaultOSBasePatrol',{'default_platoon'},{'default_platoon'}},
        BuildConditions = {
            {
                '/lua/editor/amplatoonhelperfunctions.lua', 'AMCheckPlatoonLock',
                {'default_brain','default_master'},
                {'default_brain','default_master'}
            },
            {
                '/lua/ai/opai/GenerateNaval.lua', 'FleetIsBuilt',
                {'default_brain','default_master'},
                {'default_brain','default_master'},
            },
        },
        PlatoonBuildCallbacks = {
            {
                '/lua/editor/amplatoonhelperfunctions.lua', 'AMUnlockPlatoon',
                {'default_brain','default_platoon'},
                {'default_brain','default_platoon'}
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


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- function: FleetIsBuilt = BuildCondition   doc = "Please work function docs."
----
---- parameter 0: string   aiBrain     = "default_brain"
---- parameter 1: string   master     = "default_master"
----
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function FleetIsBuilt(aiBrain, master)
    local fleetCounter = ScenarioFramework.AMPlatoonCounter(aiBrain, master..'_FleetChildren')

    if fleetCounter >= 1 then
        return true
    else
        return false
    end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- function: ChildShouldBuild = BuildCondition   doc = "Please work function docs."
----
---- parameter 0: string   aiBrain     = "default_brain"
---- parameter 1: string   master     = "default_master"
----
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function ChildShouldBuild(aiBrain, master)
    local fleetCounter = ScenarioFramework.AMPlatoonCounter(aiBrain, master..'_FleetChildren')

    if fleetCounter < 1 then
        return true
    else
        return false
    end
end
