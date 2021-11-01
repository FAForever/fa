-- Automatically upvalued moho functions for performance
local GlobalMethods = _G
local GlobalMethodsCreateAttachedEmitter = GlobalMethods.CreateAttachedEmitter
-- End of automatically upvalued moho functions

--#****************************************************************************
--#**
--#**  File     :  /cdimage/units/XSB0304/XSB0304_script.lua
--#**  Author(s):  Greg Kohne
--#**
--#**  Summary  :  Seraphim Sub Commander Gateway Unit Script
--#**
--#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--#****************************************************************************
local SQuantumGateUnit = import('/lua/seraphimunits.lua').SQuantumGateUnit
local EffectTemplates = import('/lua/EffectTemplates.lua')

XSB0304 = Class(SQuantumGateUnit)({
    OnStopBeingBuilt = function(self, builder, layer)
        -- Place emitters at the center of the gateway.
        for k, v in EffectTemplates.SeraphimSubCommanderGateway01 do
            GlobalMethodsCreateAttachedEmitter(self, 'XSB0304', self.Army, v)
        end

        -- Place emitters on certain light bones on the mesh.
        for k, v in EffectTemplates.SeraphimSubCommanderGateway02 do
            GlobalMethodsCreateAttachedEmitter(self, 'Light01', self.Army, v)
            GlobalMethodsCreateAttachedEmitter(self, 'Light02', self.Army, v)
            GlobalMethodsCreateAttachedEmitter(self, 'Light03', self.Army, v)
        end

        -- Place emitters on certain OTHER light bones on the mesh.
        for k, v in EffectTemplates.SeraphimSubCommanderGateway03 do
            GlobalMethodsCreateAttachedEmitter(self, 'Light04', self.Army, v)
            GlobalMethodsCreateAttachedEmitter(self, 'Light05', self.Army, v)
            GlobalMethodsCreateAttachedEmitter(self, 'Light06', self.Army, v)
            GlobalMethodsCreateAttachedEmitter(self, 'Light07', self.Army, v)
            GlobalMethodsCreateAttachedEmitter(self, 'Light08', self.Army, v)
            GlobalMethodsCreateAttachedEmitter(self, 'Light09', self.Army, v)
        end

        SQuantumGateUnit.OnStopBeingBuilt(self, builder, layer)
    end,
})

TypeClass = XSB0304
