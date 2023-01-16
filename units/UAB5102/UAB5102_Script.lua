--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB5102/UAB5102_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Aeon Transport Beacon Unit
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local ATransportBeaconUnit = import("/lua/aeonunits.lua").ATransportBeaconUnit

---@class UAB5102 : ATransportBeaconUnit
UAB5102 = ClassUnit(ATransportBeaconUnit) {
}

TypeClass = UAB5102