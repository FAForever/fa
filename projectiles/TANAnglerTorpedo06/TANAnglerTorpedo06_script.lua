--
-- Terran Torpedo Bomb
--

local TTorpedoShipProjectile = import("/lua/terranprojectiles.lua").TTorpedoShipProjectile
---@class TANAnglerTorpedo06: TTorpedoShipProjectile
TANAnglerTorpedo06 = ClassProjectile(TTorpedoShipProjectile) {

    ---@param self TANAnglerTorpedo06
    OnEnterWater = function(self)
        TTorpedoShipProjectile.OnEnterWater(self)

        -- set the magnitude of the velocity to something tiny to really make that water
        -- impact slow it down. We need this to prevent torpedo's striking the bottom
        -- of a shallow pond, like in setons
        self:SetVelocity(0)
        self:SetAcceleration(0.5)
    end,

    --- Adjusted movement thread to gradually speed up the torpedo. It needs to slowly speed
    --- up to prevent it from hitting the floor in relative undeep water
    ---@param self TANAnglerTorpedo06
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
TypeClass = TANAnglerTorpedo06