--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB1105/UEB1105_script.lua
--**  Author(s):  Jessica St. Croix
--**
--**  Summary  :  UEF Energy Storage
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TEnergyStorageUnit = import("/lua/terranunits.lua").TEnergyStorageUnit

---@class UEB1105 : TEnergyStorageUnit
UEB1105 = ClassUnit(TEnergyStorageUnit) {

    OnCreate = function(self)
        TEnergyStorageUnit.OnCreate(self)
        self.Trash:Add(CreateStorageManip(self, 'B01', 'ENERGY', 0, 0, -0.6, 0, 0, 0))
    end,

}

TypeClass = UEB1105