-- Cybran Anti Air Projectile
CAANanoDartProjectile = import("/lua/cybranprojectiles.lua").CAANanoDartProjectile

---@class CAANanoDart02: CAANanoDartProjectile
CAANanoDart02 = ClassProjectile(CAANanoDartProjectile) {

    ---@param self CAANanoDart02
    OnCreate = function(self)
        CAANanoDartProjectile.OnCreate(self)
        for k, v in self.FxTrails do
            CreateEmitterOnEntity(self,self.Army,v )
        end
    end,
}
TypeClass = CAANanoDart02