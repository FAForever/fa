-- Automatically upvalued moho functions for performance
local GlobalMethods = _G
local GlobalMethodsCreateEmitterAtEntity = GlobalMethods.CreateEmitterAtEntity

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileMethodsSetMaxSpeed = ProjectileMethods.SetMaxSpeed
local ProjectileMethodsSetStayUpright = ProjectileMethods.SetStayUpright
local ProjectileMethodsSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileMethodsSetVelocity = ProjectileMethods.SetVelocity
local ProjectileMethodsSetVelocityAlign = ProjectileMethods.SetVelocityAlign
local ProjectileMethodsStayUnderwater = ProjectileMethods.StayUnderwater
local ProjectileMethodsTrackTarget = ProjectileMethods.TrackTarget
-- End of automatically upvalued moho functions

#
# Depth Charge Script
#
local ADepthChargeProjectile = import('/lua/aeonprojectiles.lua').ADepthChargeProjectile
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

AANDepthCharge03 = Class(ADepthChargeProjectile)({

    CountdownLength = 10,
    FxEnterWater = {
        '/effects/emitters/water_splash_ripples_ring_01_emit.bp',
        '/effects/emitters/water_splash_plume_01_emit.bp',
    },


    OnCreate = function(self)
        ADepthChargeProjectile.OnCreate(self)
        self.HasImpacted = false
        self:ForkThread(self.CountdownExplosion)
    end,

    CountdownExplosion = function(self)
        WaitSeconds(self.CountdownLength)

        if not self.HasImpacted then
            self.OnImpact(self, 'Underwater', nil)
        end
    end,

    OnEnterWater = function(self)
        #ADepthChargeProjectile.OnEnterWater(self)

        for i in self.FxEnterWater do
            #splash
            GlobalMethodsCreateEmitterAtEntity(self, self.Army, self.FxEnterWater[i])
        end

        #self:SetMaxSpeed(20)
        #self:SetVelocity(0)
        #self:SetAcceleration(5)
        ProjectileMethodsTrackTarget(self, true)
        ProjectileMethodsStayUnderwater(self, true)
        ProjectileMethodsSetTurnRate(self, 360)
        ProjectileMethodsSetVelocityAlign(self, true)
        ProjectileMethodsSetStayUpright(self, false)
        #self:ForkThread(self.EnterWaterMovementThread)
    end,

    EnterWaterMovementThread = function(self)
        WaitTicks(1)
        ProjectileMethodsSetVelocity(self, 0.5)
    end,

    OnLostTarget = function(self)
        ProjectileMethodsSetMaxSpeed(self, 2)
        self:SetAcceleration(-0.6)
        self:ForkThread(self.CountdownMovement)
    end,

    CountdownMovement = function(self)
        WaitSeconds(3)
        ProjectileMethodsSetMaxSpeed(self, 0)
        self:SetAcceleration(0)
        ProjectileMethodsSetVelocity(self, 0)
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        #LOG('Projectile impacted with: ' .. TargetType)
        self.HasImpacted = true
        local pos = self:GetPosition()
        local spec = {
            X = pos[1],
            Z = pos[3],
            Radius = 30,
            LifeTime = 10,
            Omni = false,
            Vision = false,
            Army = self.Army,


        }
        local vizEntity = VizMarker(spec)
        ADepthChargeProjectile.OnImpact(self, TargetType, TargetEntity)
    end,
})

TypeClass = AANDepthCharge03