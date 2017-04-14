------------------------------------------------------------------------------
-- File     :  /projectiles/CIFEMPFluxWarhead02/CIFEMPFluxWarhead02_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  EMP Flux Warhead Impact effects projectile
-- Copyright © 2005,2006 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------
local NullShell = import('/lua/sim/defaultprojectiles.lua').NullShell
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local EffectTemplate = import('/lua/EffectTemplates.lua')

AIFQuantumWarhead02 = Class(NullShell) {
    NormalEffects = {'/effects/emitters/quantum_warhead_01_emit.bp',},
    CloudFlareEffects = EffectTemplate.CloudFlareEffects01,

    EffectThread = function(self)
        local army = self:GetArmy()
        CreateLightParticle(self, -1, army, 200, 200, 'beam_white_01', 'ramp_quantum_warhead_flash_01')

        self:ForkThread(self.ShakeAndBurnMe, army)
        self:ForkThread(self.InnerCloudFlares, army)
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
        CreateDecal(self:GetPosition(), orientation, 'Crater01_albedo', '', 'Albedo', 50, 50, 1200, 0, army)
        CreateDecal(self:GetPosition(), orientation, 'Crater01_normals', '', 'Normals', 50, 50, 1200, 0, army)
        self:ShakeCamera(105, 10, 0, 2)
        WaitSeconds(2)
        self:ShakeCamera(75, 1, 0, 15)
    end,

    InnerCloudFlares = function(self, army)
        local numFlares = 50
        local angle = (2*math.pi) / numFlares
        local angleInitial = 0.0
        local angleVariation = (2*math.pi)

        local emit, x, y, z = nil
        local DirectionMul = 0.02
        local OffsetMul = 4

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

            WaitSeconds(RandomFloat(0.05, 0.15))
        end

        CreateLightParticle(self, -1, army, 13, 3, 'beam_white_01', 'ramp_quantum_warhead_flash_01')
        CreateEmitterAtEntity(self, army, '/effects/emitters/quantum_warhead_ring_01_emit.bp')
    end,

    DistortionField = function(self)
        local proj = self:CreateProjectile('/effects/QuantumWarhead/QuantumWarheadEffect01_proj.bp')
        local scale = proj:GetBlueprint().Display.UniformScale

        proj:SetScaleVelocity(0.123 * scale,0.123 * scale,0.123 * scale)
        WaitSeconds(17.0)
        proj:SetScaleVelocity(0.01 * scale,0.01 * scale,0.01 * scale)
    end,
}

TypeClass = AIFQuantumWarhead02
