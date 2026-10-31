---@meta

---@class moho.CollisionManipulator : moho.manipulator_methods
local CCollisionManipulator = {}

function CCollisionManipulator:Enable()
end

function CCollisionManipulator:Disable()
end

--- Make manipulator check for intersection with the terrain or water surface
---@see moho.unit_methods.OnAnimTerrainCollision # Called instead of `OnAnimCollision` when enabled
---@see moho.unit_methods.OnNotAnimTerrainCollision
---@param bool boolean
function CCollisionManipulator:EnableTerrainCheck(bool)
end

--- Add the given bone to those watched by this manipulator
---@param bone Bone
function CCollisionManipulator:WatchBone(bone)
end

return CCollisionManipulator

