--****************************************************************************
--**
--**  File     :  /cdimage/units/XSL0103/XSL0103_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix, Aaron Lundquist
--**
--**  Summary  :  Seraphim Mobile Light Artillery Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SHoverLandUnit = import("/lua/seraphimunits.lua").SHoverLandUnit
local SIFThunthoCannonWeapon = import("/lua/seraphimweapons.lua").SIFThunthoCannonWeapon
local SlowHover = import("/lua/defaultunits.lua").SlowHoverLandUnit

---@class XSL0103 : SHoverLandUnit
XSL0103 = ClassUnit(SHoverLandUnit, SlowHover) {
    Weapons = {
        MainGun = ClassWeapon(SIFThunthoCannonWeapon) {}
    },

    OnLayerChange = function(self, new, old)
        local physics = (self.Blueprint or self:GetBlueprint()).Physics
        if physics.WaterSpeedMultiplier then
            SlowHover.OnLayerChange(self, new, old)
        else
            SHoverLandUnit.OnLayerChange(self, new, old)
        end
    end,
}

TypeClass = XSL0103