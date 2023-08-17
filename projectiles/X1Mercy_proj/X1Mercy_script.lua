#
# script for projectile AIFMiasmaShell
#
local AMiasmaProjectile = import('/lua/aeonprojectiles.lua').AMiasmaProjectile
local utilities = import('/lua/utilities.lua')
local VisionMarker = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

X1Mercy = Class(AMiasmaProjectile) {

    PassMetaDamage = function(self, data)
      AMiasmaProjectile.PassMetaDamage(self, data)
      local ScaleRadius = data.DamageRadius
      WARN("ScaleRadius" .. " - " .. tostring(ScaleRadius))
      self.FxAirUnitHitScale = ScaleRadius
      self.FxLandHitScale = ScaleRadius
      self.FxNoneHitScale = ScaleRadius
      self.FxPropHitScale = ScaleRadius
      self.FxProjectileHitScale = ScaleRadius
      self.FxProjectileUnderWaterHitScale = ScaleRadius
      self.FxShieldHitScale = ScaleRadius
      self.FxUnderWaterHitScale = ScaleRadius
      self.FxUnitHitScale = ScaleRadius
      self.FxWaterHitScale = ScaleRadius
      self.FxOnKilledScale = ScaleRadius
    end,

    OnCreate = function(self)
        AMiasmaProjectile.OnCreate(self)

        local launcher = self:GetLauncher()
        if launcher and not launcher:IsDead() then
            launcher:ProjectileFired()
        end
        self:ForkThread( self.SplitThread )
    end,

	OnImpact = function(self, TargetType, TargetEntity)
        AMiasmaProjectile.OnImpact(self, TargetType, TargetEntity)

        --WARN(tostring(TargetType) .. " - " .. tostring(TargetEntity))
        --Sounds for all other impacts, ie: Impact<TargetTypeName>
        local bp = self:GetBlueprint().Audio
        local snd = bp['Impact'.. TargetType]
        if snd then
            self:PlaySound(snd)
            --Generic Impact Sound
        elseif bp.Impact then
            self:PlaySound(bp.Impact)
        end
        
        --Vision for when projectile impacts
        ---@type VisionMarkerOpti
        local entity = VisionMarker({Owner = self})
    
        local px, py, pz = self:GetPositionXYZ()
        entity:UpdatePosition(px, pz)
        entity:UpdateIntel(self.Army, 10, 'Vision', true)
        entity:UpdateDuration(10)

        -- Transplanted AIFMiasmaShell02 code

        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly and radius ~=0

        

        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2


        -- One initial projectile following same directional path as the original, old code in case it breaks
        --local child = self:CreateChildProjectile('/projectiles/AIFMiasmaShell02/AIFMiasmaShell02_proj.bp' ):SetVelocity(x,y,z):SetVelocity(speed)

        local emitter = CreateEmitterAtEntity(self, self.Army, '/effects/emitters/X1Mercy_cloud_emit.bp')
        emitter:ScaleEmitter(self.DamageData.DamageRadius / 5 * 2):SetEmitterCurveParam('EMITRATE_CURVE',self.DamageData.DamageRadius * 2,20):SetEmitterCurveParam('Y_POSITION_CURVE', -0.5, 0)

        self:Destroy()
    end,

}

TypeClass = X1Mercy
