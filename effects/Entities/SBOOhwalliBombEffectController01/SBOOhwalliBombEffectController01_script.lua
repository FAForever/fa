--****************************************************************************
--**
--**  File     :  \data\effects\Entities\SBOOhwalliBombEffectController01\SBOOhwalliBombEffectController01_script.lua
--**  Author(s):  Greg Kohne
--**
--**  Summary  :  Ohwalli Bomb effect controller script, non-damaging
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat
local RandomInt = import("/lua/utilities.lua").GetRandomInt
local EffectTemplate = import("/lua/effecttemplates.lua")

local BaseRingRiftEffects = {
	'/effects/Entities/SBOOhwalliBombEffect03/SBOOhwalliBombEffect03_proj.bp',
	'/effects/Entities/SBOOhwalliBombEffect04/SBOOhwalliBombEffect04_proj.bp',
	'/effects/Entities/SBOOhwalliBombEffect05/SBOOhwalliBombEffect05_proj.bp',
}         
local SBOOhwalliBombEffect01 = '/effects/Entities/SBOOhwalliBombEffect01/SBOOhwalliBombEffect01_proj.bp'         
local SBOOhwalliBombEffect06 = '/effects/Entities/SBOOhwalliBombEffect06/SBOOhwalliBombEffect06_proj.bp'

SBOOhwalliBombEffectController01 = Class(NullShell) {
    
    OnCreate = function( self )  
		NullShell.OnCreate(self)
		local army = self:GetArmy()

        self:ForkThread(self.CreateInitialBuildup, army)
		self:ForkThread(self.CreateRifts, army )
        self:ForkThread(self.MainBlast, army)
    end,
    
    CreateInitialBuildup = function( self, army )
		WaitSeconds(1.0)
        for k, v in EffectTemplate.SOhwalliBombHit01 do
            emit = CreateEmitterAtEntity(self,army,v)
        end       
    end,

    CreateRifts = function(self, army )
        -- Create projectiles in a dispersal pattern, that create x/z direction that 
        -- the effects emitters use a path.
        
        local vx, vy, vz = self:GetVelocity()
        local velocity = 70
        local num_projectiles = 3       
        local horizontal_angle = (2*math.pi) / num_projectiles
        local angleInitial = RandomFloat( 0, horizontal_angle )        
        local angleVariation = 0.2  --Adjusts horizontal_angle variance spread
        local xVec, zVec
        
        ------Create pre-buildup effects------
        for k, v in EffectTemplate.SOhwalliBombHit02 do
            emit = CreateEmitterAtEntity(self,army,v)
        end  

        for i = 0, (num_projectiles -1) do
            xVec = math.sin(angleInitial + (i*horizontal_angle) + RandomFloat(-angleVariation, angleVariation) ) 
            zVec = math.cos(angleInitial + (i*horizontal_angle) + RandomFloat(-angleVariation, angleVariation) ) 
           
            local proj = self:CreateProjectile(BaseRingRiftEffects[RandomInt(1,3)], xVec * 1.2, 2, zVec * 1.2, xVec, 0, zVec)
            proj:SetVelocity(velocity * RandomFloat(0.7,1.4))
            proj:SetLifetime(0.4)
        end
    end,
    
    MainBlast = function( self, army )
		WaitSeconds(2.5)
		
        --------Create a light for this thing's flash.
        CreateLightParticle(self, -1, self:GetArmy(), 80, 14, 'flare_lens_add_03', 'ramp_white_07' )
        
        -- Create our decals
        CreateDecal( self:GetPosition(), RandomFloat(0.0,6.28), 'Scorch_012_albedo', '', 'Albedo', 80, 80, 1000, 0, self:GetArmy())          

		-- Create explosion effects
        for k, v in EffectTemplate.SOhwalliDetonate01 do
            emit = CreateEmitterAtEntity(self,army,v)
        end
        
        self:CreatePlumes()
        
        ------self:ShakeCamera( radius, maxShakeEpicenter, minShakeAtRadius, interval )
        self:ShakeCamera( 55, 10, 0, 2.5 )        

		WaitSeconds(0.3)
        
        -- Create upward moving smoke plume
        local plume = self:CreateProjectile('/effects/entities/SBOOhwalliBombEffect02/SBOOhwalliBombEffect02_proj.bp', 0, 3, 0, 0, 0, 0)
        plume:SetLifetime(1.35)
        plume:SetCollision(false)
        plume:SetVelocityAlign(true)
        
        -- Create explosion dust ring
        local vx, vy, vz = self:GetVelocity()
        local num_projectiles = 16        
        local horizontal_angle = (2*math.pi) / num_projectiles
        local angleInitial = RandomFloat( 0, horizontal_angle )  
        local xVec, zVec
        local offsetMultiple = 10.0
        local px, pz

        for i = 0, (num_projectiles -1) do            
            xVec = (math.sin(angleInitial + (i*horizontal_angle)))
            zVec = (math.cos(angleInitial + (i*horizontal_angle)))
            px = (offsetMultiple*xVec)
            pz = (offsetMultiple*zVec)
            
            local proj = self:CreateProjectile( SBOOhwalliBombEffect06, px, 1, pz, xVec, 0, zVec )
            proj:SetLifetime(2.0)
            proj:SetVelocity(15.0)
            proj:SetAcceleration(-10.0)            
        end
    end,
    
    CreatePlumes = function(self)
        -- Create fireball plumes to accentuate the explosive detonation
        local num_projectiles = 7        
        local horizontal_angle = (2*math.pi) / num_projectiles
        local angleInitial = RandomFloat( 0, horizontal_angle )  
        local xVec, yVec, zVec
        local angleVariation = 0.5        
        local px, py, pz        
     
        for i = 0, (num_projectiles -1) do            
            xVec = math.sin(angleInitial + (i*horizontal_angle) + RandomFloat(-angleVariation, angleVariation) ) 
            yVec = RandomFloat( 0.7, 2.8 ) + 2.0
            zVec = math.cos(angleInitial + (i*horizontal_angle) + RandomFloat(-angleVariation, angleVariation) ) 
            px = RandomFloat( 0.5, 1.0 ) * xVec
            py = RandomFloat( 0.5, 1.0 ) * yVec
            pz = RandomFloat( 0.5, 1.0 ) * zVec
            
            local proj = self:CreateProjectile( SBOOhwalliBombEffect01, px, py, pz, xVec, yVec, zVec )
            proj:SetVelocity(RandomFloat( 5, 15  ))
            proj:SetBallisticAcceleration(-4.8)            
        end        
    end,
}
TypeClass = SBOOhwalliBombEffectController01
