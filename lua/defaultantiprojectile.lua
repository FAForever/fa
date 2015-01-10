#****************************************************************************
#**
#**  File     :  /lua/defaultantimissile.lua
#**  Author(s):  Gordon Duclos
#**
#**  Summary  :  Default definitions collision beams
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local Entity = import('/lua/sim/Entity.lua').Entity

Flare = Class(Entity) {

    OnCreate = function(self, spec)
        self.Owner = spec.Owner
        self.Radius = spec.Radius or 5
        self:SetCollisionShape('Sphere', 0, 0, 0, self.Radius)
        self:SetDrawScale(self.Radius)
        self:AttachTo(spec.Owner, -1)
        self.RedirectCat = spec.Category or 'MISSILE'
    end,

    # We only divert projectiles. The flare-projectile itself will be responsible for
    # accepting the collision and causing the hostile projectile to impact.
    OnCollisionCheck = function(self,other)
        if EntityCategoryContains(ParseEntityCategory(self.RedirectCat), other) and (self:GetArmy() != other:GetArmy())then
            #LOG('*DEBUG FLARE COLLISION CHECK')
            other:SetNewTarget(self.Owner)
        end
        return false
    end,
}


DepthCharge = Class(Entity) {
    OnCreate = function(self, spec)
        self.Owner = spec.Owner
        self.Radius = spec.Radius
        self:SetCollisionShape('Sphere', 0, 0, 0, self.Radius)
        self:SetDrawScale(self.Radius)
        self:AttachTo(spec.Owner, -1)
    end,

    # We only divert projectiles. The flare-projectile itself will be responsible for
    # accepting the collision and causing the hostile projectile to impact.
    OnCollisionCheck = function(self,other)
        if EntityCategoryContains(categories.TORPEDO, other) and self:GetArmy() != other:GetArmy() then
            other:SetNewTarget(self.Owner)
        end
        return false
    end,
}

MissileRedirect = Class(Entity) {

    RedirectBeams = {#'/effects/emitters/particle_cannon_beam_01_emit.bp',
                   '/effects/emitters/particle_cannon_beam_02_emit.bp'},
    EndPointEffects = {'/effects/emitters/particle_cannon_end_01_emit.bp',},
    
    #AttachBone = function( AttachBone )
    #    self:AttachTo(spec.Owner, self.AttachBone)
    #end, 

    OnCreate = function(self, spec)
        Entity.OnCreate(self, spec)
        #LOG('*DEBUG MISSILEREDIRECT START BEING CREATED')
        self.Owner = spec.Owner
        self.Radius = spec.Radius
        self.RedirectRateOfFire = spec.RedirectRateOfFire or 1
        self:SetCollisionShape('Sphere', 0, 0, 0, self.Radius)
        self:SetDrawScale(self.Radius)
        self.AttachBone = spec.AttachBone
        self:AttachTo(spec.Owner, spec.AttachBone)
        ChangeState(self, self.WaitingState)
        #LOG('*DEBUG MISSILEREDIRECT DONE BEING CREATED')
    end,

    OnDestroy = function(self)
        Entity.OnDestroy(self)
        ChangeState(self, self.DeadState)
    end,

    DeadState = State {
        Main = function(self)
        end,
    },

    # Return true to process this collision, false to ignore it.

    WaitingState = State{
        OnCollisionCheck = function(self, other)
            #LOG('*DEBUG MISSILE REDIRECT COLLISION CHECK')
            if EntityCategoryContains(categories.MISSILE, other) and not EntityCategoryContains(categories.STRATEGIC, other) 
                        and other != self.EnemyProj and IsEnemy( self:GetArmy(), other:GetArmy() ) then
                self.Enemy = other:GetLauncher()
                self.EnemyProj = other
                #NOTE: Fix me We need to test enemy validity if there is no enemy 
                #      set target to 180 of the unit
                if self.Enemy then
                    other:SetNewTarget(self.Enemy)
                    other:TrackTarget(true)
                    other:SetTurnRate(720)
                end
                ChangeState(self, self.RedirectingState)
            end
            return false
        end,
    },

    RedirectingState = State{

        Main = function(self)
            if not self or self:BeenDestroyed() 
            or not self.EnemyProj or self.EnemyProj:BeenDestroyed() 
            or not self.Owner or self.Owner:IsDead() then
                return
            end
            
            local beams = {}
            for k, v in self.RedirectBeams do               
                table.insert(beams, AttachBeamEntityToEntity(self.EnemyProj, -1, self.Owner, self.AttachBone, self:GetArmy(), v))
            end
            if self.Enemy then
            # Set collision to friends active so that when the missile reaches its source it can deal damage. 
			    self.EnemyProj.DamageData.CollideFriendly = true         
			    self.EnemyProj.DamageData.DamageFriendly = true 
			    self.EnemyProj.DamageData.DamageSelf = true 
			end
            if self.Enemy and not self.Enemy:BeenDestroyed() then
                WaitSeconds(1/self.RedirectRateOfFire)
                if not self.EnemyProj:BeenDestroyed() then
                     self.EnemyProj:TrackTarget(false)
                end
            else
                WaitSeconds(1/self.RedirectRateOfFire)
                local vectordam = {}
                vectordam.x = 0
                vectordam.y = 1
                vectordam.z = 0
                self.EnemyProj:DoTakeDamage(self.Owner, 30, vectordam,'Fire')
            end
            for k, v in beams do
                v:Destroy()
            end
            ChangeState(self, self.WaitingState)
        end,

        OnCollisionCheck = function(self, other)
            return false
        end,
    },

}
