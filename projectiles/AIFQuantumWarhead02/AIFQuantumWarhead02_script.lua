-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsShakeCamera = EntityMethods.ShakeCamera

local GlobalMethods = _G
local GlobalMethodsCreateDecal = GlobalMethods.CreateDecal
local GlobalMethodsCreateEmitterAtEntity = GlobalMethods.CreateEmitterAtEntity
local GlobalMethodsCreateLightParticle = GlobalMethods.CreateLightParticle

local IEffectMethods = _G.moho.IEffect
local IEffectMethodsOffsetEmitter = IEffectMethods.OffsetEmitter
local IEffectMethodsSetEmitterCurveParam = IEffectMethods.SetEmitterCurveParam

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileMethodsSetScaleVelocity = ProjectileMethods.SetScaleVelocity
-- End of automatically upvalued moho functions

------------------------------------------------------------------------------
-- File     :  /projectiles/CIFEMPFluxWarhead02/CIFEMPFluxWarhead02_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  EMP Flux Warhead Impact effects projectile
-- Copyright © 2005,2006 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------
local NullShell = import('/lua/sim/defaultprojectiles.lua').NullShell
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local EffectTemplate = import('/lua/EffectTemplates.lua')

AIFQuantumWarhead02 = Class(NullShell)({
    NormalEffects = {
        '/effects/emitters/quantum_warhead_01_emit.bp',
    },
    CloudFlareEffects = EffectTemplate.CloudFlareEffects01,

    EffectThread = function(self)
        GlobalMethodsCreateLightParticle(self, -1, self.Army, 200, 200, 'beam_white_01', 'ramp_quantum_warhead_flash_01')

        self:ForkThread(self.ShakeAndBurnMe, self.Army)
        self:ForkThread(self.InnerCloudFlares, self.Army)
        self:ForkThread(self.DistortionField)

        for k, v in self.NormalEffects do
            GlobalMethodsCreateEmitterAtEntity(self, self.Army, v)
        end
    end,

    ShakeAndBurnMe = function(self, army)
        EntityMethodsShakeCamera(self, 75, 3, 0, 10)
        WaitSeconds(0.5)
        -- CreateDecal(position, heading, textureName, type, sizeX, sizeZ, lodParam, duration, army)");
        local orientation = RandomFloat(0, 2 * math.pi)
        GlobalMethodsCreateDecal(self:GetPosition(), orientation, 'Crater01_albedo', '', 'Albedo', 50, 50, 1200, 0, army)
        GlobalMethodsCreateDecal(self:GetPosition(), orientation, 'Crater01_normals', '', 'Normals', 50, 50, 1200, 0, army)
        EntityMethodsShakeCamera(self, 105, 10, 0, 2)
        WaitSeconds(2)
        EntityMethodsShakeCamera(self, 75, 1, 0, 15)
    end,

    InnerCloudFlares = function(self, army)
        local numFlares = 50
        local angle = (2 * math.pi) / numFlares
        local angleInitial = 0.0
        local angleVariation = (2 * math.pi)

        local emit, x, y, z = nil
        local DirectionMul = 0.02
        local OffsetMul = 4

        for i = 0, (numFlares - 1) do
            x = math.sin(angleInitial + (i * angle) + RandomFloat(-angleVariation, angleVariation))
            y = 0.5
            z = math.cos(angleInitial + (i * angle) + RandomFloat(-angleVariation, angleVariation))

            for k, v in self.CloudFlareEffects do
                emit = CreateEmitterAtEntity(self, army, v)
                IEffectMethodsOffsetEmitter(emit, x * OffsetMul, y * OffsetMul, z * OffsetMul)
                IEffectMethodsSetEmitterCurveParam(emit, 'XDIR_CURVE', x * DirectionMul, 0.01)
                IEffectMethodsSetEmitterCurveParam(emit, 'YDIR_CURVE', y * DirectionMul, 0.01)
                IEffectMethodsSetEmitterCurveParam(emit, 'ZDIR_CURVE', z * DirectionMul, 0.01)
            end

            if math.mod(i, 11) == 0 then
                GlobalMethodsCreateLightParticle(self, -1, army, 13, 3, 'beam_white_01', 'ramp_quantum_warhead_flash_01')
            end

            WaitSeconds(RandomFloat(0.05, 0.15))
        end

        GlobalMethodsCreateLightParticle(self, -1, army, 13, 3, 'beam_white_01', 'ramp_quantum_warhead_flash_01')
        GlobalMethodsCreateEmitterAtEntity(self, army, '/effects/emitters/quantum_warhead_ring_01_emit.bp')
    end,

    DistortionField = function(self)
        local proj = self:CreateProjectile('/effects/QuantumWarhead/QuantumWarheadEffect01_proj.bp')
        local scale = proj:GetBlueprint().Display.UniformScale

        ProjectileMethodsSetScaleVelocity(proj, 0.123 * scale, 0.123 * scale, 0.123 * scale)
        WaitSeconds(17.0)
        ProjectileMethodsSetScaleVelocity(proj, 0.01 * scale, 0.01 * scale, 0.01 * scale)
    end,
})

TypeClass = AIFQuantumWarhead02
