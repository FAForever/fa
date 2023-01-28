---@meta

---@class moho.CollisionManipulator : moho.manipulator_methods
local CCollisionManipulator = {}

function CCollisionManipulator:Enable()
end

function CCollisionManipulator:Disable()
end

---
--  Make manipulator check for terrain height intersection
function CCollisionManipulator:EnableTerrainCheck()
end

---
--  CollisionDetector:WatchBone(bone) -- add the given bone to those watched by this manipulator
function CCollisionManipulator:WatchBone(bone)
end

return CCollisionManipulator

