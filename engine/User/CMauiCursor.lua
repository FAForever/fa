---@meta

---@class moho.cursor_methods
local CMauiCursor = {}

---
function CMauiCursor:ResetToDefault()
end

---
---@param filename string
---@param hotspotX number
---@param hotspotY number
function CMauiCursor:SetDefaultTexture(filename, hotspotX, hotspotY)
end

---
---@param filename string
---@param hotspotX number
---@param hotspotY number
function CMauiCursor:SetNewTexture(filename, hotspotX, hotspotY)
end

---
function CMauiCursor:Show()
end

---
function CMauiCursor:Hide()
end

return CMauiCursor
