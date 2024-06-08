local Projectile = import("/lua/sim/projectile.lua").Projectile

--- Test Projectile
---@class TestProjectile01: Projectile
TestProjectile01 = ClassProjectile(Projectile)
{
    BeamName = '/effects/emitters/test_beam_01_emit.bp',
    PolyTrail = '/effects/emitters/test_polytrail_01_emit.bp',
    FxTrails = {'/effects/emitters/test_emittrail_01_emit.bp',},

    FxImpactUnit = { },
    FxImpactLand = { },
    FxImpactWater = { },

    ---@param self TestProjectile01
    OnCreate = function(self)
        Projectile.OnCreate(self)

        --Polytrail
        CreateTrail(self, -1, self.Army,self.PolyTrail )

        --Emitter trail
        for i in self.FxTrails do
            CreateEmitterOnEntity(self,self.Army,self.FxTrails[i])
        end

        --Beam Trail
        local beam = CreateBeamEmitter(self.BeamName,self.Army)
        AttachBeamToEntity(beam, self, -1, self.Army)

    end,
}
TypeClass = TestProjectile01