----------------------------------------------------------------------------------------
-- File     :  /data/Projectiles/ADFReactonCannnon01/ADFReactonCannnon01_script.lua
-- Author(s): Jessica St.Croix, Gordon Duclos
-- Summary  : Aeon Reacton Cannon Area of Effect Projectile
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------------------
local AReactonCannonProjectile = import("/lua/aeonprojectiles.lua").AReactonCannonProjectile
ADFReactonCannon01 = ClassProjectile(AReactonCannonProjectile) {
    CreateImpactEffects = function(self, army, EffectTable, EffectScale)
        local launcher = self.Launcher
        if launcher and launcher:HasEnhancement('StabilitySuppressant') then
            CreateLightParticle(self, -1, self.Army, 3.0, 6, 'ring_05', 'ramp_green_02')
            CreateEmitterAtEntity(self, self.Army,'/effects/emitters/oblivion_cannon_hit_11_emit.bp')
        end
        AReactonCannonProjectile.CreateImpactEffects(self, army, EffectTable, EffectScale)
    end,
}
TypeClass = ADFReactonCannon01