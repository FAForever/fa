local CLOATacticalChildMissileProjectile = import("/lua/cybranprojectiles.lua").CLOATacticalChildMissileProjectile

--- Cybran "Loa" Tactical Missile, child missiles that create when the mother projectile is shot down by
--- enemy anti-missile systems
---@class CIFMissileTacticalSplit01 : CLOATacticalChildMissileProjectile
CIFMissileTacticalSplit01 = ClassProjectile(CLOATacticalChildMissileProjectile) {

    ---@param self CIFMissileTacticalSplit01
    OnCreate = function(self)
        CLOATacticalChildMissileProjectile.OnCreate(self)
        self.Trash:Add(ForkThread(self.ZigZagThread, self))
    end,

    -- Give the projectile enough time to get out of the explosion
    ---@param self CIFMissileTacticalSplit01
    ZigZagThread = function(self)
        self:ChangeMaxZigZag(10)

        WaitTicks(3)

        self:TrackTarget(true)

        for k = 9, 1, -1 do
            WaitTicks(4)
            if not IsDestroyed(self) then
                self:ChangeMaxZigZag(k)
                self:ChangeZigZagFrequency(0.1 * k)
            end
        end

        self:ChangeMaxZigZag(0.5)
        self:ChangeZigZagFrequency(1)
    end,
}
TypeClass = CIFMissileTacticalSplit01
