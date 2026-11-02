local CollisionBeam = import("/lua/sim/collisionbeam.lua").CollisionBeam
local EffectTemplate = import("/lua/effecttemplates.lua")
local Util = import("/lua/utilities.lua")

local SCCollisionBeam = import("/lua/sim/collisionbeams/sccollisionbeam.lua").SCCollisionBeam

-- Used by Novax Defense Satellite XEA0002's TOrbitalDeathLaserBeamWeapon
---@class OrbitalDeathLaserCollisionBeam : SCCollisionBeam
OrbitalDeathLaserCollisionBeam = Class(SCCollisionBeam) { 
    TerrainImpactType = 'LargeBeam02',
    TerrainImpactScale = 1,

    FxBeamStartPoint = EffectTemplate.TOrbitalDeathLaserMuzzleFlash01,
    FxBeam = EffectTemplate.TOrbitalDeathLaserBeam,
    FxBeamEndPoint = EffectTemplate.TOrbitalDeathLaserHit01,

    SplatTexture = 'czar_mark01_albedo',
    ScorchSplatDropTime = 0.5,

    ---@param self OrbitalDeathLaserCollisionBeam
    ---@param impactType ImpactType
    ---@param targetEntity? Prop|Unit
    OnImpact = function(self, impactType, targetEntity)
        if impactType ~= 'Shield' and impactType ~= 'Water' and impactType ~= 'Air' and impactType ~= 'UnitAir' and impactType ~= 'Projectile' then
            if self.Scorching == nil then
                self.Scorching = self:ForkThread(self.ScorchThread)
            end
        else
            KillThread(self.Scorching)
            self.Scorching = nil
        end
        CollisionBeam.OnImpact(self, impactType, targetEntity)
    end,

    ---@param self OrbitalDeathLaserCollisionBeam
    OnDisable = function(self)
        CollisionBeam.OnDisable(self)
        KillThread(self.Scorching)
        self.Scorching = nil   
    end,

    ---@param self OrbitalDeathLaserCollisionBeam
    ScorchThread = function(self)
        local army = self:GetArmy()
        local size = 3.5 + (Random() * 3.5) 
        local CurrentPosition = self:GetPosition(1)
        local LastPosition = Vector(0,0,0)
        local skipCount = 1
        -- local FriendlyFire = self.DamageData.DamageFriendly
        
        while true do
            if Util.GetDistanceBetweenTwoVectors(CurrentPosition, LastPosition) > 0.25 or skipCount > 100 then
                CreateSplat( CurrentPosition, Util.GetRandomFloat(0,2*math.pi), self.SplatTexture, size, size, 250, 100, army)
                LastPosition = CurrentPosition
                skipCount = 1

                -- commented due to hard-crash potential
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)

            else
                skipCount = skipCount + self.ScorchSplatDropTime
            end
                
            WaitSeconds(self.ScorchSplatDropTime)
            size = 3.2 + (Random() * 3.5)
            CurrentPosition = self:GetPosition(1)
        end
    end,
}