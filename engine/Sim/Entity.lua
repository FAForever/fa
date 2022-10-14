---@meta

---@class moho.entity_methods : Destroyable
local Entity = {}

---@alias EntityId number


--- Does not appear to be used
---@unknown
---@param scrollSpeed1 number
---@param scrollSpeed2 number
function Entity:AddManualScroller(scrollSpeed1, scrollSpeed2)
end

---
--  Entity:AddPingPongScroller(ping1, pingSpeed1, pong1, pongSpeed1, ping2, pingSpeed2, pong2, pongSpeed2)
function Entity:AddPingPongScroller(ping1, pingSpeed1, pong1, pongSpeed1, ping2, pingSpeed2, pong2, pongSpeed2)
end

--- Does not appear to be used
---@unknown
---@param shooter any
function Entity:AddShooter(shooter)
end

--- Attaches a thread scroller to an entity, animating the bottom section of their textures / UVs
---@param sideDist number
---@param scrollMult number
function Entity:AddThreadScroller(sideDist, scrollMult)
end

---
--  AddWorldImpulse(self, Ix, Iy, Iz, Px, Py, Pz) Note: Does not appear to be functional.
function Entity:AddWorldImpulse(Ix, Iy, Iz, Px, Py, Pz)
end

--- Adjusts the health of the entity, with credits to the instigator
---@param instigator Unit
---@param delta number
function Entity:AdjustHealth(instigator, delta)
end

--- Attaches this entity to another entity, matching the bone position of `selfBone` and `bone` accordingly
---@param selfbone Bone
---@param entity Entity
---@param bone Bone
function Entity:AttachBoneTo(selfbone, entity, bone)
end

---
--  Attach a unit bone position to an entity bone position
function Entity:AttachBoneToEntityBone(selfBone, other, otherBone, flag)
end

---
--  Entity:AttachTo(entity, bone)
function Entity:AttachTo(entity,  bone)
end


--- Returns whether the C-side of this entity has been destroyed
---@see # As an alternative: `IsDestroyed(entity)`
function Entity:BeenDestroyed()
end

--- Creates a projectile at the position of the entity such that `projectile:GetLauncher()` returns the entity
---@param projectileid string
---@param ox number? X coordinate of the offset
---@param oy number? Y coordinate of the offset
---@param oz number? Z coordinate of the offset
---@param dx number? X direction of the projectile
---@param dy number? Y direction of the projectile
---@param dz number? Z direction of the projectile
---@return Projectile
function Entity:CreateProjectile(projectileid, ox, oy, oz, dx, dy, dz)
end

--- Creates a projectile at a bone matching the orientation of the bone such that `projectile:GetLauncher()` returns the entity
---@param projectile_blueprint string
---@param bone Bone
---@return Projectile
function Entity:CreateProjectileAtBone(projectile_blueprint, bone)
end

--- Creates a prop at a bone matching the orientation of the bone, used by tree groups when they break
---@param bone Bone
---@param propid string
---@return Prop
function Entity:CreatePropAtBone(bone, propid)
end

--- Destroys the entity, de-allocating the c-side
function Entity:Destroy()
end

--- Detaches all entities attached to the given bone
---@param bone Bone
---@param skipBallistic? boolean
function Entity:DetachAll(bone, skipBallistic)
end

--- Detaches all entities attached to this entity
---@param skipBallistic? boolean
function Entity:DetachFrom(skipBallistic)
end

---
--  Intel:DisableIntel(type)
function Entity:DisableIntel(type)
end

---
--  EnableIntel(type)
function Entity:EnableIntel(type)
end

---@param dx any
---@param dy any
---@param dz any
---@param force any
---@return moho.MotorFallDown
function Entity:FallDown(dx, dy, dz, force)
end

---
--  GetAIBrain(self)
function Entity:GetAIBrain()
end

--- Returns the army that is associated with this entity, as set by the value `Army` in its specification
---@return Army
function Entity:GetArmy()
end

---
--  blueprint = Entity:GetBlueprint()
function Entity:GetBlueprint()
end

--- Returns the total number of bones, excluding -2 and -1.
---@return number
function Entity:GetBoneCount()
end

--- Returns separate three numbers representing the roll, pitch, yaw of the bone
---@see EulerToQuaternion if you need a Quaternion instead
---@param bone Bone
---@return number
---@return number
---@return number
function Entity:GetBoneDirection(bone)
end
--- Converts the bone index to the bone name, as set in the mesh
---@param i any
---@return string
function Entity:GetBoneName(i)
end

---
--  Entity:GetCollisionExtents()
function Entity:GetCollisionExtents()
end

--- Returns the unique entity id as set by the engine, note that these are recycled as the game progresses
---@return EntityId
function Entity:GetEntityId()
end

--- Returns a number between 0 and 1, where 0 is unbuilt and 1 is completely built
---@return number
function Entity:GetFractionComplete()
end

--- Returns the heading on the XZ plane, where south is 0 and moving counter clock wise (just like the unit circle)
---@return number
function Entity:GetHeading()
end

--- Returns the amount of health this entity has
---@see For the maximum possible health, use `entity:GetMaxHealth()` instead
---@return number
function Entity:GetHealth()
end

---
--  GetIntelRadius(type)
function Entity:GetIntelRadius(type)
end

--- Returns the maximum amount of health this entity can have
---@see For the current amount of health, use `entity:GetHealth()` instead
---@return number
function Entity:GetMaxHealth()
end

--- Returns the orientation of this entity as a quaternion
---@return Quaternion
function Entity:GetOrientation()
end

---
--  Entity:GetParent()
function Entity:GetParent()
end

--- Returns the position of the entity at a given bone (or its center bone if absent) as a table that is re-used on each call
---@param bone? Bone
---@return Vector
function Entity:GetPosition(bone)
end

--- Returns the position of the entity at a given bone (or its center bone if absent) as three separate numbers
---@param bone? Bone
---@return number X
---@return number Y
---@return number Z
function Entity:GetPositionXYZ(bone)
end

--- Returns the draw scale of the mesh of the entity, note that this functionality does not work on units
---@param sx number
---@param sy number
---@param sz number
function Entity:GetScale(sx, sy, sz)
end

---
--  InitIntel(army,type,<radius>)
function Entity:InitIntel(army, type, radius)
end

---
--  IsIntelEnabled(type)
function Entity:IsIntelEnabled(type)
end

---
--  Entity:IsValidBone(nameOrIndex,allowNil=false)

--- Returns whether the bone is a valid bone for the entity
---@param bone Bone
---@param allowNil boolean Flag that to consider nil a valid bone, defaults to false
---@return boolean
function Entity:IsValidBone(bone, allowNil)
end

---
---@param instigator? Unit
---@param damageType? DamageType
---@param excessDamageRatio? number
function Entity:Kill(instigator, damageType, excessDamageRatio)
end

---
--  Entity:PlaySound(params)
function Entity:PlaySound(params)
end

---
--  Entity:PushOver(nx, ny, nz, depth)
function Entity:PushOver(nx, ny, nz, depth)
end

---
--  ReachedMaxShooters()
function Entity:ReachedMaxShooters()
end

---
--  Entity:RemoveScroller()
function Entity:RemoveScroller()
end

---
--  RemoveShooter(shooter)
function Entity:RemoveShooter(shooter)
end

---
--  Entity:RequestRefreshUI()
function Entity:RequestRefreshUI()
end

---
--  Entity:SetAmbientSound(paramTableDetail,paramTableRumble)
function Entity:SetAmbientSound(paramTableDetail, paramTableRumble)
end

--- Defines the collision shape of the entity. Should not be used excessively due to its performance impact
---@param type CollisionShape
---@param centerX number
---@param Y number
---@param Z number
---@param size number
function Entity:SetCollisionShape(type, centerX, Y, Z, size)
end

---
--  Entity:SetDrawScale(size): Change mesh scale on the fly
function Entity:SetDrawScale(size)
end

---
--  Entity:SetHealth(instigator,health)
function Entity:SetHealth(instigator, health)
end


function Entity:SetIntelRadius(type, radius)
end

---
---@param maxhealth number
function Entity:SetMaxHealth(maxhealth)
end

--- Change the mesh of the entity
---@param meshBp string
---@param keepActor boolean if set, keep all manipulators attached
function Entity:SetMesh(meshBp, keepActor)
end

--- Defines the orientation of the entity
---@see `entity:SetPosition` for the position of the entity
---@param orientation Quaternion
---@param immediately boolean defaults to false
function Entity:SetOrientation(orientation, immediately)
end

---
--  Entity:SetParentOffset(vector)
function Entity:SetParentOffset(vector)
end

---@see `entity:SetOrientation` for the orientation of the entity
---@param vector Vector
---@param immediate boolean defaults to false
function Entity:SetPosition(vector, immediate)
end

--- Defines the draw scale of the mesh of the entity, note that this functionality does not work on units
---@param sx number
---@param sy number
---@param sz number
function Entity:SetScale(sx, sy, sz)
end

--- Defines when allied armies to this entity gain vision of (the mesh of) this entity
---@param type VisionMode
function Entity:SetVizToAllies(type)
end

--- Defines when hostile armies to this entity gain vision of (the mesh of) this entity
---@param type VisionMode
function Entity:SetVizToEnemies(type)
end

--- Defines when the focus army of this entity gaisn vision of (the mesh of) this entity
---@param type VisionMode
function Entity:SetVizToFocusPlayer(type)
end

--- Defines when neutral armies to this entity gain vision of (the mesh of) this entity
---@param type VisionMode
function Entity:SetVizToNeutrals(type)
end

--- Shakes the camera, depending on its distance to the entity
---@param radius number
---@param max number
---@param min number
---@param duration number
function Entity:ShakeCamera(radius, max, min, duration)
end

--- Sink into the ground
function Entity:SinkAway(vy)
end

return Entity
