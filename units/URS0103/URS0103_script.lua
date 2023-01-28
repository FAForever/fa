--****************************************************************************
--**
--**  File     :  /cdimage/units/URS0103/URS0103_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Frigate Script
--**
--**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CSeaUnit = import("/lua/cybranunits.lua").CSeaUnit
local CybranWeaponsFile = import("/lua/cybranweapons.lua")
local CAAAutocannon = CybranWeaponsFile.CAAAutocannon
local CDFProtonCannonWeapon = CybranWeaponsFile.CDFProtonCannonWeapon

---@class URS0103 : CSeaUnit
URS0103 = ClassUnit(CSeaUnit) {
    Weapons = {
        ProtonCannon = ClassWeapon(CDFProtonCannonWeapon) {},
        AAGun = ClassWeapon(CAAAutocannon) {},
    },

    OnStopBeingBuilt = function(self,builder,layer)
        CSeaUnit.OnStopBeingBuilt(self,builder,layer)
        self.Trash:Add(CreateRotator(self, 'Cybran_Radar', 'y', nil, 90, 0, 0))
        self.Trash:Add(CreateRotator(self, 'Back_Radar', 'y', nil, -360, 0, 0))
        self.Trash:Add(CreateRotator(self, 'Front_Radar', 'y', nil, -180, 0, 0))
    end,
}

TypeClass = URS0103
