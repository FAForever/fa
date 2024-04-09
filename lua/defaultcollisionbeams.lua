--**********************************************************************************
--** Copyright (c) 2024 FAForever
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

-- Base beam that defines default effects
SCCollisionBeam = import("/lua/sim/collisionBeams/SCCollisionBeam.lua").SCCollisionBeam

-- UEF
TDFHiroCollisionBeam = import("/lua/sim/collisionBeams/TDFHiroCollisionBeam.lua").TDFHiroCollisionBeam
OrbitalDeathLaserCollisionBeam = import("/lua/sim/collisionBeams/OrbitalDeathLaserCollisionBeam.lua").OrbitalDeathLaserCollisionBeam
-- Cybran
ZapperCollisionBeam = import("/lua/sim/collisionBeams/ZapperCollisionBeam.lua").ZapperCollisionBeam
MicrowaveLaserCollisionBeam01 = import("/lua/sim/collisionBeams/MicrowaveLaserCollisionBeam01.lua").MicrowaveLaserCollisionBeam01
MicrowaveLaserCollisionBeam02 = import("/lua/sim/collisionBeams/MicrowaveLaserCollisionBeam02.lua").MicrowaveLaserCollisionBeam02
-- Aeon
QuantumBeamGeneratorCollisionBeam = import("/lua/sim/collisionBeams/QuantumBeamGeneratorCollisionBeam.lua").QuantumBeamGeneratorCollisionBeam
PhasonLaserCollisionBeam = import("/lua/sim/collisionBeams/PhasonLaserCollisionBeam.lua").PhasonLaserCollisionBeam
-- Seraphim
UnstablePhasonLaserCollisionBeam = import("/lua/sim/collisionBeams/UnstablePhasonLaserCollisionBeam.lua").UnstablePhasonLaserCollisionBeam
UltraChromaticBeamGeneratorCollisionBeam = import("/lua/sim/collisionBeams/UltraChromaticBeamGeneratorCollisionBeam.lua").UltraChromaticBeamGeneratorCollisionBeam
UltraChromaticBeamGeneratorCollisionBeam02 = import("/lua/sim/collisionBeams/UltraChromaticBeamGeneratorCollisionBeam02.lua").UltraChromaticBeamGeneratorCollisionBeam02

-- Unused Beams
-- UEF
GinsuCollisionBeam = import("/lua/sim/collisionBeams/GinsuCollisionBeam.lua").GinsuCollisionBeam
-- Cybran
ParticleCannonCollisionBeam = import("/lua/sim/collisionBeams/ParticleCannonCollisionBeam.lua").ParticleCannonCollisionBeam
-- Aeon
DisruptorBeamCollisionBeam = import("/lua/sim/collisionBeams/DisruptorBeamCollisionBeam.lua").DisruptorBeamCollisionBeam 
TractorClawCollisionBeam = import("/lua/sim/collisionBeams/TractorClawCollisionBeam.lua").TractorClawCollisionBeam
-- Seraphim
ExperimentalPhasonLaserCollisionBeam = import("/lua/sim/collisionBeams/ExperimentalPhasonLaserCollisionBeam.lua").ExperimentalPhasonLaserCollisionBeam

--#region Backwards compatibility

local CollisionBeam = import("/lua/sim/collisionbeam.lua").CollisionBeam
local EffectTemplate = import("/lua/effecttemplates.lua")
local VisionMarkerOpti = import("/lua/sim/VizMarker.lua").VisionMarkerOpti
local Util = import("/lua/utilities.lua")


--#endregion
