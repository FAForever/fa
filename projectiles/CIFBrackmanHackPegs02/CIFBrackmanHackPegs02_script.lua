--****************************************************************************
--**
--**  File     :  /data/projectiles/CIFBrackmanHackPegs02/CIFBrackmanHackPegs02_script.lua
--** 
--**  Author(s):  Greg Kohne
--**
--**  Summary  :  Brackman Peg Launching Projectile script
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TargetPos
local RandomInt = import('/lua/utilities.lua').GetRandomInt
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local EffectTemplate = import('/lua/EffectTemplates.lua')

------This one should just like be something kind of new compared to the older version
CIFBrackmanHackPegs02 = Class(import('/lua/cybranprojectiles.lua').CDFBrackmanHackPegProjectile02) {

    OnImpact = function(self, TargetType, TargetEntity)
        ------CDFBrackmanHackPegProjectile02.OnImpact(TargetType,TargetEntity) 
        self:SetVelocity(0)
        self:SetBallisticAcceleration(0)
        self:ForkThread(self.WaitingForDeath)
        self.CreateImpactEffects( self, self:GetArmy(), self.FxImpactLand, 1 )
        for k, v in EffectTemplate.CBrackmanCrabPegAmbient01 do
			CreateEmitterOnEntity( self, self:GetArmy(), v )
		end			
    end,
    
    SetTargetPosition= function(self, NewPosition) 
        TargetPos= NewPosition
    end,
        
    WaitingForDeath = function(self)
        local WaitTime
        local PrimaryHackProjectiles = {
                  '/effects/Entities/BrackmanQAIHackCircuitryEffect01/BrackmanQAIHackCircuitryEffect01_proj.bp',
                  '/effects/Entities/BrackmanQAIHackCircuitryEffect02/BrackmanQAIHackCircuitryEffect02_proj.bp',
                  '/effects/Entities/BrackmanQAIHackCircuitryEffect03/BrackmanQAIHackCircuitryEffect03_proj.bp',
        }
        local num_projectiles= 50
        for i = 0, num_projectiles do
            WaitTime= ( 0.4+RandomFloat(-0.2,0.2) )  ------Get how long to wait before launching the next one.
            WaitSeconds( WaitTime )
            local pos = self:GetPosition()
            
            local vel_x= (TargetPos[1]-pos[1])
            local vel_y= (TargetPos[2]-pos[2])
            local vel_z= (TargetPos[3]-pos[3])
            
            ------Start out the hacking cicuitry with at the position of the hack pegs for this one.
            self:CreateProjectile(PrimaryHackProjectiles[RandomInt(1,3)], 0.0, 1.0, 0.0, vel_x, vel_y, vel_z):SetCollision(false):SetLifetime(0.3):SetBallisticAcceleration(0,0,0):SetVelocity(15.0)
        end
        
        self:Destroy()
    end,
}
TypeClass = CIFBrackmanHackPegs02
