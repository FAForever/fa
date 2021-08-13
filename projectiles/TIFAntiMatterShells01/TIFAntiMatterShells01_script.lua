--
-- UEF T3 Artillery Anti-Matter Shells : ueb2302
--

local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local TArtilleryAntiMatterProjectile02 = import('/lua/terranprojectiles.lua').TArtilleryAntiMatterProjectile02
TIFAntiMatterShells01 = Class(TArtilleryAntiMatterProjectile02) {
    FxSplatScale = 7,

    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local army = self.Army
            local scale = self.FxSplatScale

            CreateDecal(pos, RandomFloat(0,2*math.pi), 'nuke_scorch_001_normals', '', 'Alpha Normals', scale, scale, 250, 150, army)
            CreateDecal(pos, RandomFloat(0,2*math.pi), 'nuke_scorch_002_albedo', '', 'Albedo', scale * 2, scale * 2, 250, 150, army)
        end
        
        self:ShakeCamera(20, 2, 0, 1)

        TArtilleryAntiMatterProjectile02.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = TIFAntiMatterShells01