------------------------------------------------------------
--  File     :  /cdimage/lua/seraphimprojectiles.lua
--  Author(s):  Gordon Duclos, Greg Kohne, Matt Vainio, Aaron Lundquist
--  Summary  : Seraphim projectile base class definitions
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

--- Projectile Files
SIFHuAntiNuke = import('/lua/sim/projectiles/seraphim/SIFHuAntiNuke.lua').SIFHuAntiNuke
SIFKhuAntiNukeTendril = import('/lua/sim/projectiles/seraphim/SIFKhuAntiNukeTendril.lua').SIFKhuAntiNukeTendril
SIFKhuAntiNukeSmallTendril = import('/lua/sim/projectiles/seraphim/SIFKhuAntiNukeSmallTendril.lua').SIFKhuAntiNukeSmallTendril
SBaseTempProjectile = import('/lua/sim/projectiles/seraphim/SBaseTempProjectile.lua').SBaseTempProjectile
SChronatronCannon = import('/lua/sim/projectiles/seraphim/SChronatronCannon.lua').SChronatronCannon
SChronatronCannonOverCharge = import('/lua/sim/projectiles/seraphim/SChronatronCannonOverCharge.lua').SChronatronCannonOverCharge
SLightChronatronCannon = import('/lua/sim/projectiles/seraphim/SLightChronatronCannon.lua').SLightChronatronCannon
SLightChronatronCannonOverCharge = import('/lua/sim/projectiles/seraphim/SLightChronatronCannonOverCharge.lua').SLightChronatronCannonOverCharge
SPhasicAutogun = import('/lua/sim/projectiles/seraphim/SPhasicAutogun.lua').SPhasicAutogun
SHeavyPhasicAutogun = import('/lua/sim/projectiles/seraphim/SHeavyPhasicAutogun.lua').SHeavyPhasicAutogun
SHeavyPhasicAutogun02 = import('/lua/sim/projectiles/seraphim/SHeavyPhasicAutogun02.lua').SHeavyPhasicAutogun02
SOhCannon = import('/lua/sim/projectiles/seraphim/SOhCannon.lua').SOhCannon
SOhCannon02 = import('/lua/sim/projectiles/seraphim/SOhCannon02.lua').SOhCannon02
SShriekerAutoCannon = import('/lua/sim/projectiles/seraphim/SShriekerAutoCannon.lua').SShriekerAutoCannon
SAireauBolter = import('/lua/sim/projectiles/seraphim/SAireauBolter.lua').SAireauBolter
STauCannon = import('/lua/sim/projectiles/seraphim/STauCannon.lua').STauCannon
SHeavyQuarnonCannon = import('/lua/sim/projectiles/seraphim/SHeavyQuarnonCannon.lua').SHeavyQuarnonCannon
SLaanseTacticalMissile = import('/lua/sim/projectiles/seraphim/SLaanseTacticalMissile.lua').SLaanseTacticalMissile
SZthuthaamArtilleryShell = import('/lua/sim/projectiles/seraphim/SZthuthaamArtilleryShell.lua').SZthuthaamArtilleryShell
SSuthanusArtilleryShell = import('/lua/sim/projectiles/seraphim/SSuthanusArtilleryShell.lua').SSuthanusArtilleryShell
SSuthanusMobileArtilleryShell = import('/lua/sim/projectiles/seraphim/SSuthanusMobileArtilleryShell.lua').SSuthanusMobileArtilleryShell
SThunthoArtilleryShell = import('/lua/sim/projectiles/seraphim/SThunthoArtilleryShell.lua').SThunthoArtilleryShell
SThunthoArtilleryShell2 = import('/lua/sim/projectiles/seraphim/SThunthoArtilleryShell2.lua').SThunthoArtilleryShell2
SShleoAACannon = import('/lua/sim/projectiles/seraphim/SShleoAACannon.lua').SShleoAACannon
SOlarisAAArtillery = import('/lua/sim/projectiles/seraphim/SOlarisAAArtillery.lua').SOlarisAAArtillery
SLosaareAAAutoCannon = import('/lua/sim/projectiles/seraphim/SLosaareAAAutoCannon.lua').SLosaareAAAutoCannon
SLosaareAAAutoCannon02 = import('/lua/sim/projectiles/seraphim/SLosaareAAAutoCannon02.lua').SLosaareAAAutoCannon02
SOtheTacticalBomb = import('/lua/sim/projectiles/seraphim/SOtheTacticalBomb.lua').SOtheTacticalBomb
SAnaitTorpedo = import('/lua/sim/projectiles/seraphim/SAnaitTorpedo.lua').SAnaitTorpedo
SHeavyCavitationTorpedo = import('/lua/sim/projectiles/seraphim/SHeavyCavitationTorpedo.lua').SHeavyCavitationTorpedo
SUallCavitationTorpedo = import('/lua/sim/projectiles/seraphim/SUallCavitationTorpedo.lua').SUallCavitationTorpedo
SIFInainoStrategicMissile = import('/lua/sim/projectiles/seraphim/SIFInainoStrategicMissile.lua').SIFInainoStrategicMissile
SExperimentalStrategicMissile = import('/lua/sim/projectiles/seraphim/SExperimentalStrategicMissile.lua').SExperimentalStrategicMissile
SIMAntiMissile01 = import('/lua/sim/projectiles/seraphim/SIMAntiMissile01.lua').SIMAntiMissile01
SExperimentalStrategicBomb = import('/lua/sim/projectiles/seraphim/SExperimentalStrategicBomb.lua').SExperimentalStrategicBomb
SIFNukeWaveTendril = import('/lua/sim/projectiles/seraphim/SIFNukeWaveTendril.lua').SIFNukeWaveTendril
SIFNukeSpiralTendril = import('/lua/sim/projectiles/seraphim/SIFNukeSpiralTendril.lua').SIFNukeSpiralTendril
SEnergyLaser = import('/lua/sim/projectiles/seraphim/SEnergyLaser.lua').SEnergyLaser
SZhanaseeBombProjectile = import('/lua/sim/projectiles/seraphim/SZhanaseeBombProjectile.lua').SZhanaseeBombProjectile
SAAHotheFlareProjectile = import('/lua/sim/projectiles/seraphim/SAAHotheFlareProjectile.lua').SAAHotheFlareProjectile
SOhwalliStrategicBombProjectile = import('/lua/sim/projectiles/seraphim/SOhwalliStrategicBombProjectile.lua').SOhwalliStrategicBombProjectile
SAnjelluTorpedoDefenseProjectile = import('/lua/sim/projectiles/seraphim/SAnjelluTorpedoDefenseProjectile.lua').SAnjelluTorpedoDefenseProjectile
SDFSniperShotNormal = import('/lua/sim/projectiles/seraphim/SDFSniperShotNormal.lua').SDFSniperShotNormal
SDFSniperShot = import('/lua/sim/projectiles/seraphim/SDFSniperShot.lua').SDFSniperShot
SDFExperimentalPhasonProjectile = import('/lua/sim/projectiles/seraphim/SDFExperimentalPhasonProjectile.lua').SDFExperimentalPhasonProjectile
SDFSinnuntheWeaponProjectile = import('/lua/sim/projectiles/seraphim/SDFSinnuntheWeaponProjectile.lua').SDFSinnuntheWeaponProjectile
SDFAireauProjectile = import('/lua/sim/projectiles/seraphim/SDFAireauProjectile.lua').SDFAireauProjectile

-- kept for mod backwards compatibility
local DefaultProjectileFile = import("/lua/sim/defaultprojectiles.lua")
local util = import("/lua/utilities.lua")
local SingleBeamProjectile = DefaultProjectileFile.SingleBeamProjectile
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat
local SinglePolyTrailProjectile = DefaultProjectileFile.SinglePolyTrailProjectile
local MultiPolyTrailProjectile = DefaultProjectileFile.MultiPolyTrailProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")
local EmitterProjectile = DefaultProjectileFile.EmitterProjectile
local RandomInt = util.GetRandomInt
local NukeProjectile = DefaultProjectileFile.NukeProjectile