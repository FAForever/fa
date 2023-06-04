--****************************************************************************
--**
--**  File     :  /units/XSB5102/XSB5102_script.lua
--**
--**  Summary  :  Transport Beacon Unit
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local STransportBeaconUnit = import("/lua/seraphimunits.lua").STransportBeaconUnit

---@class XSB5102 : STransportBeaconUnit
XSB5102 = ClassUnit(STransportBeaconUnit) {
}

TypeClass = XSB5102