--****************************************************************************
--**
--**  File     :  /data/units/XSA0202/XSA0202_script.lua
--**  Author(s):  Jessica St. Croix, Gordon Duclos, Matt Vainio, Aaron Lundquist
--**
--**  Summary  :  Seraphim Fighter/Bomber Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SAirUnit = import("/lua/seraphimunits.lua").SAirUnit
local SeraphimWeapons = import("/lua/seraphimweapons.lua")
local SAAShleoCannonWeapon = SeraphimWeapons.SAAShleoCannonWeapon
local SDFBombOtheWeapon = SeraphimWeapons.SDFBombOtheWeapon

---@class XSA0202 : SAirUnit
XSA0202 = ClassUnit(SAirUnit) {
    Weapons = {
        ShleoAAGun01 = ClassWeapon(SAAShleoCannonWeapon) {
			FxMuzzleFlash = {'/effects/emitters/sonic_pulse_muzzle_flash_02_emit.bp',},
        },
        ShleoAAGun02 = ClassWeapon(SAAShleoCannonWeapon) {
			FxMuzzleFlash = {'/effects/emitters/sonic_pulse_muzzle_flash_02_emit.bp',},
        },
        Bomb = ClassWeapon(SDFBombOtheWeapon) {
                
        IdleState = State (SDFBombOtheWeapon.IdleState) {
        Main = function(self)
                    SDFBombOtheWeapon.IdleState.Main(self)
                end,
                
        OnGotTarget = function(self)
            if self.unit:IsUnitState('Moving') then
               self.unit:SetSpeedMult(1.0)
            else
               self.unit:SetBreakOffTriggerMult(2.0)
               self.unit:SetBreakOffDistanceMult(8.0)
               self.unit:SetSpeedMult(0.67)
               SDFBombOtheWeapon.OnGotTarget(self)
            end
        end,                
            },
        
        OnGotTarget = function(self)
            if self.unit:IsUnitState('Moving') then
               self.unit:SetSpeedMult(1.0)
            else
               self.unit:SetBreakOffTriggerMult(2.0)
               self.unit:SetBreakOffDistanceMult(8.0)
               self.unit:SetSpeedMult(0.67)
               SDFBombOtheWeapon.OnGotTarget(self)
            end
        end,
        
        OnLostTarget = function(self)
            self.unit:SetBreakOffTriggerMult(1.0)
            self.unit:SetBreakOffDistanceMult(1.0)
            self.unit:SetSpeedMult(1.0)
            SDFBombOtheWeapon.OnLostTarget(self)
        end,  	
        },
    },
}
TypeClass = XSA0202
