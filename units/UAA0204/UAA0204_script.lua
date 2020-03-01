--****************************************************************************
--**
--**  File     :  /cdimage/units/UAA0204/UAA0204_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Torpedo Bomber Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AAirUnit = import('/lua/aeonunits.lua').AAirUnit
local AANDepthChargeBombWeapon = import('/lua/aeonweapons.lua').AANDepthChargeBombWeapon

UAA0204 = Class(AAirUnit) {
    Weapons = {
        Bomb = Class(AANDepthChargeBombWeapon) {
            OnLostTarget = function(self)
                if self.unit:GetTargetEntity().Dead then
                    self:ForkThread(function()
                        self:ChangeMaxRadius(100)
                        WaitTicks(1)
                        self:ChangeMaxRadius(self:GetBlueprint().MaxRadius)
                        self:ResetTarget()
                    end)
                end
                AANDepthChargeBombWeapon.OnLostTarget(self)
            end,
        },
    },
}

TypeClass = UAA0204