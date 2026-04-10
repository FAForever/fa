---@meta

---@class moho.UIWorldView : moho.control_methods
---@overload fun(parentControl: Control, cameraName: string, depth: number, isMiniMap: boolean, trackCamera: boolean?): WorldView
local CUIWorldView = {}

---
---@param parentControl Control
---@param cameraName string
---@param depth number
---@param isMiniMap boolean
---@param trackCamera boolean?
function CUIWorldView:__init(parentControl, cameraName, depth, isMiniMap, trackCamera)
end

--- Resets the camera that is attached to the worldview.
function CUIWorldView:CameraReset()
end

--- If true, enables the rendering of custom world shapes. See also all shapes at /lua/ui/game/shapes.
--- 
--- This is introduced via an assembly patch. For more information: https://github.com/FAForever/FA-Binary-Patches/pull/47
---@param bool boolean
function CUIWorldView:SetCustomRender(bool)
end

---Projects multiple vectors at once.
---@generic T
---@param positions table<T, Vector>
---@return table<T, Vector2>
function CUIWorldView:ProjectMultiple(positions)
end

--- If true, enables the rendering of resources. Note that resources can **never** be rendered when the camera is in free mode.
---@param enable boolean
function CUIWorldView:EnableResourceRendering(enable)
end

--- Is set when our mouse is over a hostile unit, reclaim, etc. and returns nil if we're in command mode.
---@return 
---| 'RULEUCC_Reclaim' 
---| 'RULEUCC_Attack' 
---| 'RULEUCC_Move' 
---| 'RULEUCC_Guard' 
---| 'RULEUCC_Repair' 
---| 'RULEUCC_Capture'
---| 'RULEUCC_CallTransport'
---| 'RULEUCC_Transport'
---| nil
function CUIWorldView:GetRightMouseButtonOrder()
end

--- Translates the world position of the unit to screen space.
---@param unit Unit
---@return Vector2 | nil
function CUIWorldView:GetScreenPos(unit)
end

--- Flag to determine what camera should receive the global camera commands such as moving with the arrow keys.
---@param getsCommands boolean
function CUIWorldView:GetsGlobalCameraCommands(getsCommands)
end

--- Returns true if the cursor is highlighting a command.
---@return boolean
function CUIWorldView:HasHighlightCommand()
end

--- Returns true if the cartographic shared is applied.
---@see CUIWorldView:SetCartographic
---@return boolean
function CUIWorldView:IsCartographic()
end

--- Unlocks the input for the camera that is attached to this worldview. Used for cinematics.
---
--- See also `LockInput` to lock the input and `UnlockInput` to unlock the input.
---@param camera? Camera
function CUIWorldView:IsInputLocked(camera)
end

--- Returns true if the rendering of resources is enabled.
---
--- See also `EnableResourceRendering` to enable or disable the resource rendering.
---@return boolean
function CUIWorldView:IsResourceRenderingEnabled()
end

--- Unlocks the input for the camera that is attached to this worldview. Used for cinematics.
---
--- See also `UnlockInput` to unlock the input and `IsInputLocked` to determine the current state.
---@param camera Camera
function CUIWorldView:LockInput(camera)
end

--- Given a point in world space, project the point to control space
---@param position Vector
---@return Vector2
function CUIWorldView:Project(position)
end

--- If true, enables the cartographic shader.
---@param cartographic boolean
function CUIWorldView:SetCartographic(cartographic)
end

--- If true, enables the highlighting of commands.
---@param enabled boolean
function CUIWorldView:SetHighlightEnabled(enabled)
end

---
---@return boolean
function CUIWorldView:ShowConvertToPatrolCursor()
end

--- Unlocks the input for the camera that is attached to this worldview. Used for cinematics.
---
--- See also `LockInput` to lock the input and `IsInputLocked` to determine the current state.
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
