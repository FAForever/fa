--
-- script for projectile Missile
--
local CEMPFluxWarheadProjectile = import("/lua/cybranprojectiles.lua").CEMPFluxWarheadProjectile

CIFEMPFluxWarhead01 = ClassProjectile(CEMPFluxWarheadProjectile) {
    FxSplashScale = 0.5,
    FxTrails = { },
    LaunchSound = 'Nuke_Launch',
    ExplodeSound = 'Nuke_Impact',
    AmbientSound = 'Nuke_Flight',

    InitialEffects = {'/effects/emitters/nuke_munition_launch_trail_02_emit.bp',},
    LaunchEffects = {'/effects/emitters/nuke_munition_launch_trail_03_emit.bp',},
    ThrustEffects = {'/effects/emitters/nuke_munition_launch_trail_04_emit.bp',},

    OnCreate = function(self)
        CEMPFluxWarheadProjectile.OnCreate(self)
        self.effectEntityPath = '/projectiles/CIFEMPFluxWarhead02/CIFEMPFluxWarhead02_proj.bp'
        self:LauncherCallbacks()
    end,
}

TypeClass = CIFEMPFluxWarhead01