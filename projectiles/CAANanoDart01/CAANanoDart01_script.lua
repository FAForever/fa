-- Cybran Anti Air Projectile
CAANanoDartProjectile03 = import("/lua/cybranprojectiles.lua").CAANanoDartProjectile03
CAANanoDart01 = ClassProjectile(CAANanoDartProjectile03) {
   OnCreate = function(self)
        CAANanoDartProjectile03.OnCreate(self)
        self.Trash:Add(ForkThread(self.UpdateThread,self))
   end,

    UpdateThread = function(self)
        WaitTicks(4)
        self:SetMaxSpeed(2)
        self:SetBallisticAcceleration(-0.5)
        WaitTicks(6)
        self:SetMesh('/projectiles/CAANanoDart01/CAANanoDartUnPacked01_mesh')
        self:SetMaxSpeed(60)
        self:SetAcceleration(16 + Random() * 5)
        WaitTicks(4)
        self:SetTurnRate(360)
    end,
}
TypeClass = CAANanoDart01