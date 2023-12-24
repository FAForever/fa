local CLOATacticalMissileProjectile = import("/lua/cybranprojectiles.lua").CLOATacticalMissileProjectile

-- upvalue for performance
local ForkThread = ForkThread
local TrashBagAdd = TrashBag.Add

--- URB2108 : cybran TML
--- Cybran "Loa" Tactical Missile, structure unit launched variant of this projectile,
--- with a higher arc and distance based adjusting trajectory. Splits into child projectile
--- if it takes enough damage.
---@class CIFMissileTactical03 : CLOATacticalMissileProjectile
CIFMissileTactical03 = ClassProjectile(CLOATacticalMissileProjectile) {
    NumChildMissiles = 3,

    ---@param self CLOATacticalMissileProjectile
    OnCreate = function(self)
        CLOATacticalMissileProjectile.OnCreate(self)
        local trash = self.Trash
        self.MoveThread = TrashBagAdd(trash,ForkThread( self.MovementThread,self ))
    end,
}
TypeClass = CIFMissileTactical03