---@meta

---@class moho.WldUIProvider_methods : Destroyable
local CLuaWldUIProvider = {}

---
function CLuaWldUIProvider:Destroy()
end

--- Called by the engine when the world starts loading.
---@type nil | fun(self: WldUIProvider)
CLuaWldUIProvider.StartLoadingDialog = nil

--- Engine never calls this, but the method exists.
---@type nil | fun(self: WldUIProvider, elapsedTime: number)
CLuaWldUIProvider.UpdateLoadingDialog = nil

--- Called by the engine when the world finishes loading.
---@type nil | fun(self: WldUIProvider)
CLuaWldUIProvider.StopLoadingDialog = nil

--- Called by the engine after `StopLoadingDialog`.
---@type nil | fun(self: WldUIProvider): string[]?
CLuaWldUIProvider.GetPrefetchTextures = nil

--- Called by the engine after prefetching textures.
---@type nil | fun(self: WldUIProvider, isReplay: boolean)
CLuaWldUIProvider.CreateGameInterface = nil

--- Called by the engine when the world is loaded locally but online clients aren't ready.
---@type nil | fun(self: WldUIProvider)
CLuaWldUIProvider.StartWaitingDialog = nil

--- Engine never calls this, but the method exists.
---@type nil | fun(self: WldUIProvider, elapsedTime: number)
CLuaWldUIProvider.UpdateWaitingDialog = nil

--- Called by the engine when all online clients become ready.
---@type nil | fun(self: WldUIProvider)
CLuaWldUIProvider.StopWaitingDialog = nil

--- Called by the engine after everyone is connected and world starts playing.
---@type nil | fun(self: WldUIProvider)
CLuaWldUIProvider.OnStart = nil

--- Called by the engine when ending the game session or closing the app.
---@type nil | fun(self: WldUIProvider)
CLuaWldUIProvider.DestroyGameInterface = nil

return CLuaWldUIProvider
