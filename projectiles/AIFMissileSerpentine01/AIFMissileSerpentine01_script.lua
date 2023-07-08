local AMissileSerpentineProjectile = import("/lua/aeonprojectiles.lua").AMissileSerpentineProjectile

-- Aeon Serpentine Missile
---@class AIFMissileSerpentine01: AMissileSerpentineProjectile
AIFMissileSerpentine01 = ClassProjectile(AMissileSerpentineProjectile) {

    ---@param self AIFMissileSerpentine01
    OnCreate = function(self)
        AMissileSerpentineProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2)
        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread,self))
    end,

    ---@param self AIFMissileSerpentine01
    MovementThread = function(self)
        self.Distance = self:GetDistanceToTarget()
        self:SetTurnRate(8)
        WaitTicks(4)
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitTicks(2)
        end
    end,

    ---@param self AIFMissileSerpentine01
    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        if dist > self.Distance then
        	self:SetTurnRate(75)
        	WaitTicks(31)
        	self:SetTurnRate(8)
        	self.Distance = self:GetDistanceToTarget()
        end
        if dist > 50 then
            WaitTicks(21)
            self:SetTurnRate(10)
        elseif dist > 30 and dist <= 50 then
						self:SetTurnRate(12)
						WaitTicks(16)
            self:SetTurnRate(12)
        elseif dist > 10 and dist <= 25 then
            WaitTicks(4)
            self:SetTurnRate(50)
				elseif dist > 0 and dist <= 10 then
            self:SetTurnRate(100)
            KillThread(self.MoveThread)
        end
    end,

    ---@param self AIFMissileSerpentine01
    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,
}
TypeClass = AIFMissileSerpentine01