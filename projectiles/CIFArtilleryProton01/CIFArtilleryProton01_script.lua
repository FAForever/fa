-- Cybran Artillery Projectile

local CArtilleryProtonProjectile = import('/lua/cybranprojectiles.lua').CArtilleryProtonProjectile
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

CIFArtilleryProton01 = Class(CArtilleryProtonProjectile) {
    OnImpact = function(self, targetType, targetEntity)
        CArtilleryProtonProjectile.OnImpact(self, targetType, targetEntity)
        local army = self:GetArmy()
        CreateLightParticle(self, -1, army, 18, 10, 'glow_03', 'ramp_red_06') -- Initial massive blast flash. Diameter
        CreateLightParticle(self, -1, army, 6, 30, 'glow_03', 'ramp_antimatter_02') -- Diameter
        if targetType == 'Terrain' or targetType == 'Prop' then
            CreateDecal(self:GetPosition(), RandomFloat(0.0,6.28), 'scorch_011_albedo', '', 'Albedo', 6, 6, 350, 200, army) -- Radius
        end
        self:ShakeCamera(10, 1, 0, 1)
    end,
}

TypeClass = CIFArtilleryProton01
