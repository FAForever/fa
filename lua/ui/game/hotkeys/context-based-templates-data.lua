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
---@field TemplateData UIBuildTemplate          # A regular build template, except that it is written in Pascal Case and usually the first unit is removed
---@field TemplateSortingOrder number           # Lower numbers end up first in the queue
---@field TemplateBlueprintId BlueprintId       
---
--- By mouse context
---@field TriggersOnUnit? EntityCategory        # When defined, includes this template when the player is hovering over a unit, a build order for a given unit or a unit in build preview that matches the categories
---@field TriggersOnLand? boolean               # When true, includes this template when the mouse is over land and not over a deposit
---@field TriggersOnWater? boolean              # When true, includes this template when the mouse is over water and not over a deposit
---@field TriggersOnMassDeposit? boolean        # When true, includes this template when the mouse is over a mass deposit
---@field TriggersOnHydroDeposit? boolean       # When true, includes this template when the mouse is over a hydrocarbon deposit
---
-- deprecated
---@field TriggersOnBuilding? EntityCategory    # when defined, includes this template when the unit that is being built matches the categories. Is deprecated, use TriggersOnUnit instead.

-------------------------------------------------------------------------------
--#region By mouse context

PointDefense = import("/lua/ui/game/hotkeys/context-based-templates-data/pointdefense.lua").Template
AirDefenseLand = import("/lua/ui/game/hotkeys/context-based-templates-data/airdefenseland.lua").Template
AirDefenseWater = import("/lua/ui/game/hotkeys/context-based-templates-data/airdefensewater.lua").Template
TorpedoDefense = import("/lua/ui/game/hotkeys/context-based-templates-data/torpedodefense.lua").Template
T3Extractor = import("/lua/ui/game/hotkeys/context-based-templates-data/t3extractor.lua").Template
T3ExtractorWithStorages = import("/lua/ui/game/hotkeys/context-based-templates-data/t3extractorwithstorages.lua").Template
T3ExtractorWithStoragesAndFabs = import("/lua/ui/game/hotkeys/context-based-templates-data/t3extractorwithstoragesandfabs.lua").Template
T1Hydrocarbon = import("/lua/ui/game/hotkeys/context-based-templates-data/t1hydrocarbon.lua").Template
    
--#endregion

-------------------------------------------------------------------------------
--#region By (unit) blueprint id

AppendExtractorWithStorages = import("/lua/ui/game/hotkeys/context-based-templates-data/appendextractorwithstorages.lua").Template
AppendExtractorWithFabs = import("/lua/ui/game/hotkeys/context-based-templates-data/appendextractorwithfabs.lua").Template
AppendRadarWithPower = import("/lua/ui/game/hotkeys/context-based-templates-data/appendradarwithpower.lua").Template
AppendOpticsWithPower = import("/lua/ui/game/hotkeys/context-based-templates-data/appendopticswithpower.lua").Template
AppendT2ArtilleryWithPower = import("/lua/ui/game/hotkeys/context-based-templates-data/appendt2artillerywithpower.lua").Template
AppendT3FabricatorWithStorages = import("/lua/ui/game/hotkeys/context-based-templates-data/appendt3fabricatorwithstorages.lua").Template
AppendT2ArtilleryWithPower = import("/lua/ui/game/hotkeys/context-based-templates-data/appendt2artillerywithpower.lua").Template
AppendT3ArtilleryWithPower = import("/lua/ui/game/hotkeys/context-based-templates-data/appendt3artillerywithpower.lua").Template
AppendSalvationWithPower = import("/lua/ui/game/hotkeys/context-based-templates-data/appendsalvationwithpower.lua").Template
AppendPowerGeneratorsToT2Artillery = import("/lua/ui/game/hotkeys/context-based-templates-data/appendpowergeneratorstot2artillery.lua").Template
AppendPowerGeneratorsToT3Artillery = import("/lua/ui/game/hotkeys/context-based-templates-data/appendpowergeneratorstot3artillery.lua").Template
AppendPowerGeneratorsToSalvation = import("/lua/ui/game/hotkeys/context-based-templates-data/appendpowergeneratorstosalvation.lua").Template
AppendPowerGeneratorsToEnergyStorage = import("/lua/ui/game/hotkeys/context-based-templates-data/appendpowergeneratorstoenergystorage.lua").Template
AppendPowerGeneratorsToTML = import("/lua/ui/game/hotkeys/context-based-templates-data/appendpowergeneratorstotml.lua").Template
AppendWallsToPointDefense = import("/lua/ui/game/hotkeys/context-based-templates-data/appendwallstopointdefense.lua").Template
AppendAirGrid = import("/lua/ui/game/hotkeys/context-based-templates-data/appendairgrid.lua").Template

--#endregion
