------------------------------------------------------------------
--  File     :  /cdimage/units/UEA0304/UEA0304_script.lua
--  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--  Summary  :  UEF Strategic Bomber Script
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local TAirUnit = import("/lua/terranunits.lua").TAirUnit
local TIFSmallYieldNuclearBombWeapon = import("/lua/terranweapons.lua").TIFSmallYieldNuclearBombWeapon
local TAirToAirLinkedRailgun = import("/lua/terranweapons.lua").TAirToAirLinkedRailgun

---@class UEA0304 : TAirUnit
UEA0304 = ClassUnit(TAirUnit) {
    Weapons = {
        Bomb = ClassWeapon(TIFSmallYieldNuclearBombWeapon) {},
        LinkedRailGun1 = ClassWeapon(TAirToAirLinkedRailgun) {},
        LinkedRailGun2 = ClassWeapon(TAirToAirLinkedRailgun) {},
    },

    ---@param self UEA0304
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        TAirUnit.OnStopBeingBuilt(self, builder, layer)
        -- Don't turn off jamming for AI so that it uses it by default
        if self.Brain.BrainType == 'Human' then
            self:SetScriptBit('RULEUTC_JammingToggle', true)
        else
            self:SetMaintenanceConsumptionActive()
        end
    end,

    --- Do not allow friendly fire from our own army's strategic bombers
    ---@param self UEA0304
    ---@param instigator Unit
    ---@param amount number
    ---@param vector Vector
    ---@param damageType DamageType
    OnDamage = function(self, instigator, amount, vector, damageType)
        if instigator and instigator.Army == self.Army and instigator.Blueprint.CategoriesHash["STRATEGICBOMBER"] then
            return
        end

        TAirUnit.OnDamage(self, instigator, amount, vector, damageType)
    end,
}

TypeClass = UEA0304
