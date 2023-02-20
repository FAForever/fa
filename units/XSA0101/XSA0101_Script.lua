-- ****************************************************************************
-- **
-- **  File     :  /cdimage/units/XSA0101/XSA0101_script.lua
-- **
-- **  Summary  :  Seraphim Scout Aircraft
-- **
-- **  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local SAirUnit = import("/lua/seraphimunits.lua").SAirUnit
local VisionMarker = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

---@class XSA0101 : SAirUnit
XSA0101 = ClassUnit(SAirUnit) {
    OnImpact = function(self, with, other)
        SAirUnit.OnImpact(self, with, other)

        ---@type VisionMarkerOpti
        local entity = VisionMarker({Owner = self})

        local px, py, pz = self:GetPositionXYZ()
        entity:UpdatePosition(px, pz)
        entity:UpdateIntel(self.Army, self.Blueprint.Intel.VisionRadiusOnDeath, 'Vision', true)
        entity:UpdateDuration(self.Blueprint.Intel.IntelDurationOnDeath)
    end,
}

TypeClass = XSA0101
