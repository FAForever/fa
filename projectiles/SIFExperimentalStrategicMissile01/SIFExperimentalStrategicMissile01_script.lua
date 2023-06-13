---------------------------------------------------------------------------------------------------------------
-- File     :  /data/projectiles/SIFExperimentalStrategicMissile01/SIFExperimentalStrategicMissile01_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Experimental Strategic Missile Projectile script, XSB2401
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------------------------------------
local SExperimentalStrategicMissile = import("/lua/seraphimprojectiles.lua").SExperimentalStrategicMissile

SIFExperimentalStrategicMissile01 = ClassProjectile(SExperimentalStrategicMissile) {
    FxSplashScale = 0.5,

    LaunchSound = 'Nuke_Launch',
    ExplodeSound = 'Nuke_Impact',
    AmbientSound = 'Nuke_Flight',

    InitialEffects = {
        '/effects/emitters/seraphim_expnuke_fxtrails_01_emit.bp',
        '/effects/emitters/seraphim_expnuke_fxtrails_02_emit.bp',
    },

    ThrustEffects = {
        '/effects/emitters/seraphim_expnuke_fxtrails_01_emit.bp',
        '/effects/emitters/seraphim_expnuke_fxtrails_02_emit.bp',
    },

    LaunchEffects = {
        '/effects/emitters/seraphim_expnuke_fxtrails_01_emit.bp',
        '/effects/emitters/seraphim_expnuke_fxtrails_02_emit.bp',
    },

    OnCreate = function(self)
        SExperimentalStrategicMissile.OnCreate(self)
        self.effectEntityPath = '/effects/entities/SeraphimNukeEffectController01/SeraphimNukeEffectController01_proj.bp'
        self:LauncherCallbacks()
    end,

    -- Need to preserve warp action
    OnImpact = function(self, TargetType, TargetEntity)
        SExperimentalStrategicMissile.OnImpact(self, TargetType, TargetEntity)
        if not TargetEntity or not EntityCategoryContains(categories.PROJECTILE, TargetEntity) then
            local pos = self:GetPosition()
            pos[2] = pos[2] + 20
            Warp(self.effectEntity, pos)
        end
    end,
}

TypeClass = SIFExperimentalStrategicMissile01
