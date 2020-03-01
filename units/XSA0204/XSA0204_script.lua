--****************************************************************************
--**
--**  File     :  /main/data/Units/XSA0204/XSA0204_script.lua
--**  Author(s):  Greg Kohne, Gordon Duclos
--**
--**  Summary  :  Seraphim Torpedo Bomber Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SAirUnit = import('/lua/seraphimunits.lua').SAirUnit
local SeraphimWeapons = import('/lua/seraphimweapons.lua')
local SANHeavyCavitationTorpedo = SeraphimWeapons.SANHeavyCavitationTorpedo

XSA0204 = Class(SAirUnit) {
    Weapons = {
        Bomb = Class(SANHeavyCavitationTorpedo) {
            OnLostTarget = function(self)
                if self.unit:GetTargetEntity().Dead then
                    self:ForkThread(function()
                        self:ChangeMaxRadius(100)
                        WaitTicks(1)
                        self:ChangeMaxRadius(self:GetBlueprint().MaxRadius)
                    end)
                end
                SANHeavyCavitationTorpedo.OnLostTarget(self)
            end,
        },
    },
}
TypeClass = XSA0204