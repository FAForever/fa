---@declare-global
---@class moho.blip_methods : moho.entity_methods
local ReconBlip = {}

---
---@return BlueprintBase
function ReconBlip:GetBlueprint()
end

---
---@return Unit
function ReconBlip:GetSource()
end

---
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
