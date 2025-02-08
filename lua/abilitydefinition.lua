--
-- Ability Definitions
--

--- Defines the default behavior of ability buttons in `orders.lua` for each `ScriptTask`'s `TaskName`.  
--- The `OrderInfo` here has the `OrderInfo` of `UnitBlueprint.Abilities` merged onto it.  
--- The `OrderInfo.behavior` is overwritten in `orders.lua`.
---@type table<string, OrderInfo>
abilities = {
    ['TargetLocation'] = {
        preferredSlot = 8,
        script = 'TargetLocation',
    },
}
