-----------------------------------------------------------------
-- File     :  /cdimage/units/XRB2205/XRB2205_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  Cybran Heavy Torpedo Launcher Script
-- Copyright ? 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local CStructureUnit = import('/lua/cybranunits.lua').CStructureUnit
local CKrilTorpedoLauncherWeapon = import('/lua/cybranweapons.lua').CKrilTorpedoLauncherWeapon

XRB2308 = Class(CStructureUnit) {
    Weapons = {
        Turret01 = Class(CKrilTorpedoLauncherWeapon) {},
    },

    OnStopBeingBuilt = function(self, builder, layer)
        CStructureUnit.OnStopBeingBuilt(self, builder, layer)
        
        local pos = self:GetPosition()
        local armySelf = self:GetArmy()
        local health = self:GetHealth()
        local armies = ListArmies()
        local spottedByArmy = {}
        
        for _,army in armies do
            if not IsAlly(armySelf, army) then
                local blip = self:GetBlip(army)
                
                if blip and blip:IsSeenEver(army) then
                    table.insert(spottedByArmy, ScenarioInfo.ArmySetup[army].ArmyIndex)
                end
            end
        end
        
        self:Destroy()
        
        local newHARMS = CreateUnitHPR('XRB2309', armySelf, pos[1], pos[2], pos[3], 0, 0, 0)
        
        newHARMS:SetHealth(newHARMS, health)
        newHARMS.SpottedByArmy = spottedByArmy
    end,
}

TypeClass = XRB2308
