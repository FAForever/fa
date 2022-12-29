local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat
local EffectTemplate = import("/lua/effecttemplates.lua")

SIFExperimentalStrategicDeath01 = ClassProjectile(NullShell) {
    NormalEffects = {'/effects/emitters/quantum_warhead_01_emit.bp',},
    CloudFlareEffects = EffectTemplate.CloudFlareEffects01,

    EffectThread = function(self)
        local army = self.Army

        CreateLightParticle(self, -1, self.Army, 80, 10, 'glow_02', 'ramp_blue_22')
        WaitTicks(4)
        CreateLightParticle(self, -1, self.Army, 40, 30, 'glow_02', 'ramp_blue_16')
        WaitTicks(31)
        CreateLightParticle(self, -1, self.Army, 60, 15, 'glow_02', 'ramp_blue_16')
        WaitTicks(11)
        CreateLightParticle(self, -1, self.Army, 30, 30, 'glow', 'ramp_blue_22')

        self.Trash:Add(ForkThread(self.ShakeAndBurnMe,self, army))
        self.Trash:Add(ForkThread(self.DistortionField,self))

        for k, v in self.NormalEffects do
            CreateEmitterAtEntity(self, army, v)
        end
    end,

    ShakeAndBurnMe = function(self, army)
        self:ShakeCamera(75, 3, 0, 10)
        WaitTicks(6)

        local orientation = RandomFloat(0,2*math.pi)
        local pos = self:GetPosition()

        DamageArea(self, pos, 25, 1, 'TreeForce', true)
        DamageArea(self, pos, 25, 1, 'TreeForce', true)

        CreateDecal(pos, orientation, 'Scorch_012_albedo', '', 'Albedo', 70, 70, 800, 0, army)
        CreateDecal(pos, orientation, 'Crater01_normals', '', 'Normals', 70, 70, 800, 0, army)
        self:ShakeCamera(105, 10, 0, 2)
        WaitTicks(21)
        self:ShakeCamera(75, 1, 0, 15)
    end,

    DistortionField = function(self)
        local proj = self:CreateProjectile('/effects/QuantumWarhead/QuantumWarheadEffect01_proj.bp')
        local scale = proj.Blueprint.Display.UniformScale

        proj:SetScaleVelocity(0.3 * scale,0.3 * scale,0.3 * scale)
        WaitTicks(171)
        proj:SetScaleVelocity(0.01 * scale,0.01 * scale,0.01 * scale)
    end,
}
TypeClass = SIFExperimentalStrategicDeath01