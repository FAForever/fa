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

    -- Toggle disabled
    OnScriptBitSet = function(self, bit)
        if bit == 8 then
            self.Sync.LowPriority = false
        else
            SWalkingLandUnit.OnScriptBitSet(self, bit)
        end
    end,

    -- Toggle enabled
    OnScriptBitClear = function(self, bit)
        if bit == 8 then
            self.Sync.LowPriority = true
        else
            SWalkingLandUnit.OnScriptBitClear(self, bit)
        end
    end,

    RevealUnit = function(self)
        if self.CloakThread then
            KillThread(self.CloakThread)
            self.CloakThread = nil
        end

        self:SetWeaponEnabledByLabel('LaserTurret', true)
        self:SetMaintenanceConsumptionInactive()
        self:DisableUnitIntel('ToggleBit5', 'RadarStealth')
        self:DisableUnitIntel('ToggleBit8', 'Cloak')
    end,

    -- Turn off the cloak to begin with
    OnStopBeingBuilt = function(self, builder, layer)
        SWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetScriptBit('RULEUTC_CloakToggle', true)
        self:RevealUnit()
    end,

    OnMotionHorzEventChange = function(self, new, old)
        if self.Sync.LowPriority then
            -- If we stopped moving, hide
            if new == 'Stopped' then
                -- We need to fork in order to use WaitSeconds
                self.CloakThread = ForkThread(function()
                    WaitSeconds(self:GetBlueprint().Intel.StealthWaitTime)

                    if not self.Dead then
                        self:SetWeaponEnabledByLabel('LaserTurret', false)
                        self:SetMaintenanceConsumptionActive()
                        self:EnableUnitIntel('ToggleBit5', 'RadarStealth')
                        self:EnableUnitIntel('ToggleBit8', 'Cloak')

                        self.CloakThread = nil
                    end
                end)
            end
        end

        -- If we begin moving, reveal ourselves
        if old == 'Stopped' then
            self:RevealUnit()
        end


        SWalkingLandUnit.OnMotionHorzEventChange(self, new, old)
    end,
}

TypeClass = XSL0101
