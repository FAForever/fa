--
-- Cybran Anti Air Projectile
--

CAANanoDartProjectile = import("/lua/cybranprojectiles.lua").CAANanoDartProjectile

CAANanoDart01 = Class(CAANanoDartProjectile) {

   OnCreate = function(self)
        CAANanoDartProjectile.OnCreate(self)
        self.Thread:Add(ForkThread(self.UpdateThread))
   end,


    UpdateThread = function(self)
        WaitTicks(3)
        self:SetMaxSpeed(10)
        self:SetBallisticAcceleration(-0.2)
        WaitTicks(3)
        self:SetMesh('/projectiles/CAANanoDart01/CAANanoDartUnPacked01_mesh')
        self:SetMaxSpeed(60)
        self:SetAcceleration(20 + Random() * 5)
        WaitTicks(4)
        self:SetTurnRate(360)

    end,
}

TypeClass = CAANanoDart01
