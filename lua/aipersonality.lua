--****************************************************************************
--**
--**  File     :  /lua/aipersonality.lua
--**  Author(s):
--**
--**  Summary  :
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
----------------------------------------------------------------------------------
-- AIPersonality Lua Module              --
----------------------------------------------------------------------------------

---@class AIPersonality : moho.aipersonality_methods
AIPersonality = Class(moho.aipersonality_methods) {}

AIPersonalityTemplate = {

    -- AverageJoe
    {
        -- Definition of template
        'AverageJoe',
        'None',

        -- Stretegic Overall Values
        { 50,   100, },     -- Army Total Unit Size
        { 1.0,  1.0, },     -- Platoon Size Mult
        { 0.0,  1.0, },     -- Attack Frequency
        { 0.0,  1.0, },     -- Repeat Attack Frequency
        { 0.0,  1.0, },     -- Counter Forces
        { 0.0,  1.0, },     -- Intel Gathering
        { 0.0,  1.0, },     -- Coordinated Attacks
        { 0.0,  1.0, },     -- Expansion Driven
        { 0.0,  1.0, },     -- Tech Advancement
        { 0.0,  1.0, },     -- Upgrades Driven

        -- Strategic Structure Emphasis Values
        { 0.0,  1.0, },     -- Defense Driven
        { 0.0,  1.0, },     -- Economy Driven
        { 0.0,  1.0, },     -- Factory Tycoon
        { 0.0,  1.0, },     -- Intel Building Tycoon
        { 0.0,  1.0, },     -- Super Weapon Tendency
        { },    -- Favourite Structures

        -- Strategic Unit Emphasis Values
        { 0.0,  1.0, },     -- Air Units Emphasis
        { 0.0,  1.0, },     -- Tank Units Emphasis
        { 0.0,  1.0, },     -- Bot Units Emphasis
        { 0.0,  1.0, },     -- Sea Units Emphasis
        { 0.0,  1.0, },     -- Specialty Forces Emphasis
        { 0.0,  1.0, },     -- Support Units Emphasis
        { 0.0,  1.0, },     -- Direct Damage Emphasis
        { 0.0,  1.0, },     -- InDirect Damage Emphasis
        { },    -- Favourite Units

        -- Tactical AI values
        { 0.0,  1.0, },     -- Survival Emphasis
        { 0.0,  1.0, },     -- Team Support
        { 0.0,  1.0, },     -- Formation Use
        { 0.0,  1.0, },     -- Target Spread

        -- Misc Values
        { 0.0,  1.0, },     -- Quitting Tendency
        { 0.0,  1.0, },     -- Chat Frequency
    },

    -- Rommel
    {
        -- Definition of template
        'Rommel',
        'None',

        -- Stretegic Overall Values
        { 100,  200, },     -- Army Total Unit Size
        { 1.0,  2.0, },     -- Platoon Size Mult
        { 0.5,  1.0, },     -- Attack Frequency
        { 0.5,  1.0, },     -- Repeat Attack Frequency
        { 0.5,  0.5, },     -- Counter Forces
        { 0.5,  0.5, },     -- Intel Gathering
        { 0.5,  0.5, },     -- Coordinated Attacks
        { 0.5,  1.0, },     -- Expansion Driven
        { 0.5,  0.5, },     -- Tech Advancement
        { 0.5,  0.5, },     -- Upgrades Driven

        -- Strategic Structure Emphasis Values
        { 0.5,  0.5, },     -- Defense Driven
        { 0.5,  1.0, },     -- Economy Driven
        { 0.5,  1.0, },     -- Factory Tycoon
        { 0.5,  0.5, },     -- Intel Building Tycoon
        { 0.5,  0.5, },     -- Super Weapon Tendency
        { },    -- Favourite Structures

        -- Strategic Unit Emphasis Values
        { 0.1,  0.1, },     -- Air Units Emphasis
        { 1.0,  1.0, },     -- Tank Units Emphasis
        { 0.1,  0.1, },     -- Bot Units Emphasis
        { 0.1,  0.1, },     -- Sea Units Emphasis
        { 0.1,  0.1, },     -- Specialty Forces Emphasis
        { 0.1,  0.5, },     -- Support Units Emphasis
        { 1.0,  1.0, },     -- Direct Damage Emphasis
        { 0.1,  0.5, },     -- InDirect Damage Emphasis
        { },    -- Favourite Units

        -- Tactical AI values
        { 0.5,  0.5, },     -- Survival Emphasis
        { 0.5,  0.5, },     -- Team Support
        { 0.5,  0.5, },     -- Formation Use
        { 0.5,  0.5, },     -- Target Spread

        -- Misc Values
        { 0.5,  0.1, },     -- Quitting Tendency
        { 0.5,  0.5, },     -- Chat Frequency
    },
}
