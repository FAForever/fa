--****************************************************************************
--**
--**  File     :  /cdimage/units/URB5102/URB5102_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Cybran Transport Beacon Unit
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CTransportBeaconUnit = import("/lua/cybranunits.lua").CTransportBeaconUnit

---@class URB5102 : CTransportBeaconUnit
URB5102 = ClassUnit(CTransportBeaconUnit) {
}

TypeClass = URB5102