--****************************************************************************
--**
--**  File     :  /data/units/XAA0306/XAA0306_script.lua
--**  Author(s):  Jessica St. Croix, Matt Vainio
--**
--**  Summary  :  Aeon Torpedo Cluster Bomber Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AAirUnit = import('/lua/aeonunits.lua').AAirUnit
local AANTorpedoCluster = import('/lua/aeonweapons.lua').AANTorpedoCluster


XAA0306 = Class(AAirUnit) {
    Weapons = {
        Bomb = Class(AANTorpedoCluster) {
            OnLostTarget = function(self)
                if self.unit:GetTargetEntity().Dead then
                    self:ResetAttackOrder()
                end
                AANTorpedoCluster.OnLostTarget(self)
            end,
            
            ResetAttackOrder = function(self)
                self:ForkThread(function()
                    self:ChangeMaxRadius(100)
                    WaitTicks(1)
                    self:ChangeMaxRadius(self:GetBlueprint().MaxRadius)
                    self:ResetTarget()
                end)
            end,
        },
    },
}

TypeClass = XAA0306