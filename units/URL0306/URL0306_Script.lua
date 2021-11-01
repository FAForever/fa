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
--import a default weapon so our pointer doesnt explode
local DefaultProjectileWeapon = import('/lua/sim/defaultweapons.lua').DefaultProjectileWeapon

URL0306 = Class(CRadarJammerUnit)({

    Weapons = {
        TargetPointer = Class(DefaultProjectileWeapon)({}),
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

    OnStopBeingBuilt = function(self, builder, layer)
        CRadarJammerUnit.OnStopBeingBuilt(self, builder, layer)
        self.ShieldEffectsBag = {

        }
        --save the pointer weapon for later - this is extra clever since the pointer weapon has to be first!
        self.TargetPointer = self:GetWeapon(1)
        --we save this to the unit table so dont have to call every time.
        self.TargetLayerCaps = self:GetBlueprint().Weapon[1].FireTargetLayerCapsTable
        --a flag to let our thread know whether we should turn on our pointer.
        self.PointerEnabled = true
    end,

    DisablePointer = function(self)
        --this disables the stop feature - note that its reset on layer change!
        self.TargetPointer:SetFireTargetLayerCaps('None')
        self.PointerRestartThread = self:ForkThread(self.PointerRestart)
    end,

    PointerRestart = function(self)
        --sadly i couldnt find some way of doing this without a thread. dont know where to check if its still assisting other than this.
        while self.PointerEnabled == false do
            WaitSeconds(1)
            if not self:GetGuardedUnit() then
                self.PointerEnabled = true
                --this resets the stop feature - note that its reset on layer change!
                self.TargetPointer:SetFireTargetLayerCaps(self.TargetLayerCaps[self.Layer])
            end
        end
    end,

    OnLayerChange = function(self, new, old)
        CRadarJammerUnit.OnLayerChange(self, new, old)

        if self.PointerEnabled == false then
            --since its reset on layer change we need to do this. unfortunate.
            self.TargetPointer:SetFireTargetLayerCaps('None')
        end
    end,
})

TypeClass = URL0306
