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

local SIFInainoSACUEffect01 = '/effects/Entities/SIFInainoSACUEffect01/SIFInainoSACUEffect01_proj.bp' 
local SIFInainoSACUEffect02 = '/effects/Entities/SIFInainoSACUEffect02/SIFInainoSACUEffect02_proj.bp' 
local SIFInainoSACUEffect03 = '/effects/Entities/SIFInainoSACUEffect03/SIFInainoSACUEffect03_proj.bp' 
local SIFInainoSACUEffect04 = '/effects/Entities/SIFInainoSACUEffect04/SIFInainoSACUEffect04_proj.bp' 

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
        self:ForkThread(self.CreateInitialHit, army)
        self:ForkThread(self.CreateInitialBuildup, army)
		self:ForkThread(self.CreateGroundFingers )
		self:ForkThread(self.CreateInitialFingers )
        self:ForkThread(self.MainBlast, army)
		
        -- -- Create full-screen glow flash
        -- CreateLightParticle(self, -1, army, 10, 4, 'glow_02', 'ramp_quantum_warhead_flash_01')
        -- WaitSeconds( 0.25 )
        -- CreateLightParticle(self, -1, army, 13, 200, 'glow_03', 'ramp_quantum_warhead_flash_01')

		-- Knockdown force rings
        DamageRing(self, position, 0.1, 15, 1, 'Force', true)
        WaitSeconds(0.1)
        DamageRing(self, position, 0.1, 15, 1, 'Force', true)
    end,
    
    CreateInitialHit = function( self, army )
        for k, v in EffectTemplate.SIFSerSCUHit01 do
            emit = CreateEmitterAtEntity(self,army,v)
        end
    end,
    
    CreateInitialBuildup = function( self, army )
		WaitSeconds(2.0)
        for k, v in EffectTemplate.SIFSerSCUHit02 do
            emit = CreateEmitterAtEntity(self,army,v)
        end
    end,
	
    MainBlast = function( self, army )
		WaitSeconds(5.00)
		
        --------Create a light for this thing's flash.
        CreateLightParticle(self, -1, army, 60, 14, 'flare_lens_add_03', 'ramp_white_07' )
        
        -- Create our decals
        -- CreateDecal( self:GetPosition(), RandomFloat(0.0,6.28), 'Scorch_012_albedo', '', 'Albedo', 80, 80, 1000, 0, army)

		-- Create explosion effects
        for k, v in EffectTemplate.SIFSerSCUDetonate01 do
            emit = CreateEmitterAtEntity(self,army,v)
        end
        
        self:CreatePlumes()
        
        ------self:ShakeCamera( radius, maxShakeEpicenter, minShakeAtRadius, interval )
        -- self:ShakeCamera( 55, 10, 0, 2.5 )
		
        -- Create ground decals
        local orientation = RandomFloat( 0, 2 * math.pi )
        local position = self:GetPosition()
        CreateDecal(position, orientation, 'Scorch_012_albedo', '', 'Albedo', 65, 65, 1000, 0, army)
        CreateDecal(position, orientation, 'Crater01_normals', '', 'Normals', 10, 10, 1200, 0, army)

		WaitSeconds(0.3)
        
        -- Create upward moving smoke plume
        local plume = self:CreateProjectile( SIFInainoSACUEffect04, 0, 0, 0, 0, 0, 0)
        plume:SetLifetime(2.0)
        plume:SetVelocity(2.0)
        plume:SetAcceleration(-4.35)
        plume:SetCollision(false)
        plume:SetVelocityAlign(true)
        
        -- Create explosion dust ring
        local vx, vy, vz = self:GetVelocity()
        local num_projectiles = 8
        local horizontal_angle = (2*math.pi) / num_projectiles
        local angleInitial = RandomFloat( 0, horizontal_angle )  
        local xVec, zVec
        local offsetMultiple = 5.0
        local px, pz

        for i = 0, (num_projectiles -1) do
            xVec = (math.sin(angleInitial + (i*horizontal_angle)))
            zVec = (math.cos(angleInitial + (i*horizontal_angle)))
            px = (offsetMultiple*xVec)
            pz = (offsetMultiple*zVec)
            
            local proj = self:CreateProjectile( SIFInainoSACUEffect03, px, 1, pz, xVec, 0, zVec )
            proj:SetLifetime(4.0)
            proj:SetVelocity(5.0)
            proj:SetAcceleration(-0.35)
        end
    end,
    
    CreateGroundFingers = function(self)
		WaitSeconds(1.0)
        -- outward rushing fingers that spawn the upward fingers
        local num_projectiles = 3
        local horizontal_angle = (2*math.pi) / num_projectiles
        local xVec, zVec
        local px, pz
     
        for i = 0, (num_projectiles -1) do
            xVec = math.sin(i*horizontal_angle) 
            zVec = math.cos(i*horizontal_angle) 
            px = 1 * xVec
            pz = 1 * zVec
            
            local proj = self:CreateProjectile( SIFInainoSACUEffect02, px, 2.0, pz, xVec, 0.0, zVec )
            proj:SetVelocity(5.0)
        end
    end,
    
    CreateInitialFingers = function(self)
		WaitSeconds(3.0)
        -- upward rising fingers that join to form explosion
        local num_projectiles = 3
        local horizontal_angle = (2*math.pi) / num_projectiles
        local xVec, zVec
        local px, pz
     
        for i = 0, (num_projectiles -1) do
            xVec = math.sin(i*horizontal_angle) 
            zVec = math.cos(i*horizontal_angle) 
            px = 10.0 * xVec
            pz = 10.0 * zVec
            
            local proj = self:CreateProjectile( SIFInainoSACUEffect01, px, 3.0, pz, -xVec, 3.0, -zVec )
            proj:SetVelocity(16)
            proj:SetLifetime(2.0)
            proj:SetBallisticAcceleration(-5.0)
        end
    end,
    
    CreatePlumes = function(self)
        -- Create fireball plumes to accentuate the explosive detonation
        local num_projectiles = 5
        local horizontal_angle = (2*math.pi) / num_projectiles
        local angleInitial = RandomFloat( 0, horizontal_angle )  
        local xVec, yVec, zVec
        local angleVariation = 1.0
        local px, py, pz
     
        for i = 0, (num_projectiles -1) do
            xVec = math.sin(angleInitial + (i*horizontal_angle) + RandomFloat(-angleVariation, angleVariation) ) 
            yVec = RandomFloat( 0.7, 2.8 ) + 2.0
            zVec = math.cos(angleInitial + (i*horizontal_angle) + RandomFloat(-angleVariation, angleVariation) ) 
            px = RandomFloat( 0.5, 1.0 ) * xVec
            py = RandomFloat( 0.5, 1.0 ) * yVec
            pz = RandomFloat( 0.5, 1.0 ) * zVec
            
            local proj = self:CreateProjectile( SIFInainoSACUEffect04, px, py, pz, xVec, yVec, zVec )
            proj:SetVelocity(RandomFloat( 2.5, 10  ))
            proj:SetBallisticAcceleration(-4.8)
        end        
    end,
}

TypeClass = SCUDeath01

