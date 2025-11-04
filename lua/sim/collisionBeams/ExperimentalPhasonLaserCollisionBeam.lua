local EffectTemplate = import("/lua/effecttemplates.lua")
local Util = import("/lua/utilities.lua")

local CollisionBeam = import("/lua/sim/collisionbeam.lua").CollisionBeam
local SCCollisionBeam = import("/lua/sim/collisionbeams/sccollisionbeam.lua").SCCollisionBeam

-- Not used. Seraphim style experimental-sized beam, like the Galactic Colossus's beam
---@class ExperimentalPhasonLaserCollisionBeam : SCCollisionBeam
---@field BeamEffectsBag TrashBag
---@field Trash TrashBag
ExperimentalPhasonLaserCollisionBeam = Class(SCCollisionBeam) { 
    TerrainImpactType = 'LargeBeam01',
    TerrainImpactScale = 1,
    FxBeamStartPoint = EffectTemplate.SExperimentalPhasonLaserMuzzle01,
    FxBeam = EffectTemplate.SExperimentalPhasonLaserBeam,
    FxBeamEndPoint = EffectTemplate.SExperimentalPhasonLaserHitLand,
    SplatTexture = 'scorch_004_albedo',
    ScorchSplatDropTime = 0.1,

    ---@param self ExperimentalPhasonLaserCollisionBeam
    ---@param impactType ImpactType
    ---@param targetEntity? Prop|Unit
    OnImpact = function(self, impactType, targetEntity)
        if impactType ~= 'Shield' and impactType ~= 'Water' and impactType ~= 'Air' and impactType ~= 'UnitAir' and impactType ~= 'Projectile' then
            if self.Scorching == nil then
                self.Scorching = self:ForkThread( self.ScorchThread )   
            end
        else
            KillThread(self.Scorching)
            self.Scorching = nil
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
        local size = 4.0 + (Random() * 1.0) 
        local CurrentPosition = self:GetPosition(1)
        local LastPosition = Vector(0,0,0)
        local skipCount = 1
        -- local FriendlyFire = self.DamageData.DamageFriendly
        
        while true do
            if Util.GetDistanceBetweenTwoVectors(CurrentPosition, LastPosition) > 0.25 or skipCount > 100 then
                CreateSplat( CurrentPosition, Util.GetRandomFloat(0,2*math.pi), self.SplatTexture, size, size, 100, 100, army )
                LastPosition = CurrentPosition
                skipCount = 1

                -- commented due to hard-crash potential
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
            else
                skipCount = skipCount + self.ScorchSplatDropTime
            end
                
            WaitSeconds(self.ScorchSplatDropTime)
            size = 4.0 + (Random() * 1.0)
            CurrentPosition = self:GetPosition(1)
        end
    end,

    ---@param self ExperimentalPhasonLaserCollisionBeam
    CreateBeamEffects = function(self)
        SCCollisionBeam.CreateBeamEffects(self)
        for k, v in EffectTemplate.SExperimentalPhasonLaserBeam do
			local fxBeam = CreateBeamEntityToEntity(self, 0, self, 1, self:GetArmy(), v)
			table.insert(self.BeamEffectsBag, fxBeam)
			self.Trash:Add(fxBeam)
        end
        -- local fxBeam = CreateBeamEntityToEntity(self, 0, self, 1, self:GetArmy(), '/effects/emitters/seraphim_expirimental_laser_beam_02_emit.bp' )
    end,
}

