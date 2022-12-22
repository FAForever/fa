--
-- Cybran Anti Air Projectile
--

CAANanoDartProjectile = import("/lua/cybranprojectiles.lua").CAANanoDartProjectile

CAANanoDart02 = Class(CAANanoDartProjectile) {

   OnCreate = function(self)
        CAANanoDartProjectile.OnCreate(self)
        for k, v in self.FxTrails do
            CreateEmitterOnEntity(self,self.Army,v )
        end
   end,
}

TypeClass = CAANanoDart02
