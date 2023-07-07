--
-- Aeon Factory Projectile for use while building
--
local Projectile = import("/lua/sim/projectile.lua").Projectile

---@class AIMFactoryBlob01: Projectile
AIMFactoryBlob01 = ClassProjectile(Projectile) {}
TypeClass = AIMFactoryBlob01