---@meta

---@class moho.text_methods : moho.control_methods
---@field FontAscent LazyVar<number>
---@field FontDescent LazyVar<number>
---@field FontExternalLeading LazyVar<number>
---@field TextAdvance LazyVar<number>
local CMauiText = {}

---
---@param text string
---@return number
function CMauiText:GetStringAdvance(text)
end

---
---@return string
function CMauiText:GetText()
end

---
---@param doCenter boolean
function CMauiText:SetCenteredHorizontally(doCenter)
end

---
---@param doCenter boolean
function CMauiText:SetCenteredVertically(doCenter)
end

---
---@param shadow boolean
function CMauiText:SetDropShadow(shadow)
end

--- Causes the control to only render as many characters as fit in its width
---@param clip boolean
function CMauiText:SetNewClipToWidth(clip)
end

---
---@param color string
function CMauiText:SetNewColor(color)
end

---
---@param family string
---@param pointsize number
function CMauiText:SetNewFont(family, pointsize)
end

---
---@param text string
function CMauiText:SetText(text)
end

return CMauiText
