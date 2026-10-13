---@meta

---@class moho.shield_methods : moho.entity_methods
local Shield = {}

--- Called by the engine during `DamageArea` for each enemy shield the damage sphere touches from
--- outside. Return the amount of damage the shield absorbs: the engine subtracts it from the
--- damage dealt to entities inside the shield.
---@type nil | fun(self: Shield, instigator: Unit | Projectile | Entity | nil, amount: number, damageType: DamageType): number
Shield.OnGetDamageAbsorption = nil

return Shield
