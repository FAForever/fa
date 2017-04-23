--- Class CUIWorldView
-- @classmod User.CUIWorldView

---
--  EnableResourceRendering(bool)
function CUIWorldView:EnableResourceRendering(bool)
end

---
--  string moho.UIWorldView:GetRightMouseButtonOrder()
function CUIWorldView:GetRightMouseButtonOrder()
end

---
--  (vector2f|nil) = GetScreenPos(unit)
function CUIWorldView:GetScreenPos(unit)
end

---
--  moho.UIWorldView:GetsGlobalCameraCommands(bool getsCommands)
function CUIWorldView:GetsGlobalCameraCommands(bool getsCommands)
end

---
--  bool moho.UIWorldView:HasHighlightCommand()
function CUIWorldView:HasHighlightCommand()
end

---
--  bool IsCartographic()
function CUIWorldView:IsCartographic()
end

---
--  IsInputLocked(camera)
function CUIWorldView:IsInputLocked(camera)
end

---
--  bool IsResourceRenderingEnabled()
function CUIWorldView:IsResourceRenderingEnabled()
end

---
--  LockInput(camera)
function CUIWorldView:LockInput(camera)
end

---
--  VECTOR2 Project(self,VECTOR3) - given a point in world space, projects the point to control space
function CUIWorldView:Project(self, VECTOR3)
end

---
--  SetCartographic(bool)
function CUIWorldView:SetCartographic(bool)
end

---
--  SetHighlightEnabled(bool)
function CUIWorldView:SetHighlightEnabled(bool)
end

---
--  bool moho.UIWorldView:ShowConvertToPatrolCursor()
function CUIWorldView:ShowConvertToPatrolCursor()
end

---
--  UnlockInput(camera)
function CUIWorldView:UnlockInput(camera)
end

---
--  ZoomScale(x, y, wheelRot, wheelDelta) - cause the world to zoom based on wheel rotation event
function CUIWorldView:ZoomScale(x,  y,  wheelRot,  wheelDelta)
end

---
--  moho.UIWorldView:__init(parent_control, cameraName, depth, isMiniMap, trackCamera)
function CUIWorldView:__init(parent_control,  cameraName,  depth,  isMiniMap,  trackCamera)
end

---
--  derived from CMauiControl
function CUIWorldView:base()
end

---
--
function CUIWorldView:moho.UIWorldView()
end

