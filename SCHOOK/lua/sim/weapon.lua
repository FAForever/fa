#****************************************************************************
#**
#**  File     :  /lua/sim/Weapon.lua
#**  Author(s):  Dru Staltman
#**
#**  Summary  : The base weapon class for all weapons in the game.  Hooked for SC.
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local MohoWeapon = Weapon

Weapon = Class(MohoWeapon) {
    GetDamageTable = function(self)
        local weaponBlueprint = self:GetBlueprint()
        local damageTable = {}
        damageTable.DamageRadius = weaponBlueprint.DamageRadius + (self.DamageRadiusMod or 0)
        damageTable.DamageAmount = weaponBlueprint.Damage + (self.DamageMod or 0)
        damageTable.DamageType = weaponBlueprint.DamageType
        damageTable.DamageFriendly = weaponBlueprint.DamageFriendly
        if damageTable.DamageFriendly == nil then
            damageTable.DamageFriendly = true
        end
        damageTable.CollideFriendly = weaponBlueprint.CollideFriendly or false
        damageTable.DoTTime = weaponBlueprint.DoTTime
        damageTable.DoTPulses = weaponBlueprint.DoTPulses
        damageTable.MetaImpactAmount = weaponBlueprint.MetaImpactAmount
        damageTable.MetaImpactRadius = weaponBlueprint.MetaImpactRadius
        damageTable.ArtilleryShieldBlocks = weaponBlueprint.ArtilleryShieldBlocks
        #Add buff
        damageTable.Buffs = {}
        if weaponBlueprint.Buffs != nil then
            for k, v in weaponBlueprint.Buffs do
                damageTable.Buffs[k] = {}
                damageTable.Buffs[k] = v
            end   
        end     
        #remove disabled buff
        if (self.Disabledbf != nil) and (damageTable.Buffs != nil) then
            for k, v in damageTable.Buffs do
                for j, w in self.Disabledbf do
                    if v.BuffType == w then
                        #Removing buff
                        table.remove( damageTable.Buffs, k )
                    end
                end
            end  
        end  
        return damageTable
    end,
}