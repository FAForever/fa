---@meta

---@class moho.prop_methods : moho.entity_methods
local Prop = {}

---@return PropBlueprint
function Prop:GetBlueprint()
end

function Prop:AddBoundedProp()
end

--- Runs Lua callback then destroys the prop
--- 
---@see Prop.OnKilled
---@overload fun()
---@param instigator Unit
---@param damageType DamageType
---@param excessDamageRatio number
function Prop:Kill(instigator, damageType, excessDamageRatio)
end

---@type nil | fun(self: moho.prop_methods, instigator: moho.entity_methods, type: DamageType, excessDamageRatio: number)
Prop.OnKilled = nil

return Prop
