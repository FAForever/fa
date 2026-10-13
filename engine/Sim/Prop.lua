---@meta

---@class moho.prop_methods : moho.entity_methods
local Prop = {}

---@return PropBlueprint
function Prop:GetBlueprint()
end

function Prop:AddBoundedProp()
end

--- Called by the engine each time a reclaimer changes how much of the prop is left
---@type nil | fun(self: Prop)
Prop.BeingReclaimed = nil

--- Called by the engine when a moving unit pushes into the prop. Naval units don't trigger it.
---@type nil | fun(self: Prop, other: Unit, nx: number, ny: number, nz: number, depth: number)
Prop.OnCollision = nil

--- Called by the engine when the prop is created
---@type nil | fun(self: Prop)
Prop.OnCreate = nil

--- Called by the engine when the prop is killed
---@type nil | fun(self: Prop, instigator: Unit | Projectile | Entity | nil, type: DamageType, overkillRatio: number)
Prop.OnKilled = nil

--- Called by the engine when the prop is reclaimed. `reclaimer` is nil when the prop's reclaim
--- progress reaches zero, after which the engine destroys the prop.
---@type nil | fun(self: Prop, reclaimer?: Unit)
Prop.OnReclaimed = nil

return Prop
