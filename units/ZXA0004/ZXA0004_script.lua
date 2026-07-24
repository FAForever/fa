local DummyUnit = import('/lua/sim/unit.lua').DummyUnit

local Warp = Warp

local PositionCache = { 0, 0, 0 }

--- Dummy unit to provide intel capabilities and range rings for an army
---
---@see VisionMarkerOpti # for just intel capabilities
---@class ZXA0004 : DummyUnit
ZXA0004 = ClassUnit(DummyUnit) {
    ---@param self ZXA0004
    OnCreate = function(self)
        DummyUnit.OnCreate(self)
    end,

    --- Sets the unit's position avoiding table allocations
    ---@param self ZXA0004
    ---@param x number
    ---@param z number
    SetPositionXZ = function(self, x, z)
        PositionCache[1] = x
        -- cache[2] doesn't need update since intel is independent of height
        PositionCache[3] = z
        Warp(self, PositionCache)
    end,

    --- Copies range of enabled intel from unit, excluding jamming.
    ---@param self ZXA0004
    ---@param unit Unit
    CopyAllIntelFrom = function(self, unit)
        ---@param type IntelType
        local function CopyIntel(type)
            if unit:IsIntelEnabled(type) then
                self:SetIntelRadius(type, unit:GetIntelRadius(type))
            end
        end
        CopyIntel("Vision")
        CopyIntel("WaterVision")
        CopyIntel("Radar")
        CopyIntel("Sonar")
        CopyIntel("Omni")
        CopyIntel("RadarStealthField")
        CopyIntel("SonarStealthField")
        CopyIntel("CloakField")
    end
}
TypeClass = ZXA0004
