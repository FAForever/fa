-- Aeon Land-Based Tactical Missile

local AMissileSerpentineProjectile = import("/lua/aeonprojectiles.lua").AMissileSerpentineProjectile
AIFMissileTactical02 = ClassProjectile(AMissileSerpentineProjectile) {
    OnCreate = function(self)
        AMissileSerpentineProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.Trash:Add(ForkThread( self.MovementThread,self ))
    end,

    MovementThread = function(self)
        self:TrackTarget(false)
        self:SetCollision(true)
        WaitTicks(21)
        self:SetTurnRate(5)
        WaitTicks(6)
        self:TrackTarget(true)
        self:SetTurnRate(10)
        WaitTicks(6)
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitTicks(6)
        end
    end,

    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        if dist > 125 and self.MovementTurnLevel < 2 then
            self:SetTurnRate(30)
            self.MovementTurnLevel = 1
        elseif dist > 85 and dist <= 125 and self.MovementTurnLevel < 3 then
            self:SetTurnRate(40)
            self.MovementTurnLevel = 2
        elseif dist > 40 and dist <= 85 and self.MovementTurnLevel < 4 then
            self:SetTurnRate(50)
            self.MovementTurnLevel = 3
        elseif dist < 40 then
            self:SetTurnRate(85)
            self.MovementTurnLevel = 4
        end
    end,

    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,
}
TypeClass = AIFMissileTactical02