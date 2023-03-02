-- This functionallity is unimplemented and will not work
---@meta

---@deprecated
---@class moho.histogram_methods : moho.control_methods
local CMauiHistogram = {}

---
---@param data {color: string, data: number[]}[]
function CMauiHistogram:SetData(data)
end

--- Sets the increment of the X-axis. If the axis needs to resize (e.g. a value comes in that's higher than
--- the current maximum) then it will do so in increments of this value.
---@param inc number
function CMauiHistogram:SetXIncrement(inc)
end

--- Sets the increment of the Y-axis. If the axis needs to resize (e.g. a value comes in that's higher than
--- the current maximum) then it will do so in increments of this value.
---@param inc number
function CMauiHistogram:SetYIncrement(inc)
end

return CMauiHistogram
