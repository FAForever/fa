--****************************************************************************
--**
--**  File     :  /lua/blip.lua
--**  Author(s):
--**
--**  Summary  : The recon blip lua module
--**
--**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local FlashBlips = {}
local DelayThread = nil

-- Thread flashing blips after a small delay to prevent upgraded units to inherit vision of builder blip
function FlashDelayed()
    local current_tick, blip, army
    WaitSeconds(.5)

    while table.getsize(FlashBlips) > 0 do
        WaitSeconds(.1)
        current_tick = GetGameTick()

        for i, data in FlashBlips do
            blip = data.blip
            army = data.army

            if blip:BeenDestroyed() or blip.flash < current_tick then
                blip.flash = nil
                if not blip:BeenDestroyed() then
                    blip:Refresh(army)
                end
                FlashBlips[i] = nil
            end
        end
    end

    DelayThread = nil
end

Blip = Class(moho.blip_methods) {
    Refresh = function(self, army)
        if not self:IsSeenEver(army) and (self:IsOnRadar(army) or self:IsOnSonar(army)) then
            -- Remove dead radar blip out of map so we don't reveal what's under it
            self:SetPosition(Vector(-100, 0, -100), true)
        end

        self:InitIntel(army, 'Vision', 2)
        self:EnableIntel('Vision')
    end,

    FlashIntel = function(self, army, delay)
        if delay then
            self.flash = GetGameTick() + 5;
            table.insert(FlashBlips, {army=army, blip=self})
            if not DelayThread then
                DelayThread = ForkThread(FlashDelayed)
            end
        else
            self:Refresh(army)
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
