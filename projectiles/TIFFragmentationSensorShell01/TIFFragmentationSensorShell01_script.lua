--
-- Terran Fragmentation/Sensor Shells
--
local EffectTemplate = import("/lua/effecttemplates.lua")
local TArtilleryProjectile = import("/lua/terranprojectiles.lua").TArtilleryProjectile
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat
local VizMarker = import("/lua/sim/vizmarker.lua").VizMarker

TIFFragmentationSensorShell01 = Class(TArtilleryProjectile) {
               
    OnImpact = function(self, TargetType, TargetEntity) 

        local FxFragEffect = EffectTemplate.TFragmentationSensorShellFrag 
        local bp = self:GetBlueprint().Physics
              
        
        -- Split effects
        for k, v in FxFragEffect do
            CreateEmitterAtEntity( self, self:GetArmy(), v )
        end
        
        local vx, vy, vz = self:GetVelocity()
        local velocity = 6
    
		-- One initial projectile following same directional path as the original
        self:CreateChildProjectile(bp.FragmentId):SetVelocity(vx, vy, vz):SetVelocity(velocity):PassDamageData(self.DamageData)
   		
		-- Create several other projectiles in a dispersal pattern
        local numProjectiles = bp.Fragments - 1
        local angle = (2 * math.pi) / numProjectiles
        local angleInitial = RandomFloat( 0, angle )
        
        -- Randomization of the spread
        local angleVariation = angle * 0.35 -- Adjusts angle variance spread
        local spreadMul = 0.5 -- Adjusts the width of the dispersal        
        
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
        local vizEntity = VizMarker(spec)
        self:Destroy()
    end,
    
    

}

TypeClass = TIFFragmentationSensorShell01