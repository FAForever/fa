-- Automatically upvalued moho functions for performance
local GlobalMethods = _G
local GlobalMethodsCreateEmitterAtEntity = GlobalMethods.CreateEmitterAtEntity
local GlobalMethodsCreateLightParticle = GlobalMethods.CreateLightParticle
-- End of automatically upvalued moho functions

#
# Cybran disintegrator laser
#
local CDisintegratorLaserProjectile = import('/lua/cybranprojectiles.lua').CDisintegratorLaserProjectile

CDFLaserDisintegrator03 = Class(CDisintegratorLaserProjectile)({
    CreateImpactEffects = function(self, army, EffectTable, EffectScale)
        local launcher = self:GetLauncher()
        if launcher and launcher:HasEnhancement('EMPCharge') then
            GlobalMethodsCreateLightParticle(self, -1, army, 1.9, 9, 'ring_07', 'ramp_red_04')
            GlobalMethodsCreateEmitterAtEntity(self, army, '/effects/emitters/cybran_empgrenade_hit_03_emit.bp')
        end
        CDisintegratorLaserProjectile.CreateImpactEffects(self, army, EffectTable, EffectScale)
    end,
})

TypeClass = CDFLaserDisintegrator03

