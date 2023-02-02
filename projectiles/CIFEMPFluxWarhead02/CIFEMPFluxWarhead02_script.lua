------------------------------------------------------------------------------
-- File     :  /projectiles/CIFEMPFluxWarhead02/CIFEMPFluxWarhead02_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  EMP Flux Warhead Impact effects projectile
-- Copyright © 2005,2006 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------
local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat

CIFEMPFluxWarhead02 = ClassProjectile(NullShell) {
    -- Effects attached to moving nuke projectile plume
    PlumeEffects = {'/effects/emitters/empfluxwarhead_concussion_ring_02_emit.bp',
                    '/effects/emitters/empfluxwarhead_01_emit.bp',
                    '/effects/emitters/empfluxwarhead_02_emit.bp',
                    '/effects/emitters/empfluxwarhead_03_emit.bp'},

    -- Effects not attached but created at the position of CIFEMPFluxWarhead02
    NormalEffects = {'/effects/emitters/empfluxwarhead_concussion_ring_01_emit.bp',
                     '/effects/emitters/empfluxwarhead_fallout_01_emit.bp'},

    PlumeVelocityScale = 0.1,

    EffectThread = function(self)
        -- Light and Camera Shake
        CreateLightParticle(self, -1, self.Army, 200, 200, 'beam_white_01', 'ramp_red_09')
        self:ShakeCamera(75, 3, 0, 20)

        -- Mesh effects
        self.Plumeproj = self:CreateProjectile('/effects/EMPFluxWarhead/EMPFluxWarheadEffect01_proj.bp')
        self.Trash:Add(ForkThread(self.PlumeThread, self, self.Plumeproj, self.Plumeproj.Blueprint.Display.UniformScale))
        self.Trash:Add(ForkThread(self.PlumeVelocityThread, self, self.Plumeproj))

        self.Plumeproj2 = self:CreateProjectile('/effects/EMPFluxWarhead/EMPFluxWarheadEffect02_proj.bp')
        self.Trash:Add(ForkThread(self.PlumeThread, self, self.Plumeproj2, self.Plumeproj2.Blueprint.Display.UniformScale))
        self.Trash:Add(ForkThread(self.PlumeVelocityThread, self, self.Plumeproj2))

        self.Plumeproj3 = self:CreateProjectile('/effects/EMPFluxWarhead/EMPFluxWarheadEffect03_proj.bp')
        self.Trash:Add(ForkThread(self.PlumeThread, self, self.Plumeproj3, self.Plumeproj3.Blueprint.Display.UniformScale))
        self.Trash:Add(ForkThread(self.PlumeVelocityThread, self, self.Plumeproj3))

        CreateDecal(self:GetPosition(), RandomFloat(0,2*math.pi), 'nuke_scorch_001_albedo', '', 'Albedo', 28, 28, 500, 0, self.Army)

        -- Emitter Effects
        self.Trash:Add(ForkThread(self.EmitterEffectsThread, self, self.Plumeproj))
    end,

    EmitterEffectsThread = function(self, plume)
        for k, v in self.PlumeEffects do
            CreateAttachedEmitter(plume, -1, self.Army, v)
        end

        for k, v in self.NormalEffects do
            CreateEmitterAtEntity(self, self.Army, v)
        end

        self:StarCloudDispersal()
    end,

    StarCloudDispersal = function(self)
        local numProjectiles = 5
        local angle = (2*math.pi) / numProjectiles
        local angleInitial = RandomFloat(0, angle)
        local angleVariation = angle * 0.5
        local projectiles = {}

        local xVec = 0
        local yVec = 0.3
        local zVec = 0
        local velocity = 0

        -- Launch projectiles at semi-random angles away from the sphere, with enough
        -- initial velocity to escape sphere core
        for i = 0, (numProjectiles -1) do
            xVec = math.sin(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))
            yVec = 0.3 + RandomFloat(-0.8, 1.0)
            zVec = math.cos(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))
            velocity = 2.4 + (yVec * 3)
            table.insert(projectiles, self:CreateProjectile('/projectiles/CIFEMPFluxWarhead03/CIFEMPFluxWarhead03_proj.bp', 0, 0, 0, xVec, yVec, zVec):SetVelocity(velocity):SetBallisticAcceleration(1.0))
        end
        WaitTicks(31)
        -- Slow projectiles down to normal speed
        for k, v in projectiles do
            v:SetVelocity(2):SetBallisticAcceleration(-0.15)
        end
    end,

    PlumeVelocityThread = function(self, plume)
        plume:SetVelocity(0,5.35 * self.PlumeVelocityScale,0)
        WaitTicks(6)
        plume:SetVelocity(0,23 * self.PlumeVelocityScale,0)
        WaitTicks(6)
        plume:SetVelocity(0,45 * self.PlumeVelocityScale,0)
        WaitTicks(14)
        plume:SetVelocity(0,27 * self.PlumeVelocityScale,0)
    end,

    PlumeThread = function(self, plume, scale)

        -- Anim Time : 1.0 sec
        plume:SetScale(0.229 * scale,0.229 * scale,0.229 * scale)
        plume:SetScaleVelocity(0.223 * scale,0.223 * scale,0.223 * scale)
        WaitTicks(24)

        -- Anim Time : 6.333 sec
        plume:SetScaleVelocity(0.086 * scale,0.086 * scale,0.086 * scale)
        WaitTicks(8)

        -- Anim Time : 7.0 sec
        plume:SetScaleVelocity(0.119 * scale,0.119 * scale,0.119 * scale)
        WaitTicks(11)

        -- Anim Time : 8.0 sec
        plume:SetScaleVelocity(0.106 * scale,0.106 * scale,0.106 * scale)
        WaitTicks(11)

        -- Anim Time : 9.0 sec
        plume:SetScaleVelocity(0.092 * scale,0.092 * scale,0.092 * scale)
        WaitTicks(11)

        -- Anim Time : 10.0 sec
        plume:SetScaleVelocity(0.077 * scale,0.077 * scale,0.077 * scale)
        WaitTicks(11)

        -- Anim Time : 11.0 sec
        plume:SetScaleVelocity(0.06 * scale,0.06 * scale,0.06 * scale)
        WaitTicks(11)

        -- Anim Time : 12.0 sec
        plume:SetScaleVelocity(0.016 * scale,0.016 * scale,0.016 * scale)
        WaitTicks(4)

        -- Anim Time : 12.333 sec
        plume:SetScaleVelocity(0.03 * scale,0.03 * scale,0.03 * scale)
        WaitTicks(8)

        -- Anim Time : 13.0 sec
        plume:SetScaleVelocity(0.043 * scale,0.043 * scale,0.043 * scale)
        WaitTicks(11)

        -- Anim Time : 14.0 sec
        plume:SetScaleVelocity(0.041 * scale,0.041 * scale,0.041 * scale)
        WaitTicks(11)

        -- Anim Time : 15.0 sec
        plume:SetScaleVelocity(0.038 * scale,0.038 * scale,0.038 * scale)
        WaitTicks(11)

        -- Anim Time : 16.0 sec
        plume:SetScaleVelocity(0.036 * scale,0.036 * scale,0.036 * scale)
        WaitTicks(11)

        -- Anim Time : 17.0 sec
        plume:SetScaleVelocity(0.033 * scale,0.033 * scale,0.033 * scale)
        WaitTicks(11)

        -- Anim Time : 18.0 sec
        plume:SetScaleVelocity(0.03 * scale,0.03 * scale,0.03 * scale)
        WaitTicks(11)

        -- Anim Time : 19.0 sec
        plume:SetScaleVelocity(0.027 * scale,0.027 * scale,0.027 * scale)
        WaitTicks(11)

        -- Anim Time : 20.0 sec
        plume:SetScaleVelocity(0.024 * scale,0.024 * scale,0.024 * scale)
        WaitTicks(11)

        -- Anim Time : 21.0 sec
        plume:SetScaleVelocity(0.02 * scale,0.02 * scale,0.02 * scale)
        WaitTicks(11)

        -- Anim Time : 22.0 sec
        plume:SetScaleVelocity(0.017 * scale,0.017 * scale,0.017 * scale)
        WaitTicks(11)

        -- Anim Time : 23.0 sec
        plume:SetScaleVelocity(0.013 * scale,0.013 * scale,0.013 * scale)
        WaitTicks(11)

        -- Anim Time : 24.0 sec
        plume:SetScaleVelocity(0.009 * scale,0.009 * scale,0.009 * scale)
        WaitTicks(11)

        -- Anim Time : 25.0 sec
        plume:SetScaleVelocity(0.005 * scale,0.005 * scale,0.005 * scale)
        WaitTicks(11)

        -- Anim Time : 26.0 sec
        plume:SetScaleVelocity(0.001 * scale,0.001 * scale,0.001 * scale)
    end,
}
TypeClass = CIFEMPFluxWarhead02