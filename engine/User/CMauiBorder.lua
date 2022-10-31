---@meta

---@class moho.border_methods : moho.control_methods
local CMauiBorder = {}

--- Sets the textures of the border. Will leave the border edge alone if `nil`.
---@param vertical   string | nil
---@param horizontal string | nil
---@param upperLeft  string | nil
---@param upperRight string | nil
---@param lowerLeft  string | nil
---@param lowerRight string | nil
function CMauiBorder:SetNewTextures(vertical, horizontal, upperLeft, upperRight, lowerLeft, lowerRight)
end

---
---@param color string
function CMauiBorder:SetSolidColor(color)
end

return CMauiBorder
