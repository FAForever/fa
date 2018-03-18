#***************************************************************************
#*
#**  File     :  /lua/ai/AIBaseTemplates/TurtleExpansion.lua
#**
#**  Summary  : Manage engineers for a location
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'UvesoExpansionNaval',
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
        -- ==== Factory ==== --
        -----------------------------------------------------------------------------
        -- Build Land/Air/Naval Factories
        'FactoryBuilders Uveso',
        -- Upgrade Factories TECH1->TECH2 and TECH2->TECH3
        'FactoryUpgradeBuilders Uveso',

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


        -----------------------------------------------------------------------------
        -- ==== Defenses BUILDER ==== --
        -----------------------------------------------------------------------------

        
    },

    BaseSettings = {
        FactoryCount = {
            Land = 0,
            Air = 0,
            Sea = 2,
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
        --LOG('*** E-ExpansionFunction: personality: [ '..personality..' ] - markerType: [ '..markerType..' ] - Uveso ExpansionNaval.lua')
        if personality == 'UvesoReflectiveFull' then
            if markerType == 'Naval Area' then
                --LOG('### E-ExpansionFunction: personality: [ '..personality..' ] - markerType: [ '..markerType..' ] - Uveso ExpansionNaval.lua')
                return 1000, 'UvesoExpansionNaval'
            end
        else
            if markerType ~= 'Start Location'
            and markerType ~= 'Expansion Area'
            and markerType ~= 'Large Expansion Area'
            and markerType ~= 'Naval Area'
            then
                LOG('---- E-ExpansionFunction: UNKNOWN EXPANSION TYPE! personality: [ '..personality..' ] - markerType: [ '..markerType..' ] - Uveso ExpansionNaval.lua')
            end
        end
        return -1
    end,
}
