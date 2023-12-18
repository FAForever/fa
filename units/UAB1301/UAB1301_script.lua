--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB1301/UAB1301_script.lua
--**  Author(s):  John Comes, Dave Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Power Generator Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local AEnergyCreationUnit = import("/lua/aeonunits.lua").AEnergyCreationUnit

-- upvale for perfomance
local TrashBagAdd = TrashBag.Add

---@class UAB1301 : AEnergyCreationUnit
UAB1301 = ClassUnit(AEnergyCreationUnit) {
    AmbientEffects = 'AT3PowerAmbient',

    OnStopBeingBuilt = function(self, builder, layer)
        AEnergyCreationUnit.OnStopBeingBuilt(self, builder, layer)
        local trash = self.Trash

        TrashBagAdd(trash,CreateRotator(self, 'Sphere', 'x', nil, 0, 15, 80 + Random(0, 20)))
        TrashBagAdd(trash,CreateRotator(self, 'Sphere', 'y', nil, 0, 15, 80 + Random(0, 20)))
        TrashBagAdd(trash,CreateRotator(self, 'Sphere', 'z', nil, 0, 15, 80 + Random(0, 20)))
    end,
}

TypeClass = UAB1301