-- File     :  /cdimage/units/URB1201/URB1201_script.lua
-- Author(s):  John Comes, Dave Tomandl, Jessica St. Croix
-- Summary  :  Cybran Tier 2 Power Generator Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local CEnergyCreationUnit = import("/lua/cybranunits.lua").CEnergyCreationUnit

---@class URB1201 : CEnergyCreationUnit
URB1201 = ClassUnit(CEnergyCreationUnit) {
    AmbientEffects = 'CT2PowerAmbient',
}

TypeClass = URB1201
