--****************************************************************************
--**
--**  File     :  /data/units/XRS0205/XRS0205_script.lua
--**  Author(s):  Jessica St. Croix
--**
--**  Summary  :  Cybran Counter-Intelligence Boat Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CSeaUnit = import("/lua/cybranunits.lua").CSeaUnit
local CIFSmartCharge = import("/lua/cybranweapons.lua").CIFSmartCharge
local EffectTemplates = import("/lua/effecttemplates.lua")

---@class XRS0205 : CSeaUnit
---@field Rotator moho.RotateManipulator
XRS0205 = ClassUnit(CSeaUnit) {

    Weapons = {
        AntiTorpedo = ClassWeapon(CIFSmartCharge) {},
    },

    ---@param self XRS0205
    OnCreate = function(self)
        CSeaUnit.OnCreate(self)
        self.Rotator = CreateRotator(self, 'Radar_B01', "y")
        self.IntelEffectsBag = TrashBag()
        self.Trash:Add(self.Rotator)
    end,

    ---@param self XRS0205
    ---@param intel? IntelType
    OnIntelEnabled = function(self, intel)
        CSeaUnit.OnIntelEnabled(self, intel)
        if intel == 'RadarStealthField' then
            self.Rotator:SetSpinDown(false)
            self.Rotator:SetTargetSpeed(10)
            self.Rotator:SetAccel(4)
            for _, effect in EffectTemplates.SJammerCrystalAmbient do
                self.IntelEffectsBag:Add(CreateAttachedEmitter(self, 'Radar_B01', self.Army, effect):OffsetEmitter(0, 0.25, -0.8))
            end
        end
    end,

    ---@param self XRS0205
    ---@param intel? IntelType
    OnIntelDisabled = function(self, intel)
        CSeaUnit.OnIntelDisabled(self, intel)
        if intel == 'RadarStealthField' then
            self.Rotator:SetSpinDown(true)
            self.IntelEffectsBag:Destroy()
        end
    end,
}

TypeClass = XRS0205