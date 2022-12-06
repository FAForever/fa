---@meta

---@class moho.manipulator_methods : Destroyable
local IAniManipulator = {}

---
function IAniManipulator:Destroy()
end

--- Disables a manipulator. This immediately removes it from the bone computation,
--- which may result in the bone's position snapping.
function IAniManipulator:Disable()
end

--- Enables a manipulator. Manipulators start out enabled so you only need this after calling `Disable()`.
function IAniManipulator:Enable()
end

--- Changes the precedence of this manipulator. Manipulators with higher precedence run first.
---@param precedence number
function IAniManipulator:SetPrecedence(precedence)
end

return IAniManipulator
