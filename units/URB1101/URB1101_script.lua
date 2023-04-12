-- File     :  /cdimage/units/URB1101/URB1101_script.lua
-- Author(s):  John Comes, Dave Tomandl, Jessica St. Croix
-- Summary  :  Cybran Power Generator Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local CEnergyCreationUnit = import("/lua/cybranunits.lua").CEnergyCreationUnit

---@class URB1101 : CEnergyCreationUnit
URB1101 = ClassUnit(CEnergyCreationUnit) { }

TypeClass = URB1101