---@declare-global
---@class moho.userDecal_methods
local ScriptedDecal = {}

---
function ScriptedDecal:Destroy()
end

--- Set the position based on world coords
function ScriptedDecal:SetPosition()
end

--- Set the position based on screen space mouse coords
function ScriptedDecal:SetPositionByScreen()
end

--- Scale the text
function ScriptedDecal:SetScale()
end

---
--  Set the texture and add it to the decal manager
function ScriptedDecal:SetTexture()
end

return ScriptedDecal
