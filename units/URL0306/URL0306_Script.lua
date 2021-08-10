--****************************************************************************
--**
--**  File     :  /cdimage/units/URL0306/URL0306_script.lua
--**  Author(s):  Jessica St. Croix
--**
--**  Summary  :  Cybran Mobile Radar Jammer Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CRadarJammerUnit = import('/lua/cybranunits.lua').CRadarJammerUnit
local EffectUtil = import('/lua/EffectUtilities.lua')
local DefaultProjectileWeapon = import('/lua/sim/defaultweapons.lua').DefaultProjectileWeapon --import a default weapon so our pointer doesnt explode

URL0306 = Class(CRadarJammerUnit) {

    Weapons = {        
        TargetPointer = Class(DefaultProjectileWeapon) {},
    },
    
    IntelEffects = {
        {
            Bones = {
                'AttachPoint',
            },
            Offset = {
                0,
                0.3,
                0,
            },
            Scale = 0.2,
            Type = 'Jammer01',
        },
    },
    
    OnStopBeingBuilt = function(self,builder,layer)
        CRadarJammerUnit.OnStopBeingBuilt(self,builder,layer)
        self.ShieldEffectsBag = {}
        
        self.TargetPointer = self:GetWeapon(1) --save the pointer weapon for later - this is extra clever since the pointer weapon has to be first!
        self.TargetLayerCaps = self.Blueprint.Weapon[1].FireTargetLayerCapsTable --we save this to the unit table so dont have to call every time.
        self.PointerEnabled = true --a flag to let our thread know whether we should turn on our pointer.
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
        CRadarJammerUnit.OnLayerChange(self, new, old)
        
        if self.PointerEnabled == false then
            self.TargetPointer:SetFireTargetLayerCaps('None') --since its reset on layer change we need to do this. unfortunate.
        end
    end,
}

TypeClass = URL0306
