--*****************************************************************************
--* File: lua/modules/ui/game/wlduiprovider.lua
--* Author: Chris Blackwell
--* Summary: Responds to wld UI events and show appropriate UI
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

--- Responds to Wld UI Events to show appropriate UI
---@class WldUIProvider : moho.WldUIProvider_methods
---@overload fun(): WldUIProvider
WldUIProvider = ClassUI(moho.WldUIProvider_methods) {
    __init = function(self)
        InternalCreateWldUIProvider(self)
    end,

    --- Called by the engine when the world starts loading.
    ---@param self WldUIProvider
    StartLoadingDialog = function(self)
    end,

    --- Engine never calls this, but the method exists.
    ---@param self WldUIProvider
    ---@param elapsedTime number
    UpdateLoadingDialog = function(self, elapsedTime)
    end,

    --- Called by the engine when the world finishes loading.
    ---@param self WldUIProvider
    StopLoadingDialog = function(self)
    end,

    --- Called by the engine when the world is loaded locally but online clients aren't ready.
    ---@param self WldUIProvider
    StartWaitingDialog = function(self)
    end,

    --- Engine never calls this, but the method exists.
    ---@param self WldUIProvider
    ---@param elapsedTime number
    UpdateWaitingDialog = function(self, elapsedTime)
    end,

    --- Called by the engine when all online clients become ready.
    ---@param self WldUIProvider
    StopWaitingDialog = function(self)
    end,

    --- Called by the engine after prefetching textures.
    ---@param self WldUIProvider
    CreateGameInterface = function(self)
    end,

    --- Called by the engine when ending the game session or closing the app.
    ---@param self WldUIProvider
    DestroyGameInterface = function(self)
    end,

    --- Called by the engine after `StopLoadingDialog`.
    ---@param self WldUIProvider
    ---@return string[]?
    GetPrefetchTextures = function(self)
        return nil
    end,
}
