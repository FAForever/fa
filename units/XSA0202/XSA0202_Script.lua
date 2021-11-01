-- Automatically upvalued moho functions for performance
local UnitMethods = _G.moho.unit_methods
local UnitMethodsSetBreakOffDistanceMult = UnitMethods.SetBreakOffDistanceMult
local UnitMethodsSetBreakOffTriggerMult = UnitMethods.SetBreakOffTriggerMult
local UnitMethodsSetSpeedMult = UnitMethods.SetSpeedMult
-- End of automatically upvalued moho functions

--****************************************************************************
--**
--**  File     :  /data/units/XSA0202/XSA0202_script.lua
--**  Author(s):  Jessica St. Croix, Gordon Duclos, Matt Vainio, Aaron Lundquist
--**
--**  Summary  :  Seraphim Fighter/Bomber Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SAirUnit = import('/lua/seraphimunits.lua').SAirUnit
local SeraphimWeapons = import('/lua/seraphimweapons.lua')
local SAAShleoCannonWeapon = SeraphimWeapons.SAAShleoCannonWeapon
local SDFBombOtheWeapon = SeraphimWeapons.SDFBombOtheWeapon

XSA0202 = Class(SAirUnit)({
    Weapons = {
        ShleoAAGun01 = Class(SAAShleoCannonWeapon)({
            FxMuzzleFlash = {
                '/effects/emitters/sonic_pulse_muzzle_flash_02_emit.bp',
            },
        }),
        ShleoAAGun02 = Class(SAAShleoCannonWeapon)({
            FxMuzzleFlash = {
                '/effects/emitters/sonic_pulse_muzzle_flash_02_emit.bp',
            },
        }),
        Bomb = Class(SDFBombOtheWeapon)({

            IdleState = State(SDFBombOtheWeapon.IdleState)({
                Main = function(self)
                    SDFBombOtheWeapon.IdleState.Main(self)
                end,

                OnGotTarget = function(self)
                    if self.unit:IsUnitState('Moving') then
                        UnitMethodsSetSpeedMult(self.unit, 1.0)
                    else
                        UnitMethodsSetBreakOffTriggerMult(self.unit, 2.0)
                        UnitMethodsSetBreakOffDistanceMult(self.unit, 8.0)
                        UnitMethodsSetSpeedMult(self.unit, 0.67)
                        SDFBombOtheWeapon.OnGotTarget(self)
                    end
                end,
            }),

            OnGotTarget = function(self)
                if self.unit:IsUnitState('Moving') then
                    UnitMethodsSetSpeedMult(self.unit, 1.0)
                else
                    UnitMethodsSetBreakOffTriggerMult(self.unit, 2.0)
                    UnitMethodsSetBreakOffDistanceMult(self.unit, 8.0)
                    UnitMethodsSetSpeedMult(self.unit, 0.67)
                    SDFBombOtheWeapon.OnGotTarget(self)
                end
            end,

            OnLostTarget = function(self)
                UnitMethodsSetBreakOffTriggerMult(self.unit, 1.0)
                UnitMethodsSetBreakOffDistanceMult(self.unit, 1.0)
                UnitMethodsSetSpeedMult(self.unit, 1.0)
                SDFBombOtheWeapon.OnLostTarget(self)
            end,
        }),
    },
})
TypeClass = XSA0202
