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
function ReconBlip:IsKnownFake()
end

---
---@return boolean
function ReconBlip:IsMaybeDead()
end

---
---@return boolean
function ReconBlip:IsOnOmni()
end

---
---@return boolean
function ReconBlip:IsOnRadar()
end

---
---@return boolean
function ReconBlip:IsOnSonar()
end

---
---@return boolean
function ReconBlip:IsSeenEver()
end

---
---@return boolean
function ReconBlip:IsSeenNow()
end

return ReconBlip
