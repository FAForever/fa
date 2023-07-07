-- Cybran laser 'bolt'
local CHeavyLaserProjectile = import("/lua/cybranprojectiles.lua").CHeavyLaserProjectile

---@class CDFLaserHeavy03 : CHeavyLaserProjectile
CDFLaserHeavy03 = ClassProjectile(CHeavyLaserProjectile) {}
TypeClass = CDFLaserHeavy03