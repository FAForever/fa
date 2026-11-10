local EffectTemplate = import("/lua/effecttemplates.lua")

local SCCollisionBeam = import("/lua/sim/collisionbeams/sccollisionbeam.lua").SCCollisionBeam

-- Used by Cybran Tactical Missile Defense URB4201's CAMZapperWeapon
---@class ZapperCollisionBeam : SCCollisionBeam
ZapperCollisionBeam = Class(SCCollisionBeam) {
    FxBeam = EffectTemplate.CZapperBeam,
    FxBeamEndPoint = EffectTemplate.CZapperHit01,
}
