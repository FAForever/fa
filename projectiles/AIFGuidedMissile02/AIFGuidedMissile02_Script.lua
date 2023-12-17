-------------------------------------------------------------------------------
--  File     :  /data/projectiles/AIFGuidedMissile02/AIFGuidedMissile02_script.lua
--  Author(s):  Gordon Duclos
--  Summary  :  Aeon Guided Split Missile, DAA0206
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------
local AGuidedMissileProjectile = import("/lua/aeonprojectiles.lua").AGuidedMissileProjectile
local VisionMarker = import("/lua/sim/vizmarker.lua").VisionMarkerOpti

---@class AIFGuidedMissile02 : AGuidedMissileProjectile
AIFGuidedMissile02 = ClassProjectile(AGuidedMissileProjectile) {

    ---@param self AIFGuidedMissile02
    ---@param TargetType string
    ---@param TargetEntity Prop|Unit unused
    OnImpact = function(self, TargetType, TargetEntity)
        local bp = self.Blueprint.Audio
        local snd = bp['Impact' .. TargetType]
        local army = self.Army

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
        entity:UpdateIntel(army, 12, 'Vision', true)
        entity:UpdateDuration(10)

        -- let bloom thrive a bit
        CreateLightParticleIntel(self, -1, army, 5, 8, 'glow_02', 'ramp_flare_02')

        self:Destroy()
    end,
}
TypeClass = AIFGuidedMissile02


-- Kept for Backwards Compatibility
local AMiasmaProjectile = import('/lua/aeonprojectiles.lua').AMiasmaProjectile
local utilities = import('/lua/utilities.lua')