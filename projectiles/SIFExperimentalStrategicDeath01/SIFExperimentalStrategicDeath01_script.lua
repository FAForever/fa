local NullShell = import('/lua/sim/defaultprojectiles.lua').NullShell
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local EffectTemplate = import('/lua/EffectTemplates.lua')

SIFExperimentalStrategicDeath01 = Class(NullShell) {
    NormalEffects = {'/effects/emitters/quantum_warhead_01_emit.bp',},
    CloudFlareEffects = EffectTemplate.CloudFlareEffects01,

    EffectThread = function(self)
        local army = self.Army
        -- CreateLightParticle(self, -1, army, 50, 50, 'beam_white_01', 'ramp_quantum_warhead_flash_01')
        -- Create full-screen glow flash
        CreateLightParticle(self, -1, self.Army, 80, 10, 'glow_02', 'ramp_blue_22')
        WaitSeconds(0.3)
        CreateLightParticle(self, -1, self.Army, 40, 30, 'glow_02', 'ramp_blue_16')
        WaitSeconds(3.0)
        CreateLightParticle(self, -1, self.Army, 60, 15, 'glow_02', 'ramp_blue_16')
        WaitSeconds(0.1)
        CreateLightParticle(self, -1, self.Army, 30, 30, 'glow', 'ramp_blue_22')
        
        self:ForkThread(self.ShakeAndBurnMe, army)
        self:ForkThread(self.DistortionField)

        for k, v in self.NormalEffects do
            CreateEmitterAtEntity(self, army, v)
        end
    end,

    ShakeAndBurnMe = function(self, army)
        self:ShakeCamera(75, 3, 0, 10)
        WaitSeconds(0.5)
        -- CreateDecal(position, heading, textureName, type, sizeX, sizeZ, lodParam, duration, army)");
        local orientation = RandomFloat(0,2*math.pi)
        local pos = self:GetPosition()
        
        DamageArea(self, pos, 25, 1, 'Force', true)
        DamageArea(self, pos, 25, 1, 'Force', true)
        
        CreateDecal(pos, orientation, 'Scorch_012_albedo', '', 'Albedo', 70, 70, 800, 0, army)
        CreateDecal(pos, orientation, 'Crater01_normals', '', 'Normals', 70, 70, 800, 0, army)
        self:ShakeCamera(105, 10, 0, 2)
        WaitSeconds(2)
        self:ShakeCamera(75, 1, 0, 15)
    end,

    DistortionField = function(self)
        local proj = self:CreateProjectile('/effects/QuantumWarhead/QuantumWarheadEffect01_proj.bp')
        local scale = proj.Blueprint.Display.UniformScale

        proj:SetScaleVelocity(0.3 * scale,0.3 * scale,0.3 * scale)
        WaitSeconds(17.0)
        proj:SetScaleVelocity(0.01 * scale,0.01 * scale,0.01 * scale)
    end,
}

TypeClass = SIFExperimentalStrategicDeath01
