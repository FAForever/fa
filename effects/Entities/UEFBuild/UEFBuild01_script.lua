--- Dummy projectile for UEF build effect
-- @class UEFBuild01 : DummyProjectile

local dummyProj = import("/lua/sim/projectile.lua").DummyProjectile
UEFBuild01 = ClassDummyProjectile(dummyProj) {
    OnCreate = function(self, inWater)
        self.CreatedAtTraceback = debug.traceback()
        dummyProj.OnCreate(self, inWater)
        local bp = self.Blueprint.Physics
        LOG('UEF build effect lifetime', bp.Lifetime, bp.LifetimeRange)
        LOG('UEF build effect detonation', bp.DetonateAboveHeight, bp.DetonateBelowHeight)
        -- self:ChangeDetonateBelowHeight(-10000)
        self:SetBallisticAcceleration(-50000)
    end,
    Destroy = function(self)
        self.DestroyedAtTraceback = debug.traceback()
        dummyProj.Destroy(self)
    end,
    ---@param self DummyProjectile
    ---@param targetType string
    ---@param targetEntity Unit | Prop
    OnImpact = function(self, targetType, targetEntity)
        LOG('UEF Build effect impacted'
            , targetType
            , targetEntity.UnitId
            , targetEntity.EntityId
            , targetEntity.__name
            , repr(targetEntity)
            , repr(self:GetPosition())
            , debug.traceback()
        )
        self:Destroy()
    end,
    SetLifetime = function(self, seconds)
        LOG('UEF Build effect lifetime set'
            , seconds
            , debug.traceback())
        dummyProj.SetLifetime(self, seconds)
    end,

}
TypeClass = UEFBuild01