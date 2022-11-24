---@meta

---@class PropBlueprint : EntityBlueprint
---@field Display PropBlueprintDisplay Display information for the unit
---@field Defense PropBlueprintDefense Defense information for the unit

---@class PropBlueprintDisplay
---@field MeshBlueprint string Name of mesh blueprint to use. Leave blank to use default mesh.

---@class PropBlueprintDefense
---@field MaxHealth number    Max health value for the prop
---@field Health number       Starting health value for the prop

---@class PropBlueprintEconomy
---@field ReclaimMassMax number    Max Reclaimable mass resource.
---@field ReclaimEnergyMax number  Max Reclaimable Energy resource.