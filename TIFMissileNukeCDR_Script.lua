--
-- Terran CDR Nuke
--
local TIFMissileNuke = import('/lua/terranprojectiles.lua').TIFMissileNuke

TIFMissileNukeCDR = Class(TIFMissileNuke) {

    BeamName = '/effects/emitters/missile_exhaust_fire_beam_06_emit.bp',
    InitialEffects = {'/effects/emitters/nuke_munition_launch_trail_02_emit.bp',},
    LaunchEffects = {
        '/effects/emitters/nuke_munition_launch_trail_03_emit.bp',
        '/effects/emitters/nuke_munition_launch_trail_05_emit.bp',
    },
    ThrustEffects = {'/effects/emitters/nuke_munition_launch_trail_04_emit.bp',},    
    
    OnCreate = function(self)
        TIFMissileNuke.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.MovementTurnLevel = 1
        self:ForkThread( self.MovementThread )
    end,
    
    OnImpact = function(self, TargetType, TargetEntity)
        if not TargetEntity or not EntityCategoryContains(categories.PROJECTILE, TargetEntity) then
            -- Play the explosion sound
            local myBlueprint = self:GetBlueprint()
            if myBlueprint.Audio.Explosion then
                self:PlaySound(myBlueprint.Audio.Explosion)
            end
           
            nukeProjectile = self:CreateProjectile('/effects/Entities/UEFNukeEffectController01/UEFNukeEffectController01_proj.bp', 0, 0, 0, nil, nil, nil):SetCollision(false)
            nukeProjectile:PassDamageData(self.DamageData)
            nukeProjectile:PassData(self.Data)
        end
        TIFMissileNuke.OnImpact(self, TargetType, TargetEntity)
    end,    
    
    CreateEffects = function( self, EffectTable, army, scale)
        for k, v in EffectTable do
            self.Trash:Add(CreateAttachedEmitter(self, -1, army, v):ScaleEmitter(scale))
        end
    end,

--    MovementThread = function(self)
--        local army = self:GetArmy()
--        local target = self:GetTrackingTarget()
--        local launcher = self:GetLauncher()
--        self:TrackTarget(false)
--        self.CreateEffects( self, self.InitialEffects, army, 1 )        
--        WaitSeconds(3)
--        self.CreateEffects( self, self.LaunchEffects, army, 1 )
--        self.CreateEffects( self, self.ThrustEffects, army, 1 )   
--        self:SetCollision(true)
--        WaitSeconds(3)
--        self:SetTurnRate(5)
--        WaitSeconds(6)
--        self:TrackTarget(true)
--        self:SetDestroyOnWater(true)
--        self:SetTurnRate(25)
--        WaitSeconds(3.5)
--        self:SetBallisticAcceleration(10)
--        while not self:BeenDestroyed() do
--            self:SetTurnRateByDist()
--            WaitSeconds(0.5)
--        end
--    end,

     MovementThread = function(self)   
        local army = self:GetArmy()
        local target = self:GetTrackingTarget()
        local launcher = self:GetLauncher()            
        self.CreateEffects( self, self.InitialEffects, army, 1 )      
        self.WaitTime = 0.1
        self:SetTurnRate(8)
        WaitSeconds(0.3)   
        self.CreateEffects( self, self.LaunchEffects, army, 1 )
        self.CreateEffects( self, self.ThrustEffects, army, 1 )        
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitSeconds(self.WaitTime)
        end
    end,

    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        if dist > 50 then        
            --Freeze the turn rate as to prevent steep angles at long distance targets
            WaitSeconds(2)
            self:SetTurnRate(20)
        elseif dist > 128 and dist <= 213 then
            -- Increase check intervals
            self:SetTurnRate(30)
            WaitSeconds(1.5)
            self:SetTurnRate(30)
        elseif dist > 43 and dist <= 107 then
            -- Further increase check intervals
            WaitSeconds(0.3)
            self:SetTurnRate(75)
        elseif dist > 0 and dist <= 43 then
            -- Further increase check intervals            
            self:SetTurnRate(200)   
            KillThread(self.MoveThread)         
        end
    end,        

    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,
    
    OnEnterWater = function(self)
        TIFMissileNuke.OnEnterWater(self)
        self:SetDestroyOnWater(true)
    end,    
}
TypeClass = TIFMissileNukeCDR

