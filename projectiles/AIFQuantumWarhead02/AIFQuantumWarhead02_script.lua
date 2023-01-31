------------------------------------------------------------------------------
-- File     :  /projectiles/CIFEMPFluxWarhead02/CIFEMPFluxWarhead02_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  EMP Flux Warhead Impact effects projectile
-- Copyright © 2005,2006 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------
local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat
local EffectTemplate = import("/lua/effecttemplates.lua")

AIFQuantumWarhead02 = ClassProjectile(NullShell) {
    NormalEffects = {'/effects/emitters/quantum_warhead_01_emit.bp',},
    CloudFlareEffects = EffectTemplate.CloudFlareEffects01,

    EffectThread = function(self)
        CreateLightParticle(self, -1, self.Army, 200, 200, 'beam_white_01', 'ramp_quantum_warhead_flash_01')

        self.Trash:Add(ForkThread(self.ShakeAndBurnMe,self, self.Army))
        self.Trash:Add(ForkThread(self.InnerCloudFlares,self, self.Army))
        self.Trash:Add(ForkThread(self.DistortionField,self))

        for k, v in self.NormalEffects do
            CreateEmitterAtEntity(self, self.Army, v)
        end
    end,

    ShakeAndBurnMe = function(self, army)
        self:ShakeCamera(75, 3, 0, 10)
        WaitTicks(6)
        local orientation = RandomFloat(0,2*math.pi)
        CreateDecal(self:GetPosition(), orientation, 'Crater01_albedo', '', 'Albedo', 50, 50, 1200, 0, army)
        CreateDecal(self:GetPosition(), orientation, 'Crater01_normals', '', 'Normals', 50, 50, 1200, 0, army)
        self:ShakeCamera(105, 10, 0, 2)
        WaitTicks(21)
        self:ShakeCamera(75, 1, 0, 15)
    end,

    InnerCloudFlares = function(self, army)
        local numFlares = 50
        local angle = (2*math.pi) / numFlares
        local angleInitial = 0.0
        local angleVariation = (2*math.pi)
        local emit, x, y, z = nil,nil,nil,nil

        local DirectionMul = 0.02
        local OffsetMul = 4
        local army = self.Army

        for i = 0, (numFlares - 1) do
            x = math.sin(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))
            y = 0.5
            z = math.cos(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))

            for k, v in self.CloudFlareEffects do
                emit = CreateEmitterAtEntity(self, army, v)
                emit:OffsetEmitter(x * OffsetMul, y * OffsetMul, z * OffsetMul)
                emit:SetEmitterCurveParam('XDIR_CURVE', x * DirectionMul, 0.01)
                emit:SetEmitterCurveParam('YDIR_CURVE', y * DirectionMul, 0.01)
                emit:SetEmitterCurveParam('ZDIR_CURVE', z * DirectionMul, 0.01)
            end

            if math.mod(i,11) == 0 then
                CreateLightParticle(self, -1, army, 13, 3, 'beam_white_01', 'ramp_quantum_warhead_flash_01')
            end

            --TODO
            WaitSeconds(RandomFloat(0.05, 0.15))
        end
        CreateLightParticle(self, -1, army, 13, 3, 'beam_white_01', 'ramp_quantum_warhead_flash_01')
        CreateEmitterAtEntity(self, army, '/effects/emitters/quantum_warhead_ring_01_emit.bp')
    end,

    DistortionField = function(self)
        local proj = self:CreateProjectile('/effects/QuantumWarhead/QuantumWarheadEffect01_proj.bp')
        local scale = proj.Blueprint.Display.UniformScale

        proj:SetScaleVelocity(0.123 * scale,0.123 * scale,0.123 * scale)
        WaitTicks(171)
        proj:SetScaleVelocity(0.01 * scale,0.01 * scale,0.01 * scale)
    end,
}
TypeClass = AIFQuantumWarhead02