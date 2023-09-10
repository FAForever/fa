---------------------------------------------------------------------------------------------------
-- File     :  /data/projectiles/SIFInainoStrategicMissile01/SIFInainoStrategicMissile01_script.lua
-- Author(s):  Gordon Duclos, Matt Vainio
-- Summary  :  Inaino Strategic Missile Projectile script, XSB2305
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------------------------
local SIFInainoStrategicMissile = import("/lua/seraphimprojectiles.lua").SIFInainoStrategicMissile

SIFInainoStrategicMissile01 = ClassProjectile(SIFInainoStrategicMissile) {
    FxSplashScale = 0.5,
    FxTrails = { },

    LaunchSound = 'Nuke_Launch',
    ExplodeSound = 'Nuke_Impact',
    AmbientSound = 'Nuke_Flight',

    InitialEffects = {
        '/effects/emitters/seraphim_inaino_fxtrails_01_emit.bp',
        '/effects/emitters/seraphim_inaino_fxtrails_02_emit.bp',
    },
    ThrustEffects = {
        '/effects/emitters/seraphim_inaino_fxtrails_01_emit.bp',
        '/effects/emitters/seraphim_inaino_fxtrails_02_emit.bp',
    },
    LaunchEffects = {
        '/effects/emitters/seraphim_inaino_fxtrails_01_emit.bp',
        '/effects/emitters/seraphim_inaino_fxtrails_02_emit.bp',
    },

    OnCreate = function(self)
        SIFInainoStrategicMissile.OnCreate(self)
        self.effectEntityPath = '/effects/entities/InainoEffectController01/InainoEffectController01_proj.bp'
        self:LauncherCallbacks()
    end,
}

TypeClass = SIFInainoStrategicMissile01
