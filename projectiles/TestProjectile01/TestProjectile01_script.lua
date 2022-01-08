#
# TestProjectile
#
local Projectile = import('/lua/sim/Projectile.lua').Projectile

TestProjectile01 = Class(Projectile)
{
    BeamName = '/effects/emitters/test_beam_01_emit.bp',
    PolyTrail = '/effects/emitters/test_polytrail_01_emit.bp',
    FxTrails = {'/effects/emitters/test_emittrail_01_emit.bp',},

    FxImpactUnit = {},
    FxImpactLand = {},
    FxImpactWater = {},
    FxImpactUnderWater = {},

    OnCreate = function(self)
        Projectile.OnCreate(self)

        #Polytrail
        CreateTrail(self, -1, self:GetArmy(),self.PolyTrail )

        #Emitter trail
        for i in self.FxTrails do
            CreateEmitterOnEntity(self,self:GetArmy(),self.FxTrails[i])
        end

        #Beam Trail
        local beam = CreateBeamEmitter(self.BeamName,self:GetArmy())
        AttachBeamToEntity(beam, self, -1, self:GetArmy())

    end,
}

TypeClass = TestProjectile01