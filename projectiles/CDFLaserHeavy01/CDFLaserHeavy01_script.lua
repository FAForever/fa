-- Cybran laser 'bolt'
local CHeavyLaserProjectile = import("/lua/cybranprojectiles.lua").CHeavyLaserProjectile

---@class CDFLaserHeavy01 : CHeavyLaserProjectile
CDFLaserHeavy01 = ClassProjectile(CHeavyLaserProjectile) {}
TypeClass = CDFLaserHeavy01