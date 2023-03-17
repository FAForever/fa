--
-- Terran Nuke Missile
--
local TIFMissileNuke = import("/lua/terranprojectiles.lua").TIFMissileNuke

TIFMissileNuke02 = ClassProjectile(TIFMissileNuke) {
    BeamName = '/effects/emitters/missile_exhaust_fire_beam_06_emit.bp',
    InitialEffects = {'/effects/emitters/nuke_munition_launch_trail_02_emit.bp',},
    LaunchEffects = {
        '/effects/emitters/nuke_munition_launch_trail_03_emit.bp',
        '/effects/emitters/nuke_munition_launch_trail_05_emit.bp',
    },
    ThrustEffects = {'/effects/emitters/nuke_munition_launch_trail_04_emit.bp',},

    OnCreate = function(self)
        TIFMissileNuke.OnCreate(self)
        self.effectEntityPath = '/effects/Entities/UEFNukeEffectController01/UEFNukeEffectController01_proj.bp'
        self:LauncherCallbacks()
    end,
}

TypeClass = TIFMissileNuke02
