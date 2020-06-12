--
-- Terran Fragmentation/Sensor Shells
--
local TArtilleryProjectile = import('/lua/terranprojectiles.lua').TArtilleryProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')

TIFFragmentationSensorShell02 = Class(TArtilleryProjectile) {
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