--****************************************************************************
--**
--**  File     :  /cdimage/units/XSS0201/XSS0201_script.lua
--**  Author(s):  Greg Kohne, Gordon Duclos, Aaron Lundquist
--**
--**  Summary  :  Seraphim Destroyer Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SSubUnit = import('/lua/seraphimunits.lua').SSubUnit
local SeraphimWeapons = import('/lua/seraphimweapons.lua')
local SDFUltraChromaticBeamGenerator = SeraphimWeapons.SDFUltraChromaticBeamGenerator02
local SANAnaitTorpedo = SeraphimWeapons.SANAnaitTorpedo
local SDFAjelluAntiTorpedoDefense = SeraphimWeapons.SDFAjelluAntiTorpedoDefense

XSS0201 = Class(SSubUnit) {
    BackWakeEffect = {},
    Weapons = {
        FrontTurret = Class(SDFUltraChromaticBeamGenerator) {},
        BackTurret = Class(SDFUltraChromaticBeamGenerator) {},
        Torpedo1 = Class(SANAnaitTorpedo) {},
        AntiTorpedo = Class(SDFAjelluAntiTorpedoDefense) {},
    },

    OnKilled = function(self, instigator, type, overkillRatio)
        local wep1 = self:GetWeaponByLabel('FrontTurret')
        local bp1 = wep1:GetBlueprint()
        if bp1.Audio.BeamStop then
            wep1:PlaySound(bp1.Audio.BeamStop)
        end
        if bp1.Audio.BeamLoop and wep1.Beams[1].Beam then
            wep1.Beams[1].Beam:SetAmbientSound(nil, nil)
        end
        for k, v in wep1.Beams do
            v.Beam:Disable()
        end

        local wep2 = self:GetWeaponByLabel('BackTurret')
        local bp2 = wep2:GetBlueprint()
        if bp2.Audio.BeamStop then
            wep2:PlaySound(bp2.Audio.BeamStop)
        end
        if bp2.Audio.BeamLoop and wep2.Beams[1].Beam then
            wep2.Beams[1].Beam:SetAmbientSound(nil, nil)
        end
        for k, v in wep2.Beams do
            v.Beam:Disable()
        end

        SSubUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

    OnMotionVertEventChange = function(self, new, old)
        SSubUnit.OnMotionVertEventChange(self, new, old)
        if new == 'Top' then
            self:SetWeaponEnabledByLabel('FrontTurret', true)
            self:SetWeaponEnabledByLabel('BackTurret', true)
        elseif new == 'Down' then
            self:SetWeaponEnabledByLabel('FrontTurret', false)
            self:SetWeaponEnabledByLabel('BackTurret', false)
        end
    end,

    OnStopBeingBuilt = function(self, builer, layer)
        SSubUnit.OnStopBeingBuilt(self, builer, layer)

        --- Unless we're gifted, we should have an original builder.
        --- Remains to be seen if this property is actually copied during gift
        if self.originalBuilder then
            IssueDive({self})
        end
    end
}
TypeClass = XSS0201
