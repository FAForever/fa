--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB3101/UEB3101_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Light Radar Installation Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TRadarUnit = import("/lua/terranunits.lua").TRadarUnit

---@class UEB3101 : TRadarUnit
UEB3101 = ClassUnit(TRadarUnit) { }
TypeClass = UEB3101