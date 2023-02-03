---@meta

---@class moho.world_mesh_methods : Destroyable
local CUIWorldMesh = {}

---
function CUIWorldMesh:Destroy()
end

---
---@return Vector
function CUIWorldMesh:GetInterpolatedAlignedBox()
end

---
---@return Vector
function CUIWorldMesh:GetInterpolatedOrientedBox()
end

---
---@return Vector
function CUIWorldMesh:GetInterpolatedPosition()
end

---
---@return Vector
function CUIWorldMesh:GetInterpolatedScroll()
end

---
---@return Vector
function CUIWorldMesh:GetInterpolatedSphere()
end

---
---@return boolean
function CUIWorldMesh:IsHidden()
end

---
---@param param number
function CUIWorldMesh:SetAuxiliaryParameter(param)
end

---
---@param hidden boolean
function CUIWorldMesh:SetColor(hidden)
end

---
---@param param number
function CUIWorldMesh:SetFractionCompleteParameter(param)
end

---
---@param param number
function CUIWorldMesh:SetFractionHealthParameter(param)
end

---
---@param hidden boolean
function CUIWorldMesh:SetHidden(hidden)
end

---
---@param param number
function CUIWorldMesh:SetLifetimeParameter(param)
end

---
---@param spec table
function CUIWorldMesh:SetMesh(spec)
end

---
---@param scale Vector
function CUIWorldMesh:SetScale(scale)
end

---
---@param position Vector
---@param orientation? Quaternion
function CUIWorldMesh:SetStance(position, orientation)
end

return CUIWorldMesh
