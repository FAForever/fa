local EffectTemplate = import("/lua/effecttemplates.lua")

local SCCollisionBeam = import("/lua/defaultcollisionbeams.lua").SCCollisionBeam

------------------------------------
--   ZAPPER COLLISION BEAM
------------------------------------
---@class ZapperCollisionBeam : SCCollisionBeam
ZapperCollisionBeam = Class(SCCollisionBeam) {
    FxBeam = EffectTemplate.CZapperBeam,
    FxBeamEndPoint = EffectTemplate.CZapperHit01,
}
