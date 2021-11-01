--
-- Cybran T3 Static Artillery Projectile : urb2302
--

-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsShakeCamera = EntityMethods.ShakeCamera

local GlobalMethods = _G
local GlobalMethodsCreateDecal = GlobalMethods.CreateDecal
local GlobalMethodsDamageArea = GlobalMethods.DamageArea
-- End of automatically upvalued moho functions

local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local CArtilleryProtonProjectile = import('/lua/cybranprojectiles.lua').CArtilleryProtonProjectile

CIFArtilleryProton02 = Class(CArtilleryProtonProjectile)({
    FxLandHitScale = 1.1,
    FxPropHitScale = 1.1,
    FxUnitHitScale = 1.1,

    OnImpact = function(self, targetType, targetEntity)
        local army = self.Army
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly and radius ~= 0

        GlobalMethodsDamageArea(self, pos, radius, 1, 'Force', FriendlyFire)
        GlobalMethodsDamageArea(self, pos, radius, 1, 'Force', FriendlyFire)

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2

        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local radius = self.DamageData.DamageRadius

            GlobalMethodsCreateDecal(pos, RandomFloat(0.0, 6.28), 'scorch_011_albedo', '', 'Albedo', radius * 2, radius * 2, 250, 200, army)
        end

        EntityMethodsShakeCamera(self, 20, 2, 0, 1)

        CArtilleryProtonProjectile.OnImpact(self, targetType, targetEntity)
    end,
})
TypeClass = CIFArtilleryProton02