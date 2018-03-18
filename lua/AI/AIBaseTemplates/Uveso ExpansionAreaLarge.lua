#***************************************************************************
#*
#**  File     :  /lua/ai/AIBaseTemplates/TurtleExpansion.lua
#**
#**  Summary  : Manage engineers for a location
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'UvesoExpansionAreaLarge',
    Builders = {
        -----------------------------------------------------------------------------
        -- ==== Engineer ==== --
        -----------------------------------------------------------------------------
        -- Build Engineers Tech 1,2,3 and SACU
        'EngineerFactoryBuilders Uveso',            -- Priority = 900
        -- Assistees
        'Assistees Uveso',
        -- Transfers Engineers from LocatonType (Expansions, Firebase etc.) to mainbase
        'Engineer Transfer To MainBase', -- Need to be in Expansion Template

        -----------------------------------------------------------------------------
        -- ==== Energy ==== --
        -----------------------------------------------------------------------------
        -- Build Power Tech 1,2,3
        'EnergyBuilders Uveso',                       -- Priority = 1100

        -----------------------------------------------------------------------------
        -- ==== Factory ==== --
        -----------------------------------------------------------------------------
        -- Build Land/Air/Naval Factories
        'FactoryBuilders Uveso',
        'GateConstruction Uveso',
        -- Upgrade Factories TECH1->TECH2 and TECH2->TECH3
        'FactoryUpgradeBuilders Uveso',

        -----------------------------------------------------------------------------
        -- ==== Land Units BUILDER ==== --
        -----------------------------------------------------------------------------
        -- Build T1 Land Arty
        'LandAttackBuilders Uveso',

        -----------------------------------------------------------------------------
        -- ==== Land Units FORMER==== --
        -----------------------------------------------------------------------------
        'Land FormBuilders',
        
        -----------------------------------------------------------------------------
        -- ==== Air Units BUILDER ==== --
        -----------------------------------------------------------------------------
        -- Build as much antiair as the enemy has
        'AntiAirBuilders Uveso',
        -- Build Air Transporter
        'Air Transport Builder Uveso',

        -----------------------------------------------------------------------------
        -- ==== Air Units FORMER==== --
        -----------------------------------------------------------------------------
        'Air FormBuilders',

        -----------------------------------------------------------------------------
        -- ==== EXPERIMENTALS BUILDER ==== --
        -----------------------------------------------------------------------------
        --'Mobile Experimental Builder Uveso',
        'Economic Experimental Builder Uveso',
        'ExperimentalAttackFormBuilders Uveso',

        -----------------------------------------------------------------------------
        -- ==== Structure Shield BUILDER ==== --
        -----------------------------------------------------------------------------
        'Shields Uveso',
        'ShieldUpgrades Uveso',

        -----------------------------------------------------------------------------
        -- ==== Defenses BUILDER ==== --
        -----------------------------------------------------------------------------
        'Tactical Missile Launcher minimum Uveso',
        'Tactical Missile Launcher TacticalAISorian Uveso',
        'Tactical Missile Defenses Uveso',
--        'Strategic Missile Launcher Uveso',
--        'Strategic Missile Launcher NukeAI Uveso',
        'Strategic Missile Defense Uveso',
        'Strategic Missile Defense SetAutoMode Uveso',
        -- Build Anti Air near AirFactories
        'Base Anti Air Defense Uveso',


        -- We need this even if we have Omni View to get target informations for experimentals attack.
        -----------------------------------------------------------------------------
        -- ==== Scout BUILDER ==== --
        -----------------------------------------------------------------------------
        'ScoutBuilder Uveso',

        -----------------------------------------------------------------------------
        -- ==== Scout FORMER ==== --
        -----------------------------------------------------------------------------
        'ScoutFormer Uveso',

        -----------------------------------------------------------------------------
        -- ==== Intel/CounterIntel BUILDER ==== --
        -----------------------------------------------------------------------------
        'RadarUpgrade Uveso',
        
        'CounterIntelBuilders',

    },
    -- We need intel in case the commander is dead.
    NonCheatBuilders = {

    },

    BaseSettings = {
        FactoryCount = {
            Land = 1,
            Air = 1,
            Sea = 1,
            Gate = 0,
        },
        EngineerCount = {
            Tech1 = 1,
            Tech2 = 1,
            Tech3 = 1,
            SCU = 0,
        },
        MassToFactoryValues = {
            T1Value = 6,
            T2Value = 15,
            T3Value = 22.5
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        if not aiBrain.Uveso then
            return 0
        end
        local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        --LOG('*** E-ExpansionFunction: personality: [ '..personality..' ] - markerType: [ '..markerType..' ] - Uveso ExpansionAreaLarge.lua')
        if personality == 'UvesoReflectiveFull' then
            if markerType == 'Large Expansion Area' then
                --LOG('### E-ExpansionFunction: personality: [ '..personality..' ] - markerType: [ '..markerType..' ] - Uveso ExpansionAreaLarge.lua')
                return 1000, 'UvesoExpansionArea'
            end
        else
            if markerType ~= 'Start Location'
            and markerType ~= 'Expansion Area'
            and markerType ~= 'Large Expansion Area'
            and markerType ~= 'Naval Area'
            then
                LOG('---- E-ExpansionFunction: UNKNOWN EXPANSION TYPE! personality: [ '..personality..' ] - markerType: [ '..markerType..' ] - Uveso ExpansionAreaLarge.lua')
            end
        end
        return -1
    end,
}
