--- Class Projectile
-- @classmod Sim.Projectile


--- Change the detonate below height for the projectile. Edits the Blueprint.Physics.DetonateBelowHeight value on a per-projectile basis.
-- @param height The height to detonate when below
function Projectile:ChangeDetonateBelowHeight(height)
end

--- Change the amount of zig zag in degrees per second. Edits the Blueprint.Physics.MaxZigZag value on a per-projectile basis.
-- @param maximum The maximum zig zag we accept in degrees per second.
function Projectile:ChangeMaxZigZag(maximum)
end

--- Change the frequency of the zig zag --> min "0" (0 %), 0.5 (50%), max "1.0" (100%). Edits the Blueprint.Physics.ZigZagFrequency value on a per-projectile basis.
-- @param The new frequency of the zig zagging.
function Projectile:ChangeZigZagFrequency(frequency)
end

---
--  Projectile:CreateChildProjectile(blueprint)
function Projectile:CreateChildProjectile(blueprint)
end

---
--  Projectile:GetCurrentSpeed() -> val
function Projectile:GetCurrentSpeed()
end

---
--  Projectile:GetCurrentTargetPosition()
function Projectile:GetCurrentTargetPosition()
end

---
--  Get who launched this projectile
function Projectile:GetLauncher()
end

---
--  Projectile:GetTrackingTarget()
function Projectile:GetTrackingTarget()
end

---
--  Projectile:GetVelocity() -> x,y,z
function Projectile:GetVelocity()
end

---
--  Projectile:SetAcceleration(accel)
function Projectile:SetAcceleration(accel)
end

---
--  Wrong number of arguments to Projectile:SetAccelerationVector(), expected 1, 2, or 4 but got %d
function Projectile:SetBallisticAcceleration(accel)
end

---
--  Projectile:SetCollideEntity(onoff)
function Projectile:SetCollideEntity(onoff)
end

---
--  Projectile:SetCollideSurface(onoff)
function Projectile:SetCollideSurface(onoff)
end

---
--  Projectile:SetCollision(onoff)
function Projectile:SetCollision(onoff)
end

---
--  Projectile:SetDamage(amount, radius) -- change how much damage this projectile will do. Either amount or radius can be nil to leave unchanged.
function Projectile:SetDamage(amount,  radius)
end

---
--  Projectile:SetDestroyOnWater(flag)
function Projectile:SetDestroyOnWater(flag)
end

---
--  Projectile:SetLifetime(seconds)
function Projectile:SetLifetime(seconds)
end

---
--  Projectile:SetLocalAngularVelocity(x,y,z)
function Projectile:SetLocalAngularVelocity(x, y, z)
end

---
--  Projectile:SetMaxSpeed(speed)
function Projectile:SetMaxSpeed(speed)
end

---
--  Projectile:SetNewTarget(entity)
function Projectile:SetNewTarget(entity)
end

---
--  Projectile:SetNewTargetGround(location)
function Projectile:SetNewTargetGround(location)
end

---
--  Projectile:SetScaleVelocity(vs) or Projectile:SetScaleVelocity(vsx, vsy, vsz)
function Projectile:SetScaleVelocity(vs)
end

---
--  Projectile:SetStayUpright(truefalse)
function Projectile:SetStayUpright(truefalse)
end

---
--  Projectile:SetTurnRate(radians_per_second)
function Projectile:SetTurnRate(radians_per_second)
end

---
--  Projectile:SetVelocity(speed) or Projectile:SetVelocity(vx,vy,vz)
function Projectile:SetVelocity(speed)
end

---
--  Projectile:SetVelocityAlign(truefalse)
function Projectile:SetVelocityAlign(truefalse)
end

---
--  SetVelocityRandomUpVector(self)
function Projectile:SetVelocityRandomUpVector(self)
end

---
--  Projectile:StayUnderwater(onoff)
function Projectile:StayUnderwater(onoff)
end

---
--  Projectile:TrackTarget(onoff)
function Projectile:TrackTarget(onoff)
end

---
--  derived from Entity
function Projectile:base()
end

---
--
function Projectile:moho.projectile_methods()
end