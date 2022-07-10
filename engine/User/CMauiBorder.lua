---@declare-global
---@class moho.border_methods : moho.control_methods
local CMauiBorder = {}

--- Leaves the border edge alone if `nil`
---@param vertical string
---@param horizontal string
---@param upperLeft string
---@param upperRight string
---@param lowerLeft string
---@param lowerRight string
function CMauiBorder:SetNewTextures(vertical, horizontal, upperLeft, upperRight, lowerLeft, lowerRight)
end

---
---@param color string
function CMauiBorder:SetSolidColor(color)
end

return CMauiBorder
