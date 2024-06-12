---@meta

---@class moho.blip_methods : moho.entity_methods
local ReconBlip = {}

---
---@return UnitBlueprint
function ReconBlip:GetBlueprint()
end

--- Returns the unit, even for blips that are part of jamming / spoofing
---@return Unit
function ReconBlip:GetSource()
end

--- Does not appear to function
---@deprecated
---@return boolean
function ReconBlip:IsKnownFake(army)
end

---
---@param army number
---@return boolean
function ReconBlip:IsMaybeDead(army)
end

---
---@param army number
---@return boolean
function ReconBlip:IsOnOmni(army)
end

---
---@param army number
---@return boolean
function ReconBlip:IsOnRadar(army)
end

---
---@param army number
---@return boolean
function ReconBlip:IsOnSonar(army)
end

---
---@param army number
---@return boolean
function ReconBlip:IsSeenEver(army)
end

---
---@param army number
---@return boolean
function ReconBlip:IsSeenNow(army)
end

return ReconBlip
