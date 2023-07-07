-- Serpentine Missile 03

local AMissileSerpentine02Projectile = import("/lua/aeonprojectiles.lua").AMissileSerpentine02Projectile

---@class AIFMissileTactical02: AMissileSerpentine02Projectile
AIFMissileTactical02 = ClassProjectile(AMissileSerpentine02Projectile) {

    ---@param self AIFMissileTactical02
    OnCreate = function(self)
        AMissileSerpentine02Projectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.Trash:Add(ForkThread( self.MovementThread,self))
    end,

    ---@param self AIFMissileTactical02
    MovementThread = function(self)
        self:SetTurnRate(3)
        WaitTicks(21)
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitTicks(1)
        end
    end,

    ---@param self AIFMissileTactical02
    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        --Get the nuke as close to 90 deg as possible
        if dist > 100 then
            --Freeze the turn rate as to prevent steep angles at long distance targets
            WaitTicks(21)
            self:SetTurnRate(20)
        elseif dist > 64 and dist <= 107 then
						-- Increase check intervals
						self:SetTurnRate(30)
						WaitTicks(16)
            self:SetTurnRate(30)
        elseif dist > 21 and dist <= 53 then
						-- Further increase check intervals
            WaitTicks(4)
            self:SetTurnRate(50)
				elseif dist > 0 and dist <= 21 then
						-- Further increase check intervals            
            self:SetTurnRate(100)
            KillThread(self.MoveThread)
        end
    end,

    ---@param self AIFMissileTactical02
    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,
}
TypeClass = AIFMissileTactical02