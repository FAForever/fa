---@meta

---@class moho.entity_methods : Destroyable
local Entity = {}

---@alias EntityId string

---@class CollisionExtents
---@field Max Vector
---@field Min Vector


--- Applies an impulse to the entity's physics body, like `AddWorldImpulse`, but with the impulse and the point in the
--- entity's own frame
---@see moho.entity_methods.AddWorldImpulse # World space variant, and what reads the physics body
---@param Ix number
---@param Iy number
---@param Iz number
---@param Px number
---@param Py number
---@param Pz number
function Entity:AddLocalImpulse(Ix, Iy, Iz, Px, Py, Pz)
end

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

--- Applies the impulse `I` at the point `P`, both in world space, to the entity's physics body. Adds `I` divided by the mass
--- to the body's velocity, and the cross product of `P` minus the body's center with `I` to its angular momentum, so a point
--- off the center also spins the body. Only mobile units have a physics body, created with their movement. On structures,
--- props, projectiles and plain Lua entities, it does nothing.
--- Only the flight of air units reads the body's velocity, so the impulse pushes and spins flying air units until their
--- flight control corrects it. A falling unit only reads the body's spin, and only while it has a random spin from `MetaImpact`.
--- A unit's mass is `AverageDensity` times `SizeX`, `SizeY` and `SizeZ`, and FAF sets `AverageDensity` to `MaxHealth`, so scale
--- the impulse by the mass
---@see moho.entity_methods.AddLocalImpulse # Impulse and point in the entity's own frame
---@see MetaImpact # Knocks units into the air
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

--- Attaches this entity to another entity, matching the bone position of `selfBone` and `bone`.
--- The attached entity follows the parent one tick behind, and waits each tick until the parent has ticked. A parent that
--- isn't attached and has no motor, such as a new Lua `Entity`, stops ticking after its first tick, so the attached entity stops
--- updating. Give such a parent a motor with `FallDown` to keep it ticking
---@see moho.entity_methods.FallDown # Keeps a plain entity ticking
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

--- Attaches this entity to another entity at a bone position on it.
--- The attached entity follows the parent one tick behind, and waits each tick until the parent has ticked. A parent that
--- isn't attached and has no motor, such as a new Lua `Entity`, stops ticking after its first tick, so the attached entity stops
--- updating. Give such a parent a motor with `FallDown` to keep it ticking
---@see moho.entity_methods.FallDown # Keeps a plain entity ticking
---@param entity moho.entity_methods
---@param bone Bone
function Entity:AttachTo(entity, bone)
end


--- Returns true once `Destroy()` has been called on the entity. Unlike other methods, it can still be
--- called after the engine deletes the entity at the end of the tick
---@see IsDestroyed # True only after the deletion, and accepts `nil`
---@see moho.unit_methods.SetDead # Sets `Dead` at the end of the tick for units destroyed without `Kill`
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

--- Detaches this entity from the entity it is attached to. A detached unit that can't fly falls in the `Ballistic` motion state
--- with the velocity of its attach point over the last tick, unless `skipBallistic` is true
---@see moho.unit_methods.OnImpact # Called when a falling unit lands dead
---@param skipBallistic? boolean
function Entity:DetachFrom(skipBallistic)
end

--- Disables an intel type for this entity.
--- Throws an error if the entity's intel manager has not been initialized.
--- Units automatically initialize intel.
---@see Entity.InitIntel # To initialize the intel manager.
---@param type IntelType
function Entity:DisableIntel(type)
end

--- Enable an intel type for this entity.
--- Throws an error if the entity's intel manager has not been initialized.
--- Units automatically initialize intel.
---@see Entity.InitIntel # To initialize the intel manager.
---@param type IntelType
function Entity:EnableIntel(type)
end

--- Creates a MotorFallDown object that can be used to whack the entity about.
--- Used for falling trees. Until it is whacked, it doesn't move the entity, but keeps the entity ticking.
--- A plain Lua `Entity` needs that to carry attached entities
---@see moho.entity_methods.AttachTo # Why the parent must keep ticking
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

--- Returns three separate numbers representing the X, Y, Z direction vector of the bone
---@param bone Bone
---@return number x
---@return number y
---@return number z
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
---@see moho.entity_methods.GetMaxHealth # For the maximum possible health
---@return number
function Entity:GetHealth()
end

--- Returns the radius for a given intel type on the entity.
--- Throws an error if the entity's intel manager has not been initialized.
--- Units automatically initialize intel.
---@see Entity.InitIntel # To initialize the intel manager.
---@param type IntelType
---@return integer
function Entity:GetIntelRadius(type)
end

--- Returns the maximum amount of health this entity can have. Note that this may not be the same
--- value as the original one in the entity's blueprint.
---@see moho.entity_methods.GetHealth # For the current amount of health
---@return number
function Entity:GetMaxHealth()
end

--- Returns the orientation of this entity in 3D space as a quaternion (an array of 4 numbers)
---@return Quaternion
function Entity:GetOrientation()
end

--- Returns the parent entity (e.g. the transport a unit is on), or nil if none
---@return Entity?
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

--- Initializes the entity's intel to provide intelligence of a partiuclar type for an army.
--- This lets the other intel methods work with this entity for that type of intel.
---@param army Army
---@param type IntelType # Logs a warning if using `"None"`, but still inits intel manager.
---@param radius? integer
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

---@see moho.unit_methods.CheckCanBeKilled # Called first on units
---@see moho.unit_methods.SetDead # Called before `OnKilled`
---@see moho.unit_methods.OnKilled
---@overload fun()
---@param instigator Unit
---@param damageType DamageType
---@param excessDamageRatio number
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

--- Calls OnSelectionChanged if the unit is currently selected.
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
--- Throws an error if the entity's intel manager has not been initialized.
--- Units automatically initialize intel.
---@param type IntelType
---@param radius integer
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
---@see moho.entity_methods.SetPosition # For setting the position
---@param orientation Quaternion
---@param immediately boolean
function Entity:SetOrientation(orientation, immediately)
end

---@param vector Vector
function Entity:SetParentOffset(vector)
end

--- Sets the position of the entity. Without `immediate`, the position applies at the end of the tick, and the move counts
--- as the entity's velocity. With `immediate`, it applies at once and the velocity is zero
---@see moho.entity_methods.SetOrientation # For setting the orientation
---@param vector Vector
---@param immediate boolean # Required: omitting it errors with "expected boolean"
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

--- Called by the engine when an entity attached to this one is destroyed
---@type nil | fun(self: Entity, attached: Entity)
Entity.OnAttachedDestroyed = nil

--- Called by the engine when an entity attached to this one is killed
---@type nil | fun(self: Entity, attached: Entity)
Entity.OnAttachedKilled = nil

--- Called by the engine when a projectile is about to hit this entity. Return true to let the
--- projectile collide with it. Without this callback, projectiles pass through
---@type nil | fun(self: Entity, other: Projectile): boolean
Entity.OnCollisionCheck = nil

--- Called by the engine when the beam of a beam weapon passes through this entity. Return true to
--- let the beam hit it. Without this callback, beams pass through
---@type nil | fun(self: Entity, firingWeapon: Weapon): boolean
Entity.OnCollisionCheckWeapon = nil

--- Called by the engine when the entity takes damage from `Damage` or `DamageArea`, with the
--- amount left after armor. Not called when that amount is 0. The engine does not change the
--- entity's health itself
---@type nil | fun(self: Entity, instigator: Unit | Projectile | Entity | nil, amount: number, vector: Vector, damageType: DamageType)
Entity.OnDamage = nil

--- Called by the engine when the health of the entity crosses a 25% threshold, with the new and the
--- old threshold as fractions of its max health
---@type nil | fun(self: Entity, new: 0 | 0.25 | 0.5 | 0.75 | 1, old: 0 | 0.25 | 0.5 | 0.75 | 1)
Entity.OnHealthChanged = nil

--- Called by the engine when the entity changes layer
---@type nil | fun(self: Entity, new: Layer, old: Layer)
Entity.OnLayerChange = nil

--- Called by the engine when the entity this one is attached to is destroyed
---@type nil | fun(self: Entity, parent: Entity)
Entity.OnParentDestroyed = nil

--- Called by the engine when the entity this one is attached to is killed
---@type nil | fun(self: Entity, parent: Entity)
Entity.OnParentKilled = nil

return Entity
