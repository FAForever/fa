--- Class CCollisionManipulator
-- @classmod Sim.CCollisionManipulator

---
--  Fixme: this should just use base manipulator enable/disable
function CCollisionManipulator:Enable()
end

---
--  Make manipulator check for terrain height intersection
function CCollisionManipulator:EnableTerrainCheck()
end

---
--  CollisionDetector:WatchBone(bone) -- add the given bone to those watched by this manipulator
function CCollisionManipulator:WatchBone(bone)
end

---
--  derived from IAniManipulator
function CCollisionManipulator:base()
end

---
--
function CCollisionManipulator:moho.CollisionManipulator()
end

