---@meta

---@class moho.WldUIProvider_methods : Destroyable
local CLuaWldUIProvider = {}

---
function CLuaWldUIProvider:Destroy()
end

--- Called by the engine when the world starts loading.
---@type fun(self: moho.WldUIProvider_methods)
CLuaWldUIProvider.StartLoadingDialog = nil

--- Engine never calls this, but the method exists.
---@type fun(self: moho.WldUIProvider_methods, elapsedTime: number)
CLuaWldUIProvider.UpdateLoadingDialog = nil

--- Called by the engine when the world finishes loading.
---@type fun(self: moho.WldUIProvider_methods)
CLuaWldUIProvider.StopLoadingDialog = nil

--- Called by the engine after `StopLoadingDialog`.
---@type fun(self: moho.WldUIProvider_methods): string[]?
CLuaWldUIProvider.GetPrefetchTextures = nil

--- Called by the engine after prefetching textures.
---@type fun(self: moho.WldUIProvider_methods, isReplay: boolean)
CLuaWldUIProvider.CreateGameInterface = nil

--- Called by the engine when the world is loaded locally but online clients aren't ready.
---@type fun(self: moho.WldUIProvider_methods)
CLuaWldUIProvider.StartWaitingDialog = nil

--- Engine never calls this, but the method exists.
---@type fun(self: moho.WldUIProvider_methods, elapsedTime: number)
CLuaWldUIProvider.UpdateWaitingDialog = nil

--- Called by the engine when all online clients become ready.
---@type fun(self: moho.WldUIProvider_methods)
CLuaWldUIProvider.StopWaitingDialog = nil

--- Called by the engine after everyone is connected and world starts playing.
---@type fun(self: moho.WldUIProvider_methods)
CLuaWldUIProvider.OnStart = nil

--- Called by the engine when ending the game session or closing the app.
---@type fun(self: moho.WldUIProvider_methods)
CLuaWldUIProvider.DestroyGameInterface = nil

return CLuaWldUIProvider
