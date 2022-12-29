-- Cybran Anti Air Projectile
CAANanoDartProjectile = import("/lua/cybranprojectiles.lua").CAANanoDartProjectile
CAANanoDart01 = ClassProjectile(CAANanoDartProjectile) {
    OnCreate = function(self)
        CAANanoDartProjectile.OnCreate(self)
        self.Trash:Add(ForkThread(self.UpdateThread,self))
    end,

    UpdateThread = function(self)
        WaitTicks(2)
        self:SetBallisticAcceleration(-0.5)
        WaitTicks(3)
        self:SetMesh('/projectiles/CAANanoDart01/CAANanoDartUnPacked01_mesh')
    end,
}
TypeClass = CAANanoDart01