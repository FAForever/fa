--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB1105/UAB1105_script.lua
--**  Author(s):  Jessica St. Croix
--**
--**  Summary  :  Aeon Energy Storage
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SEnergyStorageUnit = import("/lua/seraphimunits.lua").SEnergyStorageUnit

---@class XSB1105 : SEnergyStorageUnit
XSB1105 = ClassUnit(SEnergyStorageUnit) {

    OnStopBeingBuilt = function(self,builder,layer)
        SEnergyStorageUnit.OnStopBeingBuilt(self,builder,layer)
        self.Trash:Add(CreateStorageManip(self, 'B01', 'ENERGY', 0, 0, -0.7, 0, 0, 0))
    end,

}

TypeClass = XSB1105