-- ****************************************************************************
-- **
-- **  File     :  /lua/defaultunits.lua
-- **  Author(s):  John Comes, Gordon Duclos
-- **
-- **  Summary  :  Default definitions of units
-- **
-- **  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************


-- This entire section is for factory fixes from CBFP.  If no workie, just remove everything below this line to restore
local FactoryFixes = import('/lua/FactoryFixes.lua').FactoryFixes

-- The altered factory unit class would be ideal except that it doesn't work. The code in this file gets appended at
-- the end to the existing file from stock FA. Because the air, ground and naval factory classes are generated before
-- this script is even executed the altered factory class won't be used. I can ofcourse re-generate the factory
-- classes but that will affect already loaded mods that change this code aswell. So the best sollution to the problem
-- is to apply the bug fix that was originally meant to go in the factory unit class to each dedicated factory class.

---------------------------------------------------------------
--  FACTORY  UNITS
---------------------------------------------------------------
FactoryUnit = FactoryFixes(FactoryUnit)

---------------------------------------------------------------
--  AIR FACTORY UNITS
---------------------------------------------------------------
AirFactoryUnit = FactoryFixes(AirFactoryUnit)

---------------------------------------------------------------
--  LAND FACTORY UNITS
---------------------------------------------------------------
LandFactoryUnit = FactoryFixes(LandFactoryUnit)

---------------------------------------------------------------
--  SEA FACTORY UNITS
---------------------------------------------------------------
SeaFactoryUnit = FactoryFixes(SeaFactoryUnit)
