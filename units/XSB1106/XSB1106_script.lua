--****************************************************************************
--**
--**  File     :  /cdimage/units/XSB1106/XSB1106_script.lua
--**  Author(s):  Dru Staltman
--**
--**  Summary  :  Seraphim Mass Storage
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SMassStorageUnit = import("/lua/seraphimunits.lua").SMassStorageUnit

---@class XSB1106 : SMassStorageUnit
XSB1106 = ClassUnit(SMassStorageUnit) {

    OnStopBeingBuilt = function(self,builder,layer)
        SMassStorageUnit.OnStopBeingBuilt(self,builder,layer)
        self.Trash:Add(CreateStorageManip(self, 'B01', 'MASS', 0, 0, -0.75, 0, 0, 0))
    end,
}

TypeClass = XSB1106