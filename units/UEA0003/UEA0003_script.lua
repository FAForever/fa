-----------------------------------------------------------------
-- File     :  /cdimage/units/UEA0003/UEA0003_script.lua
-- Summary  :  UEF sACU Pod Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local TConstructionPodUnit = import("/lua/terranunits.lua").TConstructionPodUnit

---@class UEA0003 : TConstructionPodUnit
UEA0003 = ClassUnit(TConstructionPodUnit) {}

TypeClass = UEA0003