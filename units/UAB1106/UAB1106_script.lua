--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB1106/UAB1106_script.lua
--**  Author(s):  Jessica St. Croix, David Tomandl, John Comes
--**
--**  Summary  :  Aeon Mass Storage
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AMassStorageUnit = import("/lua/aeonunits.lua").AMassStorageUnit

---@class UAB1106 : AMassStorageUnit
UAB1106 = ClassUnit(AMassStorageUnit) {

    OnStopBeingBuilt = function(self,builder,layer)
        AMassStorageUnit.OnStopBeingBuilt(self,builder,layer)
        self.Trash:Add(CreateStorageManip(self, 'B01', 'MASS', 0, 0, 0, 0, 0, .41))
    end,

    AnimThread = function(self)
        
    end,
}

TypeClass = UAB1106