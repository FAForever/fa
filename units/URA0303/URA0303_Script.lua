--****************************************************************************
--**
--**  File     :  /cdimage/units/URA0303/URA0303_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Air Superiority Fighter Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CAirUnit = import("/lua/cybranunits.lua").CAirUnit
local CAAMissileNaniteWeapon = import("/lua/cybranweapons.lua").CAAMissileNaniteWeapon

---@class URA0303 : CAirUnit
URA0303 = ClassUnit(CAirUnit) {
    ExhaustBones = { 'Exhaust', },
    ContrailBones = { 'Contrail_L', 'Contrail_R', },
    Weapons = {
        Missiles1 = ClassWeapon(CAAMissileNaniteWeapon) {},
        Missiles2 = ClassWeapon(CAAMissileNaniteWeapon) {},
    },

    ---@param self URA0303
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        CAirUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionInactive()
        -- Don't turn off stealth for AI so that it uses it by default
        if self.Brain.BrainType == 'Human' then
            self:SetScriptBit('RULEUTC_StealthToggle', true)
        else
            self:SetMaintenanceConsumptionActive()
        end
    end,
}

TypeClass = URA0303
