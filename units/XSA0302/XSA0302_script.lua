--****************************************************************************
--**
--**  File     :  /cdimage/units/UAA0302/UAA0302_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Aeon Spy Plane Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SAirUnit = import("/lua/seraphimunits.lua").SAirUnit
local VisionMarker = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

---@class XSA0302 : SAirUnit
XSA0302 = ClassUnit(SAirUnit) {
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
TypeClass = XSA0302