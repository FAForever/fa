--****************************************************************************
--**
--**  File     :  /cdimage/units/URS0203/URS0203_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Attack Sub Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CSubUnit = import("/lua/cybranunits.lua").CSubUnit
local CANNaniteTorpedoWeapon = import("/lua/cybranweapons.lua").CANNaniteTorpedoWeapon
local CDFLaserHeavyWeapon = import("/lua/cybranweapons.lua").CDFLaserHeavyWeapon

---@class URS0203 : CSubUnit
URS0203 = ClassUnit(CSubUnit) {
    DeathThreadDestructionWaitTime = 0,
    
    Weapons = {
        MainGun = ClassWeapon(CDFLaserHeavyWeapon) {},
        Torpedo01 = ClassWeapon(CANNaniteTorpedoWeapon) {},
    },
    OnStopBeingBuilt = function(self, builder, layer)
        CSubUnit.OnStopBeingBuilt(self,builder,layer)
        if(self:GetCurrentLayer() == 'Water') then
			-- Enable weapon
			self:SetWeaponEnabledByLabel('MainGun', true)
        elseif (self:GetCurrentLayer() == 'UnderWater') then
			-- Disable Weapon
			self:SetWeaponDisableByLabel('MainGun', false)
       end
       self.WeaponsEnabled = true
    end,
	OnLayerChange = function(self, new, old)
		CSubUnit.OnLayerChange(self, new, old)
		if self.WeaponsEnabled then
			if( new == 'Water' ) then
				-- Enable Minigun
				self:SetWeaponEnabledByLabel('MainGun', true)
			elseif ( new == 'UnderWater' ) then
				-- Disable Land Minigun
				self:SetWeaponDisableByLabel('MainGun', false)
			end
		end
	end,
}

TypeClass = URS0203