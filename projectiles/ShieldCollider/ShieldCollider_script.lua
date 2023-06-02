--------------------------------------------------------------------
-- File     :  /projectiles/ShieldCollider_script.lua
-- Author(s):  Exotic_Retard, made for Equilibrium Balance Mod
-- Summary  : Companion projectile enabling air units to hit shields
-- Copyright c 2005 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------
local Projectile = import("/lua/sim/projectile.lua").Projectile
local VectorCached = Vector(0, 0, 0)

ShieldCollider = ClassProjectile(Projectile) {
    OnCreate = function(self, inWater)
        Projectile.OnCreate(self)

        self.CrashingAirplaneShieldCollisionLogic = true
        self:SetVizToFocusPlayer('Never') -- Set to 'Always' to see a nice box
        self:SetVizToAllies('Never')
        self:SetVizToNeutrals('Never')
        self:SetVizToEnemies('Never')
        self:SetStayUpright(false)
        self:SetCollision(true)

        if inWater then
            self:OnImpact('Water', nil)
        end
    end,
    -- Shields only detect projectiles, so we attach one to keep track of the unit.
    Start = function(self, parent, bone)
        self.PlaneBone = bone
        self.Plane = parent
        self:StartFalling()
    end,
    StartFalling = function(self)
        local vx, vy, vz = self.Plane:GetVelocity()
        -- For now we just follow the plane along, not attaching so it can rotate
        self:SetVelocity(10 * vx, 10 * vy, 10 * vz)
        Warp(self, self.Plane:GetPosition(self.PlaneBone), self.Plane:GetOrientation())
    end,

    OnCollisionCheck = function(self, other)
        -- We intercept this just incase the projectile collides with something it shouldn't
        WARN('Shield collision projectile checking collision! Fix me!')
        if IsUnit(other) then WARN('It was a unit!') return end

        Projectile.OnCollisionCheck(self, other)
    end,

    OnDestroy = function(self)
        self:DetachAll('anchor') -- If our projectile is getting destroyed we never want to have anything attached
        if self.Trash then
            self.Trash:Destroy()
        end
    end,

    OnEnterWater = function(self)
        self:OnImpact('Water', nil)
    end,

    -- Destroy the sinking unit when it hits the ground.
    OnImpact = function(self, targetType, targetEntity)
        if self and not self:BeenDestroyed() and self.Plane and not self.Plane:BeenDestroyed() then
            if targetType == 'Terrain' or targetType == 'Water' then
                -- Here it should be noted that bone 0 IS NOT what the ground checks for, so if you have a projectile at that bone
                -- and the units centre is below it, then its below the ground and that can cause it to hit water instead.
                -- All this is just to prevent that, because falling planes are stupid.

                self:SetVelocity(0, 0, 0)
                if not self.Plane.GroundImpacted then
                    self.Plane:OnImpact(targetType)
                end

                self:Destroy()
            elseif targetType == 'Shield' and targetEntity and not targetEntity:BeenDestroyed() and targetEntity.ShieldType == 'Bubble' then
                if not self.ShieldImpacted and not self.Plane.GroundImpacted then
                    self.ShieldImpacted = true -- Only impact once

                    -- Find the vector to the impact location, used for the impact ripple FX
                    local wx, wy, wz = unpack(VDiff(targetEntity:GetPosition(), self:GetPosition())) -- Vector from mid of shield to impact point

                    local shieldImpactVector = VectorCached
                    VectorCached[1] = wx 
                    VectorCached[2] = wy 
                    VectorCached[3] = wz 

                    local exclusions = categories.EXPERIMENTAL + categories.TRANSPORTATION - categories.uea0203
                    if not EntityCategoryContains(exclusions, self.Plane) then -- Exclude experimentals and transports from momentum system, but not damage
                        Warp(self, self.Plane:GetPosition(self.PlaneBone), self.Plane:GetOrientation())

                        self:DetachAll('anchor') -- Make sure to detach just in case, prior to trying to attach
                        self.Plane:DetachAll(self.PlaneBone)

                        self.Plane:AttachBoneTo(self.PlaneBone, self, 'anchor') -- We attach our bone at the very last moment when we need it
                        self.Plane.Detector = CreateCollisionDetector(self.Plane)
                        self.Plane.Detector:WatchBone(self.PlaneBone)
                        self.Plane.Detector:EnableTerrainCheck(true)
                        self.Plane.Detector:Enable()

                        -- If you try to deattach the plane, it has retarded game code that makes it continue falling in its original direction
                        self:ShieldBounce(targetEntity, shieldImpactVector) -- Calculate the appropriate change of velocity
                    end

                    if not self.Plane.deathWep or not self.Plane.DeathCrashDamage then -- Bail if stuff's missing.
                        WARN('ShieldCollider: did not find a deathWep on the plane! Is the weapon defined in the blueprint? - ' .. self.UnitId)
                        return
                    end

                    local initialDamage = self.Plane.DeathCrashDamage
                    local deathWep = self.Plane.deathWep

                    -- Calculate damage dealt, up to a maximum of 20% of the shield's maximum HP
                    local shieldDamageLimit = targetEntity:GetMaxHealth() * 0.2

                    local mult = deathWep.DeathCrashShieldMult or 1 -- Allow a unit to be designated as dealing less than normal damage to shields on crash
                    local damage = initialDamage * mult

                    -- Damage the shield
                    local finalDamage = math.min(shieldDamageLimit, damage)
                    targetEntity:ApplyDamage(self.Plane, finalDamage, shieldImpactVector, deathWep.DamageType, false)

                    -- Play an impact effect, but only if not bouncing. Also stop Exps, because it just looks very silly.
                    if not self.Plane.Detector and not EntityCategoryContains(categories.EXPERIMENTAL, self.Plane) then
                        self.Plane:CreateDestructionEffects(self, self.OverKillRatio)
                    end

                    -- Update the unit's remaining crash damage
                    self.Plane.DeathCrashDamage = initialDamage - finalDamage
                end
            elseif targetType ~= 'Shield' then -- Don't go through here for non-bubble shield collisions
                self:Destroy()
            end
        end
    end,

    -- Lets do some maths that will make the units bounce off shields
    ShieldBounce = function(self, shield, vector)
        local bp = self.Plane.Blueprint
        local volume = bp.SizeX * bp.SizeY * bp.SizeZ -- We will use this to *guess* how much force to apply

        local spin = math.min (4 / volume, 2) -- Less for larger planes; also 2 is a nice number
        self:SetLocalAngularVelocity(spin, spin, spin) -- Ideally I would just set this to whatever the plane had but I dont know how

        local vx, vy, vz = self.Plane:GetVelocity() -- Current plane velocity
        local wx, wy, wz = vector.x, vector.y, vector.z

        -- Convert our speed values from units per tick to units per second
        vx = 10 * vx
        vy = 10 * vy
        vz = 10 * vz

        local speed = math.sqrt(vx * vx + vy * vy + vz * vz) -- The length of our vector
        local shieldMag = math.sqrt(wx * wx + wy * wy + wz * wz) -- The length of our other vector

        -- Normalizing all our shield vector, so we dont need to deal with scalar nonsense
        wx = wx / shieldMag
        wy = wy / shieldMag
        wz = wz / shieldMag

        -- Get our dot products going
        local dotProduct = vx * wx + vy * wy + vz * wz

        local ke = 0.5 * volume * speed * speed -- Our kinetic energy, used to scale the stoppingpower
        local stoppingPower = math.min(50 / (ke * 0.5), 2) -- 2 is a perfect bounce, 0 is unaffected velocity

        local angleCos = 10 * dotProduct / (speed * shieldMag) -- We take our unit vectors and calculate the angle. That 10 is to convert speed back to its "proper" length
        angleCos = math.clamp(-1, angleCos, 1)

        -- Well, almost - its incredibly inaccurate at angles close to 0, but it doesnt matter since this is mostly a visual thing
        -- Angle = atan2(norm(cross(a,b)),dot(a,b)) -- This is the "correct" way, but we dont use atan because its a pain in the ass in lua
        -- So we just clamp it to make sure its ok and no more worries

        local forceScalar = 1 - 0.65 * angleCos * (stoppingPower / 2) -- Bounciness coefficient, set to taste; 1.0 is a 'perfect' bounce
        -- The more direct the hit the lower it is, down to a minimum of 1-0.5
        -- StoppingPower also affects this, so the more ke we have, the less our velocity is changed, and so the less our coefficient is affected.

        -- Applying our bounce velocity
        vx = -stoppingPower * wx * dotProduct + vx
        vy = -stoppingPower * wy * dotProduct + vy
        vz = -stoppingPower * wz * dotProduct + vz

        -- Sometimes absurd values pop up, probably due to rounding errors or something, so we prevent huge speeds here
        vx = math.clamp(vx, -7, 7)
        vy = math.clamp(vy, -4, 4) -- Less for y so we dont get planes flying into space
        vz = math.clamp(vz, -7, 7)

        self:SetVelocity(forceScalar * vx, forceScalar * vy, forceScalar * vz)
    end,
}
TypeClass = ShieldCollider