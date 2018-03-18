#***************************************************************************
#*
#**  File     :  /lua/ai/AIBaseTemplates/NormalMain.lua
#**
#**  Summary  : Manage engineers for a location
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'UvesoMainBase',
    Builders = {
        -----------------------------------------------------------------------------
        -- ==== ACU ==== --
        -----------------------------------------------------------------------------
        -- Build Main Base (only once). Land/Air factory and basic Energy
        'Initial ACU Builders Uveso',               -- Priority = 1000

        -----------------------------------------------------------------------------
        -- ==== Expansion Builders ==== --
        -----------------------------------------------------------------------------
        -- Build an Expansion
        'U1 Expansion Builder Uveso',

        -----------------------------------------------------------------------------
        -- ==== SCU ==== --
        -----------------------------------------------------------------------------

        -----------------------------------------------------------------------------
        -- ==== Engineer ==== --
        -----------------------------------------------------------------------------
        -- Build Engineers Tech 1,2,3 and SACU
        'EngineerFactoryBuilders Uveso',            -- Priority = 900
        -- Assistees
        'Assistees Uveso',

        -----------------------------------------------------------------------------
        -- ==== Mass ==== --
        -----------------------------------------------------------------------------
        -- Build MassExtractors / Creators
        'MassBuilders Uveso',                           -- Priority = 1100
        -- Upgrade MassExtractors from Tech 1 to 2 AND from Tech 2 to 3
        'ExtractorUpgrades Uveso',                      -- Priority = 1100
        -- Build Mass Storage (Adjacency)
        'MassStorageBuilder Uveso',                     -- Priority = 1100

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
        'FactoryBuilders Uveso',
        'GateConstruction Uveso',
        -- Upgrade Factories TECH1->TECH2 and TECH2->TECH3
        'FactoryUpgradeBuilders Uveso',
        -- Build Air Staging Platform to refill and repair air units.
        'Air Staging Platform Uveso',
        
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
        -- ==== Sea Units BUILDER ==== --
        -----------------------------------------------------------------------------
        -- Build Naval Units
        'SeaFactoryBuilders Uveso',

        -----------------------------------------------------------------------------
        -- ==== Sea Units FORMER ==== --
        -----------------------------------------------------------------------------
        'SeaAttack FormBuilders Uveso',

        -----------------------------------------------------------------------------
        -- ==== EXPERIMENTALS BUILDER ==== --
        -----------------------------------------------------------------------------
        'Mobile Experimental Builder Uveso',
        'Economic Experimental Builder Uveso',

        -----------------------------------------------------------------------------
        -- ==== EXPERIMENTALS FORMER ==== --
        -----------------------------------------------------------------------------
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
        'Tactical Missile Launcher Maximum Uveso',
        'Tactical Missile Launcher TacticalAISorian Uveso',
        'Tactical Missile Defenses Uveso',
        'Strategic Missile Launcher Uveso',
        'Strategic Missile Launcher NukeAI Uveso',
        'Strategic Missile Defense Uveso',
        'Strategic Missile Defense SetAutoMode Uveso',
        -- Build Anti Air near AirFactories
        'Base Anti Air Defense Uveso',

        

        # ==== ARTILLERY BUILDERS ==== #
--        'SorianT3ArtilleryGroup',
--        'SorianExperimentalArtillery',
--        'SorianSatelliteExperimentalEngineers',
--        'SorianSatelliteExperimentalForm',

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
        'RadarBuilders Uveso',
        'RadarUpgrade Uveso',
        
        'CounterIntelBuilders',
        
        'AeonOpticsEngineerBuilders',
        'CybranOpticsEngineerBuilders',

    },
    -- Not used by Uveso's AI. We always need intel in case the commander is dead.
    NonCheatBuilders = {

    },

    BaseSettings = {
        FactoryCount = {
            Land = 5,
            Air = 5,
            Sea = 2,
            Gate = 1,
        },
        EngineerCount = {
            Tech1 = 10,
            Tech2 = 2,
            Tech3 = 4,
            SCU = 1,
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
        --LOG('*** E-ExpansionFunction: personality: [ '..personality..' ] - markerType: [ '..markerType..' ] - Uveso MainBase.lua')
        if personality == 'UvesoReflectiveFull' then
            --LOG('### E-ExpansionFunction: personality: [ '..personality..' ] - markerType: [ '..markerType..' ] - Uveso MainBase.lua')
            return -1
        else
            if markerType ~= 'Start Location'
            and markerType ~= 'Expansion Area'
            and markerType ~= 'Large Expansion Area'
            and markerType ~= 'Naval Area'
            then
                LOG('---- E-ExpansionFunction: UNKNOWN EXPANSION TYPE! personality: [ '..personality..' ] - markerType: [ '..markerType..' ] - Uveso MainBase.lua')
            end
        end
        return -1
    end,
    FirstBaseFunction = function(aiBrain)
        local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if personality == 'uveso' or personality == 'uvesocheat' then
            --LOG('### M-FirstBaseFunction '..personality)
            return 1000, 'UvesoReflectiveFull'
        end
        return -1
    end,
}
