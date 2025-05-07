local EffectTemplate = import("/lua/effecttemplates.lua")
local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti
local Util = import("/lua/utilities.lua")

local CollisionBeam = import("/lua/sim/collisionbeam.lua").CollisionBeam
local SCCollisionBeam = import("/lua/sim/collisionbeams/sccollisionbeam.lua").SCCollisionBeam

-- Used by Seraphim Othuy (Ythotha's lightning storm) XSL0402's SDFUnstablePhasonBeam
---@class UnstablePhasonLaserCollisionBeam : SCCollisionBeam
UnstablePhasonLaserCollisionBeam = Class(SCCollisionBeam) { 
    TerrainImpactType = 'LargeBeam01',
    TerrainImpactScale = 1,
    FxBeamStartPoint = EffectTemplate.SExperimentalUnstablePhasonLaserMuzzle01,
    FxBeam = EffectTemplate.OthuyElectricityStrikeBeam,
    FxBeamEndPoint = EffectTemplate.OthuyElectricityStrikeHit,
    SplatTexture = 'czar_mark01_albedo',
    ScorchSplatDropTime = 0.25,

    ---@param self ExperimentalPhasonLaserCollisionBeam
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

        -- add vision to make sure we can see the impact effect
        local position = self:GetPosition(1)
        if position then
            local marker = VisionMarkerOpti({Owner = self.unit})
            marker:UpdatePosition(position[1], position[3])
            marker:UpdateDuration(1)
            marker:UpdateIntel(self.Army, 4, 'Vision', true)
        end

        CollisionBeam.OnImpact(self, impactType, targetEntity)
    end,

    ---@param self ExperimentalPhasonLaserCollisionBeam
    OnDisable = function(self)
        CollisionBeam.OnDisable(self)
        KillThread(self.Scorching)
        self.Scorching = nil   
    end,

    ---@param self ExperimentalPhasonLaserCollisionBeam
    ScorchThread = function(self)
        local army = self:GetArmy()
        local size = 1.5 + (Random() * 1.5) 
        local CurrentPosition = self:GetPosition(1)
        local LastPosition = Vector(0,0,0)
        local skipCount = 1
        -- local FriendlyFire = self.DamageData.DamageFriendly
        
        while true do
            if Util.GetDistanceBetweenTwoVectors(CurrentPosition, LastPosition) > 0.25 or skipCount > 100 then
                CreateSplat( CurrentPosition, Util.GetRandomFloat(0,2*math.pi), self.SplatTexture, size, size, 250, 100, army )
                LastPosition = CurrentPosition
                skipCount = 1

                -- commented due to hard-crash potential
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
            else
                skipCount = skipCount + self.ScorchSplatDropTime
            end
                
            WaitSeconds(self.ScorchSplatDropTime)
            size = 1.2 + (Random() * 1.5)
            CurrentPosition = self:GetPosition(1)
        end
    end,
}

