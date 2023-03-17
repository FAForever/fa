-----------------------------------------------------------------
--  File     :  /cdimage/units/URL0203/URL0203_script.lua
--  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--  Summary  :  Cybran Ambphibious Tank Script
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local CLandUnit = import("/lua/cybranunits.lua").CLandUnit
local CybranWeaponsFile = import("/lua/cybranweapons.lua")
local CDFElectronBolterWeapon = CybranWeaponsFile.CDFElectronBolterWeapon
local CDFMissileMesonWeapon = CybranWeaponsFile.CDFMissileMesonWeapon
local CANTorpedoLauncherWeapon = CybranWeaponsFile.CANTorpedoLauncherWeapon
local SlowAmphibious = import("/lua/defaultunits.lua").SlowAmphibiousLandUnit

URL0203 = ClassUnit(CLandUnit, SlowAmphibious) {

    Weapons = {
        Bolter = ClassWeapon(CDFElectronBolterWeapon) {},
        Rocket = ClassWeapon(CDFMissileMesonWeapon) {},
        Torpedo = ClassWeapon(CANTorpedoLauncherWeapon) {},
    },

	OnCreate = function(self)
		CLandUnit.OnCreate(self)
		SlowAmphibious.OnCreate(self)
	end,
    
    OnStopBeingBuilt = function(self, builder, layer)
        CLandUnit.OnStopBeingBuilt(self,builder,layer)
        -- If created with F2 on land, then play the transform anim.
        if(self.Layer == 'Land') then
			-- Enable Land weapons
	        self:SetWeaponEnabledByLabel('Rocket', true)
	        self:SetWeaponEnabledByLabel('Bolter', true)
			-- Disable Torpedo
	        self:SetWeaponEnabledByLabel('Torpedo', false)
        elseif (self.Layer == 'Seabed') then
			-- Disable Land Weapons
	        self:SetWeaponEnabledByLabel('Rocket', false)
	        self:SetWeaponEnabledByLabel('Bolter', false)
			-- Enable Torpedo
	        self:SetWeaponEnabledByLabel('Torpedo', true)
        end
       self.WeaponsEnabled = true
    end,

	OnLayerChange = function(self, new, old)
		CLandUnit.OnLayerChange(self, new, old)
		if self.WeaponsEnabled then
			if( new == 'Land' ) then
				-- Enable Land weapons
				self:SetWeaponEnabledByLabel('Rocket', true)
				self:SetWeaponEnabledByLabel('Bolter', true)
				-- Disable Torpedo
				self:SetWeaponEnabledByLabel('Torpedo', false)
			elseif ( new == 'Seabed' ) then
				-- Disable Land Weapons
				self:SetWeaponEnabledByLabel('Rocket', false)
				self:SetWeaponEnabledByLabel('Bolter', false)
				-- Enable Torpedo
				self:SetWeaponEnabledByLabel('Torpedo', true)
			end
		end
        SlowAmphibious.OnLayerChange(self, new, old)
	end,
}
TypeClass = URL0203