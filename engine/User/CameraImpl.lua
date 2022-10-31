---@meta

---@class Camera
local CameraImpl = {}


---@class UserCameraSettings 
---@field Zoom number       # See also `CameraImpl:GetFocusPosition()`
---@field Pitch number
---@field Heading number
---@field Focus Vector      # See also `CameraImpl:GetFocusPosition()`

---@alias UserCameraAccelerationModes 'Linear' | 'FastInSlowOut' | 'SlowInOut'

---
function CameraImpl:EnableEaseInOut()
end

--- Returns the focus point (on the terrain) of the center of the screen
---@return Vector
function CameraImpl:GetFocusPosition()
end

--- Returns the highest possible zoom distance
---@return number
function CameraImpl:GetMaxZoom()
end

--- Returns the lowest possible zoom distance
---@return number
function CameraImpl:GetMinZoom()
end

--- Returns the target zoom distance
---@return number
function CameraImpl:GetTargetZoom()
end

--- Returns the current zoom distance
---@return number
function CameraImpl:GetZoom()
end

--- Disables rotating the camera
function CameraImpl:HoldRotation()
end

--- Transforms the camera to the given position, orientation and zoom
---@param position Vector
---@param orientationHPR Vector
---@param zoom number
---@param seconds number
function CameraImpl:MoveTo(position, orientationHPR, zoom, seconds)
end

--- Transforms the camera to be able to view the entire region
---@param region Rectangle
---@param seconds? number
function CameraImpl:MoveToRegion(region, seconds)
end

--- Third-person like camera movement
---@param ent Unit
---@param pitchAdjust boolean
---@param zoom number
---@param seconds number
---@param transition any
function CameraImpl:NoseCam(ent, pitchAdjust, zoom, seconds, transition)
end

--- Resets the camera, including console commands applied to it
function CameraImpl:Reset()
end

--- Applies the provided settings to the camera
---@see `CameraImpl:SaveSettings` to retrieve the settings
---@param settings UserCameraSettings
function CameraImpl:RestoreSettings(settings)
end

--- Reverts the camera to the basic rotation scheme
function CameraImpl:RevertRotation()
end

--- Returns the current camera settings
---@see `CameraImpl:RestoreSettings` to apply the settings
---@return UserCameraSettings
function CameraImpl:SaveSettings()
end

--- ???
---@param accTypeName UserCameraAccelerationModes
function CameraImpl:SetAccMode(accTypeName)
end

--- Sets zoom scale to allow zooming past or before the point where map fills control
function CameraImpl:SetMaxZoomMult()
end

--- 
---@param zoom any
function CameraImpl:SetTargetZoom(zoom)
end

--- Zooms the camera
---@param zoom any
---@param seconds any
function CameraImpl:SetZoom(zoom, seconds)
end

--- Snaps the camera to the given position, orientation and zoom
---@param position any
---@param orientationHPR any
---@param zoom any
function CameraImpl:SnapTo(position, orientationHPR, zoom)
end

--- Spins and rotates the camera
---@param headingRate number
---@param zoomRate? number
function CameraImpl:Spin(headingRate, zoomRate)
end

--- ???
---@param ents UserUnit[]
---@param zoom number
---@param seconds number
function CameraImpl:TargetEntities(ents, zoom, seconds)
end

--- Tracks several entities at a given zoom
---@param ents UserUnit[]
---@param zoom number
---@param seconds number
function CameraImpl:TrackEntities(ents, zoom, seconds)
end

--- Use the game clock for interval checks, useful if the game is slowed down during a cinemation. Defaults to using the system clock
function CameraImpl:UseGameClock()
end

--- use the system clock for interval checks, useful if the game is slowed down during a cinemation
function CameraImpl:UseSystemClock()
end

return CameraImpl
