--
-- Cybran Anti Air Projectile
--

CAANanoDartProjectile = import("/lua/cybranprojectiles.lua").CAANanoDartProjectile

CAANanoDart01 = Class(CAANanoDartProjectile) {

   OnCreate = function(self)
        CAANanoDartProjectile.OnCreate(self)
        self:ForkThread(self.UpdateThread)
   end,


    UpdateThread = function(self)
        WaitSeconds(0.3)
        self:SetMaxSpeed(6)
        self:SetBallisticAcceleration(-0.5)

        for i in self.FxTrails do
            CreateEmitterOnEntity(self, self.Army, self.FxTrails[i])
        end

        WaitSeconds(0.5)
        self:SetMesh('/projectiles/CAANanoDart01/CAANanoDartUnPacked01_mesh')
        self:SetMaxSpeed(60)
        self:SetAcceleration(25 + Random() * 3)

        WaitSeconds(0.3)
        self:SetTurnRate(360)

    end,
}

TypeClass = CAANanoDart01
