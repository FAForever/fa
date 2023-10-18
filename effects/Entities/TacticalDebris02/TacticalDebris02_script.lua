
local GenericDebris = import("/lua/genericdebris.lua").GenericDebris

---@class TacticalDebris02 : GenericDebris
TacticalDebris02 = ClassDummyProjectile(GenericDebris) {
    FxTrails = import("/lua/EffectTemplates.lua").TacticalDebrisTrails02,

    ---@param self BaseGenericDebris
    ---@param targetType string
    ---@param targetEntity Unit | Shield | Projectile
    OnImpact = function(self, targetType, targetEntity)
        GenericDebris.OnImpact(self, targetType, targetEntity)

        DamageArea(self, self:GetPosition(), 2, 1, 'TreeFire', false, false)
        CreateLightParticle(self, -1, self.Army, 3, 6, 'flare_lens_add_02', 'ramp_fire_13')
    end,
}
TypeClass = TacticalDebris02
