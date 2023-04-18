-- File     :  /cdimage/units/URL0101/URL0101_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  Cybran Land Scout Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local CWalkingLandUnit = import("/lua/cybranunits.lua").CWalkingLandUnit

---@class URL0101 : CWalkingLandUnit
URL0101 = ClassUnit(CWalkingLandUnit) {
    OnStopBeingBuilt = function(self, builder, layer)
        CWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)

        self.Trash:Add(CreateRotator(self, 'Spinner', 'y', nil, 90, 5, 90))
        self:SetMaintenanceConsumptionInactive()
        self:SetScriptBit('RULEUTC_CloakToggle', true)
        self:RequestRefreshUI()
    end,
}

TypeClass = URL0101
