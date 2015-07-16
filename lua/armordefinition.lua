-----------------------------------------------------------------
-- File     :  /lua/armordefinition.lua
-- Author(s):
-- Summary  :
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- Armor Type Definitions
-- Laid out as follows:
--  {   
--      {
--          'Armor Name'
--          'Damage Type - Multiplier'
--      }
--  }
armordefinition = {

    {
        'Default',
        
        'Normal 1.0',
    },
    {
        'Normal',
        
        'Normal 1.0',
    },
    {
        'Light',
        
        'Normal 1.0',
    },
    {
        'Commander',
        
        'Normal 1.0',
        'Overcharge 0.033333',
        'Deathnuke 1.0',
    },
    {
        'Structure',

        'Normal 1.0',
        'Overcharge 0.066666',
        'Deathnuke 0.032',
    },
    {
        'Experimental',

        'ExperimentalFootfall 0.0',        
    },
    {
        'FireBeetle',

        'Normal 1.0',        
        'FireBeetleExplosion 0.0',        
    },
    {

        'ASF',

        'Normal 1.0',        
        'CzarBeam 0.25',
        'OtheTacticalBomb 0.1',   
    },
    {
        'TMD',

        'Normal 1.0',        
        'TacticalMissile 0.55',   
    },
}
