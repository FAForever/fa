---@meta

---@class moho.CollisionBeamEntity : moho.entity_methods
local CCollisionBeamEntity = {}

---
--  CollisionBeamEntity:Enable()
function CCollisionBeamEntity:Enable()
end

---
--  CCollisionBeamEntity:GetLauncher()
function CCollisionBeamEntity:GetLauncher()
end

---
--  bool = CCollisionBeamEntity:IsEnabled()
function CCollisionBeamEntity:IsEnabled()
end

---
--  CCollisionBeamEntity:SetBeamFx(beamEmitter, checkCollision) -- set an emitter to be controlled by this beam. Its length parameter will be set from the beam entity's collision distance.
function CCollisionBeamEntity:SetBeamFx(beamEmitter,  checkCollision)
end

---
--  beam = CreateCollisionBeam(spec)spec is a table with the following fields defined:
function CCollisionBeamEntity:__init()
end

return CCollisionBeamEntity
