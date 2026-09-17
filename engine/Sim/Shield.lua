---@meta

--- Note that `Army` and `Owner: integer` are unused compared to EntitySpec
---@see _c_CreateShield
---@class CShieldSpec
---@field Owner? moho.entity_methods

--- A shield is an entity with special damage processing for area damage.
--- 
--- Everything else like health, regen, collision shape, mesh, etc. needs
--- to be implemented by the shield lua class.
---
---@see Entity.RegenRate # For shield assist behavior
---@class moho.shield_methods : moho.entity_methods
local Shield = {}

return Shield
