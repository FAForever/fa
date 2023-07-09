local CAANanoDartProjectile = import("/lua/cybranprojectiles.lua").CAANanoDartProjectile

-- Cybran Anti Air Projectile
---@class CAANanoDart01: CAANanoDartProjectile
CAANanoDart01 = ClassProjectile(CAANanoDartProjectile) {

    ---@param self CAANanoDart01
    OnCreate = function(self)
        CAANanoDartProjectile.OnCreate(self)
        self.Trash:Add(ForkThread(self.UpdateThread,self))
    end,

    ---@param self CAANanoDart01
    UpdateThread = function(self)
        WaitTicks(2)
        self:SetBallisticAcceleration(-0.5)
        WaitTicks(3)
        self:SetMesh('/projectiles/CAANanoDart01/CAANanoDartUnPacked01_mesh')
    end,
}
TypeClass = CAANanoDart01