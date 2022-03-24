--****************************************************************************
--**
--**  File     :  /effects/Entities/SCUDeath01/SCUDeath01_script.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  SCU Death Explosion
--**
--**  Copyright � 2005,2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local NullShell = import('/lua/sim/defaultprojectiles.lua').NullShell
local EffectTemplate = import('/lua/EffectTemplates.lua')
local Util = import('/lua/utilities.lua')
local RandomFloat = Util.GetRandomFloat
local PlumeVelocityScale = 0.025

SCUDeath01 = Class(NullShell) {

    OnCreate = function(self)
        NullShell.OnCreate(self)
        local myBlueprint = self:GetBlueprint()
            
        -- Play the "NukeExplosion" sound
        if myBlueprint.Audio.NukeExplosion then
            self:PlaySound(myBlueprint.Audio.NukeExplosion)
        end
		
		-- Create thread that spawns and controls effects
        self:ForkThread(self.EffectThread)
    end,
     
    PassDamageData = function(self, damageData)
        NullShell.PassDamageData(self, damageData)
        local instigator = self:GetLauncher()
        if instigator == nil then
            instigator = self
        end

        -- Do Damage
        self:DoDamage( instigator, self.DamageData, nil )  
    end,
    
    OnImpact = function(self, targetType, targetEntity)
        self:Destroy()
    end,

    EffectThread = function(self)
        local army = self:GetArmy()
        local position = self:GetPosition()
        local projectilescale = 0.3
        -- Create full-screen glow flash
        CreateLightParticle(self, -1, army, 10, 4, 'beam_white_01', 'ramp_red_09')
        WaitSeconds( 0.25 )
        CreateLightParticle(self, -1, army, 23, 160, 'beam_white_01', 'ramp_red_09')
        WaitSeconds( 0.25 )
        CreateLightParticle(self, -1, army, 17, 170, 'beam_white_01', 'ramp_red_09')
        -- Mesh effects
        self.Plumeproj = self:CreateProjectile('/effects/EMPFluxWarhead/EMPFluxWarheadEffect01_proj.bp')
		self.Plumeproj:SetScale(projectilescale, projectilescale, projectilescale)
        self:ForkThread(self.PlumeThread, self.Plumeproj, self.Plumeproj:GetBlueprint().Display.UniformScale)
        self:ForkThread(self.PlumeVelocityThread, self.Plumeproj )

        self.Plumeproj2 = self:CreateProjectile('/effects/EMPFluxWarhead/EMPFluxWarheadEffect02_proj.bp')
		self.Plumeproj2:SetScale(projectilescale, projectilescale, projectilescale)
        self:ForkThread( self.PlumeThread, self.Plumeproj2, self.Plumeproj2:GetBlueprint().Display.UniformScale)
        self:ForkThread(self.PlumeVelocityThread, self.Plumeproj2 )

        self.Plumeproj3 = self:CreateProjectile('/effects/EMPFluxWarhead/EMPFluxWarheadEffect03_proj.bp')
		self.Plumeproj3:SetScale(projectilescale, projectilescale, projectilescale)
        self:ForkThread(self.PlumeThread, self.Plumeproj3, self.Plumeproj3:GetBlueprint().Display.UniformScale)
        self:ForkThread(self.PlumeVelocityThread, self.Plumeproj3 )

        -- Emitter Effects
        self:ForkThread(self.EmitterEffectsThread, self.Plumeproj)
        
        -- Create ground decals
        local orientation = RandomFloat( 0, 2 * math.pi )
        CreateDecal(position, orientation, 'nuke_scorch_001_albedo', '', 'Albedo', 20, 20, 1200, 0, army)

		-- Knockdown force rings
        DamageRing(self, position, 0.1, 15, 1, 'Force', true)
        WaitSeconds(0.1)
        DamageRing(self, position, 0.1, 15, 1, 'Force', true)
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
            CreateAttachedEmitter( plume, -1, army, v ):ScaleEmitter(0.5)
        end

        for k, v in self.NormalEffects do
            CreateEmitterAtEntity( self, army, v ):ScaleEmitter(0.3)
        end

        self:StarCloudDispersal()
        self:CreateOuterRingWaveSmokeRing()
    end,

    CreateOuterRingWaveSmokeRing = function(self) -- New
        local sides = 10*6
        local angle = (2*math.pi) / sides
        local velocity = 7
        local OffsetMod = 1
        local projectiles = {}
        local Deceleration = -0.45

        for i = 0, (sides-1) do
            local X = math.sin(i*angle)
            local Z = math.cos(i*angle)
            local proj = self:CreateProjectile('/effects/entities/SACUShockwaveEdgeThick/SACUShockwaveEdgeThick_proj.bp', X * OffsetMod , 2, Z * OffsetMod, X, 0, Z)
                :SetVelocity(velocity):SetAcceleration(Deceleration)
        end
    end,
	
    StarCloudDispersal = function(self)
        local numProjectiles = 3
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
            yVec = 0.3 + RandomFloat(-0.7, 0.9)
            zVec = math.cos(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation)) 
            velocity = 1.4 + (yVec * 3)
            table.insert(projectiles, self:CreateProjectile('/projectiles/CIFEMPFluxWarhead03/CIFEMPFluxWarhead03_proj.bp', 0, 0, 0, xVec, yVec, zVec):SetVelocity(velocity):SetBallisticAcceleration(0.5):SetScale(0.3, 0.3, 0.3):SetLifetime(10.0) )
        end

        WaitSeconds( 3 )

        -- Slow projectiles down to normal speed
        for k, v in projectiles do
            v:SetVelocity(2):SetBallisticAcceleration(-0.15)
        end
    end,

    PlumeVelocityThread = function(self, plume)
        plume:SetVelocity(0,3.35 * PlumeVelocityScale,0)
        WaitSeconds(0.5)
        plume:SetVelocity(0,13 * PlumeVelocityScale,0)
        WaitSeconds(0.5)
        plume:SetVelocity(0,25 * PlumeVelocityScale,0)
        WaitSeconds(1.3)
        plume:SetVelocity(0,17 * PlumeVelocityScale,0)
        WaitSeconds(3)
        plume:SetVelocity(0,8 * PlumeVelocityScale,0)
        WaitSeconds(0.5)
        plume:SetVelocity(0,-15 * PlumeVelocityScale,0)
        WaitSeconds(0.5)
        plume:SetVelocity(0,-8,0)
        WaitSeconds(4.5)
        plume:Destroy()
    end,

    PlumeThread = function(self, plume, bpscale )
		local scale = bpscale * 0.35
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
    end,
    
}

TypeClass = SCUDeath01

