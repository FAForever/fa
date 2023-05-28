----****************************************************************************
----**
----**  File     :  /cdimage/units/UES0103/UES0103_script.lua
----**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
----**
----**  Summary  :  UEF Frigate Script
----**
----**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local TSeaUnit = import("/lua/terranunits.lua").TSeaUnit
local TAALinkedRailgun = import("/lua/terranweapons.lua").TAALinkedRailgun
local TDFGaussCannonWeapon = import("/lua/terranweapons.lua").TDFGaussCannonWeapon
local Entity = import("/lua/sim/entity.lua").Entity

---@class UES0103 : TSeaUnit
UES0103 = ClassUnit(TSeaUnit) {
    Weapons = {
        MainGun = ClassWeapon(TDFGaussCannonWeapon) {},
        AAGun = ClassWeapon(TAALinkedRailgun) {},
    },

    OnStopBeingBuilt = function(self,builder,layer)
        TSeaUnit.OnStopBeingBuilt(self,builder,layer)
        self.Trash:Add(CreateRotator(self, 'Spinner01', 'y', nil, 360, 0, 180))
        self.Trash:Add(CreateRotator(self, 'Spinner02', 'y', nil, 90, 0, 180))
        self.Trash:Add(CreateRotator(self, 'Spinner03', 'y', nil, -180, 0, -180))
        self.RadarEnt = Entity {}
        self.Trash:Add(self.RadarEnt)
        local bp = self:GetBlueprint()
        self.RadarEnt:InitIntel(self.Army, 'Radar', bp.Intel.RadarRadius or 75)
        self.RadarEnt:EnableIntel('Radar')
        self.RadarEnt:InitIntel(self.Army, 'Sonar', bp.Intel.SonarRadius or 75)
        self.RadarEnt:EnableIntel('Sonar')
        self.RadarEnt:AttachBoneTo(-1, self, 0)
    end,
}

TypeClass = UES0103
