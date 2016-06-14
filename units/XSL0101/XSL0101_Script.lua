-----------------------------------------------------------------
-- File     :  /cdimage/units/XSL0101/XSL0101_script.lua
-- Summary  :  Seraphim Land Scout Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local SWalkingLandUnit = import('/lua/seraphimunits.lua').SWalkingLandUnit
local SDFPhasicAutoGunWeapon = import('/lua/seraphimweapons.lua').SDFPhasicAutoGunWeapon

XSL0101 = Class(SWalkingLandUnit) {
    Weapons = {
		LaserTurret = Class(SDFPhasicAutoGunWeapon) {},
    },

    -- Set custom flag and add Stealth toggles to the cloak switch
    OnScriptBitSet = function(self, bit)
        SWalkingLandUnit.OnScriptBitSet(self, bit)
        if bit == 8 then
            self.HiddenSelen = false
            self:SetWeaponEnabledByLabel('LaserTurret', true)
            self:DisableUnitIntel('ToggleBit5', 'RadarStealth')
            self:DisableUnitIntel('ToggleBit5', 'RadarStealthField')
            self:DisableUnitIntel('ToggleBit5', 'SonarStealth')
            self:DisableUnitIntel('ToggleBit5', 'SonarStealthField')
        end
    end,

    OnScriptBitClear = function(self, bit)
        SWalkingLandUnit.OnScriptBitClear(self, bit)
        if bit == 8 then
            self.HiddenSelen = true
            self:SetWeaponEnabledByLabel('LaserTurret', false)
            self:EnableUnitIntel('ToggleBit5', 'RadarStealth')
            self:EnableUnitIntel('ToggleBit5', 'RadarStealthField')
            self:EnableUnitIntel('ToggleBit5', 'SonarStealth')
            self:EnableUnitIntel('ToggleBit5', 'SonarStealthField')
            
            IssueStop({self})
        end
    end,
    
    -- Turn off the cloak to begin with
    OnStopBeingBuilt = function(self, builder, layer)
        SWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetScriptBit('RULEUTC_CloakToggle', true)
    end,
    
    OnMotionHorzEventChange = function(self, new, old)
        if new ~= 'Stopped' and self.HiddenSelen then
            self:SetScriptBit('RULEUTC_CloakToggle', true)
        end
        SWalkingLandUnit.OnMotionHorzEventChange(self, new, old)
    end,
}
TypeClass = XSL0101