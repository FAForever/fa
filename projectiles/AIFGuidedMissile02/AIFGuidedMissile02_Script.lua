-------------------------------------------------------------------------------
--  File     :  /data/projectiles/AIFGuidedMissile02/AIFGuidedMissile02_script.lua
--  Author(s):  Gordon Duclos
--  Summary  :  Aeon Guided Split Missile, DAA0206
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------
local AGuidedMissileProjectile = import("/lua/aeonprojectiles.lua").AGuidedMissileProjectile
local AMiasmaProjectile = import('/lua/aeonprojectiles.lua').AMiasmaProjectile
local VisionMarker = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

--- Aeon Guided Split Missile, DAA0206
---@class AIFGuidedMissile02 : AGuidedMissileProjectile
AIFGuidedMissile02 = ClassProjectile(AGuidedMissileProjectile) {

    ---@param self AIFGuidedMissile02
    OnCreate = function(self)
		AGuidedMissileProjectile.OnCreate(self)
		self.Trash:Add(ForkThread(self.MovementThread, self))
    end,

    ---@param self AIFGuidedMissile02
	MovementThread = function(self)
		WaitTicks(7)
		self:TrackTarget(true)
	end,

    ---@param self AIFGuidedMissile02
    ---@param TargetType string
    ---@param TargetEntity Prop|Unit
	OnImpact = function(self, TargetType, TargetEntity)
        AMiasmaProjectile.OnImpact(self, TargetType, TargetEntity)

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
        entity:UpdateIntel(self.Army, 12, 'Vision', true)
        entity:UpdateDuration(10)

        -- Transplanted AIFMiasmaShell02 code

        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly and radius ~=0

        DamageArea( self, pos, 0.5 * radius, 1, 'TreeFire', FriendlyFire )
        DamageArea( self, pos, 0.5 * radius, 1, 'TreeFire', FriendlyFire )

        local emitter = CreateEmitterAtEntity(self, self.Army, '/effects/emitters/X1Mercy_cloud_emit.bp')
        emitter:ScaleEmitter(self.DamageData.DamageRadius / 5 * 2):SetEmitterCurveParam('Y_POSITION_CURVE', 0.5, 1)

        local emitter = CreateEmitterAtEntity(self, self.Army, '/effects/emitters/X2Mercy_cloud_emit.bp')
        emitter:ScaleEmitter(self.DamageData.DamageRadius / 5 * 2):SetEmitterCurveParam('Y_POSITION_CURVE', 0.2, 1)

        self:Destroy()
    end,
}
TypeClass = AIFGuidedMissile02

-- Moved for mod compatibility
local utilities = import('/lua/utilities.lua')