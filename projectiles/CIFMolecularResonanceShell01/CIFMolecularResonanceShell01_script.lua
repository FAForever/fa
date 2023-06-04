-- Cybran T2 Artillery Projectile : urb2303

local CIFMolecularResonanceShell = import("/lua/cybranprojectiles.lua").CIFMolecularResonanceShell
CIFMolecularResonanceShell01 = ClassProjectile(CIFMolecularResonanceShell) {
	OnImpact = function(self, targetType, targetEntity)       
		CIFMolecularResonanceShell.OnImpact(self, targetType, targetEntity)  
        -- make it flashy!
        CreateLightParticle( self, -1, self.Army, 24, 5, 'glow_03', 'ramp_red_10' )
        CreateLightParticle( self, -1, self.Army, 8, 16, 'glow_03', 'ramp_antimatter_02' )
	end,
	
    CreateImpactEffects = function( self, army, EffectTable, EffectScale )
        local emit = nil
        for k, v in EffectTable do
            emit = CreateEmitterAtEntity(self,army,v)
            if emit and EffectScale ~= 1 then
                emit:ScaleEmitter(EffectScale or 1)
            end
        end
    end,
}
TypeClass = CIFMolecularResonanceShell01