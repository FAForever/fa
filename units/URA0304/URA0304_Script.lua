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
        ---@class Bomb : CIFBombNeutronWeapon
        Bomb = ClassWeapon(CIFBombNeutronWeapon) {
            LastDrop = 0,
            Drops = 0,
            SumDropInterval = 0,

            ---@param self Bomb
            CreateProjectileAtMuzzle = function(self, muzzle)
                if self.LastDrop ~= 0 then
                    local dt = GetGameTick() - self.LastDrop
                    self.Drops = self.Drops + 1
                    self.SumDropInterval = self.SumDropInterval + dt
                    local ux,uy,uz = self.unit:GetVelocity()
                    local spd = math.sqrt(ux*ux+uy*uy+uz*uz) * 10 -- convert from ogrids/tick to ogrids/s
                        LOG(('Ticks between bomb drops %d (avg over %d: %.1f); Unit speed ogrids/s: %.1f'):format(
                        dt, self.Drops, self.SumDropInterval / self.Drops, spd
                    ))
                end
                self.LastDrop = GetGameTick()
                CIFBombNeutronWeapon.CreateProjectileAtMuzzle(self, muzzle)
            end,

            OnLostTarget = function(self)
                self.LastDrop = 0
                self.Drops = 0
                self.SumDropInterval = 0
                CIFBombNeutronWeapon.OnLostTarget(self)
            end,
        },
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
