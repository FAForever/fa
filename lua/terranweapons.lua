--****************************************************************************
--**
--**  File     :  /lua/terranweapons.lua
--**  Author(s):  John Comes, David Tomandl, Gordon Duclos
--**
--**  Summary  :  Terran-specific weapon definitions
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local WeaponFile = import("/lua/sim/defaultweapons.lua")
local CollisionBeams = import("/lua/defaultcollisionbeams.lua")

-- Weapon Files --

TDFFragmentationGrenadeLauncherWeapon = import('/lua/sim/weapons/uef/TDFFragmentationGrenadeLauncherWeapon.lua').TDFFragmentationGrenadeLauncherWeapon
TDFPlasmaCannonWeapon = import('/lua/sim/weapons/uef/TDFPlasmaCannonWeapon.lua').TDFPlasmaCannonWeapon
TIFFragLauncherWeapon = import('/lua/sim/weapons/uef/TIFFragLauncherWeapon.lua').TIFFragLauncherWeapon
TDFHeavyPlasmaGatlingWeapon = import('/lua/sim/weapons/uef/TDFHeavyPlasmaGatlingWeapon.lua').TDFHeavyPlasmaGatlingWeapon
TDFLightPlasmaCannonWeapon = import('/lua/sim/weapons/uef/TDFLightPlasmaCannonWeapon.lua').TDFLightPlasmaCannonWeapon
TDFHeavyPlasmaCannonWeapon = import('/lua/sim/weapons/uef/TDFHeavyPlasmaCannonWeapon.lua').TDFHeavyPlasmaCannonWeapon
TDFHeavyPlasmaGatlingCannonWeapon = import('/lua/sim/weapons/uef/TDFHeavyPlasmaGatlingCannonWeapon.lua').TDFHeavyPlasmaGatlingCannonWeapon
TDFOverchargeWeapon = import('/lua/sim/weapons/uef/TDFOverchargeWeapon.lua').TDFOverchargeWeapon
TDFMachineGunWeapon = import('/lua/sim/weapons/uef/TDFMachineGunWeapon.lua').TDFMachineGunWeapon
TDFGaussCannonWeapon = import('/lua/sim/weapons/uef/TDFGaussCannonWeapon.lua').TDFGaussCannonWeapon
TDFShipGaussCannonWeapon = import('/lua/sim/weapons/uef/TDFShipGaussCannonWeapon.lua').TDFShipGaussCannonWeapon
TDFLandGaussCannonWeapon = import('/lua/sim/weapons/uef/TDFLandGaussCannonWeapon.lua').TDFLandGaussCannonWeapon
TDFZephyrCannonWeapon = import('/lua/sim/weapons/uef/TDFZephyrCannonWeapon.lua').TDFZephyrCannonWeapon
TDFRiotWeapon = import('/lua/sim/weapons/uef/TDFRiotWeapon.lua').TDFRiotWeapon
TAAGinsuRapidPulseWeapon = import('/lua/sim/weapons/uef/TAAGinsuRapidPulseWeapon.lua').TAAGinsuRapidPulseWeapon
TDFIonizedPlasmaCannon = import('/lua/sim/weapons/uef/TDFIonizedPlasmaCannon.lua').TDFIonizedPlasmaCannon
TDFHiroPlasmaCannon = import('/lua/sim/weapons/uef/TDFHiroPlasmaCannon.lua').TDFHiroPlasmaCannon
TAAFlakArtilleryCannon = import('/lua/sim/weapons/uef/TAAFlakArtilleryCannon.lua').TAAFlakArtilleryCannon
TAALinkedRailgun = import('/lua/sim/weapons/uef/TAALinkedRailgun.lua').TAALinkedRailgun
TAirToAirLinkedRailgun = import('/lua/sim/weapons/uef/TAirToAirLinkedRailgun.lua').TAirToAirLinkedRailgun
TIFCruiseMissileUnpackingLauncher = import('/lua/sim/weapons/uef/TIFCruiseMissileUnpackingLauncher.lua').TIFCruiseMissileUnpackingLauncher
TIFCruiseMissileLauncher = import('/lua/sim/weapons/uef/TIFCruiseMissileLauncher.lua').TIFCruiseMissileLauncher
TIFCruiseMissileLauncherSub = import('/lua/sim/weapons/uef/TIFCruiseMissileLauncherSub.lua').TIFCruiseMissileLauncherSub
TSAMLauncher = import('/lua/sim/weapons/uef/TSAMLauncher.lua').TSAMLauncher
TANTorpedoLandWeapon = import('/lua/sim/weapons/uef/TANTorpedoLandWeapon.lua').TANTorpedoLandWeapon
TANTorpedoAngler = import('/lua/sim/weapons/uef/TANTorpedoAngler.lua').TANTorpedoAngler
TIFSmartCharge = import('/lua/sim/weapons/uef/TIFSmartCharge.lua').TIFSmartCharge
TIFStrategicMissileWeapon = import('/lua/sim/weapons/uef/TIFStrategicMissileWeapon.lua').TIFStrategicMissileWeapon
TIFArtilleryWeapon = import('/lua/sim/weapons/uef/TIFArtilleryWeapon.lua').TIFArtilleryWeapon
TIFCarpetBombWeapon = import('/lua/sim/weapons/uef/TIFCarpetBombWeapon.lua').TIFCarpetBombWeapon
TIFSmallYieldNuclearBombWeapon = import('/lua/sim/weapons/uef/TIFSmallYieldNuclearBombWeapon.lua').TIFSmallYieldNuclearBombWeapon
TIFHighBallisticMortarWeapon = import('/lua/sim/weapons/uef/TIFHighBallisticMortarWeapon.lua').TIFHighBallisticMortarWeapon
TAMInterceptorWeapon = import('/lua/sim/weapons/uef/TAMInterceptorWeapon.lua').TAMInterceptorWeapon
TAMPhalanxWeapon = import('/lua/sim/weapons/uef/TAMPhalanxWeapon.lua').TAMPhalanxWeapon
TOrbitalDeathLaserBeamWeapon = import('/lua/sim/weapons/uef/TOrbitalDeathLaserBeamWeapon.lua').TOrbitalDeathLaserBeamWeapon


-- Kept for Mod backwards compatibility
local BareBonesWeapon = WeaponFile.BareBonesWeapon
local GinsuCollisionBeam = CollisionBeams.GinsuCollisionBeam
local DefaultProjectileWeapon = WeaponFile.DefaultProjectileWeapon
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon
local OrbitalDeathLaserCollisionBeam = CollisionBeams.OrbitalDeathLaserCollisionBeam
local EffectTemplate = import("/lua/EffectTemplates.lua")