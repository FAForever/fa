--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB1201/UAB1201_script.lua
--**  Author(s):  John Comes, Dave Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon T2 Power Generator Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local AEnergyCreationUnit = import("/lua/aeonunits.lua").AEnergyCreationUnit

-- upvalue for perfomance
local CreateRotator = CreateRotator
local TrashBagAdd = TrashBag.Add

---@class UAB1201 : AEnergyCreationUnit
UAB1201 = ClassUnit(AEnergyCreationUnit) {
    AmbientEffects = 'AT2PowerAmbient',

    OnStopBeingBuilt = function(self, builder, layer)
        AEnergyCreationUnit.OnStopBeingBuilt(self, builder, layer)
        local trash = self.Trash

        TrashBagAdd(trash,CreateRotator(self, 'Sphere', 'x', nil, 0, 15, 80 + Random(0, 20)))
        TrashBagAdd(trash,CreateRotator(self, 'Sphere', 'y', nil, 0, 15, 80 + Random(0, 20)))
        TrashBagAdd(trash,CreateRotator(self, 'Sphere', 'z', nil, 0, 15, 80 + Random(0, 20)))
    end,
}

TypeClass = UAB1201