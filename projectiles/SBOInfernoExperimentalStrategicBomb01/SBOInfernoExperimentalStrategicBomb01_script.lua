-- File     :  /data/projectiles/SBOVortexTacticalBomb02/SBOVortexTacticalBomb02_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Inferno Experimental Stragetic Bomb, XSA0402
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------------------------

local SExperimentalStrategicBomb = import("/lua/seraphimprojectiles.lua").SExperimentalStrategicBomb

SBOInfernoExperimentalStrategicBomb01 = ClassProjectile(SExperimentalStrategicBomb) {
    OnImpact = function(self, TargetType, TargetEntity)
        if not TargetEntity or not EntityCategoryContains(categories.PROJECTILE, TargetEntity) then
            -- Play the explosion sound
            local myBlueprint = self.Blueprint
            if myBlueprint.Audio.Explosion then
                self:PlaySound(myBlueprint.Audio.Explosion)
            end
            nukeProjectile = self:CreateProjectile('/effects/entities/SeraphimNukeEffectController01/SeraphimNukeEffectController01_proj.bp', 0, 0, 0, nil, nil, nil):SetCollision(false)
            local pos = self:GetPosition()
            pos[2] = pos[2] + 20
            Warp( nukeProjectile, pos)
            nukeProjectile:PassData(self.Data)
        end
        SExperimentalStrategicBomb.OnImpact(self, TargetType, TargetEntity)
    end,
}
TypeClass = SBOInfernoExperimentalStrategicBomb01