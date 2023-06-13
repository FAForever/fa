--****************************************************************************
--**
--**  File     :  /cdimage/units/XSB2302/XSB2302_script.lua
--**  Author(s):  Drew Staltman, Jessica St. Croix, Gordon Duclos, Aaron Lundquist
--**
--**  Summary  :  Seraphim Long Range Artillery Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SStructureUnit = import("/lua/seraphimunits.lua").SStructureUnit
local SIFSuthanusArtilleryCannon = import("/lua/seraphimweapons.lua").SIFSuthanusArtilleryCannon

---@class XSB2302 : SStructureUnit
XSB2302 = ClassUnit(SStructureUnit) {
    Weapons = {
        MainGun = ClassWeapon(SIFSuthanusArtilleryCannon) {
            CreateProjectileAtMuzzle = function(self, muzzle)
                local proj = SIFSuthanusArtilleryCannon.CreateProjectileAtMuzzle(self, muzzle)
                local data = self:GetBlueprint().ShieldDamage
                if proj and not proj:BeenDestroyed() then
                    proj:PassData(data)
                end

                return proj
            end,
        },
    },
}
TypeClass = XSB2302