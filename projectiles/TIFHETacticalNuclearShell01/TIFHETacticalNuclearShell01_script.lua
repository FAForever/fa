--
-- UEF Anti-Matter Shells
--

local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local TArtilleryAntiMatterProjectile = import('/lua/terranprojectiles.lua').TArtilleryAntiMatterProjectile

TIFAntiMatterShells01 = Class(TArtilleryAntiMatterProjectile) {
    FxSplatScale = 9,
    OnImpact = function(self, targetType, targetEntity)
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local pos = self:GetPosition()
            local army = self.Army
            local scale = self.FxSplatScale
            
            CreateDecal(pos, RandomFloat(0,2*math.pi), 'nuke_scorch_001_normals', '', 'Alpha Normals', scale, scale, 250, 200, army)
            CreateDecal(pos, RandomFloat(0,2*math.pi), 'nuke_scorch_002_albedo', '', 'Albedo', scale * 2, scale * 2, 250, 200, army)
        
        end
        self:ShakeCamera(20, 3, 0, 1)
        
        TArtilleryAntiMatterProjectile.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = TIFAntiMatterShells01