local CLOATacticalMissileProjectile = import("/lua/cybranprojectiles.lua").CLOATacticalMissileProjectile

-- upvalue for performance
local ForkThread = ForkThread
local TrashBagAdd = TrashBag.Add

--- URS0304 : cybran nuke sub
--- Cybran "Loa" Tactical Missile, structure unit and sub launched variant of this projectile,
--- with a higher arc and distance based adjusting trajectory. Splits into child projectile
--- if it takes enough damage.
---@class CIFMissileTactical02 : CLOATacticalMissileProjectile
CIFMissileTactical02 = ClassProjectile(CLOATacticalMissileProjectile) {

    NumChildMissiles = 3,

    ---@param self CIFMissileTactical02
    OnCreate = function(self)
        CLOATacticalMissileProjectile.OnCreate(self)
        local trash = self.Trash
        self.MoveThread = TrashBagAdd(trash,ForkThread( self.MovementThread,self ))
    end,
}
TypeClass = CIFMissileTactical02