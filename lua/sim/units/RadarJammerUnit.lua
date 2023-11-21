--**********************************************************************************
--** Copyright (c) 2023 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--**********************************************************************************

local StructureUnit = import("/lua/sim/units/structureunit.lua").StructureUnit
local StructureUnitOnCreate = StructureUnit.OnCreate
local StructureUnitOnStartBuild = StructureUnit.OnStartBuild
local StructureUnitOnStopBuild = StructureUnit.OnStopBuild
local StructureUnitOnFailedToBuild = StructureUnit.OnFailedToBuild
local StructureUnitOnStopBeingBuilt = StructureUnit.OnStopBeingBuilt
local StructureUnitOnIntelEnabled = StructureUnit.OnIntelEnabled
local StructureUnitOnIntelDisabled = StructureUnit.OnIntelDisabled
local StructureUnitDestroyAllTrashBags = StructureUnit.DestroyAllTrashBags

---@class RadarJammerUnit : StructureUnit
---@field IntelFxOn boolean
---@field IntelEffects? table
---@field IntelEffectsBag TrashBag
RadarJammerUnit = ClassUnit(StructureUnit) {

    ---@param self RadarJammerUnit
    OnCreate = function(self)
        StructureUnitOnCreate(self)
        self.IntelEffectsBag = TrashBag()
    end,

    ---@param self RadarJammerUnit
    DestroyAllTrashBags = function(self)
        StructureUnitDestroyAllTrashBags(self)
        self.IntelEffectsBag:Destroy()
    end,

    -- Shut down intel while upgrading
    ---@param self RadarJammerUnit
    ---@param unitbuilding RadarJammerUnit
    ---@param order string
    OnStartBuild = function(self, unitbuilding, order)
        StructureUnitOnStartBuild(self, unitbuilding, order)
        self:SetMaintenanceConsumptionInactive()
        self:DisableUnitIntel('Construction', 'Jammer')
        self:DisableUnitIntel('Construction', 'RadarStealthField')
    end,

    -- If we abort the upgrade, re-enable the intel
    ---@param self RadarJammerUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStopBuild = function(self, unitBeingBuilt, order)
        StructureUnitOnStopBuild(self, unitBeingBuilt, order)
        self:SetMaintenanceConsumptionActive()
        self:EnableUnitIntel('Construction', 'Jammer')
        self:EnableUnitIntel('Construction', 'RadarStealthField')
    end,

    -- If we abort the upgrade, re-enable the intel
    ---@param self RadarJammerUnit
    OnFailedToBuild = function(self)
        StructureUnitOnFailedToBuild(self)
        self:SetMaintenanceConsumptionActive()
        self:EnableUnitIntel('Construction', 'Jammer')
        self:EnableUnitIntel('Construction', 'RadarStealthField')
    end,

    ---@param self RadarJammerUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnitOnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
    end,

    ---@param self RadarJammerUnit
    OnIntelEnabled = function(self, intel)
        StructureUnitOnIntelEnabled(self, intel)
        self.IntelFxOn = true

        local intelEffects = self.IntelEffects
        if intelEffects and not self.IntelFxOn then
            self:CreateTerrainTypeEffects(intelEffects, 'FXIdle', self.Layer, nil, self.IntelEffectsBag)
        end
    end,

    ---@param self RadarJammerUnit
    OnIntelDisabled = function(self, intel)
        StructureUnitOnIntelDisabled(self, intel)
        self.IntelFxOn = false
        self.IntelEffectsBag:Destroy()
    end,
}
