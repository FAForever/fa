------------------------------------------------------------------------------
-- File     :  /projectiles/CIFEMPFluxWarhead02/CIFEMPFluxWarhead02_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  EMP Flux Warhead Impact effects projectile
-- Copyright � 2005,2006 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------

local NullShell = import('/lua/sim/defaultprojectiles.lua').NullShell
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

CIFEMPFluxWarhead02 = Class(NullShell) {
    NukeOuterRingDamage = 0,
    NukeOuterRingRadius = 0,
    NukeOuterRingTicks = 0,
    NukeOuterRingTotalTime = 0,

    NukeInnerRingDamage = 0,
    NukeInnerRingRadius = 0,
    NukeInnerRingTicks = 0,
    NukeInnerRingTotalTime = 0,

    NukeMeshScale = 8.5725,
    PlumeVelocityScale = 0.1,

    -- NOTE: This script has been modified to REQUIRE that data is passed in!  The nuke won't explode until this happens!

    PassData = function(self, Data)
        if Data.NukeOuterRingDamage then self.NukeOuterRingDamage = Data.NukeOuterRingDamage end
        if Data.NukeOuterRingRadius then self.NukeOuterRingRadius = Data.NukeOuterRingRadius end
        if Data.NukeOuterRingTicks then self.NukeOuterRingTicks = Data.NukeOuterRingTicks end
        if Data.NukeOuterRingTotalTime then self.NukeOuterRingTotalTime = Data.NukeOuterRingTotalTime end
        if Data.NukeInnerRingDamage then self.NukeInnerRingDamage = Data.NukeInnerRingDamage end
        if Data.NukeInnerRingRadius then self.NukeInnerRingRadius = Data.NukeInnerRingRadius end
        if Data.NukeInnerRingTicks then self.NukeInnerRingTicks = Data.NukeInnerRingTicks end
        if Data.NukeInnerRingTotalTime then self.NukeInnerRingTotalTime = Data.NukeInnerRingTotalTime end

        self:CreateNuclearExplosion()
    end,

    CreateNuclearExplosion = function(self)
        -- Light and Camera Shake
        CreateLightParticle(self, -1, self:GetArmy(), 200, 200, 'beam_white_01', 'ramp_red_09')
        self:ShakeCamera( 75, 3, 0, 20 )

        -- Mesh effects
        self.Plumeproj = self:CreateProjectile('/effects/EMPFluxWarhead/EMPFluxWarheadEffect01_proj.bp')
        self:ForkThread(self.PlumeThread, self.Plumeproj, self.Plumeproj:GetBlueprint().Display.UniformScale)
        self:ForkThread(self.PlumeVelocityThread, self.Plumeproj )

        self.Plumeproj2 = self:CreateProjectile('/effects/EMPFluxWarhead/EMPFluxWarheadEffect02_proj.bp')
        self:ForkThread( self.PlumeThread, self.Plumeproj2, self.Plumeproj2:GetBlueprint().Display.UniformScale)
        self:ForkThread(self.PlumeVelocityThread, self.Plumeproj2 )

        self.Plumeproj3 = self:CreateProjectile('/effects/EMPFluxWarhead/EMPFluxWarheadEffect03_proj.bp')
        self:ForkThread(self.PlumeThread, self.Plumeproj3, self.Plumeproj3:GetBlueprint().Display.UniformScale)
        self:ForkThread(self.PlumeVelocityThread, self.Plumeproj3 )

        -- Emitter Effects
        self:ForkThread(self.EmitterEffectsThread, self.Plumeproj)
        
        -- Do Damage
        self:ForkThread(self.InnerRingDamage)
        self:ForkThread(self.OuterRingDamage)
        self:ForkThread(self.ForceThread)
    end,
    
    OuterRingDamage = function(self)
        local myPos = self:GetPosition()
        if self.NukeOuterRingTotalTime == 0 then
            DamageArea(self:GetLauncher(), myPos, self.NukeOuterRingRadius, self.NukeOuterRingDamage, self.DamageData.DamageType, true, true)
        else
            local ringWidth = ( self.NukeOuterRingRadius / self.NukeOuterRingTicks )
            local tickLength = ( self.NukeOuterRingTotalTime / self.NukeOuterRingTicks )
            -- Since we're not allowed to have an inner radius of 0 in the DamageRing function,
            -- I'm manually executing the first tick of damage with a DamageArea function.
            DamageArea(self:GetLauncher(), myPos, ringWidth, self.NukeOuterRingDamage, 'Normal', true, true)
            WaitSeconds(tickLength)
            for i = 2, self.NukeOuterRingTicks do
                DamageRing(self:GetLauncher(), myPos, ringWidth * (i - 1), ringWidth * i, self.NukeOuterRingDamage, self.DamageData.DamageType, true, true)
                WaitSeconds(tickLength)
            end
        end
    end,

    InnerRingDamage = function(self)
        local myPos = self:GetPosition()
        if self.NukeInnerRingTotalTime == 0 then
            DamageArea(self:GetLauncher(), myPos, self.NukeInnerRingRadius, self.NukeInnerRingDamage, self.DamageData.DamageType, true, true)
        else
            local ringWidth = ( self.NukeInnerRingRadius / self.NukeInnerRingTicks )
            local tickLength = ( self.NukeInnerRingTotalTime / self.NukeInnerRingTicks )
            -- Since we're not allowed to have an inner radius of 0 in the DamageRing function,
            -- I'm manually executing the first tick of damage with a DamageArea function.
            DamageArea(self:GetLauncher(), myPos, ringWidth, self.NukeInnerRingDamage, 'Normal', true, true)
            WaitSeconds(tickLength)
            for i = 2, self.NukeInnerRingTicks do
                DamageRing(self:GetLauncher(), myPos, ringWidth * (i - 1), ringWidth * i, self.NukeInnerRingDamage, self.DamageData.DamageType, true, true)
                WaitSeconds(tickLength)
            end
        end
    end,   

    -- Knocks down trees
    ForceThread = function(self)
        local pos = self:GetPosition()
        pos[2] = GetSurfaceHeight(pos[1], pos[3]) + 1
        DamageArea(self, pos, 5, 1, 'Force', true)
        WaitSeconds(0.5)
        local army = self:GetArmy()
        CreateDecal(self:GetPosition(), RandomFloat(0,2*math.pi), 'nuke_scorch_001_albedo', '', 'Albedo', 28, 28, 500, 0, army)
        DamageRing(self, pos, 4, 15, 1, 'Force', true)
        WaitSeconds(0.5)
        DamageArea(self, pos, 15, 1, 'Force', true)
    end,

    -- Effects attached to moving nuke projectile plume
    PlumeEffects = {'/effects/emitters/empfluxwarhead_concussion_ring_02_emit.bp',
                    '/effects/emitters/empfluxwarhead_01_emit.bp',
                    '/effects/emitters/empfluxwarhead_02_emit.bp',
                    '/effects/emitters/empfluxwarhead_03_emit.bp'},

    -- Effects not attached but created at the position of CIFEMPFluxWarhead02
    NormalEffects = {'/effects/emitters/empfluxwarhead_concussion_ring_01_emit.bp',
                     '/effects/emitters/empfluxwarhead_fallout_01_emit.bp'},

    EmitterEffectsThread = function(self, plume)
        local army = self:GetArmy()

        for k, v in self.PlumeEffects do
            CreateAttachedEmitter( plume, -1, army, v )
        end

        for k, v in self.NormalEffects do
            CreateEmitterAtEntity( self, army, v )
        end

        self:StarCloudDispersal()
    end,

    StarCloudDispersal = function(self)
        local numProjectiles = 5
        local angle = (2*math.pi) / numProjectiles
        local angleInitial = RandomFloat( 0, angle )
        local angleVariation = angle * 0.5
        local projectiles = {}

        local xVec = 0 
        local yVec = 0.3
        local zVec = 0
        local velocity = 0

        -- yVec -0.2, requires 2 initial velocity to start
        -- yVec 0.3, requires 3 initial velocity to start
        -- yVec 1.8, requires 8.5 initial velocity to start

        -- Launch projectiles at semi-random angles away from the sphere, with enough
        -- initial velocity to escape sphere core
        for i = 0, (numProjectiles -1) do
            xVec = math.sin(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))
            yVec = 0.3 + RandomFloat(-0.8, 1.0)
            zVec = math.cos(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation)) 
            velocity = 2.4 + (yVec * 3)
            table.insert(projectiles, self:CreateProjectile('/projectiles/CIFEMPFluxWarhead03/CIFEMPFluxWarhead03_proj.bp', 0, 0, 0, xVec, yVec, zVec):SetVelocity(velocity):SetBallisticAcceleration(1.0) )
        end

        WaitSeconds( 3 )

        -- Slow projectiles down to normal speed
        for k, v in projectiles do
            v:SetVelocity(2):SetBallisticAcceleration(-0.15)
        end
    end,

    PlumeVelocityThread = function(self, plume)
        plume:SetVelocity(0,5.35 * self.PlumeVelocityScale,0)
        WaitSeconds(0.5)
        plume:SetVelocity(0,23 * self.PlumeVelocityScale,0)
        WaitSeconds(0.5)
        plume:SetVelocity(0,45 * self.PlumeVelocityScale,0)
        WaitSeconds(1.3)
        plume:SetVelocity(0,27 * self.PlumeVelocityScale,0)
    end,

    PlumeThread = function(self, plume, scale )

        -- Anim Time : 1.0 sec
        plume:SetScale(0.229 * scale,0.229 * scale,0.229 * scale)
        plume:SetScaleVelocity(0.223 * scale,0.223 * scale,0.223 * scale)
        WaitSeconds(2.3)

        -- Anim Time : 6.333 sec
        plume:SetScaleVelocity(0.086 * scale,0.086 * scale,0.086 * scale)
        WaitSeconds(0.7)

        -- Anim Time : 7.0 sec
        plume:SetScaleVelocity(0.119 * scale,0.119 * scale,0.119 * scale)
        WaitSeconds(1)

        -- Anim Time : 8.0 sec
        plume:SetScaleVelocity(0.106 * scale,0.106 * scale,0.106 * scale)
        WaitSeconds(1)

        -- Anim Time : 9.0 sec
        plume:SetScaleVelocity(0.092 * scale,0.092 * scale,0.092 * scale)
        WaitSeconds(1)

        -- Anim Time : 10.0 sec
        plume:SetScaleVelocity(0.077 * scale,0.077 * scale,0.077 * scale)
        WaitSeconds(1)

        -- Anim Time : 11.0 sec
        plume:SetScaleVelocity(0.06 * scale,0.06 * scale,0.06 * scale)
        WaitSeconds(1)

        -- Anim Time : 12.0 sec
        plume:SetScaleVelocity(0.016 * scale,0.016 * scale,0.016 * scale)
        WaitSeconds(0.3)

        -- Anim Time : 12.333 sec
        plume:SetScaleVelocity(0.03 * scale,0.03 * scale,0.03 * scale)
        WaitSeconds(0.7)

        -- Anim Time : 13.0 sec
        plume:SetScaleVelocity(0.043 * scale,0.043 * scale,0.043 * scale)
        WaitSeconds(1)

        -- Anim Time : 14.0 sec
        plume:SetScaleVelocity(0.041 * scale,0.041 * scale,0.041 * scale)
        WaitSeconds(1)

        -- Anim Time : 15.0 sec
        plume:SetScaleVelocity(0.038 * scale,0.038 * scale,0.038 * scale)
        WaitSeconds(1)

        -- Anim Time : 16.0 sec
        plume:SetScaleVelocity(0.036 * scale,0.036 * scale,0.036 * scale)
        WaitSeconds(1)

        -- Anim Time : 17.0 sec
        plume:SetScaleVelocity(0.033 * scale,0.033 * scale,0.033 * scale)
        WaitSeconds(1)

        -- Anim Time : 18.0 sec
        plume:SetScaleVelocity(0.03 * scale,0.03 * scale,0.03 * scale)
        WaitSeconds(1)

        -- Anim Time : 19.0 sec
        plume:SetScaleVelocity(0.027 * scale,0.027 * scale,0.027 * scale)
        WaitSeconds(1)

        -- Anim Time : 20.0 sec
        plume:SetScaleVelocity(0.024 * scale,0.024 * scale,0.024 * scale)
        WaitSeconds(1)

        -- Anim Time : 21.0 sec
        plume:SetScaleVelocity(0.02 * scale,0.02 * scale,0.02 * scale)
        WaitSeconds(1)

        -- Anim Time : 22.0 sec
        plume:SetScaleVelocity(0.017 * scale,0.017 * scale,0.017 * scale)
        WaitSeconds(1)

        -- Anim Time : 23.0 sec
        plume:SetScaleVelocity(0.013 * scale,0.013 * scale,0.013 * scale)
        WaitSeconds(1)

        -- Anim Time : 24.0 sec
        plume:SetScaleVelocity(0.009 * scale,0.009 * scale,0.009 * scale)
        WaitSeconds(1)

        -- Anim Time : 25.0 sec
        plume:SetScaleVelocity(0.005 * scale,0.005 * scale,0.005 * scale)
        WaitSeconds(1)

        -- Anim Time : 26.0 sec
        plume:SetScaleVelocity(0.001 * scale,0.001 * scale,0.001 * scale)
    end,
}

TypeClass = CIFEMPFluxWarhead02
