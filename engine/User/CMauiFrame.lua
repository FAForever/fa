---@meta

---@class moho.frame_methods : moho.control_methods
local CMauiFrame = {}

---
function CMauiFrame:GetTargetHead()
end

---
---@return number
function CMauiFrame:GetTopmostDepth()
end

---
---@param head number
function CMauiFrame:SetTargetHead(head)
end

--- Will crash the game
---@deprecated
function CMauiFrame.ClearChildren()
end

return CMauiFrame
