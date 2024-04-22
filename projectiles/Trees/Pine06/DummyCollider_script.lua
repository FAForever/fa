---@class DummyCollider : DummyProjectile
DummyCollider = ClassDummyProjectile(import("/lua/sim/projectile.lua").DummyProjectile) {

    OnCollisionCheck = function(self, other)
        return self.Parent:OnCollisionCheck(other)
    end,

    OnImpact = function(self, targetType, targetEntity)
        return self.Parent:OnCollision(targetType, targetEntity)
    end,
}
TypeClass = DummyCollider