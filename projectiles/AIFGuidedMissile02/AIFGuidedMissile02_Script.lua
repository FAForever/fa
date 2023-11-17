-------------------------------------------------------------------------------
--  File     :  /data/projectiles/AIFGuidedMissile02/AIFGuidedMissile02_script.lua
--  Author(s):  Gordon Duclos
--  Summary  :  Aeon Guided Split Missile, DAA0206
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------
local AGuidedMissileProjectile = import("/lua/aeonprojectiles.lua").AGuidedMissileProjectile
local AMiasmaProjectile = import('/lua/aeonprojectiles.lua').AMiasmaProjectile
local utilities = import('/lua/utilities.lua')
local VisionMarker = import("/lua/sim/vizmarker.lua").VisionMarkerOpti


AIFGuidedMissile02 = ClassProjectile(AGuidedMissileProjectile) {
    OnImpact = function(self, TargetType, TargetEntity)
        AMiasmaProjectile.OnImpact(self, TargetType, TargetEntity)

        local bp = self:GetBlueprint().Audio
        local snd = bp['Impact' .. TargetType]
        if snd then
            self:PlaySound(snd)
            --Generic Impact Sound
        elseif bp.Impact then
            self:PlaySound(bp.Impact)
        end

        --Vision for when projectile impacts
        ---@type VisionMarkerOpti
        local entity = VisionMarker({ Owner = self })

        local px, py, pz = self:GetPositionXYZ()
        entity:UpdatePosition(px, pz)
        entity:UpdateIntel(self.Army, 12, 'Vision', true)
        entity:UpdateDuration(10)

        --emitter = CreateEmitterAtEntity(self, self.Army, '/effects/emitters/_Mercy_Circle_1.bp')
        --emitter = CreateEmitterAtEntity(self, self.Army, '/effects/emitters/_Mercy_Circle_2.bp')
        --local emitter = CreateEmitterAtEntity(self, self.Army, '/effects/emitters/_Mercy_Circle.bp')


        self:Destroy()
    end,
}
TypeClass = AIFGuidedMissile02
