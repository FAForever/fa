--****************************************************************************
--**
--**  File     :  /data/projectiles/AIFFragmentationSensorShell02/AIFFragmentationSensorShell02_script.lua
--**  Author(s):  Drew Staltman, Gordon Duclos
--**
--**  Summary  :  Aeon Quantic Cluster Fragmentation Sensor shell script,XAB2307
--**				 Child Projectile after 1st split	
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local EffectTemplate = import("/lua/effecttemplates.lua")
local AArtilleryFragmentationSensorShellProjectile = import("/lua/aeonprojectiles.lua").AArtilleryFragmentationSensorShellProjectile02
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat

AIFFragmentationSensorShell02 = Class(AArtilleryFragmentationSensorShellProjectile) {
               
    OnImpact = function(self, TargetType, TargetEntity) 
        if TargetType != 'Shield' then
	        local FxFragEffect = EffectTemplate.Aeon_QuanticClusterFrag02 
            local bp = self:GetBlueprint().Physics
	        
	        -- Split effects
	        for k, v in FxFragEffect do
	            CreateEmitterAtBone( self, -1, self:GetArmy(), v )
	        end
	        
	        local vx, vy, vz = self:GetVelocity()
	        local velocity = 12
	    
			-- One initial projectile following same directional path as the original
            self:CreateChildProjectile(bp.FragmentId):SetVelocity(vx,0.8*vy, vz):SetVelocity(velocity):PassDamageData(self.DamageData)
	   		
			-- Create several other projectiles in a dispersal pattern
            local numProjectiles = bp.Fragments - 1
            local angle = (2 * math.pi) / numProjectiles
            local angleInitial = RandomFloat( 0, angle )
            
            -- Randomization of the spread
            local angleVariation = angle * 13 -- Adjusts angle variance spread
            local spreadMul = 0.4 -- Adjusts the width of the dispersal        
			               
	        local xVec = 0 
	        local yVec = vy*0.8
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
	        local pos = self:GetPosition()
	        local spec = {
	            X = pos[1],
	            Z = pos[3],
	            Radius = self.Data.Radius,
	            LifeTime = self.Data.Lifetime,
	            Army = self.Data.Army,
	            Omni = false,
	            WaterVision = false,
	        }
	        self:Destroy()
		else
	        self:DoDamage( self, self.DamageData, TargetEntity)
	        self:OnImpactDestroy(TargetType, TargetEntity)
        end
    end,
}
TypeClass = AIFFragmentationSensorShell02