-------------------------------------
-- script for projectile BoneAttached
-------------------------------------

local EmitterProjectile = import('/lua/sim/defaultprojectiles.lua').EmitterProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')

CZARShockwaveEdgeUpper = Class(EmitterProjectile) {
    FxTrails = EffectTemplate.SCUEdge,
}

TypeClass = CZARShockwaveEdgeUpper