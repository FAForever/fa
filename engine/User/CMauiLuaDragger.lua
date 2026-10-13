---@meta

---@class moho.dragger_methods : Destroyable
local CMauiLuaDragger = {}

---
function CMauiLuaDragger:Destroy()
end

--- Called by the engine when another dragger replaces this one as the active dragger.
---@type nil | fun(self: Dragger)
CMauiLuaDragger.OnCancel = nil

--- Called by the engine when the mouse moves during the drag, with the cursor position in screen
--- coordinates.
---@type nil | fun(self: Dragger, x: number, y: number)
CMauiLuaDragger.OnMove = nil

--- Called by the engine when the mouse button is released, with the cursor position in screen
--- coordinates.
---@type nil | fun(self: Dragger, x: number, y: number)
CMauiLuaDragger.OnRelease = nil

return  CMauiLuaDragger
