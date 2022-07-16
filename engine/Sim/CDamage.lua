---@declare-global
---@class moho.CDamage
local CDamage = {}

---
---@return Entity | Projectile | Prop | Unit
function CDamage:GetTarget()
end

---
---@param instigator Unit
function CDamage:SetInstigator(instigator)
end

---
---@param target Entity | Projectile | Prop | Unit
function CDamage:SetTarget(target)
end

return CDamage
