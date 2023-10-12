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
        WaitTicks(3)

        self:TrackTarget(true)
    end,
}
TypeClass = CIFMissileTacticalSplit01