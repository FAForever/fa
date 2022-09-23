---@meta

---@class moho.userDecal_methods : Destroyable
local ScriptedDecal = {}

---
function ScriptedDecal:Destroy()
end

--- Sets the position based on world coords
---@param pos Vector
function ScriptedDecal:SetPosition(pos)
end

--- Sets the position based on screen space mouse coords
---@param pos Vector2
function ScriptedDecal:SetPositionByScreen(pos)
end

--- Scales the text
---@param scale Vector
function ScriptedDecal:SetScale(scale)
end

--- Sets the texture and add it to the decal manager
---@param tex string
function ScriptedDecal:SetTexture(tex)
end

return ScriptedDecal
