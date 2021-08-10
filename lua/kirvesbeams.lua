local CollisionBeam = import('/lua/sim/CollisionBeam.lua').CollisionBeam
local EffectTemplate = import('/lua/EffectTemplates.lua')
local CustomEffectTemplate = import('/lua/kirveseffects.lua')
local SCCollisionBeam = import('/lua/defaultcollisionbeams.lua').SCCollisionBeam
local Util = import('/lua/utilities.lua')

EmptyCollisionBeam = Class(CollisionBeam) {
    FxImpactUnit = {},
    FxImpactLand = {},--EffectTemplate.DefaultProjectileLandImpact,
    FxImpactWater = EffectTemplate.DefaultProjectileWaterImpact,
    FxImpactUnderWater = EffectTemplate.DefaultProjectileUnderWaterImpact,
    FxImpactAirUnit = {},
    FxImpactProp = {},
    FxImpactShield = {},
    FxImpactNone = {},
}


TargetingCollisionBeam = Class(EmptyCollisionBeam) {
    FxBeam = {
        '/effects/emitters/targetting_beam_01_emit.bp'
    },
}

TargetingCollisionBeamInvisible = Class(EmptyCollisionBeam) {
    FxBeam = {
        '/effects/emitters/targeting_beam_invisible.bp'
    },
}

UnstablePhasonLaserCollisionBeam = Class(SCCollisionBeam) {

    TerrainImpactType = 'LargeBeam01',
    TerrainImpactScale = 0.2,
    FxBeamStartPoint = CustomEffectTemplate.SExperimentalUnstablePhasonLaserMuzzle01,
    FxBeam = CustomEffectTemplate.OthuyElectricityStrikeBeam,
    FxBeamEndPoint = CustomEffectTemplate.OthuyElectricityStrikeHit,
    SplatTexture = 'czar_mark01_albedo',
    ScorchSplatDropTime = 0.25,

    OnImpact = function(self, impactType, targetEntity)
        CollisionBeam.OnImpact(self, impactType, targetEntity)
    end,

    OnDisable = function(self)
        CollisionBeam.OnDisable(self)
        KillThread(self.Scorching)
        self.Scorching = nil
    end,

}

UnstablePhasonLaserCollisionBeam2 = Class(SCCollisionBeam) {

    TerrainImpactType = 'LargeBeam01',
    TerrainImpactScale = 0.1,
    FxBeamStartPoint = CustomEffectTemplate.SExperimentalUnstablePhasonLaserMuzzle01,
    FxBeam = CustomEffectTemplate.OthuyElectricityStrikeBeam2,
    FxBeamEndPoint = CustomEffectTemplate.OthuyElectricityStrikeHit,
    SplatTexture = 'czar_mark01_albedo',
    ScorchSplatDropTime = 0.25,

    OnImpact = function(self, impactType, targetEntity)
        if impactType == 'Terrain' then
            if self.Scorching == nil then
                self.Scorching = self:ForkThread(self.ScorchThread)
            end
        elseif not impactType == 'Unit' then
            KillThread(self.Scorching)
            self.Scorching = nil
        end
        CollisionBeam.OnImpact(self, impactType, targetEntity)
   end,

    OnDisable = function(self)
        CollisionBeam.OnDisable(self)
        KillThread(self.Scorching)
        self.Scorching = nil
    end,

    ScorchThread = function(self)
        local size = 1 + (Random() * 1.1)
        local CurrentPosition = self:GetPosition(1)
        local LastPosition = Vector(0,0,0)
        local skipCount = 1
        while true do
            if Util.GetDistanceBetweenTwoVectors(CurrentPosition, LastPosition) > 0.25 or skipCount > 100 then
                CreateSplat(CurrentPosition, Util.GetRandomFloat(0,2*math.pi), self.SplatTexture, size, size, 100, 100, self.Army)
                LastPosition = CurrentPosition
                skipCount = 1
            else
                skipCount = skipCount + self.ScorchSplatDropTime
            end

            WaitSeconds(self.ScorchSplatDropTime)
            size = 1 + (Random() * 1.1)
            CurrentPosition = self:GetPosition(1)
        end
    end,
}