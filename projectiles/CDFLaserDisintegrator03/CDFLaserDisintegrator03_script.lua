local CDisintegratorLaserProjectile = import("/lua/cybranprojectiles.lua").CDisintegratorLaserProjectile

-- Cybran disintegrator laser
---@class CDFLaserDisintegrator03 : CDisintegratorLaserProjectile
CDFLaserDisintegrator03 = ClassProjectile(CDisintegratorLaserProjectile) {

    ---@param self CDFLaserDisintegrator03
    ---@param army number
    ---@param EffectTable table
    ---@param EffectScale number
    CreateImpactEffects = function(self, army, EffectTable, EffectScale)
        local launcher = self.Launcher
        if launcher and launcher:HasEnhancement('EMPCharge') then
            CreateLightParticle(self, -1, self.Army, 1.9, 9, 'ring_07', 'ramp_red_04')
            CreateEmitterAtEntity(self, self.Army,'/effects/emitters/cybran_empgrenade_hit_03_emit.bp')
        end
        CDisintegratorLaserProjectile.CreateImpactEffects(self, army, EffectTable, EffectScale)
    end,
}
TypeClass = CDFLaserDisintegrator03