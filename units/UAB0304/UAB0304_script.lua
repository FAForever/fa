-- Automatically upvalued moho functions for performance
local GlobalMethods = _G
local GlobalMethodsCreateAttachedEmitter = GlobalMethods.CreateAttachedEmitter
-- End of automatically upvalued moho functions

--#****************************************************************************
--#**
--#**  File     :  /cdimage/units/UAB0304/UAB0304_script.lua
--#**  Author(s):  John Comes, David Tomandl
--#**
--#**  Summary  :  Aeon Unit Script
--#**
--#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--#****************************************************************************
local AQuantumGateUnit = import('/lua/aeonunits.lua').AQuantumGateUnit
local AQuantumGateAmbient = import('/lua/EffectTemplates.lua').AQuantumGateAmbient

UAB0304 = Class(AQuantumGateUnit)({

    OnStopBeingBuilt = function(self, builder, layer)
        for k, v in AQuantumGateAmbient do
            GlobalMethodsCreateAttachedEmitter(self, 'UAB0304', self.Army, v)
        end

        AQuantumGateUnit.OnStopBeingBuilt(self, builder, layer)
    end,
})

TypeClass = UAB0304
