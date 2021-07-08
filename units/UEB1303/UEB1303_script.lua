--#****************************************************************************
--#**
--#**  File     :  /cdimage/units/UAB1303/UAB1303_script.lua
--#**  Author(s):  Jessica St. Croix, David Tomandl
--#**
--#**  Summary  :  UEF T3 Mass Fabricator
--#**
--#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--#****************************************************************************

local TMassFabricationUnit = import('/lua/terranunits.lua').TMassFabricationUnit

UEB1303 = Class(TMassFabricationUnit) {

    OnCreate = function(self)
        TMassFabricationUnit.OnCreate(self)
		self.Rotator = CreateRotator(self, 'Spinner', 'z')
        self.Trash:Add(self.Rotator)
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        TMassFabricationUnit.OnStopBeingBuilt(self, builder, layer)
        self.Rotator:SetAccel(10)
        self.Rotator:SetTargetSpeed(40)
		self.AmbientEffects = CreateEmitterAtEntity(self, self.Army, '/effects/emitters/uef_t3_massfab_ambient_01_emit.bp')
		self.Trash:Add(self.AmbientEffects)        
    
    end,
    
    OnProductionPaused = function(self)
        TMassFabricationUnit.OnProductionPaused(self)
        self.Rotator:SetSpinDown(true)
		if self.AmbientEffects then
			self.AmbientEffects:Destroy()
			self.AmbientEffects = nil
		end            
    end,
    
    OnProductionUnpaused = function(self)
        TMassFabricationUnit.OnProductionUnpaused(self)
        self.Rotator:SetTargetSpeed(40)
        self.Rotator:SetSpinDown(false)
		self.AmbientEffects = CreateEmitterAtEntity(self, self.Army, '/effects/emitters/uef_t3_massfab_ambient_01_emit.bp')
		self.Trash:Add(self.AmbientEffects)          
    end,
}

TypeClass = UEB1303