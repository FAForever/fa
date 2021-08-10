--****************************************************************************
--**
--**  File     :  /lua/blip.lua
--**  Author(s):
--**
--**  Summary  : The recon blip lua module
--**
--**  Copyright � 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

Blip = Class(moho.blip_methods) {

    AddDestroyHook = function(self,hook)
        if not self.DestroyHooks then
            self.DestroyHooks = {}
        end
        table.insert(self.DestroyHooks,hook)
    end,

    RemoveDestroyHook = function(self,hook)
        if self.DestroyHooks then
            for k,v in self.DestroyHooks do
                if v == hook then
                    table.remove(self.DestroyHooks,k)
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
