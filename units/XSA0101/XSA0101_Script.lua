-- ****************************************************************************
-- **
-- **  File     :  /cdimage/units/XSA0101/XSA0101_script.lua
-- **
-- **  Summary  :  Seraphim Scout Aircraft
-- **
-- **  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local SAirUnit = import('/lua/seraphimunits.lua').SAirUnit
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

XSA0101 = Class(SAirUnit) {
    OnImpact = function(self, with, other)
        SAirUnit.OnImpact(self, with, other)
        local pos = self:GetPosition()
        local spec = {
            X = pos[1],
            Z = pos[3],
            Radius = self:GetBlueprint().Intel.VisionRadiusOnDeath,
            LifeTime = self:GetBlueprint().Intel.IntelDurationOnDeath,
            Army = self:GetArmy(),
            Omni = false,
            WaterVision = false,
        }
        local vizEntity = VizMarker(spec)
    end,
}

TypeClass = XSA0101
