----****************************************************************************
----**
----**  File     :  /cdimage/units/UES0103/UES0103_script.lua
----**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
----**
----**  Summary  :  UEF Frigate Script
----**
----**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local TSeaUnit = import("/lua/terranunits.lua").TSeaUnit
local TAALinkedRailgun = import("/lua/terranweapons.lua").TAALinkedRailgun
local TDFGaussCannonWeapon = import("/lua/terranweapons.lua").TDFGaussCannonWeapon

---@class UES0103 : TSeaUnit
---@field Spinner01 moho.RotateManipulator
---@field Spinner02 moho.RotateManipulator
---@field Spinner03 moho.RotateManipulator
UES0103 = ClassUnit(TSeaUnit) {
    Weapons = {
        MainGun = ClassWeapon(TDFGaussCannonWeapon) {},
        AAGun = ClassWeapon(TAALinkedRailgun) {},
    },

    ---@param self UES0103
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        TSeaUnit.OnStopBeingBuilt(self, builder, layer)
        local trash = self.Trash
        self.Spinner01 = trash:Add(CreateRotator(self, 'Spinner01', 'y', nil, 360, 0, 180))
        self.Spinner02 = trash:Add(CreateRotator(self, 'Spinner02', 'y', nil, 90, 0, 180))
        self.Spinner03 = trash:Add(CreateRotator(self, 'Spinner03', 'y', nil, -180, 0, -180))
    end,

    ---@param self UES0103
    ---@param instigator Unit
    ---@param type DamageType
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        TSeaUnit.OnKilled(self, instigator, type, overkillRatio)

        if self:GetFractionComplete() >= 1.0 then
            self.Spinner01:SetTargetSpeed(0)
            self.Spinner01:SetAccel(-40)
            self.Spinner02:SetTargetSpeed(0)
            self.Spinner02:SetAccel(-10)
            self.Spinner03:SetAccel(20)
            self.Spinner03:SetTargetSpeed(0)
        end
    end,
}

TypeClass = UES0103
