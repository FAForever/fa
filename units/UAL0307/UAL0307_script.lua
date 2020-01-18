--****************************************************************************
--**
--**  File     :  /cdimage/units/UAL0307/UAL0307_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Aeon Mobile Shield Generator Script
--**
--**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AShieldHoverLandUnit = import('/lua/aeonunits.lua').AShieldHoverLandUnit
local DefaultProjectileWeapon = import('/lua/sim/defaultweapons.lua').DefaultProjectileWeapon --import a default weapon so our pointer doesnt explode

UAL0307 = Class(AShieldHoverLandUnit) {
    
    Weapons = {        
        TargetPointer = Class(DefaultProjectileWeapon) {},
    },
    
    ShieldEffects = {
        '/effects/emitters/aeon_shield_generator_mobile_01_emit.bp',
    },
    
    OnStopBeingBuilt = function(self,builder,layer)
        AShieldHoverLandUnit.OnStopBeingBuilt(self,builder,layer)
        self.ShieldEffectsBag = {}
        
        self.TargetPointer = self:GetWeapon(1) --save the pointer weapon for later - this is extra clever since the pointer weapon has to be first!
        self.TargetLayerCaps = self:GetBlueprint().Weapon[1].FireTargetLayerCapsTable --we save this to the unit table so dont have to call every time.
        self.PointerEnabled = true --a flag to let our thread know whether we should turn on our pointer.
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
            table.insert( self.ShieldEffectsBag, CreateAttachedEmitter( self, 0, self.Army, v ) )
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
    
    DisablePointer = function(self)
        self.TargetPointer:SetFireTargetLayerCaps('None') --this disables the stop feature - note that its reset on layer change!
        self.PointerRestartThread = self:ForkThread( self.PointerRestart )
    end,
    
    PointerRestart = function(self)
    --sadly i couldnt find some way of doing this without a thread. dont know where to check if its still assisting other than this.
        while self.PointerEnabled == false do
            WaitSeconds(1)
            if not self:GetGuardedUnit() then
                self.PointerEnabled = true
                self.TargetPointer:SetFireTargetLayerCaps(self.TargetLayerCaps[self:GetCurrentLayer()]) --this resets the stop feature - note that its reset on layer change!
            end
        end
    end,
    
    OnLayerChange = function(self, new, old)
        AShieldHoverLandUnit.OnLayerChange(self, new, old)
        
        if self.PointerEnabled == false then
            self.TargetPointer:SetFireTargetLayerCaps('None') --since its reset on layer change we need to do this. unfortunate.
        end
    end,
}

TypeClass = UAL0307
