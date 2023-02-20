----****************************************************************************
----**
----**  File     :  /cdimage/units/UAB5103/UAB5103_script.lua
----**  Author(s):  John Comes, David Tomandl
----**
----**  Summary  :  Aeon Quantum Gate Beacon Unit
----**
----**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit

---@class UAB5103 : AStructureUnit
UAB5103 = ClassUnit(AStructureUnit) {
    FxTransportBeacon = {'/effects/emitters/red_beacon_light_01_emit.bp'},
    FxTransportBeaconScale = 1,

    OnCreate = function(self)
        AStructureUnit.OnCreate(self)
        for k, v in self.FxTransportBeacon do
            self.Trash:Add(CreateAttachedEmitter(self, 0,self.Army, v):ScaleEmitter(self.FxTransportBeaconScale))
        end
    end,
}

TypeClass = UAB5103
