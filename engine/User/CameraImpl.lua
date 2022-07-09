
---@class Camera
Camera = {}

---
function Camera:EnableEaseInOut()
end

---
function Camera:GetFocusPosition()
end

---
function Camera:GetMaxZoom()
end

---
function Camera:GetMinZoom()
end

---
function Camera:GetTargetZoom()
end

---
function Camera:GetZoom()
end

---
function Camera:HoldRotation()
end

---
function Camera:MoveTo(position, orientationHPR, zoom, seconds)
end

---
function Camera:MoveToRegion(region, seconds?)
end

---
function Camera:NoseCam(ent, pitchAdjust, zoom, seconds, transition)
end

---
function Camera:Reset()
end

---
function Camera:RestoreSettings(settings)
end

---
function Camera:RevertRotation()
end

---
function Camera:SaveSettings()
end

---
function Camera:SetAccMode(accTypeName)
end

--- Set zoom scale to allow zooming past or before the point where map fills control
function Camera:SetMaxZoomMult()
end

---
function Camera:SetTargetZoom(zoom)
end

---
function Camera:SetZoom(zoom, seconds)
end

---
function Camera:SnapTo(position, orientationHPR, zoom)
end

---
function Camera:Spin(headingRate, zoomRate?)
end

---
function Camera:TargetEntities(ents, zoom, seconds)
end

---
function Camera:TrackEntities(ents, zoom, seconds)
end

---
function Camera:UseGameClock()
end

---
function Camera:UseSystemClock()
end

