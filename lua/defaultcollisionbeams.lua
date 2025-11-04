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
SCCollisionBeam = import("/lua/sim/collisionbeams/sccollisionbeam.lua").SCCollisionBeam

-- UEF
TDFHiroCollisionBeam = import("/lua/sim/collisionbeams/tdfhirocollisionbeam.lua").TDFHiroCollisionBeam
OrbitalDeathLaserCollisionBeam = import("/lua/sim/collisionbeams/orbitaldeathlasercollisionbeam.lua").OrbitalDeathLaserCollisionBeam
-- Cybran
ZapperCollisionBeam = import("/lua/sim/collisionbeams/zappercollisionbeam.lua").ZapperCollisionBeam
MicrowaveLaserCollisionBeam01 = import("/lua/sim/collisionbeams/microwavelasercollisionbeam01.lua").MicrowaveLaserCollisionBeam01
MicrowaveLaserCollisionBeam02 = import("/lua/sim/collisionbeams/microwavelasercollisionbeam02.lua").MicrowaveLaserCollisionBeam02
-- Aeon
QuantumBeamGeneratorCollisionBeam = import("/lua/sim/collisionbeams/quantumbeamgeneratorcollisionbeam.lua").QuantumBeamGeneratorCollisionBeam
PhasonLaserCollisionBeam = import("/lua/sim/collisionbeams/phasonlasercollisionbeam.lua").PhasonLaserCollisionBeam
-- Seraphim
UnstablePhasonLaserCollisionBeam = import("/lua/sim/collisionbeams/unstablephasonlasercollisionbeam.lua").UnstablePhasonLaserCollisionBeam
UltraChromaticBeamGeneratorCollisionBeam = import("/lua/sim/collisionbeams/ultrachromaticbeamgeneratorcollisionbeam.lua").UltraChromaticBeamGeneratorCollisionBeam
UltraChromaticBeamGeneratorCollisionBeam02 = import("/lua/sim/collisionbeams/ultrachromaticbeamgeneratorcollisionbeam02.lua").UltraChromaticBeamGeneratorCollisionBeam02

-- Unused Beams
-- UEF
GinsuCollisionBeam = import("/lua/sim/collisionbeams/ginsucollisionbeam.lua").GinsuCollisionBeam
-- Cybran
ParticleCannonCollisionBeam = import("/lua/sim/collisionbeams/particlecannoncollisionbeam.lua").ParticleCannonCollisionBeam
-- Aeon
DisruptorBeamCollisionBeam = import("/lua/sim/collisionbeams/disruptorbeamcollisionbeam.lua").DisruptorBeamCollisionBeam 
TractorClawCollisionBeam = import("/lua/sim/collisionbeams/tractorclawcollisionbeam.lua").TractorClawCollisionBeam
-- Seraphim
ExperimentalPhasonLaserCollisionBeam = import("/lua/sim/collisionbeams/experimentalphasonlasercollisionbeam.lua").ExperimentalPhasonLaserCollisionBeam

--#region Backwards compatibility

local CollisionBeam = import("/lua/sim/collisionbeam.lua").CollisionBeam
local EffectTemplate = import("/lua/effecttemplates.lua")
local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti
local Util = import("/lua/utilities.lua")


--#endregion
