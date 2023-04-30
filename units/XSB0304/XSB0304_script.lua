----****************************************************************************
----**
----**  File     :  /cdimage/units/XSB0304/XSB0304_script.lua
----**  Author(s):  Greg Kohne
----**
----**  Summary  :  Seraphim Sub Commander Gateway Unit Script
----**
----**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local SQuantumGateUnit = import("/lua/seraphimunits.lua").SQuantumGateUnit
local EffectTemplates = import("/lua/effecttemplates.lua")

---@class XSB0304 : SQuantumGateUnit
XSB0304 = ClassUnit(SQuantumGateUnit) {
    OnStopBeingBuilt = function(self, builder, layer)
        -- Place emitters at the center of the gateway.
        for k, v in EffectTemplates.SeraphimSubCommanderGateway01 do
            CreateAttachedEmitter(self, 'XSB0304', self.Army, v)
        end

        -- Place emitters on certain light bones on the mesh.
        for k, v in EffectTemplates.SeraphimSubCommanderGateway02 do
            CreateAttachedEmitter(self, 'Light01', self.Army, v)
            CreateAttachedEmitter(self, 'Light02', self.Army, v)
            CreateAttachedEmitter(self, 'Light03', self.Army, v)
        end

        -- Place emitters on certain OTHER light bones on the mesh.
        for k, v in EffectTemplates.SeraphimSubCommanderGateway03 do
            CreateAttachedEmitter(self, 'Light04', self.Army, v)
            CreateAttachedEmitter(self, 'Light05', self.Army, v)
            CreateAttachedEmitter(self, 'Light06', self.Army, v)
            CreateAttachedEmitter(self, 'Light07', self.Army, v)
            CreateAttachedEmitter(self, 'Light08', self.Army, v)
            CreateAttachedEmitter(self, 'Light09', self.Army, v)
        end

        SQuantumGateUnit.OnStopBeingBuilt(self, builder, layer)
    end,
}

TypeClass = XSB0304
