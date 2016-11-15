-----------------------------------------------------------------
-- File     :  /cdimage/units/XSL0101/XSL0101_script.lua
-- Summary  :  Seraphim Land Scout Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local SWalkingLandUnit = import('/lua/seraphimunits.lua').SWalkingLandUnit
local SDFPhasicAutoGunWeapon = import('/lua/seraphimweapons.lua').SDFPhasicAutoGunWeapon

XSL0101 = Class(SWalkingLandUnit) {
    Weapons = {
		LaserTurret = Class(SDFPhasicAutoGunWeapon) {
            OnWeaponFired = function(self)
                self.unit:RevealUnit()

                -- Each time we fire, reveal cancels CloakThread so we only cloak after firing is over
                -- Messy, but can't use weapon IdleState because it's called during and immediately after
                -- construction, and before motion events
                self.unit.CloakThread = self.unit:ForkThread(self.unit.HideUnit)
            end,
        },
    },

    -- Toggle disabled
    OnScriptBitSet = function(self, bit)
        if bit == 8 then
            self.Sync.LowPriority = false
            self:SetWeaponEnabledByLabel('LaserTurret', true)
        else
            SWalkingLandUnit.OnScriptBitSet(self, bit)
        end
    end,

    -- Toggle enabled
    OnScriptBitClear = function(self, bit)
        if bit == 8 then
            self.Sync.LowPriority = true
            self:SetWeaponEnabledByLabel('LaserTurret', false)
        else
            SWalkingLandUnit.OnScriptBitClear(self, bit)
        end
    end,

    RevealUnit = function(self)
        if self.CloakThread then
            KillThread(self.CloakThread)
            self.CloakThread = nil
        end

        -- Ensure weapon state
        self:SetWeaponEnabledByLabel('LaserTurret', true)
        
        -- Toggle stealth off
        self:SetMaintenanceConsumptionInactive()
        self:DisableUnitIntel('ToggleBit5', 'RadarStealth')
        self:DisableUnitIntel('ToggleBit8', 'Cloak')
    end,

    HideUnit = function(self)
        if not self.Dead and self:GetFractionComplete() == 1 then
            WaitSeconds(self:GetBlueprint().Intel.StealthWaitTime)

            if self:IsMoving() then return end

            -- Ensure weapon state
            if self.Sync.LowPriority then
                self:SetWeaponEnabledByLabel('LaserTurret', false)
            end

            -- Toggle stealth on
            self:SetMaintenanceConsumptionActive()
            self:EnableUnitIntel('ToggleBit5', 'RadarStealth')
            self:EnableUnitIntel('ToggleBit8', 'Cloak')

            self.CloakThread = nil
        end
    end,

    -- Turn off the cloak to begin with
    OnStopBeingBuilt = function(self, builder, layer)
        SWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetScriptBit('RULEUTC_CloakToggle', true)
        self:ForkThread(self.HideUnit)
    end,

    OnMotionHorzEventChange = function(self, new, old)
        -- If we stopped moving, hide
        if new == 'Stopped' then
            -- We need to fork in order to use WaitSeconds
            self.CloakThread = self:ForkThread(self.HideUnit)
        end

        -- If we begin moving, reveal ourselves
        if old == 'Stopped' then
            self:RevealUnit()
        end

        SWalkingLandUnit.OnMotionHorzEventChange(self, new, old)
    end,
}

TypeClass = XSL0101
