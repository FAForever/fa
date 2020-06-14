--
-- Cybran T2 Artillery Projectile : urb2303
--

local CIFMolecularResonanceShell = import('/lua/cybranprojectiles.lua').CIFMolecularResonanceShell
CIFMolecularResonanceShell01 = Class(CIFMolecularResonanceShell) {
	OnImpact = function(self, targetType, targetEntity)
        local army = self.Army
        
        CreateLightParticle( self, -1, army, 24, 5, 'glow_03', 'ramp_red_10' )
        CreateLightParticle( self, -1, army, 8, 16, 'glow_03', 'ramp_antimatter_02' )
		
        if targetType != 'Water' or targetType != 'UnitAir' or targetType != 'Shield' then
            local pos = self:GetPosition()
            local radius = self.DamageData.DamageRadius
            
            DamageArea( self, pos, radius, 1, 'Force', true )
            DamageArea( self, pos, radius, 1, 'Force', true )
        end
        
		CIFMolecularResonanceShell.OnImpact(self, targetType, targetEntity)  
	end,
	
    CreateImpactEffects = function( self, army, EffectTable, EffectScale )
        local emit = nil
        for k, v in EffectTable do
            emit = CreateEmitterAtEntity(self,army,v)
            if emit and EffectScale != 1 then
                emit:ScaleEmitter(EffectScale or 1)
            end
        end
    end,
}

TypeClass = CIFMolecularResonanceShell01