--****************************************************************************
--**
--**  File     :  /units/XSL0307/XSL0307_script.lua
--**
--**  Summary  :  Seraphim Mobile Shield Generator Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SShieldHoverLandUnit = import("/lua/seraphimunits.lua").SShieldHoverLandUnit
local DefaultProjectileWeapon = import("/lua/sim/defaultweapons.lua").DefaultProjectileWeapon --import a default weapon so our pointer doesnt explode

---@class XSL0307 : SShieldHoverLandUnit
XSL0307 = Class(SShieldHoverLandUnit) {
    
    Weapons = {        
        TargetPointer = Class(DefaultProjectileWeapon) {},
    },
    
    ShieldEffects = {
        '/effects/emitters/aeon_shield_generator_mobile_01_emit.bp',
    },
    
    OnStopBeingBuilt = function(self,builder,layer)
        SShieldHoverLandUnit.OnStopBeingBuilt(self,builder,layer)
        self.ShieldEffectsBag = {}
        
        self.TargetPointer = self:GetWeapon(1) --save the pointer weapon for later - this is extra clever since the pointer weapon has to be first!
        self.TargetLayerCaps = self:GetBlueprint().Weapon[1].FireTargetLayerCapsTable --we save this to the unit table so dont have to call every time.
        self.PointerEnabled = true --a flag to let our thread know whether we should turn on our pointer.
    end,
    
    OnShieldEnabled = function(self)
        SShieldHoverLandUnit.OnShieldEnabled(self)
                
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
        SShieldHoverLandUnit.OnShieldDisabled(self)
         
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

            -- break if we're a gooner
            if IsDestroyed(self) or IsDestroyed(self.TargetPointer) then 
                break 
            end

            if not self:GetGuardedUnit() then
                self.PointerEnabled = true
                self.TargetPointer:SetFireTargetLayerCaps(self.TargetLayerCaps[self.Layer]) --this resets the stop feature - note that its reset on layer change!
            end
        end
    end,
    
    OnLayerChange = function(self, new, old)
        SShieldHoverLandUnit.OnLayerChange(self, new, old)
        
        if not IsDestroyed(self.TargetPointer) then
            if self.PointerEnabled == false then
                self.TargetPointer:SetFireTargetLayerCaps('None') --since its reset on layer change we need to do this. unfortunate.
            end
        end
    end,
}

TypeClass = XSL0307
