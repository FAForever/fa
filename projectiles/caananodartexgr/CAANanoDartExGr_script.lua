--
-- Cybran Anti Air Projectile
--

CAANanoDartProjectile = import("/lua/cybranprojectiles.lua").CAANanoDartProjectile

CAANanoDart01 = Class(CAANanoDartProjectile) {

   OnCreate = function(self)
        CAANanoDartProjectile.OnCreate(self)
        self.Trash:Add(ForkThread(self.UpdateThread))
   end,


    UpdateThread = function(self)
        WaitTicks(1)
        self:SetBallisticAcceleration(-0.5)

        for i in self.FxTrails do
            CreateEmitterOnEntity(self, self.Army, self.FxTrails[i])
        end

        WaitTicks(2)
        self:SetMesh('/projectiles/CAANanoDart01/CAANanoDartUnPacked01_mesh')


    end,
}

TypeClass = CAANanoDart01
