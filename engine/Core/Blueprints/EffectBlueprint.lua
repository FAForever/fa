---@meta

---@class EffectBlueprint : Blueprint
---@field HighFidelity boolean Allowed in high fidelity
---@field MedFidelity  boolean Allowed in medium fidelity
---@field LowFidelity  boolean Allowed in low fidelity

--- A curve made of linear segments defined by a set of points.
--- It defines the values for an effect at a specific time in an emitter's cycle.
---@class EffectCurve
---@field XRange number Defines what value of `x` corresponds to the end of the emitter's cycle. The emitter editor will default this to the cycle's tick count.
---@field Keys NamedPosition[]

---@class NamedPosition
---@field x number Time at the point on the curve, relative to `XRange`. Represents ticks in the emitter editor.
---@field y number Value at the point.
---@field z number Range within which the value is randomized.

--- Used by beam blueprints to interpolate the color/alpha of the beam between the start point and end point
---@class NamedQuaternion
---@field x number R
---@field y number G
---@field z number B
---@field w number A
