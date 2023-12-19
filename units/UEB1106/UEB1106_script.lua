--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB1106/UEB1106_script.lua
--**  Author(s):  Jessica St. Croix
--**
--**  Summary  :  UEF Mass Storage
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TMassStorageUnit = import("/lua/terranunits.lua").TMassStorageUnit

-- upvalue for perfomance
local TrashBagAdd = TrashBag.Add

---@class UEB1106 : TMassStorageUnit
UEB1106 = ClassUnit(TMassStorageUnit) {

    OnStopBeingBuilt = function(self,builder,layer)
        TMassStorageUnit.OnStopBeingBuilt(self,builder,layer)
        local trash = self.Trash
        TrashBagAdd(trash,CreateStorageManip(self, 'Block', 'MASS', 0, 0, -0.3, 0, 0, 0))
    end,
}

TypeClass = UEB1106