--****************************************************************************
--**
--**  File     :  /lua/blip.lua
--**  Author(s):
--**
--**  Summary  : The recon blip lua module
--**
--**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

---@class Blip : moho.blip_methods
Blip = Class(moho.blip_methods) {

    ---@alias funBlip fun(blip: Blip)

    ---@param self Blip
    ---@param hook funBlip
    AddDestroyHook = function(self,hook)
        if not self.DestroyHooks then
            self.DestroyHooks = {}
        end
        table.insert(self.DestroyHooks,hook)
    end,

    ---@param self Blip
    ---@param hook funBlip
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

    ---@param self Blip
    OnDestroy = function(self)
        if self.DestroyHooks then
            for k,v in self.DestroyHooks do
                v(self)
            end
        end
    end,
}
