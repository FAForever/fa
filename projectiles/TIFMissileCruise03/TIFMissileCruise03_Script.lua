--
-- Terran Land-Based Cruise Missile : UEL0111 (UEF T2 MML)
--

local TMissileCruiseProjectile = import("/lua/terranprojectiles.lua").TMissileCruiseProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")

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
    
    OnCreate = function(self)
        TMissileCruiseProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2)        
        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread,self))
    end,

    MovementThread = function(self)
        self:SetTurnRate(8)
        WaitTicks(4)
        self.Distance = self:GetDistanceToTarget()
        local turnrate = 500 / math.pow(self.Distance, 0.75)
        self:SetTurnRate(math.min(turnrate, 170))
        KillThread(self.MoveThread)
    end,

    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,
}
TypeClass = TIFMissileCruise03

