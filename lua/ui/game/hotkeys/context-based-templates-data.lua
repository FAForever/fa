--******************************************************************************************************
--** Copyright (c) 2023  Willem 'Jip' Wijnia
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
--******************************************************************************************************

---@class ContextBasedTemplate
---@field Name string                           # Printed on screen when cycling the templates
---@field TemplateData BuildTemplate            # A regular build template, except that it is written in Pascal Case and usually the first unit is removed
---@field TemplateSortingOrder number           # Lower numbers end up first in the queue
---
--- By mouse context
---@field TriggersOnUnit? EntityCategory        # When defined, includes this template when the unit the mouse is hovering over matches the categories
---@field TriggersOnLand? boolean               # When true, includes this template when the mouse is over land and not over a deposit
---@field TriggersOnWater? boolean              # When true, includes this template when the mouse is over water and not over a deposit
---@field TriggersOnMassDeposit? boolean        # When true, includes this template when the mouse is over a mass deposit
---@field TriggersOnHydroDeposit? boolean       # When true, includes this template when the mouse is over a hydrocarbon deposit
---
-- By command mode context
---@field TriggersOnBuilding? EntityCategory    # when defined, includes this template when the unit that is being built matches the categories

-------------------------------------------------------------------------------
--#region By mouse context

CapExtractorWithStorages = import("/lua/ui/game/hotkeys/context-based-templates-data/CapExtractorWithStorages.lua").Template
CapExtractorWithFabs = import("/lua/ui/game/hotkeys/context-based-templates-data/CapExtractorWithFabs.lua").Template
CapRadarWithPower = import("/lua/ui/game/hotkeys/context-based-templates-data/CapRadarWithPower.lua").Template
CapOpticsWithPower = import("/lua/ui/game/hotkeys/context-based-templates-data/CapOpticsWithPower.lua").Template
CapT2ArtilleryWithPower = import("/lua/ui/game/hotkeys/context-based-templates-data/CapT2ArtilleryWithPower.lua").Template
CapT3FabricatorWithStorages = import("/lua/ui/game/hotkeys/context-based-templates-data/CapT3FabricatorWithStorages.lua").Template
CapT2ArtilleryWithPower = import("/lua/ui/game/hotkeys/context-based-templates-data/CapT2ArtilleryWithPower.lua").Template
CapT3ArtilleryWithPower = import("/lua/ui/game/hotkeys/context-based-templates-data/CapT3ArtilleryWithPower.lua").Template
CapSalvationWithPower = import("/lua/ui/game/hotkeys/context-based-templates-data/CapSalvationWithPower.lua").Template
PointDefense = import("/lua/ui/game/hotkeys/context-based-templates-data/PointDefense.lua").Template
AirDefenseLand = import("/lua/ui/game/hotkeys/context-based-templates-data/AirDefenseLand.lua").Template
AirDefenseWater = import("/lua/ui/game/hotkeys/context-based-templates-data/AirDefenseWater.lua").Template
TorpedoDefense = import("/lua/ui/game/hotkeys/context-based-templates-data/TorpedoDefense.lua").Template
T1Extractor = import("/lua/ui/game/hotkeys/context-based-templates-data/T1Extractor.lua").Template
T2ExtractorWithStorages = import("/lua/ui/game/hotkeys/context-based-templates-data/T2ExtractorWithStorages.lua").Template
T3ExtractorWithStorages = import("/lua/ui/game/hotkeys/context-based-templates-data/T3ExtractorWithStorages.lua").Template
T3ExtractorWithStoragesAndFabs = import("/lua/ui/game/hotkeys/context-based-templates-data/T3ExtractorWithStoragesAndFabs.lua").Template
T1Hydrocarbon = import("/lua/ui/game/hotkeys/context-based-templates-data/T1Hydrocarbon.lua").Template

--#endregion

-------------------------------------------------------------------------------
--#region By command mode context

AppendMassStoragesToExtractors = import("/lua/ui/game/hotkeys/context-based-templates-data/AppendMassStoragesToExtractors.lua").Template
AppendMassStoragesAndFabricatorsToT3Extractor = import("/lua/ui/game/hotkeys/context-based-templates-data/AppendMassStoragesAndFabricatorsToT3Extractor.lua").Template
AppendPowerGeneratorsToT2Artillery = import("/lua/ui/game/hotkeys/context-based-templates-data/AppendPowerGeneratorsToT2Artillery.lua").Template
AppendPowerGeneratorsToT3Artillery = import("/lua/ui/game/hotkeys/context-based-templates-data/AppendPowerGeneratorsToT3Artillery.lua").Template
AppendPowerGeneratorsToSalvation = import("/lua/ui/game/hotkeys/context-based-templates-data/AppendPowerGeneratorsToSalvation.lua").Template
AppendPowerGeneratorsToEnergyStorage = import("/lua/ui/game/hotkeys/context-based-templates-data/AppendPowerGeneratorsToEnergyStorage.lua").Template
AppendPowerGeneratorsToRadar = import("/lua/ui/game/hotkeys/context-based-templates-data/AppendPowerGeneratorsToRadar.lua").Template
-- Soothsayer and Eye have different footprints so they need different appending templates.
AppendPowerGeneratorsToSoothsayer = import("/lua/ui/game/hotkeys/context-based-templates-data/AppendPowerGeneratorsToSoothsayer.lua").Template
AppendPowerGeneratorsToEye = import("/lua/ui/game/hotkeys/context-based-templates-data/AppendPowerGeneratorsToEye.lua").Template
AppendPowerGeneratorsToTML = import("/lua/ui/game/hotkeys/context-based-templates-data/AppendPowerGeneratorsToTML.lua").Template
AppendWallsToPointDefense = import("/lua/ui/game/hotkeys/context-based-templates-data/AppendWallsToPointDefense.lua").Template

AppendAirGrid = import("/lua/ui/game/hotkeys/context-based-templates-data/AppendAirGrid.lua").Template

--#endregion
