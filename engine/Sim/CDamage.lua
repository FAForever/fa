---@meta

---@class moho.CDamage This particular class is not made approachable in Lua, and it appears to be unfinished implementation-wise. This is therefore merely a dummy class
---@deprecated
local CDamage = {}

---
---@return Entity | Projectile | Prop | Unit
function CDamage:GetInstigator()
end

---
--  CDamage:GetTarget()
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
