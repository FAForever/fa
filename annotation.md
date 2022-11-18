# Annotations

All contributions should be properly annotated.
With it, [our Lua extension](https://github.com/FAForever/fa-lua-vscode-extension) is able to provide intellisense support for our game, mod, and campaign developers.
You can find all the supported annotations on the [official repository](https://github.com/sumneko/lua-language-server/wiki/EmmyLua-Annotations).
Note that annotations support markdown.

## Conventions

In general the following conventions apply:

- Always use three dashes to start an annotation
- All function annotation comments should be in the declarative mood
    * Inline comments inside a function or in a file header can (and usually will) be in the descriptive mood, however
- All comments should only say as much as they need to
    * In particlar, comments on function parameters that merely rephrase the parameter name are distracting (they only make a reader of the code have to process more without adding anything of value)
- All classes and functions should have all of the annotations that are applicable - and those only - the same order
- Often used type unions should be packaged inside of an `@alias` - and definitely reuse existing ones!
    * If too long, each item should be put on a separate line

Long alias example

```lua
---@alias Layer
---| "Land"
---| "Seabed"
---| "Sub"
---| "Water"
---| "Air"
---| "Orbital"
```

And a few specifics:

- Place free-floating annotation classes and aliases at the top of the file, below the imports
- Place a blank line before a `@class` annotation, and, if not attached to a variable, after as well
    * Just make sure that any `@alias` annotations can't be confused for a `@field` of the class at a glance, or vice-versa 
- A function that returns multiple values should have multiple `@return`, each on a separate line and named
    * Only group returns onto one line if they logically belong together
- A comment should have a space before the first word and after the dash
- A one-sentence comments should not end with a full-stop "."
- The colon indicating class bases should have a space on either side of it
- If the description is empty, remove the entire line
- Use `any` instead of `unknown`
- Use `@param arg? type` instead of `@param arg type?`
- Prefer `type[]` over `table<number, type>` for arrays
- Prefer `@param arg? type` over `@param arg type|nil` for optional arguments
    * However, if the argument specifically treats `nil` different (rather than checking for being optional), the later is appropriate
    * All parameters after an optional one should also be optional, or otherwise use an `@overload` or the `type|nil` type
- Prefer `@return type?` over `@return type|nil` when the return is `nil` due not returning anything (rather than an actual `nil`), either in the implicit return at the end of the function or explicitly.
If `nil` is returned, or otherwise means something special different from an absent return, then the later is appropriate.

    In general, if there's a `nil`, the reader will be looking for it in the code. 
- Varargs `...` should be documented as: `@param ... <type> <description>`, instead of `@vararg`

## Function prototype

The preferred annotation order for a function (note that you will likely not use all of these for any one function):

```lua
---@deprecated
---@overload fun(a: type, b: type): type
--- Description
---@see
---@generic T
---@param a type  optional comment
---@param b type  optional comment
---@return type # optional comment
function fn(a, b) end
```

or with multiple returns:

```lua
...
---@param b type   optional comment
---@return type A  optional comment
---@return type B  optional comment
function fn(a, b) end
```

## Class prototype

```lua
---@deprecated
--- Description
---@class Class : Base1, Base2
---@field method1(): type
---@field method2(): type
---
---@field field1
---@field field2
---
---@field private1
---@field private2
ClassName = Class {}
```

Note that not every field and method needs to written in the class definition.
Intellisense will automatically pick up fields and methods added to a class.

## Examples

In general, all annotated code in the repository is a good example.
Some was written before these guidelines were written.
Therefore, we'll include some good examples for you to look at.

```lua
--- Attaches a beam between two entities
---@param entityA BoneObject
---@param boneA Bone
---@param entityB BoneObject
---@param boneB Bone
---@param army Army
---@param blueprint BeamBlueprint
---@return moho.IEffect
function AttachBeamEntityToEntity(entityA, boneA, entityB, boneB, army, blueprint)
    -- (...)
end
```

```lua
--- Takes transports from the transports pool and loads units them with units. Once ready a
--- scenario variable can be set. Can wait on another scenario variable. Attempts to land at the
--- location with the least threat and uses the accompanying attack chain for the units that have
--- landed.
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

Note that the latter is from `scenarioplatoonai.lua` and that file contains a series of platoon behaviors.
Because of its setup, the parameters of the function are send via `platoon.PlatoonData` instead of as separate parameters.
We can't change this - but via a markdown table we can still help the user to understand what parameters are there.

```lua
---@alias BrainType "AI" | "Human"
---@alias BrainState "Defeat" | "Victory" | "InProgress" | "Draw"

---@class AIBrain : moho.aibrain_methods
...
---@field Status BrainState
---@field BrainType BrainType
---@field EnergyExcessThread thread
AIBrain = Class(moho.aibrain_methods) {
    -- The state of the brain in the match
    Status = 'InProgress',

    ...

    --- Human brain functions handled here
    ---@param self AIBrain
    ---@param planName string
    OnCreateHuman = function(self, planName)
        self:CreateBrainShared(planName)
        self.BrainType = 'Human'

        -- human-only behavior
        self.EnergyExcessThread = ForkThread(self.ToggleEnergyExcessUnitsThread, self)
    end,

    ...
}
```

```lua
---@class BaseManager
---@field Active boolean
---@field AIBrain AIBrain
BaseManager = ClassSimple {
    ...

    ---@param self BaseManager
    Create = function(self)
        self.Trash = TrashBag()
        self.Active = false
        self.AIBrain = false
    end,

    ...
}
```

Two examples of annotating a class.
Note that fields usually need to be added manually, specifically those that are populated in the instance of a class or that get assigned an incorrect type.
