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

DefaultProjectileWeapon = import("/lua/sim/weapons/DefaultProjectileWeapon.lua").DefaultProjectileWeapon
KamikazeWeapon = import("/lua/sim/weapons/KamikazeWeapon.lua").KamikazeWeapon
BareBonesWeapon = import("/lua/sim/weapons/BareBonesWeapon.lua").BareBonesWeapon
OverchargeWeapon = import("/lua/sim/weapons/OverchargeWeapon.lua").OverchargeWeapon
DefaultBeamWeapon = import("/lua/sim/weapons/DefaultBeamWeapon.lua").DefaultBeamWeapon
DeathNukeWeapon = import("/lua/sim/weapons/DeathNukeWeapon.lua").DeathNukeWeapon
SCUDeathWeapon = import("/lua/sim/weapons/SCUDeathWeapon.lua").SCUDeathWeapon

-- kept for mod backwards compatibility
local Weapon = import("/lua/sim/weapon.lua").Weapon
local XZDist = import("/lua/utilities.lua").XZDistanceTwoVectors

local EntityMethods = moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition
local EntityGetPositionXYZ = EntityMethods.GetPositionXYZ

local UnitMethods = moho.unit_methods
local UnitGetVelocity = UnitMethods.GetVelocity
local UnitGetTargetEntity = UnitMethods.GetTargetEntity

local MathClamp = math.clamp
local GetSurfaceHeight = GetSurfaceHeight
local VDist2 = VDist2
