-----------------------------------------------------------------
-- File     :  /cdimage/units/XSL0101/XSL0101_script.lua
-- Summary  :  Seraphim Land Scout Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

---@alias SelenBuffType "SELENCLOAKBONUS"
---@alias SelenBuffName "SelenCloakVisionDebuff"

local SWalkingLandUnit = import("/lua/seraphimunits.lua").SWalkingLandUnit
local SDFPhasicAutoGunWeapon = import("/lua/seraphimweapons.lua").SDFPhasicAutoGunWeapon
local Buff = import("/lua/sim/buff.lua")

---@class XSL0101 : SWalkingLandUnit
XSL0101 = ClassUnit(SWalkingLandUnit) {
    Weapons = {
        LaserTurret = ClassWeapon(SDFPhasicAutoGunWeapon) {
            OnWeaponFired = function(self)
                if not self.unit.WaitingForCloak then
                    self.unit:RevealUnit()
                    -- Firing uncloaks but doesn't stop cloaking attempt (StealthWaitTime)
                    -- Attack order firing also cancels cloaking attempts
                    -- Messy, but can't use weapon IdleState because it's called during and immediately after
                    -- construction, and before motion events
                    self.unit.CloakThread = self.unit:ForkThread(self.unit.HideUnit)
                end
            end,
        },
    },

    -- Toggle disabled
    OnScriptBitSet = function(self, bit)
        if bit == 8 then
            self.Sync.LowPriority = false
            self:RevealUnit()

            if Buff.HasBuff(self, 'SelenCloakVisionDebuff') then
                Buff.RemoveBuff(self, 'SelenCloakVisionDebuff')
            end
        else
            SWalkingLandUnit.OnScriptBitSet(self, bit)
        end
    end,

    -- Toggle enabled
    OnScriptBitClear = function(self, bit)
        if bit == 8 then
            self.Sync.LowPriority = true
            -- Only actually hides if stationary and doesn't have an attack order
            self.CloakThread = self:ForkThread(self.HideUnit)
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
        if not self.Dead and self:GetFractionComplete() == 1 and self.Sync.LowPriority then
            self.WaitingForCloak = true
            WaitSeconds(self:GetBlueprint().Intel.StealthWaitTime)
            if self.Dead or self:IsMoving() or self:IsUnitState("Attacking") then
                self.WaitingForCloak = false
                return
            end

            -- Ensure weapon state
            self:SetWeaponEnabledByLabel('LaserTurret', false)

            -- Toggle stealth on
            self:SetMaintenanceConsumptionActive()
            self:EnableUnitIntel('ToggleBit5', 'RadarStealth')
            self:EnableUnitIntel('ToggleBit8', 'Cloak')

            if not Buffs['SelenCloakVisionDebuff'] then
                BuffBlueprint {
                    Name = 'SelenCloakVisionDebuff',
                    DisplayName = 'SelenCloakVisionDebuff',
                    BuffType = 'SELENCLOAKBONUS',
                    Stacks = 'ALWAYS',
                    Duration = -1,
                    Affects = {
                        VisionRadius = {
                            Mult = 0.6,
                        },
                        RadarRadius = {
                            Mult = 0.6,
                        },
                    },
                }
            end
            if Buff.HasBuff(self, 'SelenCloakVisionDebuff') then
                Buff.RemoveBuff(self, 'SelenCloakVisionDebuff')
            end
            Buff.ApplyBuff(self, 'SelenCloakVisionDebuff')

            self.WaitingForCloak = false
        end
        self.CloakThread = nil
    end,

    -- Turn off the cloak to begin with
    OnStopBeingBuilt = function(self, builder, layer)
        SWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionInactive()
        self:SetScriptBit('RULEUTC_CloakToggle', true)
        self.WaitingForCloak = false
        self:ForkThread(self.HideUnit)
    end,

    OnMotionHorzEventChange = function(self, new, old)
        -- If we stopped moving, hide
        if new == 'Stopped' then
            -- Kill possible existing cloak thread from toggle first
            KillThread(self.CloakThread)
            self.CloakThread = nil
            -- We need to fork in order to use WaitSeconds
            self.CloakThread = self:ForkThread(self.HideUnit)
        end

        -- If we begin moving, reveal ourselves
        if old == 'Stopped' then
            self:RevealUnit()

            if Buff.HasBuff(self, 'SelenCloakVisionDebuff') then
                Buff.RemoveBuff(self, 'SelenCloakVisionDebuff')
            end
        end

        SWalkingLandUnit.OnMotionHorzEventChange(self, new, old)
    end,
}

TypeClass = XSL0101
