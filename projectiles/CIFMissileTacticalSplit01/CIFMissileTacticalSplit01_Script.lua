--
-- Cybran "Loa" Tactical Missile, child missiles that create when the mother projectile is shot down by
-- enemy anti-missile systems
--
local CLOATacticalChildMissileProjectile = import("/lua/cybranprojectiles.lua").CLOATacticalChildMissileProjectile

---@class CIFMissileTacticalSplit01 : CLOATacticalChildMissileProjectile
CIFMissileTacticalSplit01 = ClassProjectile(CLOATacticalChildMissileProjectile) {

    ---@param self CIFMissileTacticalSplit01
    OnCreate = function(self)
        CLOATacticalChildMissileProjectile.OnCreate(self)
        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread,self))
    end,

    -- Give the projectile enough time to get out of the explosion
    ---@param self CIFMissileTacticalSplit01
    MovementThread = function(self)
        self:ChangeMaxZigZag(10)

        WaitTicks(3)

        self:TrackTarget(true)

        for k = 9, 5, -1 do
            WaitTicks(6)
            if not IsDestroyed(self) then
                self:ChangeMaxZigZag(k)
                self:ChangeZigZagFrequency(0.1 * k)
            end
        end
    end,
}
TypeClass = CIFMissileTacticalSplit01