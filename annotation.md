
# Annotating

All future contributions should be properly annotated. With it [our Lua extension](https://github.com/FAForever/fa-lua-vscode-extension) is able to provide intellisense support for our game, mod and campaign developers. You can find all the supported annotations on the [official repository](https://github.com/sumneko/lua-language-server/wiki/EmmyLua-Annotations). Note that the annotations supports markdown.

## Conventions

In general the following conventions apply:

- All comments should be in the declarative mood
- All comments should be as extensive as required, but not needlessly descriptive. They should atleast define the default value (if applicable)
- All functions should at least be annotated with `@param` for parameters, `@return` for return values, `@see` for similar alternatives (if applicable) and `@deprecated` if a better alternative exists
- All annotations with `@param` and `@return` require their type to be defined
- The annotation order is the description and then: `@deprecation`, `@see`, `@param` and at last `@return` if they are applicable

And a few specifics:

- A function that returns multiple values should have multiple `@return`, each on a separate line
- A comment should not have a space ( ) before the first word
- A comment should not end with a dot (.), but it can be used between sentences
- Varargs `...` should be documented as: `@param ... <type> <description>`, it shouldn't use `@vararg`

## Examples

In general, all annotated code in the repository is a good example. Some was written before these guidelines were written. Therefore we'll include some good examples for you to look at.

```lua
--- Attaches a beam between two entities.
---@param entityA Entity | Unit | Prop
---@param boneA number | string
---@param entityB Entity | Unit | Prop
---@param boneB number | string
---@param army number
---@param blueprint BeamBlueprint
---@return moho.IEffect
function AttachBeamEntityToEntity(entityA, boneA, entityB, boneB, army, blueprint)
    -- (...)
end
```

```lua
--- Takes transports from the transports pool and loads units them with units. Once ready a scenario variable can be set. Can wait on another scenario variable. Attempts to land at the location with the least threat and uses the accompanying attack chain for the units that have landed.
--- | Platoon data value | Description |
--- | ------------------ | ----------- |
--- | ReadyVariable      | `ScenarioInfo.VarTable[ReadyVariable]` Set when all units are on the transports
--- | WaitVariable       | `ScenarioInfo.VarTable[WaitVariable]` Needs to be set before the transports can leave
--- | LandingList        | (REQUIRED or LandingChain)               
--- | LandingChain       | (REQUIRED or LandingList)
--- | TransportReturn    | Location for transports to return to (they will attack with the land units if this isn't set)
--- | TransportChain     | (REQUIRED or TransportRoute)
--- | AttackPoints       | (REQUIRED or AttackChain or PatrolChain) The platoon attacks the highest threat first
--- | AttackChain        | (REQUIRED or AttackPoints or PatrolChain)
--- | PatrolChain        | (REQUIRED or AttackChain or AttackPoints)
---@param platoon Platoon
function LandAssaultWithTransports(platoon)
```

Note that the latter is from `scenarioplatoonai.lua` and that file contains a series of platoon behaviors. Because of its setup, the parameters of the function are send via `platoon.PlatoonData` instead of as separate parameters. We can't change this - but via a markdown table we can still help the user to understand what parameters are there.

```lua
---@class AIBrain : moho.aibrain_methods
---@field Status "Defeat" | "Victory" | "InProgress" | "Draw"
---@field BrainType 'Human' | 'AI'
---@field EnergyExcessThread thread
AIBrain = Class(moho.aibrain_methods) {

    -- The state of the brain in the match
    Status = 'InProgress',

    --- (...)

    --- Human brain functions handled here
    ---@param self AIBrain
    ---@param planName string
    OnCreateHuman = function(self, planName)
        self:CreateBrainShared(planName)
        self.BrainType = 'Human'
    end,

    --- (...)
}
```

```lua
---@class BaseManager
---@field Active boolean
---@field AIBrain AIBrain
BaseManager = ClassSimple {

    --- (...)

    Create = function(self)
        self.Trash = TrashBag()
        self.Active = false
        self.AIBrain = false
    end,

    --- (...)

}
```

Two examples of annotating a class. Note that fields need to be added manually, specifically those that are populated in the instance of a class.
