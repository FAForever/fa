#
# script for projectile AIFMiasmaShell
#
local AMiasmaProjectile = import('/lua/aeonprojectiles.lua').AMiasmaProjectile
local utilities = import('/lua/utilities.lua')

AIFMiasmaShell01 = Class(AMiasmaProjectile) {


    OnImpact = function(self, TargetType, TargetEntity) 
        
        #Sounds for all other impacts, ie: Impact<TargetTypeName>
        local bp = self:GetBlueprint().Audio
        local snd = bp['Impact'.. TargetType]
        if snd then
            self:PlaySound(snd)
            #Generic Impact Sound
        elseif bp.Impact then
            self:PlaySound(bp.Impact)
        end
        
		self:CreateImpactEffects( self:GetArmy(), self.FxImpactNone, self.FxNoneHitScale )
		local x,y,z = self:GetVelocity()
		local speed = utilities.GetVectorLength(Vector(x*10,y*10,z*10))
		
		# One initial projectile following same directional path as the original
        self:CreateChildProjectile('/projectiles/AIFMiasmaShell02/AIFMiasmaShell02_proj.bp' )
        :SetVelocity(x,y,z):SetVelocity(speed):PassDamageData(self.DamageData)
                
        self:Destroy()
    end,
    
}

TypeClass = AIFMiasmaShell01