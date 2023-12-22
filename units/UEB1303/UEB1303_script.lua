--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB1303/UAB1303_script.lua
--**  Author(s):  Jessica St. Croix, David Tomandl
--**
--**  Summary  :  UEF T3 Mass Fabricator
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TMassFabricationUnit = import("/lua/terranunits.lua").TMassFabricationUnit

-- Upvalue for perfomance
local CreateRotator = CreateRotator
local CreateEmitterAtEntity = CreateEmitterAtEntity
local TrashBagAdd = TrashBag.Add

---@class UEB1303 : TMassFabricationUnit
UEB1303 = ClassUnit(TMassFabricationUnit) {

    OnStopBeingBuilt = function(self,builder,layer)
        TMassFabricationUnit.OnStopBeingBuilt(self,builder,layer)
        local rotator = self.Rotator
        local army = self.Army
        local trash = self.Trash
        local ambientEffects = self.AmbientEffects

        rotator = CreateRotator(self, 'Spinner', 'z')
        rotator:SetAccel(10)
        rotator:SetTargetSpeed(40)
        TrashBagAdd(trash, rotator)
		ambientEffects = CreateEmitterAtEntity(self, army, '/effects/emitters/uef_t3_massfab_ambient_01_emit.bp')
		TrashBagAdd(trash,ambientEffects)
    end,

    OnProductionPaused = function(self)
        TMassFabricationUnit.OnProductionPaused(self)
        local rotator = self.Rotator
        local ambientEffects = self.AmbientEffects

        rotator:SetSpinDown(true)
		if ambientEffects then
			ambientEffects:Destroy()
			ambientEffects = nil
		end
    end,

    OnProductionUnpaused = function(self)
        TMassFabricationUnit.OnProductionUnpaused(self)
        local rotator = self.Rotator
        local army = self.Army
        local ambientEffects = self.AmbientEffects
        local trash = self.Trash

        rotator:SetTargetSpeed(40)
        rotator:SetSpinDown(false)
		ambientEffects = CreateEmitterAtEntity(self, army, '/effects/emitters/uef_t3_massfab_ambient_01_emit.bp')
		TrashBagAdd(trash,ambientEffects)          
    end,
}

TypeClass = UEB1303