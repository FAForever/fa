-- Aeon T2 Artillery Projectile : uab2303

local AMiasmaProjectile = import("/lua/aeonprojectiles.lua").AMiasmaProjectile
local utilities = import("/lua/utilities.lua")

AIFMiasmaShell01 = ClassProjectile(AMiasmaProjectile) {
    OnImpact = function(self, targetType, targetEntity)
        local bp = self.Blueprint.Audio
        local snd = bp['Impact'.. targetType]

        if snd then
            self:PlaySound(snd)
            -- Generic Impact Sound
        elseif bp.Impact then
            self:PlaySound(bp.Impact)
        end

		self:CreateImpactEffects( self.Army, self.FxImpactNone, self.FxNoneHitScale )
		local x,y,z = self:GetVelocity()
		local speed = utilities.GetVectorLength(Vector(x*10,y*10,z*10))

		-- One initial projectile following same directional path as the original
        self:CreateChildProjectile('/projectiles/AIFMiasmaShell02/AIFMiasmaShell02_proj.bp')
        :SetVelocity(x,y,z):SetVelocity(speed).DamageData = self.DamageData
        self:Destroy()
    end,
}
TypeClass = AIFMiasmaShell01