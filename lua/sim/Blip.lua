--****************************************************************************
--**
--**  File     :  /lua/blip.lua
--**  Author(s):
--**
--**  Summary  : The recon blip lua module
--**
--**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local FlashedBlips = {}
local ClearThread = nil

-- Thread running as long as there is blips that need manual clear after 5 ticks
function ClearFlashedThread(army)
    local tick = GetGameTick()

    while table.getsize(FlashedBlips) > 0 do
        WaitSeconds(.5)

        for i, blip in FlashedBlips do
            if blip:BeenDestroyed() then
                blip.flash = nil
            elseif blip.flash and tick - blip.flash > 5 then
                blip.flash = nil
                blip:DisableIntel('Vision')
            end

            if not blip.flash then
                FlashedBlips[i] = nil
            end
        end
    end

    ClearThread = nil
end

Blip = Class(moho.blip_methods) {
    FlashIntel = function(self, army, was_upgrade)
        if not self:IsSeenEver(army) and (self:IsOnRadar(army) or self:IsOnSonar(self)) then
            -- Remove dead radar blip out of map so we don't reveal what's under it
            self:SetPosition(Vector(-100, 0, -100), true)
        end

        self:InitIntel(army, 'Vision', 2)
        self:EnableIntel('Vision')

        if was_upgrade then -- need to make sure upgraded blips are cleared
            self.flash = GetGameTick()
            table.insert(FlashedBlips, self)
            if not ClearThread then
                ClearThread = ForkThread(ClearFlashedThread)
            end
        end
    end,

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
