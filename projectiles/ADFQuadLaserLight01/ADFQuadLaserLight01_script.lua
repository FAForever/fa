local ALightLaserProjectile = import("/lua/aeonprojectiles.lua").AQuadLightLaserProjectile

-- Aeon laser 'bolt'
---@class ADFLaserLight01 : AQuadLightLaserProjectile
ADFLaserLight01 = ClassProjectile(ALightLaserProjectile) {}
TypeClass = ADFLaserLight01