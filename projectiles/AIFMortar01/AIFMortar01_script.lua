-- Automatically upvalued moho functions for performance
local GlobalMethods = _G
local GlobalMethodsCreateDecal = GlobalMethods.CreateDecal
local GlobalMethodsDamageArea = GlobalMethods.DamageArea
-- End of automatically upvalued moho functions

--
-- Aeon T1 Artillery Mortar : ual0103
--
local AArtilleryProjectile = import('/lua/aeonprojectiles.lua').AArtilleryProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')

AIFMortar01 = Class(AArtilleryProjectile)({
    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly and radius ~= 0

        GlobalMethodsDamageArea(self, pos, radius, 1, 'Force', FriendlyFire)
        GlobalMethodsDamageArea(self, pos, radius, 1, 'Force', FriendlyFire)

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2

        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0, 2 * math.pi)
            local army = self.Army

            GlobalMethodsCreateDecal(pos, rotation, 'crater_radial01_albedo', '', 'Albedo', radius, radius, 100, 10, army)
        end

        AArtilleryProjectile.OnImpact(self, targetType, targetEntity)
    end,

    FxImpactLand = EffectTemplate.ALightMortarHit01,
    FxImpactProp = EffectTemplate.ALightMortarHit01,
    FxImpactUnit = EffectTemplate.ALightMortarHit01,
})

TypeClass = AIFMortar01