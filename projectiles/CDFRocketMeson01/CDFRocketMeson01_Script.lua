local CRocketProjectile = import("/lua/cybranprojectiles.lua").CRocketProjectile

--- Cybran Dumbfire Rocket
---@class CDFRocketMeson01 : CRocketProjectile
CDFRocketMeson01 = ClassProjectile(CRocketProjectile) {
    PolyTrail = '/effects/emitters/default_polytrail_06_emit.bp',

    ---@param self CDFRocketMeson01
    OnCreate = function(self)
        CRocketProjectile.OnCreate(self)
        self.Trash:Add(ForkThread(self.UpdateThread,self))
   end,

    ---@param self CDFRocketMeson01
    UpdateThread = function(self)
        WaitTicks(2)
        self:SetMesh('/projectiles/CDFRocketMeson01/CDFRocketMesonUnPacked01_mesh')
        local army = self.Army

        -- Polytrails offset to wing tips
        CreateTrail(self, -1, army, self.PolyTrail ):OffsetEmitter(0.075, -0.05, 0.25)
        CreateTrail(self, -1, army, self.PolyTrail ):OffsetEmitter(-0.085, -0.055, 0.25)
        CreateTrail(self, -1, army, self.PolyTrail ):OffsetEmitter(0, 0.09, 0.25)
    end,
}
TypeClass = CDFRocketMeson01