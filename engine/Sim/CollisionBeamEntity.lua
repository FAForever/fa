---@meta

---@class CollisionBeamSpec
---@field Weapon Weapon # Weapon to attach to
---@field BeamBone Bone # Bone of the weapon's unit which the beam is attached to
---@field OtherBone 0 # Which bone of the beam is attached to the unit. Use 0 for a functioning beam. 1 attaches it backwards, which is practically non-functional.
---@field CollisionCheckInterval number # Interval in ticks between collision check ticks

---@class moho.CollisionBeamEntity : moho.entity_methods
local CCollisionBeamEntity = {}

--- Enables beam collision checking, which calls `CCollisionBeamEntity:OnImpact` in Lua every check.
function CCollisionBeamEntity:Enable()
end

--- Disables beam collision checking.
function CCollisionBeamEntity:Disable()
end

--- Returns the unit that is responsible for creating this collision beam.
---@return Unit
function CCollisionBeamEntity:GetLauncher()
end

---@return boolean
function CCollisionBeamEntity:IsEnabled()
end

--- Set an emitter to be controlled by this beam. Its length parameter will be set from the beam entity's collision distance.
---@param beamEmitter moho.IEffect # Beam type emitter
---@param checkCollision boolean
function CCollisionBeamEntity:SetBeamFx(beamEmitter,  checkCollision)
end

---@param spec CollisionBeamSpec
---@return moho.CollisionBeamEntity
function CCollisionBeamEntity:__init(spec)
end

return CCollisionBeamEntity
