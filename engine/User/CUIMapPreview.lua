---@meta

---@class moho.ui_map_preview_methods : moho.control_methods
local CUIMapPreview = {}

---
function CUIMapPreview:ClearTexture()
end

---
---@param textureName string
---@return boolean
function CUIMapPreview:SetTexture(textureName)
end

---
---@param mapName string
---@return boolean
function CUIMapPreview:SetTextureFromMap(mapName)
end

return CUIMapPreview
