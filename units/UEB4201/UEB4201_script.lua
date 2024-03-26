--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB4201/UEB4201_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Phalanx Gun Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TStructureUnit = import("/lua/terranunits.lua").TStructureUnit
local TAMPhalanxWeapon = import("/lua/terranweapons.lua").TAMPhalanxWeapon

-- upvalue for perfomance
local CreateRotator = CreateRotator
local TrashBagAdd = TrashBag.Add

---@class UEB4201 : TStructureUnit
UEB4201 = ClassUnit(TStructureUnit) {
    Weapons = {
        Turret01 = ClassWeapon(TAMPhalanxWeapon) {

                PlayFxWeaponUnpackSequence = function(self)
                    local unit = self.unit
                    local trash = unit.Trash

                    if not self.SpinManip then 
                        self.SpinManip = CreateRotator(unit, 'Turret_Barrel_B01', 'z', nil, 270, 180, 60)
                        self.unit.Trash:Add(self.SpinManip)
                    end
                    if self.SpinManip then
                        self.SpinManip:SetTargetSpeed(270)
                    end
                    TAMPhalanxWeapon.PlayFxWeaponUnpackSequence(self)
                end,

                PlayFxWeaponPackSequence = function(self)
                    if self.SpinManip then
                        self.SpinManip:SetTargetSpeed(0)
                    end
                    TAMPhalanxWeapon.PlayFxWeaponPackSequence(self)
                end,

            },
    },
}

TypeClass = UEB4201