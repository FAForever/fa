-- Aeon Torpedo Bomb

local ATorpedoShipProjectile= import("/lua/aeonprojectiles.lua").ATorpedoShipProjectile

AANTorpedo02 = ClassProjectile(ATorpedoShipProjectile) {
    FxSplashScale = 1,
    FxTrailScale = 0.75,

    OnCreate = function(self, inWater)
        ATorpedoShipProjectile.OnCreate(self, inWater)
        self:SetMaxSpeed(8)
        self.Trash:Add(ForkThread( self.MotionThread,self))
    end,

    MotionThread = function(self)
        WaitTicks(4)
        self:SetTurnRate(80)
        self:SetMaxSpeed(3)
        self:SetVelocity(3)
    end,
}
TypeClass = AANTorpedo02