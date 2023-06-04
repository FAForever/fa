-- script for projectile Missile
local TMissileCruiseSubProjectile = import("/lua/terranprojectiles.lua").TMissileCruiseSubProjectile

MissileCruiseSubTerran01 = ClassProjectile(TMissileCruiseSubProjectile) {
    FxSplashScale = 0.5,
    OnCreate = function(self)
        TMissileCruiseSubProjectile.OnCreate(self)
        self:SetScale(0.6)
    end,

    Thread = function(self)
        self:TrackTarget(false)

        for i in self.FxInitialAtEntityEmitter do --old way of firing muzzle fx
            CreateEmitterAtEntity(self,self.Army,self.FxInitialAtEntityEmitter[i]):ScaleEmitter(self.FxTrailScale):OffsetEmitter(0,0,self.FxTrailOffset)
        end
        WaitTicks(1)
        local emitter = {}
        for i in self.FxUnderWaterTrail do --underwater trail
            table.insert(emitter, CreateEmitterOnEntity(self,self:GetArmy(),self.FxUnderWaterTrail[i]):ScaleEmitter(self.FxTrailScale):OffsetEmitter(0,0,self.FxTrailOffset))
        end

        WaitTicks(45)
        for i in self.FxExitWaterEmitter do --splash
            CreateEmitterAtEntity(self,self.Army,self.FxExitWaterEmitter[i]):ScaleEmitter(self.FxSplashScale)
        end
        for i in emitter do
            emitter[i]:Destroy()
        end
        self.MissileExhaust = CreateBeamEmitter('/effects/emitters/missile_cruise_munition_exhaust_beam_01_emit.bp',self:GetArmy())
        AttachBeamToEntity(self.MissileExhaust, self, -1, self:GetArmy())
        for i in self.FxLaunchTrails do --launch trails
            CreateEmitterOnEntity(self,self:GetArmy(),self.FxLaunchTrails[i]):ScaleEmitter(self.FxTrailScale):OffsetEmitter(0,0,self.FxTrailOffset)
        end
        WaitTicks(30) --Straight Up
        self:TrackTarget(true)
        WaitTicks(10) --Start Tracking
        self:TrackTarget(false)
        self:SetMaxSpeed(2)
        self:SetBallisticAcceleration()
        self.MissileExhaust:Destroy()
        WaitTicks(10) --Falling
        self.MissileExhaust = CreateBeamEmitter('/effects/emitters/missile_cruise_munition_exhaust_beam_02_emit.bp',self:GetArmy())
        AttachBeamToEntity(self.MissileExhaust, self, -1, self:GetArmy())
        for i in self.FxTrails do --flight trails
            CreateEmitterOnEntity(self,self.Army,self.FxTrails[i]):ScaleEmitter(self.FxTrailScale):OffsetEmitter(0,0,self.FxTrailOffset)
        end
        self:SetTurnRate(10)
        self:TrackTarget(true)
        WaitTicks(6)
        self:SetTurnRate(30)
        self:SetMaxSpeed(50)
        self:SetAcceleration(50)
    end,
}
TypeClass = MissileCruiseSubTerran01