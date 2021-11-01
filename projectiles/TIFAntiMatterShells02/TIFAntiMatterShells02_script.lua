--
-- UEF T3 Mobile Artillery Anti-Matter Shells : uel0304
--

-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsShakeCamera = EntityMethods.ShakeCamera

local GlobalMethods = _G
local GlobalMethodsCreateDecal = GlobalMethods.CreateDecal
local GlobalMethodsDamageArea = GlobalMethods.DamageArea
-- End of automatically upvalued moho functions

local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local TArtilleryAntiMatterSmallProjectile = import('/lua/terranprojectiles.lua').TArtilleryAntiMatterSmallProjectile
TIFAntiMatterShells02 = Class(TArtilleryAntiMatterSmallProjectile)({
    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly and radius ~= 0

        GlobalMethodsDamageArea(self, pos, radius, 1, 'Force', FriendlyFire)
        GlobalMethodsDamageArea(self, pos, radius, 1, 'Force', FriendlyFire)

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2

        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local army = self.Army

            GlobalMethodsCreateDecal(pos, RandomFloat(0, 2 * math.pi), 'nuke_scorch_001_normals', '', 'Alpha Normals', radius + 1, radius + 1, 200, 150, army)
            GlobalMethodsCreateDecal(pos, RandomFloat(0, 2 * math.pi), 'nuke_scorch_002_albedo', '', 'Albedo', radius + 6, radius + 6, 200, 150, army)
        end

        EntityMethodsShakeCamera(self, 20, 1, 0, 1)

        TArtilleryAntiMatterSmallProjectile.OnImpact(self, targetType, targetEntity)
    end,
})

TypeClass = TIFAntiMatterShells02