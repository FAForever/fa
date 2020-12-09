--
-- Terran T1 Artillery Fragmentation/Sensor Shells : uel0103
--
local TArtilleryProjectile = import('/lua/terranprojectiles.lua').TArtilleryProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')

TIFFragmentationSensorShell02 = Class(TArtilleryProjectile) {
    OnImpact = function(self, targetType, targetEntity)
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0,2*math.pi)
            local pos = self:GetPosition()
            local radius = self.DamageData.DamageRadius
            local army = self.Army
        
            DamageArea( self, pos, radius, 1, 'Force', true )
            DamageArea( self, pos, radius, 1, 'Force', true )
            CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', radius, radius, 100, 10, army)
        end
        
        TArtilleryProjectile.OnImpact(self, targetType, targetEntity)
    end,
    
    FxTrails     = EffectTemplate.TFragmentationSensorShellTrail,
    FxImpactUnit = EffectTemplate.TFragmentationSensorShellHit,
    FxImpactLand = EffectTemplate.TFragmentationSensorShellHit,
    
    -- OnCreate = function(self)
        -- TArtilleryProjectile.OnCreate(self)
           -- local army = self:GetArmy()
           -- for i in self.FxTrails do
               -- CreateEmitterOnEntity(self, army, self.FxTrails[i]):ScaleEmitter(self.FxTrailScale):OffsetEmitter(0, 0, self.FxTrailOffset)
           -- end
        -- CreateEmitterAtBone( self, -1, self:GetArmy(), '/effects/emitters/mortar_munition_02_flare_emit.bp')
    -- end,
}

TypeClass = TIFFragmentationSensorShell02