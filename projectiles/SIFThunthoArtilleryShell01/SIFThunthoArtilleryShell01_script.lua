--****************************************************************************
--**
--**  File     :  /data/projectiles/SIFThunthoArtilleryShell01/SIFThunthoArtilleryShell01_script.lua
--**  Author(s):  Gordon Duclos, Aaron Lundquist
--**
--**  Summary  :  Thuntho Artillery Shell Projectile script, XSL0103
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local EffectTemplate = import('/lua/EffectTemplates.lua')
local SThunthoArtilleryShell = import('/lua/seraphimprojectiles.lua').SThunthoArtilleryShell
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

SIFThunthoArtilleryShell01 = Class(SThunthoArtilleryShell) {
               
    OnImpact = function(self, TargetType, TargetEntity) 
        
        local FxFragEffect = EffectTemplate.SThunderStormCannonProjectileSplitFx 
        local bp = self.Blueprint.Physics
              
        ------ Split effects
        for k, v in FxFragEffect do
            CreateEmitterAtEntity( self, self.Army, v )
        end
        
        local vx, vy, vz = self:GetVelocity()
        local velocity = 18
    
		-- One initial projectile following same directional path as the original
        --self:CreateChildProjectile(bp.FragmentId):SetVelocity(vx, vy, vz):SetVelocity(velocity):PassDamageData(self.DamageData)
   		
		-- Create several other projectiles in a dispersal pattern
        local numProjectiles = bp.Fragments
        
        local angle = (2 * math.pi) / numProjectiles
        local angleInitial = RandomFloat( 0, angle )
        
        -- Randomization of the spread
        local angleVariation = angle * 0.8 -- Adjusts angle variance spread
        local spreadMul = 0.15 -- Adjusts the width of the dispersal        
        
        --vy= -0.8
        
        local xVec = 0
        local yVec = vy
        local zVec = 0
     

        -- Launch projectiles at semi-random angles away from split location
        for i = 0, numProjectiles - 1 do
            xVec = vx + (math.sin(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul
            zVec = vz + (math.cos(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul 
            local proj = self:CreateChildProjectile(bp.FragmentId)
            proj:SetVelocity(xVec,yVec,zVec)
            proj:SetVelocity(velocity)
            proj:PassDamageData(self.DamageData)                        
        end
        
        self:Destroy()
    end
}

TypeClass = SIFThunthoArtilleryShell01