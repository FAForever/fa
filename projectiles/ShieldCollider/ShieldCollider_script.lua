--------------------------------------------------------------------
-- File     :  /projectiles/ShieldCollider_script.lua
-- Author(s):  Exotic_Retard, made for Equilibrium Balance Mod
-- Summary  : Companion projectile enabling air units to hit shields
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------

local GetRandomFloat = import('/lua/utilities.lua').GetRandomFloat
local Projectile = import('/lua/sim/projectile.lua').Projectile

ShieldCollider = Class(Projectile) {
    OnCreate = function(self)
        Projectile.OnCreate(self)

        self:SetVizToFocusPlayer('Never') -- Set to always to see a nice box
        self:SetVizToAllies('Never')
        self:SetVizToNeutrals('Never')
        self:SetVizToEnemies('Never')
        self:SetStayUpright(false)
        self:SetCollision(true)
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

    -- Destroy the sinking unit when it hits the ground.
    OnImpact = function(self, targetType, targetEntity)
        if targetType == 'Terrain' then
            -- Here it should be noted that bone 0 IS NOT what the ground checks for, so if you have a projectile at that bone
            -- and the units centre is below it, then its below the ground and that can cause it to hit water instead.
            -- All this is just to prevent that, because falling planes are stupid.

            if self.GroundImpacted then
                WARN('ERROR: OnImpact has been called for a second time hitting the ground for a ShieldCollider proj. Investigate.')
            end

            self.GroundImpacted = true

            -- Get position of impact and ground height
            local pos = self:GetPosition()
            local groundLevel = GetTerrainHeight(pos[1], pos[3])

            -- Move attached plane to the surface at the impact point if it fell through
            pos[2] = groundLevel
            self:SetPosition(pos, true)
            self.Plane:SetPosition(pos, true) -- Make sure the plane is above ground if its not
            
            self:SetVelocity(0, 0, 0) -- The plane is attached to our projectile, so that stops too
            
            self.Plane:OnImpact('Terrain', true) -- Tell the plane we hit land
            self:Destroy()
        elseif targetType == 'Water' then
            self:DetachAll('anchor')
            self.Plane:OnImpact('Water', true) -- Tell the plane we hit water
            self:Destroy()
        elseif targetType == 'Shield' and targetEntity.ShieldType == 'Bubble' then
            if not self.ShieldImpacted then
                self.ShieldImpacted = true -- Only impact once

                if not EntityCategoryContains(categories.EXPERIMENTAL, self.Plane) then -- Exclude Experimentals from momentum system, but not damage
                    Warp(self, self.Plane:GetPosition(self.PlaneBone), self.Plane:GetOrientation())
                    self.Plane:AttachBoneTo(self.PlaneBone, self, 'anchor') -- We attach our bone at the very last moment when we need it

                    -- If you try to deattach the plane, it has retarded game code that makes it continue falling in its original direction
                    self:ShieldBounce(targetEntity) -- Calculate the appropriate change of velocity
                end

                if not self.Plane.deathWep or not self.Plane.DeathCrashDamage then -- Bail if stuff's missing.
                    WARN('ShieldCollider: did not find a deathWep on the plane! Is the weapon defined in the blueprint?')
                    return
                end

                local initialDamage = self.Plane.DeathCrashDamage
                local deathWep = self.Plane.deathWep

                local mult = deathWep.DeathCrashShieldMult or 0.2
                local damage = initialDamage * mult

                -- Damage the impact site (The shield mainly)
                DamageArea(self, self:GetPosition(), deathWep.DamageRadius, damage, deathWep.DamageType, deathWep.DamageFriendly)

                -- Update the unit's remaining crash damage
                self.Plane.DeathCrashDamage = initialDamage - damage
            end
        elseif targetType ~= 'Shield' then -- Don't go through here for non-bubble shield collisions
            self:Destroy()
        end
    end,

    -- Lets do some maths that will make the units bounce off shields
    ShieldBounce = function(self, shield)
        local bp = self.Plane:GetBlueprint()
        local volume = bp.SizeX * bp.SizeY * bp.SizeZ -- We will use this to *guess* how much force to apply

        local spin = math.min (4 / volume, 2) -- Less for larger planes; also 2 is a nice number
        self:SetLocalAngularVelocity(spin, spin, spin) -- Ideally I would just set this to whatever the plane had but I dont know how

        local vx, vy, vz = self.Plane:GetVelocity() -- Current plane velocity
        local wx, wy, wz = unpack(VDiff(shield:GetPosition(), self:GetPosition())) -- Vector from mid of shield to impact point

        -- Convert our speed values from units per tick to units per second
        vx = 10 * vx 
        vy = 10 * vy
        vz = 10 * vz

        local speed = math.sqrt(vx * vx + vy * vy + vz * vz) -- The length of our vector
        local shieldMag = math.sqrt(wx * wx + wy * vy + wz * wz) -- The length of our other vector

        -- Normalizing all our shield vector, so we dont need to deal with scalar nonsense
        wx = wx / shieldMag
        wy = wy / shieldMag
        wz = wz / shieldMag

        -- Get our dot products going
        local dotProduct = vx * wx + vy * wy + vz * wz

        local ke = 0.5 * volume * speed * speed -- Our kinetic energy, used to scale the stoppingpower
        local stoppingPower = math.min(80 / ke, 2) -- 2 is a perfect bounce, 0 is unaffected velocity

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
        vx = math.clamp(-7, vx, 7)
        vy = math.clamp(-4, vy, 4) -- Less for y so we dont get planes flying into space
        vz = math.clamp(-7, vz, 7)

        self:SetVelocity(forceScalar * vx, forceScalar * vy, forceScalar * vz)
    end,
}

TypeClass = ShieldCollider
