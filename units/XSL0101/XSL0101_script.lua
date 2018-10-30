-----------------------------------------------------------------
-- File     :  /cdimage/units/XSL0101/XSL0101_script.lua
-- Summary  :  Seraphim Land Scout Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local SWalkingLandUnit = import('/lua/seraphimunits.lua').SWalkingLandUnit
local HiderUnit = import('/lua/defaultunits.lua').HiderUnit
local SDFPhasicAutoGunWeapon = import('/lua/seraphimweapons.lua').SDFPhasicAutoGunWeapon

XSL0101 = Class(SWalkingLandUnit, HiderUnit) {
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
            self:RevealUnit()
        else
            SWalkingLandUnit.OnScriptBitSet(self, bit)
        end
    end,

    -- Toggle enabled
    OnScriptBitClear = function(self, bit)
        if bit == 8 then
            self.Sync.LowPriority = true
            self.CloakThread = self:ForkThread(self.HideUnit) -- Only actually hides if stationary
        else
            SWalkingLandUnit.OnScriptBitClear(self, bit)
        end
    end,

    -- Turn off the cloak to begin with
    OnStopBeingBuilt = function(self, builder, layer)
        SWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetScriptBit('RULEUTC_CloakToggle', true)
        self:ForkThread(self.HideUnit)
    end,

    OnMotionHorzEventChange = function(self, new, old)
        SWalkingLandUnit.OnMotionHorzEventChange(self, new, old)
        self:StealthMotionHandler(new, old)
    end,

    HideUnit = function(self)
        if not self.Sync.LowPriority then return end

        HiderUnit.HideUnit(self)

        -- Ensure weapon state
        self:SetWeaponEnabledByLabel('LaserTurret', false)
    end,

    RevealUnit = function(self)
        HiderUnit.RevealUnit(self)

        -- Ensure weapon state
        self:SetWeaponEnabledByLabel('LaserTurret', true)
    end,
}

TypeClass = XSL0101
