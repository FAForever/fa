--
-- Aeon T3 Static Artillery Projectile : uab2302
--

-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsShakeCamera = EntityMethods.ShakeCamera

local GlobalMethods = _G
local GlobalMethodsCreateDecal = GlobalMethods.CreateDecal
local GlobalMethodsDamageArea = GlobalMethods.DamageArea
-- End of automatically upvalued moho functions

local AArtilleryProjectile = import('/lua/aeonprojectiles.lua').AArtilleryProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

AIFSonanceShell02 = Class(AArtilleryProjectile)({

    FxTrails = EffectTemplate.ASonanceWeaponFXTrail02,

    FxImpactUnit = EffectTemplate.ASonanceWeaponHit02,
    FxImpactProp = EffectTemplate.ASonanceWeaponHit02,
    FxImpactLand = EffectTemplate.ASonanceWeaponHit02,

    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly and radius ~= 0

        GlobalMethodsDamageArea(self, pos, radius, 1, 'Force', FriendlyFire)
        GlobalMethodsDamageArea(self, pos, radius, 1, 'Force', FriendlyFire)

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2

        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local army = self.Army

            GlobalMethodsCreateDecal(pos, RandomFloat(0, 2 * math.pi), 'crater_radial01_normals', '', 'Alpha Normals', radius + 2, radius + 2, 250, 200, army)
            GlobalMethodsCreateDecal(pos, RandomFloat(0, 2 * math.pi), 'crater_radial01_albedo', '', 'Albedo', radius + 5, radius + 5, 250, 200, army)
        end

        EntityMethodsShakeCamera(self, 20, 2, 0, 1)

        AArtilleryProjectile.OnImpact(self, targetType, targetEntity)
    end,
})

TypeClass = AIFSonanceShell02