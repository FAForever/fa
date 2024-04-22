---@class DummyCollider : DummyProjectile
DummyCollider = ClassDummyProjectile(import("/lua/sim/projectile.lua").DummyProjectile) {

    OnCreate = function(self)
        self:SetVizToFocusPlayer('Never') -- Set to 'Always' to see a nice box
        self:SetVizToAllies('Never')
        self:SetVizToNeutrals('Never')
        self:SetVizToEnemies('Never')
        self:SetCollision(true)
    end,

    OnCollisionCheck = function(self, other)
        return self.Parent:OnCollisionCheck(other)
    end,

    OnImpact = function(self, targetType, targetEntity)
        return self.Parent:OnCollision(targetType, targetEntity)
    end,
}
TypeClass = DummyCollider