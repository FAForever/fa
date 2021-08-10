--
-- Cybran Anti Air Projectile
--

CAANanoDartProjectile03 = import('/lua/cybranprojectiles.lua').CAANanoDartProjectile03

CAANanoDart01 = Class(CAANanoDartProjectile03) {

   OnCreate = function(self)
        CAANanoDartProjectile03.OnCreate(self)
        self:ForkThread(self.UpdateThread)
   end,


    UpdateThread = function(self)
        WaitSeconds(0.35)
        self:SetMaxSpeed(2)
        self:SetBallisticAcceleration(-0.5)
        local army = self:GetArmy()

        for i in self.FxTrails do
            CreateEmitterOnEntity(self,army,self.FxTrails[i])
        end

        WaitSeconds(0.5)
        self:SetMesh('/projectiles/CAANanoDart01/CAANanoDartUnPacked01_mesh')
        self:SetMaxSpeed(60)
        self:SetAcceleration(16 + Random() * 5)

        WaitSeconds(0.3)
        self:SetTurnRate(360)

    end,
}

TypeClass = CAANanoDart01
