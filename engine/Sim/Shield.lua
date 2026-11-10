---@meta

--- Passed to `_c_CreateShield`. Unlike `EntitySpec`, the engine reads only an entity `Owner`, and
--- ignores `Army` and an integer `Owner`
---@see _c_CreateShield
---@class CShieldSpec
---@field Owner? moho.entity_methods

---@class moho.shield_methods : moho.entity_methods
local Shield = {}

return Shield
