---@meta

---@class moho.projectile_methods : moho.entity_methods
local Projectile = {}

---@return ProjectileBlueprint
function Projectile:GetBlueprint()
end

--- Change the detonate above height for the projectile, relative to the terrain
---
--- Note: does **not** support chained calls
---@param height number
function Projectile:ChangeDetonateAboveHeight(height)
end

--- Change the detonate below height for the projectile, relative to the terrain
---
--- Note: does **not** support chained calls
---@param height number
function Projectile:ChangeDetonateBelowHeight(height)
end

--- Change the amount of zig-zag in degrees per second
---
--- You can use `Projectile:GetMaxZigZag()` to retrieve the current zig zag distance.
--- Note: does **not** support chained calls
---@param max number
function Projectile:ChangeMaxZigZag(max)
end

--- Change the frequency of the zig-zag
---
--- You can use `Projectile:GetZigZagFrequency()` to retrieve the current zig zag frequency.
--- Note: does **not** support chained calls
---@param freq number
function Projectile:ChangeZigZagFrequency(freq)
end

--- Creates a child projectile that inherits the speed and orientation of its parent
---@param blueprint BlueprintId
---@return Projectile
function Projectile:CreateChildProjectile(blueprint)
end

--- Returns the speed over ticks instead of over seconds. Multiply by 10 to get the (usually) expected speed value
---@return number
function Projectile:GetCurrentSpeed()
end

--- Returns the position of the current target.
---@return Vector
function Projectile:GetCurrentTargetPosition()
end

--- Returns the position of the current target as separate coordinates.
---@return number   # x
---@return number   # y
---@return number   # z
function Projectile:GetCurrentTargetPositionXYZ()
end

--- Returns the zig zag frequency.
---
--- You can use `Projectile:ChangeMaxZigZag(value)` to change the zig zag frequency.
---@return number
function Projectile:GetZigZagFrequency()
end

--- Returns the zig zag distance.
---
--- You can use `Projectile:ChangeMaxZigZag(value)` to change the zig zag distance.
---@return number
function Projectile:GetMaxZigZag()
end

--- Returns the entity that is responsible for creating this projectile.
---@return Entity | Unit | nil
function Projectile:GetLauncher()
end

--- Returns the target that we're tracking.
---@return Entity | Unit | nil
function Projectile:GetTrackingTarget()
end

--- Returns the speed over ticks instead of over seconds. Multiply by 10 to get the (usually) expected speed value
---@return number
---@return number
---@return number
function Projectile:GetVelocity()
end

--- Override the acceleration value in the blueprint.
---@generic T
---@param self T
---@param accel number
---@return T
function Projectile:SetAcceleration(accel)
end

--- Set the vertical (gravitational) acceleration of the projectile. Default is -4.9, which is expected by the engine's weapon targeting and firing
---@generic T
---@param self T
---@param accel number
---@return T
function Projectile:SetBallisticAcceleration(accel)
end

--- Whether or not this projecile collides with units and shields, should not be used for dummy projectiles as this is expensive
---@generic T
---@param self T
---@param collide boolean
---@return T
function Projectile:SetCollideEntity(collide)
end

--- Whether or not this projectile collides with the terrain and water surface
---@generic T
---@param self T
---@param collide boolean
---@return T
function Projectile:SetCollideSurface(collide)
end

---@generic T
---@param self T
---@param collide boolean
---@return Projectile
---@return T
function Projectile:SetCollision(collide)
end

--- Note: does **not** support chained calls
---@param flag boolean
function Projectile:SetDestroyOnWater(flag)
end

---@generic T
---@param self T
---@param seconds number
---@return T
function Projectile:SetLifetime(seconds)
end

---@generic T
---@param self T
---@param x number
---@param y number
---@param z number
---@return T
function Projectile:SetLocalAngularVelocity(x, y, z)
end

---@generic T
---@param self T
---@param speed number
---@return T
function Projectile:SetMaxSpeed(speed)
end

--- Note: does **not** support chained calls
---@param object Blip | Entity | Unit | Projectile
function Projectile:SetNewTarget(object)
end

--- Note: does **not** support chained calls
---@param location Vector
function Projectile:SetNewTargetGround(location)
end

--- Note: does **not** support chained calls
---@param x number
---@param y number
---@param z number
function Projectile:SetNewTargetGroundXYZ(x, y, z)
end

---@generic T
---@param self T
---@param svx number
---@param svy number
---@param svz number
---@return T
function Projectile:SetScaleVelocity(svx, svy, svz)
end

--- Note: does **not** support chained calls
---@param upright boolean
function Projectile:SetStayUpright(upright)
end

---@generic T
---@param self T
---@param degreesPerSecond number
---@return T
function Projectile:SetTurnRate(degreesPerSecond)
end

---@generic T
---@param self T
---@param velX number
---@param velY? number
---@param velZ? number
---@return T
function Projectile:SetVelocity(velX, velY, velZ)
end

--- Note: does **not** support chained calls
---@param align boolean
function Projectile:SetVelocityAlign(align)
end

--- Note: does **not** support chained calls
---@unknown
function Projectile:SetVelocityRandomUpVector()
end

---@generic T
---@param self T
---@param stay boolean
---@return T
function Projectile:StayUnderwater(stay)
end

---@generic T
---@param self T
---@param track boolean
---@return T
function Projectile:TrackTarget(track)
end

--- Unused, damage is passed by the weapon via the damage table
---@deprecated
---@param amount number | nil
---@param radius number | nil
function Projectile:SetDamage(amount, radius)
end

return Projectile
