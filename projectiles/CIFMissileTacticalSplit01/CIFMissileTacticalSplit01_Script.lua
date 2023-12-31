local CLOATacticalChildMissileProjectile = import("/lua/cybranprojectiles.lua").CLOATacticalChildMissileProjectile

--- Cybran "Loa" Tactical Missile, child missiles that create when the mother projectile is shot down by
--- enemy anti-missile systems
---@class CIFMissileTacticalSplit01 : CLOATacticalChildMissileProjectile
CIFMissileTacticalSplit01 = ClassProjectile(CLOATacticalChildMissileProjectile) {

    ---@param self CIFMissileTacticalSplit01
    OnCreate = function(self)
        CLOATacticalChildMissileProjectile.OnCreate(self)
        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread,self))
    end,

    -- Give time for splitting to move the projectile outwards before tracking takes over.
    -- Forking the thread waits 1 tick.
    ---@param self CIFMissileTacticalSplit01
    MovementThread = function(self)
        if not IsDestroyed(self) then
            local turnrate = self:TurnRateFromDistance()*1.5
            self:SetTurnRate(math.min(360, turnrate))
            self:ChangeMaxZigZag(0)
            self:TrackTarget(true)
        end
    end,
}
TypeClass = CIFMissileTacticalSplit01