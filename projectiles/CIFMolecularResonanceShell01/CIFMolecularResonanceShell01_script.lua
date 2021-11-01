--
-- Cybran T2 Artillery Projectile : urb2303
--

-- Automatically upvalued moho functions for performance
local GlobalMethods = _G
local GlobalMethodsCreateDecal = GlobalMethods.CreateDecal
local GlobalMethodsCreateLightParticle = GlobalMethods.CreateLightParticle
local GlobalMethodsDamageArea = GlobalMethods.DamageArea

local IEffectMethods = _G.moho.IEffect
local IEffectMethodsScaleEmitter = IEffectMethods.ScaleEmitter
-- End of automatically upvalued moho functions

local CIFMolecularResonanceShell = import('/lua/cybranprojectiles.lua').CIFMolecularResonanceShell
CIFMolecularResonanceShell01 = Class(CIFMolecularResonanceShell)({
    OnImpact = function(self, targetType, targetEntity)
        local army = self.Army
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly and radius ~= 0

        GlobalMethodsDamageArea(self, pos, radius, 1, 'Force', FriendlyFire)
        GlobalMethodsDamageArea(self, pos, radius, 1, 'Force', FriendlyFire)

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2

        GlobalMethodsCreateLightParticle(self, -1, army, 24, 5, 'glow_03', 'ramp_red_10')
        GlobalMethodsCreateLightParticle(self, -1, army, 8, 16, 'glow_03', 'ramp_antimatter_02')

        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0, 2 * math.pi)

            GlobalMethodsCreateDecal(pos, rotation, 'nuke_scorch_002_albedo', '', 'Albedo', radius * 2, radius * 2, 200, 100, army)
        end

        CIFMolecularResonanceShell.OnImpact(self, targetType, targetEntity)
    end,

    CreateImpactEffects = function(self, army, EffectTable, EffectScale)
        local emit = nil
        for k, v in EffectTable do
            emit = CreateEmitterAtEntity(self, army, v)
            if emit and EffectScale ~= 1 then
                IEffectMethodsScaleEmitter(emit, EffectScale or 1)
            end
        end
    end,
})

TypeClass = CIFMolecularResonanceShell01