---@meta

---@class moho.entity_methods : Destroyable
local Entity = {}

---@alias EntityId string

---@class CollisionExtents
---@field Max Vector
---@field Min Vector


--- Attaches a manual scroller to an entity, animating the bottom sections of its textures.
--- Only one texture scroller may be active at a time (the others being a tread scroller or
--- ping-ping scroller).
---@param scrollSpeed1 number
---@param scrollSpeed2 number
function Entity:AddManualScroller(scrollSpeed1, scrollSpeed2)
end

--- Attaches a ping-pong scroller to an entity, animating the bottom sections of its textures.
--- Only one texture scroller may be active at a time (the others being a tread scroller or
--- manual scroller).
---@param ping1 any
---@param pingSpeed1 any
---@param pong1 any
---@param pongSpeed1 any
---@param ping2 any
---@param pingSpeed2 any
---@param pong2 any
---@param pongSpeed2 any
function Entity:AddPingPongScroller(ping1, pingSpeed1, pong1, pongSpeed1, ping2, pingSpeed2, pong2, pongSpeed2)
end

---@unknown
---@param shooter any
function Entity:AddShooter(shooter)
end

--- Attaches a tread scroller to an entity, animating the bottom sections of its textures.
--- Only one texture scroller may be active at a time (the others being a ping-pong scroller or
--- manual scroller). "Thread" is an engine typo and should have been "Tread".
---@param sideDist number
---@param scrollMult number
function Entity:AddThreadScroller(sideDist, scrollMult)
end

---@unknown
---@param Ix number
---@param Iy number
---@param Iz number
---@param Px number
---@param Py number
---@param Pz number
function Entity:AddWorldImpulse(Ix, Iy, Iz, Px, Py, Pz)
end

--- Adjusts the health of the entity, with credits to the instigator
---@param instigator Unit
---@param delta number
function Entity:AdjustHealth(instigator, delta)
end

--- Attaches this entity to another entity, matching the bone position of `selfBone` and `bone`
---@param selfbone Bone
---@param entity moho.entity_methods
---@param bone Bone
function Entity:AttachBoneTo(selfbone, entity, bone)
end

--- Attaches a bone on this entity's mesh to another entity's bone.
--- This does not move either entity.
---@param selfBone Bone
---@param other moho.entity_methods
---@param otherBone Bone
---@param flag any unknown usage, always `false`
function Entity:AttachBoneToEntityBone(selfBone, other, otherBone, flag)
end

--- Attaches this entity to another entity at a bone position on it
---@param entity moho.entity_methods
---@param bone Bone
function Entity:AttachTo(entity, bone)
end


--- Returns whether the engine-side C object of this entity has been destroyed
---@see IsDestroyed(entity) as an alternative
---@return boolean
function Entity:BeenDestroyed()
end

--- Creates a projectile at the position of the entity (offset from its center) such that
--- `projectile:GetLauncher()` returns the entity. If one offset or direction value is non-nil,
--- all three in the triplet must also be.
---@param projectileBp FileName
---@param offX number?
---@param offY number?
---@param offZ number?
---@param dirX number?
---@param dirY number?
---@param dirZ number?
---@return Projectile
function Entity:CreateProjectile(projectileBp, offX, offY, offZ, dirX, dirY, dirZ)
end

--- Creates a projectile at a bone matching its orientation such that `projectile:GetLauncher()`
--- returns the entity
---@param projectileBp FileName
---@param bone Bone
---@return Projectile
function Entity:CreateProjectileAtBone(projectileBp, bone)
end

--- Creates a prop at a bone matching its orientaiton. Used by tree groups when they split.
---@param bone Bone
---@param propid string
---@return Prop
function Entity:CreatePropAtBone(bone, propid)
end

--- Destroys the entity, de-allocating the engine-side C object
function Entity:Destroy()
end

--- Detaches all entities attached to the given bone from it
---@param bone Bone
---@param skipBallistic? boolean
function Entity:DetachAll(bone, skipBallistic)
end

--- Detaches all entities attached to this entity from it
---@param skipBallistic? boolean
function Entity:DetachFrom(skipBallistic)
end

--- Disables an intel type for this entity.
--- Throws an error if the intel type has not been initialized.
---@param type IntelType
function Entity:DisableIntel(type)
end

--- Enable an intel type for this entity.
--- Throws an error if the intel type has not been initialized.
---@param type IntelType
function Entity:EnableIntel(type)
end

--- Creates a MotorFallDown object that can be used to whack the entity about.
--- Used for falling trees.
---@return moho.MotorFallDown
function Entity:FallDown()
end

---@return AIBrain
function Entity:GetAIBrain()
end

--- Returns the army that is associated with this entity, as set by the `Army` value in the
--- specification it was constructed with
---@return Army
function Entity:GetArmy()
end

---@return EntityBlueprint
function Entity:GetBlueprint()
end

--- Returns the total number of bones, excluding the `-2` and `-1` pseudobones
---@return number
function Entity:GetBoneCount()
end

--- Returns separate three numbers representing the roll, pitch, yaw of the bone
---@see EulerToQuaternion(roll, pitch, yaw) if you need a quaternion instead
---@param bone Bone
---@return number roll
---@return number pitch
---@return number yaw
function Entity:GetBoneDirection(bone)
end

--- Converts the bone index (counting from 0) to the bone name, as defined in the mesh
---@param index number
---@return string
function Entity:GetBoneName(index)
end

---@return CollisionExtents
function Entity:GetCollisionExtents()
end

--- Returns the unique entity id as set by the engine.
--- Note that these are recycled as the game progresses.
---@return EntityId
function Entity:GetEntityId()
end

--- Returns a number `0.0` to `1.0`, where 0 is unbuilt and 1 is completely built
---@return number
function Entity:GetFractionComplete()
end

--- Returns the heading on the XZ plane, where `0` is *south* going *counter-clockwise*.
--- Note that both of these properties are opposite to the common notion of a heading,
--- and doesn't work mathematically in trigonometric functions.
---@return number
function Entity:GetHeading()
end

--- Returns the amount of health this entity has
---@see entity:GetMaxHealth() for the maximum possible health
---@return number
function Entity:GetHealth()
end

--- Returns the radius for a given intel type on the entity.
--- Throws an error if the intel type has not been initialized.
---@param type IntelType
---@return number | nil
function Entity:GetIntelRadius(type)
end

--- Returns the maximum amount of health this entity can have. Note that this may not be the same
--- value as the original one in the entity's blueprint.
---@see entity:GetHealth() for the current amount of health
---@return number
function Entity:GetMaxHealth()
end

--- Returns the orientation of this entity in 3D space as a quaternion (an array of 4 numbers)
---@return Quaternion
function Entity:GetOrientation()
end

--- Returns the parent entity (e.g. the transport a unit is on), or nil if none
---@return moho.entity_methods | nil
function Entity:GetParent()
end

--- Returns the position of the entity at a given bone as a vector table that is reused on each
--- call. Writing to this table will not change the position of the entity.
---@param bone? Bone defaults to the center bone
---@return Vector
function Entity:GetPosition(bone)
end

--- Returns the position of the entity at a given bone as three separate numbers
---@param bone? Bone defaults to the center bone
---@return number x
---@return number y
---@return number z
function Entity:GetPositionXYZ(bone)
end

--- Returns the draw scale of the mesh of the entity. Note that this does not work for units.
---@return number sx
---@return number sy
---@return number sz
function Entity:GetScale()
end

--- Initializes the entity to provide intelligence of a partiuclar type for an army.
--- This lets the other intel methods work with this entity for that type of intel.
---@param army Army
---@param type IntelType
---@param radius? number
function Entity:InitIntel(army, type, radius)
end

--- Returns if the intel type is currently enabled on the unit.
---@param type IntelType
---@return boolean
function Entity:IsIntelEnabled(type)
end

--- Returns whether the bone is a valid bone for the entity
---@param bone Bone | nil
---@param allowNil? boolean if nil should be considered a valid bone, defaults to `false`
---@return boolean
function Entity:IsValidBone(bone, allowNil)
end

---@param instigator? Unit
---@param damageType? DamageType
---@param excessDamageRatio? number
function Entity:Kill(instigator, damageType, excessDamageRatio)
end

--- Plays a sound at the location of the entity
---@param params SoundHandle
function Entity:PlaySound(params)
end

---@unknown
---@param nx number
---@param ny number
---@param nz number
---@param depth number
function Entity:PushOver(nx, ny, nz, depth)
end

---@unknown
---@return boolean
function Entity:ReachedMaxShooters()
end

--- Removes the texture scroller from the entity, if any
function Entity:RemoveScroller()
end

---@unknown
---@param shooter moho.entity_methods
function Entity:RemoveShooter(shooter)
end

function Entity:RequestRefreshUI()
end

--- Sets an audio cue to loop at the entity's position
---@param paramTableDetail SoundHandle | nil
---@param paramTableRumble any unknown usage, always `nil`
function Entity:SetAmbientSound(paramTableDetail, paramTableRumble)
end

---@overload fun(self: moho.entity_methods, type: "None")
---@overload fun(self: moho.entity_methods, type: "Sphere", centerX: number, centerY: number, centerZ: number, radius: number)
---@overload fun(self: moho.entity_methods, type: "Box", centerX: number, centerY: number, centerZ: number, sizeX: number, sizeY: number, sizeZ: number)
--- Defines the collision shape of the entity.
--- Should not be used excessively due to its performance impact
---@param type CollisionShape
---@param centerX? number
---@param centerY? number
---@param centerZ? number
---@param sizeX? number
---@param sizeY? number
---@param sizeZ? number
function Entity:SetCollisionShape(type, centerX, centerY, centerZ, sizeX, sizeY, sizeZ)
end

--- Changes the mesh scale of the entity on the fly
---@param size number
function Entity:SetDrawScale(size)
end

---@param instigator? moho.entity_methods
---@param health number
function Entity:SetHealth(instigator, health)
end

--- Sets the radius on the entity of an intel type.
--- Throws an error if the intel type has not been initialized.
---@param type IntelType
---@param radius number
function Entity:SetIntelRadius(type, radius)
end

--- Sets the maximum health the entity can have. Does not change its actual health, except
--- when clamping it to the new max health.
---@param maxhealth number
function Entity:SetMaxHealth(maxhealth)
end

--- Changes the mesh of the entity
---@param meshBp FileName
---@param keepActor? boolean if set, all manipulators are kept attached
function Entity:SetMesh(meshBp, keepActor)
end

--- Defines the orientation of the entity
---@see entity:SetPosition(vector, immediate) for setting the position
---@param orientation Quaternion
---@param immediately boolean
function Entity:SetOrientation(orientation, immediately)
end

---@param vector Vector
function Entity:SetParentOffset(vector)
end

---@see entity:SetOrientation(vector, immediate) for setting the orientation
---@param vector Vector
---@param immediate? boolean
function Entity:SetPosition(vector, immediate)
end

---@overload fun(self: moho.entity_methods, size: number)
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

--- Shake the camera. This is a method of entities rather than a global function because it takes
--- the position of the entity as the epicenter where it shakes more.
---@param radius number distance from epicenter at which shaking falls off to `min`
---@param max number size of shaking in world units, when looking at epicenter
---@param min number size of shaking in world units, when at `radius` distance or farther
---@param duration number in seconds
function Entity:ShakeCamera(radius, max, min, duration)
end

--- Sets the entity's y position to change by an amount, allowing clipping into the ground
---@param dy number
function Entity:SinkAway(dy)
end

return Entity
