--
-- script for projectile BoneAttached
--
local GenericDebris = import("/lua/genericdebris.lua").GenericDebris
DebrisBoneAttachChassis01 = Class(GenericDebris) {
    FxLandHitScale = 1.0,
    FxTrails = {},
    FxTrailScale = 1,
}

TypeClass = DebrisBoneAttachChassis01

