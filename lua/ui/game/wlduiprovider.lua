--*****************************************************************************
--* File: lua/modules/ui/game/wlduiprovider.lua
--* Author: Chris Blackwell
--* Summary: Responds to wld UI events and show appropriate UI
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

-- Functions exposed to lua

---@class WldUIProvider : moho.WldUIProvider_methods
WldUIProvider = ClassUI(moho.WldUIProvider_methods) {
    __init = function(self)
        InternalCreateWldUIProvider(self)
    end,

    StartLoadingDialog = function(self)
    end,

    UpdateLoadingDialog = function(self, elapsedTime)
    end,

    StopLoadingDialog = function(self)
    end,

    StartWaitingDialog = function(self)
    end,

    UpdateWaitingDialog = function(self, elapsedTime)
    end,

    StopWaitingDialog = function(self)
    end,

    CreateGameInterface = function(self)
    end,

    DestroyGameInterface = function(self)
    end,
    
    GetPrefetchTextures = function(self)
        return nil
    end,
}

