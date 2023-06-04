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

---@class XES0205 : TShieldSeaUnit
XES0205 = ClassUnit(TShieldSeaUnit) {
    ShieldEffects = {
        '/effects/emitters/terran_shield_generator_shipmobile_01_emit.bp',
        '/effects/emitters/terran_shield_generator_shipmobile_02_emit.bp',
    },

    OnStopBeingBuilt = function(self, builder, layer)
        TShieldSeaUnit.OnStopBeingBuilt(self, builder, layer)
        self.ShieldEffectsBag = {}
    end,

    OnShieldEnabled = function(self)
        TShieldSeaUnit.OnShieldEnabled(self)

        if self.ShieldEffectsBag then
            for _, v in self.ShieldEffectsBag do
                v:Destroy()
            end
            self.ShieldEffectsBag = {}
        end
        for _, v in self.ShieldEffects do
            local emitter = CreateAttachedEmitter(self, 'XES0205', self:GetArmy(), v)
            emitter:OffsetEmitter(0, -0.15, 0.35)
            table.insert(self.ShieldEffectsBag, emitter)
        end
    end,

    OnShieldDisabled = function(self)
        TShieldSeaUnit.OnShieldDisabled(self)

        if self.ShieldEffectsBag then
            for _, v in self.ShieldEffectsBag do
                v:Destroy()
            end
            self.ShieldEffectsBag = {}
        end
    end,
}

TypeClass = XES0205