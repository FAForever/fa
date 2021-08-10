----****************************************************************************
----**
----**  File     :  /cdimage/units/UEL0103/UEL0103_script.lua
----**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
----**
----**  Summary  :  Mobile Light Artillery Script
----**
----**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local TLandUnit = import('/lua/terranunits.lua').TLandUnit
local TIFHighBallisticMortarWeapon = import('/lua/terranweapons.lua').TIFHighBallisticMortarWeapon

UEL0103 = Class(TLandUnit) {
    Weapons = {
        MainGun = Class(TIFHighBallisticMortarWeapon) {
            CreateProjectileAtMuzzle = function(self, muzzle)
                local proj = TIFHighBallisticMortarWeapon.CreateProjectileAtMuzzle(self, muzzle)
                local bp = self.Blueprint
                local data = {
                    Radius = bp.CameraVisionRadius or 5,
                    Lifetime = bp.CameraLifetime or 5,
                    Army = self.unit.Army,
                }
                if proj and not proj:BeenDestroyed() then
                    proj:PassData(data)
                end
            end,
        },
    },
}

TypeClass = UEL0103
