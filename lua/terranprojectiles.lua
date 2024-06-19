------------------------------------------------------------
--  File     : /lua/terranprojectiles.lua
--  Author(s): John Comes, Gordon Duclos, Matt Vainio
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

TFragmentationGrenade = import("/lua/sim/projectiles/uef/TFragmentationGrenadeProjectile.lua").TFragmentationGrenade
TIFMissileNuke = import("/lua/sim/projectiles/uef/TIFMissileNukeProjectile.lua").TIFMissileNuke
TIFTacticalNuke = import("/lua/sim/projectiles/uef/TIFTacticalNukeProjectile.lua").TIFTacticalNuke
TAAGinsuRapidPulseBeamProjectile = import("/lua/sim/projectiles/uef/TAAGinsuRapidPulseBeamProjectile.lua").TAAGinsuRapidPulseBeamProjectile
TAALightFragmentationProjectile = import("/lua/sim/projectiles/uef/TAALightFragmentationProjectile.lua").TAALightFragmentationProjectile
TArtilleryAntiMatterProjectile = import("/lua/sim/projectiles/uef/TArtilleryAntiMatterProjectile.lua").TArtilleryAntiMatterProjectile
TArtilleryAntiMatterProjectile02 = import("/lua/sim/projectiles/uef/TArtilleryAntiMatterProjectile02.lua").TArtilleryAntiMatterProjectile02
TArtilleryAntiMatterSmallProjectile = import("/lua/sim/projectiles/uef/TArtilleryAntiMatterSmallProjectile.lua").TArtilleryAntiMatterSmallProjectile
TArtilleryProjectile = import("/lua/sim/projectiles/uef/TArtilleryProjectile.lua").TArtilleryProjectile
TArtilleryProjectilePolytrail = import("/lua/sim/projectiles/uef/TArtilleryProjectilePolytrail.lua").TArtilleryProjectilePolytrail
TCannonSeaProjectile = import("/lua/sim/projectiles/uef/TCannonSeaProjectile.lua").TCannonSeaProjectile
TCannonTankProjectile = import("/lua/sim/projectiles/uef/TCannonTankProjectile.lua").TCannonTankProjectile
TDepthChargeProjectile = import("/lua/sim/projectiles/uef/TDepthChargeProjectile.lua").TDepthChargeProjectile
TDFGeneralGaussCannonProjectile = import("/lua/sim/projectiles/uef/TDFGeneralGaussCannonProjectile.lua").TDFGeneralGaussCannonProjectile
TDFGaussCannonProjectile = import("/lua/sim/projectiles/uef/TDFGaussCannonProjectile.lua").TDFGaussCannonProjectile
TDFMediumShipGaussCannonProjectile = import("/lua/sim/projectiles/uef/TDFMediumShipGaussCannonProjectile.lua").TDFMediumShipGaussCannonProjectile
TDFBigShipGaussCannonProjectile = import("/lua/sim/projectiles/uef/TDFBigShipGaussCannonProjectile.lua").TDFBigShipGaussCannonProjectile
TDFMediumLandGaussCannonProjectile = import("/lua/sim/projectiles/uef/TDFMediumLandGaussCannonProjectile.lua").TDFMediumLandGaussCannonProjectile
TDFBigLandGaussCannonProjectile = import("/lua/sim/projectiles/uef/TDFBigLandGaussCannonProjectile.lua").TDFBigLandGaussCannonProjectile
THeavyPlasmaCannonProjectile = import("/lua/sim/projectiles/uef/THeavyPlasmaCannonProjectile.lua").THeavyPlasmaCannonProjectile
TIFSmallYieldNuclearBombProjectile = import("/lua/sim/projectiles/uef/TIFSmallYieldNuclearBombProjectile.lua").TIFSmallYieldNuclearBombProjectile
TLaserBotProjectile = import("/lua/sim/projectiles/uef/TLaserBotProjectile.lua").TLaserBotProjectile
TLaserProjectile = import("/lua/sim/projectiles/uef/TLaserProjectile.lua").TLaserProjectile
TMachineGunProjectile = import("/lua/sim/projectiles/uef/TMachineGunProjectile.lua").TMachineGunProjectile
TMissileAAProjectile = import("/lua/sim/projectiles/uef/TMissileAAProjectile.lua").TMissileAAProjectile
TAntiNukeInterceptorProjectile = import("/lua/sim/projectiles/uef/TAntiNukeInterceptorProjectile.lua").TAntiNukeInterceptorProjectile
TMissileProjectile = import("/lua/sim/projectiles/uef/TMissileProjectile.lua").TMissileProjectile
TMissileCruiseProjectile = import("/lua/sim/projectiles/uef/TMissileCruiseProjectile.lua").TMissileCruiseProjectile
TMissileCruiseProjectile02 = import("/lua/sim/projectiles/uef/TMissileCruiseProjectile02.lua").TMissileCruiseProjectile02

--#region Mod Compatibility
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local util = import('utilities.lua')
local Explosion = import('defaultexplosions.lua')
local Projectile = import('/lua/sim/projectile.lua').Projectile
local DefaultProjectileFile = import("/lua/sim/defaultprojectiles.lua")
local EmitterProjectile = import("/lua/sim/defaultprojectiles.lua").EmitterProjectile
local OnWaterEntryEmitterProjectile = import("/lua/sim/defaultprojectiles.lua").OnWaterEntryEmitterProjectile
local SingleBeamProjectile = import("/lua/sim/defaultprojectiles.lua").SingleBeamProjectile
local SinglePolyTrailProjectile = import("/lua/sim/defaultprojectiles.lua").SinglePolyTrailProjectile
local MultiPolyTrailProjectile = import("/lua/sim/defaultprojectiles.lua").MultiPolyTrailProjectile
local SingleCompositeEmitterProjectile = import("/lua/sim/defaultprojectiles.lua").SingleCompositeEmitterProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")
local DepthCharge = import("/lua/defaultantiprojectile.lua").DepthCharge
local NukeProjectile = import("/lua/sim/defaultprojectiles.lua").NukeProjectile
local DebrisComponent = import('/lua/sim/projectiles/components/DebrisComponent.lua').DebrisComponent
local TacticalMissileComponent = import('/lua/sim/defaultprojectiles.lua').TacticalMissileComponent

--#endregion