--
-- Terran Land-Based Cruise Missile : UES0202 (UEF cruiser)
--

local TMissileCruiseProjectile = import('/lua/terranprojectiles.lua').TMissileCruiseProjectile
local Explosion = import('/lua/defaultexplosions.lua')

TIFMissileCruise04 = Class(TMissileCruiseProjectile) {

    FxAirUnitHitScale = 1.5,
    FxLandHitScale = 1.5,
    FxNoneHitScale = 1.5,
    FxPropHitScale = 1.5,
    FxProjectileHitScale = 1.5,
    FxProjectileUnderWaterHitScale = 1.5,
    FxShieldHitScale = 1.5,
    FxUnderWaterHitScale = 1.5,
    FxUnitHitScale = 1.5,
    FxWaterHitScale = 1.5,
    FxOnKilledScale = 1.5,

    OnCreate = function(self)
        TMissileCruiseProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.MovementTurnLevel = 1
        self:ForkThread( self.MovementThread )
    end,

    MovementThread = function(self)        
        self.WaitTime = 0.1
        self:SetTurnRate(8)
        WaitSeconds(0.3)        
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitSeconds(self.WaitTime)
        end
    end,

    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        -- Get the nuke as close to 90 deg as possible
        if dist > 50 then        
            -- Freeze the turn rate as to prevent steep angles at long distance targets
            WaitSeconds(2)
            self:SetTurnRate(20)
        elseif dist > 64 and dist <= 107 then
						-- Increase check intervals
						self:SetTurnRate(30)
						WaitSeconds(1.5)
            self:SetTurnRate(30)
        elseif dist > 21 and dist <= 53 then
						-- Further increase check intervals
            WaitSeconds(0.3)
            self:SetTurnRate(50)
				elseif dist > 0 and dist <= 21 then
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
    
    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0,2*math.pi)
            local army = self.Army

            CreateDecal(pos, rotation, 'nuke_scorch_002_albedo', '', 'Albedo', radius, radius, 180, 40, army)
        end
        
        TMissileCruiseProjectile.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = TIFMissileCruise04

