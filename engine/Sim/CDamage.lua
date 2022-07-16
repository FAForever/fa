---@declare-global
---@class moho.CDamage This particular class is not made approachable in Lua, and it appears to be unfinished implementation-wise. This is therefore merely a dummy class
---@deprecated
local CDamage = {}

---
---@return Entity
function CDamage:GetInstigator()
end

---
--  CDamage:GetTarget()
function CDamage:GetTarget()
end

---
--  CDamage:SetInstigator()
function CDamage:SetInstigator()
end

---
--  CDamage:SetTarget()
function CDamage:SetTarget()
end

return CDamage

