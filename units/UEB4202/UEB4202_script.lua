#****************************************************************************
#**
#**  File     :  /cdimage/units/UEB4202/UEB4202_script.lua
#**  Author(s):  David Tomandl
#**
#**  Summary  :  UEF Shield Generator Script
#**
#**  Copyright © 20010 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local TShieldStructureUnit = import('/lua/terranunits.lua').TShieldStructureUnit

UEB4202 = Class(TShieldStructureUnit) {
    
    ShieldEffects = {
        '/effects/emitters/terran_shield_generator_t2_01_emit.bp',
        '/effects/emitters/terran_shield_generator_t2_02_emit.bp',
        ###'/effects/emitters/terran_shield_generator_t2_03_emit.bp',
    },
    
    OnStopBeingBuilt = function(self,builder,layer)
        TShieldStructureUnit.OnStopBeingBuilt(self,builder,layer)
        self.Rotator1 = CreateRotator(self, 'Spinner', 'y', nil, 10, 5, 10)
        self.Rotator2 = CreateRotator(self, 'B01', 'z', nil, -10, 5, -10)
        self.Trash:Add(self.Rotator1)
        self.Trash:Add(self.Rotator2)
		self.ShieldEffectsBag = {}
    end,

    OnShieldEnabled = function(self)
        TShieldStructureUnit.OnShieldEnabled(self)
        if self.Rotator1 then
            self.Rotator1:SetTargetSpeed(10)
        end
        if self.Rotator2 then
            self.Rotator2:SetTargetSpeed(-10)
        end
        
        if self.ShieldEffectsBag then
            for k, v in self.ShieldEffectsBag do
                v:Destroy()
            end
		    self.ShieldEffectsBag = {}
		end
        for k, v in self.ShieldEffects do
            table.insert( self.ShieldEffectsBag, CreateAttachedEmitter( self, 0, self:GetArmy(), v ) )
        end
    end,

    OnShieldDisabled = function(self)
        TShieldStructureUnit.OnShieldDisabled(self)
        self.Rotator1:SetTargetSpeed(0)
        self.Rotator2:SetTargetSpeed(0)
        
        if self.ShieldEffectsBag then
            for k, v in self.ShieldEffectsBag do
                v:Destroy()
            end
		    self.ShieldEffectsBag = {}
		end
    end,
    
    UpgradingState = State(TShieldStructureUnit.UpgradingState) {
        Main = function(self)
            self.Rotator1:SetTargetSpeed(90)
            self.Rotator2:SetTargetSpeed(90)
            self.Rotator1:SetSpinDown(true)
            self.Rotator2:SetSpinDown(true)
            TShieldStructureUnit.UpgradingState.Main(self)
        end,
        
        
        EnableShield = function(self)
            TShieldStructureUnit.EnableShield(self)
        end,
        
        DisableShield = function(self)
            TShieldStructureUnit.DisableShield(self)
        end,
    }
    
}

TypeClass = UEB4202