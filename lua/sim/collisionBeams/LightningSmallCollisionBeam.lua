local SCCollisionBeam = import("/lua/sim/collisionbeams/sccollisionbeam.lua").SCCollisionBeam

LightningSmallCollisionBeam = Class(SCCollisionBeam) {
    FxBeamStartPoint = {
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_01_emit.bp',
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_02_emit.bp',
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_03_emit.bp',
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_04_emit.bp',
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_05_emit.bp',
        '/Effects/Emitters/seraphim_experimental_phasonproj_muzzle_flash_06_emit.bp',
        '/Effects/Emitters/seraphim_electricity_emit.bp'
    },
    FxBeam = {
        '/Effects/Emitters/seraphim_lightning_beam_01_emit.bp',
    },
    FxBeamEndPoint = {
        '/Effects/Emitters/seraphim_lightning_hit_01_emit.bp',
        '/Effects/Emitters/seraphim_lightning_hit_02_emit.bp',
        '/Effects/Emitters/seraphim_lightning_hit_03_emit.bp',
        '/Effects/Emitters/seraphim_lightning_hit_04_emit.bp',
    },

    TerrainImpactType = 'LargeBeam01',
    TerrainImpactScale = 0.2,
}
