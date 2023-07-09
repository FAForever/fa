local TLaserBotProjectile = import("/lua/terranprojectiles.lua").TLaserBotProjectile

-- Cybran laser 'bolt'
---@class LaserBotTerran01 : TLaserBotProjectile
LaserBotTerran01 = ClassProjectile(TLaserBotProjectile) {}
TypeClass = LaserBotTerran01