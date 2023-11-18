---@meta

---@class moho.projectile_methods : moho.entity_methods
local Projectile = {}

---@return ProjectileBlueprint
function Projectile:GetBlueprint()
end

--- Change the detonate above height for the projectile, relative to the terrain
---@param height number
function Projectile:ChangeDetonateAboveHeight(height)
end

--- Change the detonate below height for the projectile, relative to the terrain
---@param height number
function Projectile:ChangeDetonateBelowHeight(height)
end

--- Change the amount of zig-zag in degrees per second
---@param max number
function Projectile:ChangeMaxZigZag(max)
end

--- Change the frequency of the zig-zag
---@param freq number
function Projectile:ChangeZigZagFrequency(freq)
end

--- Creates a child projectile that inherits the speed and orientation of its parent
---@param blueprint BlueprintId
---@return Projectile
function Projectile:CreateChildProjectile(blueprint)
end

---
---@return number
function Projectile:GetCurrentSpeed()
end

---
---@return Vector
function Projectile:GetCurrentTargetPosition()
end

--- Get who launched this projectile
---@return Entity | Unit | nil
function Projectile:GetLauncher()
end

---
---@return Entity | Unit | nil
function Projectile:GetTrackingTarget()
end

---
---@return Vector
function Projectile:GetVelocity()
end

---
---@param accel number
function Projectile:SetAcceleration(accel)
end

--- 
---@param accel number
function Projectile:SetBallisticAcceleration(accel)
end

--- Whether or not this projecile collides with units and shields, should not be used for dummy projectiles as this is expensive
---@param collide boolean
function Projectile:SetCollideEntity(collide)
end

--- Whether or not this projectile collides with the terrain and water surface
---@param collide boolean
function Projectile:SetCollideSurface(collide)
end

---
---@param collide boolean
function Projectile:SetCollision(collide)
end

--- Unused, damage is passed by the weapon via the damage table
---@deprecated
---@param amount number | nil
---@param radius number | nil
function Projectile:SetDamage(amount, radius)
end

---
---@param flag boolean
function Projectile:SetDestroyOnWater(flag)
end

---
---@param seconds number
function Projectile:SetLifetime(seconds)
end

---
---@param x number
---@param y number
---@param z number
function Projectile:SetLocalAngularVelocity(x, y, z)
end

---
---@param speed number
function Projectile:SetMaxSpeed(speed)
end

---
---@param object Blip | Entity | Unit | Projectile
function Projectile:SetNewTarget(object)
end

---
---@param location Vector
function Projectile:SetNewTargetGround(location)
end

---
---@param svx number
---@param svy number
---@param svz number
function Projectile:SetScaleVelocity(svx, svy, svz)
end

---
---@param upright boolean
function Projectile:SetStayUpright(upright)
end

---
---@param degreesPerSecond number
function Projectile:SetTurnRate(degreesPerSecond)
end

---
---@param velX number
---@param velY? number
---@param velZ? number
function Projectile:SetVelocity(velX, velY, velZ)
end

---
---@param align boolean
function Projectile:SetVelocityAlign(align)
end

---@unknown
function Projectile:SetVelocityRandomUpVector()
end

---
---@param stay boolean
function Projectile:StayUnderwater(stay)
end

---
---@param track boolean
function Projectile:TrackTarget(track)
end

return Projectile
