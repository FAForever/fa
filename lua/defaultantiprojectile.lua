--****************************************************************************
--**
--**  File     :  /lua/defaultantimissile.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Default definitions collision beams
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local projectile_methodsTrackTarget = moho.projectile_methods.TrackTarget
local GetSurfaceHeight = GetSurfaceHeight
local entity_methodsSetCollisionShape = moho.entity_methods.SetCollisionShape
local IsEnemy = IsEnemy
local projectile_methodsSetNewTarget = moho.projectile_methods.SetNewTarget
local entity_methodsSetDrawScale = moho.entity_methods.SetDrawScale
local ParseEntityCategory = ParseEntityCategory
local ipairs = ipairs
local tableInsert = table.insert
local next = next
local AttachBeamEntityToEntity = AttachBeamEntityToEntity
local KillThread = KillThread
local projectile_methodsSetNewTargetGround = moho.projectile_methods.SetNewTargetGround
local entity_methodsBeenDestroyed = moho.entity_methods.BeenDestroyed
local Vector = Vector
local mathMax = math.max
local entity_methodsAttachTo = moho.entity_methods.AttachTo
local projectile_methodsSetTurnRate = moho.projectile_methods.SetTurnRate
local projectile_methodsSetCollideSurface = moho.projectile_methods.SetCollideSurface
local EntityCategoryContains = EntityCategoryContains
local projectile_methodsSetLifetime = moho.projectile_methods.SetLifetime

local Entity = import('/lua/sim/Entity.lua').Entity
local GetRandomFloat = import('/lua/utilities.lua').GetRandomFloat

Flare = Class(Entity){
        OnCreate = function(self, spec)
            self.Owner = spec.Owner
            self.Radius = spec.Radius or 5
            entity_methodsSetCollisionShape(self, 'Sphere', 0, 0, 0, self.Radius)
            entity_methodsSetDrawScale(self, self.Radius)
            entity_methodsAttachTo(self, spec.Owner, -1)
            self.RedirectCat = spec.Category or 'MISSILE'
        end,

        -- We only divert projectiles. The flare-projectile itself will be responsible for
        -- accepting the collision and causing the hostile projectile to impact.
        OnCollisionCheck = function(self, other)
            if EntityCategoryContains(ParseEntityCategory(self.RedirectCat), other) and (self.Army ~= other.Army) then
                projectile_methodsSetNewTarget(other, self.Owner)
            end
            return false
        end,
}

DepthCharge = Class(Entity){
    OnCreate = function(self, spec)
        self.Owner = spec.Owner
        self.Radius = spec.Radius
        entity_methodsSetCollisionShape(self, 'Sphere', 0, 0, 0, self.Radius)
        entity_methodsSetDrawScale(self, self.Radius)
        entity_methodsAttachTo(self, spec.Owner, -1)
    end,

    -- We only divert projectiles. The flare-projectile itself will be responsible for
    -- accepting the collision and causing the hostile projectile to impact.
    OnCollisionCheck = function(self, other)
        if EntityCategoryContains(categories.TORPEDO, other) and self.Army ~= other.Army then
            projectile_methodsSetNewTarget(other, self.Owner)
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
            entity_methodsSetCollisionShape(self, 'Sphere', 0, 0, 0, self.Radius)
            entity_methodsSetDrawScale(self, self.Radius)
            self.AttachBone = spec.AttachBone
            entity_methodsAttachTo(self, spec.Owner, spec.AttachBone)
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
                if not self or entity_methodsBeenDestroyed(self) or
                   not self.EnemyProj or self.EnemyProj:BeenDestroyed() or
                   not self.Owner or self.Owner.Dead then
                    if self then
                        ChangeState(self, self.WaitingState)
                    end

                    return
                end

                local beams = {}
                for k, v in self.RedirectBeams do
                    tableInsert(beams, AttachBeamEntityToEntity(self.EnemyProj, -1, self.Owner, self.AttachBone, self.Army, v))
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

                        projectile_methodsSetLifetime(proj, 30)
                        projectile_methodsSetCollideSurface(proj, true)
                        projectile_methodsSetTurnRate(proj, 160)
                        projectile_methodsSetNewTargetGround(proj, above)
                        projectile_methodsTrackTarget(proj, true)
                        WaitSeconds(1)

                        if proj:BeenDestroyed() then return end
                        if not enemy then
                            proj:DoTakeDamage(self.Owner, 30, Vector(0, 1, 0), 'Fire')
                        elseif not enemy:BeenDestroyed() then
                            projectile_methodsSetNewTarget(proj, enemy)
                            WaitSeconds(2)
                            enemyPos = enemy:GetPosition()
                        end

                        -- aim at right below surface if unit is submerged
                        enemyPos = enemyPos or projPos
                        local surfaceHeight = GetSurfaceHeight(enemyPos[1], enemyPos[3]) - 0.02
                        enemyPos[2] = mathMax(surfaceHeight, enemyPos[2])

                        projectile_methodsSetNewTargetGround(proj, enemyPos)
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
