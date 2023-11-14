-----------------------------------------------------------------
-- File     :  /lua/sim/DefaultWeapons.lua
-- Author(s):  John Comes
-- Summary  :  Default definitions of weapons
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

--- Default Weapon Files
DefaultProjectileWeapon = import('/lua/sim/weapons/DefaultProjectileWeapon.lua').DefaultProjectileWeapon
KamikazeWeapon = import('/lua/sim/weapons/KamikazeWeapon.lua').KamikazeWeapon
BareBonesWeapon = import('/lua/sim/weapons/BareBonesWeapon.lua').BareBonesWeapon
OverchargeWeapon = import('/lua/sim/weapons/OverchargeWeapon.lua').OverchargeWeapon
DefaultBeamWeapon = import('/lua/sim/weapons/DefaultBeamWeapon.lua').DefaultBeamWeapon
DeathNukeWeapon = import('/lua/sim/weapons/DeathNukeWeapon.lua').DeathNukeWeapon
SCUDeathWeapon = import('/lua/sim/weapons/SCUDeathWeapon.lua').SCUDeathWeapon

-- kept for mod backwards compatibility
local XZDist = import("/lua/utilities.lua").XZDistanceTwoVectors
local GetSurfaceHeight = GetSurfaceHeight
local VDist2 = VDist2
local EntityMethods = moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition
local EntityGetPositionXYZ = EntityMethods.GetPositionXYZ
local UnitMethods = moho.unit_methods
local UnitGetVelocity = UnitMethods.GetVelocity
local UnitGetTargetEntity = UnitMethods.GetTargetEntity
local Weapon = import("/lua/sim/weapon.lua").Weapon
local CollisionBeam = import("/lua/sim/collisionbeam.lua").CollisionBeam
local MathClamp = math.clamp