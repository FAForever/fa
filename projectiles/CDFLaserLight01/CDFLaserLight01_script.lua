-- Cybran laser 'bolt'
local CLaserLaserProjectile = import("/lua/cybranprojectiles.lua").CLaserLaserProjectile

---@class CDFLaserLight01 : CLaserLaserProjectile
CDFLaserLight01 = ClassProjectile(CLaserLaserProjectile) {}
TypeClass = CDFLaserLight01