-- script for projectile Missile

local Projectile = import("/lua/sim/projectile.lua").Projectile

MissileCruiseTerran01 = ClassProjectile(Projectile) {
    MissileExhaust = {},

    -- LAUNCH BEAM
    FxLaunchBeamTexture = '/textures/particles/beam_missile_exhaust_01.dds',
    FxLaunchBeamSize = {-0.5, 0.015}, --Length, Width
    FxLaunchBeamColor = {1, 1, 0.75}, --R,G,B
    FxLaunchBeamGlow = 0.0,
    -- LAUNCH TRAILS
    FxLaunchTrails = {'/effects/emitters/missile_cruise_munition_launch_trail_01_emit.bp',},
    FxLaunchTrailScale = 1,
    FxLaunchTrailOffset = -0.5,
    -- BEAM
    FxBeamTexture = '/textures/particles/beam_missile_exhaust_02.dds',
    FxBeamSize = {-1, 0.5}, --Length, Width
    FxBeamColor = {1, 1, 0.75}, --R,G,B
    FxBeamGlow = 0.0,
    -- TRAILS
    FxTrails = {'/effects/emitters/missile_cruise_munition_trail_01_emit.bp',},
    FxTrailScale = 1,
    FxTrailOffset = -0.5,
    -- Hit Effects
    FxUnitHitScale = 1,
    FxImpactUnit = {'/effects/emitters/missile_hit_flash_01_emit.bp',
        '/effects/emitters/missile_hit_fire_01_emit.bp',
    },
    FxLandHitScale = 1,
    FxImpactLand = {'/effects/emitters/missile_hit_flash_01_emit.bp',
        '/effects/emitters/missile_hit_fire_01_emit.bp',
        '/effects/emitters/destruction_scorch_01_emit.bp',
    },
    FxImpactNone = {'/effects/emitters/missile_hit_flash_01_emit.bp',
        '/effects/emitters/missile_hit_fire_01_emit.bp',
    },

    OnCreate = function(self)
        Projectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)

        self.trails = {}
        local army = self.Army

        for i in self.FxTrails do
            table.insert(self.trails, CreateEmitterOnEntity(self, army,self.FxLaunchTrails[i]):ScaleEmitter(self.FxLaunchTrailScale):OffsetEmitter(0, 0, self.FxLaunchTrailOffset))
        end
        self.MissileExhaust = CreateBeamEmitter('/effects/emitters/missile_cruise_munition_exhaust_beam_01_emit.bp',army)
        AttachBeamToEntity(self.MissileExhaust, self, -1, army)
        self.Trash:Add(ForkThread(self.CruiseMissileThread,self))
    end,

    CruiseMissileThread = function(self)
        self:TrackTarget(false)
        WaitTicks(41)
        self:TrackTarget(true)
        WaitTicks(11)
        self:TrackTarget(false)
        self:SetMaxSpeed(2)
        self:SetBallisticAcceleration()
        for i in self.trails do
            self.trails[i]:Destroy()
        end
        self.MissileExhaust:Destroy()
        WaitTicks(6) --Falling
        local army = self.Army
        self.MissileExhaust = CreateBeamEmitter('/effects/emitters/missile_cruise_munition_exhaust_beam_02_emit.bp', army)
        AttachBeamToEntity(self.MissileExhaust, self, -1, army)

        self.trails = {}
        for i in self.FxTrails do
            table.insert(self.trails, CreateEmitterOnEntity(self, army,self.FxTrails[i]):ScaleEmitter(self.FxTrailScale):OffsetEmitter(0, 0, self.FxTrailOffset))
        end
        self:SetTurnRate(20)
        self:TrackTarget(true)
        WaitTicks(6)
        self:SetTurnRate(400)
        self:SetMaxSpeed(25)
        self:SetAcceleration(25)
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        for i in self.trails do
            self.trails[i]:Destroy()
        end
        self.trails = {}
        Projectile.OnImpact(self, TargetType, TargetEntity)
    end,
}
TypeClass = MissileCruiseTerran01