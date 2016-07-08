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

    -- Set custom flag and add Stealth and Cloak toggles to the switch
    OnScriptBitSet = function(self, bit)
        if bit == 8 then
            if self.CloakThread then
                KillThread(self.CloakThread)
                self.CloakThread = nil
            end

            self.HiddenSelen = false
            self:SetFireState(0)
            self:SetMaintenanceConsumptionInactive()
            self:DisableUnitIntel('ToggleBit5', 'RadarStealth')
            self:DisableUnitIntel('ToggleBit8', 'Cloak')
            
            if not self.MaintenanceConsumption then
                self.ToggledOff = true
            end
        else
            SWalkingLandUnit.OnScriptBitSet(self, bit)
        end
    end,

    OnScriptBitClear = function(self, bit)
        if bit == 8 then
            if not self.CloakThread then
                self.CloakThread = ForkThread(function()
                    WaitSeconds(1)

                    self.HiddenSelen = true
                    self:SetFireState(1)
                    self:SetMaintenanceConsumptionActive()
                    self:EnableUnitIntel('ToggleBit5', 'RadarStealth')
                    self:EnableUnitIntel('ToggleBit8', 'Cloak')

                    IssueStop({self})
                    IssueClearCommands({self})

                    if self.MaintenanceConsumption then
                        self.ToggledOff = false
                    end
                end)
            end

            -- This sends one stop, to force the unit to a halt etc
            IssueStop({self})
            IssueClearCommands({self})
        else
            SWalkingLandUnit.OnScriptBitClear(self, bit)
        end
    end,

    -- Turn off the cloak to begin with
    OnStopBeingBuilt = function(self, builder, layer)
        SWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetScriptBit('RULEUTC_CloakToggle', true)
    end,

    OnMotionHorzEventChange = function(self, new, old)
        if new ~= 'Stopped' and not self:IsIdleState() and self.HiddenSelen then
            self:SetScriptBit('RULEUTC_CloakToggle', true)
        end

        SWalkingLandUnit.OnMotionHorzEventChange(self, new, old)
    end,
}

TypeClass = XSL0101
