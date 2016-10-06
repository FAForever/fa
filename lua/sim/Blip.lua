--****************************************************************************
--**
--**  File     :  /lua/blip.lua
--**  Author(s):
--**
--**  Summary  : The recon blip lua module
--**
--**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local Entity = import('/lua/sim/Entity.lua').Entity
local Visions = {}
local VisionThread = nil

-- Thread flashing blips after a small delay to prevent upgraded units to inherit vision of builder blip
function CheckVisions()
    local done, unit, old_blip, new_blip
    local current_tick

    while table.getsize(Visions) > 0 do
        current_tick = GetGameTick()

        for i, vision in Visions do
            if vision.delete and current_tick >= vision.delete then
                vision:DisableIntel('Vision')
                vision:Destroy()
                Visions[i] = nil
            elseif not vision.delete then
                old_blip = vision.old_blip
                unit = vision.unit
                done = false
                if unit then
                    new_blip = unit:GetBlip(vision.army)
                    done = unit.Dead or new_blip and new_blip:IsSeenNow(vision.army)
                else -- this blip doesn't have a new unit
                    done = old_blip:BeenDestroyed()
                end

                if done then
                    vision.delete = current_tick + 5
                end
            end
        end

        WaitSeconds(.1)
    end

    VisionThread = nil
end

Blip = Class(moho.blip_methods) {
    FlashIntel = function(self, army, new_unit)
        if self.flashed then return end
        self.flashed = true

        if not self:IsSeenEver(army) and (self:IsOnRadar(army) or self:IsOnSonar(army)) then
            -- Remove dead radar blip out of map so we don't reveal what's under it
            self:SetPosition(Vector(-100, 0, -100), true)
            new_unit = nil -- won't see this anyway due to movement of blip
        end

        local vision = Entity({Owner = army})
        Warp(vision, self:GetPosition())
        vision:InitIntel(army, 'Vision', 3)
        vision:EnableIntel('Vision')
        vision.army = army
        vision.unit = new_unit
        vision.old_blip = self
        table.insert(Visions, vision)

        if not VisionThread then
            VisionThread = ForkThread(CheckVisions)
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
