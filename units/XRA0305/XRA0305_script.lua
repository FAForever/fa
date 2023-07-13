--****************************************************************************
--**
--**  File     :  /cdimage/units/XRA0305/XRA0305_script.lua
--**  Author(s):  Drew Staltman, Jessica St. Croix, Gordon Duclos
--**
--**  Summary  :  Cybran Heavy Gunship Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local CAirUnit = import("/lua/cybranunits.lua").CAirUnit
local CAAMissileNaniteWeapon = import("/lua/cybranweapons.lua").CAAMissileNaniteWeapon
local CDFLaserDisintegratorWeapon = import("/lua/cybranweapons.lua").CDFLaserDisintegratorWeapon02

---@class XRA0305 : CAirUnit
XRA0305 = ClassUnit(CAirUnit) {
    
    Weapons = {
        Missiles1 = ClassWeapon(CAAMissileNaniteWeapon) {},
        Disintegrator01 = ClassWeapon(CDFLaserDisintegratorWeapon) {},
    },
    
    OnStopBeingBuilt = function(self,builder,layer)
        CAirUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionActive()
    end,
}
TypeClass = XRA0305