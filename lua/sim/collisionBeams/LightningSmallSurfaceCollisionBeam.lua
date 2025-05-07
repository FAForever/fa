local EffectTemplate = import("/lua/effecttemplates.lua")
local Util = import("/lua/utilities.lua")

local CollisionBeam = import("/lua/sim/collisionbeam.lua").CollisionBeam
local LightningSmallCollisionBeam = import("/lua/sim/collisionbeams/lightningsmallcollisionbeam.lua").LightningSmallCollisionBeam

LightningSmallSurfaceCollisionBeam = Class(LightningSmallCollisionBeam) {
    TerrainImpactScale = 0.1,
    FxBeam = { '/Effects/Emitters/seraphim_lightning_beam_02_emit.bp', },
    
    SplatTexture = 'czar_mark01_albedo',
    ScorchSplatDropTime = 0.25,

    ---@param self LightningSmallSurfaceCollisionBeam
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

    ---@param self LightningSmallSurfaceCollisionBeam
    OnDisable = function(self)
        CollisionBeam.OnDisable(self)
        KillThread(self.Scorching)
        self.Scorching = nil   
    end,

    ---@param self LightningSmallSurfaceCollisionBeam
    ScorchThread = function(self)
        local army = self:GetArmy()
        local size = 1.1 + (Random() * 1.1) 
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
            size = 1 + (Random() * 1.1)
            CurrentPosition = self:GetPosition(1)
        end
    end,
}
