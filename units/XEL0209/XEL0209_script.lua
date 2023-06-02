--****************************************************************************
--**
--**  File     :  /units/XEL0209/XEL0209_script.lua
--**
--**  Summary  :  UEF Combat Engineer T2
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local EffectTemplate = import("/lua/effecttemplates.lua")
local TConstructionUnit = import("/lua/terranunits.lua").TConstructionUnit
local TDFRiotWeapon = import("/lua/terranweapons.lua").TDFRiotWeapon

---@class XEL0209 : TConstructionUnit
XEL0209 = ClassUnit(TConstructionUnit) {
    Weapons = {
        Riotgun01 = ClassWeapon(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank,
            FxMuzzleFlashScale = 0.75,
        },
    },

    OnStopBeingBuilt = function(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
        TConstructionUnit.OnStopBeingBuilt(self, builder, layer)
        --Rotate the antenna
        self.Rotator = CreateRotator(self, 'Antenna', 'y')
        self.Trash:Add(self.Rotator)
        self.Rotator:SetSpinDown(false)
        self.Rotator:SetTargetSpeed(30)
        self.Rotator:SetAccel(20)
    end,

    --[[OnStartBuild = function(self, unitBeingBuilt, order)
        --Disable the gun while building something
        self:SetWeaponEnabledByLabel('Riotgun01', false)
        TConstructionUnit.OnStartBuild(self, unitBeingBuilt, order)
    end,

    OnStopBuild = function(self)
        --Re-enable the gun after done building
        self:SetWeaponEnabledByLabel('Riotgun01', true)
        TConstructionUnit.OnStopBuild(self)
    end,

    OnStartReclaim = function(self, target)
        TConstructionUnit.OnStartReclaim(self, target)
        self:SetAllWeaponsEnabled(false)
    end,

    OnStopReclaim = function(self, target)
        TConstructionUnit.OnStopReclaim(self, target)
        self:SetAllWeaponsEnabled(true)
    end,--]]
}

TypeClass = XEL0209
