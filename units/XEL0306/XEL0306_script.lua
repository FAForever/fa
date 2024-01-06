--****************************************************************************
--**
--**  File     :  /data/units/XEL0306/XEL0306_script.lua
--**  Author(s):  Jessica St. Croix, Dru Staltman
--**
--**  Summary  :  UEF Mobile Missile Platform Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TLandUnit = import("/lua/terranunits.lua").TLandUnit
local TIFCruiseMissileUnpackingLauncher = import("/lua/terranweapons.lua").TIFCruiseMissileUnpackingLauncher

---@class XEL0306 : TLandUnit
XEL0306 = ClassUnit(TLandUnit) {
    Weapons = {
        MissileWeapon = ClassWeapon(TIFCruiseMissileUnpackingLauncher) 
        {
            FxMuzzleFlash = {'/effects/emitters/terran_mobile_missile_launch_01_emit.bp'},
            RackSalvoFiringState = State(TIFCruiseMissileUnpackingLauncher.RackSalvoFiringState) {
            OnLostTarget = function(self)
                if not self:WeaponHasTarget() then
                    self.HaltFireOrdered = true
                end
            end,
            },
        },
    },
}

TypeClass = XEL0306