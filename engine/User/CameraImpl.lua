---@declare-global
---@class Camera
local CameraImpl = {}

---
function CameraImpl:EnableEaseInOut()
end

---
function CameraImpl:GetFocusPosition()
end

---
function CameraImpl:GetMaxZoom()
end

---
function CameraImpl:GetMinZoom()
end

---
function CameraImpl:GetTargetZoom()
end

---
function CameraImpl:GetZoom()
end

---
function CameraImpl:HoldRotation()
end

---
---@param position any
---@param orientationHPR any
---@param zoom any
---@param seconds any
function CameraImpl:MoveTo(position, orientationHPR, zoom, seconds)
end

---
---@param region any
---@param seconds? any
function CameraImpl:MoveToRegion(region, seconds)
end

---
---@param ent any
---@param pitchAdjust any
---@param zoom any
---@param seconds any
---@param transition any
function CameraImpl:NoseCam(ent, pitchAdjust, zoom, seconds, transition)
end

---
function CameraImpl:Reset()
end

---
---@param settings any
function CameraImpl:RestoreSettings(settings)
end

---
function CameraImpl:RevertRotation()
end

---
function CameraImpl:SaveSettings()
end

---
---@param accTypeName any
function CameraImpl:SetAccMode(accTypeName)
end

--- Sets zoom scale to allow zooming past or before the point where map fills control
function CameraImpl:SetMaxZoomMult()
end

---
---@param zoom any
function CameraImpl:SetTargetZoom(zoom)
end

---
---@param zoom any
---@param seconds any
function CameraImpl:SetZoom(zoom, seconds)
end

---
---@param position any
---@param orientationHPR any
---@param zoom any
function CameraImpl:SnapTo(position, orientationHPR, zoom)
end

---
---@param headingRate any
---@param zoomRate? any
function CameraImpl:Spin(headingRate, zoomRate)
end

---
---@param ents any
---@param zoom any
---@param seconds any
function CameraImpl:TargetEntities(ents, zoom, seconds)
end

---
---@param ents any
---@param zoom any
---@param seconds any
function CameraImpl:TrackEntities(ents, zoom, seconds)
end

---
function CameraImpl:UseGameClock()
end

---
function CameraImpl:UseSystemClock()
end

return CameraImpl
