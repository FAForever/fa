# Annotating

All future contributions should be properly annotated. With it [our Lua extension](https://github.com/FAForever/fa-lua-vscode-extension) is able to provide intellisense support for our game, mod and campaign developers. You can find all the supported annotations on the [LuaLS annotation reference](https://luals.github.io/wiki/annotations/). Note that the annotations supports markdown.

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

## Comment style

Comments say what a reader can't get from the code in a few seconds. Write them like a technical writer: short, plain words, and one line where possible.

### Rules

1. Every function and class gets typed `@param`, `@return` and `---@field` annotations. Its `---` description can be left out when it would only repeat the name.
2. The `---` description is what the language server shows on hover. It says what the function does and what a caller needs to know. Rationale and implementation details go in the body, at the top, before any logic.
3. Comments are declarative. State the fact, not the reasoning around the fact.
4. Use exact identifiers (`CAPTURABLE`, not "capturable units") and common words, not new terms.
5. Put a fact where it applies: engine behavior in the `engine/` stub, Lua behavior in the Lua file. Repeating a fact in a `---` description is fine when the hover needs it.
6. No period after the last sentence, and no em-dashes (`—`). Split into separate sentences, or use a colon, a comma or parentheses.

### Leave out

- What the name or the code already says.
- Lists of callers ("Used by the receive path and..."). They go out of date.
- The history of the change ("now", "instead of", "no longer", "previously"). That goes in the commit message.
- Section banners (`--------` lines with a heading).
- Standard Lua behavior, and rules the guides already state.
- What the type in `@param` or `@return` already says.
- Numbers that the code or a benchmark result already holds. State the comparison, as a multiple.

### Keep

- Engine behavior, and mistakes that are easy to make.
- Why a non-obvious construct exists, such as an unrolled loop or an intentional space in a string.
- Hooks and behavior in other files that the code doesn't show.
- When to use an optional parameter.
- `@see` links between functions that send and receive the same data, so a reader can jump over the engine.

### Before finishing

Reread every comment you wrote. Delete each one whose removal loses nothing a reader gets from the code in a few seconds, and shorten the rest.

### Examples

The description repeats the name:

```lua
-- before
--- Shows the chat window.
function OpenWindow()

-- after
function OpenWindow()
```

The description lists callers and explains the implementation:

```lua
-- before
--- Appends a local-only system line. Used by the slash-command dispatcher
--- to surface parse/accept errors without sending over the network.
---@param text string
function AppendLocalSystemMessage(text)

-- after
--- Shows a system line to the local player only
---@param text string
function AppendLocalSystemMessage(text)
```

The comment repeats the code below it, so it is removed:

```lua
-- before
IsValidEntry = function(entry)
    -- Gates on the per-army mute map and the `links` option. Camera
    -- or Location both qualify as "link" messages: either surfaces
    -- the camera-link affordance on the row.
    if entry == nil then return false end
    local options = ChatConfigModel.GetOptions()
    if options.muted and entry.ArmyID and options.muted[entry.ArmyID] then
```

Inline comments explain more than the value needs:

```lua
-- before
Drill.SparkLife = { 9, 14 } -- ticks the orbs live, give or take 40%: with their speed, how far they fly
Drill.Jets = 16 -- around the cone, close enough together to draw its surface

-- after
Drill.SparkLife = { 9, 14 } -- ticks, +-40%
Drill.Jets = 16 -- around the cone
```

Rationale in the hover, joined with an em-dash:

```lua
-- before
--- Returns the army index that authored the current command — the engine
--- clears the source between command dispatches so a nil is normal during
--- idle ticks. Returns nil if there is no source.
---@return integer?
function GetCurrentCommandSourceArmy()

-- after
--- Returns the army that issued the current command, or `nil` outside a command
---@return integer?
function GetCurrentCommandSourceArmy()
    -- the engine clears the source between commands, so `nil` is normal during idle ticks
```

## Examples

In general, all annotated code in the repository is a good example. Some was written before these guidelines were written. Therefore we'll include some good examples for you to look at.

```lua
--- Attaches a beam between two entities.
---@param entityA Entity | Unit | Prop
---@param boneA number | string
---@param entityB Entity | Unit | Prop
---@param boneB number | string
---@param army Army
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

        -- human-only behavior
        self.EnergyExcessThread = ForkThread(self.ToggleEnergyExcessUnitsThread, self)
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

## Class fields

Every field assigned to `self` inside a constructor or initialization function (`__init`, `__post_init`, `Create`, `OnCreate`, etc.) must have a matching `---@field` annotation on the class definition. This gives the language server full type information across the whole file and makes the class self-documenting at a glance.

### Rule

Annotate the class immediately above the class declaration. List every field in the order it appears in the constructor. For fields whose type is an array of a named struct, define that struct as its own `---@class` above the main class.

### Example

```lua
---@class UIChatConfigColorRow
---@field label Text
---@field combo BitmapCombo
---@field key   string

---@class UIChatConfigInterface : Window
---@field LabelColors    Text
---@field ColorRows      UIChatConfigColorRow[]
---@field LabelFontSize  Text
---@field SliderFontSize IntegerSlider
---@field LabelBehavior  Text
---@field Checkboxes     Checkbox[]
---@field BtnApply       Button
---@field BtnOk          Button
local ChatConfigInterface = ClassUI(Window) {
    __init = function(self, parent, ...)
        self.LabelColors    = UIUtil.CreateText(...)
        self.ColorRows      = {}
        self.LabelFontSize  = UIUtil.CreateText(...)
        self.SliderFontSize = IntegerSlider(...)
        self.LabelBehavior  = UIUtil.CreateText(...)
        self.Checkboxes     = {}
        self.BtnApply       = UIUtil.CreateButtonStd(...)
        self.BtnOk          = UIUtil.CreateButtonStd(...)
    end,
}
```

### What counts as a field

- Every `self.Foo` written in any constructor or init function (`__init`, `__post_init`, `Create`, `OnCreate`, etc.).
- Fields inherited from the parent class do **not** need repeating — the `: Parent` in the `---@class` declaration inherits them.
- Methods defined inside the class table (`Foo = function(self, ...) end` entries) do **not** need `---@field` — the language server picks them up from the function signature.
- Temporary locals inside a method are not fields and need no annotation.
- Optional fields (assigned only on some code paths) should be marked with `?`, e.g. `---@field DebugBG? Bitmap`.
