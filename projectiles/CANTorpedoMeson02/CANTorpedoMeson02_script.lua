--
-- Cybran Non-guided Torpedo, Made to be fired from above the water
--
local CTorpedoSubProjectile = import("/lua/cybranprojectiles.lua").CTorpedoSubProjectile

CANTorpedoMeson02 = ClassProjectile(CTorpedoSubProjectile) {
    FxSplashScale = 1,
}
TypeClass = CANTorpedoMeson02