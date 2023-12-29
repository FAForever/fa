local CLOATacticalMissileProjectile = import("/lua/cybranprojectiles.lua").CLOATacticalMissileProjectile

--- URS0304 : cybran nuke sub
--- Cybran "Loa" Tactical Missile, structure unit and sub launched variant of this projectile,
--- with a higher arc and distance based adjusting trajectory. Splits into child projectile
--- if it takes enough damage.
---@class CIFMissileTactical02 : CLOATacticalMissileProjectile
CIFMissileTactical02 = ClassProjectile(CLOATacticalMissileProjectile) {
    ChildCount = 3,

    ---@param self CIFMissileTactical02
    OnCreate = function(self)
        CLOATacticalMissileProjectile.OnCreate(self)
        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread, self))
    end,

    ---@param self CIFMissileTactical02
    OnExitWater = function(self)
        CLOATacticalMissileProjectile.OnExitWater(self)
        self:SetDestroyOnWater(true)
    end,
}
TypeClass = CIFMissileTactical02
