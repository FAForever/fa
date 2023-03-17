----****************************************************************************
----**
----**  File     :  /cdimage/units/URB5103/URB5103_script.lua
----**  Author(s):  John Comes, David Tomandl
----**
----**  Summary  :  Cybran Quantum Gate Beacon Unit
----**
----**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local CStructureUnit = import("/lua/cybranunits.lua").CStructureUnit

---@class URB5103 : CStructureUnit
URB5103 = ClassUnit(CStructureUnit) {
    FxTransportBeacon = {'/effects/emitters/red_beacon_light_01_emit.bp'},
    FxTransportBeaconScale = 1,

    OnCreate = function(self)
        CStructureUnit.OnCreate(self)
        for k, v in self.FxTransportBeacon do
            self.Trash:Add(CreateAttachedEmitter(self, 0, self.Army, v):ScaleEmitter(self.FxTransportBeaconScale))
        end
    end,
}

TypeClass = URB5103
