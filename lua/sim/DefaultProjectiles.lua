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

SemiBallisticComponent = import("/lua/sim/projectiles/components/semiballisticcomponent.lua").SemiBallisticComponent
TacticalMissileComponent = import("/lua/sim/projectiles/components/tacticalmissilecomponent.lua").TacticalMissileComponent

NullShell = import("/lua/sim/projectiles/nullprojectile.lua").NullShell

EmitterProjectile = import("/lua/sim/projectiles/emitterprojectile.lua").EmitterProjectile

SingleBeamProjectile = import("/lua/sim/projectiles/singlebeamprojectile.lua").SingleBeamProjectile
MultiBeamProjectile = import("/lua/sim/projectiles/multibeamprojectile.lua").MultiBeamProjectile

NukeProjectile = import("/lua/sim/projectiles/nukeprojectile.lua").NukeProjectile

SinglePolyTrailProjectile = import("/lua/sim/projectiles/singlepolytrailprojectile.lua").SinglePolyTrailProjectile
MultiPolyTrailProjectile = import("/lua/sim/projectiles/multipolytrailprojectile.lua").MultiPolyTrailProjectile

SingleCompositeEmitterProjectile = import("/lua/sim/projectiles/singlecompositeemitterprojectile.lua").SingleCompositeEmitterProjectile
MultiCompositeEmitterProjectile = import("/lua/sim/projectiles/multicompositeemitterprojectile.lua").MultiCompositeEmitterProjectile

OnWaterEntryEmitterProjectile = import("/lua/sim/projectiles/onwaterentryemitterprojectile.lua").OnWaterEntryEmitterProjectile

BaseGenericDebris = import("/lua/sim/projectiles/debrisprojectile.lua").BaseGenericDebris

OverchargeProjectile = import("/lua/sim/projectiles/overchargeprojectile.lua").OverchargeProjectile

-------------------------------------------------------------------------------
--#region Backwards compatibility

local MathFloor = math.floor
local Random = Random
local CreateTrail = CreateTrail
local CreateEmitterOnEntity = CreateEmitterOnEntity
local CreateBeamEmitterOnEntity = CreateBeamEmitterOnEntity
local VDist2 = VDist2
local TableGetn = table.getn

local IEffectScaleEmitter = _G.moho.IEffect.ScaleEmitter
local IEffectOffsetEmitter = _G.moho.IEffect.OffsetEmitter

local Projectile = import("/lua/sim/projectile.lua").Projectile
local DummyProjectile = import("/lua/sim/projectile.lua").DummyProjectile
local UnitsInSphere = import("/lua/utilities.lua").GetTrueEnemyUnitsInSphere
local GetDistanceBetweenTwoEntities = import("/lua/utilities.lua").GetDistanceBetweenTwoEntities

--#endregion