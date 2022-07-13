---@declare-global
---@class moho.manipulator_methods
local CManipulator = {}
---
--  Manipulator:Disable() -- disable a manipulator. This immediately removes it from the bone computation, which may result in the bone's position snapping.
function CManipulator:Disable()
end

---
--  Manipulator:Enable() -- enable a manipulator. Manipulators start out enabled so you only need this after calling Disable().
function CManipulator:Enable()
end

---
--  Manipulator:SetPrecedence(integer) -- change the precedence of this manipulator. Manipulators with higher precedence run first.
function CManipulator:SetPrecedence(integer)
end

function CManipulator:Destroy()
end

return CManipulator
