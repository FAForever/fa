----****************************************************************************
----**
----**  File     :  /cdimage/units/URB4206/URB4206_script.lua
----**  Author(s):  David Tomandl, Greg Kohne
----**
----**  Summary  :  Cybran Shield Generator lvl 4 Script
----**
----**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local CShieldStructureUnit = import("/lua/cybranunits.lua").CShieldStructureUnit

---@class URB4206 : CShieldStructureUnit
URB4206 = ClassUnit(CShieldStructureUnit) {
    ShieldEffects = { 
        '/effects/emitters/cybran_shield_04_generator_01_emit.bp',
        '/effects/emitters/cybran_shield_04_generator_02_emit.bp',
        '/effects/emitters/cybran_shield_04_generator_03_emit.bp',
    },

    OnStopBeingBuilt = function(self, builder, layer)
        CShieldStructureUnit.OnStopBeingBuilt(self, builder, layer)
        self.Rotator1 = CreateRotator(self, 'Shaft', 'z', nil, 30, 5, 30)
        self.Trash:Add(self.Rotator1)
        self.ShieldEffectsBag = {}
    end,

    OnShieldEnabled = function(self)
        CShieldStructureUnit.OnShieldEnabled(self)
        if self.Rotator1 then
            self.Rotator1:SetTargetSpeed(10)
        end

        if self.ShieldEffectsBag then
            for k, v in self.ShieldEffectsBag do
                v:Destroy()
            end
            self.ShieldEffectsBag = {}
        end

        for k, v in self.ShieldEffects do
            table.insert(self.ShieldEffectsBag, CreateAttachedEmitter(self, 'Shaft', self.Army, v))
        end
    end,

    OnShieldDisabled = function(self)
        CShieldStructureUnit.OnShieldDisabled(self)
        self.Rotator1:SetTargetSpeed(0)
        
        if self.ShieldEffectsBag then
            for k, v in self.ShieldEffectsBag do
                v:Destroy()
            end
            self.ShieldEffectsBag = {}
        end
    end,
}

TypeClass = URB4206
