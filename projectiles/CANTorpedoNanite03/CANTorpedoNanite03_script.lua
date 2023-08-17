--****************************************************************************
--**
--**  File     :  /data/projectiles/CANTorpedoNanite02/CANTorpedoNanite02_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
--**
--**  Summary  :  Cybran Anti-Navy Nanite Torpedo Script
--                Nanite Torpedo releases tiny nanites that do DoT
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local CTorpedoShipProjectile = import("/lua/cybranprojectiles.lua").CTorpedoShipProjectile

---@class CANTorpedoNanite03 : CTorpedoShipProjectile
CANTorpedoNanite03 = ClassProjectile(CTorpedoShipProjectile) { 

    ---@param self CANTorpedoNanite03
    OnEnterWater = function(self)
        CTorpedoShipProjectile.OnEnterWater(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)

        -- set the magnitude of the velocity to something tiny to really make that water
        -- impact slow it down. We need this to prevent torpedo's striking the bottom
        -- of a shallow pond, like in setons
        self:SetVelocity(0)
        self:SetAcceleration(0.5)
    end,

    --- Adjusted movement thread to gradually speed up the torpedo. It needs to slowly speed
    --- up to prevent it from hitting the floor in relative undeep water
    ---@param self CANTorpedoNanite03
    MovementThread = function(self)
        WaitTicks(1)
        for k = 1, 6 do
            WaitTicks(1)
            if not IsDestroyed(self) then
                self:SetAcceleration(k)
            else
                break
            end
        end
    end,

}
TypeClass = CANTorpedoNanite03