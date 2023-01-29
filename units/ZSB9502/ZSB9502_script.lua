-- File     :  /units/ZSB9502/ZSB9502_script.lua
-- Summary  :  Seraphim T2 Air Factory Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local SAirFactoryUnit = import("/lua/seraphimunits.lua").SAirFactoryUnit
---@class ZSB9502 : SAirFactoryUnit
ZSB9502 = ClassUnit(SAirFactoryUnit) {

    RollOffBones = { 'Pod01', 'Pod02', },

    OnCreate = function(self)
        SAirFactoryUnit.OnCreate(self)
        self.Rotator1 = CreateRotator(self, 'Pod01', 'y', nil, 5, 0, 0)
        self.Trash:Add(self.Rotator1)

        self.Rotator2 = CreateRotator(self, 'Pod02', 'y', nil, 8, 0, 0)
        self.Trash:Add(self.Rotator2)
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        self.Rotator1:SetSpeed(0)
        self.Rotator2:SetSpeed(0)
        SAirFactoryUnit.OnKilled(self, instigator, type, overkillRatio)
    end,
}

TypeClass = ZSB9502
