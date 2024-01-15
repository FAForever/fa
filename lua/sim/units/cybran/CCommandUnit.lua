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

local CommandUnit = import('/lua/defaultunits.lua').CommandUnit
local CommandUnitOnCreate = CommandUnit.OnCreate
local CommandUnitDestroyAllBuildEffects = CommandUnit.DestroyAllBuildEffects
local CommandUnitStopBuildingEffects = CommandUnit.StopBuildingEffects
local CommandUnitOnPaused = CommandUnit.OnPaused
local CommandUnitOnDestroy = CommandUnit.OnDestroy

local CConstructionTemplate = import('/lua/cybranunits.lua').CConstructionTemplate
local CConstructionTemplateOnCreate = CConstructionTemplate.OnCreate
local CConstructionTemplateDestroyAllBuildEffects = CConstructionTemplate.DestroyAllBuildEffects
local CConstructionTemplateStopBuildingEffects = CConstructionTemplate.StopBuildingEffects
local CConstructionTemplateOnPaused = CConstructionTemplate.OnPaused
local CConstructionTemplateCreateBuildEffects = CConstructionTemplate.CreateBuildEffects
local CConstructionTemplateOnDestroy = CConstructionTemplate.OnDestroy

---# CCommandUnit
---Cybran Command Units (ACU and SCU) have stealth and cloak enhancements, toggles can be handled in one class
---@class CCommandUnit : CommandUnit, CConstructionTemplate
CCommandUnit = ClassUnit(CommandUnit, CConstructionTemplate) {

    ---@param self CCommandUnit
    OnCreate = function(self)
        CommandUnitOnCreate(self)
        CConstructionTemplateOnCreate(self)
    end,

    ---@param self CCommandUnit
    DestroyAllBuildEffects = function(self)
        CommandUnitDestroyAllBuildEffects(self)
        CConstructionTemplateDestroyAllBuildEffects(self)
    end,

    ---@param self CCommandUnit
    ---@param built Unit
    StopBuildingEffects = function(self, built)
        CommandUnitStopBuildingEffects(self, built)
        CConstructionTemplateStopBuildingEffects(self, built)
    end,

    ---@param self CCommandUnit
    OnPaused = function(self)
        CommandUnitOnPaused(self)
        CConstructionTemplateOnPaused(self)
    end,

    ---@param self CCommandUnit
    ---@param unitBeingBuilt Unit
    ---@param order number
    ---@param stationary boolean
    CreateBuildEffects = function(self, unitBeingBuilt, order, stationary)
        CConstructionTemplateCreateBuildEffects(self, unitBeingBuilt, order, stationary)
    end,

    ---@param self CCommandUnit
    OnDestroy = function(self)
        CommandUnitOnDestroy(self)
        CConstructionTemplateOnDestroy(self)
    end,

    ---@param self CCommandUnit
    ---@param bit number
    OnScriptBitSet = function(self, bit)
        if bit == 8 then -- Cloak toggle
            self:StopUnitAmbientSound('ActiveLoop')
            self:SetMaintenanceConsumptionInactive()
            self:DisableUnitIntel('ToggleBit8', 'Cloak')
            self:DisableUnitIntel('ToggleBit8', 'RadarStealth')
            self:DisableUnitIntel('ToggleBit8', 'RadarStealthField')
            self:DisableUnitIntel('ToggleBit8', 'SonarStealth')
            self:DisableUnitIntel('ToggleBit8', 'SonarStealthField')
        end
    end,

    ---@param self CCommandUnit
    ---@param bit number
    OnScriptBitClear = function(self, bit)
        if bit == 8 then -- Cloak toggle
            self:PlayUnitAmbientSound('ActiveLoop')
            self:SetMaintenanceConsumptionActive()
            self:EnableUnitIntel('ToggleBit8', 'Cloak')
            self:EnableUnitIntel('ToggleBit8', 'RadarStealth')
            self:EnableUnitIntel('ToggleBit8', 'RadarStealthField')
            self:EnableUnitIntel('ToggleBit8', 'SonarStealth')
            self:EnableUnitIntel('ToggleBit8', 'SonarStealthField')
        end
    end,
}
