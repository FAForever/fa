--****************************************************************************
--**
--**  File     :  /lua/defaultantimissile.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Default definitions collision beams
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local Entity = import('/lua/sim/Entity.lua').Entity
local GetRandomFloat = import('/lua/utilities.lua').GetRandomFloat

Flare = Class(Entity){
        OnCreate = function(self, spec)
            self.Army = self:GetArmy()
            self.Owner = spec.Owner
            self.Radius = spec.Radius or 5
            self.OffsetMult = spec.OffsetMult or 0
            self:SetCollisionShape('Sphere', 0, 0, self.Radius * self.OffsetMult, self.Radius)
            self:SetDrawScale(self.Radius)
            self:AttachTo(spec.Owner, -1)
            self.RedirectCat = spec.Category or 'MISSILE'
        end,

        -- We only divert projectiles. The flare-projectile itself will be responsible for
        -- accepting the collision and causing the hostile projectile to impact.
        OnCollisionCheck = function(self, other)
            myArmy = self.Army
            otherArmy = other.Army
            if EntityCategoryContains(ParseEntityCategory(self.RedirectCat), other) and myArmy ~= otherArmy and IsAlly(myArmy, otherArmy) == false then
                other:SetNewTarget(self.Owner)
            end
            return false
        end,
}

DepthCharge = Class(Entity){
    OnCreate = function(self, spec)
        self.Army = self:GetArmy()
        self.Owner = spec.Owner
        self.Radius = spec.Radius
        self:SetCollisionShape('Sphere', 0, 0, 0, self.Radius)
        self:SetDrawScale(self.Radius)
        self:AttachTo(spec.Owner, -1)
    end,

    -- We only divert projectiles. The flare-projectile itself will be responsible for
    -- accepting the collision and causing the hostile projectile to impact.
    OnCollisionCheck = function(self, other)
        myArmy = self.Army
        otherArmy = other.Army
        if EntityCategoryContains(categories.TORPEDO, other) and myArmy ~= otherArmy and IsAlly(myArmy, otherArmy) == false then
            other:SetNewTarget(self.Owner)
        end
        return false
    end,
}

MissileRedirect = Class(Entity) {
        RedirectBeams = { '/effects/emitters/particle_cannon_beam_02_emit.bp' },
        EndPointEffects = {'/effects/emitters/particle_cannon_end_01_emit.bp' },

        OnCreate = function(self, spec)
            Entity.OnCreate(self, spec)
            self.Owner = spec.Owner
            self.Radius = spec.Radius
            self.RedirectRateOfFire = spec.RedirectRateOfFire or 1
            self:SetCollisionShape('Sphere', 0, 0, 0, self.Radius)
            self:SetDrawScale(self.Radius)
            self.AttachBone = spec.AttachBone
            self:AttachTo(spec.Owner, spec.AttachBone)
            ChangeState(self, self.WaitingState)
        end,

        OnDestroy = function(self)
            Entity.OnDestroy(self)
            ChangeState(self, self.DeadState)
        end,

        DeadState = State{
            Main = function(self)
            end,
        },

        -- Return true to process this collision, false to ignore it.
        WaitingState = State {
            OnCollisionCheck = function(self, other)
                if EntityCategoryContains(categories.MISSILE, other) and not EntityCategoryContains(categories.STRATEGIC, other) and
                   other ~= self.EnemyProj and IsEnemy(self.Army, other.Army) then
                    self.Enemy = other:GetLauncher()
                    self.EnemyProj = other

                    ChangeState(self, self.RedirectingState)
                end
                return false
            end,
        },

        RedirectingState = State{
            Main = function(self)
                if not self or self:BeenDestroyed() or
                   not self.EnemyProj or self.EnemyProj:BeenDestroyed() or
                   not self.Owner or self.Owner.Dead then
                    if self then
                        ChangeState(self, self.WaitingState)
                    end

                    return
                end

                local beams = {}
                for k, v in self.RedirectBeams do
                    table.insert(beams, AttachBeamEntityToEntity(self.EnemyProj, -1, self.Owner, self.AttachBone, self.Army, v))
                end

                if self.Enemy then
                    -- Set collision to friends active so that when the missile reaches its source it can deal damage.
                    self.EnemyProj.CollideFriendly = true
                    self.EnemyProj.DamageData.DamageFriendly = true
                    self.EnemyProj.DamageData.DamageSelf = true
                end

                if not self.EnemyProj:BeenDestroyed() then
                    local proj = self.EnemyProj
                    local enemy = self.Enemy
                    local enemyPos = enemy and enemy:GetPosition()

                    if proj.MoveThread then
                        KillThread(proj.MoveThread)
                        proj.MoveThread = nil
                    end

                    proj:ForkThread(function()
                        local projPos = proj:GetPosition()
                        local above = {projPos[1] + GetRandomFloat(-2, 2), projPos[2] + GetRandomFloat(4, 6), projPos[3] + GetRandomFloat(-2, 2)}

                        proj:SetLifetime(30)
                        proj:SetCollideSurface(true)
                        proj:SetTurnRate(160)
                        proj:SetNewTargetGround(above)
                        proj:TrackTarget(true)
                        WaitSeconds(1)

                        if proj:BeenDestroyed() then return end
                        if not enemy then
                            proj:DoTakeDamage(self.Owner, 30, Vector(0, 1, 0), 'Fire')
                        elseif not enemy:BeenDestroyed() then
                            proj:SetNewTarget(enemy)
                            WaitSeconds(2)
                            enemyPos = enemy:GetPosition()
                        end

                        -- aim at right below surface if unit is submerged
                        enemyPos = enemyPos or projPos
                        local surfaceHeight = GetSurfaceHeight(enemyPos[1], enemyPos[3]) - 0.02
                        enemyPos[2] = math.max(surfaceHeight, enemyPos[2])

                        proj:SetNewTargetGround(enemyPos)
                    end)
                end

                WaitSeconds(1 / self.RedirectRateOfFire)
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
