--
-- Aeon T3 Static Artillery Projectile : uab2302
--
local AArtilleryProjectile = import('/lua/aeonprojectiles.lua').AArtilleryProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

AIFSonanceShell02 = Class(AArtilleryProjectile) {
    
    FxTrails = EffectTemplate.ASonanceWeaponFXTrail02,
    
    FxImpactUnit =  EffectTemplate.ASonanceWeaponHit02,
    FxImpactProp =  EffectTemplate.ASonanceWeaponHit02,
    FxImpactLand =  EffectTemplate.ASonanceWeaponHit02,
    
    OnImpact = function(self, targetType, targetEntity)
        if targetType != 'Shield' and targetType != 'Water' and targetType != 'UnitAir' then
            local rotation = RandomFloat(0,2*math.pi)
            local pos = self:GetPosition()
            local radius = self.DamageData.DamageRadius
            local army = self.Army
            
            CreateDecal(pos, rotation, 'crater_radial01_normals', '', 'Alpha Normals', 10, 10, 300, 0, army)
            CreateDecal(pos, rotation, 'crater_radial01_albedo', '', 'Albedo', 12, 12, 300, 0, army)

            DamageArea( self, pos, radius, 1, 'Force', true )
            DamageArea( self, pos, radius, 1, 'Force', true )
        end
        

 
        AArtilleryProjectile.OnImpact( self, targetType, targetEntity )
    end,
}

TypeClass = AIFSonanceShell02