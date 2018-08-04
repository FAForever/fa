#****************************************************************************
#**
#**  File     :  /cdimage/units/UAL0307/UAL0307_script.lua
#**  Author(s):  John Comes, David Tomandl
#**
#**  Summary  :  Aeon Mobile Shield Generator Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AShieldHoverLandUnit = import('/lua/aeonunits.lua').AShieldHoverLandUnit

UAL0307 = Class(AShieldHoverLandUnit) {
    
    ShieldEffects = {
        '/effects/emitters/aeon_shield_generator_mobile_01_emit.bp',
    },
    
    OnStopBeingBuilt = function(self,builder,layer)
        AShieldHoverLandUnit.OnStopBeingBuilt(self,builder,layer)
		self.ShieldEffectsBag = {}
    end,
    
    OnShieldEnabled = function(self)
        AShieldHoverLandUnit.OnShieldEnabled(self)
        if not self.Animator then
            self.Animator = CreateAnimator(self)
            self.Trash:Add(self.Animator)
            self.Animator:PlayAnim(self:GetBlueprint().Display.AnimationOpen)
        end
        self.Animator:SetRate(1)
                
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
        AShieldHoverLandUnit.OnShieldDisabled(self)
        if self.Animator then
            self.Animator:SetRate(-1)
        end
         
        if self.ShieldEffectsBag then
            for k, v in self.ShieldEffectsBag do
                v:Destroy()
            end
		    self.ShieldEffectsBag = {}
		end
    end,


}

TypeClass = UAL0307
