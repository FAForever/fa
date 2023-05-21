-- File     :  /units/ZSB9602/ZSB9602_script.lua
-- Summary  :  Seraphim T3 Air FactoryScript
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local SAirFactoryUnit = import("/lua/seraphimunits.lua").SAirFactoryUnit
---@class ZSB9602 : SAirFactoryUnit
ZSB9602 = ClassUnit(SAirFactoryUnit) {

    RollOffBones = { 'Pod01', 'Pod02', 'Pod03', },

    OnCreate = function(self)
        SAirFactoryUnit.OnCreate(self)
        self.Rotator1 = CreateRotator(self, 'Pod01', 'y', nil, 5, 0, 0)
        self.Trash:Add(self.Rotator1)
        self.Rotator2 = CreateRotator(self, 'Pod02', 'y', nil, 8, 0, 0)
        self.Trash:Add(self.Rotator2)
        self.Rotator3 = CreateRotator(self, 'Pod03', 'y', nil, -3, 0, 0)
        self.Trash:Add(self.Rotator3)
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        self.Rotator1:SetSpeed(0)
        self.Rotator2:SetSpeed(0)
        self.Rotator3:SetSpeed(0)
        SAirFactoryUnit.OnKilled(self, instigator, type, overkillRatio)
    end,
}

TypeClass = ZSB9602
