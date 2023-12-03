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
        WaitTicks(4)
        self:SetMaxSpeed(6)
        self:SetBallisticAcceleration(-0.5)
        WaitTicks(6)
        self:SetMesh('/projectiles/CAANanoDart01/CAANanoDartUnPacked01_mesh')
        self:SetMaxSpeed(60)
        self:SetAcceleration(25 + Random() * 3)
        WaitTicks(4)
        self:SetTurnRate(360)
    end,
}
TypeClass = CAANanoDart01