---@declare-global
---@class moho.projectile_methods : moho.entity_methods
local Projectile = {}

--- Change the detonate above height for the projectile
---@param height number
function Projectile:ChangeDetonateAboveHeight(height)
end

--- Change the detonate below height for the projectile
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

--- Internally calls `import` to find the projectile
---@param blueprint ProjectileBlueprint
---@return Projectile
function Projectile:CreateChildProjectile(blueprint)
end

---
---@return number
function Projectile:GetCurrentSpeed()
end

---
---@return Position
function Projectile:GetCurrentTargetPosition()
end

--- Get who launched this projectile
---@return Entity | Unit
function Projectile:GetLauncher()
end

---
---@return Entity | Unit
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

---
---@param collide boolean
function Projectile:SetCollideEntity(collide)
end

---
---@param collide boolean
function Projectile:SetCollideSurface(collide)
end

---
---@param collide boolean
function Projectile:SetCollision(collide)
end

--- Change how much damage this projectile will do. Either amount or radius can be nil to leave unchanged.
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
---@param object Entity | Unit
function Projectile:SetNewTarget(object)
end

---
---@param location Position
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
---@param radiansPerSecond number
function Projectile:SetTurnRate(radiansPerSecond)
end

---
---@param velX number
---@param velY number
---@param velZ number
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
