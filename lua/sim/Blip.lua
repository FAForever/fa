#****************************************************************************
#**
#**  File     :  /lua/blip.lua
#**  Author(s):
#**
#**  Summary  : The recon blip lua module
#**
#**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local ipairs = ipairs
local tableRemove = table.remove
local next = next
local tableInsert = table.insert

Blip = Class(moho.blip_methods) {

    AddDestroyHook = function(self,hook)
        if not self.DestroyHooks then
            self.DestroyHooks = {}
        end
        tableInsert(self.DestroyHooks,hook)
    end,

    RemoveDestroyHook = function(self,hook)
        if self.DestroyHooks then
            for k,v in self.DestroyHooks do
                if v == hook then
                    tableRemove(self.DestroyHooks,k)
                    return
                end
            end
        end
    end,

    OnDestroy = function(self)
        if self.DestroyHooks then
            for k,v in self.DestroyHooks do
                v(self)
            end
        end
    end,
}
