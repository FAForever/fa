local Projectile = import("/lua/sim/projectile.lua").Projectile

-- Aeon Factory Projectile for use while building
---@class AIMFactoryBlob01 : Projectile
AIMFactoryBlob01 = ClassProjectile(Projectile) {}
TypeClass = AIMFactoryBlob01