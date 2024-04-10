-- File     :  /cdimage/units/UAB0304/UAB0304_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  Aeon Unit Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local AQuantumGateUnit = import("/lua/aeonunits.lua").AQuantumGateUnit
local AQuantumGateAmbient = import("/lua/effecttemplates.lua").AQuantumGateAmbient

---@class UAB0304 : AQuantumGateUnit
UAB0304 = ClassUnit(AQuantumGateUnit) {

    ---@param self UAB0304
    ---@param builder Unit
    ---@param layer string
    OnStopBeingBuilt = function(self, builder, layer)
        local army = self.Army

        for k, v in AQuantumGateAmbient do
            CreateAttachedEmitter(self, 'UAB0304', army, v)
        end
        AQuantumGateUnit.OnStopBeingBuilt(self, builder, layer)
    end,
}
TypeClass = UAB0304