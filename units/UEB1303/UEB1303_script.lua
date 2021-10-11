--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB1303/UAB1303_script.lua
--**  Author(s):  Jessica St. Croix, David Tomandl
--**
--**  Summary  :  UEF T3 Mass Fabricator
--**
--**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TMassFabricationUnit = import('/lua/terranunits.lua').TMassFabricationUnit

UEB1303 = Class(TMassFabricationUnit) {

    OnStopBeingBuilt = function(self,builder,layer)
        TMassFabricationUnit.OnStopBeingBuilt(self,builder,layer)
        self.Rotator = CreateRotator(self, 'Spinner', 'z')
        self.Rotator:SetAccel(10)
        self.Rotator:SetTargetSpeed(40)
        self.Trash:Add(self.Rotator)
		self.AmbientEffects = CreateEmitterAtEntity(self, self:GetArmy(), '/effects/emitters/uef_t3_massfab_ambient_01_emit.bp')
		self.Trash:Add(self.AmbientEffects)        
    
    end,
    
    OnProductionPaused = function(self)
        -- guard for eco manager mod
        if self.isFinishedUnit then 
            TMassFabricationUnit.OnProductionPaused(self)
            self.Rotator:SetSpinDown(true)
            if self.AmbientEffects then
                self.AmbientEffects:Destroy()
                self.AmbientEffects = nil
            end
        end            
    end,
    
    OnProductionUnpaused = function(self)
        -- guard for eco manager mod
        if self.isFinishedUnit then 
            TMassFabricationUnit.OnProductionUnpaused(self)
            self.Rotator:SetTargetSpeed(40)
            self.Rotator:SetSpinDown(false)
            self.AmbientEffects = CreateEmitterAtEntity(self, self:GetArmy(), '/effects/emitters/uef_t3_massfab_ambient_01_emit.bp')
            self.Trash:Add(self.AmbientEffects)        
        end  
    end,
}

TypeClass = UEB1303