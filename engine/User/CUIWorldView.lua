---@meta

---@class moho.UIWorldView : moho.control_methods
local CUIWorldView = {}

---
---@param parentControl Control
---@param cameraName string
---@param depth number
---@param isMiniMap boolean
---@param trackCamera boolean
function CUIWorldView:__init(parentControl, cameraName, depth, isMiniMap, trackCamera)
end

---
function CUIWorldView:CameraReset()
end

---
---@param enable boolean
function CUIWorldView:EnableResourceRendering(enable)
end

---
---@return string
function CUIWorldView:GetRightMouseButtonOrder()
end

---
---@param unit Unit
---@return Vector2 | nil
function CUIWorldView:GetScreenPos(unit)
end

---
---@param getsCommands boolean
function CUIWorldView:GetsGlobalCameraCommands(getsCommands)
end

---
---@return boolean
function CUIWorldView:HasHighlightCommand()
end

---
---@return boolean
function CUIWorldView:IsCartographic()
end

---
---@param camera Camera
function CUIWorldView:IsInputLocked(camera)
end

---
---@return boolean
function CUIWorldView:IsResourceRenderingEnabled()
end

---
---@param camera Camera
function CUIWorldView:LockInput(camera)
end

--- Given a point in world space, project the point to control space
---@param position Vector
---@return Vector2
function CUIWorldView:Project(position)
end

---
---@param cartographic boolean
function CUIWorldView:SetCartographic(cartographic)
end

---
---@param enabled boolean
function CUIWorldView:SetHighlightEnabled(enabled)
end

---
---@return boolean
function CUIWorldView:ShowConvertToPatrolCursor()
end

---
---@param camera Camera
function CUIWorldView:UnlockInput(camera)
end

--- Cause the world to zoom based on wheel rotation event
---@param x number
---@param y number
---@param wheelRot number
---@param wheelDelta number
function CUIWorldView:ZoomScale(x, y, wheelRot, wheelDelta)
end


return CUIWorldView
