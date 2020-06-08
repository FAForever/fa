#****************************************************************************
#**
#**  File     :  /data/projectiles/AIFFragmentationSensorShell01/AIFFragmentationSensorShell01_script.lua
#**  Author(s):  Drew Staltman, Gordon Duclos
#**
#**  Summary  :  Aeon Quantic Cluster Fragmentation Sensor shell script,XAB2307
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local EffectTemplate = import('/lua/EffectTemplates.lua')
local AArtilleryFragmentationSensorShellProjectile = import('/lua/aeonprojectiles.lua').AArtilleryFragmentationSensorShellProjectile
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

AIFFragmentationSensorShell01 = Class(AArtilleryFragmentationSensorShellProjectile) {
               
    OnImpact = function(self, TargetType, TargetEntity) 
        local FxFragEffect = EffectTemplate.Aeon_QuanticClusterFrag01
        local ChildProjectileBP = '/projectiles/AIFFragmentationSensorShell02/AIFFragmentationSensorShell02_proj.bp'  
        
        # Split effects
        for k, v in FxFragEffect do
            CreateEmitterAtBone( self, -1, self:GetArmy(), v )
        end
        
        local vx, vy, vz = self:GetVelocity()
        local velocity = 16
    
		# One initial projectile following same directional path as the original
        self:CreateChildProjectile(ChildProjectileBP):SetVelocity(vx,0.8*vy, vz):SetVelocity(velocity):PassDamageData(self.DamageData)
   		
		# Create several other projectiles in a dispersal pattern
		        local numProjectiles = 5
		        local angle = (2*math.pi) / numProjectiles
		        local angleInitial = RandomFloat( 0, angle )
		        
		        # Randomization of the spread
		        local angleVariation = angle * 8 # Adjusts angle variance spread
		        local spreadMul = 0.8 # Adjusts the width of the dispersal        
       
        local xVec = 0 
        local yVec = vy*0.8
        local zVec = 0

        # Launch projectiles at semi-random angles away from split location
        for i = 0, (numProjectiles -1) do
            xVec = vx + (math.sin(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul
            zVec = vz + (math.cos(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul 
            local proj = self:CreateChildProjectile(ChildProjectileBP)
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
    end,
}
TypeClass = AIFFragmentationSensorShell01