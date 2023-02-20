--****************************************************************************
--**
--**  File     :  /cdimage/units/UES0201/UES0201_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Terran Destroyer Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TSeaUnit = import("/lua/terranunits.lua").TSeaUnit
local WeaponFile = import("/lua/terranweapons.lua")
local TAALinkedRailgun = WeaponFile.TAALinkedRailgun
local TDFGaussCannonWeapon = WeaponFile.TDFGaussCannonWeapon
local TANTorpedoAngler = WeaponFile.TANTorpedoAngler
local TIFSmartCharge = WeaponFile.TIFSmartCharge

---@class UES0201 : TSeaUnit
UES0201 = ClassUnit(TSeaUnit) {
    Weapons = {
        FrontTurret01 = ClassWeapon(TDFGaussCannonWeapon) {},
        BackTurret01 = ClassWeapon(TDFGaussCannonWeapon) {},
        FrontTurret02 = ClassWeapon(TAALinkedRailgun) {},
        Torpedo01 = ClassWeapon(TANTorpedoAngler) {},
        AntiTorpedo = ClassWeapon(TIFSmartCharge) {},
    },

    OnStopBeingBuilt = function(self,builder,layer)
        TSeaUnit.OnStopBeingBuilt(self,builder,layer)
        self.Trash:Add(CreateRotator(self, 'Spinner01', 'y', nil, 180, 0, 180))
        self.Trash:Add(CreateRotator(self, 'Spinner02', 'y', nil, 180, 0, 180))
        self:HideBone( 'Back_Turret02', true )
    end,
}

TypeClass = UES0201