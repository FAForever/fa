#****************************************************************************
#**
#**  File     :  /cdimage/units/URA0303/URA0303_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Cybran Air Superiority Fighter Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CAirUnit = import('/lua/cybranunits.lua').CAirUnit
local CAAMissileNaniteWeapon = import('/lua/cybranweapons.lua').CAAMissileNaniteWeapon

URA0303 = Class(CAirUnit) {
    ExhaustBones = { 'Exhaust', },
    ContrailBones = { 'Contrail_L', 'Contrail_R', },
    Weapons = {
        Missiles1 = Class(CAAMissileNaniteWeapon) {},
        Missiles2 = Class(CAAMissileNaniteWeapon) {},
    },
    OnStopBeingBuilt = function(self,builder,layer)
        CAirUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionInactive()
        self:SetScriptBit('RULEUTC_StealthToggle', true)
        self:RequestRefreshUI()
    end,
    
}

TypeClass = URA0303
