-- AA Missile for Cybrans

local CAAMissileNaniteProjectile = import("/lua/cybranprojectiles.lua").CAAMissileNaniteProjectile
CAAMissileNanite01 = ClassProjectile(CAAMissileNaniteProjectile) {
    OnCreate = function(self)
        CAAMissileNaniteProjectile.OnCreate(self)
        self.Trash:Add(ForkThread(self.UpdateThread, self))
    end,

    UpdateThread = function(self)
        WaitTicks(16)
        self:SetMaxSpeed(80)
        self:SetAcceleration(10 + Random() * 8)
        self:ChangeMaxZigZag(0.5)
        self:ChangeZigZagFrequency(2)
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        CAAMissileNaniteProjectile.OnImpact(self, TargetType, TargetEntity)
    end,
}
TypeClass = CAAMissileNanite01