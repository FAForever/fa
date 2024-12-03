-------------------------------------------------------------------
--  File     :  /cdimage/units/URA0304/URA0304_script.lua
--  Author(s):  John Comes, David Tomandl
--  Summary  :  Cybran Strategic Bomber Script
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------

local CAirUnit = import("/lua/cybranunits.lua").CAirUnit
local CIFBombNeutronWeapon = import("/lua/cybranweapons.lua").CIFBombNeutronWeapon
local CAAAutocannon = import("/lua/cybranweapons.lua").CAAAutocannon

---@class URA0304 : CAirUnit
URA0304 = ClassUnit(CAirUnit) {
    Weapons = {
        Bomb = ClassWeapon(CIFBombNeutronWeapon) {},
        AAGun1 = ClassWeapon(CAAAutocannon) {},
        AAGun2 = ClassWeapon(CAAAutocannon) {},
    },
    ContrailBones = {'Left_Exhaust','Center_Exhaust','Right_Exhaust'},
    ExhaustBones = {'Left_Exhaust','Center_Exhaust','Right_Exhaust'},
    
    OnStopBeingBuilt = function(self,builder,layer)
        CAirUnit.OnStopBeingBuilt(self,builder,layer)
        --Turns Stealth off when unit is built
        self:SetScriptBit('RULEUTC_StealthToggle', true)
    end,
    
    OnDamage = function(self, instigator, amount, vector, damageType)
        if instigator and instigator:GetBlueprint().CategoriesHash.STRATEGICBOMBER and instigator.Army == self.Army then
            return
        end
        
        CAirUnit.OnDamage(self, instigator, amount, vector, damageType)
    end,
}
TypeClass = URA0304
