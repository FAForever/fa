-----------------------------------------------------------------
-- File     :  /cdimage/units/UEA0001/UEA0001_script.lua
-- Author(s):  John Comes
-- Summary  :  UEF CDR Pod Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local TConstructionPodUnit = import("/lua/terranunits.lua").TConstructionPodUnit

---@class UEA0001 : TConstructionPodUnit
UEA0001 = ClassUnit(TConstructionPodUnit) {}

TypeClass = UEA0001