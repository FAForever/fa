---@meta
---@diagnostic disable: lowercase-global

---@class SimCommand

-- TODO : Needs Definision
---@alias Task table
---@alias CSimSoundManager any
---@alias EconomyEvent moho.EconomyEvent
---@alias ArmyPlans any

---@alias Faction
---| 0 # UEF
---| 1 # Aeon
---| 2 # Cybran
---| 3 # Seraphim
---| 4 # (Nomads if enabled)

---@alias ResourceDepositType "Mass" | "Hydrocarbon"
---@alias ResourceType "MASS" | "ENERGY"
---@alias DecalType
---| "Albedo"
---| "AlbedoXP"
---| "Alpha Normals"
---| "Glow"
---| "Glow Mask"
---| "Normals"
---| "Water Albedo"
---| "Water Mask"
---| "Water Normals"

---@alias Object Blip | CollisionBeam | moho.entity_methods | moho.prop_methods | moho.projectile_methods | moho.unit_methods
---@alias BoneObject moho.entity_methods | moho.prop_methods | moho.projectile_methods | moho.unit_methods
---@alias ReclaimObject moho.prop_methods | moho.unit_methods
---@alias TargetObject moho.prop_methods | moho.unit_methods | moho.projectile_methods

--- restricts the army from building the unit category
---@param army Army
---@param category EntityCategory
function AddBuildRestriction(army, category)
end

--- it is unknown what this function does or where it gets its value from
---@param army Army
---@deprecated
function ArmyGetHandicap(army)
end

--- initializes the prebuilt units of an army via `AIBrain:OnSpawnPreBuiltUnits()`
---@param army Army
function ArmyInitializePrebuiltUnits(army)
end

--- returns true if the indicated army is a civilian army
---@param army Army
---@return boolean
function ArmyIsCivilian(army)
end

--- returns true if the indicated army has been defeated by having the flag been set with
--- `SetArmyOutOfGame(army)`
---@param army Army
---@return boolean
function ArmyIsOutOfGame(army)
end

--- attaches a beam between two entities
---@param entityA BoneObject
---@param boneA Bone
---@param entityB BoneObject
---@param boneB Bone
---@param army Army
---@param texture string
---@return moho.IEffect
function AttachBeamEntityToEntity(entityA, boneA, entityB, boneB, army, texture)
end

--- attaches a beam to an entity
---@param emitter moho.IEffect
---@param entity BoneObject
---@param bone Bone
---@param army Army
---@return moho.IEffect
function AttachBeamToEntity(emitter, entity, bone, army)
end

-- engine patched to allow commanders to be able to be shared

--- changes the army of a unit, returning the new unit and destroying the old one
---@param unit Unit
---@param army Army
---@return Unit
function ChangeUnitArmy(unit, army)
end

--- returns true if cheats are enabled and logs the cheat attempt no matter what
---@return boolean
function CheatsEnabled()
end

--- it is not known what this does or what its parameters are
---@deprecated
function CoordinateAttacks()
end

--- Creates a bone manipulator for a weapon, allowing it to aim at a target
---@param weapon Weapon
---@param label string
---@param turretBone Bone
---@param barrelBone? Bone
---@param muzzleBone? Bone
---@return moho.AimManipulator
function CreateAimController(weapon, label, turretBone, barrelBone, muzzleBone)
end

--- Creates a bone manipulator for a unit, allowing it to be animated
---@param object BoneObject
---@param alignWithSpeed? boolean    # if set, animation rate takes into account the speed of the unit. Defaults to false
---@return moho.AnimationManipulator
function CreateAnimator(object, alignWithSpeed)
end

--- Creates a beam that is attached to an entity
---@param object BoneObject
---@param bone Bone
---@param army Army
---@param length number
---@param thickness number
---@param blueprint FileName
---@return moho.IEffect
function CreateAttachedBeam(object, bone, army, length, thickness, blueprint)
end

--- creates an emitter that is attached to an entity at a bone
---@see CreateEmitterAtBone(object, bone, army, blueprint) # to create the emitter at an entity's bone without attaching it there
---@see CreateEmitterAtEntity(object, bone, army, blueprint) # to create the emitter at an entity without attaching it there
---@param object BoneObject
---@param bone Bone
---@param army Army
---@param blueprint FileName
---@return moho.IEffect
function CreateAttachedEmitter(object, bone, army, blueprint)
end

--- creates a beam, which then needs to be attached to a bone
---@see AttachBeamToEntity(emitter, entity, bone, army) # to attach the beam to an entity bone
---@see CreateBeamEmitterOnEntity(object, tobone, army, blueprint) # to create an attached beam emitter at once
---@param blueprint string
---@param army Army
---@return moho.IEffect
function CreateBeamEmitter(blueprint, army)
end

--- creates a beam and attaches it to an entity, usually used for weaponry
---@see CreateBeamEmitter(blueprint, army) # to create the beam without attaching it to anything
---@param object BoneObject
---@param tobone Bone
---@param army Army
---@param blueprint string
---@return moho.IEffect
function CreateBeamEmitterOnEntity(object, tobone, army, blueprint)
end

--- creates a beam collision entity (not a beam emitter) attached between two entities' bones
---@param object BoneObject
---@param bone Bone
---@param other BoneObject
---@param otherBone Bone
---@param army Army
---@param blueprint FileName
---@return moho.CollisionBeamEntity
function CreateBeamEntityToEntity(object, bone, other, otherBone, army, blueprint)
end

---@param object BoneObject
---@param bone Bone
---@param other BoneObject
---@param otherBone Bone
---@param army Army
---@param thickness number
---@param texture string
---@return moho.CollisionBeamEntity
function CreateBeamToEntityBone(object, bone, other, otherBone, army, thickness, texture)
end

--- Creates a builder arm controller that aims for the unit that is being built, repaired, or
--- reclaimed. Similar to an aim controller for weapons.
---@param unit Unit
---@param turretBone Bone
---@param barrelBone Bone
---@param aimBone Bone
---@return moho.BuilderArmManipulator
function CreateBuilderArmController(unit, turretBone, barrelBone, aimBone)
end

--- Creates a collision detection manipulator, calling the function
--- `self:OnAnimTerrainCollision(bone, x, y, z)`
--- when a bone that is being watched collides with the terrain
---@param unit Unit
---@return moho.CollisionManipulator
function CreateCollisionDetector(unit)
end

--- Creates a decal with supplied parameters. The decal is visible only to armies allied to `army`.
---@param position Vector
---@param heading number
---@param textureName1 FileName
---@param textureName2 FileName
---@param type DecalType
---@param sizeX number size on x axis in game units
---@param sizeZ number size on y axis in game units
---@param lodParam number distance in game units before the decals disappear
---@param duration number lifetime of the decal in seconds, 0 for infinite
---@param army Army
---@param fidelity? number
---@return moho.CDecalHandle
function CreateDecal(position, heading, textureName1, textureName2, type, sizeX, sizeZ, lodParam, duration, army, fidelity)
end

--- Creates an economy event for the unit that consumes resources over given time.
--- The unit shows the orange build bar for this event.
---@param unit Unit
---@param totalEnergy number
---@param totalMass number
---@param timeInSeconds number
---@return EconomyEvent
function CreateEconomyEvent(unit, totalEnergy, totalMass, timeInSeconds)
end

--- creates an emitter at an entity's bone, but does not attach the emitter to it
---@see CreateEmitterAtEntity(object, army, blueprint) # for an at-object version
---@see CreateEmitterOnEntity(object, army, blueprint) # for an on-object version
---@param object BoneObject
---@param army Army
---@param blueprint FileName
---@return moho.IEffect
function CreateEmitterAtBone(object, bone, army, blueprint)
end

--- creates an emitter at an entity, but does not attach the emitter to it
---@see CreateEmitterAtBone(object, bone, army, blueprint) # for an at-bone version
---@see CreateEmitterOnEntity(object, army, blueprint) # for an on-object version
---@param object BoneObject
---@param army Army
---@param blueprint FileName
---@return moho.IEffect
function CreateEmitterAtEntity(object, army, blueprint)
end

--- creates an emitter on an object and attaches the emitter to it
---@see CreateEmitterAtBone(object, bone, army, blueprint) # for an at-bone version
---@see CreateEmitterAtEntity(object, army, blueprint) # for an at-object version
---@param object BoneObject
---@param army Army
---@param blueprint FileName
---@return moho.IEffect
function CreateEmitterOnEntity(object, army, blueprint)
end

--- prevents a bone from going through the terrain (useful for units that walk)
---@param unit Unit
---@param footBone Bone
---@param kneeBone Bone
---@param hipBone Bone
---@param straightLegs? boolean
---@param maxFootFall? number
---@return moho.FootPlantManipulator
function CreateFootPlantController(unit, footBone, kneeBone, hipBone, straightLegs, maxFootFall)
end

--- spawns the initial unit for the given army
---@param army Army
---@param unitId UnitId
---@return Unit
function CreateInitialArmyUnit(army, unitId)
end

--- Creates a light particle that provides vision, is often used in combination with effects
---@see CreateLightParticleIntel() # intel-giving version
---@param object BoneObject
---@param bone Bone
---@param army Army
---@param size number
---@param lifetime number
---@param texture string
---@param rampName string
---@return moho.IEffect
function CreateLightParticle(object, bone, army, size, lifetime, texture, rampName)
end

--- Creates a light particle, is often used in combination with effects
---@see CreateLightParticle() # non intel-giving version
---@param object BoneObject
---@param bone Bone
---@param army Army
---@param size number
---@param lifetime number
---@param texture string
---@param rampName string
---@return moho.IEffect
function CreateLightParticleIntel(object, bone, army, size, lifetime, texture, rampName)
end

--- Spawns a prop, using the default orientation
---@see CreatePropHPR() # heading-pitch-roll version
---@param location Vector
---@param blueprintId string
---@return Prop
function CreateProp(location, blueprintId)
end

--- Spawns a prop with control over orientation
---@see CreateProp() # simple version
---@param blueprintPath string full path to the prop's blueprint
---@param x number
---@param y number
---@param z number
---@param heading number
---@param pitch number
---@param roll number
---@return Prop
function CreatePropHPR(blueprintPath, x, y, z, heading, pitch, roll)
end

--- Spawns mass and hydro deposits on the map
---@param type ResourceDepositType
---@param x number
---@param y number
---@param z number
---@param size number 1 for Mass, 3 for Hydro
function CreateResourceDeposit(type, x, y, z, size)
end

--- Creates a manipulator which rotates on a unit's bone
---@param object BoneObject
---@param bone Bone
---@param axis "x" | "y" | "z"
---@param goal? unknown
---@param speed? number
---@param accel? number
---@param goalspeed? number
---@return moho.RotateManipulator
function CreateRotator(object, bone, axis, goal, speed, accel, goalspeed)
end

--- Creates a manipulator which copies the motion of `srcBone` onto `dstBone`.
--- Order matters! Only manipulators which come before the slave manipulator will be copied.
---@param object BoneObject
---@param destBone Bone
---@param srcBone Bone
---@return moho.SlaveManipulator
function CreateSlaver(object, destBone, srcBone)
end

--- Creates a slider similar to those used in robotics. When applied with other manipulators the
--- slider can cause the entire sequence to 'stutter' at one update per tick, usually you should
--- only manipulate a bone with a slider and nothing else
---@param object BoneObject
---@param bone Bone
---@param goalX? number
---@param goalY? number
---@param goalZ? number
---@param speed? number
---@param worldSpace? boolean
---@return moho.SlideManipulator
function CreateSlider(object, bone, goalX, goalY, goalZ, speed, worldSpace)
end

--- Adds a splat to the game at a position and heading
---@see CreateSplatOnBone() # adds the splat at an entity bone
---@param position Vector
---@param heading number
---@param texture string
---@param sizeX number
---@param sizeZ number
---@param lodParam number
---@param duration number
---@param army Army
---@param fidelity? number
function CreateSplat(position, heading, texture, sizeX, sizeZ, lodParam, duration, army, fidelity)
end

--- Adds a splat to the game at an entity bone position and heading
---@see CreateSplatOnBone() # adds the splat at a position
---@param object BoneObject
---@param offset Vector
---@param bone Bone
---@param texture string
---@param sizeX number
---@param sizeZ number
---@param lodParam number
---@param duration number
---@param army Army
function CreateSplatOnBone(object, offset, bone, texture, sizeX, sizeZ, lodParam, duration, army)
end

---@param object BoneObject
---@param bone Bone
---@param resource any
---@param minX number
---@param minY number
---@param minZ number
---@param maxX number
---@param maxY number
---@param maxZ number
---@return moho.StorageManipulator
function CreateStorageManip(object, bone, resource, minX, minY, minZ, maxX, maxY, maxZ)
end

---@param unit Unit
---@param label string
---@param thrustBone Bone
---@return moho.ThrustManipulator
function CreateThrustController(unit, label, thrustBone)
end

---@param object BoneObject
---@param bone Bone
---@param army Army
---@param trailBlueprint FileName
---@return moho.IEffect
function CreateTrail(object, bone, army, trailBlueprint)
end

--- Creates a unit from a blueprint for an army, at a position with quaternion orientation
---@see CreateUnit2() # simple version
---@see CreateUnitHPR() # heading-pitch-roll version
---@param blueprint string
---@param army Army
---@param x number
---@param y number
---@param z number
---@param qx number
---@param qy number
---@param qz number
---@param qw number
---@param layer? number
---@return Unit
function CreateUnit(blueprint, army, x, y, z, qx, qy, qz, qw, layer)
end

--- Creates a unit from a blueprint for an army, at an X-Z map point with a heading
---@see CreateUnit() # quaternion version
---@see CreateUnitHPR() # heading-pitch-roll version
---@param blueprint string
---@param army Army
---@param layer? number
---@param x number
---@param z number
---@param heading number
---@return Unit
function CreateUnit2(blueprint, army, layer, x, z, heading)
end

--- Creates a unit from a blueprint for an army, at a position with heading, pitch, and roll
---@see CreateUnit() # quaternion version
---@see CreateUnit2() # simple version
---@param blueprint UnitId
---@param army Army
---@param x number
---@param y number
---@param z number
---@param heading number
---@param pitch number
---@param roll number
---@return Unit
function CreateUnitHPR(blueprint, army, x, y, z, heading, pitch, roll)
end

--- Deals damage to the target unit
---@param instigator TargetObject | nil
---@param location Vector origin of the damage, used for effects
---@param target Unit
---@param amount number
---@param damageType DamageType
function Damage(instigator, location, target, amount, damageType)
end

--- Deals damage in an circle
---@param instigator TargetObject | nil
---@param location Vector
---@param radius number
---@param damage number
---@param damageType DamageType
---@param damageFriendly boolean
---@param damageSelf? boolean
function DamageArea(instigator, location, radius, damage, damageType, damageFriendly, damageSelf)
end

--- Deals damage in an ring
---@param instigator TargetObject | nil
---@param location Vector
---@param minRadius number
---@param maxRadius number
---@param damage number
---@param damageType DamageType
---@param damageFriendly boolean
---@param damageSelf? boolean
function DamageRing(instigator, location, minRadius, maxRadius, damage, damageType, damageFriendly, damageSelf)
end

--- Gets the selected units for debug purposes. Note that the selection depends on the player,
--- so it should not be used in synchronous code.
---@return Unit[]
function DebugGetSelection()
end

--- Draws a 3D circle
---@param center Vector
---@param diameter number
---@param color Color
function DrawCircle(center, diameter, color)
end

--- Draws a 3D line
---@param pointA Vector
---@param pointB Vector
---@param color Color
function DrawLine(pointA, pointB, color)
end

--- Draws a 3D line with a circle at the end
---@param start Vector
---@param finish Vector
---@param color Color
function DrawLinePop(start, finish, color)
end

--- Returns true if the economy event is finished
---@param event EconomyEvent
---@return boolean
function EconomyEventIsDone(event)
end

--- Signals the end of the game (acts like a permanent pause)
function EndGame()
end

--- Counts how many units fit the specified category.
---@param category EntityCategory
---@param tblUnits Unit[]
---@return number
function EntityCategoryCount(category, tblUnits)
end

--- Counts how many units fit the specified category around a position.
---@param category EntityCategory
---@param position Vector
---@return number
function EntityCategoryCountAroundPosition(category, position)
end

--- Changes elevation of the map in the desired area.
--- Used mainly for spawning buildings, so they don't float in air.
---@param x number
---@param z number
---@param sizeX number
---@param sizeZ number
---@param elevation number
function FlattenMapRect(x, z, sizeX, sizeZ, elevation)
end

--- Removes all recon blips from the target area. If the area is in radar range it generates unseen
--- recon blips.
---@param minX number
---@param minZ number
---@param maxX number
---@param maxZ number
function FlushIntelInRect(minX, minZ, maxX, maxZ)
end

---@param armyName string
function GenerateArmyStart(armyName)
end

---@return Quaternion
function GenerateRandomOrientation()
end

--- Returns an army's brain
---@param army Army
---@return AIBrain
function GetArmyBrain(army)
end

--- Returns the army's unit cap
---@param army Army
---@return number
function GetArmyUnitCap(army)
end

--- Returns the total unit cap cost of the army
---@param army Army
---@return number
function GetArmyUnitCostTotal(army)
end

--- Returns the currently active command source in the sim state. This number is the army index
--- of the army that sent the command.
---@return number
function GetCurrentCommandSource()
end

--- returns the entities inside the given rectangle
---@param rectangle Rectangle
function GetEntitiesInRect(rectangle)
end

--- Gets entity by entity ID. This ID is unique for each entity.
--- Note that entity ID's are recycled as entities are destroyed.
---@param id EntityId
---@return Entity
function GetEntityById(id)
end

--- Gets the current game time in ticks.
--- The game time is the simulation time, that stops when the game is paused.
---@return number
function GetGameTick()
end

--- Returns map size
---@return number sizeX
---@return number sizeZ
function GetMapSize()
end

---@overload fun(x0: number, z0: number, x1: number, z1: number): ReclaimObject[] | nil
--- Returns the reclaimable objects inside the given rectangle.
--- This includes props, units, wreckages.
---@param rectangle Rectangle
---@return ReclaimObject[] | nil
function GetReclaimablesInRect(rectangle)
end

--- Returns surface elevation at given position.
--- Takes water into count.
---@param x number
---@param z number
---@return number
function GetSurfaceHeight(x, z)
end

--- Returns System time in seconds
---@return number
function GetSystemTimeSecondsOnlyForProfileUse()
end

--- Returns elevation at given position.
--- Ignores water surface.
---@param x number
---@param z number
---@return number
function GetTerrainHeight(x, z)
end

--- Returns terrain type at given position
---@param x number
---@param z number
---@return TerrainType
function GetTerrainType(x, z)
end

---@return number
function GetTerrainTypeOffset(x, z)
end

--- Returns unit's blueprint given the blueprint's name
---@param bpName string
---@return UnitBlueprint
function GetUnitBlueprintByName(bpName)
end

--- retrieves all units in a rectangle
---@param rectangle Rectangle
---@return Unit[] | nil
function GetUnitsInRect(rectangle)
end

--- Starts the AI on given army
---@param army string
function InitializeArmyAI(army)
end

---@param object Object
---@return boolean
function IsBlip(object)
end

---@param object Object
---@return boolean
function IsCollisionBeam(object)
end

--- Returns true if the given command is finished
---@param cmd SimCommand
---@return boolean
function IsCommandDone(cmd)
end

--- Returns true if the given object is an Entity
---@param object Object
---@return boolean
function IsEntity(object)
end

--- Returns true if the game is over
---@return boolean
function IsGameOver()
end

--- Returns true if the target entity is a projectile
---@param object Object
---@return boolean
function IsProjectile(object)
end

--- Returns true if the target entity is a prop
---@param object Object
---@return boolean
function IsProp(object)
end

--- Returns true if the target entity is a unit
---@param object Object
---@return boolean
function IsUnit(object)
end

--- Orders a group of units to attack-move to a position
---@param units Unit[]
---@param position Vector
---@return SimCommand
function IssueAggressiveMove(units, position)
end

--- Orders a group of units to attack a target
---@param units Unit[]
---@param target Unit
---@return SimCommand
function IssueAttack(units, target)
end

--- Orders a group of units to build a unit
---@param units Unit[]
---@param blueprintID string
---@param count number
---@return SimCommand
function IssueBuildFactory(units, blueprintID, count)
end

--- Orders a group of units to build a unit, the nearest unit is given the order
--- Takes some time to apply (at least 3 ticks).
---@param units Unit[]
---@param position Vector
---@param blueprintID string
---@param table number[] # A list of alternative build locations, similar to AiBrain.BuildStructure. Doesn't appear to function properly
function IssueBuildMobile(units, position, blueprintID, table)
end

--- Orders a group of units to start building another unit by blueprint id
--- Takes some time to apply (at least 3 ticks).
---@param units Unit[]
---@param position Vector
---@param blueprintID string
---@param table number[] # A list of alternative build locations, similar to AiBrain.BuildStructure. Doesn't appear to function properly
function IssueBuildAllMobile(units, position, blueprintID, table)
end

--- Orders a group of units to capture a target, usually engineers
---@param units Unit[]
---@param target Unit
---@return SimCommand
function IssueCapture(units, target)
end

--- Clears out all commands issued on the group of units, this happens immediately. See `IssueToUnitClearCommands` when you want to computationally efficiently apply it to a single unit 
---@param units Unit[]
---@return SimCommand
function IssueClearCommands(units)
end

--- Clears out all commands issued on the group of factories without affecting
--- the build queue, allows you to change the rally point
---@param factories Unit[]
---@return SimCommand
function IssueClearFactoryCommands(factories)
end

--- Orders a group of units to destroy themselves, doesn't leave a wreckage
---@see IssueKillSelf() # an alternative that does leave a wreckage
---@param units Unit[]
---@return SimCommand
function IssueDestroySelf(units)
end

--- Orders a group of units to dive
---@param units Unit[]
---@return SimCommand
function IssueDive(units)
end

--- Orders a group of factories to assist another factory
---@param units Unit[]
---@param target Unit
---@return SimCommand
function IssueFactoryAssist(units, target)
end

--- Orders a group of factories to set their rally point
---@param units Unit[]
---@param position Vector
---@return SimCommand
function IssueFactoryRallyPoint(units, position)
end

--- Orders a group of units to setup a ferry
---@param units Unit[]
---@param position Vector
---@return SimCommand
function IssueFerry(units, position)
end

--- Orders a group of units to attack move to a position in formation
--- @param units Unit[]
--- @param position Vector
--- @param formation UnitFormations     # Unit formation to use as defined in `formations.lua`
--- @param degrees number               # Orientation the platoon takes when it reaches the position. South is 0 degrees, east is 90 degrees, etc.
--- @return SimCommand
function IssueFormAggressiveMove(units, position, formation, degrees)
end

--- Orders a group of units to attack a target in formation
--- @param units Unit[]
--- @param target Unit
--- @param formation UnitFormations     # Unit formation to use as defined in `formations.lua`
--- @param degrees number               # Orientation the platoon takes when it reaches the position. South is 0 degrees, east is 90 degrees, etc.
--- @return SimCommand
function IssueFormAttack(units, target, formation, degrees)
end

--- Orders a group of units to move to a position in formation
--- @param units Unit[]
--- @param position Vector
--- @param formation UnitFormations     # Unit formation to use as defined in `formations.lua`
--- @param degrees number               # Orientation the platoon takes when it reaches the position. South is 0 degrees, east is 90 degrees, etc.
--- @return SimCommand
function IssueFormMove(units, position, formation, degrees)
end

--- Orders a group of units to patrol to a position in formation
--- @param units Unit[]
--- @param position Vector
--- @param formation UnitFormations     # Unit formation to use as defined in `formations.lua`
--- @param degrees number               # Orientation the platoon takes when it reaches the position. South is 0 degrees, east is 90 degrees, etc.
--- @return SimCommand
function IssueFormPatrol(units, position, formation, degrees)
end

--- Orders a group of units to guard a target
---@param units Unit[]
---@param target Unit | Vector
---@return SimCommand
function IssueGuard(units, target)
end

--- Orders a group of units to kill themselves
---@see IssueDestroySelf() # an alternative that does not leave a wreckage
---@param units Unit[]
---@return SimCommand
function IssueKillSelf(units)
end

--- Orders a group of units to move to a position.  See `IssueToUnitMove` when you want to computationally efficiently apply it to a single unit 
---@param units Unit[]
---@param position Vector
---@return SimCommand
function IssueMove(units, position)
end

--- Orders a group of units to move off a factory build site. See `IssueToUnitMoveOffFactory` when you want to computationally efficiently apply it to a single unit
---@param units Unit[]
---@param position Vector
---@return SimCommand
function IssueMoveOffFactory(units, position)
end

--- Orders a group of units to launch a strategic missile at a position
---@see IssueTactical() # for tactical missiles
---@param units Unit[]
---@param position Vector
---@return SimCommand
function IssueNuke(units, position)
end

--- Orders a group of units to use Overcharge at a target
---@param units Unit[]
---@param target Unit
---@return SimCommand
function IssueOverCharge(units, target)
end

--- Orders a group of units to patrol to a position
---@param units Unit[]
---@param position Vector
---@return SimCommand
function IssuePatrol(units, position)
end

--- Orders a unit to pause, this happens immediately
---@param unit Unit
function IssuePause(unit)
end

--- Orders a group of units to reclaim a target
---@param units Unit[]
---@param target ReclaimObject
---@return SimCommand
function IssueReclaim(units, target)
end

--- Orders a group of units to repair a target
---@param units Unit[]
---@param target Unit
---@return SimCommand
function IssueRepair(units, target)
end

--- Orders a group of units to sacrifice, yielding part of their build cost to a target
---@param tblUnits Unit[]
---@param target Unit
---@return SimCommand
function IssueSacrifice(tblUnits, target)
end

--- Orders a group of units to run a script sequence, as an example:
--- `{ TaskName = "EnhanceTask", Enhancement = "AdvancedEngineering" }`
---@param tblUnits Unit[]
---@param order Task
---@return ScriptTask
function IssueScript(tblUnits, order)
end

--- Orders a group of units (SML or SMD) to build a nuke
---@param units Unit[]
---@return SimCommand
function IssueSiloBuildNuke(units)
end

--- Orders a group of units to build a tactical missile
---@param units Unit[]
---@return SimCommand
function IssueSiloBuildTactical(units)
end

--- Orders a group of units to stop, this happens immediately
---@param units Unit[]
function IssueStop(units)
end

--- Orders a group of units to launch a tactical missile
---@see IssueNuke() # for nuclear missiles
---@param units Unit[]
---@param target Unit | Vector
---@return SimCommand
function IssueTactical(units, target)
end

--- Orders a group of units to teleport to a position
---@param units Unit[]
---@param position Vector
---@return SimCommand
function IssueTeleport(units, position)
end

---@param units Unit[]
---@param beacon unknown
---@return SimCommand
function IssueTeleportToBeacon(units, beacon)
end

--- Orders a group of units to attach themselves to a transport
---@param units Unit[]
---@param transport Unit
---@return SimCommand
function IssueTransportLoad(units, transport)
end

--- Orders a group of transports to unload their cargo at a position
---@param units Unit[]
---@param position Vector
---@return SimCommand
function IssueTransportUnload(units, position)
end

--- Orders a group of ~~transports~~ or carriers to unload specific units,
--- appears to work only for carriers
---@param units Unit[]
---@param position Vector
---@param category EntityCategory
---@return SimCommand
function IssueTransportUnloadSpecific(units, category, position)
end

--- Orders a group of units to upgrade
---@param units Unit[]
---@param blueprintID string
---@return SimCommand
function IssueUpgrade(units, blueprintID)
end

--- Latent unit move
---@param unit Unit
---@param target Vector
function LUnitMove(unit, target)
end

--- Latent unit move near
---@param unit Unit
---@param target Vector
---@param range number
function LUnitMoveNear(unit, target, range)
end

--- Lists all armies in the game, as defined by the current army configuration of the
---@return string[]
function ListArmies()
end

---@param instigator Unit
---@param location Vector
---@param maxRadius number
---@param amount number
---@param affectsCategory? EntityCategory
---@param damageFriendly? boolean
---@deprecated
function MetaImpact(instigator, location, maxRadius, amount, affectsCategory, damageFriendly)
end

---@param from Unit
---@param to Unit
function NotifyUpgrade(from, to)
end

--- Returns true if the current command source is authorized to mess with the given army,
--- or if cheats are enabled
---@param army Army
---@return boolean
function OkayToMessWithArmy(army)
end

---@param manager CSimSoundManager
---@param sound SoundHandle
---@return SoundHandle
function PlayLoop(manager, sound)
end

--- Unrestricts the army from building the unit category
---@param army Army
---@param category EntityCategory
function RemoveBuildRestriction(army, category)
end

--- Removes economy event created by CreateEconomyEvent function from the unit
---@param unit Unit
---@param event EconomyEvent
function RemoveEconomyEvent(unit, event)
end

--- Returns the currently selected unit. For use at the lua console, so you can call Lua methods on a unit
---@return Unit
function SelectedUnit()
end

--- Sets alliance type between 2 armies, note that weapons do not reset their target
---@param army1 Army
---@param army2 Army
---@param alliance AllianceType
function SetAlliance(army1, army2, alliance)
end

--- Sets alliance type from army1 to army2, note that weapons do not reset their target
---@param army1 Army
---@param army2 Army
---@param alliance AllianceType
function SetAllianceOneWay(army1, army2, alliance)
end

--- Use `/lua/ui/game/diplomacy.lua#SetAlliedVectory(state)` instead
---@deprecated
---@param state boolean
function SetAlliedVictory(state)
end

--- Unfinished function related to AI, is not used
---@deprecated
---@param army Army
---@param personality AIPersonality
function SetArmyAIPersonality(army, personality)
end

--- Sets army's color using RGB values, `0` - `255`
---@param army Army
---@param r number
---@param g number
---@param b number
function SetArmyColor(army, r, g, b)
end

--- Sets the color index of the army
---@param army Army
---@param color number
function SetArmyColorIndex(army, color)
end

--- Sets mass and energy of the army
---@param army Army
---@param mass number
---@param energy number
function SetArmyEconomy(army, mass, energy)
end

--- Sets faction for the given army
---@param army Army
---@param index Faction
function SetArmyFactionIndex(army, index)
end

--- Indicates that the army has been defeated
---@param army Army
function SetArmyOutOfGame(army)
end

--- Unfinished function related to AI, is not used
---@deprecated
---@param army Army
---@param plans ArmyPlans
function SetArmyPlans(army, plans)
end

--- Determines if the user should be able to see the army score
---@param army Army
---@param show boolean
function SetArmyShowScore(army, show)
end

--- Sets the army starting position for the initial unit.
---@param army Army
---@param x number
---@param z number
function SetArmyStart(army, x, z)
end

--- Sets the army for which to sync army stats
---@param army Army
function SetArmyStatsSyncArmy(army)
end

--- Sets the unit cap for the army
---@param army Army
---@param unitCap number
function SetArmyUnitCap(army, unitCap)
end

--- Sets the command source of an army to match another army's command source.
---@param targetArmyIndex number
---@param sourceHumanIndex number
---@param enable boolean
function SetCommandSource(targetArmyIndex, sourceHumanIndex, enable)
end

--- sets an army to ignore unit cap
---@param army Army
---@param ignore boolean
function SetIgnoreArmyUnitCap(army, ignore)
end

--- Sets an army to ignore the playable area on a map.
--- Used in campaign for offmap attacks.
---@param army Army
---@param ignore boolean
function SetIgnorePlayableRect(army, ignore)
end

--- sets the playable area of a map
---@param minX number
---@param minZ number
---@param maxX number
---@param maxZ number
function SetPlayableRect(minX, minZ, maxX, maxZ)
end

--- Changes terrain type at given position
---@param x number
---@param z number
---@param type TerrainType
function SetTerrainType(x, z, type)
end

--- changes the terrain type in given area
---@param rect Rectangle
---@param type TerrainType
function SetTerrainTypeRect(rect, type)
end

---@return boolean createInitial
function ShouldCreateInitialArmyUnits()
end

--- performs a console command
---@param command string
function SimConExecute(command)
end

--- Sinks the entity into the ground. Used for dead trees, for example.
---@param velY number
function SinkAway(velY)
end

--- Splits a prop into multiple child props, spawning one prop per bone.
--- Used for breaking up tree groups at collision.
---@param original Prop
---@param blueprintId string
---@return Prop[]
function SplitProp(original, blueprintId)
end

---@param manager CSimSoundManager
---@param handle SoundHandle
function StopLoop(manager, handle)
end

--- requests that we submit XML army stats to GPG.net
function SubmitXMLArmyStats()
end

--- Attempts to copy animation pose from the unit to the prop.
--- Only works if the mesh and skeletons are the same, but will not produce an error if not.
---@param unitFrom Unit
---@param entityTo Prop
---@param copyWorldTransform boolean
function TryCopyPose(unitFrom, entityTo, copyWorldTransform)
end

--- instantly moves an entity to a location with an orientation
---@param object Object
---@param location Vector
---@param orientation? Quaternion no orientation change if absent
function Warp(object, location, orientation)
end

---@param entity Entity
---@param spec EntitySpec
function _c_CreateEntity(entity, spec)
end

---@param shield Shield
---@param spec UnitBlueprintDefenseShield
function _c_CreateShield(shield, spec)
end
