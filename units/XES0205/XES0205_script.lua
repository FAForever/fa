----****************************************************************************
----**
----**  File     :  /data/units/XES0205/XES0205_script.lua
----**  Author(s):  Jessica St. Croix
----**
----**  Summary  :  UEF Mobile Shield Boat Script
----**
----**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local TShieldSeaUnit = import("/lua/terranunits.lua").TShieldSeaUnit
local ShieldEffectsComponent = import("/lua/defaultcomponents.lua").ShieldEffectsComponent

---@class XES0205 : TShieldSeaUnit
XES0205 = ClassUnit(TShieldSeaUnit, ShieldEffectsComponent) {
    ShieldEffects = {
        '/effects/emitters/terran_shield_generator_shipmobile_01_emit.bp',
        '/effects/emitters/terran_shield_generator_shipmobile_02_emit.bp',
    },

    ShieldEffectsBone = 'XES0205',

    ---@param self XES0205
    OnCreate = function(self) -- Are these missng on purpose?
        TShieldSeaUnit.OnCreate(self)
        ShieldEffectsComponent.OnCreate(self)
    end,

    ---@param self XES0205
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        TShieldSeaUnit.OnStopBeingBuilt(self, builder, layer)
    end,

    ---@param self XES0205
    OnShieldEnabled = function(self)
        TShieldSeaUnit.OnShieldEnabled(self)
        ShieldEffectsComponent.OnShieldEnabled(self)
        if self.ShieldEffectsBag then 
            for _, v in self.ShieldEffectsBag do
                v:OffsetEmitter(0, -0.15, 0.35)
            end
        end
    end,

    ---@param self XES0205
    OnShieldDisabled = function(self)
        TShieldSeaUnit.OnShieldDisabled(self)
        ShieldEffectsComponent.OnShieldDisabled(self)
    end,
}

TypeClass = XES0205