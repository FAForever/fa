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

--- Unit Base Classes
CConstructionTemplate = import('/lua/sim/units/cybran/CConstructionTemplate.lua').CConstructionTemplate
CConstructionUnit = import('/lua/sim/units/cybran/CConstructionUnit.lua').CConstructionUnit
CAirFactoryUnit = import('/lua/sim/units/cybran/CAirFactoryUnit.lua').CAirFactoryUnit
CAirStagingPlatformUnit = import('/lua/sim/units/cybran/CAirStagingPlatformUnit.lua').CAirStagingPlatformUnit
CLandFactoryUnit = import('/lua/sim/units/cybran/CLandFactoryUnit.lua').CLandFactoryUnit
CBuildBotUnit = import('/lua/sim/units/cybran/CBuildBotUnit.lua').CBuildBotUnit
CAirUnit = import('/lua/sim/units/cybran/CAirUnit.lua').CAirUnit
CConcreteStructureUnit = import('/lua/sim/units/cybran/CConcreteStructureUnit.lua').CConcreteStructureUnit
CEnergyCreationUnit = import('/lua/sim/units/cybran/CEnergyCreationUnit.lua').CEnergyCreationUnit
CEnergyStorageUnit = import('/lua/sim/units/cybran/CEnergyStorageUnit.lua').CEnergyStorageUnit
CLandUnit = import('/lua/sim/units/cybran/CLandUnit.lua').CLandUnit
CMassCollectionUnit = import('/lua/sim/units/cybran/CMassCollectionUnit.lua').CMassCollectionUnit
CMassFabricationUnit = import('/lua/sim/units/cybran/CMassFabricationUnit.lua').CMassFabricationUnit
CMassStorageUnit = import('/lua/sim/units/cybran/CMassStorageUnit.lua').CMassStorageUnit
CRadarUnit = import('/lua/sim/units/cybran/CRadarUnit.lua').CRadarUnit
CSonarUnit = import('/lua/sim/units/cybran/CSonarUnit.lua').CSonarUnit
CSeaFactoryUnit = import('/lua/sim/units/cybran/CSeaFactoryUnit.lua').CSeaFactoryUnit
CSeaUnit = import('/lua/sim/units/cybran/CSeaUnit.lua').CSeaUnit
CShieldLandUnit = import('/lua/sim/units/cybran/CShieldLandUnit.lua').CShieldLandUnit
CShieldStructureUnit = import('/lua/sim/units/cybran/CShieldStructureUnit.lua').CShieldStructureUnit
CStructureUnit = import('/lua/sim/units/cybran/CStructureUnit.lua').CStructureUnit
CSubUnit = import('/lua/sim/units/cybran/CSubUnit.lua').CSubUnit
CTransportBeaconUnit = import('/lua/sim/units/cybran/CTransportBeaconUnit.lua').CTransportBeaconUnit
CWalkingLandUnit = import('/lua/sim/units/cybran/CWalkingLandUnit.lua').CWalkingLandUnit
CWallStructureUnit = import('/lua/sim/units/cybran/CWallStructureUnit.lua').CWallStructureUnit
CCivilianStructureUnit = import('/lua/sim/units/cybran/CCivilianStructureUnit.lua').CCivilianStructureUnit
CQuantumGateUnit = import('/lua/sim/units/cybran/CQuantumGateUnit.lua').CQuantumGateUnit
CRadarJammerUnit = import('/lua/sim/units/cybran/CRadarJammerUnit.lua').CRadarJammerUnit
CConstructionEggUnit = import('/lua/sim/units/cybran/CConstructionEggUnit.lua').CConstructionEggUnit
CConstructionStructureUnit = import('/lua/sim/units/cybran/CConstructionStructureUnit.lua').CConstructionStructureUnit
CCommandUnit = import('/lua/sim/units/cybran/CCommandUnit.lua').CCommandUnit

-- kept for mod backwards compatibility
MathMax = math.max

local Util = import("/lua/utilities.lua")
local CreateCybranBuildBeams = false
local TrashBag = _G.TrashBag
local TrashBagAdd = TrashBag.Add

local DummyUnit = import("/lua/sim/unit.lua").DummyUnit
local DefaultUnitsFile = import("/lua/defaultunits.lua")
local AirFactoryUnit = DefaultUnitsFile.AirFactoryUnit
local AirStagingPlatformUnit = DefaultUnitsFile.AirStagingPlatformUnit
local AirUnit = DefaultUnitsFile.AirUnit
local ConcreteStructureUnit = DefaultUnitsFile.ConcreteStructureUnit
local ConstructionUnit = DefaultUnitsFile.ConstructionUnit
local EnergyStorageUnit = DefaultUnitsFile.EnergyStorageUnit
local LandFactoryUnit = DefaultUnitsFile.LandFactoryUnit
local SeaFactoryUnit = DefaultUnitsFile.SeaFactoryUnit
local SeaUnit = DefaultUnitsFile.SeaUnit
local ShieldLandUnit = DefaultUnitsFile.ShieldLandUnit
local ShieldStructureUnit = DefaultUnitsFile.ShieldStructureUnit
local StructureUnit = DefaultUnitsFile.StructureUnit
local QuantumGateUnit = DefaultUnitsFile.QuantumGateUnit
local RadarJammerUnit = DefaultUnitsFile.RadarJammerUnit
local CommandUnit = DefaultUnitsFile.CommandUnit
local RadarUnit = DefaultUnitsFile.RadarUnit
local MassCollectionUnit = DefaultUnitsFile.MassCollectionUnit
local EffectTemplate = import("/lua/effecttemplates.lua")
local EffectUtil = import("/lua/effectutilities.lua")

-- upvalued effect utility functions for performance
local SpawnBuildBotsOpti = EffectUtil.SpawnBuildBotsOpti
local CreateCybranEngineerBuildEffectsOpti = EffectUtil.CreateCybranEngineerBuildEffectsOpti
local CreateCybranBuildBeamsOpti = EffectUtil.CreateCybranBuildBeamsOpti

-- upvalued globals for performance
local Random = Random
local VDist2Sq = VDist2Sq
local ArmyBrains = ArmyBrains
local KillThread = KillThread
local ForkThread = ForkThread
local WaitTicks = coroutine.yield
local IssueMove = IssueMove
local IssueClearCommands = IssueClearCommands
-- upvalued moho functions for performance
local EntityFunctions = _G.moho.entity_methods
local EntityDestroy = EntityFunctions.Destroy
local EntityGetPosition = EntityFunctions.GetPosition
local EntityGetPositionXYZ = EntityFunctions.GetPositionXYZ
local UnitFunctions = _G.moho.unit_methods
local UnitSetConsumptionActive = UnitFunctions.SetConsumptionActive
