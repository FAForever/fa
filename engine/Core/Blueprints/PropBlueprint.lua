---@meta

---@alias PropType "Tree" | "TreeGroup" | "Wreckage"

---@class PropBlueprint : EntityBlueprint
---@field Defense PropBlueprintDefense
---@field Display PropBlueprintDisplay
---@field Economy PropBlueprintEconomy
---@field Physics PropBlueprintPhysics
---@field ScriptClass PropType Class name for this prop
---@field ScriptModule FileName File to find class in

---@class PropBlueprintDefense
--- max health value for the prop
---@field MaxHealth number
--- starting health value for the prop
---@field Health number

---@class PropBlueprintDisplay
--- Name of mesh blueprint to use. Leave blank to use default mesh.
---@field MeshBlueprint string

---@class PropBlueprintEconomy
--- maximum reclaimable mass in this prop (taking damage removes some)
---@field ReclaimMassMax number
--- maximum reclaimable energy in this prop (taking damage removes some)
---@field ReclaimEnergyMax number
---@field ReclaimTimeMultiplier number
---@field ReclaimMassTimeMultiplier number
---@field ReclaimEnergyTimeMultiplier number

---@class PropBlueprintPhysics
---@field BlockPath boolean
