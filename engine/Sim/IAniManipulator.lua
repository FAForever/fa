--- Class IAniManipulator
-- @classmod Sim.IAniManipulator

---
--  Manipulator:Disable() -- disable a manipulator. This immediately removes it from the bone computation, which may result in the bone's position snapping.
function IAniManipulator:Disable()
end

---
--  Manipulator:Enable() -- enable a manipulator. Manipulators start out enabled so you only need this after calling Disable().
function IAniManipulator:Enable()
end

---
--  Manipulator:SetPrecedence(integer) -- change the precedence of this manipulator. Manipulators with higher precedence run first.
function IAniManipulator:SetPrecedence(integer)
end

---
--
function IAniManipulator:moho.manipulator_methods()
end

