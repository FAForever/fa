local TMissileCruiseProjectile = import("/lua/terranprojectiles.lua").TMissileCruiseProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")

---@class TIFMissileCruise03: TMissileCruiseProjectile
TIFMissileCruise03 = ClassProjectile(TMissileCruiseProjectile) {

    FxTrails = EffectTemplate.TMissileExhaust01,
    FxTrailOffset = -0.85,
    FxAirUnitHitScale = 0.65,
    FxLandHitScale = 0.65,
    FxNoneHitScale = 0.65,
    FxPropHitScale = 0.65,
    FxProjectileHitScale = 0.65,
    FxProjectileUnderWaterHitScale = 0.65,
    FxShieldHitScale = 0.65,
    FxUnderWaterHitScale = 0.65,
    FxUnitHitScale = 0.65,
    FxWaterHitScale = 0.65,
    FxOnKilledScale = 0.65,

    ---@param self TIFMissileCruise03
    OnCreate = function(self)
        TMissileCruiseProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2)        
        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread,self))
    end,

    ---@param self TIFMissileCruise03
    MovementThread = function(self)        
        self.Distance = self:GetDistanceToTarget()
        self:SetTurnRate(8)
        WaitTicks(4)        
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitTicks(2)
        end
    end,

    ---@param self TIFMissileCruise03
    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        if dist > self.Distance then
        	self:SetTurnRate(75)
        	WaitTicks(31)
        	self:SetTurnRate(8)
        	self.Distance = self:GetDistanceToTarget()
        end
        -- Get the nuke as close to 90 deg as possible
        if dist > 50 then        
            -- Freeze the turn rate as to prevent steep angles at long distance targets
            WaitTicks(21)
            self:SetTurnRate(10)
        elseif dist > 30 and dist <= 50 then
						-- Increase check intervals
						self:SetTurnRate(12)
						WaitTicks(16)
            self:SetTurnRate(12)
        elseif dist > 10 and dist <= 25 then
						-- Further increase check intervals
                        WaitTicks(4)
            self:SetTurnRate(50)
				elseif dist > 0 and dist <= 10 then
						-- Further increase check intervals            
            self:SetTurnRate(100)   
            KillThread(self.MoveThread)         
        end
    end,        

    ---@param self TIFMissileCruise03
    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,
}
TypeClass = TIFMissileCruise03

