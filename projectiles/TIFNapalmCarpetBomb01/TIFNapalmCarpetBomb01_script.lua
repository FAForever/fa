--
-- Terran Napalm Carpet Bomb
--

-- Automatically upvalued moho functions for performance
local GlobalMethods = _G
local GlobalMethodsCreateDecal = GlobalMethods.CreateDecal
local GlobalMethodsDamageArea = GlobalMethods.DamageArea
local GlobalMethodsDamageRing = GlobalMethods.DamageRing
-- End of automatically upvalued moho functions

local TNapalmCarpetBombProjectile = import('/lua/terranprojectiles.lua').TNapalmCarpetBombProjectile

TIFNapalmCarpetBomb01 = Class(TNapalmCarpetBombProjectile)({
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
            local size = radius + RandomFloat(0.75, 2.0)
            local army = self.Army

            GlobalMethodsDamageRing(self, pos, 0.1, 5 / 4 * radius, 10, 'Fire', FriendlyFire, false)

            GlobalMethodsCreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', size, size, 150, 30, army)
        end
        TNapalmCarpetBombProjectile.OnImpact(self, targetType, targetEntity)
    end,
})

TypeClass = TIFNapalmCarpetBomb01
