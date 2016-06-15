#****************************************************************************
#**
#**  File     :  /cdimage/units/URL0104/URL0104_script.lua
#**  Author(s):  John Comes, David Tomandl
#**
#**  Summary  :  Cybran Anti-Air Tank Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CLandUnit = import('/lua/cybranunits.lua').CLandUnit
local CybranWeaponsFile = import('/lua/cybranweapons.lua')
local CAANanoDartWeapon = CybranWeaponsFile.CAANanoDartWeapon

URL0104 = Class(CLandUnit) {
    Weapons = {
        AAGun = Class(CAANanoDartWeapon) {},
        GroundGun = Class(CAANanoDartWeapon) {
            SetOnTransport = function(self, transportstate)
                CAANanoDartWeapon.SetOnTransport(self, transportstate)
                self.unit:SetScriptBit('RULEUTC_WeaponToggle', false)
            end,
        },
    },
    
    OnCreate = function(self)
        CLandUnit.OnCreate(self)
        self:SetWeaponEnabledByLabel('GroundGun', false)
    end,
    
    OnScriptBitSet = function(self, bit)
        CLandUnit.OnScriptBitSet(self, bit)
        if bit == 1 then 
            self:SetWeaponEnabledByLabel('GroundGun', true)
            self:SetWeaponEnabledByLabel('AAGun', false)
            self:GetWeaponManipulatorByLabel('GroundGun'):SetHeadingPitch( self:GetWeaponManipulatorByLabel('AAGun'):GetHeadingPitch() )
        end
    end,

    OnScriptBitClear = function(self, bit)
        CLandUnit.OnScriptBitClear(self, bit)
        if bit == 1 then 
            self:SetWeaponEnabledByLabel('GroundGun', false)
            self:SetWeaponEnabledByLabel('AAGun', true)
            self:GetWeaponManipulatorByLabel('AAGun'):SetHeadingPitch( self:GetWeaponManipulatorByLabel('GroundGun'):GetHeadingPitch() )
        end
    end,
}
TypeClass = URL0104

