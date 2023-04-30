--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB0101/UEB0101_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Tier 1 Land Factory Script
--**
--**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TLandFactoryUnit = import("/lua/terranunits.lua").TLandFactoryUnit

---@class UEB0101 : TLandFactoryUnit
UEB0101 = ClassUnit(TLandFactoryUnit) {}

TypeClass = UEB0101