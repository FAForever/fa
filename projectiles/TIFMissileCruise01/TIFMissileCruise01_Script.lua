--
-- Terran Land-Based Cruise Missile
--
local TMissileCruiseProjectile = import("/lua/terranprojectiles.lua").TMissileCruiseProjectile02
local EffectTemplate = import("/lua/effecttemplates.lua")

TIFMissileCruise01 = ClassProjectile(TMissileCruiseProjectile) {

	FxAirUnitHitScale = 1.65,
    FxLandHitScale = 1.65,
    FxNoneHitScale = 1.65,
    FxPropHitScale = 1.65,
    FxProjectileHitScale = 1.65,
    FxProjectileUnderWaterHitScale = 1.65,
    FxShieldHitScale = 1.65,
    FxUnderWaterHitScale = 1.65,
    FxUnitHitScale = 1.65,
    FxWaterHitScale = 1.65,
    FxOnKilledScale = 1.65,

    FxTrails = EffectTemplate.TMissileExhaust01,

    OnCreate = function(self)
        TMissileCruiseProjectile.OnCreate(self)
        self.Trash:Add(ForkThread( self.MovementThread,self ))
    end,
    
    MovementThread = function(self)
        self:SetTurnRate(8)
        WaitTicks(4)
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitTicks(2)
        end
    end,

    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        --Get the nuke as close to 90 deg as possible
        if dist > 50 then        
            --Freeze the turn rate as to prevent steep angles at long distance targets
            WaitTicks(21)
            self:SetTurnRate(20)
        elseif dist > 128 and dist <= 213 then
						-- Increase check intervals
						self:SetTurnRate(30)
						WaitTicks(16)
            self:SetTurnRate(30)
        elseif dist > 43 and dist <= 107 then
						-- Further increase check intervals
                        WaitTicks(4)
            self:SetTurnRate(50)
				elseif dist > 0 and dist <= 43 then
						-- Further increase check intervals            
            self:SetTurnRate(100)   
            KillThread(self.MoveThread)         
        end
    end,        

    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,
}
TypeClass = TIFMissileCruise01