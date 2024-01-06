---@meta

---@class moho.CollisionManipulator : moho.manipulator_methods
local CCollisionManipulator = {}

--- Enables the manipulator. Events trigger the `OnAnimTerrainCollision` function of the unit
function CCollisionManipulator:Enable()
end

--- Disables the manipulator. It is disabled by default
function CCollisionManipulator:Disable()
end

--- Enables checking for the terrain. Events trigger the `OnAnimTerrainCollision` function of the unit
---@param checked boolean # Enables or disables the terrain check
function CCollisionManipulator:EnableTerrainCheck(checked)
end

---
--- Specify the bones to keep track of.Events trigger the `OnAnimTerrainCollision` function of the unit
---@param bone Bone
function CCollisionManipulator:WatchBone(bone)
end

return CCollisionManipulator
