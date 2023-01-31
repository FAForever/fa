--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB5102/UEB5102_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  UEF Transport Beacon Unit
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TTransportBeaconUnit = import("/lua/terranunits.lua").TTransportBeaconUnit

---@class UEB5102 : TTransportBeaconUnit
UEB5102 = ClassUnit(TTransportBeaconUnit) { }

TypeClass = UEB5102