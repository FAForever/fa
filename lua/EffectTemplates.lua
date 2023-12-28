---@diagnostic disable:local-limit
-- ****************************************************************************
-- **
-- **  File     :  /data/lua/effecttemplates.lua
-- **  Author(s):  Gordon Duclos, Greg Kohne, Matt Vainio, Aaron Lundquist
-- **
-- **  Summary  :  Generic templates for commonly used effects
-- **
-- **  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************
EmtBpPath = '/effects/emitters/'
EmitterTempEmtBpPath = '/effects/emitters/temp/'

-- For gatling gun cooldown
WeaponSteam01 = {
    EmtBpPath .. 'weapon_mist_01_emit.bp',
}

-- ---------------------------------------------------------------
-- Concussion Ring Effects
-- ---------------------------------------------------------------
ConcussionRingSml01 = { EmtBpPath .. 'destruction_explosion_concussion_ring_02_emit.bp',}
ConcussionRingMed01 = { EmtBpPath .. 'destruction_explosion_concussion_ring_01_emit.bp',}
ConcussionRingLrg01 = { EmtBpPath .. 'destruction_explosion_concussion_ring_01_emit.bp',}


-- ---------------------------------------------------------------
-- Fire Cloud Effects
-- ---------------------------------------------------------------
FireCloudSml01 = {
    EmtBpPath .. 'fire_cloud_05_emit.bp',
    EmtBpPath .. 'fire_cloud_04_emit.bp',
    EmtBpPath .. 'small_test_sonic.bp',
    EmtBpPath .. 'small_test_fire.bp',
    EmtBpPath .. 'small_test_random.bp',
    EmtBpPath .. 'small_test_smoke.bp',
}

FireCloudMed01 = {
    EmtBpPath .. 'explosion_fire_sparks_01_emit.bp',
    EmtBpPath .. 'small_test_sonic.bp',
    EmtBpPath .. 'small_test_fire.bp',
    EmtBpPath .. 'small_test_random.bp',
    EmtBpPath .. 'small_test_smoke.bp',
}


-- ---------------------------------------------------------------
-- FireShadow Faked Flat Particle Effects
-- ---------------------------------------------------------------
FireShadowSml01 = { EmtBpPath .. 'destruction_explosion_fire_shadow_02_emit.bp',}
FireShadowMed01 = { EmtBpPath .. 'destruction_explosion_fire_shadow_01_emit.bp',}
FireShadowLrg01 = { EmtBpPath .. 'destruction_explosion_fire_shadow_01_emit.bp',}


-- ---------------------------------------------------------------
-- Flash Effects
-- ---------------------------------------------------------------
FlashSml01 = { EmtBpPath .. 'flash_01_emit.bp',}


-- ---------------------------------------------------------------
-- Flare Effects
-- ---------------------------------------------------------------
FlareSml01 = { EmtBpPath .. 'flare_01_emit.bp',}


-- ---------------------------------------------------------------
-- Smoke Effects
-- ---------------------------------------------------------------
SmokeSml01 = { EmtBpPath .. 'destruction_explosion_smoke_02_emit.bp',}
SmokeMed01 = { EmtBpPath .. 'destruction_explosion_smoke_04_emit.bp',}
SmokeLrg01 = {
    EmtBpPath .. 'destruction_explosion_smoke_03_emit.bp',
    EmtBpPath .. 'destruction_explosion_smoke_07_emit.bp',
}

SmokePlumeLightDensityMed01 = { EmtBpPath .. 'destruction_explosion_smoke_08_emit.bp',}
SmokePlumeMedDensitySml01 = { EmtBpPath .. 'destruction_explosion_smoke_06_emit.bp',}
SmokePlumeMedDensitySml02 = { EmtBpPath .. 'destruction_explosion_smoke_05_emit.bp',}
SmokePlumeMedDensitySml03 = { EmtBpPath .. 'destruction_explosion_smoke_11_emit.bp',}


-- ---------------------------------------------------------------
-- Wreckage Smoke Effects
-- ---------------------------------------------------------------

DefaultWreckageEffectsSml01 = table.concatenate(SmokePlumeLightDensityMed01, SmokePlumeMedDensitySml01, SmokePlumeMedDensitySml02, SmokePlumeMedDensitySml03)
DefaultWreckageEffectsSml01Count = table.getn(DefaultWreckageEffectsSml01)

DefaultWreckageEffectsMed01 = table.concatenate(SmokePlumeLightDensityMed01, SmokePlumeMedDensitySml01, SmokePlumeMedDensitySml02, SmokePlumeMedDensitySml03)
DefaultWreckageEffectsMed01Count = table.getn(DefaultWreckageEffectsMed01)

DefaultWreckageEffectsLrg01 = table.concatenate(SmokePlumeLightDensityMed01, SmokePlumeMedDensitySml01, SmokePlumeMedDensitySml02, SmokePlumeMedDensitySml01, SmokePlumeMedDensitySml02, SmokePlumeMedDensitySml01, SmokePlumeMedDensitySml02, SmokePlumeMedDensitySml03)
DefaultWreckageEffectsLrg01Count = table.getn(DefaultWreckageEffectsLrg01)


-- ---------------------------------------------------------------
-- Explosion Debris Effects
-- ---------------------------------------------------------------
ExplosionDebrisSml01 = {
    EmtBpPath .. 'destruction_explosion_debris_07_emit.bp',
    EmtBpPath .. 'destruction_explosion_debris_08_emit.bp',
    EmtBpPath .. 'destruction_explosion_debris_09_emit.bp',
}
ExplosionDebrisMed01 = {
    EmtBpPath .. 'destruction_explosion_debris_10_emit.bp',
    EmtBpPath .. 'destruction_explosion_debris_11_emit.bp',
    EmtBpPath .. 'destruction_explosion_debris_12_emit.bp',
}
ExplosionDebrisLrg01 = {
    EmtBpPath .. 'destruction_explosion_debris_01_emit.bp',
    EmtBpPath .. 'destruction_explosion_debris_02_emit.bp',
    EmtBpPath .. 'destruction_explosion_debris_03_emit.bp',
}


-- ---------------------------------------------------------------
-- Explosion Effects
-- ---------------------------------------------------------------
ExplosionEffectsSml01 = table.concatenate(FireShadowSml01, FlareSml01, FireCloudSml01, ExplosionDebrisSml01)
ExplosionEffectsMed01 = table.concatenate(FireShadowMed01, SmokeMed01, FireCloudMed01, ExplosionDebrisMed01)
ExplosionEffectsLrg01 = table.concatenate(FireShadowLrg01, SmokeLrg01, ExplosionDebrisLrg01)
ExplosionEffectsDefault01 = ExplosionEffectsMed01

DefaultHitExplosion01 = table.concatenate(FireCloudMed01, FlashSml01, FlareSml01, SmokeSml01)
DefaultHitExplosion02 = table.concatenate(FireCloudSml01, FlashSml01, FlareSml01, SmokeSml01)

Splashy = {
    EmtBpPath .. 'Watersplash_s.bp',
    EmtBpPath .. 'Water_pie_s.bp',
}

ExplosionSmallWater = {
    EmtBpPath .. 'Watertower_s.bp',
    EmtBpPath .. 'Water_pie_s.bp',
    EmtBpPath .. 'Watersplash_s.bp',

}

ExplosionMediumWater = {
    EmtBpPath .. 'Watertower_m.bp',
    EmtBpPath .. 'Water_pie.bp',
    EmtBpPath .. 'Watersplash_m.bp',

}

ExplosionLarge = {
    EmtBpPath .. 'Large_test_smoke.bp',
    EmtBpPath .. 'Large_test_fire.bp',
    EmtBpPath .. 'Large_test_random.bp',
    EmtBpPath .. 'Large_test_sonic.bp',
}

ExplosionSmallAir = {
    EmtBpPath .. 'small_test_sonic.bp',
    EmtBpPath .. 'small_test_fire.bp',
    EmtBpPath .. 'small_test_random.bp',
    EmtBpPath .. 'small_test_smoke.bp',
}

ExplosionSmall = {
    EmtBpPath .. 'dust_small_emit.bp',
    EmtBpPath .. 'small_test_sonic.bp',
    EmtBpPath .. 'small_test_fire.bp',
    EmtBpPath .. 'small_test_random.bp',
    EmtBpPath .. 'small_test_smoke.bp',
}
ExplosionMedium = {
    EmtBpPath .. 'dust_emit.bp',
    EmtBpPath .. 'Medium_test_smoke.bp',
    EmtBpPath .. 'Medium_test_fire.bp',
    EmtBpPath .. 'Medium_test_random.bp',
    EmtBpPath .. 'Medium_test_sonic.bp',
}
ExplosionEffectsLrg02 = {
    EmtBpPath .. 'destruction_explosion_flash_04_emit.bp',
    EmtBpPath .. 'destruction_explosion_flash_05_emit.bp',
}


-- ---------------------------------------------------------------
-- Ambient and Weather Effects
-- ---------------------------------------------------------------
WeatherTwister = {
    EmtBpPath .. 'weather_twister_01_emit.bp',
    EmtBpPath .. 'weather_twister_02_emit.bp',
    EmtBpPath .. 'weather_twister_03_emit.bp',
    EmtBpPath .. 'weather_twister_04_emit.bp',
}

-- ---------------------------------------------------------------
-- Operation Effects
-- ---------------------------------------------------------------
op_cratersmoke_01 = {
    EmtBpPath .. 'op_cratersmoke_01_emit.bp',
}

op_waterbubbles_01 = {
    EmtBpPath .. 'quarry_water_bubbles_emit.bp',
}

op_fire_01 = {
    EmtBpPath .. 'op_ambient_fire_01_emit.bp',
    EmtBpPath .. 'op_ambient_fire_02_emit.bp',
    EmtBpPath .. 'op_ambient_fire_03_emit.bp',
    EmtBpPath .. 'op_ambient_fire_04_emit.bp',
    EmtBpPath .. 'op_ambient_fire_05_emit.bp',
}

-- ---------------------------------------------------------------
-- Default Projectile Impact Effects
-- ---------------------------------------------------------------
DefaultMissileHit01 = table.concatenate(FireCloudSml01, FlashSml01, FlareSml01)
DefaultProjectileAirUnitImpact = {
    EmtBpPath .. 'destruction_unit_hit_flash_01_emit.bp',
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
}
DefaultProjectileLandImpact = {
    EmtBpPath .. 'projectile_dirt_impact_small_01_emit.bp',
    EmtBpPath .. 'projectile_dirt_impact_small_02_emit.bp',
    EmtBpPath .. 'projectile_dirt_impact_small_03_emit.bp',
    EmtBpPath .. 'projectile_dirt_impact_small_04_emit.bp',
}
DefaultProjectileLandUnitImpact = {
    EmtBpPath .. 'destruction_unit_hit_flash_01_emit.bp',
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
}
DefaultProjectileWaterImpact = {
    EmtBpPath .. 'destruction_water_splash_ripples_01_emit.bp',
    EmtBpPath .. 'destruction_water_splash_wash_01_emit.bp',
    EmtBpPath .. 'destruction_water_splash_plume_01_emit.bp',
}
DefaultProjectileUnderWaterImpact = {
    EmtBpPath .. 'destruction_underwater_explosion_flash_01_emit.bp',
    EmtBpPath .. 'destruction_underwater_explosion_flash_02_emit.bp',
    EmtBpPath .. 'destruction_underwater_explosion_splash_01_emit.bp',
}
DustDebrisLand01 = {
    EmtBpPath .. 'dust_cloud_02_emit.bp',
    EmtBpPath .. 'dust_cloud_04_emit.bp',
    EmtBpPath .. 'destruction_explosion_debris_04_emit.bp',
    EmtBpPath .. 'destruction_explosion_debris_05_emit.bp',
}
GenericDebrisLandImpact01 = {
    EmtBpPath .. 'dust_cloud_02_emit.bp',
    EmtBpPath .. 'dust_cloud_04_emit.bp',
    EmtBpPath .. 'destruction_explosion_debris_04_emit.bp',
    EmtBpPath .. 'destruction_explosion_debris_05_emit.bp',
}
GenericDebrisTrails01 = {
    EmtBpPath .. 'destruction_explosion_debris_trail_01_emit.bp',
}

TacticalDebrisTrails01 = {
    EmtBpPath .. 'tactical_debris_smoke_01_emit.bp',
    EmtBpPath .. 'tactical_debris_smoke_02_emit.bp',
    EmtBpPath .. 'tactical_debris_trail_01_emit.bp',
}

TacticalDebrisTrails02 = {
    EmtBpPath .. 'tactical_debris_fire_01_emit.bp',
    EmtBpPath .. 'tactical_debris_distortion_01_emit.bp',
    EmtBpPath .. 'tactical_debris_trail_01_emit.bp',
}

TacticalDebrisTrails03 = {
    EmtBpPath .. 'tactical_debris_smoke_03_emit.bp',
    EmtBpPath .. 'tactical_debris_smoke_04_emit.bp',
    EmtBpPath .. 'tactical_debris_trail_01_emit.bp',
}


UnitHitShrapnel01 = { EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',}

WaterSplash01 = {
    EmtBpPath .. 'water_splash_ripples_ring_01_emit.bp',
    EmtBpPath .. 'water_splash_plume_01_emit.bp',
}


-- ---------------------------------------------------------------
-- Default Unit Damage Effects
-- ---------------------------------------------------------------
DamageSmoke01 = { EmtBpPath .. 'destruction_damaged_smoke_01_emit.bp',}
DamageSparks01 = { EmtBpPath .. 'destruction_damaged_sparks_01_emit.bp',}
DamageFire01 = {
    EmtBpPath .. 'destruction_damaged_fire_01_emit.bp',
    EmtBpPath .. 'destruction_damaged_fire_distort_01_emit.bp',
}
DamageFireSmoke01 = table.concatenate(DamageSmoke01, DamageFire01)

DamageStructureSmoke01 = { EmtBpPath .. 'destruction_damaged_smoke_02_emit.bp',}
DamageStructureFire01 = {
    EmtBpPath .. 'destruction_damaged_fire_02_emit.bp',
    EmtBpPath .. 'destruction_damaged_fire_03_emit.bp',
    EmtBpPath .. 'destruction_damaged_fire_distort_02_emit.bp',
}
DamageStructureSparks01 = { EmtBpPath .. 'destruction_damaged_sparks_01_emit.bp',}
DamageStructureFireSmoke01 = table.concatenate(DamageStructureSmoke01, DamageStructureFire01)

-- ---------------------------------------------------------------
-- Ambient effects
-- ---------------------------------------------------------------

TreeBurning01 = {
    EmtBpPath .. 'forest_fire_01.bp',
    EmtBpPath .. 'forest_distortion_01.bp',
    EmtBpPath .. 'forest_smoke_01.bp',
}

-- ---------------------------------------------------------------
-- Shield Impact effects
-- ---------------------------------------------------------------
AeonShieldHit01 = {
    EmtBpPath .. '_test_shield_impact_emit.bp',
}
CybranShieldHit01 = {
    EmtBpPath .. '_test_shield_impact_emit.bp',
}
UEFShieldHit01 = {
    -- EmtBpPath .. 'shield_impact_terran_01_emit.bp',
    -- EmtBpPath .. 'shield_impact_terran_02_emit.bp',
    -- EmtBpPath .. 'shield_impact_terran_03_emit.bp',
    EmtBpPath .. '_test_shield_impact_emit.bp',
}
UEFAntiArtilleryShieldHit01 = {
    EmtBpPath .. 'shield_impact_large_01_emit.bp',
}
SeraphimShieldHit01 = {
    EmtBpPath .. '_test_shield_impact_emit.bp',
}

SeraphimSubCommanderGateway01 = {
    EmtBpPath .. 'seraphim_gate_01_emit.bp',
    -- EmtBpPath .. 'seraphim_gate_02_emit.bp',
    -- EmtBpPath .. 'seraphim_gate_03_emit.bp',
}

SeraphimSubCommanderGateway02 = {
    EmtBpPath .. 'seraphim_gate_04_emit.bp',
    EmtBpPath .. 'seraphim_gate_05_emit.bp',
}

SeraphimSubCommanderGateway03 = {
    EmtBpPath .. 'seraphim_gate_06_emit.bp',
}

SeraphimAirStagePlat01 = {
    EmtBpPath .. 'seraphim_airstageplat_01_emit.bp',
}

SeraphimAirStagePlat02 = {
    EmtBpPath .. 'seraphim_airstageplat_02_emit.bp',
}

-- ---------------------------------------------------------------
-- Teleport effects
-- ---------------------------------------------------------------
UnitTeleport01 = {
    EmtBpPath .. 'teleport_ring_01_emit.bp',
    EmtBpPath .. 'teleport_rising_mist_01_emit.bp',
    -- EmtBpPath .. '_test_commander_gate_explosion_01_emit.bp',
    EmtBpPath .. '_test_commander_gate_explosion_02_emit.bp',
    -- EmtBpPath .. '_test_commander_gate_explosion_03_emit.bp',
    EmtBpPath .. '_test_commander_gate_explosion_04_emit.bp',
    EmtBpPath .. '_test_commander_gate_explosion_05_emit.bp',
}

UnitTeleport02 = {
    -- EmtBpPath .. 'teleport_phosphor_01_emit.bp',
    EmtBpPath .. 'teleport_timing_01_emit.bp',
    EmtBpPath .. 'teleport_sparks_01_emit.bp',
    EmtBpPath .. 'teleport_ground_01_emit.bp',
    -- EmtBpPath .. 'teleport_sparks_02_emit.bp',
}

UnitTeleportSteam01 = {
    EmtBpPath .. 'teleport_commander_mist_01_emit.bp',
}

CommanderTeleport01 = {
    EmtBpPath .. 'teleport_ring_01_emit.bp',
    EmtBpPath .. 'teleport_rising_mist_01_emit.bp',
    EmtBpPath .. 'commander_teleport_01_emit.bp',
    EmtBpPath .. 'commander_teleport_02_emit.bp',
    EmtBpPath .. '_test_commander_gate_explosion_02_emit.bp',
    -- EmtBpPath .. '_test_commander_gate_explosion_04_emit.bp',
    -- EmtBpPath .. '_test_commander_gate_explosion_05_emit.bp',
}

CommanderQuantumGateInEnergy = {
    EmtBpPath .. 'energy_stream_01_emit.bp',
    EmtBpPath .. 'energy_stream_02_emit.bp',
    EmtBpPath .. 'energy_stream_03_emit.bp',
    EmtBpPath .. 'energy_stream_04_emit.bp',
    EmtBpPath .. 'energy_stream_05_emit.bp',
    EmtBpPath .. 'energy_stream_sparks_01_emit.bp',
    EmtBpPath .. 'energy_rays_01_emit.bp',
}

CloudFlareEffects01 = {
    '/effects/emitters/quantum_warhead_02_emit.bp',
    '/effects/emitters/quantum_warhead_04_emit.bp',
}

GenericTeleportCharge01 = {
    EmtBpPath .. 'generic_teleport_charge_01_emit.bp',
    EmtBpPath .. 'generic_teleport_charge_02_emit.bp',
    EmtBpPath .. 'generic_teleport_charge_03_emit.bp',
}

GenericTeleportCharge02 = {
    EmtBpPath .. 'generic_teleport_charge_04_emit.bp',
    EmtBpPath .. 'generic_teleport_charge_05_emit.bp',
    EmtBpPath .. 'generic_teleport_charge_06_emit.bp',
    EmtBpPath .. 'generic_teleport_charge_07_emit.bp',
    EmtBpPath .. 'generic_teleport_charge_08_emit.bp',
}

GenericTeleportOut01 = {
    EmtBpPath .. 'generic_teleportout_01_emit.bp',
    EmtBpPath .. 'generic_teleportin_05_emit.bp',
}

GenericTeleportIn01 = {
    EmtBpPath .. 'generic_teleportin_01_emit.bp',
    EmtBpPath .. 'generic_teleportin_02_emit.bp',
    EmtBpPath .. 'generic_teleportin_03_emit.bp',
    EmtBpPath .. 'generic_teleportin_04_emit.bp',
    EmtBpPath .. 'generic_teleportin_05_emit.bp',
}

GenericTeleportInWeapon01 = {
    EmtBpPath .. 'generic_teleportin_weapon_01_emit.bp',
}

UEFTeleportCharge01 = {
    EmtBpPath .. 'uef_teleport_charge_02_emit.bp',
    EmtBpPath .. 'uef_teleport_charge_03_emit.bp',
    EmtBpPath .. 'uef_teleport_charge_04_emit.bp',
    EmtBpPath .. 'uef_teleport_charge_09_emit.bp',
}

UEFTeleportCharge02 = {
    EmtBpPath .. 'uef_teleport_charge_01_emit.bp',
    EmtBpPath .. 'uef_teleport_charge_06_emit.bp',
    EmtBpPath .. 'uef_teleport_charge_05_emit.bp',
    EmtBpPath .. 'uef_teleport_charge_07_emit.bp',
    EmtBpPath .. 'uef_teleport_charge_08_emit.bp',
}

UEFTeleportOut01 = {
}

UEFTeleportIn01 = {
    EmtBpPath .. 'uef_teleportin_01_emit.bp',
    EmtBpPath .. 'uef_teleportin_02_emit.bp',
}

UEFTeleportInWeapon01 = {
    EmtBpPath .. 'uef_teleportin_weapon_01_emit.bp',
}

CybranTeleportCharge01 = {
    EmtBpPath .. 'cybran_teleport_charge_07_emit.bp',
    EmtBpPath .. 'cybran_teleport_charge_08_emit.bp',
}

CybranTeleportCharge02 = {
    EmtBpPath .. 'cybran_teleport_charge_01_emit.bp',
    EmtBpPath .. 'cybran_teleport_charge_02_emit.bp',
    EmtBpPath .. 'cybran_teleport_charge_03_emit.bp',
    EmtBpPath .. 'cybran_teleport_charge_04_emit.bp',
    EmtBpPath .. 'cybran_teleport_charge_05_emit.bp',
    EmtBpPath .. 'cybran_teleport_charge_06_emit.bp',
}

CybranTeleportOut01 = {
}

CybranTeleportIn01 = {
    EmtBpPath .. 'cybran_teleportin_01_emit.bp',
--    EmtBpPath .. 'cybran_teleportin_02_emit.bp',
    EmtBpPath .. 'cybran_teleportin_04_emit.bp',
    EmtBpPath .. 'cybran_teleportin_05_emit.bp',
    EmtBpPath .. 'cybran_teleportin_06_emit.bp',
    EmtBpPath .. 'cybran_teleportin_07_emit.bp',
    EmtBpPath .. 'cybran_teleportin_08_emit.bp',
    EmtBpPath .. 'cybran_teleportin_09_emit.bp',
}

CybranTeleportInWeapon01 = {
    EmtBpPath .. 'cybran_teleportin_weapon_01_emit.bp',
}

SeraphimTeleportCharge01 = {
    EmtBpPath .. 'seraphim_teleport_charge_01_emit.bp',
    EmtBpPath .. 'seraphim_teleport_charge_02_emit.bp',
}

SeraphimTeleportCharge02 = {
    EmtBpPath .. 'seraphim_teleport_charge_03_emit.bp',
    EmtBpPath .. 'seraphim_teleport_charge_04_emit.bp',
    EmtBpPath .. 'seraphim_teleport_charge_05_emit.bp',
    EmtBpPath .. 'seraphim_teleport_charge_06_emit.bp',
--    EmtBpPath .. 'seraphim_teleport_charge_07_emit.bp',
}

SeraphimTeleportOut01 = {
    EmtBpPath .. 'seraphim_rift_in_small_03_emit.bp',
    EmtBpPath .. 'seraphim_rift_in_small_04_emit.bp',
}

SeraphimTeleportIn01 = {
    EmtBpPath .. 'seraphim_rift_in_large_03_emit.bp',
    EmtBpPath .. 'seraphim_rift_in_large_04_emit.bp',
}

SeraphimTeleportIn02 = {
    EmtBpPath .. 'seraphim_rift_in_small_03_emit.bp',
    EmtBpPath .. 'seraphim_rift_in_small_04_emit.bp',
}

SeraphimTeleportInWeapon01 = {
    EmtBpPath .. 'seraphim_teleportin_weapon_01_emit.bp',
}


-- ---------------------------------------------------------------
-- -- -- -- UNIT CONSTRUCTION -- -- --

-- ---------------------------------------------------------------
-- Build Effects
-- ---------------------------------------------------------------
DefaultBuildUnit01 = { EmtBpPath .. 'default_build_01_emit.bp'}

AeonBuildBeams01 = {
    EmtBpPath .. 'aeon_build_beam_01_emit.bp',
    EmtBpPath .. 'aeon_build_beam_02_emit.bp',
    EmtBpPath .. 'aeon_build_beam_03_emit.bp',
}
AeonBuildBeams02 = {
    EmtBpPath .. 'aeon_build_beam_04_emit.bp',
    EmtBpPath .. 'aeon_build_beam_05_emit.bp',
    EmtBpPath .. 'aeon_build_beam_06_emit.bp',
}

AeonVolcanoBeam01 = {
    EmtBpPath .. 'aeon_volcano_beam_01.bp',
    EmtBpPath .. 'aeon_volcano_beam_02.bp',
    EmtBpPath .. 'aeon_volcano_beam_03.bp',
}

CybranBuildUnitBlink01 = { EmtBpPath .. 'build_cybran_blink_blue_01_emit.bp'}
CybranBuildFlash01 =  EmtBpPath .. 'build_cybran_spark_flash_03_emit.bp'
CybranBuildSparks01 =  EmtBpPath .. 'build_sparks_blue_01_emit.bp'
CybranFactoryBuildSparksLeft01 = {
    EmtBpPath .. 'sparks_04_emit.bp',
    EmtBpPath .. 'build_cybran_spark_flash_02_emit.bp',
}
CybranFactoryBuildSparksRight01 = {
    EmtBpPath .. 'sparks_03_emit.bp',
    EmtBpPath .. 'build_cybran_spark_flash_01_emit.bp',
}
CybranUnitBuildSparks01 = {
    EmtBpPath .. 'build_cybran_sparks_01_emit.bp',
    EmtBpPath .. 'build_cybran_sparks_02_emit.bp',
    EmtBpPath .. 'build_cybran_sparks_03_emit.bp',
}

SeraphimBuildBeams01 = {
    EmtBpPath .. 'seraphim_build_beam_01_emit.bp',
    EmtBpPath .. 'seraphim_build_beam_02_emit.bp',
}

-- ---------------------------------------------------------------
-- Reclaim Effects
-- ---------------------------------------------------------------
ReclaimBeams = {
    EmtBpPath .. 'reclaim_beam_01_emit.bp',
    EmtBpPath .. 'reclaim_beam_02_emit.bp',
    EmtBpPath .. 'reclaim_beam_03_emit.bp',
    EmtBpPath .. 'reclaim_beam_04_emit.bp',
    EmtBpPath .. 'reclaim_beam_05_emit.bp',
}

ReclaimObjectAOE = { '/effects/emitters/reclaim_01_emit.bp' }
ReclaimObjectEnd = { '/effects/emitters/reclaim_02_emit.bp' }


-- ---------------------------------------------------------------
-- Capture Effects
-- ---------------------------------------------------------------
CaptureBeams = {
    EmtBpPath .. 'capture_beam_01_emit.bp',
    EmtBpPath .. 'capture_beam_02_emit.bp',
    EmtBpPath .. 'capture_beam_03_emit.bp',
}


-- ---------------------------------------------------------------
-- Upgrade Effects
-- ---------------------------------------------------------------
UpgradeUnitAmbient = {
    EmtBpPath .. 'unit_upgrade_ambient_01_emit.bp',
    EmtBpPath .. 'unit_upgrade_ambient_02_emit.bp',
}
UpgradeBoneAmbient = {
    EmtBpPath .. 'unit_upgrade_bone_ambient_01_emit.bp',
}


-- ---------------------------------------------------------------
-- -- -- -- UNIT TRANSPORT BEAMS -- -- --

-- ---------------------------------------------------------------
-- Terran Transport Beam Effects
-- ---------------------------------------------------------------
TTransportBeam01 = EmtBpPath .. 'terran_transport_beam_01_emit.bp'                  -- Unit to Transport beam
TTransportBeam02 = EmtBpPath .. 'terran_transport_beam_02_emit.bp'                  -- Transport to Unit beam
ACollossusTractorBeam01 = EmtBpPath .. 'collossus_tractor_beam_01_emit.bp'          -- This is just for the colossus beam and how it will tractor beam stuff.
ACollossusTractorBeamGlow01 = EmtBpPath .. 'collossus_tractor_beam_glow_01_emit.bp' -- Glow on the colossus tractor beam.
ACollossusTractorBeamGlow02 = EmtBpPath .. 'collossus_tractor_beam_glow_02_emit.bp' -- Glow on the colossus tractor beam.
ACollossusTractorBeamGlow02 = EmtBpPath .. 'collossus_tractor_beam_glow_03_emit.bp' -- Glow on the colossus tractor beam.
ACollossusTractorBeamVacuum01 = {
        EmtBpPath .. 'collossus_vacuum_grab_01_emit.bp',
}
TTransportGlow01 = EmtBpPath .. 'terran_transport_glow_01_emit.bp'
TTransportGlow02 = EmtBpPath .. 'terran_transport_glow_02_emit.bp'
TTransportBeam03 = EmtBpPath .. 'terran_transport_beam_03_emit.bp'                  -- Transport to Unit beam

ACollossusTractorBeamCrush01 = {
    EmtBpPath .. 'collossus_crush_explosion_01_emit.bp',
    EmtBpPath .. 'collossus_crush_explosion_02_emit.bp',
}

-- ---------------------------------------------------------------
-- -- -- -- UNIT MOVEMENT -- -- --

-- ---------------------------------------------------------------
-- Sea Unit Environmental Effects
-- ---------------------------------------------------------------
DefaultSeaUnitBackWake01 = {
    EmtBpPath .. 'water_move_trail_back_01_emit.bp',
    EmtBpPath .. 'water_move_trail_back_r_01_emit.bp',
    EmtBpPath .. 'water_move_trail_back_l_01_emit.bp',
}

DefaultSeaUnitIdle01 = { EmtBpPath .. 'water_idle_ripples_02_emit.bp',}
DefaultUnderWaterUnitWake01 = { EmtBpPath .. 'underwater_move_trail_01_emit.bp',}
DefaultUnderWaterIdle01 = { EmtBpPath .. 'underwater_idle_bubbles_01_emit.bp',}

-- ---------------------------------------------------------------
-- Land Unit Environmental Effects
-- ---------------------------------------------------------------
DustBrownMove01 = { EmtBpPath .. 'land_move_brown_dust_01_emit.bp',}
FootFall01 = {
    EmtBpPath .. 'tt_dirt02_footfall01_01_emit.bp',
    EmtBpPath .. 'tt_dirt02_footfall01_02_emit.bp',
}

-- ---------------------------------------------------------------
-- -- -- -- AEON UNIT AMBIENT EFFECTS -- -- --
-- ---------------------------------------------------------------
AT1PowerAmbient = {
    EmtBpPath .. 'aeon_t1power_ambient_01_emit.bp',
    EmtBpPath .. 'aeon_t1power_ambient_02_emit.bp',
}

AT2MassCollAmbient = {
    EmtBpPath .. 'aeon_t2masscoll_ambient_01_emit.bp',
}

AT2PowerAmbient = {
    EmtBpPath .. 'aeon_t2power_ambient_01_emit.bp',
    EmtBpPath .. 'aeon_t2power_ambient_02_emit.bp',
}

AT3PowerAmbient = {
    EmtBpPath .. 'aeon_t3power_ambient_01_emit.bp',
    EmtBpPath .. 'aeon_t3power_ambient_02_emit.bp',
}

AQuantumGateAmbient = {
    EmtBpPath .. 'aeon_gate_01_emit.bp',
    EmtBpPath .. 'aeon_gate_02_emit.bp',
    EmtBpPath .. 'aeon_gate_03_emit.bp',
}

ATractorAmbient = {
    EmtBpPath .. 'tractor_01_emit.bp',
    EmtBpPath .. 'tractor_02_emit.bp',
    EmtBpPath .. 'tractor_03_emit.bp',
}


AResourceGenAmbient = {
    EmtBpPath .. 'aeon_rgen_ambient_01_emit.bp',
    EmtBpPath .. 'aeon_rgen_ambient_02_emit.bp',
    EmtBpPath .. 'aeon_rgen_ambient_03_emit.bp',
}

ASacrificeOfTheAeon01 = {
    '/effects/emitters/aeon_sacrifice_01_emit.bp',
    '/effects/emitters/aeon_sacrifice_02_emit.bp',
    '/effects/emitters/aeon_sacrifice_03_emit.bp',
}

ASacrificeOfTheAeon02 = {
    '/effects/emitters/aeon_sacrifice_04_emit.bp',
}

AeonOpWeapDisable = {
    EmtBpPath .. 'op_aeon_weapdisable_01_emit.bp',
    EmtBpPath .. 'op_aeon_weapdisable_02_emit.bp',
}

AeonOpHackACU = {
    EmtBpPath .. 'op_aeon_hackacu_01_emit.bp',
    EmtBpPath .. 'op_aeon_hackacu_02_emit.bp',
    EmtBpPath .. 'op_aeon_hackacu_03_emit.bp',
}

-- ---------------------------------------------------------------
-- -- -- -- AEON PROJECTILES -- -- --

AMercyGuidedMissileSplit = {
    EmtBpPath .. 'aeon_mercy_guided_missile_split_01.bp',
    EmtBpPath .. 'aeon_mercy_guided_missile_split_02.bp',
}

AMercyGuidedMissileSplitMissileHit = {
    EmtBpPath ..'aeon_mercy_missile_hit_01_emit.bp',
}

AMercyGuidedMissileSplitMissileHitLand = {
    EmtBpPath ..'aeon_mercy_missile_hit_land_01_emit.bp',
    EmtBpPath ..'aeon_mercy_missile_hit_land_02_emit.bp',
}

AMercyGuidedMissileSplitMissileHitUnit = {
    EmtBpPath ..'aeon_mercy_missile_hit_01_emit.bp',
    EmtBpPath ..'aeon_mercy_missile_hit_land_02_emit.bp',
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
}

AMercyGuidedMissilePolyTrail = EmtBpPath .. 'aeon_mercy_missile_polytrail_01_emit.bp'

AMercyGuidedMissileFxTrails = {
    EmtBpPath .. 'aeon_mercy_missile_fxtrail_01_emit.bp',
}

AMercyGuidedMissileExhaustFxTrails = {
    EmtBpPath .. 'aeon_mercy_missile_thruster_beam_01_emit.bp',
}



AQuasarAntiTorpedoPolyTrails = {
    EmtBpPath .. 'aeon_quasar_antitorpedo_polytrail_01_emit.bp',
    EmtBpPath .. 'aeon_quasar_antitorpedo_polytrail_02_emit.bp',
}

AQuasarAntiTorpedoFxTrails= {
}

AQuasarAntiTorpedoFlash= {
    EmtBpPath .. 'aeon_quasar_antitorpedo_flash_01_emit.bp',
}

AQuasarAntiTorpedoHit= {
    EmtBpPath .. 'aeon_quasar_antitorpedo_hit_01_emit.bp',
    EmtBpPath .. 'aeon_quasar_antitorpedo_hit_02_emit.bp',
    EmtBpPath .. 'aeon_quasar_antitorpedo_hit_03_emit.bp',
    EmtBpPath .. 'aeon_quasar_antitorpedo_hit_04_emit.bp',
}

AQuasarAntiTorpedoLandHit= {
}

AQuasarAntiTorpedoUnitHit= {
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
}


AAntiMissileFlare = {
    EmtBpPath .. 'aeon_missiled_wisp_01_emit.bp',
    EmtBpPath .. 'aeon_missiled_wisp_02_emit.bp',
    EmtBpPath .. 'aeon_missiled_wisp_04_emit.bp',
}

AAntiMissileFlareFlash = {
    EmtBpPath .. 'aeon_missiled_flash_01_emit.bp',
    EmtBpPath .. 'aeon_missiled_flash_02_emit.bp',
    EmtBpPath .. 'aeon_missiled_flash_03_emit.bp',
}
AAntiMissileFlareHit = {
    EmtBpPath .. 'aeon_missiled_hit_01_emit.bp',
    EmtBpPath .. 'aeon_missiled_hit_02_emit.bp',
    EmtBpPath .. 'aeon_missiled_hit_03_emit.bp',
    EmtBpPath .. 'aeon_missiled_hit_04_emit.bp',
}

ABeamHit01 = {
    EmtBpPath .. 'beam_hit_sparks_01_emit.bp',
    EmtBpPath .. 'beam_hit_smoke_01_emit.bp',
}
ABeamHitUnit01 = ABeamHit01
ABeamHitLand01 = ABeamHit01

ABombHit01 = {
    EmtBpPath .. 'aeon_bomber_hit_01_emit.bp',
    EmtBpPath .. 'aeon_bomber_hit_02_emit.bp',
    EmtBpPath .. 'aeon_bomber_hit_03_emit.bp',
    EmtBpPath .. 'aeon_bomber_hit_04_emit.bp',
}

AChronoDampener = {
    EmtBpPath .. 'aeon_chrono_dampener_01_emit.bp',
    EmtBpPath .. 'aeon_chrono_dampener_02_emit.bp',
    EmtBpPath .. 'aeon_chrono_dampener_03_emit.bp',
    EmtBpPath .. 'aeon_chrono_dampener_04_emit.bp',
}

AChronoDampenerLarge = {
    EmtBpPath .. 'aeon_chrono_dampener_large_01_emit.bp',
    EmtBpPath .. 'aeon_chrono_dampener_large_02_emit.bp',
    EmtBpPath .. 'aeon_chrono_dampener_large_03_emit.bp',
    EmtBpPath .. 'aeon_chrono_dampener_large_04_emit.bp',
}

ACommanderOverchargeFlash01 = {
    EmtBpPath .. 'aeon_commander_overcharge_flash_01_emit.bp',
    EmtBpPath .. 'aeon_commander_overcharge_flash_02_emit.bp',
    EmtBpPath .. 'aeon_commander_overcharge_flash_03_emit.bp',
}

ACommanderOverchargeFXTrail01 = {
    EmtBpPath .. 'aeon_commander_overcharge_01_emit.bp',
    EmtBpPath .. 'aeon_commander_overcharge_02_emit.bp',
}

ACommanderOverchargeHit01 = {
    EmtBpPath .. 'aeon_commander_overcharge_hit_01_emit.bp',
    EmtBpPath .. 'aeon_commander_overcharge_hit_02_emit.bp',
}

ADepthCharge01 = { EmtBpPath .. 'harmonic_depth_charge_resonance_01_emit.bp',}
ADepthChargeHitUnit01 = DefaultProjectileUnderWaterImpact
ADepthChargeHitUnderWaterUnit01 = table.concatenate(ADepthCharge01, DefaultProjectileUnderWaterImpact)

ADisruptorCannonMuzzle01 = {
    EmtBpPath .. 'adisruptor_cannon_muzzle_01_emit.bp',
    EmtBpPath .. 'disruptor_cannon_muzzle_01_emit.bp',
    EmtBpPath .. 'disruptor_cannon_muzzle_02_emit.bp',
    EmtBpPath .. 'disruptor_cannon_muzzle_03_emit.bp',
}

ADisruptorMunition01 = {
    EmtBpPath .. 'adisruptor_cannon_munition_01_emit.bp',
}

ADisruptorHit01 = {
    EmtBpPath .. 'adisruptor_hit_01_emit.bp',
}

ADisruptorHitShield = {
    EmtBpPath .. '_test_shield_impact_emit.bp',
}

ASDisruptorCannonMuzzle01 = {
    EmtBpPath .. 'disruptor_cannon_muzzle_03_emit.bp',
    EmtBpPath .. 'disruptor_cannon_muzzle_04_emit.bp',
    EmtBpPath .. 'disruptor_cannon_muzzle_05_emit.bp',
    EmtBpPath .. 'disruptor_cannon_muzzle_06_emit.bp',
}

ASDisruptorCannonChargeMuzzle01 = {
    EmtBpPath .. 'disruptor_cannon_muzzle_01_emit.bp',
    EmtBpPath .. 'disruptor_cannon_muzzle_02_emit.bp',
}

ASDisruptorPolytrail01 =  EmtBpPath .. 'disruptor_cannon_polytrail_01_emit.bp'

ASDisruptorMunition01 = {
    EmtBpPath .. 'disruptor_cannon_munition_01_emit.bp',
    EmtBpPath .. 'disruptor_cannon_munition_02_emit.bp',
    EmtBpPath .. 'disruptor_cannon_munition_03_emit.bp',
    EmtBpPath .. 'disruptor_cannon_munition_04_emit.bp',
}

ASDisruptorHit01 = {
    EmtBpPath .. 'disruptor_hit_01_emit.bp',
    EmtBpPath .. 'disruptor_hit_02_emit.bp',
    EmtBpPath .. 'disruptor_hit_03_emit.bp',
    EmtBpPath .. 'disruptor_hit_04_emit.bp',
    EmtBpPath .. 'disruptor_hit_05_emit.bp',
}

ASDisruptorHitUnit01 = {
    EmtBpPath .. 'disruptor_hitunit_01_emit.bp',
    EmtBpPath .. 'disruptor_hitunit_02_emit.bp',
    EmtBpPath .. 'disruptor_hitunit_03_emit.bp',
    EmtBpPath .. 'disruptor_hitunit_04_emit.bp',
}

ASDisruptorHitShield = {
    EmtBpPath .. 'disruptor_hit_shield_emit.bp',
    EmtBpPath .. 'disruptor_hit_shield_02_emit.bp',
    EmtBpPath .. 'disruptor_hit_shield_03_emit.bp',
    EmtBpPath .. 'disruptor_hit_shield_04_emit.bp',
    EmtBpPath .. 'disruptor_hit_shield_05_emit.bp',
    EmtBpPath .. 'disruptor_hit_shield_06_emit.bp',
}

AHighIntensityLaserHit01 = {
    EmtBpPath .. 'laserturret_hit_flash_04_emit.bp',
    EmtBpPath .. 'laserturret_hit_flash_05_emit.bp',
    EmtBpPath .. 'laserturret_hit_flash_09_emit.bp',
}
AHighIntensityLaserHitUnit01 = table.concatenate(AHighIntensityLaserHit01, UnitHitShrapnel01)
AHighIntensityLaserHitLand01 = table.concatenate(AHighIntensityLaserHit01)
AHighIntensityLaserFlash01   = {
    -- EmtBpPath .. 'aeon_laser_highintensity_flash_01_emit.bp',
    EmtBpPath .. 'aeon_laser_highintensity_flash_02_emit.bp',
}

AGravitonBolterHit01 = {
    EmtBpPath .. 'graviton_bolter_hit_02_emit.bp',
    EmtBpPath .. 'sparks_07_emit.bp',
}
AGravitonBolterMuzzleFlash01 = {
    EmtBpPath .. 'graviton_bolter_flash_01_emit.bp',
}

ALaserBotHit01 = {
    EmtBpPath .. 'laserturret_hit_flash_04_emit.bp',
    EmtBpPath .. 'laserturret_hit_flash_05_emit.bp',
}
ALaserBotHitUnit01 = table.concatenate(ALaserBotHit01, UnitHitShrapnel01)
ALaserBotHitLand01 = table.concatenate(ALaserBotHit01)

ALaserHit01 = { EmtBpPath .. 'laserturret_hit_flash_02_emit.bp',}
ALaserHitUnit01 = table.concatenate(ALaserHit01, UnitHitShrapnel01)
ALaserHitLand01 = table.concatenate(ALaserHit01)

ALightLaserHit01 = { EmtBpPath .. 'laserturret_hit_flash_07_emit.bp',}
ALightLaserHit02 = {
    EmtBpPath .. 'laserturret_hit_flash_07_emit.bp',
    EmtBpPath .. 'laserturret_hit_flash_08_emit.bp',
}

ALightLaserHitUnit01 = table.concatenate(ALightLaserHit02, UnitHitShrapnel01)

ALightMortarHit01 = {
    EmtBpPath .. 'aeon_light_shell_01_emit.bp',
    EmtBpPath .. 'aeon_light_shell_02_emit.bp',
    EmtBpPath .. 'aeon_light_shell_03_emit.bp',
    -- EmtBpPath .. 'aeon_light_shell_05_emit.bp',
}

AIFBallisticMortarHit01 = {
    EmtBpPath .. 'aeon_light_shell_01_emit.bp',
    EmtBpPath .. 'aeon_light_shell_02_emit.bp',
    EmtBpPath .. 'aeon_light_shell_03_emit.bp',
}

AIFBallisticMortarTrails01 = {
    EmtBpPath .. 'quark_bomb_01_emit.bp',
    EmtBpPath .. 'quark_bomb_02_emit.bp',
    EmtBpPath .. 'quark_bomb_03_emit.bp',
}

AIFBallisticMortarFxTrails02 = {
    EmtBpPath .. 'aeon_mortar02_fxtrail_01_emit.bp',
    EmtBpPath .. 'aeon_mortar02_fxtrail_02_emit.bp',
}

AIFBallisticMortarTrails02 = {
    EmtBpPath .. 'aeon_mortar02_polytrail_01_emit.bp',
    EmtBpPath .. 'aeon_mortar02_polytrail_02_emit.bp',
}

AIFBallisticMortarFlash02 = {
    EmtBpPath .. 'aeon_mortar02_flash_01_emit.bp',
    EmtBpPath .. 'aeon_mortar02_flash_02_emit.bp',
    EmtBpPath .. 'aeon_mortar02_flash_03_emit.bp',
    EmtBpPath .. 'aeon_mortar02_flash_04_emit.bp',
}

AIFBallisticMortarHitUnit02 = {
    EmtBpPath .. 'aeon_mortar02_shell_01_emit.bp',
    EmtBpPath .. 'aeon_mortar02_shell_02_emit.bp',
    EmtBpPath .. 'aeon_mortar02_shell_03_emit.bp',
    EmtBpPath .. 'aeon_mortar02_shell_04_emit.bp',
}

AIFBallisticMortarHitLand02 = {
    EmtBpPath .. 'aeon_mortar02_shell_01_emit.bp',
    EmtBpPath .. 'aeon_mortar02_shell_02_emit.bp',
    EmtBpPath .. 'aeon_mortar02_shell_03_emit.bp',
    EmtBpPath .. 'aeon_mortar02_shell_04_emit.bp',
}


AMiasmaMunition01 = {
    EmtBpPath .. 'miasma_munition_trail_01_emit.bp',
}
AMiasmaMunition02 = {
    EmtBpPath .. 'miasma_cloud_02_emit.bp',
}

AMiasma01 = {
    EmtBpPath .. 'miasma_munition_burst_01_emit.bp',
}

AMiasmaField01 = {
    EmtBpPath .. 'miasma_cloud_01_emit.bp',
}

AMissileHit01 = DefaultMissileHit01

ASerpFlash01 = {
    EmtBpPath .. 'aeon_serp_flash_01_emit.bp',
    EmtBpPath .. 'aeon_serp_flash_02_emit.bp',
    EmtBpPath .. 'aeon_serp_flash_03_emit.bp',
}

AOblivionCannonHit01 = {
    EmtBpPath .. 'oblivion_cannon_hit_01_emit.bp',
    EmtBpPath .. 'oblivion_cannon_hit_02_emit.bp',
    EmtBpPath .. 'oblivion_cannon_hit_03_emit.bp',
    EmtBpPath .. 'oblivion_cannon_hit_04_emit.bp',
}

AOblivionCannonHit02 = {
    EmtBpPath .. 'oblivion_cannon_hit_05_emit.bp',
    EmtBpPath .. 'oblivion_cannon_hit_06_emit.bp',
    EmtBpPath .. 'oblivion_cannon_hit_07_emit.bp',
    EmtBpPath .. 'oblivion_cannon_hit_08_emit.bp',
    EmtBpPath .. 'oblivion_cannon_hit_09_emit.bp',
    EmtBpPath .. 'oblivion_cannon_hit_10_emit.bp',
    EmtBpPath .. 'oblivion_cannon_hit_11_emit.bp',
    EmtBpPath .. 'oblivion_cannon_hit_12_emit.bp',
    EmtBpPath .. 'oblivion_cannon_hit_13_emit.bp',
}

AOblivionCannonHit03 = {
    EmtBpPath .. 'oblivion_cannon_hit_14_emit.bp',
    EmtBpPath .. 'oblivion_cannon_hit_15_emit.bp',
}

AOblivionCannonFXTrails02 = {
    EmtBpPath .. 'oblivion_cannon_munition_03_emit.bp',
    EmtBpPath .. 'oblivion_cannon_munition_04_emit.bp',
}

AOblivionCannonFXTrails03 = {
    EmtBpPath .. 'oblivion_cannon_munition_05_emit.bp',
    EmtBpPath .. 'oblivion_cannon_munition_06_emit.bp',
}

AOblivionCannonMuzzleFlash02 = {
    EmtBpPath .. 'oblivion_cannon_flash_10_emit.bp',
    EmtBpPath .. 'oblivion_cannon_flash_11_emit.bp',
    EmtBpPath .. 'oblivion_cannon_flash_12_emit.bp',
    EmtBpPath .. 'oblivion_cannon_flash_13_emit.bp',
}

AOblivionCannonChargeMuzzleFlash02 = {
    EmtBpPath .. 'oblivion_cannon_flash_07_emit.bp',
    EmtBpPath .. 'oblivion_cannon_flash_08_emit.bp',
    EmtBpPath .. 'oblivion_cannon_flash_09_emit.bp',
}

AQuantumCannonMuzzle01 = {
    EmtBpPath .. 'disruptor_cannon_muzzle_01_emit.bp',
    EmtBpPath .. 'quantum_cannon_muzzle_flash_04_emit.bp',
    EmtBpPath .. 'aeon_light_tank_muzzle_charge_01_emit.bp',
    EmtBpPath .. 'aeon_light_tank_muzzle_charge_02_emit.bp',
}
AQuantumCannonMuzzle02 = {                      -- tweaked version for ships
    EmtBpPath .. 'disruptor_cannon_muzzle_01_emit.bp',
    EmtBpPath .. 'quantum_cannon_muzzle_flash_04_emit.bp',
    EmtBpPath .. 'quantum_cannon_muzzle_charge_s01_emit.bp',
    EmtBpPath .. 'quantum_cannon_muzzle_charge_s02_emit.bp',
}
AQuantumCannonHit01 = {
    EmtBpPath .. 'quantum_hit_flash_04_emit.bp',
    EmtBpPath .. 'quantum_hit_flash_05_emit.bp',
    EmtBpPath .. 'quantum_hit_flash_06_emit.bp',
    EmtBpPath .. 'quantum_hit_flash_07_emit.bp',
    EmtBpPath .. 'quantum_hit_flash_08_emit.bp',
    EmtBpPath .. 'quantum_hit_flash_09_emit.bp',
}
AQuantumDisruptor01 = {
    EmtBpPath .. 'aeon_commander_disruptor_01_emit.bp',
    EmtBpPath .. 'aeon_commander_disruptor_02_emit.bp',
}
AQuantumDisruptorHit01 = {
    EmtBpPath .. 'aeon_commander_disruptor_hit_01_emit.bp',
    EmtBpPath .. 'aeon_commander_disruptor_hit_02_emit.bp',
    EmtBpPath .. 'aeon_commander_disruptor_hit_03_emit.bp',
}

AQuantumDisruptorHitWater01 = {
    EmtBpPath .. 'aeon_commander_disruptor_hit_01_emit.bp',
    EmtBpPath .. 'aeon_commander_disruptor_hit_02_emit.bp',
}

AQuantumDisplacementHit01 = {
    EmtBpPath .. 'quantum_displacement_cannon_hit_01_emit.bp',
    EmtBpPath .. 'quantum_displacement_cannon_hit_02_emit.bp',
}
AQuantumDisplacementTeleport01 = {
    EmtBpPath .. 'sparks_07_emit.bp',
    EmtBpPath .. 'teleport_01_emit.bp',
}
AQuarkBomb01 = {
    EmtBpPath .. 'quark_bomb_01_emit.bp',
    EmtBpPath .. 'quark_bomb_02_emit.bp',
    EmtBpPath .. 'sparks_06_emit.bp',
}
AQuarkBomb02 = {                                   -- A larger version of AQuarkBomb01
    EmtBpPath .. 'quark_bomb2_01_emit.bp',
    EmtBpPath .. 'quark_bomb2_02_emit.bp',
    EmtBpPath .. 'sparks_11_emit.bp',
}
AQuarkBombHit01 = {
    EmtBpPath .. 'quark_bomb_explosion_03_emit.bp',
    EmtBpPath .. 'quark_bomb_explosion_04_emit.bp',
    EmtBpPath .. 'quark_bomb_explosion_05_emit.bp',
    EmtBpPath .. 'quark_bomb_explosion_07_emit.bp',
    EmtBpPath .. 'quark_bomb_explosion_08_emit.bp',
    EmtBpPath .. 'quark_bomb_chrono_effect_01_emit.bp',
    EmtBpPath .. 'quark_bomb_chrono_effect_02_emit.bp',
}
AQuarkBombHit02 = {
    EmtBpPath .. 'quark_bomb_explosion_03_emit.bp',
    EmtBpPath .. 'quark_bomb_explosion_06_emit.bp',
}
AQuarkBombHitUnit01 = AQuarkBombHit01
AQuarkBombHitAirUnit01 = AQuarkBombHit02
AQuarkBombHitLand01 = AQuarkBombHit01

APhasonLaserMuzzle01 = {
    EmtBpPath .. 'phason_laser_muzzle_01_emit.bp',
    EmtBpPath .. 'phason_laser_muzzle_02_emit.bp',
}

APhasonLaserImpact01 = {
    EmtBpPath .. 'phason_laser_end_01_emit.bp',
    EmtBpPath .. 'phason_laser_end_02_emit.bp',
}

AReactonCannon01 = {
    EmtBpPath .. 'flash_06_emit.bp',
    EmtBpPath .. 'reacton_cannon_hit_03_emit.bp',
    EmtBpPath .. 'reacton_cannon_hit_04_emit.bp',
    EmtBpPath .. 'reacton_cannon_hit_05_emit.bp',
    EmtBpPath .. 'reacton_cannon_hit_06_emit.bp',
}
AReactonCannon02 = {
    EmtBpPath .. 'flash_06_emit.bp',
    EmtBpPath .. 'sparks_10_emit.bp',
    EmtBpPath .. 'reacton_cannon_hit_01_emit.bp',
    EmtBpPath .. 'reacton_cannon_hit_02_emit.bp',
}
AReactonCannonHitUnit01 = AReactonCannon01
AReactonCannonHitUnit02 = AReactonCannon02
AReactonCannonHitLand01 = AReactonCannon01
AReactonCannonHitLand02 = AReactonCannon02

ASaintLaunch01 =
{
    EmtBpPath .. 'flash_03_emit.bp',
    EmtBpPath .. 'saint_launch_01_emit.bp',
    EmtBpPath .. 'saint_launch_02_emit.bp',
}

ASaintImpact01 =
{
    EmtBpPath .. 'flash_03_emit.bp',
    EmtBpPath .. 'saint_launch_01_emit.bp',
    EmtBpPath .. 'saint_launch_02_emit.bp',
}

ASonanceWeaponFXTrail01 = {
    EmtBpPath .. 'aeon_heavy_artillery_trail_02_emit.bp',
    EmtBpPath .. 'quark_bomb_01_emit.bp',
    EmtBpPath .. 'quark_bomb_02_emit.bp',
}
ASonanceWeaponFXTrail02 = {                                   -- A larger version of ASonanceWeaponFXTrail01
    EmtBpPath .. 'aeon_heavy_artillery_trail_01_emit.bp',
    EmtBpPath .. 'quark_bomb2_01_emit.bp',
    EmtBpPath .. 'quark_bomb2_02_emit.bp',
}
ASonanceWeaponHit02 = {
    EmtBpPath .. 'aeon_sonance_hit_01_emit.bp',
    EmtBpPath .. 'aeon_sonance_hit_02_emit.bp',
    EmtBpPath .. 'aeon_sonance_hit_03_emit.bp',
    EmtBpPath .. 'aeon_sonance_hit_04_emit.bp',
    EmtBpPath .. 'quark_bomb_explosion_08_emit.bp',
}

ASonicPulse01 = { EmtBpPath .. 'sonic_pulse_hit_flash_01_emit.bp',}
ASonicPulseHitUnit01 = table.concatenate(ASonicPulse01, UnitHitShrapnel01)
ASonicPulseHitAirUnit01 = ASonicPulseHitUnit01
ASonicPulseHitLand01 = table.concatenate(ASonicPulse01)

ASonicPulsarMunition01 = {
    '/effects/emitters/sonic_pulsar_01_emit.bp',
}

ATemporalFizzHit01 = {
    EmtBpPath .. 'temporal_fizz_02_emit.bp',
    EmtBpPath .. 'temporal_fizz_03_emit.bp',
    EmtBpPath .. 'temporal_fizz_hit_flash_01_emit.bp',
}

ATorpedoUnitHit01 = {
    EmtBpPath .. 'aeon_torpedocluster_hit_01_emit.bp',
    EmtBpPath .. 'aeon_torpedocluster_hit_02_emit.bp',
}

ATorpedoHit_Bubbles = {
    EmtBpPath .. 'aeon_torpedocluster_hit_03_emit.bp',
    EmtBpPath .. 'destruction_underwater_explosion_splash_01_emit.bp',
}

ATorpedoUnitHitUnderWater01 = table.concatenate(ATorpedoUnitHit01, ATorpedoHit_Bubbles)

ATorpedoPolyTrails01 =  EmtBpPath .. 'aeon_torpedocluster_polytrail_01_emit.bp'

-- ---------------------------------------------------------------
-- -- -- -- CYBRAN UNIT AMBIENT EFFECTS -- -- --

CCivilianBuildingInfectionAmbient = {
    EmtBpPath .. 'cybran_building01_infect_ambient_01_emit.bp',
    EmtBpPath .. 'cybran_building01_infect_ambient_02_emit.bp',
    EmtBpPath .. 'cybran_building01_infect_ambient_03_emit.bp',
}

CBrackmanQAIHackCircuitryEffect01Polytrails01= {
    EmtBpPath .. 'cybran_brackman_hacking_qai_polytrail_01_emit.bp',
}

CBrackmanQAIHackCircuitryEffect02Polytrails01= {
    EmtBpPath .. 'cybran_brackman_hacking_qai_polytrail_02_emit.bp',
}

CBrackmanQAIHackCircuitryEffect02Fxtrails01= {
    EmtBpPath .. 'cybran_brackman_hacking_qai_fxtrail_01_emit.bp',
}

CBrackmanQAIHackCircuitryEffect02Fxtrails02= {
    EmtBpPath .. 'cybran_brackman_hacking_qai_fxtrail_02_emit.bp',
}

CBrackmanQAIHackCircuitryEffect02Fxtrails03= {
    EmtBpPath .. 'cybran_brackman_hacking_qai_fxtrail_03_emit.bp',
}

CBrackmanQAIHackCircuitryEffectFxtrailsALL=
{
    CBrackmanQAIHackCircuitryEffect02Fxtrails01,
    CBrackmanQAIHackCircuitryEffect02Fxtrails02,
    CBrackmanQAIHackCircuitryEffect02Fxtrails03,
}


CQaiShutdown = {
    EmtBpPath .. 'cybran_qai_shutdown_ambient_01_emit.bp',
    EmtBpPath .. 'cybran_qai_shutdown_ambient_02_emit.bp',
    EmtBpPath .. 'cybran_qai_shutdown_ambient_03_emit.bp',
    EmtBpPath .. 'cybran_qai_shutdown_ambient_04_emit.bp',
}

CT2PowerAmbient = {
    EmtBpPath .. 'cybran_t2power_ambient_01_emit.bp',
    EmtBpPath .. 'cybran_t2power_ambient_01b_emit.bp',
    EmtBpPath .. 'cybran_t2power_ambient_02_emit.bp',
    EmtBpPath .. 'cybran_t2power_ambient_02b_emit.bp',
    EmtBpPath .. 'cybran_t2power_ambient_03_emit.bp',
    EmtBpPath .. 'cybran_t2power_ambient_03b_emit.bp',
}

CT3PowerAmbient = {
    EmtBpPath .. 'cybran_t3power_ambient_01_emit.bp',
    EmtBpPath .. 'cybran_t3power_ambient_01b_emit.bp',
    EmtBpPath .. 'cybran_t3power_ambient_02_emit.bp',
    EmtBpPath .. 'cybran_t3power_ambient_02b_emit.bp',
    EmtBpPath .. 'cybran_t3power_ambient_03_emit.bp',
    EmtBpPath .. 'cybran_t3power_ambient_03b_emit.bp',
}

CSoothSayerAmbient = {
    EmtBpPath .. 'cybran_soothsayer_ambient_01_emit.bp',
    EmtBpPath .. 'cybran_soothsayer_ambient_02_emit.bp',
}

-- ---------------------------------------------------------------
-- -- -- -- CYBRAN PROJECTILES -- -- --

CBrackmanCrabPegPodSplit01 = {
    EmtBpPath .. 'cybran_brackman_crab_pegpod_split_01_emit.bp',
}

CBrackmanCrabPegPodTrails= {
    EmtBpPath .. 'cybran_brackman_crab_pegpod_polytrail_01_emit.bp',
}


CBrackmanCrabPeg01 = {
    EmtBpPath .. 'cybran_nano_dart_hit_01_emit.bp',
    EmtBpPath .. 'cybran_nano_dart_hit_02_emit.bp',
    EmtBpPath .. 'cybran_nano_dart_hit_03_emit.bp',
    EmtBpPath .. 'cybran_nano_dart_glow_hit_land_01_emit.bp',
}

CBrackmanCrabPegHit01= {
    EmtBpPath .. 'cybran_brackman_crab_peg_hit_01_emit.bp',
    EmtBpPath .. 'cybran_brackman_crab_peg_hit_02_emit.bp',
}

CBrackmanCrabPegAmbient01= {
    EmtBpPath .. 'cybran_brackman_crab_peg_hit_03_emit.bp',
    EmtBpPath .. 'cybran_brackman_crab_peg_hit_03_flat_emit.bp',
    EmtBpPath .. 'cybran_brackman_crab_peg_hit_04_emit.bp',
}

CBrackmanCrabPegTrails= {
    EmtBpPath .. 'cybran_brackman_crab_peg_polytrail_01_emit.bp',
}



CIridiumRocketProjectile = {
    EmtBpPath .. 'cybran_nano_dart_hit_01_emit.bp',
    EmtBpPath .. 'cybran_nano_dart_hit_02_emit.bp',
}

CNanoDartHit01 = {
    EmtBpPath .. 'cybran_nano_dart_hit_01_emit.bp',
    EmtBpPath .. 'cybran_nano_dart_hit_02_emit.bp',
}
CNanoDartLandHit01 = {
    EmtBpPath .. 'cybran_nano_dart_hit_01_emit.bp',
    EmtBpPath .. 'cybran_nano_dart_hit_02_emit.bp',
    EmtBpPath .. 'cybran_nano_dart_hit_03_emit.bp',
    EmtBpPath .. 'cybran_nano_dart_glow_hit_land_01_emit.bp',
}
CNanoDartUnitHit01 = {
    EmtBpPath .. 'cybran_nano_dart_hit_01_emit.bp',
    EmtBpPath .. 'cybran_nano_dart_hit_02_emit.bp',
    EmtBpPath .. 'cybran_nano_dart_hit_03_emit.bp',
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
    EmtBpPath .. 'cybran_nano_dart_glow_hit_unit_01_emit.bp',
}

CNanoDartLandHit02 = {
    EmtBpPath .. 'cybran_nano_dart_hit_03_emit.bp',
    EmtBpPath .. 'cybran_nano_dart_hit_04_emit.bp',
    EmtBpPath .. 'cybran_nano_dart_glow_hit_land_02_emit.bp',
}
CNanoDartUnitHit02 = {
    EmtBpPath .. 'cybran_nano_dart_hit_03_emit.bp',
    EmtBpPath .. 'cybran_nano_dart_hit_04_emit.bp',
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
    EmtBpPath .. 'cybran_nano_dart_glow_hit_unit_02_emit.bp',
}

CNanoDartPolyTrail01= EmtBpPath .. 'cybran_nano_dart_polytrail_01_emit.bp'
CNanoDartPolyTrail02= EmtBpPath .. 'cybran_nano_dart_polytrail_02_emit.bp'

CCorsairMissileHit01 = {
    EmtBpPath .. 'cybran_corsair_missile_hit_01_emit.bp',
}
CCorsairMissileLandHit01 = {
    EmtBpPath .. 'cybran_corsair_missile_hit_01_emit.bp',
    EmtBpPath .. 'cybran_corsair_missile_hit_02_emit.bp',
    EmtBpPath .. 'cybran_corsair_missile_hit_03_emit.bp',
    EmtBpPath .. 'cybran_corsair_missile_glow_hit_land_01_emit.bp',
    EmtBpPath .. 'cybran_corsair_missile_glow_hit_land_02_emit.bp',
    EmtBpPath .. 'cybran_corsair_missile_hit_ring.bp',
}
CCorsairMissileUnitHit01 = {
    EmtBpPath .. 'cybran_corsair_missile_hit_01_emit.bp',
    EmtBpPath .. 'cybran_corsair_missile_hit_02_emit.bp',
    EmtBpPath .. 'cybran_corsair_missile_hit_03_emit.bp',
    EmtBpPath .. 'cybran_corsair_missile_glow_hit_unit_01_emit.bp',
    EmtBpPath .. 'cybran_corsair_missile_hit_ring.bp',
    EmtBpPath .. 'unit_shrapnel_hit_01_emit.bp',
}
CCorsairMissileFxTrails01 = { }
CCorsairMissilePolyTrail01 = EmtBpPath .. 'cybran_corsair_missile_polytrail_01_emit.bp'










CAntiNukeLaunch01 = {
    EmtBpPath .. 'cybran_antinuke_launch_02_emit.bp',
    EmtBpPath .. 'cybran_antinuke_launch_03_emit.bp',
    EmtBpPath .. 'cybran_antinuke_launch_04_emit.bp',
    EmtBpPath .. 'cybran_antinuke_launch_05_emit.bp',
}

CAntiTorpedoHit01 = {
    EmtBpPath .. 'anti_torpedo_flare_hit_01_emit.bp',
    EmtBpPath .. 'anti_torpedo_flare_hit_02_emit.bp',
    EmtBpPath .. 'anti_torpedo_flare_hit_03_emit.bp',
}

CArtilleryFlash01 = {
    EmtBpPath .. 'proton_artillery_muzzle_01_emit.bp',
    EmtBpPath .. 'proton_artillery_muzzle_02_emit.bp',
    EmtBpPath .. 'proton_artillery_muzzle_03_emit.bp',
    EmtBpPath .. 'proton_artillery_muzzle_04_emit.bp',
    EmtBpPath .. 'proton_artillery_muzzle_05_emit.bp',
    EmtBpPath .. 'proton_artillery_muzzle_06_emit.bp',
    EmtBpPath .. 'proton_artillery_muzzle_08_emit.bp',
}
CArtilleryFlash02 = {
    EmtBpPath .. 'proton_artillery_muzzle_07_emit.bp',
}

CArtilleryHit01 = DefaultHitExplosion01

CBeamHit01 = {
    EmtBpPath .. 'beam_hit_sparks_01_emit.bp',
    EmtBpPath .. 'beam_hit_smoke_01_emit.bp',
}
CBeamHitUnit01 = CBeamHit01
CBeamHitLand01 = CBeamHit01

CBombHit01 = {
    EmtBpPath .. 'bomb_hit_flash_01_emit.bp',
    EmtBpPath .. 'bomb_hit_fire_01_emit.bp',
    EmtBpPath .. 'bomb_hit_fire_shadow_01_emit.bp',
}

CCommanderOverchargeFxTrail01 = {
    EmtBpPath .. 'cybran_commander_overcharge_fxtrail_01_emit.bp',
    EmtBpPath .. 'cybran_commander_overcharge_fxtrail_02_emit.bp',
}
CCommanderOverchargeHit01 = {
    EmtBpPath .. 'cybran_commander_overcharge_hit_01_emit.bp',
    EmtBpPath .. 'cybran_commander_overcharge_hit_02_emit.bp',
    -- EmtBpPath .. 'cybran_commander_overcharge_hit_03_emit.bp',
}

CDisintegratorHit01 = {
    EmtBpPath .. 'disintegrator_hit_flash_01_emit.bp',
    EmtBpPath .. 'disintegrator_hit_flash_02_emit.bp',
    EmtBpPath .. 'disintegrator_hit_flash_03_emit.bp',
    EmtBpPath .. 'disintegrator_hit_flash_04_emit.bp',
    EmtBpPath .. 'disintegrator_hit_flash_05_emit.bp',
    EmtBpPath .. 'disintegrator_hit_flash_06_emit.bp',
    EmtBpPath .. 'disintegrator_hit_flash_07_emit.bp',
}
CDisintegratorHit02 = {
    EmtBpPath .. 'disintegrator_hit_sparks_01_emit.bp',
    EmtBpPath .. 'disintegrator_hit_flashunit_05_emit.bp',
    EmtBpPath .. 'disintegrator_hit_flashunit_07_emit.bp',
}
CDisintegratorHit03 = { EmtBpPath .. 'disintegrator_hit_flash_02_emit.bp',}
CDisintegratorHitUnit01 = table.concatenate(CDisintegratorHit01, CDisintegratorHit02)
CDisintegratorHitAirUnit01 = table.concatenate(CDisintegratorHit03, CDisintegratorHit02)
CDisintegratorFxTrails01 = {
    EmtBpPath .. 'disintegrator_fxtrail_01_emit.bp'
}
CDisintegratorHitLand01 = CDisintegratorHit01

CHvyDisintegratorHit01 = {
    EmtBpPath .. 'disintegratorhvy_hit_flash_01_emit.bp',
    EmtBpPath .. 'disintegratorhvy_hit_flash_flat_02_emit.bp',
    EmtBpPath .. 'disintegratorhvy_hit_flash_flat_03_emit.bp',
    EmtBpPath .. 'disintegratorhvy_hit_flash_04_emit.bp',
    EmtBpPath .. 'disintegratorhvy_hit_flash_05_emit.bp',
    EmtBpPath .. 'disintegratorhvy_hit_flash_flat_06_emit.bp',
    EmtBpPath .. 'disintegratorhvy_hit_flash_07_emit.bp',
    EmtBpPath .. 'disintegratorhvy_hit_sparks_01_emit.bp',
    EmtBpPath .. 'disintegratorhvy_hit_flash_flat_08_emit.bp',
    EmtBpPath .. 'disintegratorhvy_hit_flash_09_emit.bp',
    EmtBpPath .. 'disintegratorhvy_hit_flash_distort_emit.bp',
}
CHvyDisintegratorHit02 = {
    EmtBpPath .. 'disintegratorhvy_hit_flash_02_emit.bp',
    EmtBpPath .. 'disintegratorhvy_hit_flash_03_emit.bp',
    EmtBpPath .. 'disintegratorhvy_hit_flash_06_emit.bp',
    EmtBpPath .. 'disintegratorhvy_hit_flash_08_emit.bp',
}
CHvyDisintegratorHitUnit01 = table.concatenate(CHvyDisintegratorHit01, CHvyDisintegratorHit02)
CHvyDisintegratorHitLand01 = CHvyDisintegratorHit01


CDisruptorGroundEffect = {
    EmtBpPath .. 'cybran_lra_ground_effect_01_emit.bp'
}
CDisruptorVentEffect = {
    EmtBpPath .. 'cybran_lra_vent_effect_01_emit.bp'
}
CDisruptorMuzzleEffect = {
    EmtBpPath .. 'cybran_lra_muzzle_effect_01_emit.bp',
    EmtBpPath .. 'cybran_lra_muzzle_effect_02_emit.bp',
}
CDisruptorCoolDownEffect = {
    EmtBpPath .. 'cybran_lra_cooldown_effect_01_emit.bp',
    EmtBpPath .. 'cybran_lra_barrel_effect_01_emit.bp',
}

CElectronBolterMuzzleFlash01 = {
    EmtBpPath .. 'electron_bolter_flash_01_emit.bp',
    EmtBpPath .. 'electron_bolter_flash_02_emit.bp',
    EmtBpPath .. 'electron_bolter_flash_04_emit.bp',
    EmtBpPath .. 'electron_bolter_flash_05_emit.bp',
    EmtBpPath .. 'laserturret_muzzle_flash_01_emit.bp',
}
CElectronBolterMuzzleFlash02 = {
    EmtBpPath .. 'electron_bolter_flash_03_emit.bp',
    EmtBpPath .. 'electron_bolter_sparks_01_emit.bp',
}
CElectronBolterHit01 = {
    EmtBpPath .. 'electron_bolter_hit_02_emit.bp',
    EmtBpPath .. 'electron_bolter_hit_03_emit.bp',
    EmtBpPath .. 'electron_bolter_hit_04_emit.bp',
    EmtBpPath .. 'electron_bolter_hit_flash_01_emit.bp',
    EmtBpPath .. 'electron_bolter_hit_flash_03_emit.bp',
}
CElectronBolterHit02 = {
    EmtBpPath .. 'electron_bolter_hit_01_emit.bp',
    EmtBpPath .. 'electron_bolter_hitunit_04_emit.bp',
}
CElectronBolterHit03 = {
    EmtBpPath .. 'electron_bolter_hit_flash_02_emit.bp',
    EmtBpPath .. 'electron_bolter_hit_05_emit.bp',
}
CElectronBolterHitUnit01 = table.concatenate(CElectronBolterHit01, CElectronBolterHit02, UnitHitShrapnel01)
CElectronBolterHitLand01 = CElectronBolterHit01
CElectronBolterHitUnit02 = table.concatenate(CElectronBolterHit01, CElectronBolterHit02, CElectronBolterHit03, UnitHitShrapnel01)
CElectronBolterHitLand02 = table.concatenate(CElectronBolterHit01, CElectronBolterHit03)
CElectronBolterHit03 = {
    EmtBpPath .. 'electron_bolter_hit_02_emit.bp',
    EmtBpPath .. 'electron_bolter_hit_flash_01_emit.bp',
}
CElectronBolterHit04 = {
    EmtBpPath .. 'electron_bolter_hit_02_emit.bp',
    EmtBpPath .. 'electron_bolter_hit_flash_02_emit.bp',
}


CElectronBurstCloud01 = {
    EmtBpPath .. 'electron_burst_cloud_gas_01_emit.bp',
    EmtBpPath .. 'electron_burst_cloud_sparks_01_emit.bp',
    EmtBpPath .. 'electron_burst_cloud_flash_01_emit.bp',
}

CEMPGrenadeHit01 = {
    EmtBpPath .. 'cybran_empgrenade_hit_01_emit.bp',
    EmtBpPath .. 'cybran_empgrenade_hit_02_emit.bp',
    EmtBpPath .. 'cybran_empgrenade_hit_03_emit.bp',
}

CIFCruiseMissileLaunchSmoke = {
    EmtBpPath .. 'cybran_cruise_missile_launch_01_emit.bp',
    EmtBpPath .. 'cybran_cruise_missile_launch_02_emit.bp',
}

CLaserHit01 = {
    EmtBpPath .. 'cybran_laser_hit_flash_01_emit.bp',
    EmtBpPath .. 'cybran_laser_hit_flash_02_emit.bp',
}
CLaserHit02 = {
    EmtBpPath .. 'cybran_laser_hit_flash_01_emit.bp',
    EmtBpPath .. 'cybran_laser_hit_sparks_01_emit.bp',
}
CLaserHitLand01 = CLaserHit01
CLaserHitUnit01 = table.concatenate(CLaserHit02, UnitHitShrapnel01)
CLaserMuzzleFlash01 = {
    EmtBpPath .. 'laser_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'default_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'default_muzzle_flash_02_emit.bp',
}

CLaserMuzzleFlash02 = {
    EmtBpPath .. 'cybran_laser_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'cybran_laser_muzzle_flash_02_emit.bp',
}

CLaserMuzzleFlash03 = {
    EmtBpPath .. 'cybran_laser_muzzle_flash_03_emit.bp',
    EmtBpPath .. 'cybran_laser_muzzle_flash_04_emit.bp',
}

CMicrowaveLaserMuzzle01 = {
    EmtBpPath .. 'microwave_laser_flash_01_emit.bp',
    EmtBpPath .. 'microwave_laser_muzzle_01_emit.bp',
}

CMicrowaveLaserCharge01 = {
    EmtBpPath .. 'microwave_laser_charge_01_emit.bp',
    EmtBpPath .. 'microwave_laser_charge_02_emit.bp',
}
CMicrowaveLaserEndPoint01 = {
    EmtBpPath .. 'microwave_laser_end_01_emit.bp',
    EmtBpPath .. 'microwave_laser_end_02_emit.bp',
    EmtBpPath .. 'microwave_laser_end_03_emit.bp',
    EmtBpPath .. 'microwave_laser_end_04_emit.bp',
    EmtBpPath .. 'microwave_laser_end_05_emit.bp',
    EmtBpPath .. 'microwave_laser_end_06_emit.bp',
}

CMissileHit01 = DefaultMissileHit01

CMissileHit02a = {
    EmtBpPath .. 'cybran_iridium_hit_unit_01_emit.bp',
    EmtBpPath .. 'cybran_iridium_hit_land_01_emit.bp',
    EmtBpPath .. 'cybran_iridium_hit_land_02_emit.bp',
    EmtBpPath .. 'cybran_iridium_hit_ring_01_emit.bp',
}
CMissileHit02b = {
    EmtBpPath .. 'cybran_corsair_missile_glow_hit_unit_01_emit.bp',
}

CMissileHit02 = table.concatenate(FireCloudSml01, FlashSml01, FlareSml01, CMissileHit02a)
CMissileLOAHit01 = {
    EmtBpPath .. 'cybran_missile_hit_01_emit.bp',
    EmtBpPath .. 'cybran_missile_hit_02_emit.bp',
}

-- CMolecularResonanceHitUnit01 = {
--    EmtBpPath .. 'molecular_resonance_cannon_01_emit.bp',
--    EmtBpPath .. 'molecular_resonance_cannon_02_emit.bp',
--    EmtBpPath .. 'molecular_resonance_cannon_03_emit.bp',
--    EmtBpPath .. 'molecular_resonance_cannon_04_emit.bp',
--    EmtBpPath .. 'molecular_resonance_cannon_ring_03_emit.bp',
--    EmtBpPath .. 'molecular_resonance_cannon_ring_04_emit.bp',
-- }
CMolecularResonanceHitUnit01 = {
    EmtBpPath .. 'cybran_light_artillery_hit_01_emit.bp',
    EmtBpPath .. 'cybran_light_artillery_hit_02_emit.bp',
}

CMolecularResonanceHitLand01 = {
    EmtBpPath .. 'dust_cloud_06_emit.bp',
    EmtBpPath .. 'dirtchunks_01_emit.bp',
    EmtBpPath .. 'molecular_resonance_cannon_ring_02_emit.bp',
}

-- ------------------------------------------------------------------------
--  CYBRAN MOLECULAR RIPPER CANNON EMITTERS
-- ------------------------------------------------------------------------
CMolecularRipperFlash01 = {
    EmtBpPath .. 'molecular_ripper_flash_01_emit.bp',
    EmtBpPath .. 'molecular_ripper_flash_02_emit.bp',
    EmtBpPath .. 'molecular_ripper_charge_01_emit.bp',
    EmtBpPath .. 'molecular_ripper_charge_02_emit.bp',
    EmtBpPath .. 'molecular_cannon_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'molecular_cannon_muzzle_flash_02_emit.bp',
}
CMolecularRipperOverChargeFlash01 = {
    EmtBpPath .. 'molecular_ripper_flash_01_emit.bp',
    EmtBpPath .. 'molecular_ripper_oc_charge_01_emit.bp',
    EmtBpPath .. 'molecular_ripper_oc_charge_02_emit.bp',
    EmtBpPath .. 'molecular_ripper_oc_charge_03_emit.bp',
    EmtBpPath .. 'molecular_cannon_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'default_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'default_muzzle_flash_02_emit.bp'
}
CMolecularCannon01 = {
    EmtBpPath .. 'molecular_ripper_01_emit.bp',
    EmtBpPath .. 'molecular_ripper_02_emit.bp',
    EmtBpPath .. 'molecular_ripper_03_emit.bp',
}
CMolecularRipperHit01 = {
    EmtBpPath .. 'molecular_ripper_hit_01_emit.bp',
    EmtBpPath .. 'molecular_ripper_hit_02_emit.bp',
    EmtBpPath .. 'molecular_ripper_hit_03_emit.bp',
    EmtBpPath .. 'molecular_ripper_hit_04_emit.bp',
    EmtBpPath .. 'molecular_ripper_hit_05_emit.bp',
    EmtBpPath .. 'molecular_ripper_hit_06_emit.bp',
    EmtBpPath .. 'molecular_ripper_hit_07_emit.bp',
}


CNeutronClusterBombHit01 = {
    EmtBpPath .. 'neutron_cluster_bomb_hit_01_emit.bp',
    EmtBpPath .. 'neutron_cluster_bomb_hit_02_emit.bp',
}
CNeutronClusterBombHitUnit01 = CNeutronClusterBombHit01
CNeutronClusterBombHitLand01 = CNeutronClusterBombHit01
CNeutronClusterBombHitWater01 = CNeutronClusterBombHit01

CParticleCannonHit01 = { EmtBpPath .. 'laserturret_hit_flash_01_emit.bp',}
CParticleCannonHitUnit01 = table.concatenate(CParticleCannonHit01, UnitHitShrapnel01)
CParticleCannonHitLand01 = table.concatenate(CParticleCannonHit01)

CProtonBombHit01 = {
    EmtBpPath .. 'proton_bomb_hit_01_emit.bp',
    EmtBpPath .. 'proton_bomb_hit_02_emit.bp',
}

CHvyProtonCannonMuzzleflash = {
    EmtBpPath .. 'hvyproton_cannon_muzzle_01_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_muzzle_02_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_muzzle_03_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_muzzle_04_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_muzzle_05_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_muzzle_06_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_muzzle_07_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_muzzle_08_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_hit_10_emit.bp',
}
CHvyProtonCannonHit01 = {
    EmtBpPath .. 'hvyproton_cannon_hit_01_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_hit_02_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_hit_03_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_hit_04_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_hit_05_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_hit_07_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_hit_09_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_hit_10_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_hit_distort_emit.bp',
}
CHvyProtonCannonHit02 = {
    EmtBpPath .. 'hvyproton_cannon_hit_06_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_hit_08_emit.bp',
}
CHvyProtonCannonHitLand = table.concatenate(CHvyProtonCannonHit01, CHvyProtonCannonHit02)
CHvyProtonCannonHitUnit01 = {
    EmtBpPath .. 'hvyproton_cannon_hitunit_01_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_hit_02_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_hit_03_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_hitunit_04_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_hitunit_05_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_hitunit_06_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_hitunit_07_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_hit_08_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_hit_09_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_hit_10_emit.bp',
    EmtBpPath .. 'hvyproton_cannon_hit_distort_emit.bp',
}
CHvyProtonCannonHitUnit = table.concatenate(CHvyProtonCannonHitUnit01, UnitHitShrapnel01)
CHvyProtonCannonPolyTrail =  EmtBpPath .. 'hvyproton_cannon_polytrail_01_emit.bp'
CHvyProtonCannonFXTrail01 =  { EmtBpPath .. 'hvyproton_cannon_fxtrail_01_emit.bp' }

CProtonCannonHit01 = {
     EmtBpPath .. 'proton_cannon_hit_01_emit.bp',
}

CProtonCannonHitWater01 = {
    EmtBpPath .. 'proton_cannon_hit_01_emit.bp',
}

CProtonCannonPolyTrail =  EmtBpPath .. 'proton_cannon_polytrail_01_emit.bp'
CProtonCannonPolyTrail02 =  EmtBpPath .. 'proton_cannon_polytrail_02_emit.bp'
CProtonCannonFXTrail01 =  { EmtBpPath .. 'proton_cannon_fxtrail_01_emit.bp' }
CProtonCannonFXTrail02 =  { EmtBpPath .. 'proton_cannon_fxtrail_02_emit.bp' }
CProtonArtilleryPolytrail01 = EmtBpPath .. 'proton_artillery_polytrail_01_emit.bp'
CProtonArtilleryHit01 = {
    EmtBpPath .. 'proton_bomb_hit_02_emit.bp',
    EmtBpPath .. 'proton_artillery_hit_01_emit.bp',
    EmtBpPath .. 'proton_artillery_hit_02_emit.bp',
    EmtBpPath .. 'proton_artillery_hit_03_emit.bp',
    EmtBpPath .. 'shockwave_01_emit.bp',
}

CTorpedoUnitHit01 = table.concatenate(DefaultProjectileWaterImpact, DefaultProjectileUnderWaterImpact)

CZealotLaunch01 = {
    EmtBpPath .. 'muzzle_flash_01_emit.bp',
    EmtBpPath .. 'zealot_launch_01_emit.bp',
    EmtBpPath .. 'zealot_launch_02_emit.bp',
}

CKrilTorpedoLauncherMuzzleFlash01 = {
    EmtBpPath .. 'muzzle_flash_02_emit.bp',
    EmtBpPath .. 'muzzle_smoke_01_emit.bp',
}

CMobileKamikazeBombExplosion = {
    EmtBpPath .. 'cybran_kamibomb_hit_01_emit.bp',
    EmtBpPath .. 'cybran_kamibomb_hit_02_emit.bp',
    EmtBpPath .. 'cybran_kamibomb_hit_03_emit.bp',
    EmtBpPath .. 'cybran_kamibomb_hit_04_emit.bp',
    EmtBpPath .. 'cybran_kamibomb_hit_05_emit.bp',
    EmtBpPath .. 'cybran_kamibomb_hit_06_emit.bp',
    EmtBpPath .. 'cybran_kamibomb_hit_07_emit.bp',
    EmtBpPath .. 'cybran_kamibomb_hit_08_emit.bp',
    EmtBpPath .. 'cybran_kamibomb_hit_09_emit.bp',
    EmtBpPath .. 'cybran_kamibomb_hit_10_emit.bp',
    EmtBpPath .. 'cybran_kamibomb_hit_11_emit.bp',
}

CMobileKamikazeBombDeathExplosion = {
    EmtBpPath .. 'cybran_kamibomb_hit_02_emit.bp',  -- -- -- Chaf that is thrown about.
    EmtBpPath .. 'cybran_kamibomb_hit_04_emit.bp',  -- -- -- Largest main explosion cloud.
    EmtBpPath .. 'cybran_kamibomb_hit_05_emit.bp',  -- -- -- Darkening.
    EmtBpPath .. 'cybran_kamibomb_hit_08_emit.bp',  -- -- -- Small main core explosion.
    EmtBpPath .. 'cybran_kamibomb_hit_11_emit.bp',  -- -- -- Smoke after the explosion.
    EmtBpPath .. 'cybran_kamibomb_hit_12_emit.bp',  -- -- -- Yellow explosion flash.
    EmtBpPath .. 'cybran_kamibomb_hit_13_emit.bp',  -- -- -- Yellow explosion flash.
}

CMobileBeetleExplosion = {
    EmtBpPath .. 'proton_bomb_hit_02_emit.bp',
    EmtBpPath .. 'proton_artillery_hit_01_emit.bp',
    EmtBpPath .. 'proton_artillery_hit_02_emit.bp',
    EmtBpPath .. 'quark_bomb_explosion_06_emit.bp',
    EmtBpPath .. 'antimatter_ring_03_emit.bp',
    EmtBpPath .. 'antimatter_ring_04_emit.bp',
}

-- ---------------------------------------------------------------
-- -- -- -- UEF PROJECTILES (previously Terran) -- -- --
-- ---------------------------------------------------------------


-- ------------------------------------------------------------------------
--  TERRAN ANTI-MATTER SHELL EMITTERS
-- ------------------------------------------------------------------------
TAntiMatterShellHit01 = {
    EmtBpPath .. 'antimatter_hit_01_emit.bp', -- -- 	glow
    EmtBpPath .. 'antimatter_hit_02_emit.bp', -- -- 	flash
    EmtBpPath .. 'antimatter_hit_03_emit.bp', 	-- -- 	sparks
    EmtBpPath .. 'antimatter_hit_04_emit.bp', -- -- 	plume fire
    EmtBpPath .. 'antimatter_hit_05_emit.bp', -- -- 	plume dark
    EmtBpPath .. 'antimatter_hit_06_emit.bp', -- -- 	base fire
    EmtBpPath .. 'antimatter_hit_07_emit.bp', -- -- 	base dark
    EmtBpPath .. 'antimatter_hit_08_emit.bp', -- -- 	plume smoke
    EmtBpPath .. 'antimatter_hit_09_emit.bp', -- -- 	base smoke
    EmtBpPath .. 'antimatter_hit_10_emit.bp', -- -- 	plume highlights
    EmtBpPath .. 'antimatter_hit_11_emit.bp', -- -- 	base highlights
    EmtBpPath .. 'antimatter_ring_01_emit.bp', -- -- 	ring14
    EmtBpPath .. 'antimatter_ring_02_emit.bp', -- -- 	ring11
}

TAntiMatterShellHit02 = {
    EmtBpPath .. 'antimatter_hit_12_emit.bp',
    EmtBpPath .. 'antimatter_hit_13_emit.bp',
    EmtBpPath .. 'antimatter_hit_14_emit.bp',
    EmtBpPath .. 'antimatter_hit_15_emit.bp',
    EmtBpPath .. 'antimatter_hit_16_emit.bp',
    EmtBpPath .. 'antimatter_ring_03_emit.bp',
    EmtBpPath .. 'antimatter_ring_04_emit.bp',
    EmtBpPath .. 'quark_bomb_explosion_06_emit.bp',
}

-- ------------------------------------------------------------------------
--  TERRAN APDS EMITTERS
-- ------------------------------------------------------------------------
TAPDSHit01 = {
    EmtBpPath .. 'uef_t2_artillery_hit_01_emit.bp',
    EmtBpPath .. 'uef_t2_artillery_hit_02_emit.bp',
    EmtBpPath .. 'uef_t2_artillery_hit_03_emit.bp',
    EmtBpPath .. 'uef_t2_artillery_hit_04_emit.bp',
    EmtBpPath .. 'uef_t2_artillery_hit_05_emit.bp',
    EmtBpPath .. 'uef_t2_artillery_hit_06_emit.bp',
    EmtBpPath .. 'uef_t2_artillery_hit_07_emit.bp',
}

TAPDSHitUnit01 = table.concatenate(TAPDSHit01, UnitHitShrapnel01)


-- ------------------------------------------------------------------------
--  TERRAN ARTILLERY EMITTERS
-- ------------------------------------------------------------------------
TIFArtilleryMuzzleFlash = {
    EmtBpPath .. 'cannon_artillery_muzzle_flash_01_emit.bp',
    -- EmtBpPath .. 'cannon_muzzle_smoke_06_emit.bp',
    EmtBpPath .. 'cannon_muzzle_smoke_07_emit.bp',
    EmtBpPath .. 'cannon_muzzle_smoke_10_emit.bp',
    EmtBpPath .. 'cannon_muzzle_flash_03_emit.bp',
}


-- ------------------------------------------------------------------------
--  TERRAN COMMANDER OVERCHARGE WEAPON EMITTERS
-- ------------------------------------------------------------------------
TCommanderOverchargeFlash01 = {
    EmtBpPath .. 'terran_commander_overcharge_flash_01_emit.bp',
}
TCommanderOverchargeFXTrail01 = {
    EmtBpPath .. 'terran_commander_overcharge_trail_01_emit.bp',
    EmtBpPath .. 'terran_commander_overcharge_trail_02_emit.bp',
}
TCommanderOverchargeHit01 = {
    EmtBpPath .. 'quantum_hit_flash_07_emit.bp',
    EmtBpPath .. 'terran_commander_overcharge_hit_01_emit.bp',
    EmtBpPath .. 'terran_commander_overcharge_hit_02_emit.bp',
    EmtBpPath .. 'terran_commander_overcharge_hit_03_emit.bp',
    EmtBpPath .. 'terran_commander_overcharge_hit_04_emit.bp',
}


-- ------------------------------------------------------------------------
--  TERRAN FLAK CANNON EMITTERS
-- ------------------------------------------------------------------------
TFlakCannonMuzzleFlash01 = {
    EmtBpPath .. 'cannon_muzzle_flash_05_emit.bp',
    EmtBpPath .. 'cannon_muzzle_fire_02_emit.bp',
    EmtBpPath .. 'muzzle_sparks_01_emit.bp',
    EmtBpPath .. 'cannon_muzzle_smoke_09_emit.bp',
}
TFragmentationShell01 = {
    EmtBpPath .. 'fragmentation_shell_phosphor_01_emit.bp',
    EmtBpPath .. 'fragmentation_shell_hit_flash_01_emit.bp',
    EmtBpPath .. 'fragmentation_shell_shrapnel_01_emit.bp',
    EmtBpPath .. 'fragmentation_shell_smoke_01_emit.bp',
    EmtBpPath .. 'fragmentation_shell_smoke_02_emit.bp',
}


-- ------------------------------------------------------------------------
--  TERRAN FRAGMENTATION SENSOR SHELL EMITTERS
-- ------------------------------------------------------------------------
TFragmentationSensorShellFrag = {
    EmtBpPath .. 'terran_fragmentation_bomb_split_01_emit.bp',
    EmtBpPath .. 'terran_fragmentation_bomb_split_02_emit.bp',
}
TFragmentationSensorShellHit = {
    -- EmtBpPath .. 'plasma_cannon_hit_01_emit.bp',
    EmtBpPath .. 'terran_fragmentation_bomb_hit_01_emit.bp',
    EmtBpPath .. 'terran_fragmentation_bomb_hit_02_emit.bp',
    EmtBpPath .. 'terran_fragmentation_bomb_hit_03_emit.bp',
    EmtBpPath .. 'terran_fragmentation_bomb_hit_04_emit.bp',
    EmtBpPath .. 'terran_fragmentation_bomb_hit_05_emit.bp',
}
TFragmentationSensorShellTrail = {
    EmtBpPath .. 'mortar_munition_02_emit.bp',
    EmtBpPath .. 'mortar_munition_02_flare_emit.bp',
}


-- ------------------------------------------------------------------------
--  TERRAN GAUSS CANNON EMITTERS
-- ------------------------------------------------------------------------
TGaussCannonFlash = {
    EmtBpPath .. 'gauss_cannon_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'gauss_cannon_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'gauss_cannon_muzzle_smoke_02_emit.bp',
    EmtBpPath .. 'cannon_muzzle_smoke_09_emit.bp',
}
TGaussCannonHit01 = {
    EmtBpPath .. 'gauss_cannon_hit_01_emit.bp',
    EmtBpPath .. 'gauss_cannon_hit_02_emit.bp',
    EmtBpPath .. 'gauss_cannon_hit_03_emit.bp',
    EmtBpPath .. 'gauss_cannon_hit_04_emit.bp',
    EmtBpPath .. 'gauss_cannon_hit_05_emit.bp',
}

TGaussWaterSplash01 = {
    EmtBpPath .. 'gauss_cannon_hit_02_emit.bp',
    EmtBpPath .. 'gauss_cannon_hit_05_emit.bp',
}

TGaussCannonHit02 = {
    EmtBpPath .. 'gauss_cannon_hit_01_emit.bp',
    EmtBpPath .. 'gauss_cannon_hit_02_emit.bp',
    EmtBpPath .. 'gauss_cannon_hit_03_emit.bp',
    EmtBpPath .. 'gauss_cannon_hit_04_emit.bp',
    EmtBpPath .. 'gauss_cannon_hit_05_emit.bp',
}
TGaussCannonHitUnit01 = table.concatenate(TGaussCannonHit01, UnitHitShrapnel01)
TGaussCannonHitLand01 = TGaussCannonHit01
TGaussCannonHitUnit02 = table.concatenate(TGaussCannonHit02, UnitHitShrapnel01)
TGaussCannonHitLand02 = TGaussCannonHit02
TGaussCannonPolyTrail =  {
    EmtBpPath .. 'gauss_cannon_polytrail_01_emit.bp',
    EmtBpPath .. 'gauss_cannon_polytrail_02_emit.bp',
}

-- -- adjustments for UES0302
TShipGaussCannonFlash = {
    EmtBpPath .. 'cannon_muzzle_fire_01_emit.bp',
    EmtBpPath .. 'cannon_muzzle_smoke_03_emit.bp',
    EmtBpPath .. 'cannon_muzzle_smoke_04_emit.bp',
    -- EmtBpPath .. 'cannon_muzzle_smoke_05_emit.bp',
    EmtBpPath .. 'cannon_muzzle_water_shock_01_emit.bp',
    EmtBpPath .. 'cannon_muzzle_flash_06_emit.bp',
    EmtBpPath .. 'cannon_muzzle_flash_07_emit.bp',
}

TLandGaussCannonFlash = {
    EmtBpPath .. 'cannon_muzzle_fire_01_emit.bp',
    EmtBpPath .. 'cannon_muzzle_smoke_03_emit.bp',
    EmtBpPath .. 'cannon_muzzle_smoke_04_emit.bp',
    -- EmtBpPath .. 'cannon_muzzle_smoke_05_emit.bp',
    -- EmtBpPath .. 'cannon_muzzle_water_shock_01_emit.bp',
    EmtBpPath .. 'cannon_muzzle_flash_09_emit.bp',
    EmtBpPath .. 'cannon_muzzle_flash_08_emit.bp',
}

TShipGaussCannonHit01 = {
    EmtBpPath .. 'shipgauss_cannon_hit_01_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_02_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_03_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_04_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_05_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_06_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_07_emit.bp',
    -- EmtBpPath .. 'shipgauss_cannon_hit_08_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_09_emit.bp',
}

TMediumShipGaussCannonHit01 = {
    EmtBpPath .. 'shipgauss_cannon_hit_medium_01_emit.bp', -- white glow
    EmtBpPath .. 'shipgauss_cannon_hit_medium_02_emit.bp', -- particles
    EmtBpPath .. 'shipgauss_cannon_hit_medium_03_emit.bp', -- muzzle blaze
    EmtBpPath .. 'shipgauss_cannon_hit_medium_04_emit.bp', -- fire
    EmtBpPath .. 'shipgauss_cannon_hit_medium_05_emit.bp', -- black fire/smoke
    EmtBpPath .. 'shipgauss_cannon_hit_medium_06_emit.bp', -- orange glow
    EmtBpPath .. 'shipgauss_cannon_hit_medium_07_emit.bp', -- single big air distortion ring
    -- EmtBpPath .. 'shipgauss_cannon_hit_08_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_medium_09_emit.bp', -- many smaller air distortion rings
}

TShipGaussCannonHit02 = {
    EmtBpPath .. 'shipgauss_cannon_hit_01_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_02_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_03_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_10_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_11_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_06_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_07_emit.bp',
    -- EmtBpPath .. 'shipgauss_cannon_hit_08_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_09_emit.bp',
}

TMediumLandGaussCannonHit01 = {
    EmtBpPath .. 'landgauss_cannon_hit_medium_01_emit.bp', -- white glow
    EmtBpPath .. 'landgauss_cannon_hit_medium_02_emit.bp', -- particles
    EmtBpPath .. 'landgauss_cannon_hit_medium_03_emit.bp', -- muzzle blaze
    EmtBpPath .. 'landgauss_cannon_hit_medium_04_emit.bp', -- fire
    EmtBpPath .. 'landgauss_cannon_hit_medium_05_emit.bp', -- black fire/smoke
    EmtBpPath .. 'landgauss_cannon_hit_medium_06_emit.bp', -- orange glow
    --EmtBpPath .. 'shipgauss_cannon_hit_07_emit.bp', -- single big air distortion ring
    EmtBpPath .. 'landgauss_cannon_hit_medium_09_emit.bp', -- many smaller air distortion rings
}

TBigLandGaussCannonHit01 = {
    EmtBpPath .. 'landgauss_cannon_hit_01_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_02_emit.bp',
    EmtBpPath .. 'landgauss_cannon_hit_03_emit.bp',
    EmtBpPath .. 'landgauss_cannon_hit_04_emit.bp',
    EmtBpPath .. 'landgauss_cannon_hit_05_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_06_emit.bp',
    -- EmtBpPath .. 'shipgauss_cannon_hit_07_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_09_emit.bp',
}

TLandGaussCannonHit01 = { 
    EmtBpPath .. 'landgauss_cannon_hit_01_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_02_emit.bp',
    EmtBpPath .. 'landgauss_cannon_hit_03_emit.bp',
    EmtBpPath .. 'landgauss_cannon_hit_04_emit.bp',
    EmtBpPath .. 'landgauss_cannon_hit_05_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_06_emit.bp',
    -- EmtBpPath .. 'shipgauss_cannon_hit_07_emit.bp',
    EmtBpPath .. 'shipgauss_cannon_hit_09_emit.bp',
}

TShipGaussCannonHitUnit01 = table.concatenate(TShipGaussCannonHit01, UnitHitShrapnel01)
TShipGaussCannonHitUnit02 = table.concatenate(TShipGaussCannonHit02, UnitHitShrapnel01)
TLandGaussCannonHitUnit01 = table.concatenate(TLandGaussCannonHit01, UnitHitShrapnel01)
TBigLandGaussCannonHitUnit01 = table.concatenate(TBigLandGaussCannonHit01, UnitHitShrapnel01)
TMediumLandGaussCannonHitUnit01 = table.concatenate(TMediumLandGaussCannonHit01, UnitHitShrapnel01)
TMediumShipGaussCannonHitUnit01 = table.concatenate(TMediumShipGaussCannonHit01, UnitHitShrapnel01)

-- ------------------------------------------------------------------------
--  TERRAN GINSU BEAM EMITTERS
-- ------------------------------------------------------------------------
TAAGinsuHitLand = {
    EmtBpPath .. 'ginsu_laser_hit_land_01_emit.bp',
}

TAAGinsuHitUnit = {
    EmtBpPath .. 'ginsu_laser_hit_unit_01_emit.bp',
    EmtBpPath .. 'laserturret_hit_flash_03_emit.bp',
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
}


-- ------------------------------------------------------------------------
--  TERRAN HEAVY FRAGMENTATION GRENADE EMITTERS
-- ------------------------------------------------------------------------
THeavyFragmentationGrenadeMuzzleFlash = {
    EmtBpPath .. 'terran_fragmentation_grenade_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'terran_fragmentation_grenade_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'terran_fragmentation_grenade_muzzle_flash_03_emit.bp',
    EmtBpPath .. 'terran_fragmentation_grenade_muzzle_flash_04_emit.bp',
}
THeavyFragmentationGrenadeHit = {
    EmtBpPath .. 'terran_fragmentation_grenade_hit_01_emit.bp',
    EmtBpPath .. 'terran_fragmentation_grenade_hit_02_emit.bp',
    EmtBpPath .. 'terran_fragmentation_grenade_hit_03_emit.bp',
    EmtBpPath .. 'terran_fragmentation_grenade_hit_04_emit.bp',
    EmtBpPath .. 'terran_fragmentation_grenade_hit_05_emit.bp',
    EmtBpPath .. 'terran_fragmentation_grenade_hit_06_emit.bp',
    EmtBpPath .. 'terran_fragmentation_grenade_hit_07_emit.bp',
    EmtBpPath .. 'terran_fragmentation_grenade_hit_08_emit.bp',
}
THeavyFragmentationGrenadeUnitHit = {
    EmtBpPath .. 'terran_fragmentation_grenade_hit_01_emit.bp',
    EmtBpPath .. 'terran_fragmentation_grenade_hit_02_emit.bp',
    EmtBpPath .. 'terran_fragmentation_grenade_hit_03_emit.bp',
    EmtBpPath .. 'terran_fragmentation_grenade_hit_04_emit.bp',
    EmtBpPath .. 'terran_fragmentation_grenade_hit_05_emit.bp',
    EmtBpPath .. 'terran_fragmentation_grenade_hit_06_emit.bp',
    EmtBpPath .. 'terran_fragmentation_grenade_hit_07_emit.bp',
    EmtBpPath .. 'terran_fragmentation_grenade_hit_08_emit.bp',
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
}
THeavyFragmentationGrenadeFxTrails = {
    EmtBpPath .. 'terran_fragmentation_grenade_fxtrail_01_emit.bp',
}

THeavyFragmentationGrenadePolyTrail = EmtBpPath .. 'default_polytrail_02_emit.bp'


-- ------------------------------------------------------------------------
--  TERRAN HEAVY NAPALM CARPET BOMB EMITTERS
-- ------------------------------------------------------------------------
TNapalmHvyCarpetBombHitUnit01 = {
    EmtBpPath .. 'flash_01_emit.bp',
}
TNapalmHvyCarpetBombHitLand01 = {
    EmtBpPath .. 'napalm_hvy_flash_emit.bp',
    EmtBpPath .. 'napalm_hvy_thick_smoke_emit.bp',
    -- EmtBpPath .. 'napalm_hvy_fire_emit.bp',
    EmtBpPath .. 'napalm_hvy_thin_smoke_emit.bp',
    EmtBpPath .. 'napalm_hvy_01_emit.bp',
    EmtBpPath .. 'napalm_hvy_02_emit.bp',
    EmtBpPath .. 'napalm_hvy_03_emit.bp',
}
TNapalmHvyCarpetBombHitWater01 = {
    EmtBpPath .. 'napalm_hvy_waterflash_emit.bp',
    EmtBpPath .. 'napalm_hvy_water_smoke_emit.bp',
    EmtBpPath .. 'napalm_hvy_oilslick_emit.bp',
    EmtBpPath .. 'napalm_hvy_lines_emit.bp',
    EmtBpPath .. 'napalm_hvy_water_ripples_emit.bp',
    EmtBpPath .. 'napalm_hvy_water_dots_emit.bp',
}


-- ------------------------------------------------------------------------
--  TERRAN HEAVY PLASMA CANNON EMITTERS
-- ------------------------------------------------------------------------
TPlasmaCannonHeavyMuzzleFlash = {
    '/effects/emitters/plasma_cannon_muzzle_flash_01_emit.bp',
    '/effects/emitters/plasma_cannon_muzzle_flash_02_emit.bp',
    '/effects/emitters/cannon_muzzle_flash_01_emit.bp',
    '/effects/emitters/heavy_plasma_cannon_hitunit_05_emit.bp',
}
TPlasmaCannonHeavyHit02 = {
    EmtBpPath .. 'heavy_plasma_cannon_hit_01_emit.bp',
    EmtBpPath .. 'heavy_plasma_cannon_hit_02_emit.bp',
    EmtBpPath .. 'heavy_plasma_cannon_hit_03_emit.bp',
    EmtBpPath .. 'heavy_plasma_cannon_hit_04_emit.bp',
    EmtBpPath .. 'heavy_plasma_cannon_hit_05_emit.bp',
}
TPlasmaCannonHeavyHit03 = {
    EmtBpPath .. 'heavy_plasma_cannon_hit_05_emit.bp',
}
TPlasmaCannonHeavyHit04 = {
    EmtBpPath .. 'heavy_plasma_cannon_hitunit_05_emit.bp',
}
TPlasmaCannonHeavyHit01 = table.concatenate(TPlasmaCannonHeavyHit02, TPlasmaCannonHeavyHit03)
TPlasmaCannonHeavyHitUnit01 = table.concatenate(TPlasmaCannonHeavyHit02, TPlasmaCannonHeavyHit04, UnitHitShrapnel01)

TPlasmaCannonHeavyMunition = {
    EmtBpPath .. 'plasma_cannon_trail_02_emit.bp',
}
TPlasmaCannonHeavyMunition02 = {
    EmtBpPath .. 'plasma_cannon_trail_03_emit.bp',
}
TPlasmaCannonHeavyPolyTrails = {
    EmtBpPath .. 'plasma_cannon_polytrail_01_emit.bp',
    EmtBpPath .. 'plasma_cannon_polytrail_02_emit.bp',
    EmtBpPath .. 'plasma_cannon_polytrail_03_emit.bp',
}


-- ------------------------------------------------------------------------
--  TERRAN HEAVY PLASMA GATLING CANNON EMITTERS
-- ------------------------------------------------------------------------
THeavyPlasmaGatlingCannonHit = {
    EmtBpPath .. 'heavy_plasma_gatling_cannon_laser_hit_01_emit.bp',
    EmtBpPath .. 'heavy_plasma_gatling_cannon_laser_hit_02_emit.bp',
    EmtBpPath .. 'heavy_plasma_gatling_cannon_laser_hit_03_emit.bp',
    EmtBpPath .. 'heavy_plasma_gatling_cannon_laser_hit_04_emit.bp',
    EmtBpPath .. 'heavy_plasma_gatling_cannon_laser_hit_05_emit.bp',
}

THeavyPlasmaGatlingCannonHit02 = {
}

THeavyPlasmaGatlingCannonHitUnit = table.concatenate(THeavyPlasmaGatlingCannonHit, THeavyPlasmaGatlingCannonHit02, UnitHitShrapnel01)

THeavyPlasmaGatlingCannonMuzzleFlash = {
    EmtBpPath .. 'heavy_plasma_gatling_cannon_laser_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'heavy_plasma_gatling_cannon_laser_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'heavy_plasma_gatling_cannon_laser_muzzle_flash_03_emit.bp',
    EmtBpPath .. 'heavy_plasma_gatling_cannon_laser_muzzle_flash_04_emit.bp',
    EmtBpPath .. 'heavy_plasma_gatling_cannon_laser_muzzle_flash_05_emit.bp',
    EmtBpPath .. 'heavy_plasma_gatling_cannon_laser_muzzle_flash_06_emit.bp',
}
THeavyPlasmaGatlingCannonFxTrails = {
    -- EmtBpPath .. 'heavy_plasma_gatling_cannon_laser_fxtrail_01_emit.bp',
    -- -- EmtBpPath .. 'heavy_plasma_gatling_cannon_laser_fxtrail_02_emit.bp',
    -- -- -- EmtBpPath .. 'heavy_plasma_gatling_cannon_laser_fxtrail_03_emit.bp',
}
THeavyPlasmaGatlingCannonPolyTrail = EmtBpPath .. 'heavy_plasma_gatling_cannon_laser_polytrail_01_emit.bp'


-- ------------------------------------------------------------------------
--  TERRAN HIRO LASER EMITTERS
-- ------------------------------------------------------------------------
THiroLaserMuzzleFlash = {
    EmtBpPath .. 'hiro_laser_cannon_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'hiro_laser_cannon_muzzle_flash_02_emit.bp',
}
THiroLaserPolytrail =  EmtBpPath .. 'hiro_laser_cannon_polytrail_01_emit.bp'
THiroLaserFxtrails =  {
    EmtBpPath .. 'hiro_laser_cannon_fxtrail_01_emit.bp',
    EmtBpPath .. 'hiro_laser_cannon_fxtrail_02_emit.bp',
    EmtBpPath .. 'hiro_laser_cannon_fxtrail_03_emit.bp',
}
THiroLaserHit = {
    EmtBpPath .. 'hiro_laser_cannon_hit_01_emit.bp',
    EmtBpPath .. 'hiro_laser_cannon_hit_02_emit.bp',
    EmtBpPath .. 'hiro_laser_cannon_hit_03_emit.bp',
    EmtBpPath .. 'hiro_laser_cannon_hit_04_emit.bp',
}
THiroLaserUnitHit = {
    EmtBpPath .. 'hiro_laser_cannon_hit_01_emit.bp',
    EmtBpPath .. 'hiro_laser_cannon_hit_02_emit.bp',
    EmtBpPath .. 'hiro_laser_cannon_hit_03_emit.bp',
    EmtBpPath .. 'hiro_laser_cannon_hit_04_emit.bp',
    EmtBpPath .. 'hiro_laser_cannon_land_hit_01_emit.bp',
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
}
THiroLaserLandHit = {
    EmtBpPath .. 'hiro_laser_cannon_hit_01_emit.bp',
    EmtBpPath .. 'hiro_laser_cannon_hit_02_emit.bp',
    EmtBpPath .. 'hiro_laser_cannon_hit_03_emit.bp',
    EmtBpPath .. 'hiro_laser_cannon_hit_04_emit.bp',
    EmtBpPath .. 'hiro_laser_cannon_hit_05_emit.bp',
}

-- ------------------------------------------------------------------------
--  TERRAN HIRO BEAM GENERATOR EMITTERS
-- ------------------------------------------------------------------------
TDFHiroGeneratorMuzzle01 =
{
    EmtBpPath .. 'hiro_beam_generator_muzzle_01_emit.bp',
    EmtBpPath .. 'hiro_beam_generator_muzzle_02_emit.bp',
    EmtBpPath .. 'hiro_beam_generator_muzzle_03_emit.bp',
    EmtBpPath .. 'hiro_beam_generator_muzzle_04_emit.bp',
}

TDFHiroGeneratorHitLand = {
    EmtBpPath .. 'hiro_beam_generator_hit_01_emit.bp',
    EmtBpPath .. 'hiro_beam_generator_hit_02_emit.bp',
    EmtBpPath .. 'hiro_beam_generator_hit_03_emit.bp',
    EmtBpPath .. 'hiro_beam_generator_hit_04_emit.bp',
    EmtBpPath .. 'hiro_beam_generator_hit_05_emit.bp',
}

TDFHiroGeneratorBeam = {
    EmtBpPath .. 'hiro_beam_generator_beam_emit.bp',
}


-- ------------------------------------------------------------------------
--  TERRAN IONIZED GATLING CANNON EMITTERS
-- ------------------------------------------------------------------------
TIonizedPlasmaGatlingCannonHit01 = {
    EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_hit_01_emit.bp',
    EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_hit_02_emit.bp',
    EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_hit_03_emit.bp',
    EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_hit_04_emit.bp',
    EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_hit_05_emit.bp',
    EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_hit_06_emit.bp',
}
TIonizedPlasmaGatlingCannonHit02 = {
    EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_land_hit_01_emit.bp',
    EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_land_hit_02_emit.bp',
}
TIonizedPlasmaGatlingCannonHit03 = {
    EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_hitunit_01_emit.bp',
    EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_hitunit_03_emit.bp',
    EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_hitunit_06_emit.bp',
}
TIonizedPlasmaGatlingCannonUnitHit = table.concatenate(TIonizedPlasmaGatlingCannonHit01, TIonizedPlasmaGatlingCannonHit03, UnitHitShrapnel01)
TIonizedPlasmaGatlingCannonHit = table.concatenate(TIonizedPlasmaGatlingCannonHit01, TIonizedPlasmaGatlingCannonHit02)
TIonizedPlasmaGatlingCannonMuzzleFlash = {
    EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_muzzle_flash_03_emit.bp',
    EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_muzzle_flash_04_emit.bp',
    EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_muzzle_flash_05_emit.bp',
    EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_muzzle_flash_06_emit.bp',
}
TIonizedPlasmaGatlingCannonFxTrails = {
    EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_fxtrail_01_emit.bp',
    EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_fxtrail_02_emit.bp',
    EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_fxtrail_03_emit.bp',
}
TIonizedPlasmaGatlingCannonPolyTrail = EmtBpPath .. 'ionized_plasma_gatling_cannon_laser_polytrail_01_emit.bp'


-- ------------------------------------------------------------------------
--  TERRAN MACHINE GUN EMITTERS
-- ------------------------------------------------------------------------
TMachineGunPolyTrail =  EmtBpPath .. 'machinegun_polytrail_01_emit.bp'


-- ------------------------------------------------------------------------
--  TERRAN MISSILE EMITTERS
-- ------------------------------------------------------------------------
TAAMissileLaunch = {
    EmtBpPath .. 'terran_sam_launch_smoke_emit.bp',
    EmtBpPath .. 'terran_sam_launch_smoke2_emit.bp',
}
TAAMissileLaunchNoBackSmoke = {
    EmtBpPath .. 'terran_sam_launch_smoke_emit.bp',
}
TMissileExhaust01 = { EmtBpPath .. 'missile_munition_trail_01_emit.bp',}
TMissileExhaust02 = { EmtBpPath .. 'missile_munition_trail_02_emit.bp',}
TMissileExhaust03 = { EmtBpPath .. 'missile_smoke_exhaust_02_emit.bp',}


-- ------------------------------------------------------------------------
--  TERRAN MOBILE MORTAR EMITTERS
-- ------------------------------------------------------------------------
TMobileMortarMuzzleEffect01 = {
    EmtBpPath .. 'cannon_muzzle_smoke_02_emit.bp',
    EmtBpPath .. 'cannon_muzzle_smoke_09_emit.bp',
    EmtBpPath .. 'cannon_artillery_fire_01_emit.bp',
    EmtBpPath .. 'cannon_artillery_flash_01_emit.bp',
}


-- ------------------------------------------------------------------------
--  TERRAN NAPALM CARPET BOMB EMITTERS
-- ------------------------------------------------------------------------
TNapalmCarpetBombHitUnit01 = {
    EmtBpPath .. 'flash_01_emit.bp',
}
TNapalmCarpetBombHitLand01 = {
    EmtBpPath .. 'napalm_flash_emit.bp',
    EmtBpPath .. 'napalm_thick_smoke_emit.bp',
    -- EmtBpPath .. 'napalm_fire_emit.bp',
    EmtBpPath .. 'napalm_thin_smoke_emit.bp',
    EmtBpPath .. 'napalm_01_emit.bp',
    EmtBpPath .. 'napalm_02_emit.bp',
    EmtBpPath .. 'napalm_03_emit.bp',
}
TNapalmCarpetBombHitWater01 = {
    EmtBpPath .. 'napalm_hvy_waterflash_emit.bp',
    EmtBpPath .. 'napalm_hvy_water_smoke_emit.bp',
    EmtBpPath .. 'napalm_hvy_oilslick_emit.bp',
    EmtBpPath .. 'napalm_hvy_lines_emit.bp',
    EmtBpPath .. 'napalm_hvy_water_ripples_emit.bp',
    EmtBpPath .. 'napalm_hvy_water_dots_emit.bp',
}


-- ------------------------------------------------------------------------
--  TERRAN NUKE EMITTERS
-- ------------------------------------------------------------------------
TNukeRings01 = {
    EmtBpPath .. 'nuke_concussion_ring_01_emit.bp',
    EmtBpPath .. 'nuke_concussion_ring_02_emit.bp',
    EmtBpPath .. 'shockwave_01_emit.bp',
    EmtBpPath .. 'shockwave_smoke_01_emit.bp',
}
Twig = {
    EmtBpPath .. 'nuke_concussion_ring_01_emit.bp',
    EmtBpPath .. 'nuke_concussion_ring_02_emit.bp',
    EmtBpPath .. 'shockwave_01_emit.bp',
    EmtBpPath .. 'shockwave_smoke_01_emit.bp',
}
TNukeFlavorPlume01 = { EmtBpPath .. 'nuke_smoke_trail01_emit.bp', }
TNukeGroundConvectionEffects01 = { EmtBpPath .. 'nuke_mist_01_emit.bp', }
TNukeBaseEffects01 = { EmtBpPath .. 'nuke_base03_emit.bp', }
TNukeBaseEffects02 = { EmtBpPath .. 'nuke_base05_emit.bp', }
TNukeHeadEffects01 = { EmtBpPath .. 'nuke_plume_01_emit.bp', }
TNukeHeadEffects02 = {
    EmtBpPath .. 'nuke_head_smoke_03_emit.bp',
    EmtBpPath .. 'nuke_head_smoke_04_emit.bp',

}
TNukeHeadEffects03 = { EmtBpPath .. 'nuke_head_fire_01_emit.bp', }


-- ------------------------------------------------------------------------
--  TERRAN RAIL GUN EMITTERS
-- ------------------------------------------------------------------------
TRailGunMuzzleFlash01 = { EmtBpPath .. 'railgun_flash_02_emit.bp', }
TRailGunMuzzleFlash02 = { EmtBpPath .. 'muzzle_flash_01_emit.bp', }
TRailGunHitAir01 = {
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
    EmtBpPath .. 'terran_railgun_hit_air_01_emit.bp',
    EmtBpPath .. 'terran_railgun_hit_air_02_emit.bp',
    EmtBpPath .. 'terran_railgun_hit_air_03_emit.bp',
}
TRailGunHitGround01 = {
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
    EmtBpPath .. 'terran_railgun_hit_ground_01_emit.bp',
    EmtBpPath .. 'terran_railgun_hit_air_02_emit.bp',
    EmtBpPath .. 'terran_railgun_hit_ground_03_emit.bp',
}


-- ------------------------------------------------------------------------
--  TERRAN RIOTGUN EMITTERS
-- ------------------------------------------------------------------------
TRiotGunHit01 = {
     EmtBpPath .. 'riot_gun_hit_01_emit.bp',
     EmtBpPath .. 'riot_gun_hit_02_emit.bp',
     EmtBpPath .. 'riot_gun_hit_03_emit.bp',
}
TRiotGunHitUnit01 = table.concatenate(TRiotGunHit01, UnitHitShrapnel01)
TRiotGunHit02 = {
     EmtBpPath .. 'riot_gun_hit_04_emit.bp',
     EmtBpPath .. 'riot_gun_hit_05_emit.bp',
     EmtBpPath .. 'riot_gun_hit_06_emit.bp',
}
TRiotGunHitUnit02 = table.concatenate(TRiotGunHit02, UnitHitShrapnel01)
TRiotGunMuzzleFx = {
    EmtBpPath .. 'riotgun_muzzle_fire_01_emit.bp',
    EmtBpPath .. 'riotgun_muzzle_flash_01_emit.bp',
    -- EmtBpPath .. 'riotgun_muzzle_smoke_01_emit.bp',
    EmtBpPath .. 'riotgun_muzzle_sparks_01_emit.bp',
    EmtBpPath .. 'cannon_muzzle_flash_01_emit.bp',
}
TRiotGunMuzzleFxTank = {
    EmtBpPath .. 'riotgun_muzzle_fire_01_emit.bp',
    EmtBpPath .. 'riotgun_muzzle_flash_03_emit.bp',
    -- EmtBpPath .. 'riotgun_muzzle_smoke_01_emit.bp',
    EmtBpPath .. 'riotgun_muzzle_sparks_02_emit.bp',
    -- EmtBpPath .. 'cannon_muzzle_flash_01_emit.bp',
}
TRiotGunPolyTrails = {
    EmtBpPath .. 'riot_gun_polytrail_01_emit.bp',
    EmtBpPath .. 'riot_gun_polytrail_02_emit.bp',
    EmtBpPath .. 'riot_gun_polytrail_03_emit.bp',
}
TRiotGunPolyTrailsTank = {
    EmtBpPath .. 'riot_gun_polytrail_tank_01_emit.bp',
    EmtBpPath .. 'riot_gun_polytrail_tank_02_emit.bp',
    EmtBpPath .. 'riot_gun_polytrail_tank_03_emit.bp',
}
TRiotGunPolyTrailsEngineer = {
    EmtBpPath .. 'riot_gun_polytrail_engi_01_emit.bp',
    EmtBpPath .. 'riot_gun_polytrail_engi_02_emit.bp',
    EmtBpPath .. 'riot_gun_polytrail_engi_03_emit.bp',
}
TRiotGunPolyTrailsOffsets = {0.05,0.05,0.05}

TRiotGunMunition01 = {
    EmtBpPath .. 'riotgun_munition_01_emit.bp',
}


-- ------------------------------------------------------------------------
--  TERRAN PHALANX GUN EMITTERS
-- ------------------------------------------------------------------------
TPhalanxGunPolyTrails = {
    EmtBpPath .. 'phalanx_munition_polytrail_01_emit.bp',
}
TPhalanxGunMuzzleFlash = {
    EmtBpPath .. 'phalanx_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'phalanx_muzzle_glow_01_emit.bp',
}
TPhalanxGunShells = {
    EmtBpPath .. 'phalanx_shells_01_emit.bp',
}
TPhalanxGunPolyTrailsOffsets = {0.05,0.05,0.05}


-- ------------------------------------------------------------------------
--  TERRAN PLASMA CANNON EMITTERS
-- ------------------------------------------------------------------------
TPlasmaCannonLightMuzzleFlash = {
    '/effects/emitters/plasma_cannon_muzzle_flash_03_emit.bp',
    '/effects/emitters/plasma_cannon_muzzle_flash_04_emit.bp',
}
TPlasmaCannonLightHit01 = {
    EmtBpPath .. 'plasma_cannon_hit_01_emit.bp',
    EmtBpPath .. 'plasma_cannon_hit_02_emit.bp',
    EmtBpPath .. 'plasma_cannon_hit_03_emit.bp',
    EmtBpPath .. 'cannon_muzzle_flash_01_emit.bp',
}
TPlasmaCannonLightHitUnit01 = TPlasmaCannonLightHit01
TPlasmaCannonLightHitLand01 = TPlasmaCannonLightHit01

TPlasmaCannonLightMunition = {
    EmtBpPath .. 'plasma_cannon_trail_01_emit.bp',
}
TPlasmaCannonLightPolyTrail = EmtBpPath .. 'plasma_cannon_polytrail_04_emit.bp'


-- ------------------------------------------------------------------------
--  TERRAN PLASMA GATLING CANNON EMITTERS
-- ------------------------------------------------------------------------
TPlasmaGatlingCannonMuzzleFlash = {
    EmtBpPath .. 'terran_gatling_plasma_cannon_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'terran_gatling_plasma_cannon_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'terran_gatling_plasma_cannon_muzzle_flash_03_emit.bp',
    EmtBpPath .. 'terran_gatling_plasma_cannon_muzzle_flash_04_emit.bp',
    EmtBpPath .. 'terran_gatling_plasma_cannon_muzzle_flash_05_emit.bp',
    EmtBpPath .. 'terran_gatling_plasma_cannon_muzzle_flash_06_emit.bp',
}

TPlasmaGatlingCannonHit = {
    EmtBpPath .. 'terran_gatling_plasma_cannon_hit_01_emit.bp',
    EmtBpPath .. 'terran_gatling_plasma_cannon_hit_02_emit.bp',
    EmtBpPath .. 'terran_gatling_plasma_cannon_hit_03_emit.bp',
    EmtBpPath .. 'terran_gatling_plasma_cannon_hit_04_emit.bp',
    EmtBpPath .. 'terran_gatling_plasma_cannon_hit_05_emit.bp',
}

TPlasmaGatlingCannonUnitHit = {
    EmtBpPath .. 'terran_gatling_plasma_cannon_hit_01_emit.bp',
    EmtBpPath .. 'terran_gatling_plasma_cannon_hitunit_01_emit.bp',
    EmtBpPath .. 'terran_gatling_plasma_cannon_hitunit_02_emit.bp',
    EmtBpPath .. 'terran_gatling_plasma_cannon_hitunit_03_emit.bp',
    EmtBpPath .. 'terran_gatling_plasma_cannon_hitunit_04_emit.bp',
    EmtBpPath .. 'terran_gatling_plasma_cannon_hit_05_emit.bp',
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
}

TPlasmaGatlingCannonFxTrails = {
    EmtBpPath .. 'terran_gatling_plasma_cannon_trail_01_emit.bp',
}

TPlasmaGatlingCannonPolyTrails = {
    EmtBpPath .. 'terran_gatling_plasma_cannon_polytrail_01_emit.bp',
    EmtBpPath .. 'terran_gatling_plasma_cannon_polytrail_02_emit.bp',
    EmtBpPath .. 'terran_gatling_plasma_cannon_polytrail_03_emit.bp',
}

TPlasmaGatlingCannonPolyTrailsOffsets = {0.05,0.05,0.05}

-- ------------------------------------------------------------------------
--  TERRAN SMALL YIELD NUCLEAR BOMB EMITTERS
-- ------------------------------------------------------------------------
TSmallYieldNuclearBombHit01 = {
    EmtBpPath .. 'terran_bomber_bomb_explosion_01_emit.bp',
    -- EmtBpPath .. 'terran_bomber_bomb_explosion_02_emit.bp',
    EmtBpPath .. 'terran_bomber_bomb_explosion_03_emit.bp',
    EmtBpPath .. 'terran_bomber_bomb_explosion_05_emit.bp',
    EmtBpPath .. 'terran_bomber_bomb_explosion_06_emit.bp',
}


-- ------------------------------------------------------------------------
--  TERRAN TACTICAL CRUISE MISSILE EMITTERS
-- ------------------------------------------------------------------------
TIFCruiseMissileLaunchSmoke = {
    EmtBpPath .. 'terran_cruise_missile_launch_01_emit.bp',
    EmtBpPath .. 'terran_cruise_missile_launch_02_emit.bp',
}
TIFCruiseMissileLaunchBuilding = {
    EmtBpPath .. 'terran_cruise_missile_launch_03_emit.bp',
    EmtBpPath .. 'terran_cruise_missile_launch_04_emit.bp',
    EmtBpPath .. 'terran_cruise_missile_launch_05_emit.bp',
}
TIFCruiseMissileLaunchUnderWater = {
    EmtBpPath .. 'terran_cruise_missile_sublaunch_01_emit.bp',
}
TIFCruiseMissileLaunchExitWater = {
    EmtBpPath .. 'water_splash_ripples_ring_01_emit.bp',
    EmtBpPath .. 'water_splash_plume_01_emit.bp',
}


-- ------------------------------------------------------------------------
--  TERRAN TACTICAL MISSILE EMITTERS
-- ------------------------------------------------------------------------
TMissileHit01 = {
    EmtBpPath .. 'terran_missile_hit_01_emit.bp',
    EmtBpPath .. 'terran_missile_hit_02_emit.bp',
    EmtBpPath .. 'terran_missile_hit_03_emit.bp',
    EmtBpPath .. 'terran_missile_hit_04_emit.bp',
}

TMissileKilled01 = {
    EmtBpPath .. 'terran_missile_hit_01_emit.bp',
    EmtBpPath .. 'terran_missile_hit_02_emit.bp',
    EmtBpPath .. 'tactical_debris_smoke_01_emit.bp',
    -- EmtBpPath .. 'terran_missile_hit_03_emit.bp',
    -- EmtBpPath .. 'terran_missile_hit_04_emit.bp',
}

TMissileHit02 = {
    EmtBpPath .. 'terran_missile_hit_01_emit.bp',
    EmtBpPath .. 'terran_missile_hit_02_emit.bp',
    EmtBpPath .. 'terran_missile_hit_03_emit.bp',
}


-- ------------------------------------------------------------------------
--  TERRAN TORPEDO EMITTERS
-- ------------------------------------------------------------------------
TTorpedoHitUnit01 = table.concatenate(DefaultProjectileWaterImpact, DefaultProjectileUnderWaterImpact)
TTorpedoHitUnitUnderwater01 = DefaultProjectileUnderWaterImpact




-- ---------------------------------------------------------------
-- -- -- -- -- -- -- SERAPHIM AMBIENTS -- -- -- -- -- --
-- ---------------------------------------------------------------

SerRiftIn_Small = {
    EmtBpPath .. 'seraphim_rift_in_small_01_emit.bp',
    EmtBpPath .. 'seraphim_rift_in_small_02_emit.bp',
}
SerRiftIn_SmallFlash = {
    EmtBpPath .. 'seraphim_rift_in_small_03_emit.bp',
    EmtBpPath .. 'seraphim_rift_in_small_04_emit.bp',
}

SerRiftIn_Large = {
    EmtBpPath .. 'seraphim_rift_in_large_01_emit.bp',
    EmtBpPath .. 'seraphim_rift_in_large_02_emit.bp',
}
SerRiftIn_LargeFlash = {
    EmtBpPath .. 'seraphim_rift_in_large_03_emit.bp',
    EmtBpPath .. 'seraphim_rift_in_large_04_emit.bp',
}

SAdjacencyAmbient01 = {
    '/effects/emitters/seraphim_adjacency_node_01_emit.bp',
    '/effects/emitters/seraphim_adjacency_node_02_emit.bp',
    '/effects/emitters/seraphim_adjacency_node_03_emit.bp',
}

SAdjacencyAmbient02 = {
    '/effects/emitters/seraphim_adjacency_node_01_emit.bp',
    '/effects/emitters/seraphim_adjacency_node_02_emit.bp',
    '/effects/emitters/seraphim_adjacency_node_03a_emit.bp',
}

SAdjacencyAmbient03 = {
    '/effects/emitters/seraphim_adjacency_node_01_emit.bp',
    '/effects/emitters/seraphim_adjacency_node_02_emit.bp',
    '/effects/emitters/seraphim_adjacency_node_03b_emit.bp',
}

-- ------------------------------------------------------------------------
--  SERAPHIM UYA-IYA POWER GENERATOR
-- ------------------------------------------------------------------------
ST1PowerAmbient = {
    EmtBpPath .. 'seraphim_t1_power_ambient_01_emit.bp',
    EmtBpPath .. 'seraphim_t1_power_ambient_02_emit.bp',
}
ST2PowerAmbient = {
    EmtBpPath .. 'seraphim_t2_power_ambient_01_emit.bp',
    EmtBpPath .. 'seraphim_t2_power_ambient_02_emit.bp',
}
ST3PowerAmbient = {
    EmtBpPath .. 'seraphim_t3power_ambient_01_emit.bp',
    EmtBpPath .. 'seraphim_t3power_ambient_02_emit.bp',
    EmtBpPath .. 'seraphim_t3power_ambient_04_emit.bp',
}
OthuyAmbientEmanation = {
    EmtBpPath .. 'seraphim_othuy_ambient_01_emit.bp',
    EmtBpPath .. 'seraphim_othuy_ambient_02_emit.bp',
    EmtBpPath .. 'seraphim_othuy_ambient_03_emit.bp',
    EmtBpPath .. 'seraphim_othuy_ambient_04_emit.bp',
    EmtBpPath .. 'seraphim_othuy_ambient_05_emit.bp',
    EmtBpPath .. 'seraphim_othuy_ambient_06_emit.bp',
}
OthuyElectricityStrikeBeam = {
    EmtBpPath .. 'seraphim_othuy_beam_01_emit.bp',
}
OthuyElectricityStrikeHit = {
    EmtBpPath .. 'seraphim_othuy_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_othuy_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_othuy_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_othuy_hit_04_emit.bp',
}
OthuyElectricityStrikeMuzzleFlash = {
    EmtBpPath .. 'seraphim_othuy_beam_01_emit.bp',
}



-- ------------------------------------------------------------------------
--  SERAPHIM JAMMER CRYSTAL EMITTERS
-- ------------------------------------------------------------------------
SJammerCrystalAmbient = {
    EmtBpPath .. 'op_quantum_jammer_crystal.bp',
    EmtBpPath .. 'jammer_ambient_03_emit.bp',
}

-- ------------------------------------------------------------------------
--  SERAPHIM QUANTUM JAMMER TOWER EMITTERS
-- ------------------------------------------------------------------------
SJammerTowerAmbient = {
    EmtBpPath .. 'op_seraphim_quantum_jammer_tower_emit.bp',
    EmtBpPath .. 'jammer_ambient_01_emit.bp',
}

SJammerTowerWire1Ambient = EmtBpPath .. 'op_seraphim_quantum_jammer_tower_wire_01_emit.bp'
SJammerTowerWire2Ambient = EmtBpPath .. 'op_seraphim_quantum_jammer_tower_wire_02_emit.bp'
SJammerTowerWire3Ambient = EmtBpPath .. 'op_seraphim_quantum_jammer_tower_wire_03_emit.bp'
SJammerTowerWire4Ambient = EmtBpPath .. 'op_seraphim_quantum_jammer_tower_wire_04_emit.bp'

-- ---------------------------------------------------------------
-- -- -- -- -- -- -- SERAPHIM PROJECTILES -- -- -- -- -- --
-- ---------------------------------------------------------------

-- ------------------------------------------------------------------------
--  SERAPHIM AIRE-AU AUTOCANNON
-- ------------------------------------------------------------------------
SDFAireauWeaponPolytrails01 = {
    EmtBpPath .. 'seraphim_aireau_autocannon_polytrail_01_emit.bp',
    EmtBpPath .. 'seraphim_aireau_autocannon_polytrail_02_emit.bp',
    EmtBpPath .. 'seraphim_aireau_autocannon_polytrail_03_emit.bp',
}

SDFAireauWeaponMuzzleFlash = {
    EmtBpPath .. 'seraphim_aireau_autocannon_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'seraphim_aireau_autocannon_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_aireau_autocannon_muzzle_flash_03_emit.bp',
}

SDFAireauWeaponHit01 = {
    EmtBpPath .. 'seraphim_aireau_autocannon_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_aireau_autocannon_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_aireau_autocannon_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_aireau_autocannon_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_aireau_autocannon_hit_05_emit.bp',
}

SDFAireauWeaponHit02 = {
    EmtBpPath .. 'seraphim_aireau_autocannon_hitunit_04_emit.bp',
    EmtBpPath .. 'seraphim_aireau_autocannon_hitunit_05_emit.bp',
}

SDFAireauWeaponHitUnit = table.concatenate(SDFAireauWeaponHit01, SDFAireauWeaponHit02, UnitHitShrapnel01)

-- ------------------------------------------------------------------------
--  SERAPHIM SINN-UTHE CANNON
-- ------------------------------------------------------------------------

SDFSinnutheWeaponMuzzleFlash = {
    EmtBpPath .. 'seraphim_sinnuthe_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'seraphim_sinnuthe_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_sinnuthe_muzzle_flash_03_emit.bp',
    EmtBpPath .. 'seraphim_sinnuthe_muzzle_flash_04_emit.bp',
    EmtBpPath .. 'seraphim_sinnuthe_muzzle_flash_05_emit.bp',
}

SDFSinnutheWeaponChargeMuzzleFlash = {
    EmtBpPath .. 'seraphim_sinnuthe_muzzle_charge_01_emit.bp',
    EmtBpPath .. 'seraphim_sinnuthe_muzzle_charge_02_emit.bp',
    EmtBpPath .. 'seraphim_sinnuthe_muzzle_charge_03_emit.bp',
}

SDFSinnutheWeaponHit01 = {
    EmtBpPath .. 'seraphim_sinnuthe_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_sinnuthe_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_sinnuthe_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_sinnuthe_hit_05_emit.bp',
    EmtBpPath .. 'seraphim_sinnuthe_hit_06_emit.bp',
    EmtBpPath .. 'seraphim_sinnuthe_hit_07_emit.bp',
    EmtBpPath .. 'seraphim_sinnuthe_hit_08_emit.bp',
    EmtBpPath .. 'seraphim_sinnuthe_hit_09_emit.bp',
    EmtBpPath .. 'seraphim_sinnuthe_hit_10_emit.bp',
}

SDFSinnutheWeaponHit02 = {
    EmtBpPath .. 'seraphim_sinnuthe_hit_04_emit.bp',
}

SDFSinnutheWeaponHit03 = {
    EmtBpPath .. 'seraphim_sinnuthe_hitunit_04_emit.bp',
}

SDFSinnutheWeaponHit = table.concatenate(SDFSinnutheWeaponHit01, SDFSinnutheWeaponHit02)
SDFSinnutheWeaponHitUnit = table.concatenate(SDFSinnutheWeaponHit01, SDFSinnutheWeaponHit03, UnitHitShrapnel01)

SDFSinnutheWeaponFXTrails01 = {
    EmtBpPath .. 'seraphim_sinnuthe_fxtrails_01_emit.bp',
    EmtBpPath .. 'seraphim_sinnuthe_fxtrails_02_emit.bp',
    EmtBpPath .. 'seraphim_sinnuthe_fxtrails_03_emit.bp',
}

-- ------------------------------------------------------------------------
--  SERAPHIM EXPERIMENTAL PHASON PROJECTILE
-- ------------------------------------------------------------------------

SDFExperimentalPhasonProjMuzzleFlash = {
    EmtBpPath .. 'seraphim_experimental_phasonproj_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_muzzle_flash_03_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_muzzle_flash_04_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_muzzle_flash_05_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_muzzle_flash_06_emit.bp',
}

SDFExperimentalPhasonProjChargeMuzzleFlash = {
    EmtBpPath .. 'seraphim_experimental_phasonproj_muzzle_charge_01_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_muzzle_charge_02_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_muzzle_charge_03_emit.bp',
}

SDFExperimentalPhasonProjHit01 = {
    EmtBpPath .. 'seraphim_experimental_phasonproj_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_hit_05_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_hit_06_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_hit_07_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_hit_08_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_hit_09_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_hit_10_emit.bp',
}

SDFExperimentalPhasonProjHit02 = {
    EmtBpPath .. 'seraphim_experimental_phasonproj_hitunit_01_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_hitunit_08_emit.bp',
}

SDFExperimentalPhasonProjHitUnit = table.concatenate(SDFExperimentalPhasonProjHit01, SDFExperimentalPhasonProjHit02, UnitHitShrapnel01)

SDFExperimentalPhasonProjFXTrails01 = {
    EmtBpPath .. 'seraphim_experimental_phasonproj_fxtrails_01_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_fxtrails_02_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_fxtrails_03_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_fxtrails_04_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_fxtrails_05_emit.bp',
    EmtBpPath .. 'seraphim_experimental_phasonproj_fxtrails_06_emit.bp',
}

-- ------------------------------------------------------------------------
--  SERAPHIM AJELLU ANTI TORPEDO EMITTERS
-- ------------------------------------------------------------------------
SDFAjelluAntiTorpedoLaunch01 = {
    EmtBpPath .. 'seraphim_ajellu_muzzle_flash_01_emit.bp',
}

SDFAjelluAntiTorpedoPolyTrail01 = {
    EmtBpPath .. 'seraphim_ajellu_polytrail_01_emit.bp',
    EmtBpPath .. 'seraphim_ajellu_polytrail_02_emit.bp',
}

SDFAjelluAntiTorpedoHit01 = {
    EmtBpPath .. 'seraphim_ajellu_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_ajellu_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_ajellu_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_ajellu_hit_04_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM HU EMITTERS
-- ------------------------------------------------------------------------
SIFHuHit01 = DefaultMissileHit01

SIFHuImpact01 = DefaultProjectileAirUnitImpact

SIFHuLaunch01 = {
    EmtBpPath .. 'saint_launch_01_emit.bp',
}



-- ------------------------------------------------------------------------
--  SERAPHIM INAINO NUKE
-- ------------------------------------------------------------------------
SIFInainoPreLaunch01 = {
    EmtBpPath .. 'seraphim_inaino_prelaunch_01_emit.bp',
    EmtBpPath .. 'seraphim_inaino_prelaunch_02_emit.bp',
    EmtBpPath .. 'seraphim_inaino_prelaunch_03_emit.bp',
}

SIFInainoLaunch01 = {
    EmtBpPath .. 'seraphim_inaino_launch_01_emit.bp', -- -- glow
    EmtBpPath .. 'seraphim_inaino_launch_02_emit.bp', -- -- plasma down
    EmtBpPath .. 'seraphim_inaino_launch_03_emit.bp', -- -- flash
    EmtBpPath .. 'seraphim_inaino_launch_04_emit.bp', -- -- plasma out
    EmtBpPath .. 'seraphim_inaino_launch_05_emit.bp', -- -- rings
}

SIFInainoHit01 = {
    EmtBpPath .. 'seraphim_inaino_hit_03_emit.bp', 		-- -- long glow
    EmtBpPath .. 'seraphim_inaino_hit_07_emit.bp', 		-- -- outer ring sucking in, ground oriented
    EmtBpPath .. 'seraphim_inaino_hit_08_emit.bp', 		-- -- fast flash
    EmtBpPath .. 'seraphim_inaino_concussion_04_emit.bp', -- -- ring slow
}

SIFInainoHit02 = {
    EmtBpPath .. 'seraphim_inaino_hit_01_emit.bp', 	-- -- ring alpha oriented
    EmtBpPath .. 'seraphim_inaino_hit_02_emit.bp', 	-- -- ring add oriented
    EmtBpPath .. 'seraphim_inaino_hit_03_emit.bp', 	-- -- long glow oriented
    EmtBpPath .. 'seraphim_inaino_hit_04_emit.bp', 	-- -- blue plasma lines add
    EmtBpPath .. 'seraphim_inaino_hit_05_emit.bp', 	-- -- ring add upwards
    EmtBpPath .. 'seraphim_inaino_hit_06_emit.bp', 	-- -- ring, darkening lines inward
}

SIFInainoDetonate01 = {
    EmtBpPath .. 'seraphim_inaino_explode_01_emit.bp', 	-- -- glow in air
    EmtBpPath .. 'seraphim_inaino_concussion_01_emit.bp', -- -- ring
    EmtBpPath .. 'seraphim_inaino_concussion_02_emit.bp', -- -- outward lines, faint add
    EmtBpPath .. 'seraphim_inaino_concussion_03_emit.bp', -- -- ring slow
    EmtBpPath .. 'seraphim_inaino_explode_02_emit.bp', 	-- -- faint plasma downward
    EmtBpPath .. 'seraphim_inaino_explode_03_emit.bp', 	-- -- vertical plasma, ser7
    EmtBpPath .. 'seraphim_inaino_explode_04_emit.bp', 	-- -- ring outward add oriented
    EmtBpPath .. 'seraphim_inaino_explode_05_emit.bp', 	-- -- glow on ground, oriented
    EmtBpPath .. 'seraphim_inaino_explode_06_emit.bp', 	-- -- fast flash in air
    EmtBpPath .. 'seraphim_inaino_explode_07_emit.bp', 	-- -- long glow in air, oriented
    EmtBpPath .. 'seraphim_inaino_explode_08_emit.bp', 	-- -- center plasma, ser7
}

SIFInainoPlumeFxTrails01 = {
    EmtBpPath .. 'seraphim_inaino_plume_fxtrails_01_emit.bp', -- -- bright center
    EmtBpPath .. 'seraphim_inaino_plume_fxtrails_02_emit.bp', -- -- faint plasma trails
}

SIFInainoPlumeFxTrails02 = {
    EmtBpPath .. 'seraphim_inaino_plume_fxtrails_03_emit.bp', -- -- oriented glows
    EmtBpPath .. 'seraphim_inaino_plume_fxtrails_04_emit.bp', -- -- plasma
}

SIFInainoPlumeFxTrails03 = {
    EmtBpPath .. 'seraphim_inaino_plume_fxtrails_05_emit.bp', -- -- upwards nuke cloud
    EmtBpPath .. 'seraphim_inaino_plume_fxtrails_06_emit.bp', -- -- upwards nuke cloud highlights
}

SIFInainoHitRingProjectileFxTrails01 = {
    EmtBpPath .. 'seraphim_inaino_hitring_fxtrails_01_emit.bp',
    EmtBpPath .. 'seraphim_inaino_hitring_fxtrails_02_emit.bp',
}

-- ------------------------------------------------------------------------
--  SERAPHIM EXPERIMENTAL NUKE
-- ------------------------------------------------------------------------

SIFExperimentalStrategicLauncherReload01 = {
    EmtBpPath .. 'seraphim_expnuke_prelaunch_02_emit.bp', -- -- down + right upward lines
    EmtBpPath .. 'seraphim_expnuke_prelaunch_03_emit.bp', -- -- down + left upward lines
    EmtBpPath .. 'seraphim_expnuke_prelaunch_04_emit.bp', -- -- up upward lines
    EmtBpPath .. 'seraphim_expnuke_prelaunch_05_emit.bp', -- -- down + right coalescing orb
    EmtBpPath .. 'seraphim_expnuke_prelaunch_06_emit.bp', -- -- down + left coalescing orb
    EmtBpPath .. 'seraphim_expnuke_prelaunch_07_emit.bp', -- -- up coalescing orb
}

SIFExperimentalStrategicLauncherLoaded01 = {
    EmtBpPath .. 'seraphim_expnuke_prelaunch_10_emit.bp', -- -- blueish glow, but infinite lifetime
}

SIFExperimentalStrategicMissileChargeLaunch01 = {
    EmtBpPath .. 'seraphim_expnuke_prelaunch_01_emit.bp', -- -- glowy plasma at bottom
    EmtBpPath .. 'seraphim_expnuke_prelaunch_08_emit.bp', -- -- inward dark lines
    EmtBpPath .. 'seraphim_expnuke_prelaunch_09_emit.bp', -- -- blueish glow
}

SIFExperimentalStrategicMissileLaunch01 = {
    EmtBpPath .. 'seraphim_expnuke_launch_01_emit.bp', -- -- glow
    EmtBpPath .. 'seraphim_expnuke_launch_02_emit.bp', -- -- plasma down
    EmtBpPath .. 'seraphim_expnuke_launch_03_emit.bp', -- -- flash
    EmtBpPath .. 'seraphim_expnuke_launch_04_emit.bp', -- -- plasma out
    EmtBpPath .. 'seraphim_expnuke_launch_05_emit.bp', -- -- rings
    EmtBpPath .. 'seraphim_expnuke_launch_06_emit.bp', -- -- plasma rings
    EmtBpPath .. 'seraphim_expnuke_launch_07_emit.bp', -- -- fast ring
    EmtBpPath .. 'seraphim_expnuke_launch_08_emit.bp', -- -- burn mark
    EmtBpPath .. 'seraphim_expnuke_launch_09_emit.bp', -- -- delayed plasma
}

SIFExperimentalStrategicMissileHit01 = {
    EmtBpPath .. 'seraphim_expnuke_hit_01_emit.bp', 		-- -- plasma outward
    EmtBpPath .. 'seraphim_expnuke_hit_02_emit.bp', 		-- -- spiky lines
    EmtBpPath .. 'seraphim_expnuke_hit_03_emit.bp', 		-- -- plasma darkening outward
    EmtBpPath .. 'seraphim_expnuke_hit_04_emit.bp', 		-- -- twirling line buildup
    EmtBpPath .. 'seraphim_expnuke_detonate_03_emit.bp', -- -- non oriented glow
    EmtBpPath .. 'seraphim_expnuke_concussion_01_emit.bp', -- -- ring fast
    EmtBpPath .. 'seraphim_expnuke_concussion_02_emit.bp', -- -- ring slow
}

SIFExperimentalStrategicMissileDetonate01 = {
    EmtBpPath .. 'seraphim_expnuke_detonate_01_emit.bp', 	-- -- upwards plasma darkening
    EmtBpPath .. 'seraphim_expnuke_detonate_02_emit.bp', 	-- -- upwards plasma ser7
    EmtBpPath .. 'seraphim_expnuke_detonate_03_emit.bp', 	-- -- non oriented glow
    EmtBpPath .. 'seraphim_expnuke_detonate_04_emit.bp', 	-- -- oriented glow
    EmtBpPath .. 'seraphim_expnuke_concussion_01_emit.bp', 	-- -- ring fast
}

SIFExperimentalStrategicMissileFxTrails01 = {
    EmtBpPath .. 'seraphim_inaino_hitring_fxtrails_01_emit.bp', 	-- -- clouds
    EmtBpPath .. 'seraphim_inaino_hitring_fxtrails_02_emit.bp', 	-- -- add clouds
}

SIFExperimentalStrategicMissilePlumeFxTrails01 = {
    EmtBpPath .. 'seraphim_inaino_plume_fxtrails_05_emit.bp', -- -- upwards nuke cloud
    EmtBpPath .. 'seraphim_inaino_plume_fxtrails_06_emit.bp', -- -- upwards nuke cloud highlights
}

SIFExperimentalStrategicMissilePlumeFxTrails02 = {
    EmtBpPath .. 'seraphim_expnuke_plume_fxtrails_03_emit.bp', -- -- upwards plasma cloud
    EmtBpPath .. 'seraphim_expnuke_plume_fxtrails_04_emit.bp', -- -- upwards plasma cloud darkening
}

SIFExperimentalStrategicMissilePlumeFxTrails03 = {
    EmtBpPath .. 'seraphim_expnuke_plume_fxtrails_05_emit.bp', 	-- -- plasma trail
    EmtBpPath .. 'seraphim_expnuke_plume_fxtrails_06_emit.bp', 	-- -- plasma trail darkening
    EmtBpPath .. 'seraphim_expnuke_plume_fxtrails_10_emit.bp', 	-- -- bright tip
    -- EmtBpPath .. '_align_x_emit.bp',
    -- EmtBpPath .. '_align_y_emit.bp',
    -- EmtBpPath .. '_align_z_emit.bp',
}

SIFExperimentalStrategicMissilePlumeFxTrails04 = {
    EmtBpPath .. 'seraphim_expnuke_plume_fxtrails_07_emit.bp', -- -- plasma cloud
    EmtBpPath .. 'seraphim_expnuke_plume_fxtrails_08_emit.bp', -- -- plasma cloud 2, ser 07
}

SIFExperimentalStrategicMissilePlumeFxTrails05 = {
    EmtBpPath .. 'seraphim_expnuke_plume_fxtrails_09_emit.bp', -- -- line detail in explosion, fingers.
}

SIFExperimentalStrategicMissilePolyTrails = {
    EmtBpPath .. 'seraphim_expnuke_polytrail_01_emit.bp',
    EmtBpPath .. 'seraphim_expnuke_polytrail_02_emit.bp',
    EmtBpPath .. 'seraphim_expnuke_polytrail_03_emit.bp',
}

SIFExperimentalStrategicMissileFXTrails = {
    EmtBpPath .. 'seraphim_expnuke_fxtrails_01_emit.bp',
    EmtBpPath .. 'seraphim_expnuke_fxtrails_02_emit.bp',
}

-- ------------------------------------------------------------------------
--  SERAPHIM ZHANASEE EMITTERS
-- ------------------------------------------------------------------------
SZhanaseeMuzzleFlash01 = {
    EmtBpPath .. 'seraphim_khamaseen_bomb_muzzle_flash_01_emit.bp',
}
SZhanaseeBombFxTrails01 = {
    EmtBpPath .. 'seraphim_khamaseen_bomb_fxtrails_01_emit.bp',
    EmtBpPath .. 'seraphim_khamaseen_bomb_fxtrails_02_emit.bp',
}
SZhanaseeBombHit01 = {
    EmtBpPath .. 'seraphim_khamaseen_bomb_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_khamaseen_bomb_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_khamaseen_bomb_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_khamaseen_bomb_hit_06_emit.bp',
    EmtBpPath .. 'seraphim_khamaseen_bomb_hit_08_emit.bp',
    EmtBpPath .. 'seraphim_khamaseen_bomb_hit_09_emit.bp',
    EmtBpPath .. 'seraphim_khamaseen_bomb_hit_10_emit.bp',
    EmtBpPath .. 'seraphim_khamaseen_bomb_hit_11_emit.bp',
    EmtBpPath .. 'seraphim_khamaseen_bomb_hit_12_emit.bp',
    EmtBpPath .. 'seraphim_khamaseen_bomb_hit_13_emit.bp',
    EmtBpPath .. 'seraphim_khamaseen_bomb_hit_14_emit.bp',
    EmtBpPath .. 'seraphim_khamaseen_bomb_hit_15_emit.bp',
    EmtBpPath .. 'seraphim_khamaseen_bomb_hit_16_emit.bp',
    EmtBpPath .. 'seraphim_khamaseen_bomb_hit_17_emit.bp',
    EmtBpPath .. 'seraphim_khamaseen_bomb_hit_18_emit.bp',
}
SZhanaseeBombHitSpiralFxTrails01 = {
    EmtBpPath .. 'seraphim_khamaseen_bombhitspiral_fxtrails_02_emit.bp',
    EmtBpPath .. 'seraphim_khamaseen_bombhitspiral_fxtrails_03_emit.bp',
    EmtBpPath .. 'seraphim_khamaseen_bombhitspiral_fxtrails_04_emit.bp',
}
SZhanaseeBombHitSpiralFxTrails02 = {
    EmtBpPath .. 'seraphim_khamaseen_bombhitspiral_fxtrails_01_emit.bp',
}

SZhanaseeBombHitSpiralFxPolyTrails = {
    EmtBpPath .. 'seraphim_khamaseen_bombhitspiral_polytrail_01_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM KHU ANTI-NUKE EMITTERS
-- ------------------------------------------------------------------------
SKhuAntiNukeMuzzleFlash = {
    EmtBpPath .. 'seraphim_khu_anti_nuke_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'seraphim_khu_anti_nuke_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_khu_anti_nuke_muzzle_flash_03_emit.bp',
}
SKhuAntiNukeFxTrails = {
    EmtBpPath .. 'seraphim_khu_anti_nuke_fxtrail_01_emit.bp',
    EmtBpPath .. 'seraphim_khu_anti_nuke_fxtrail_02_emit.bp',
    EmtBpPath .. 'seraphim_khu_anti_nuke_fxtrail_03_emit.bp',
}
SKhuAntiNukeHit= {
    EmtBpPath .. 'seraphim_khu_anti_nuke_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_khu_anti_nuke_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_khu_anti_nuke_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_khu_anti_nuke_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_khu_anti_nuke_hit_05_emit.bp',
    EmtBpPath .. 'seraphim_khu_anti_nuke_hit_06_emit.bp',
    EmtBpPath .. 'seraphim_khu_anti_nuke_hit_07_emit.bp',
    EmtBpPath .. 'seraphim_khu_anti_nuke_hit_08_emit.bp',
    EmtBpPath .. 'seraphim_khu_anti_nuke_hit_09_emit.bp',
}
SKhuAntiNukeHitTendrilFxTrails= {
    -- -- EmtBpPath .. 'seraphim_khu_anti_nuke_hit_tendril_fxtrail_01_emit.bp',
    EmtBpPath .. 'seraphim_khu_anti_nuke_hit_tendril_fxtrail_02_emit.bp',
    EmtBpPath .. 'seraphim_khu_anti_nuke_hit_tendril_fxtrail_04_emit.bp',
}
SKhuAntiNukeHitSmallTendrilFxTrails= {
    EmtBpPath .. 'seraphim_khu_anti_nuke_hit_small_tendril_fxtrail_01_emit.bp',
    EmtBpPath .. 'seraphim_khu_anti_nuke_hit_small_tendril_fxtrail_02_emit.bp',
}
SKhuAntiNukePolyTrail= EmtBpPath .. 'seraphim_khu_anti_nuke_polytrail_01_emit.bp'


-- ------------------------------------------------------------------------
--  SERAPHIM PHASIC AUTOGUN EMITTERS
-- ------------------------------------------------------------------------
PhasicAutoGunMuzzleFlash = {
    EmtBpPath .. 'seraphim_phasic_autogun_muzzle_flash_emit.bp',
    EmtBpPath .. 'seraphim_phasic_autogun_muzzle_flash_02_emit.bp',
}
PhasicAutoGunProjectileTrail = {
    EmtBpPath .. 'seraphim_phasic_autogun_projectile_emit.bp',
    EmtBpPath .. 'seraphim_phasic_autogun_projectile_02_emit.bp',
}
PhasicAutoGunHit = {
    EmtBpPath .. 'seraphim_phasic_autogun_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_phasic_autogun_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_phasic_autogun_projectile_hit_03_emit.bp',
}
PhasicAutoGunHitUnit = {
    EmtBpPath .. 'seraphim_phasic_autogun_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_phasic_autogun_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_phasic_autogun_projectile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_phasic_autogun_projectile_hitunit_01_emit.bp',
    EmtBpPath .. 'seraphim_phasic_autogun_projectile_hitunit_03_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM HEAVY PHASIC AUTOGUN EMITTERS
-- ------------------------------------------------------------------------
HeavyPhasicAutoGunMuzzleFlash = {
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_muzzle_flash_emit.bp',
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_muzzle_flash01_emit.bp',
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_muzzle_flash02_emit.bp',
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_muzzle_flash03_emit.bp',
}
HeavyPhasicAutoGunTankMuzzleFlash = {
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_muzzle_flash_emit.bp',
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_muzzle_flash04_emit.bp',
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_muzzle_flash05_emit.bp',
}
HeavyPhasicAutoGunProjectileTrail = {
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_projectile_polytrail_01_emit.bp',
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_projectile_polytrail_02_emit.bp',
}
HeavyPhasicAutoGunProjectileTrail02 = {
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_projectile_polytrail_01_emit.bp',
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_projectile_polytrail_03_emit.bp',
}
HeavyPhasicAutoGunProjectileTrailGlow = {
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_projectile_glow.bp',
}
HeavyPhasicAutoGunProjectileTrailGlow02 = {
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_projectile_glow_02.bp',
}
HeavyPhasicAutoGunHit = {
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_projectile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_projectile_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_projectile_hit_05_emit.bp',
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_projectile_hit_06_emit.bp',
}
HeavyPhasicAutoGunHitUnit = {
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_projectile_hitunit_01_emit.bp',
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_projectile_hitunit_02_emit.bp',
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_projectile_hitunit_03_emit.bp',
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_projectile_hitunit_04_emit.bp',
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_projectile_hitunit_05_emit.bp',
    EmtBpPath .. 'seraphim_heavy_phasic_autogun_projectile_hit_06_emit.bp',
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM OH SPECTRA CANNON EMITTERS
-- ------------------------------------------------------------------------
OhCannonMuzzleFlash = {
    EmtBpPath .. 'seraphim_spectra_cannon_muzzle_flash_emit.bp',
    EmtBpPath .. 'seraphim_spectra_cannon_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_spectra_cannon_muzzle_flash_03_emit.bp',
    EmtBpPath .. 'seraphim_spectra_cannon_muzzle_flash_04_emit.bp',
}
OhCannonProjectileTrail = {
    EmtBpPath .. 'seraphim_spectra_cannon_polytrail_01_emit.bp',
    EmtBpPath .. 'seraphim_spectra_cannon_polytrail_02_emit.bp',
}
OhCannonFxTrails = {
    EmtBpPath .. 'seraphim_spectra_cannon_fxtrail_01_emit.bp',
    -- EmtBpPath .. 'seraphim_spectra_cannon_projectile_emit.bp'
}
OhCannonHit =
{
    EmtBpPath .. 'seraphim_spectra_cannon_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_spectra_cannon_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_spectra_cannon_projectile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_spectra_cannon_projectile_hit_06_emit.bp',
}
OhCannonHitUnit =
{
    EmtBpPath .. 'seraphim_spectra_cannon_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_spectra_cannon_projectile_hit_02_emit.bp',
    -- EmtBpPath .. 'seraphim_spectra_cannon_projectile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_spectra_cannon_projectile_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_spectra_cannon_projectile_hit_05_emit.bp',
}


OhCannonProjectileTrail02 = {
    EmtBpPath .. 'seraphim_spectra_cannon_polytrail_03_emit.bp',
    EmtBpPath .. 'seraphim_spectra_cannon_polytrail_04_emit.bp',
    EmtBpPath .. 'default_polytrail_03_emit.bp',
}
OhCannonMuzzleFlash02 = {
    EmtBpPath .. 'seraphim_spectra_cannon_muzzle_flash_05_emit.bp',
    EmtBpPath .. 'seraphim_spectra_cannon_muzzle_flash_06_emit.bp',
    EmtBpPath .. 'seraphim_spectra_cannon_muzzle_flash_07_emit.bp',
    EmtBpPath .. 'seraphim_spectra_cannon_muzzle_flash_08_emit.bp',
}

-- ------------------------------------------------------------------------
--  SERAPHIM SHRIEKER EMITTERS
-- ------------------------------------------------------------------------
ShriekerCannonMuzzleFlash = {
    EmtBpPath .. 'seraphim_shrieker_cannon_muzzle_flash_emit.bp',
    EmtBpPath .. 'seraphim_shrieker_cannon_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_shrieker_cannon_muzzle_flash_03_emit.bp',
}
ShriekerCannonPolyTrail = {
    EmtBpPath .. 'seraphim_shrieker_cannon_projectile_polytrail_01_emit.bp',
    EmtBpPath .. 'seraphim_shrieker_cannon_projectile_polytrail_02_emit.bp',
    EmtBpPath .. 'seraphim_shrieker_cannon_projectile_polytrail_03_emit.bp',
}
ShriekerCannonProjectileTrail = EmtBpPath .. 'seraphim_shrieker_cannon_projectile_emit.bp'
ShriekerCannonFxTrails= {
    EmtBpPath .. 'seraphim_shrieker_cannon_projectile_fxtrail_01_emit.bp',
    EmtBpPath .. 'seraphim_shrieker_cannon_projectile_fxtrail_02_emit.bp',
}
ShriekerCannonHit = {
    EmtBpPath .. 'seraphim_shrieker_cannon_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_shrieker_cannon_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_shrieker_cannon_projectile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_shrieker_cannon_projectile_hit_04_emit.bp',
}
ShriekerCannonHitUnit = {
    EmtBpPath .. 'seraphim_shrieker_cannon_projectile_hitunit_01_emit.bp',
    EmtBpPath .. 'seraphim_shrieker_cannon_projectile_hitunit_02_emit.bp',
    EmtBpPath .. 'seraphim_shrieker_cannon_projectile_hitunit_03_emit.bp',
    EmtBpPath .. 'seraphim_shrieker_cannon_projectile_hitunit_04_emit.bp',
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM CHRONOTRON CANNON EMITTERS
-- ------------------------------------------------------------------------
SChronotronCannonMuzzleCharge = {
    EmtBpPath .. 'seraphim_chronotron_cannon_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_muzzle_flash_02_emit.bp',
}
SChronotronCannonMuzzle = {
    EmtBpPath .. 'seraphim_chronotron_cannon_muzzle_flash_03_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_muzzle_flash_04_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_muzzle_flash_05_emit.bp',
}
SChronotronCannonProjectileTrails = {
    EmtBpPath .. 'seraphim_chronotron_cannon_projectile_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_projectile_01_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_projectile_02_emit.bp',
}
SChronotronCannonProjectileFxTrails = {
    EmtBpPath .. 'seraphim_chronotron_cannon_projectile_fxtrail_01_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_projectile_fxtrail_02_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_projectile_fxtrail_03_emit.bp',
}
SChronotronCannonHit = {
    EmtBpPath .. 'seraphim_chronotron_cannon_projectile_hit_01_emit.bp',
    -- -- EmtBpPath .. 'seraphim_chronotron_cannon_projectile_hit_02_emit.bp',
}
SChronotronCannonLandHit = {
    EmtBpPath .. 'seraphim_chronotron_cannon_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_projectile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_projectile_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_projectile_hit_05_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_projectile_hit_06_emit.bp',
}
SChronotronCannonUnitHit = {
    EmtBpPath .. 'seraphim_chronotron_cannon_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_projectile_hit_02_emit.bp',
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
}
SChronotronCannonOverChargeMuzzle = {
    EmtBpPath .. 'seraphim_chronotron_cannon_overcharge_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_overcharge_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_overcharge_muzzle_flash_03_emit.bp',
}
SChronotronCannonOverChargeProjectileTrails = {
    EmtBpPath .. 'seraphim_chronotron_cannon_overcharge_projectile_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_overcharge_projectile_01_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_overcharge_projectile_02_emit.bp',
}
SChronotronCannonOverChargeProjectileFxTrails = {
    EmtBpPath .. 'seraphim_chronotron_cannon_overcharge_projectile_fxtrail_01_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_overcharge_projectile_fxtrail_02_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_overcharge_projectile_fxtrail_03_emit.bp',
}
SChronotronCannonOverChargeLandHit = {
    EmtBpPath .. 'seraphim_chronotron_cannon_overcharge_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_overcharge_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_overcharge_projectile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_overcharge_projectile_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_projectile_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_projectile_hit_05_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_projectile_hit_06_emit.bp',
}
SChronotronCannonOverChargeUnitHit = {
    EmtBpPath .. 'seraphim_chronotron_cannon_overcharge_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_overcharge_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_overcharge_projectile_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_projectile_hit_05_emit.bp',
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
}
SChronatronCannonBlastAttackAOE= {
    EmtBpPath .. 'seraphim_chronotron_cannon_blast_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_blast_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_chronotron_cannon_blast_projectile_hit_03_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM LIGHT CHRONOTRON EMITTERS
-- ------------------------------------------------------------------------
SLightChronotronCannonMuzzleFlash = {
    EmtBpPath.. 'seraphim_light_chronotron_cannon_muzzle_flash_01_emit.bp',
    -- -- -- EmtBpPath .. 'seraphim_light_chronotron_cannon_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_light_chronotron_cannon_muzzle_flash_03_emit.bp',
}
SLightChronotronCannonMuzzleFlash = {
    EmtBpPath .. 'seraphim_light_chronotron_cannon_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'seraphim_light_chronotron_cannon_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_light_chronotron_cannon_muzzle_flash_03_emit.bp',
}
SLightChronotronCannonProjectileTrails =
{
    EmtBpPath .. 'seraphim_light_chronotron_cannon_projectile_emit.bp',
}

SLightChronotronCannonProjectileFxTrails = {
    EmtBpPath .. 'seraphim_light_chronotron_cannon_projectile_fxtrail_01_emit.bp',
    EmtBpPath .. 'seraphim_light_chronotron_cannon_projectile_fxtrail_02_emit.bp',
}
SLightChronotronCannonHit = {
    EmtBpPath .. 'seraphim_light_chronotron_cannon_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_light_chronotron_cannon_projectile_hit_02_emit.bp',
}
SLightChronotronCannonUnitHit = {
    EmtBpPath .. 'seraphim_light_chronotron_cannon_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_light_chronotron_cannon_projectile_hit_02_emit.bp',
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
}
SLightChronotronCannonLandHit = {
    EmtBpPath .. 'seraphim_light_chronotron_cannon_projectile_hit_01_emit.bp',
    -- -- -- EmtBpPath .. 'seraphim_light_chronotron_cannon_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_light_chronotron_cannon_projectile_hit_03_emit.bp',
}
SLightChronotronCannonOverChargeMuzzleFlash = {
    EmtBpPath..  'seraphim_light_chronotron_cannon_overcharge_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'seraphim_light_chronotron_cannon_overcharge_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_light_chronotron_cannon_overcharge_muzzle_flash_03_emit.bp',
    EmtBpPath .. 'seraphim_light_chronotron_cannon_overcharge_muzzle_flash_04_emit.bp',
}
SLightChronotronCannonOverChargeProjectileTrails = {
    EmtBpPath .. 'seraphim_light_chronotron_cannon_overcharge_projectile_emit.bp',
    -- -- EmtBpPath .. 'seraphim_light_chronotron_cannon_overcharge_projectile_01_emit.bp',
    -- -- EmtBpPath .. 'seraphim_light_chronotron_cannon_overcharge_projectile_02_emit.bp',
}
SLightChronotronCannonOverChargeProjectileFxTrails = {
    EmtBpPath .. 'seraphim_light_chronotron_cannon_overcharge_projectile_fxtrail_01_emit.bp',
    EmtBpPath .. 'seraphim_light_chronotron_cannon_overcharge_projectile_fxtrail_02_emit.bp',
}
SLightChronotronCannonOverChargeHit = {

    EmtBpPath .. 'seraphim_light_chronotron_cannon_overcharge_projectile_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_light_chronotron_cannon_overcharge_projectile_hit_05_emit.bp',
    EmtBpPath .. 'seraphim_light_chronotron_cannon_overcharge_projectile_hit_06_emit.bp',
    EmtBpPath .. 'seraphim_light_chronotron_cannon_overcharge_projectile_hit_07_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM AIRE-AU BOLTER EMITTERS
-- ------------------------------------------------------------------------
SAireauBolterMuzzleFlash = {
    EmtBpPath .. 'seraphim_aero_bolter_muzzle_flash_emit.bp',
}
SAireauBolterMuzzleFlash02 = {
    EmtBpPath .. 'seraphim_aero_bolter_muzzle_flash_emit.bp',
    EmtBpPath .. 'seraphim_aero_bolter_muzzle_flash_02_emit.bp',
}
SAireauBolterProjectileFxTrails = {
    EmtBpPath .. 'seraphim_aero_bolter_projectile_fxtrail_01_emit.bp',
}
SAireauBolterProjectilePolyTrails = {
    EmtBpPath .. 'seraphim_aero_bolter_projectile_polytrail_01_emit.bp',
    EmtBpPath .. 'seraphim_aero_bolter_projectile_polytrail_02_emit.bp',
    EmtBpPath .. 'seraphim_aero_bolter_projectile_polytrail_03_emit.bp',
}
SAireauBolterHit = {
    EmtBpPath .. 'seraphim_aero_bolter_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_aero_bolter_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_aero_bolter_projectile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_aero_bolter_projectile_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_aero_bolter_projectile_hit_05_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM SHLEO EMITTERS
-- ------------------------------------------------------------------------
SShleoCannonMuzzleFlash = {
    EmtBpPath .. 'seraphim_cleo_cannon_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'seraphim_cleo_cannon_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_cleo_cannon_muzzle_flash_03_emit.bp',
}
SShleoCannonProjectileTrails = {
    EmtBpPath .. 'seraphim_cleo_cannon_projectile_01_emit.bp',
    -- EmtBpPath .. 'seraphim_cleo_cannon_projectile_02_emit.bp',
}
SShleoCannonProjectilePolyTrails = {
    {
        EmtBpPath .. 'seraphim_cleo_cannon_projectile_polytrail_01_emit.bp',
        EmtBpPath .. 'seraphim_cleo_cannon_projectile_polytrail_02_emit.bp',
    },
    {
        EmtBpPath .. 'seraphim_cleo_cannon_projectile_polytrail_03_emit.bp',
        EmtBpPath .. 'seraphim_cleo_cannon_projectile_polytrail_04_emit.bp',
    },
    {
        EmtBpPath .. 'seraphim_cleo_cannon_projectile_polytrail_05_emit.bp',
        EmtBpPath .. 'seraphim_cleo_cannon_projectile_polytrail_06_emit.bp',
    },

}
SShleoCannonHit = {
    -- EmtBpPath .. 'seraphim_cleo_cannon_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_cleo_cannon_projectile_hit_07_emit.bp',
    EmtBpPath .. 'seraphim_cleo_cannon_projectile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_cleo_cannon_projectile_hit_08_emit.bp',
}
SShleoCannonUnitHit = {
    -- EmtBpPath .. 'seraphim_cleo_cannon_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_cleo_cannon_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_cleo_cannon_projectile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_cleo_cannon_projectile_hit_06_emit.bp',
    EmtBpPath .. 'seraphim_cleo_cannon_projectile_hit_08_emit.bp',
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
}
SShleoCannonLandHit = {
    EmtBpPath .. 'seraphim_cleo_cannon_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_cleo_cannon_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_cleo_cannon_projectile_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_cleo_cannon_projectile_hit_05_emit.bp',
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM THUNDERSTORM CANNON EMITTERS
-- ------------------------------------------------------------------------
SThunderStormCannonMuzzleFlash= {
    EmtBpPath .. 'seraphim_thunderstorm_artillery_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'seraphim_thunderstorm_artillery_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_thunderstorm_artillery_muzzle_flash_03_emit.bp',
}

SThunderStormCannonProjectileTrails = {
    EmtBpPath .. 'seraphim_thunderstorm_artillery_projectile_02_emit.bp',
}



SThunderStormCannonProjectileSplitFx = {
    EmtBpPath .. 'seraphim_thunderstorm_artillery_projectile_split_01_emit.bp',
}

SThunderStormCannonProjectilePolyTrails = {
    EmtBpPath .. 'seraphim_thunderstorm_artillery_projectile_trail_01_emit.bp',
    EmtBpPath .. 'default_polytrail_01_emit.bp',
}


-- SThunderStormCannonLightningProjectileTrails = {
-- 	EmtBpPath .. 'seraphim_thunderstorm_artillery_projectile_03_emit.bp',
-- 	EmtBpPath .. 'seraphim_thunderstorm_artillery_projectile_04_emit.bp',
-- }

SThunderStormCannonLightningProjectilePolyTrail = EmtBpPath .. 'seraphim_thunderstorm_artillery_projectile_trail_02_emit.bp'

SThunderStormCannonHit = {
    EmtBpPath .. 'seraphim_thunderstorm_artillery_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_thunderstorm_artillery_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_thunderstorm_artillery_projectile_hit_03_emit.bp',
}

SThunderStormCannonUnitHit = {
    EmtBpPath .. 'seraphim_thunderstorm_artillery_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_thunderstorm_artillery_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_thunderstorm_artillery_projectile_hit_03_emit.bp',
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
}

SThunderStormCannonLandHit = {
    EmtBpPath .. 'seraphim_thunderstorm_artillery_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_thunderstorm_artillery_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_thunderstorm_artillery_projectile_hit_03_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM RIFTER ARTILLERY EMITTERS
-- ------------------------------------------------------------------------
SRifterArtilleryProjectileFxTrails= {
    EmtBpPath .. 'seraphim_rifter_artillery_projectile_fxtrails_01_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_projectile_fxtrails_02_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_projectile_fxtrails_03_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_projectile_fxtrails_04_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_projectile_fxtrails_05_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_projectile_fxtrails_06_emit.bp',
}

SRifterArtilleryProjectilePolyTrail= EmtBpPath .. 'seraphim_rifter_mobileartillery_polytrail_01_emit.bp'

SRifterArtilleryHit= {
    EmtBpPath .. 'seraphim_rifter_artillery_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_hit_05_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_hit_06_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_hit_07_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_hit_08_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_hit_09_emit.bp',
}

SRifterArtilleryWaterHit= {
    EmtBpPath .. 'seraphim_rifter_artillery_hit_01w_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_hit_02w_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_hit_03w_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_hit_05w_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_hit_06w_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_hit_07_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_hit_08w_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_hit_09_emit.bp',
}

SRifterArtilleryMuzzleFlash= {
    EmtBpPath .. 'seraphim_rifter_artillery_muzzle_01_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_muzzle_02_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_muzzle_05_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_muzzle_06_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_muzzle_07_emit.bp',
}

SRifterArtilleryChargeMuzzleFlash= {
    EmtBpPath .. 'seraphim_rifter_artillery_muzzle_03_emit.bp',
    EmtBpPath .. 'seraphim_rifter_artillery_muzzle_04_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM MOBILE RIFTER ARTILLERY EMITTERS
-- ------------------------------------------------------------------------
SRifterMobileArtilleryProjectileFxTrails= {
    -- EmtBpPath .. 'seraphim_rifter_mobileartillery_projectile_fxtrails_01_emit.bp',
    EmtBpPath .. 'seraphim_rifter_mobileartillery_projectile_fxtrails_02_emit.bp',
    -- EmtBpPath .. 'seraphim_rifter_mobileartillery_projectile_fxtrails_03_emit.bp',
    -- EmtBpPath .. 'seraphim_rifter_mobileartillery_projectile_fxtrails_04_emit.bp',
    EmtBpPath .. 'seraphim_rifter_mobileartillery_projectile_fxtrails_05_emit.bp',
    EmtBpPath .. 'seraphim_rifter_mobileartillery_projectile_fxtrails_06_emit.bp',
}

SRifterMobileArtilleryHit= {
    EmtBpPath .. 'seraphim_rifter_mobileartillery_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_rifter_mobileartillery_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_rifter_mobileartillery_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_rifter_mobileartillery_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_rifter_mobileartillery_hit_05_emit.bp',
    EmtBpPath .. 'seraphim_rifter_mobileartillery_hit_06_emit.bp',
    EmtBpPath .. 'seraphim_rifter_mobileartillery_hit_07_emit.bp',
    EmtBpPath .. 'seraphim_rifter_mobileartillery_hit_08_emit.bp',
}

SRifterMobileArtilleryWaterHit= {
    EmtBpPath .. 'seraphim_rifter_mobileartillery_hit_01w_emit.bp',
    EmtBpPath .. 'seraphim_rifter_mobileartillery_hit_02w_emit.bp',
    EmtBpPath .. 'seraphim_rifter_mobileartillery_hit_03w_emit.bp',
    EmtBpPath .. 'seraphim_rifter_mobileartillery_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_rifter_mobileartillery_hit_05w_emit.bp',
    EmtBpPath .. 'seraphim_rifter_mobileartillery_hit_06w_emit.bp',
    EmtBpPath .. 'seraphim_rifter_mobileartillery_hit_07_emit.bp',
    EmtBpPath .. 'seraphim_rifter_mobileartillery_hit_08w_emit.bp',
}

SRifterMobileArtilleryChargeMuzzleFlash= {
    EmtBpPath .. 'seraphim_rifter_mobileartillery_muzzle_01_emit.bp',
    EmtBpPath .. 'seraphim_rifter_mobileartillery_muzzle_02_emit.bp',
}

SRifterMobileArtilleryMuzzleFlash= {
    EmtBpPath .. 'seraphim_rifter_mobileartillery_muzzle_03_emit.bp',
    EmtBpPath .. 'seraphim_rifter_mobileartillery_muzzle_04_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM ZTHUTHAAM ARTILLERY EMITTERS
-- ------------------------------------------------------------------------
SZthuthaamArtilleryProjectilePolyTrails= {
    EmtBpPath .. 'seraphim_reviler_artillery_projectile_polytrail_emit.bp',
    EmtBpPath .. 'seraphim_reviler_artillery_projectile_polytrail_02_emit.bp',
}
SZthuthaamArtilleryProjectileFXTrails= {
    EmtBpPath .. 'seraphim_reviler_artillery_projectile_fxtrail_emit.bp',
}
SZthuthaamArtilleryHit= {
    EmtBpPath .. 'seraphim_reviler_artillery_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_reviler_artillery_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_reviler_artillery_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_reviler_artillery_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_reviler_artillery_hit_05_emit.bp',
    EmtBpPath .. 'seraphim_reviler_artillery_hit_07_emit.bp',
    EmtBpPath .. 'seraphim_reviler_artillery_hit_08_emit.bp',
    EmtBpPath .. 'seraphim_reviler_artillery_hit_09_emit.bp',
}
SZthuthaamArtilleryHit02= {
    EmtBpPath .. 'seraphim_reviler_artillery_hit_06_emit.bp',
}
SZthuthaamArtilleryUnitHit = table.concatenate(SZthuthaamArtilleryHit, UnitHitShrapnel01, SZthuthaamArtilleryHit02)
SZthuthaamArtilleryMuzzleFlash= {
    EmtBpPath .. 'seraphim_reviler_artillery_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'seraphim_reviler_artillery_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_reviler_artillery_muzzle_flash_05_emit.bp',
    EmtBpPath .. 'seraphim_reviler_artillery_muzzle_flash_07_emit.bp',
}
SZthuthaamArtilleryChargeMuzzleFlash= {
    EmtBpPath .. 'seraphim_reviler_artillery_muzzle_flash_03_emit.bp',
    EmtBpPath .. 'seraphim_reviler_artillery_muzzle_flash_04_emit.bp',
    EmtBpPath .. 'seraphim_reviler_artillery_muzzle_flash_06_emit.bp',
}

-- ------------------------------------------------------------------------
--  SERAPHIM TAU CANNON EMITTERS
-- ------------------------------------------------------------------------
STauCannonMuzzleFlash= {
    EmtBpPath .. 'seraphim_tau_cannon_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'seraphim_tau_cannon_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_tau_cannon_muzzle_flash_03_emit.bp',
    EmtBpPath .. 'seraphim_tau_cannon_muzzle_flash_10_emit.bp',
    EmtBpPath .. 'seraphim_tau_cannon_muzzle_flash_11_emit.bp',
}

STauCannonProjectileTrails = {
    EmtBpPath .. 'seraphim_tau_cannon_projectile_01_emit.bp',
    EmtBpPath .. 'seraphim_tau_cannon_projectile_02_emit.bp',
    EmtBpPath .. 'seraphim_tau_cannon_projectile_03_emit.bp',
}

STauCannonProjectilePolyTrails = {
    EmtBpPath .. 'seraphim_tau_cannon_projectile_polytrail_01_emit.bp',
    EmtBpPath .. 'seraphim_tau_cannon_projectile_polytrail_02_emit.bp',
}

STauCannonHit = {
    EmtBpPath .. 'seraphim_tau_cannon_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_tau_cannon_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_tau_cannon_projectile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_tau_cannon_projectile_hit_03_flat_emit.bp',
    EmtBpPath .. 'seraphim_tau_cannon_projectile_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_tau_cannon_projectile_hit_05_emit.bp',
    EmtBpPath .. 'seraphim_tau_cannon_projectile_hit_06_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM HEAVY QUARNON EMITTERS
-- ------------------------------------------------------------------------
SHeavyQuarnonCannonMuzzleFlash= {
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_muzzle_flash_03_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_muzzle_flash_04_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_muzzle_flash_05_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_frontal_glow_01_emit.bp',
}

SHeavyQuarnonCannonProjectileTrails = {
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_01_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_02_emit.bp',
}

SHeavyQuarnonCannonProjectileFxTrails = {
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_fxtrail_01_emit1.bp',
}

SHeavyQuarnonCannonProjectilePolyTrails = {
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_trail_01_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_trail_02_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_trail_03_emit.bp',
}

SHeavyQuarnonCannonHit = {
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_hit_02_emit.bp',
}

SHeavyQuarnonCannonUnitHit = {
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_hit_05_emit.bp',
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
}

SHeavyQuarnonCannonLandHit = {
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_surface_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_hit_05_emit.bp',
}

SHeavyQuarnonCannonWaterHit = {
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_surface_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_surface_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_hit_05_emit.bp',
    EmtBpPath .. 'seraphim_heavyquarnon_cannon_projectile_surface_hit_03_emit.bp',
}

-- ------------------------------------------------------------------------
--  SERAPHIM LOSAARE AUTOCANNON EMITTERS
-- ------------------------------------------------------------------------
SLosaareAutoCannonMuzzleFlash = {
    EmtBpPath .. 'seraphim_losaare_cannon_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'seraphim_losaare_cannon_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_losaare_cannon_muzzle_flash_03_emit.bp',
}

SLosaareAutoCannonMuzzleFlashAirUnit = {
    EmtBpPath .. 'seraphim_losaare_cannon_muzzle_flash_04_emit.bp',
    EmtBpPath .. 'seraphim_losaare_cannon_muzzle_flash_05_emit.bp',
}

SLosaareAutoCannonMuzzleFlashSeaUnit = {
    EmtBpPath .. 'seraphim_losaare_cannon_muzzle_flash_06_emit.bp',
    EmtBpPath .. 'seraphim_losaare_cannon_muzzle_flash_07_emit.bp',
    EmtBpPath .. 'seraphim_losaare_cannon_muzzle_flash_08_emit.bp',
}

SLosaareAutoCannonProjectileTrail = {
    EmtBpPath .. 'seraphim_losaare_cannon_projectile_emit.bp',
    EmtBpPath .. 'seraphim_losaare_cannon_projectile_emit_02.bp',
}

SLosaareAutoCannonProjectileTrail02 = {
    EmtBpPath .. 'seraphim_losaare_cannon_projectile_emit_03.bp',
    EmtBpPath .. 'seraphim_losaare_cannon_projectile_emit_04.bp',
}

SLosaareAutoCannonHit = {
    EmtBpPath .. 'seraphim_losaare_cannon_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_losaare_cannon_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_losaare_cannon_projectile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_losaare_cannon_projectile_hit_04_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM OLARIS CANNON EMITTERS
-- ------------------------------------------------------------------------
SOlarisCannonMuzzleCharge = {
    EmtBpPath .. 'seraphim_polarix_cannon_muzzle_charge_01_emit.bp',
}

SOlarisCannonMuzzleFlash01 = {
    EmtBpPath .. 'seraphim_polarix_cannon_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'seraphim_polarix_cannon_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_polarix_cannon_muzzle_flash_03_emit.bp',
    EmtBpPath .. 'seraphim_polarix_cannon_muzzle_flash_04_emit.bp',
    EmtBpPath .. 'seraphim_polarix_cannon_muzzle_flash_05_emit.bp',
}

SOlarisCannonTrails = {
    -- EmtBpPath .. 'seraphim_polarix_cannon_trails_01_emit.bp',
    EmtBpPath .. 'seraphim_polarix_cannon_trails_02_emit.bp',
    EmtBpPath .. 'seraphim_polarix_cannon_trails_03_emit.bp',
    EmtBpPath .. 'seraphim_polarix_cannon_trails_04_emit.bp',
}

SOlarisCannonProjectilePolyTrail = {
    EmtBpPath .. 'seraphim_polarix_cannon_projectile_emit.bp',
    EmtBpPath .. 'seraphim_polarix_cannon_projectile_02_emit.bp',
}

SOlarisCannonHit = {
    EmtBpPath .. 'seraphim_polarix_cannon_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_polarix_cannon_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_polarix_cannon_projectile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_polarix_cannon_projectile_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_polarix_cannon_projectile_hit_05_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM EXPERIMENTAL UNSTABLE PHASON BEAM EMITTERS
-- ------------------------------------------------------------------------
SExperimentalUnstablePhasonLaserMuzzle01 = {
    EmtBpPath .. 'seraphim_expirimental_laser_charge_01_emit.bp',
    EmtBpPath .. 'seraphim_expirimental_laser_charge_01_emit.bp',
}

SChargeExperimentalUnstablePhasonLaser = {
    EmtBpPath .. 'seraphim_expirimental_unstable_laser_charge_01_emit.bp',
    EmtBpPath .. 'seraphim_expirimental_unstable_laser_charge_02_emit.bp',
}

SExperimentalUnstablePhasonLaserHitLand = {
    EmtBpPath .. 'seraphim_expirimental_unstable_laser_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_expirimental_unstable_laser_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_expirimental_unstable_laser_hit_03_emit.bp',
}

SExperimentalUnstablePhasonLaserFxTrails = {
    EmtBpPath .. 'seraphim_expirimental_unstable_laser_fxtrail_01_emit.bp',
    EmtBpPath .. 'seraphim_expirimental_unstable_laser_fxtrail_02_emit.bp',
}

SExperimentalUnstablePhasonLaserPolyTrail = EmtBpPath .. 'seraphim_expirimental_unstable_laser_trail_emit.bp'

SExperimentalUnstablePhasonLaserBeam = {
    EmtBpPath .. 'seraphim_expirimental_unstable_laser_beam_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM EXPERIMENTAL PHASON LASER EMITTERS
-- ------------------------------------------------------------------------
SExperimentalPhasonLaserMuzzle01 =
{
    EmtBpPath .. 'seraphim_expirimental_laser_muzzle_01_emit.bp',
    EmtBpPath .. 'seraphim_expirimental_laser_muzzle_02_emit.bp',
    EmtBpPath .. 'seraphim_expirimental_laser_muzzle_03_emit.bp',
    EmtBpPath .. 'seraphim_expirimental_laser_muzzle_04_emit.bp',
    EmtBpPath .. 'phason_laser_muzzle_01_emit.bp',

}

SChargeExperimentalPhasonLaser = {
    EmtBpPath .. 'seraphim_expirimental_laser_charge_01_emit.bp',
    EmtBpPath .. 'seraphim_expirimental_laser_charge_02_emit.bp',
}

SExperimentalPhasonLaserHitLand = {
    EmtBpPath .. 'seraphim_expirimental_laser_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_expirimental_laser_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_expirimental_laser_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_expirimental_laser_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_expirimental_laser_hit_05_emit.bp',
    EmtBpPath .. 'seraphim_expirimental_laser_hit_06_emit.bp',
    EmtBpPath .. 'seraphim_expirimental_laser_hit_07_emit.bp',
}


SExperimentalPhasonLaserFxTrails = {
    EmtBpPath .. 'seraphim_expirimental_laser_fxtrail_01_emit.bp',
    EmtBpPath .. 'seraphim_expirimental_laser_fxtrail_02_emit.bp',
}

SExperimentalPhasonLaserPolyTrail = EmtBpPath .. 'seraphim_expirimental_laser_trail_emit.bp'


SExperimentalPhasonLaserBeam = {
    EmtBpPath .. 'seraphim_expirimental_laser_beam_emit.bp',
    -- EmtBpPath .. 'seraphim_expirimental_laser_beam_02_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM ULTRACHROMATIC BEAM GENERATOR EMITTERS
-- ------------------------------------------------------------------------
SUltraChromaticBeamGeneratorMuzzle01 =
{
    EmtBpPath .. 'seraphim_chromatic_beam_generator_muzzle_01_emit.bp',
    EmtBpPath .. 'seraphim_chromatic_beam_generator_muzzle_02_emit.bp',
    EmtBpPath .. 'seraphim_chromatic_beam_generator_muzzle_03_emit.bp',
    EmtBpPath .. 'seraphim_chromatic_beam_generator_muzzle_04_emit.bp',
    EmtBpPath .. 'seraphim_chromatic_beam_generator_muzzle_06_emit.bp',
}

SUltraChromaticBeamGeneratorMuzzle02 =
{
    EmtBpPath .. 'seraphim_chromatic_beam_generator_muzzle_01_emit.bp',
    EmtBpPath .. 'seraphim_chromatic_beam_generator_muzzle_05_emit.bp',
}

SChargeUltraChromaticBeamGenerator = {
    EmtBpPath .. 'seraphim_chromatic_beam_generator_charge_01_emit.bp',
    EmtBpPath .. 'seraphim_chromatic_beam_generator_charge_02_emit.bp',
}

SUltraChromaticBeamGeneratorHitLand = {
    EmtBpPath .. 'seraphim_chromatic_beam_generator_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_chromatic_beam_generator_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_chromatic_beam_generator_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_chromatic_beam_generator_hit_05_emit.bp',
}

SUltraChromaticBeamGeneratorFxTrails = {
    EmtBpPath .. 'seraphim_chromatic_beam_generator_fxtrail_01_emit.bp',
    EmtBpPath .. 'seraphim_chromatic_beam_generator_fxtrail_02_emit.bp',
}

SUltraChromaticBeamGeneratorPolyTrail = EmtBpPath .. 'seraphim_chromatic_beam_generator_trail_emit.bp'

SUltraChromaticBeamGeneratorBeam = {
    EmtBpPath .. 'seraphim_chromatic_beam_generator_beam_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM LAANSE MISSILE EMITTERS
-- ------------------------------------------------------------------------
SLaanseMissleMuzzleFlash = {
    EmtBpPath .. 'seraphim_lancer_missile_launch_01_emit.bp',
    EmtBpPath .. 'seraphim_lancer_missile_launch_02_emit.bp',
}

SLaanseMissleExhaust01 = EmtBpPath .. 'seraphim_lancer_missile_exhaust_polytrail_01.bp'

SLaanseMissleExhaust02 = {
    EmtBpPath .. 'seraphim_lancer_missile_exhaust_fxtrail_01_emit.bp',
}

SLaanseMissleHit = {
    EmtBpPath .. 'seraphim_lancer_missile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_lancer_missile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_lancer_missile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_lancer_missile_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_lancer_missile_hit_05_emit.bp',
    EmtBpPath .. 'seraphim_lancer_missile_hit_06_emit.bp',
}

SLaanseMissleHitNone = {
    EmtBpPath .. 'seraphim_lancer_missile_hit_01_emit.bp', -- little flash effect
    EmtBpPath .. 'seraphim_lancer_missile_hit_02_none_emit.bp', -- inner white ring
    EmtBpPath .. 'seraphim_lancer_missile_hit_03_none_emit.bp', -- inner white ring
    EmtBpPath .. 'seraphim_lancer_missile_hit_05_emit.bp', -- smoke
}

SLaanseMissleHitWater = {
    EmtBpPath .. 'seraphim_lancer_missile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_lancer_missile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_lancer_missile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_lancer_missile_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_lancer_missile_hit_05_emit.bp',
    EmtBpPath .. 'seraphim_lancer_missile_hit_06_emit.bp',
    EmtBpPath .. 'Watertower_tactical.bp',
    EmtBpPath .. 'water_pie_tactical.bp',
    EmtBpPath .. 'Watersplash_tactical.bp',
}

SLaanseMissleHitUnit = {
    EmtBpPath .. 'seraphim_lancer_missile_hit_01_unit.bp', -- little flash effect
    EmtBpPath .. 'seraphim_lancer_missile_hit_02_unit.bp', -- inner white ring
    EmtBpPath .. 'seraphim_lancer_missile_hit_02_flat_unit.bp', -- inner white ring
    EmtBpPath .. 'seraphim_lancer_missile_hit_04_unit.bp', -- black lines
    EmtBpPath .. 'seraphim_lancer_missile_hit_05_unit.bp', -- smoke
    EmtBpPath .. 'seraphim_lancer_missile_hit_06_emit.bp', -- outer black ring
}


-- ------------------------------------------------------------------------
--  SERAPHIM EXPERIMENTAL STRATEGIC MISSILE EMITTERS
-- ------------------------------------------------------------------------
SExperimentalStrategicMissileMuzzleFlash = {
    EmtBpPath .. 'seraphim_experimental_missile_launch_01_emit.bp',
}

SExperimentalStrategicMissileExhaust01 = EmtBpPath .. 'seraphim_experimental_missile_exhaust_beam_01_emit.bp'

SExperimentalStrategicMissleExhaust02 = {
    EmtBpPath .. 'seraphim_experimental_missile_exhaust_fxtrail_01_emit.bp',
}

SExperimentalStrategicMissileHit = {
    EmtBpPath .. 'seraphim_experimental_missile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_experimental_missile_hit_02_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM ELECTRUM EMITTERS
-- ------------------------------------------------------------------------
SElectrumMissleDefenseMuzzleFlash = {
    EmtBpPath .. 'seraphim_electrum_missile_defense_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'seraphim_electrum_missile_defense_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_electrum_missile_defense_muzzle_flash_03_emit.bp',
}

SElectrumMissleDefenseProjectilePolyTrail = {
    EmtBpPath .. 'seraphim_electrum_missile_defense_projectile_emit.bp',
    EmtBpPath .. 'seraphim_electrum_missile_defense_projectile_emit_02.bp',
}

SElectrumMissleDefenseHit = {
    EmtBpPath .. 'seraphim_electrum_missile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_electrum_missile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_electrum_missile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_electrum_missile_hit_04_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM SUALL TORPEDO EMITTERS
-- ------------------------------------------------------------------------
SUallTorpedoMuzzleFlash= {
    EmtBpPath .. 'seraphim_uall_torpedo_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'seraphim_uall_torpedo_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_uall_torpedo_muzzle_flash_03_emit.bp',
}

SUallTorpedoFxTrails = {
    EmtBpPath .. 'seraphim_uall_torpedo_projectile_fxtrail_01_emit.bp',
    EmtBpPath .. 'seraphim_uall_torpedo_projectile_fxtrail_02_emit.bp',
    EmtBpPath .. 'seraphim_uall_torpedo_projectile_fxtrail_03_emit.bp',
}

SUallTorpedoPolyTrail = EmtBpPath .. 'seraphim_uall_torpedo_projectile_polytrail_01_emit.bp'

SUallTorpedoHit = {
    EmtBpPath .. 'seraphim_uall_torpedo_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_uall_torpedo_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_uall_torpedo_projectile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_uall_torpedo_projectile_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_uall_torpedo_projectile_hit_05_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM ANA-IT TORPEDO EMITTERS
-- ------------------------------------------------------------------------
SAnaitTorpedoMuzzleFlash= {
    EmtBpPath .. 'seraphim_ammit_torpedo_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'seraphim_ammit_torpedo_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_ammit_torpedo_muzzle_flash_03_emit.bp',
}

SAnaitTorpedoFxTrails = {
    EmtBpPath .. 'seraphim_ammit_torpedo_projectile_fxtrail_01_emit.bp',
}

SAnaitTorpedoPolyTrails = {
    EmtBpPath .. 'seraphim_ammit_torpedo_projectile_polytrail_01_emit.bp',
    EmtBpPath .. 'seraphim_ammit_torpedo_projectile_polytrail_02_emit.bp',
}

SAnaitTorpedoHit = {
    EmtBpPath .. 'seraphim_ammit_torpedo_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_ammit_torpedo_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_ammit_torpedo_projectile_hit_03_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM HEAVY CAVITATION TORPEDO EMITTERS
-- ------------------------------------------------------------------------
SHeavyCavitationTorpedoMuzzleFlash = {
    EmtBpPath .. 'seraphim_heayvcavitation_torpedo_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'seraphim_heayvcavitation_torpedo_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'seraphim_heayvcavitation_torpedo_muzzle_flash_03_emit.bp',
}

SHeavyCavitationTorpedoMuzzleFlash02 = {
    EmtBpPath .. 'seraphim_heayvcavitation_torpedo_muzzle_flash_04_emit.bp',
}

SHeavyCavitationTorpedoFxTrails = EmtBpPath .. 'seraphim_heayvcavitation_torpedo_projectile_fxtrail_01_emit.bp'
SHeavyCavitationTorpedoFxTrails02 = EmtBpPath .. 'seraphim_heayvcavitation_torpedo_projectile_fxtrail_02_emit.bp'


SHeavyCavitationTorpedoPolyTrails = {
    EmtBpPath .. 'seraphim_heayvcavitation_torpedo_projectile_polytrail_01_emit.bp',
    EmtBpPath .. 'seraphim_heayvcavitation_torpedo_projectile_polytrail_02_emit.bp',
}

SHeavyCavitationTorpedoHit = {
    EmtBpPath .. 'seraphim_heayvcavitation_torpedo_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_heayvcavitation_torpedo_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_heayvcavitation_torpedo_projectile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_heayvcavitation_torpedo_projectile_hit_04_emit.bp',
    EmtBpPath .. 'seraphim_heayvcavitation_torpedo_projectile_hit_05_emit.bp',
}

SHeavyCavitationTorpedoSplit = {
    EmtBpPath .. 'seraphim_ajellu_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_ajellu_hit_04_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM OTHE BOMB EMITTERS
-- ------------------------------------------------------------------------
SOtheBombMuzzleFlash= {
    EmtBpPath .. 'seraphim_othe_bomb_muzzle_flash_01_emit.bp',
}

SOtheBombFxTrails = {
    EmtBpPath .. 'seraphim_othe_bomb_projectile_fxtrail_01_emit.bp',
    EmtBpPath .. 'seraphim_othe_bomb_projectile_fxtrail_02_emit.bp',
}

SOtheBombPolyTrail = EmtBpPath .. 'seraphim_othe_bomb_projectile_polytrail_01_emit.bp'

SOtheBombHit = {
    EmtBpPath .. 'seraphim_othe_bomb_projectile_hit_01_flat_emit.bp',
    EmtBpPath .. 'seraphim_othe_bomb_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_othe_bomb_projectile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_othe_bomb_projectile_hit_04_emit.bp',
}

SOtheBombHitUnit = {
    EmtBpPath .. 'seraphim_othe_bomb_projectile_hit_01_flat_emit.bp',
    EmtBpPath .. 'seraphim_othe_bomb_projectile_hit_01_emit.bp',
    EmtBpPath .. 'seraphim_othe_bomb_projectile_hit_02_emit.bp',
    EmtBpPath .. 'seraphim_othe_bomb_projectile_hit_03_emit.bp',
    EmtBpPath .. 'seraphim_othe_bomb_projectile_hit_04_emit.bp',
}


-- ------------------------------------------------------------------------
--  SERAPHIM OHWALLI BOMB EMITTERS
-- ------------------------------------------------------------------------
SOhwalliBombMuzzleFlash01 = {
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_muzzle_flash_01_emit.bp',
}
SOhwalliBombFxTrails01 = {
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_fxtrails_01_emit.bp',
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_fxtrails_02_emit.bp',
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_fxtrails_03_emit.bp',
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_fxtrails_04_emit.bp',
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_fxtrails_05_emit.bp',
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_fxtrails_06_emit.bp',
}
SOhwalliBombPolyTrails = {
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_polytrails_01_emit.bp',
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_polytrails_02_emit.bp',
}
SOhwalliBombHit01 = {
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_hit_01_emit.bp', 	-- -- ring
    -- EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_hit_02_emit.bp', 	-- -- lines
    -- EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_hit_03_emit.bp', 	-- -- fast flash
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_hit_04_emit.bp', 	-- -- spiky center
    -- EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_hit_06_emit.bp', 	-- -- little dots
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_hit_07_emit.bp', 	-- -- long glow
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_hit_08_emit.bp', 	-- -- blue ser7
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_hit_09_emit.bp', 	-- -- darkening
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_hit_10_emit.bp', 	-- -- white cloud
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_hit_11_emit.bp', 	-- -- distortion
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_hit_12_emit.bp', 	-- -- inward lines
}
SOhwalliBombHit02 = {
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_hit_03_emit.bp', 	-- -- fast flash
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_hit_14_emit.bp', 	-- -- long glow
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_hit_13_emit.bp', 	-- -- faint plasma, ser7
}
SOhwalliDetonate01 = {
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_explode_01_emit.bp', 	-- -- glow
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_explode_02_emit.bp', 	-- -- upwards plasma tall
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_explode_03_emit.bp', 	-- -- upwards plasma short/wide
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_explode_04_emit.bp', 	-- -- upwards plasma top column, thin/tall
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_explode_05_emit.bp', 	-- -- upwards lines
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_concussion_01_emit.bp', -- -- ring
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_concussion_02_emit.bp', -- -- smaller/slower ring bursts
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_hit_03_emit.bp', 	-- -- fast flash
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_hit_14_emit.bp', 	-- -- long glow
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_hit_13_emit.bp', 	-- -- faint plasma, ser7
}
SOhwalliBombHitSpiralFxTrails02 = {
    EmtBpPath .. 'seraphim_ohwalli_strategic_bombhitspiral_fxtrails_01_emit.bp', -- -- upwards nuke cloud
    EmtBpPath .. 'seraphim_ohwalli_strategic_bombhitspiral_fxtrails_02_emit.bp', -- -- upwards nuke cloud highlights
}
SOhwalliBombHitRingProjectileFxTrails03 = {
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_ring_fxtrails_01_emit.bp', -- Rift Trail head
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_ring_fxtrails_01a_emit.bp', -- Center darkening
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_ring_fxtrails_01b_emit.bp',   -- Right rift edge
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_ring_fxtrails_01c_emit.bp', -- Left rift edge
    -- EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_ring_fxtrails_01d_emit.bp',   -- Right rift lines
}
SOhwalliBombHitRingProjectileFxTrails04 = {
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_ring_fxtrails_02_emit.bp',    -- Rift Trail head
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_ring_fxtrails_02a_emit.bp', -- Center darkening
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_ring_fxtrails_02b_emit.bp',   -- Right rift edge
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_ring_fxtrails_02c_emit.bp',   -- Left rift edge
}
SOhwalliBombHitRingProjectileFxTrails05 = {
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_ring_fxtrails_03_emit.bp',    -- Rift Trail head
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_ring_fxtrails_03a_emit.bp',   -- Center darkening
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_ring_fxtrails_03b_emit.bp', -- Right rift edge
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_ring_fxtrails_03c_emit.bp',   -- Left rift edge
}
SOhwalliBombHitRingProjectileFxTrails06 = {
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_ring_fxtrails_04_emit.bp',
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_ring_fxtrails_06_emit.bp',
}
SOhwalliBombPlumeFxTrails01 = {
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_plume_fxtrails_01_emit.bp',
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_plume_fxtrails_02_emit.bp',
    EmtBpPath .. 'seraphim_ohwalli_strategic_bomb_plume_fxtrails_03_emit.bp',
}

-- ------------------------------------------------------------------------
--  SERAPHIM SNIPER BOT WEAPON EMITTERS
-- ------------------------------------------------------------------------
SDFSniperShotMuzzleFlash = {
    EmtBpPath .. 'seraphim_sih_muzzleflash_01_emit.bp',
    EmtBpPath .. 'seraphim_sih_muzzleflash_02_emit.bp',
    EmtBpPath .. 'seraphim_sih_muzzleflash_03_emit.bp',
    EmtBpPath .. 'seraphim_sih_muzzleflash_04_emit.bp',
    EmtBpPath .. 'seraphim_sih_muzzleflash_05_emit.bp',
    EmtBpPath .. 'seraphim_sih_muzzleflash_06_emit.bp',

}
SDFSniperShotNormalMuzzleFlash = {
    EmtBpPath .. 'seraphim_sih_muzzleflash_01_emit.bp',
    EmtBpPath .. 'seraphim_sih_muzzleflash_02_emit.bp',
}
SDFSniperShotNormalHit = {
    EmtBpPath .. 'seraphim_sih_projectile_06_emit.bp',
    EmtBpPath .. 'seraphim_sih_projectile_07_emit.bp',
    EmtBpPath .. 'seraphim_sih_projectile_08_emit.bp',
    EmtBpPath .. 'seraphim_sih_projectile_09_emit.bp',
}
SDFSniperShotHit = {
    EmtBpPath .. 'seraphim_sih_projectile_01_emit.bp',
    EmtBpPath .. 'seraphim_sih_projectile_02_emit.bp',
    EmtBpPath .. 'seraphim_sih_projectile_03_emit.bp',
    EmtBpPath .. 'seraphim_sih_projectile_04_emit.bp',
    EmtBpPath .. 'seraphim_sih_projectile_05_emit.bp',
}

SDFSniperShotNormalHitUnit = {
    EmtBpPath .. 'seraphim_sih_projectile_unit_06_emit.bp',
    EmtBpPath .. 'seraphim_sih_projectile_unit_07_emit.bp',
    EmtBpPath .. 'seraphim_sih_projectile_unit_08_emit.bp',
    EmtBpPath .. 'seraphim_sih_projectile_09_emit.bp',
}
SDFSniperShotHitUnit = {
    EmtBpPath .. 'seraphim_sih_projectile_unit_01_emit.bp',
    EmtBpPath .. 'seraphim_sih_projectile_unit_02_emit.bp',
    EmtBpPath .. 'seraphim_sih_projectile_03_emit.bp',
    EmtBpPath .. 'seraphim_sih_projectile_unit_04_emit.bp',
    EmtBpPath .. 'seraphim_sih_projectile_unit_05_emit.bp'
}

SDFSniperShotTrails = {
    EmtBpPath .. 'seraphim_sih_fxtrail_01_emit.bp',
}

SDFSniperShotNormalPolytrail = {
    EmtBpPath .. 'seraphim_sih_polytrail_03_emit.bp',
    EmtBpPath .. 'seraphim_sih_polytrail_04_emit.bp',
}
SDFSniperShotPolytrail = {
    EmtBpPath .. 'seraphim_sih_polytrail_01_emit.bp',
    EmtBpPath .. 'seraphim_sih_polytrail_02_emit.bp',
}


-- ---------------------------------------------------------------
-- -- -- -- -- -- -- AEON PROJECTILES -- -- -- -- -- --
-- ---------------------------------------------------------------


Aeon_QuadLightLaserCannonMuzzleFlash= {
    EmtBpPath .. 'aeon_dualquantum_cannon_muzzle_flash_emit.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_muzzle_flash_emit2.bp',
}

Aeon_QuadLightLaserCannonProjectilePolyTrails = {
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_trail_emit.bp',
}


Aeon_QuadLightLaserCannonProjectileFxTrails = {
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_01_emit.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_02_emit.bp',
}

Aeon_QuadLightLaserCannonLandHit = {
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_emit_land.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_emit2.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_emit3.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_emit4.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_emit5.bp',
}

Aeon_QuadLightLaserCannonHit = {
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_emit.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_emit2.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_emit3.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_emit4.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_emit5.bp',
}

Aeon_QuadLightLaserCannonUnitHit = table.concatenate (Aeon_QuadLightLaserCannonHit, UnitHitShrapnel01)






Aeon_DualQuantumAutoGunMuzzleFlash= {
    EmtBpPath .. 'aeon_dualquantum_cannon_muzzle_flash_emit.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_muzzle_flash_03_emit.bp',
}

Aeon_DualQuantumAutoGunProjectileTrail = EmtBpPath .. 'aeon_dualquantum_cannon_projectile_trail_emit.bp'


Aeon_DualQuantumAutoGunProjectile = {
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_01_emit.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_02_emit.bp',
}

Aeon_DualQuantumAutoGunFxTrail = {
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_fxtrail_emit.bp',
}

Aeon_DualQuantumAutoGunHitLand = {
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_emit.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_02_emit.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_03_emit.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_04_emit.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_05_emit.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_06_emit.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_07_emit.bp',
}

Aeon_DualQuantumAutoGunHit = {
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_emit.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_02_emit.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_03_emit.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_04_emit.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hit_05_emit.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hitunit_06_emit.bp',
    EmtBpPath .. 'aeon_dualquantum_cannon_projectile_hitunit_07_emit.bp',
}

Aeon_DualQuantumAutoGunHit_Unit = table.concatenate (Aeon_DualQuantumAutoGunHit, UnitHitShrapnel01)

Aeon_HeavyDisruptorCannonMuzzleCharge= {
    EmtBpPath .. 'aeon_heavydisruptor_cannon_muzzle_charge_01_emit.bp',
    EmtBpPath .. 'aeon_heavydisruptor_cannon_muzzle_charge_02_emit.bp',
}

Aeon_HeavyDisruptorCannonMuzzleFlash= {
    EmtBpPath .. 'aeon_heavydisruptor_cannon_muzzle_flash_emit.bp',
    EmtBpPath .. 'aeon_heavydisruptor_cannon_muzzle_flash_02_emit.bp',
    EmtBpPath .. 'aeon_heavydisruptor_cannon_muzzle_flash_03_emit.bp',
    EmtBpPath .. 'aeon_heavydisruptor_cannon_muzzle_flash_04_emit.bp',
    EmtBpPath .. 'aeon_heavydisruptor_cannon_muzzle_flash_05_emit.bp',
    EmtBpPath .. 'aeon_heavydisruptor_cannon_muzzle_flash_06_emit.bp',
}

Aeon_HeavyDisruptorCannonProjectileTrails = {
    EmtBpPath .. 'aeon_heavydisruptor_cannon_projectile_trail_emit.bp',
}

Aeon_HeavyDisruptorCannonProjectile = {
    -- -- -- EmtBpPath .. 'aeon_heavydisruptor_cannon_projectile_01_emit.bp',
    -- -- -- EmtBpPath .. 'aeon_heavydisruptor_cannon_projectile_02_emit.bp',
}

Aeon_HeavyDisruptorCannonProjectileFxTrails  = {
    EmtBpPath .. 'aeon_heavydisruptor_cannon_projectile_01_emit.bp',
}

Aeon_HeavyDisruptorCannonLandHit = {
    EmtBpPath .. 'aeon_heavydisruptor_cannon_projectile_hit_01_emit.bp',
    EmtBpPath .. 'aeon_heavydisruptor_cannon_projectile_hit_02_emit.bp',
    EmtBpPath .. 'aeon_heavydisruptor_cannon_projectile_hit_03_emit.bp',
    EmtBpPath .. 'aeon_heavydisruptor_cannon_projectile_hit_04_emit.bp',
    EmtBpPath .. 'aeon_heavydisruptor_cannon_projectile_hit_05_emit.bp',
    EmtBpPath .. 'aeon_heavydisruptor_cannon_projectile_hit_06_emit.bp',
    EmtBpPath .. 'aeon_heavydisruptor_cannon_projectile_hit_07_emit.bp',
    EmtBpPath .. 'aeon_heavydisruptor_cannon_projectile_hit_08_emit.bp',
}

Aeon_HeavyDisruptorCannonHit01 = {
    EmtBpPath .. 'aeon_heavydisruptor_cannon_projectile_hit_unit_02_emit.bp',
    EmtBpPath .. 'destruction_unit_hit_shrapnel_01_emit.bp',
}

Aeon_HeavyDisruptorCannonUnitHit = table.concatenate(Aeon_HeavyDisruptorCannonLandHit, Aeon_HeavyDisruptorCannonHit01)



Aeon_QuanticClusterChargeMuzzleFlash= {
    EmtBpPath .. 'aeon_quanticcluster_muzzle_flash_01_emit.bp',
    EmtBpPath .. 'aeon_quanticcluster_muzzle_flash_02_emit.bp',
}

Aeon_QuanticClusterMuzzleFlash= {
    EmtBpPath .. 'aeon_quanticcluster_muzzle_flash_03_emit.bp', -- flat flash glow
    EmtBpPath .. 'aeon_quanticcluster_muzzle_flash_04_emit.bp', -- expanding ring
    EmtBpPath .. 'aeon_quanticcluster_muzzle_flash_05_emit.bp', -- flash glow
    EmtBpPath .. 'aeon_quanticcluster_muzzle_flash_06_emit.bp', -- straight blue lines, velocity aligned
    EmtBpPath .. 'aeon_quanticcluster_muzzle_flash_07_emit.bp', -- dust
    EmtBpPath .. 'aeon_quanticcluster_muzzle_flash_08_emit.bp', -- little dot glows
}

Aeon_QuanticClusterFrag01 = {
    EmtBpPath .. 'aeon_quanticcluster_split_01_emit.bp',
    EmtBpPath .. 'aeon_quanticcluster_split_02_emit.bp',
    EmtBpPath .. 'aeon_quanticcluster_split_03_emit.bp',
}

Aeon_QuanticClusterFrag02 = {
    EmtBpPath .. 'aeon_quanticcluster_split_04_emit.bp',
    EmtBpPath .. 'aeon_quanticcluster_split_05_emit.bp',
    EmtBpPath .. 'aeon_quanticcluster_split_06_emit.bp',
}

Aeon_QuanticClusterProjectileTrails = {
     EmtBpPath .. 'aeon_quanticcluster_fxtrail_01_emit.bp',
}
Aeon_QuanticClusterProjectileTrails02 = {
     EmtBpPath .. 'aeon_quanticcluster_fxtrail_02_emit.bp',
}

Aeon_QuanticClusterProjectilePolyTrail = EmtBpPath .. 'aeon_quantic_cluster_polytrail_01_emit.bp'
Aeon_QuanticClusterProjectilePolyTrail02 = EmtBpPath .. 'aeon_quantic_cluster_polytrail_02_emit.bp'
Aeon_QuanticClusterProjectilePolyTrail03 = EmtBpPath .. 'aeon_quantic_cluster_polytrail_03_emit.bp'

Aeon_QuanticClusterHit = {
    EmtBpPath .. 'aeon_quanticcluster_hit_01_emit.bp', -- initial flash
    EmtBpPath .. 'aeon_quanticcluster_hit_02_emit.bp', -- glow
    EmtBpPath .. 'aeon_quanticcluster_hit_03_emit.bp', -- fast ring
    EmtBpPath .. 'aeon_quanticcluster_hit_04_emit.bp', -- plasma
    EmtBpPath .. 'aeon_quanticcluster_hit_05_emit.bp', -- lines
    EmtBpPath .. 'aeon_quanticcluster_hit_06_emit.bp', -- darkening molecular
    EmtBpPath .. 'aeon_quanticcluster_hit_07_emit.bp', -- little dot glows
    EmtBpPath .. 'aeon_quanticcluster_hit_08_emit.bp', -- slow ring
    EmtBpPath .. 'aeon_quanticcluster_hit_09_emit.bp', -- darkening
    EmtBpPath .. 'aeon_quanticcluster_hit_10_emit.bp', -- radial rays
}





ALightDisplacementAutocannonMissileMuzzleFlash = {
    EmtBpPath .. 'aeon_light_displacement_missile_muzzleflash_01.bp',
}

ALightDisplacementAutocannonMissileExhaust01 = EmtBpPath .. 'seraphim_lancer_missile_exhaust_polytrail_01.bp'

ALightDisplacementAutocannonMissileExhaust02 = {
    EmtBpPath .. 'seraphim_lancer_missile_exhaust_fxtrail_01_emit.bp',
}

ALightDisplacementAutocannonMissileHit = {
    -- EmtBpPath .. 'seraphim_lancer_missile_hit_01_emit.bp',
    -- EmtBpPath .. 'seraphim_lancer_missile_hit_02_emit.bp',
    -- EmtBpPath .. 'seraphim_lancer_missile_hit_03_emit.bp',
    -- EmtBpPath .. 'seraphim_lancer_missile_hit_04_emit.bp',
    -- EmtBpPath .. 'seraphim_lancer_missile_hit_05_emit.bp',

    EmtBpPath .. 'aeon_light_displacement_missile_hit_01_emit.bp',
    EmtBpPath .. 'aeon_light_displacement_missile_hit_02_emit.bp',
    EmtBpPath .. 'aeon_light_displacement_missile_hit_03_emit.bp',
    EmtBpPath .. 'aeon_light_displacement_missile_hit_04_emit.bp',
}

ALightDisplacementAutocannonMissileHitUnit = {
    -- EmtBpPath .. 'seraphim_lancer_missile_hit_01_unit.bp',
    -- EmtBpPath .. 'seraphim_lancer_missile_hit_02_unit.bp',
    -- EmtBpPath .. 'seraphim_lancer_missile_hit_02_flat_unit.bp',
    -- EmtBpPath .. 'seraphim_lancer_missile_hit_04_unit.bp',
    -- EmtBpPath .. 'seraphim_lancer_missile_hit_05_unit.bp',

    EmtBpPath .. 'aeon_light_displacement_missile_hit_01_emit.bp',
    EmtBpPath .. 'aeon_light_displacement_missile_hit_03_emit.bp',
    EmtBpPath .. 'aeon_light_displacement_missile_hit_02_emit.bp',
    EmtBpPath .. 'aeon_light_displacement_missile_hit_04_emit.bp',
}

ALightDisplacementAutocannonMissilePolyTrails = {
    EmtBpPath .. 'aeon_light_displacement_missile_polytrail_01_emit.bp',
    EmtBpPath .. 'aeon_light_displacement_missile_polytrail_02_emit.bp',
}


--------------------------------------------------
--  OLD UN-REFEFENCED EFFECT MAPPINGS
-- -- FIXME: These don't seem to be used anymore. Double check, and remove
-- -- references and associated assets. ~gd 6.21.07
-- ------------------------------------------------------------------------
TBombHit01 = {
    EmtBpPath .. 'bomb_hit_flash_01_emit.bp',
    EmtBpPath .. 'bomb_hit_fire_01_emit.bp',
    EmtBpPath .. 'bomb_hit_fire_shadow_01_emit.bp',
}
CSGTestAeonGroundFX = {
    EmtBpPath .. '_test_aeon_groundfx_emit.bp',
}
CSGTestAeonGroundFXSmall = {
    EmtBpPath .. '_test_aeon_groundfx_small_emit.bp',
}
CSGTestAeonGroundFXMedium = {
    EmtBpPath .. '_test_aeon_groundfx_medium_emit.bp',
}
CSGTestAeonGroundFXLow = {
    EmtBpPath .. '_test_aeon_groundfx_low_emit.bp',
}
CSGTestAeonT2EngineerGroundFX = {
    EmtBpPath .. '_test_aeon_t2eng_groundfx01_emit.bp',
    EmtBpPath .. '_test_aeon_t2eng_groundfx02_emit.bp',
}

TLaserPolytrail01 = {
    EmtBpPath .. 'terran_commander_cannon_polytrail_01_emit.bp',
    EmtBpPath .. 'terran_commander_cannon_polytrail_02_emit.bp',
    EmtBpPath .. 'default_polytrail_01_emit.bp',
}
TLaserFxtrail01 = {
     EmtBpPath .. 'terran_commander_cannon_fxtrail_01_emit.bp',
}
TLaserMuzzleFlash = {
    EmtBpPath .. 'terran_commander_cannon_flash_01_emit.bp',
    EmtBpPath .. 'terran_commander_cannon_flash_02_emit.bp',
    EmtBpPath .. 'terran_commander_cannon_flash_03_emit.bp',
    EmtBpPath .. 'terran_commander_cannon_flash_04_emit.bp',
    EmtBpPath .. 'terran_commander_cannon_flash_05_emit.bp',
}
TLaserHit01 = { EmtBpPath .. 'laserturret_hit_flash_02_emit.bp',}
TLaserHit02 = {
    EmtBpPath .. 'terran_commander_cannon_hit_01_emit.bp', -- outward lines, non facing
    EmtBpPath .. 'terran_commander_cannon_hit_02_emit.bp', -- fast flash
    EmtBpPath .. 'terran_commander_cannon_hit_03_emit.bp', -- ground oriented flash, slow
    EmtBpPath .. 'terran_commander_cannon_hit_04_emit.bp', -- black ground spots
    EmtBpPath .. 'terran_commander_cannon_hit_05_emit.bp', -- blue wispy
    EmtBpPath .. 'terran_commander_cannon_hit_06_emit.bp', -- darkening dot particles
    EmtBpPath .. 'terran_commander_cannon_hit_07_emit.bp', -- ring
}
TLaserHit03 = {
    EmtBpPath .. 'terran_commander_cannon_hitunit_01_emit.bp', -- outward lines, non facing
    EmtBpPath .. 'terran_commander_cannon_hitunit_02_emit.bp', -- fast flash
    EmtBpPath .. 'terran_commander_cannon_hitunit_03_emit.bp', -- ground oriented flash, slow
    EmtBpPath .. 'terran_commander_cannon_hitunit_04_emit.bp', -- black ground spots
    EmtBpPath .. 'terran_commander_cannon_hit_05_emit.bp', -- blue wispy
    EmtBpPath .. 'terran_commander_cannon_hitunit_06_emit.bp', -- darkening dot particles
    EmtBpPath .. 'terran_commander_cannon_hitunit_07_emit.bp', -- ring
}
TLaserHitUnit01 = table.concatenate(TLaserHit01, UnitHitShrapnel01)
TLaserHitLand01 = table.concatenate(TLaserHit01)
TLaserHitUnit02 = table.concatenate(TLaserHit03, UnitHitShrapnel01)
TLaserHitLand02 = table.concatenate(TLaserHit02)


-- -----------------------------------------------------------------------------------
-- -- --  TEST EMITTERS!  -- --
-- -----------------------------------------------------------------------------------
TestExplosion01 = {
    EmtBpPath .. '_test_explosion_b1_emit.bp', -- lowest layer orange
    EmtBpPath .. '_test_explosion_b2_emit.bp', -- top layer smoke
    EmtBpPath .. '_test_explosion_b3_emit.bp', -- midlayer orange
    EmtBpPath .. '_test_explosion_b1_flash_emit.bp',
    EmtBpPath .. '_test_explosion_b1_sparks_emit.bp',
    EmtBpPath .. '_test_explosion_b2_dustring_emit.bp',
    EmtBpPath .. '_test_explosion_b2_flare_emit.bp',
    EmtBpPath .. '_test_explosion_b2_smokemask_emit.bp',
}

CSGTestEffect = {
    EmtBpPath .. '_test_explosion_medium_01_emit.bp',
    EmtBpPath .. '_test_explosion_medium_02_emit.bp',
    EmtBpPath .. '_test_explosion_medium_03_emit.bp',
    EmtBpPath .. '_test_explosion_medium_04_emit.bp',
    EmtBpPath .. '_test_explosion_medium_05_emit.bp',
    EmtBpPath .. '_test_explosion_medium_06_emit.bp',
}

CSGTestEffect2 = {
    EmtBpPath .. '_test_swirl_01b_emit.bp',
    -- EmtBpPath .. '_test_swirl_02_emit.bp',
    EmtBpPath .. '_test_swirl_03_emit.bp',
    EmtBpPath .. '_test_swirl_04_emit.bp',
    EmtBpPath .. '_test_swirl_05_emit.bp',
    EmtBpPath .. '_test_swirl_06_emit.bp',
}
CSGTestSpinner1 = {
    EmtBpPath .. '_test_gatecloud_01_emit.bp',
    EmtBpPath .. '_test_gatecloud_02_emit.bp',
    EmtBpPath .. '_test_gatecloud_03_emit.bp',
}
CSGTestSpinner2 = {
    EmtBpPath .. '_test_gatecloud_04_emit.bp',
    EmtBpPath .. '_test_gatecloud_05_emit.bp',
}
CSGTestSpinner3 = {
    -- EmtBpPath .. '_test_gatecloud_06_emit.bp',
    EmtBpPath .. '_test_gatecloud_07_emit.bp',
}

-------------------------------------------------------------------------------
--#region Legacy and deprecated code

-- Everything below is considered deprecated. You should not use it. Especially
-- `NoEffects` and the three `DefaultPolyTrail` tables are dangerous. They can
-- cause the class loader to find itself in infinite loops

NoEffects = { }
DefaultPolyTrailOffset1 = { 0 }
DefaultPolyTrailOffset2 = { 0, 0 }
DefaultPolyTrailOffset3 = { 0, 0, 0 }

--#endregion
