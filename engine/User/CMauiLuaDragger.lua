---@meta

---@class moho.dragger_methods : Destroyable
local CMauiLuaDragger = {}

---
function CMauiLuaDragger:Destroy()
end

--- Called by the engine when this dragger stops being the active dragger without being destroyed:
--- - `PostDragger` or an engine drag (camera, selection box, build or command drag) replaces it.
--- - The mouse button is released and `OnRelease` didn't destroy the dragger. The engine then calls
---   `OnRelease` and then `OnCancel`.
--- - Any world view is destroyed, or the UI Lua state is replaced.
---
--- Destroying the dragger removes it as the active dragger without calling this. There is an
--- active dragger only between `PostDragger` and the end of the drag
---@see PostDragger # Makes a dragger the active dragger
---@type nil | fun(self: Dragger)
CMauiLuaDragger.OnCancel = nil

--- Called by the engine when the mouse moves during the drag, with the cursor position in screen
--- coordinates
---@see PostDragger # Makes a dragger the active dragger
---@type nil | fun(self: Dragger, x: number, y: number)
CMauiLuaDragger.OnMove = nil

--- Called by the engine when the mouse button that `PostDragger` named is released, with the
--- cursor position in screen coordinates
---@see PostDragger # Makes a dragger the active dragger
---@type nil | fun(self: Dragger, x: number, y: number)
CMauiLuaDragger.OnRelease = nil

return  CMauiLuaDragger
