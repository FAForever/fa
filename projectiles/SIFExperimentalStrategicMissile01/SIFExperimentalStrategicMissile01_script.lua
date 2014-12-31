#****************************************************************************
#**
#**  File     :  /data/projectiles/SIFExperimentalStrategicMissile01/SIFExperimentalStrategicMissile01_script.lua
#**  Author(s):  Gordon Duclos
#**
#**  Summary  :  Experimental Strategic Missile Projectile script, XSB2401
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SExperimentalStrategicMissile = import('/lua/seraphimprojectiles.lua').SExperimentalStrategicMissile

SIFExperimentalStrategicMissile01 = Class(SExperimentalStrategicMissile) {
    FxSplashScale = 0.5,

    LaunchSound = 'Nuke_Launch',
    ExplodeSound = 'Nuke_Impact',
    AmbientSound = 'Nuke_Flight',

	InitialEffects = {
		'/effects/emitters/seraphim_expnuke_fxtrails_01_emit.bp',
		'/effects/emitters/seraphim_expnuke_fxtrails_02_emit.bp',
	},    
    ThrustEffects = {
		'/effects/emitters/seraphim_expnuke_fxtrails_01_emit.bp',
		'/effects/emitters/seraphim_expnuke_fxtrails_02_emit.bp',
	},
    LaunchEffects = {
		'/effects/emitters/seraphim_expnuke_fxtrails_01_emit.bp',
		'/effects/emitters/seraphim_expnuke_fxtrails_02_emit.bp',
	},

    
    OnCreate = function(self)
        SExperimentalStrategicMissile.OnCreate(self)
        local launcher = self:GetLauncher()
        if launcher and not launcher:IsDead() and launcher.EventCallbacks.ProjectileDamaged then
            self.ProjectileDamaged = {}
            for k,v in launcher.EventCallbacks.ProjectileDamaged do
                table.insert( self.ProjectileDamaged, v )
            end
        end 
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.MovementTurnLevel = 1
        self:ForkThread( self.MovementThread )
    end,    

    OnImpact = function(self, TargetType, TargetEntity)
        if not TargetEntity or not EntityCategoryContains(categories.PROJECTILE, TargetEntity) then
            # Play the explosion sound
            local myBlueprint = self:GetBlueprint()
            if myBlueprint.Audio.Explosion then
                self:PlaySound(myBlueprint.Audio.Explosion)
            end
    
            nukeProjectile = self:CreateProjectile('/effects/entities/SeraphimNukeEffectController01/SeraphimNukeEffectController01_proj.bp', 0, 0, 0, nil, nil, nil):SetCollision(false)
            local pos = self:GetPosition()
            pos[2] = pos[2] + 20
            Warp( nukeProjectile, pos)
            nukeProjectile:PassDamageData(self.DamageData)
            nukeProjectile:PassData(self.Data)
        end
        SExperimentalStrategicMissile.OnImpact(self, TargetType, TargetEntity)
    end,

    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        if self.ProjectileDamaged then
            for k,v in self.ProjectileDamaged do
                v(self)
            end
        end
        SExperimentalStrategicMissile.DoTakeDamage(self, instigator, amount, vector, damageType)
    end,

    CreateEffects = function( self, EffectTable, army, scale)
        for k, v in EffectTable do
            self.Trash:Add(CreateAttachedEmitter(self, -1, army, v):ScaleEmitter(scale))
        end
    end,

    MovementThread = function(self)
        local army = self:GetArmy()
        local launcher = self:GetLauncher()
        self.CreateEffects( self, self.InitialEffects, army, 3 )
        self:TrackTarget(false)
        WaitSeconds(2.5)		# Height
        self:SetCollision(true)
        ###self.CreateEffects( self, self.LaunchEffects, army, 1 )
        WaitSeconds(2.5)
        ###self.CreateEffects( self, self.ThrustEffects, army, 3 )
        WaitSeconds(2.5)
        self:TrackTarget(true) # Turn ~90 degrees towards target
        self:SetDestroyOnWater(true)
        self:SetTurnRate(47.36)
        WaitSeconds(2) 					# Now set turn rate to zero so nuke flies straight
        self:SetTurnRate(0)
        self:SetAcceleration(0.001)
        self.WaitTime = 0.5
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitSeconds(self.WaitTime)
        end
    end,

    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        #Get the nuke as close to 90 deg as possible
        if dist > 150 then        
            #Freeze the turn rate as to prevent steep angles at long distance targets
            self:SetTurnRate(0)
        elseif dist > 75 and dist <= 150 then
						# Increase check intervals
            self.WaitTime = 0.3
        elseif dist > 32 and dist <= 75 then
						# Further increase check intervals
            self.WaitTime = 0.1
        elseif dist < 32 then
						# Turn the missile down
            self:SetTurnRate(50)
        end
    end,

    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,

}

TypeClass = SIFExperimentalStrategicMissile01
