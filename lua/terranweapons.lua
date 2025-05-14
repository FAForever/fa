--****************************************************************************
--**
--**  File     :  /lua/terranweapons.lua
--**  Author(s):  John Comes, David Tomandl, Gordon Duclos
--**
--**  Summary  :  Terran-specific weapon definitions
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

TDFFragmentationGrenadeLauncherWeapon = import('/lua/sim/weapons/uef/tdffragmentationgrenadelauncherweapon.lua').TDFFragmentationGrenadeLauncherWeapon
TDFPlasmaCannonWeapon = import('/lua/sim/weapons/uef/tdfplasmacannonweapon.lua').TDFPlasmaCannonWeapon
TIFFragLauncherWeapon = import('/lua/sim/weapons/uef/tiffraglauncherweapon.lua').TIFFragLauncherWeapon
TDFHeavyPlasmaGatlingWeapon = import('/lua/sim/weapons/uef/tdfheavyplasmagatlingweapon.lua').TDFHeavyPlasmaGatlingWeapon
TDFLightPlasmaCannonWeapon = import('/lua/sim/weapons/uef/tdflightplasmacannonweapon.lua').TDFLightPlasmaCannonWeapon
TDFHeavyPlasmaCannonWeapon = import('/lua/sim/weapons/uef/tdfheavyplasmacannonweapon.lua').TDFHeavyPlasmaCannonWeapon
TDFHeavyPlasmaGatlingCannonWeapon = import('/lua/sim/weapons/uef/tdfheavyplasmagatlingcannonweapon.lua').TDFHeavyPlasmaGatlingCannonWeapon
TDFOverchargeWeapon = import('/lua/sim/weapons/uef/tdfoverchargeweapon.lua').TDFOverchargeWeapon
TDFMachineGunWeapon = import('/lua/sim/weapons/uef/tdfmachinegunweapon.lua').TDFMachineGunWeapon
TDFGaussCannonWeapon = import('/lua/sim/weapons/uef/tdfgausscannonweapon.lua').TDFGaussCannonWeapon
TDFShipGaussCannonWeapon = import('/lua/sim/weapons/uef/tdfshipgausscannonweapon.lua').TDFShipGaussCannonWeapon
TDFLandGaussCannonWeapon = import('/lua/sim/weapons/uef/tdflandgausscannonweapon.lua').TDFLandGaussCannonWeapon
TDFZephyrCannonWeapon = import('/lua/sim/weapons/uef/tdfzephyrcannonweapon.lua').TDFZephyrCannonWeapon
TDFRiotWeapon = import('/lua/sim/weapons/uef/tdfriotweapon.lua').TDFRiotWeapon
TAAGinsuRapidPulseWeapon = import('/lua/sim/weapons/uef/taaginsurapidpulseweapon.lua').TAAGinsuRapidPulseWeapon
TDFIonizedPlasmaCannon = import('/lua/sim/weapons/uef/tdfionizedplasmacannon.lua').TDFIonizedPlasmaCannon
TDFHiroPlasmaCannon = import('/lua/sim/weapons/uef/tdfhiroplasmacannon.lua').TDFHiroPlasmaCannon
TAAFlakArtilleryCannon = import('/lua/sim/weapons/uef/taaflakartillerycannon.lua').TAAFlakArtilleryCannon
TAALinkedRailgun = import('/lua/sim/weapons/uef/taalinkedrailgun.lua').TAALinkedRailgun
TAirToAirLinkedRailgun = import('/lua/sim/weapons/uef/tairtoairlinkedrailgun.lua').TAirToAirLinkedRailgun
TIFCruiseMissileUnpackingLauncher = import('/lua/sim/weapons/uef/tifcruisemissileunpackinglauncher.lua').TIFCruiseMissileUnpackingLauncher
TIFCruiseMissileLauncher = import('/lua/sim/weapons/uef/tifcruisemissilelauncher.lua').TIFCruiseMissileLauncher
TIFCruiseMissileLauncherSub = import('/lua/sim/weapons/uef/tifcruisemissilelaunchersub.lua').TIFCruiseMissileLauncherSub
TSAMLauncher = import('/lua/sim/weapons/uef/tsamlauncher.lua').TSAMLauncher
TANTorpedoLandWeapon = import('/lua/sim/weapons/uef/tantorpedolandweapon.lua').TANTorpedoLandWeapon
TANTorpedoAngler = import('/lua/sim/weapons/uef/tantorpedoangler.lua').TANTorpedoAngler
TIFSmartCharge = import('/lua/sim/weapons/uef/tifsmartcharge.lua').TIFSmartCharge
TIFStrategicMissileWeapon = import('/lua/sim/weapons/uef/tifstrategicmissileweapon.lua').TIFStrategicMissileWeapon
TIFArtilleryWeapon = import('/lua/sim/weapons/uef/tifartilleryweapon.lua').TIFArtilleryWeapon
TIFCarpetBombWeapon = import('/lua/sim/weapons/uef/tifcarpetbombweapon.lua').TIFCarpetBombWeapon
TIFSmallYieldNuclearBombWeapon = import('/lua/sim/weapons/uef/tifsmallyieldnuclearbombweapon.lua').TIFSmallYieldNuclearBombWeapon
TIFHighBallisticMortarWeapon = import('/lua/sim/weapons/uef/tifhighballisticmortarweapon.lua').TIFHighBallisticMortarWeapon
TAMInterceptorWeapon = import('/lua/sim/weapons/uef/taminterceptorweapon.lua').TAMInterceptorWeapon
TAMPhalanxWeapon = import('/lua/sim/weapons/uef/tamphalanxweapon.lua').TAMPhalanxWeapon
TOrbitalDeathLaserBeamWeapon = import('/lua/sim/weapons/uef/torbitaldeathlaserbeamweapon.lua').TOrbitalDeathLaserBeamWeapon


--#region kept for mod backwards compatibility
local CollisionBeams = import("/lua/defaultcollisionbeams.lua")
local GinsuCollisionBeam = CollisionBeams.GinsuCollisionBeam
local OrbitalDeathLaserCollisionBeam = CollisionBeams.OrbitalDeathLaserCollisionBeam

local WeaponFile = import("/lua/sim/defaultweapons.lua")
local BareBonesWeapon = WeaponFile.BareBonesWeapon
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon
local DefaultProjectileWeapon = WeaponFile.DefaultProjectileWeapon

local EffectTemplate = import("/lua/effecttemplates.lua")
--#endregion
