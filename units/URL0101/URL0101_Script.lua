-- File     :  /cdimage/units/URL0101/URL0101_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  Cybran Land Scout Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local CWalkingLandUnit = import("/lua/cybranunits.lua").CWalkingLandUnit

---@class URL0101 : CWalkingLandUnit
URL0101 = ClassUnit(CWalkingLandUnit) {

    ---@param self URL0101
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        CWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)

        self.Trash:Add(CreateRotator(self, 'Spinner', 'y', nil, 90, 5, 90))

        -- Don't turn off cloak for AI so that it uses it by default
        if self.Brain.BrainType == 'Human' then
            self:SetScriptBit('RULEUTC_CloakToggle', true)
        else
            self:SetMaintenanceConsumptionActive()
            -- `StopBeingBuiltEffects` is a thread that sets our mesh, and since it is a thread
            -- it will act after the cloak update from OnStopBeingBuilt so we add another
            -- thread to update the cloak again after the built effects are done.
            ForkThread(self.UpdateCloakEffect, self, true, "Cloak")
        end
    end,
}

TypeClass = URL0101
