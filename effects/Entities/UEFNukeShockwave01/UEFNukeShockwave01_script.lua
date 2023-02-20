--
-- script for projectile BoneAttached
--
local EmitterProjectile = import("/lua/sim/defaultprojectiles.lua").EmitterProjectile

UEFNukeShockwave01 = Class(EmitterProjectile) {
    FxTrails = {'/effects/emitters/nuke_blanket_smoke_02_emit.bp',},
    FxTrailScale = 1,
    FxTrailOffset = 0,
}

TypeClass = UEFNukeShockwave01