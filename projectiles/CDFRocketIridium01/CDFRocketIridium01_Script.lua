--
-- URA0203 : cybran T2 gunship & URA0401 : Soul Ripper
--

-- Automatically upvalued moho functions for performance
local GlobalMethods = _G
local GlobalMethodsCreateDecal = GlobalMethods.CreateDecal
local GlobalMethodsDamageArea = GlobalMethods.DamageArea
local GlobalMethodsDamageRing = GlobalMethods.DamageRing
-- End of automatically upvalued moho functions

local CIridiumRocketProjectile = import('/lua/cybranprojectiles.lua').CIridiumRocketProjectile

CDFRocketIridium01 = Class(CIridiumRocketProjectile)({
    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly and radius ~= 0

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2

        if radius > 0 then
            GlobalMethodsDamageArea(self, pos, radius - 1, 1, 'Force', FriendlyFire)
            GlobalMethodsDamageArea(self, pos, radius - 1, 1, 'Force', FriendlyFire)
        else
            GlobalMethodsDamageArea(self, pos, 1, 1, 'Force', FriendlyFire)
            GlobalMethodsDamageArea(self, pos, 1, 1, 'Force', FriendlyFire)
        end

        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0, 2 * math.pi)
            local army = self.Army

            if radius > 0 then
                GlobalMethodsDamageRing(self, pos, radius, 5 / 4 * radius, 1, 'Fire', true)

                GlobalMethodsCreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', radius - 0.5, radius - 0.5, 100, 50, army)
            else
                GlobalMethodsDamageRing(self, pos, 1, 5 / 4, 1, 'Fire', true)

                GlobalMethodsCreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', 1, 1, 100, 50, army)
            end
        end

        CIridiumRocketProjectile.OnImpact(self, targetType, targetEntity)
    end,
})

TypeClass = CDFRocketIridium01
