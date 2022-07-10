---@declare-global
---@class Camera
local Camera = {}

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
---@param position any
---@param orientationHPR any
---@param zoom any
---@param seconds any
function Camera:MoveTo(position, orientationHPR, zoom, seconds)
end

---
---@param region any
---@param seconds? any
function Camera:MoveToRegion(region, seconds)
end

---
---@param ent any
---@param pitchAdjust any
---@param zoom any
---@param seconds any
---@param transition any
function Camera:NoseCam(ent, pitchAdjust, zoom, seconds, transition)
end

---
function Camera:Reset()
end

---
---@param settings any
function Camera:RestoreSettings(settings)
end

---
function Camera:RevertRotation()
end

---
function Camera:SaveSettings()
end

---
---@param accTypeName any
function Camera:SetAccMode(accTypeName)
end

--- Set zoom scale to allow zooming past or before the point where map fills control
function Camera:SetMaxZoomMult()
end

---
---@param zoom any
function Camera:SetTargetZoom(zoom)
end

---
---@param zoom any
---@param seconds any
function Camera:SetZoom(zoom, seconds)
end

---
---@param position any
---@param orientationHPR any
---@param zoom any
function Camera:SnapTo(position, orientationHPR, zoom)
end

---
---@param headingRate any
---@param zoomRate? any
function Camera:Spin(headingRate, zoomRate)
end

---
---@param ents any
---@param zoom any
---@param seconds any
function Camera:TargetEntities(ents, zoom, seconds)
end

---
---@param ents any
---@param zoom any
---@param seconds any
function Camera:TrackEntities(ents, zoom, seconds)
end

---
function Camera:UseGameClock()
end

---
function Camera:UseSystemClock()
end

