--
-- UEF Anti-Matter Shells
--

-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsShakeCamera = EntityMethods.ShakeCamera

local GlobalMethods = _G
local GlobalMethodsCreateDecal = GlobalMethods.CreateDecal
local GlobalMethodsDamageArea = GlobalMethods.DamageArea
-- End of automatically upvalued moho functions

local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local TArtilleryAntiMatterProjectile = import('/lua/terranprojectiles.lua').TArtilleryAntiMatterProjectile

TIFAntiMatterShells01 = Class(TArtilleryAntiMatterProjectile)({
    FxSplatScale = 9,
    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly and radius ~= 0

        GlobalMethodsDamageArea(self, pos, radius, 1, 'Force', FriendlyFire)
        GlobalMethodsDamageArea(self, pos, radius, 1, 'Force', FriendlyFire)

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2

        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local army = self.Army
            local scale = self.FxSplatScale

            GlobalMethodsCreateDecal(pos, RandomFloat(0, 2 * math.pi), 'nuke_scorch_001_normals', '', 'Alpha Normals', scale, scale, 350, 200, army)
            GlobalMethodsCreateDecal(pos, RandomFloat(0, 2 * math.pi), 'nuke_scorch_002_albedo', '', 'Albedo', scale * 2, scale * 2, 350, 200, army)
        end

        EntityMethodsShakeCamera(self, 20, 3, 0, 1)

        TArtilleryAntiMatterProjectile.OnImpact(self, targetType, targetEntity)
    end,
})

TypeClass = TIFAntiMatterShells01