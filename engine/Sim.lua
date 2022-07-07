---@declare-global
---Module: Sim
-- @module Sim

-- TODO
---@class Decal

-- TODO
---@class SimCommand

---@alias Language "cn" | "cz" | "de" | "es" | "fr" | "it" | "pl" | "ru" | "tw" | "tzm" | "us"

--- Restrict the army from building the unit category, which can be combined using the typical category arithmetics (+ for union, - for subtraction, * for intersection)
---@param army number
---@param category Categories
function AddBuildRestriction(army, category)
end

---@param army number
---@deprecated It is unknown what this function does and where it gets its value from.
function ArmyGetHandicap(army)
end

--- Initialises the prebuilt units of an army via `brain:OnSpawnPreBuiltUnits`
---@param army number
function ArmyInitializePrebuiltUnits(army)
end

--- Return true if the indicated army is a civilian army.
---@param army number
---@return boolean
function ArmyIsCivilian(army)
end

--- Return true if the indicated army has been defeated.
---@param army number | string
function ArmyIsOutOfGame(army)
end

--- Attaches a beam between two entities
---@param entityA Entity | Unit | Prop
---@param boneA number | string
---@param entityB Entity | Unit | Prop
---@param boneB number | string
---@param army number
---@param blueprint BeamBlueprint
---@return moho.IEffect
function AttachBeamEntityToEntity(entityA, boneA, entityB, boneB, army, blueprint)
end

--- Attaches a beam to an entity
---@param emitter BeamBlueprint
---@param entity Entity | Unit | Prop
---@param bone number | string
---@param army number
---@return moho.IEffect
function AttachBeamToEntity(emitter, entity, bone, army)
end

--- Sets language for playing voices.
-- Available languages are in '/gamedata/loc'.
-- Game currently defaults on 'us' language if the localized voices don't exists.
-- @param language String of the language shortcut, example: 'us'.

--- Sets the language for voice overs, available languages are in '/gamedata/loc'. The game defaults to 'us' language if the localized voices do not exist
---@param language Language
function AudioSetLanguage(language)
end

--- Change a unit's army, return the new unit.
-- @param unit Unit to be given.
-- @param army Army's index to recieve the unit.

--- Changes the army of a unit, returning a new unit.
---@param unit Unit
---@param army number
---@return Unit
function ChangeUnitArmy(unit, army)
end

--- Returns true if cheats are enabled, logs the cheat attempt no matter what
---@return boolean
function CheatsEnabled()
end

--- It is not known what this does or what its parameters are.
---@deprecated
function CoordinateAttacks()
end

--- Creates a bone manipulator for a weapon, allowing it to aim at a target
---@param weapon Weapon
---@param label string
---@param turretBone number | string
---@param barrelBone number | string
---@param muzzleBone number | string
---@return CAimManipulator
function CreateAimController(weapon, label, turretBone, barrelBone, muzzleBone)
end

--- Creates a bone manipulator for a unit, allowing it to be animated
---@param unit Unit
---@return moho.manipulator_methods
function CreateAnimator(unit)
end

--- TODO.
function CreateAttachedBeam(entity, bone, army, length, thickness, texture_filename)
end

--- TODO.
function CreateAttachedEmitter(entity, bone, army, emitter_blueprint)
end

--- TODO.
function CreateBeamEmitter(blueprint, army)
end

--- TODO.
function CreateBeamEmitterOnEntity(entity, tobone, army, blueprint)
end

--- TODO.
function CreateBeamEntityToEntity(entity, bone, other, bone, army, blueprint)
end

--- TODO.
function CreateBeamToEntityBone(entity, bone, other, bone, army, thickness, texture_filename)
end

--- TODO.
---@param unit any
---@param turretBone any
---@param barrelBone any?
---@param aimBone any?
function CreateBuilderArmController(unit,turretBone, barrelBone, aimBone)
end

--- Create a collision detection manipulator
-- TODO.
function CreateCollisionDetector(unit)
end

--- Creates a decal with supplied parametrs.
-- This decal is visible to all armies.
-- @param position Table with position {x, y, z}.
-- @param heading Table with orientation {x, y, z}.
-- @param textureName1 TODO.
-- @param textureName2 TODO.
-- @param type TODO.
-- @param sizeX Size on x axis in game units.
-- @param sizeZ Size on y axisin game units.
-- @param lodParam Distance in game units before the decals disappear.
-- @param duration Life time of the decal in seconds, 0 for infinite.
-- @param army Owner's army's index.
-- @param fidelity TODO.
-- @return The created decal.
function CreateDecal(position, heading, textureName1, textureName2, type, sizeX, sizeZ, lodParam, duration, army, fidelity)
end

--- Creates an economy event for the unit that consumes resources over given time.
-- The unit shows the orange build bar for this event.
-- @param unit Target unit.
-- @param energy Amount of total energy the event will consume.
-- @param mass Amount of total energy the event will consume.
-- @param timeInSeconds How many seconds will the event last.
-- return event Created economy event.
function CreateEconomyEvent(unit, energy, mass, timeInSeconds)
end

--- TODO.
function CreateEmitterAtBone(entity, bone, army, emitter_blueprint)
end

--- TODO.
function CreateEmitterAtEntity(entity, army, emitter_bp_name)
end

--- TODO.
function CreateEmitterOnEntity(entity, army, emitter_bp_name)
end

--- TODO.
---@param unit any
---@param footBone any
---@param kneeBone any
---@param hipBone any
---@param straightLegs any?
---@param maxFootFall any?
function CreateFootPlantController(unit, footBone, kneeBone, hipBone, straightLegs, maxFootFall)
end

--- Spawns initial unit for the given army.
-- @param armyName String, army's name.
-- @param initialUnitName String, unit blueprint name, example: 'uel0001'.
-- @return The created unit.
function CreateInitialArmyUnit(armyName, initialUnitName)
end

--- TODO.
function CreateLightParticle(entity, bone, army, size, lifetime, textureName, rampName)
end

--- TODO.
function CreateLightParticleIntel(entity, bone, army, size, lifetime, textureName, rampName)
end

--- Spawns a prop.
-- Orientation is set by the prop's model.
-- For more control over the orientation use CreatePropHPR.
-- @param location Table with position {x, y, z}.
-- @param prop_blueprint_id Blueprint ID of the prop to spawn, example: 'CrysCrystal01_prop'.
-- @return The spawned prop.
function CreateProp(location, prop_blueprint_id)
end

--- Spawns a prop.
-- Additional control to set orientation of the prop.
-- @param blueprint Full path to the prop's blueprint.
-- @param x Position on x axis.
-- @param y Position on y axis.
-- @param z Position on z axis.
-- @param heading TODO.
-- @param pitch TODO.
-- @param roll TODO.
-- @return The spawned prop.
function CreatePropHPR(blueprint, x, y, z, heading, pitch, roll)
end

--- Spawn Mass and Hydro points on the map.
-- @param type Type of the resource to create, either 'Mass' or 'Hydrocarbon'.
-- @param x Position on x axis.
-- @param y Position on y axis.
-- @param z Position on z axis.
-- @param size Size in game units, 1 for Mass, 3 for Hydro.
function CreateResourceDeposit(type, x, y, z, size)
end

--- Create a manipulator which rotates unit's bone.
---@param unit Unit to create the manipulator for.
---@param bone string name of the bone to rotate.
---@param axis string 'x', 'Y' or 'z', axis to rotate around.
---@param goal unknown? TODO.
---@param speed unknown? TODO.
---@param accel unknown? TODO.
---@param goalspeed unknown? TODO.
-- @return manipulator
function CreateRotator(unit, bone, axis, goal, speed, accel, goalspeed)
end

--- Create a manipulator which copies the motion of src_bone onto dst_bone.
-- Priority matters! Only manipulators which come before the slave manipulator will be copied.
-- @param unit Unit to create the manipulator for.
-- @param dest_bone String, name of the bone to paste the motion to.
-- @param src_bone String, name of the bone to copy the motion from.
-- @return manipulator
function CreateSlaver(unit, dest_bone, src_bone)
end

--- TODO.
-- CreateSlider(unit, bone, [goal_x, goal_y, goal_z, [speed, [world_space]]]).
function CreateSlider()
end

--- TODO.
function CreateSplat(position, heading, textureName, sizeX, sizeZ, lodParam, duration, army, fidelity)
end

--- Add a splat to the game at an entity bone position and heading.
-- TODO.
function CreateSplatOnBone(boneName, offset, textureName, sizeX, sizeZ, lodParam, duration, army)
end

--- TODO.
function CreateStorageManip(unit, bone, resouceName, minX, minY, minZ, maxX, maxY, maxZ)
end

--- TODO.
function CreateThrustController(unit, label, thrustBone)
end

--- TODO.
function CreateTrail(entity, bone, army, trail_blueprint)
end

--- TODO.
---@param blueprint any
---@param army any
---@param tx any
---@param ty any
---@param tz any
---@param qx any
---@param qy any
---@param qz any
---@param qw any
---@param layer any?
function CreateUnit(blueprint, army, tx, ty, tz, qx, qy, qz, qw, layer)
end

--- TODO.
function CreateUnit2(blueprint, army, layer, x, z, heading)
end

--- TODO.
function CreateUnitHPR(blueprint, army, x, y, z, pitch, yaw, roll)
end

--- Deals damage to the target unit.
-- @param instigator Source of the damage (unit) or nil.
-- @param target Unit taking the damage
-- @param amount Number, amount of damage.
-- @param damageType Example: 'Force', 'Normal', 'Nuke', 'Fire', TODO.
function Damage(instigator, target, amount, damageType)
end

--- Deals damage to the target unit.
---@param instigator Unit Source of the damage (unit) or nil.
---@param location {x:number, y:number, z:number} with position {x, y, z}.
---@param radius number distance from the location to deal the damage.
---@param amount number amount of damage.
---@param damageType string 'Force', 'Normal', 'Nuke', 'Fire', TODO.
---@param damageFriendly boolean if it should damage allied units.
---@param damageSelf boolean? if the unit dealing the damage should take it as well.
function DamageArea(instigator, location, radius, amount, damageType, damageFriendly, damageSelf)
end

--- Deals damage to the target unit.
---@param instigator Unit Source of the damage (unit) or nil.
---@param location {x:number, y:number, z:number} with position {x, y, z}.
---@param minRadius number distance from the location to start dealing damage.
---@param maxRadius number distance from the location to stop dealing damage.
---@param amount number amount of damage.
---@param damageType string 'Force', 'Normal', 'Nuke', 'Fire', TODO.
---@param damageFriendly boolean if it should damage allied units.
---@param damageSelf boolean if the unit dealing the damage should take it as well.
function DamageRing(instigator, location, minRadius, maxRadius, amount, damageType, damageFriendly, damageSelf)
end

--- Get DEBUG info for UI selection.
-- TODO.
function DebugGetSelection()
end

--- Draw a 3d circle at a with size s and color c.

-- Draws a circle at a given location with a given diameter and color
-- @param position An array-based table { 0, 0, 0 } that represents a position
-- @param diameter Diameter of the circle
-- @param color Color of the circle
function DrawCircle()
end

--- Draw a 3d line from a to b with color c.
-- TODO.
function DrawLine()
end

--- Draw a 3d line from a to b with color c with a circle at the endof the target line.
-- TODO.
function DrawLinePop()
end

--- Check if the economy event is finished.
-- @param event Economy event created by CreateEconomyEvent function.
-- @return true/false.
function EconomyEventIsDone(event)
end

--- Signal the end of the game.
-- Acts like a permanent pause.
function EndGame()
end

--- Returns true if a unit category contains this unit.
-- @param category Unit category.
-- @unit Unit fo check for category.
function EntityCategoryContains(category, unit)
end

--- Count how many units fit the specified category.
-- @param category Unit category.
-- @tblUnits Table containing units, same as group of units.
-- @return Number.
function EntityCategoryCount(category, tblUnits)
end

--- Count how many units fit the specified category around a position.
-- TODO Ideas: (cytegory, position).
-- @return Number.
function EntityCategoryCountAroundPosition()
end

--- Filter a list of units to only those found in the category.
-- @param category Unit category.
-- @tblUnits Table containing units, same as group of units.
-- @return Filtered list of units.
function EntityCategoryFilterDown(category, tblUnits)
end

--- Changes elevation of the map in the desired area.
-- Used mainly for spawning buildings, so they don't float in air.
-- @param x Starting point on x axis in game units.
-- @param z Starting point on z axis in game units.
-- @param sizex Size on x axis in game units.
-- @param sizez Size on z axis in game units.
-- @param elevation Target elevation in game units.
function FlattenMapRect(x, z, sizex, sizez, elevation)
end

--- Deletes sscouted icons from the target area.
-- If the area is in a radar range, it will switch back to default unscouted icons.
function FlushIntelInRect(minX, minZ, maxX, maxZ)
end

--- TODO.
function GenerateArmyStart(strArmy)
end

--- TODO.
-- INFO: rotation = GenerateRandomOrientation()
function GenerateRandomOrientation()
end

--- Returns an army brain given the brain's name.
---@param strArmy any
---@return AIBrain
function GetArmyBrain(strArmy)
end

--- Returns current army's unit capacity.
function GetArmyUnitCap(strArmy)
end

--- TODO.
function GetArmyUnitCostTotal(strArmy)
end

--- Returns entity's blueprint.
-- Can be used as local bp = entity:GetBlueprint().
function GetBlueprint(entity)
end

--- Return the (1 based) index of the current command source.
-- TODO.
function GetCurrentCommandSource()
end

--- Return the enitities inside the given rectangle.
-- @param rectangle Map area created by function Rect(x0, z0, x1, z1).
function GetEntitiesInRect(rectangle)
end

--- Get entity by entity id.
-- This ID is unique for each entity.
function GetEntityById(id)
end

--- Returns the index of local army.
function GetFocusArmy()
end

--- Get the current game time in ticks.
-- The game time is the simulation time, that stops when the game is paused.
function GetGameTick()
end

--- Get the current game time in seconds.
-- The game time is the simulation time, that stops when the game is paused.
function GetGameTimeSeconds()
end

--- Returns map size.
-- @return sizeX, sizeZ.
function GetMapSize()
end

--- Return the reclamable things inside the given rectangle.
-- That includes props, units, wreckages.
-- @param rectangle Map area created by function Rect(x0, z0, x1, z1).
function GetReclaimablesInRect(rectangle)
end

--- Returns surface elevation at given position.
-- Takes water into count.
---@param x number Position on x axis.
---@param z number Position on z axis.
function GetSurfaceHeight(x, z)
end

--- Returns System time in seconds.
-- INFO: float GetSystemTimeSecondsOnlyForProfileUse().
-- TODO.
function GetSystemTimeSecondsOnlyForProfileUse()
end

--- Returns elevation at given position.
-- Ignores water surface.
-- @param x Position on x axis.
-- @param z Position on x axis.
function GetTerrainHeight(x, z)
end

--- Returns terrain type at given position.
-- INFO: type = GetTerrainType(x,z).
-- @param x Position on x axis.
-- @param z Position on z axis.
function GetTerrainType(x, z)
end

--- TODO.
-- INFO: type = GetTerrainTypeOffset(x,z).
function GetTerrainTypeOffset(x, z)
end

--- Returns unit's blueprint given the blueprint's name.
-- Example: 'ueb0101'.
-- @param bpName Unit's blueprint name.
function GetUnitBlueprintByName(bpName)
end

--- Returns unit by unique entity id.
-- This ID is unique for each entity.
function GetUnitById(id)
end

--- Retrieves all units in a rectangle, Excludes insignificant units, such as the Cybran Drone, by default.
-- @param rectangle The rectangle to look for units in {x0, z0, x1, z1}.
-- OR
-- @param tlx Top left x coordinate.
-- @param tlz Top left z coordinate.
-- @param brx Bottom right x coordinate.
-- @param brz Bottom right z coordinate.
-- @return nil if none found or a table.
function GetUnitsInRect(rectangle)
end

--- Returns true if the language for playing voices exists.
-- Available languages are in '/gamedata/loc'.
-- Game currently defaults on 'us' language if the localized voices don't exists.
-- @param language String of the language shortcut, example: 'us'.
function HasLocalizedVO(language)
end

--- Starts the AI on given army.
function InitializeArmyAI(strArmy)
end

--- Returns true if army2 is allied with army1.
-- @param army1 Army's index.
-- @param army2 Army's index.
function IsAlly(army1, army2)
end

--- TODO.
-- INFO: Blip = IsBlip(entity).
function IsBlip(entity)
end

--- TODO.
-- INFO: CollisionBeam = IsCollisionBeam(entity).
function IsCollisionBeam(entity)
end

--- Returns true if given command is finished.
-- @param cmd Unit's command crated for example by IssueMove().
function IsCommandDone(cmd)
end

--- Returns true if army2 is enemy to army1.
-- @param army1 Army's index.
-- @param army2 Army's index.
function IsEnemy(army1, army2)
end

--- Returns true if the given object is a Entity.
function IsEntity(object)
end

--- Return true if the game is over.
-- i.e. EndGame() has been called.
function IsGameOver()
end

--- Returns true if army2 is neutral to army1.
-- @param army1 Army's index.
-- @param army2 Army's index.
function IsNeutral(army1, army2)
end

--- Returns true if the target entity is a projectile.
function IsProjectile(entity)
end

--- Returns true if the target entity is a prop.
function IsProp(entity)
end

--- Returns true if the target entity is a unit.
function IsUnit(entity)
end

--- Order a group of units to attack move to target position.
---@param tblUnits Unit[]   # Units to issue the command to
---@param position Point    # Position to attack move to
---@return SimCommand       # Command that has been issued
function IssueAggressiveMove(tblUnits, position)
end

--- Order a group of units to attack a target
---@param tblUnits Unit[]   # Units to issue the command to
---@param target Unit       # Unit to attack
---@return SimCommand       # Command that has been issued
function IssueAttack(tblUnits, target)
end

--- Order a group of units to build a unit
---@param tblUnits Unit[]       # Units to issue the command to, usually factories
---@param blueprintID string    # BlueprintId of the unit to build
---@param count number          # Number of units to build
---@return SimCommand           # Command that has been issued
function IssueBuildFactory(tblUnits, blueprintID, count)
end

--- Order a group of units to build a unit, each unit is assigned the closest building
---@param tblUnits Unit[]       # Units to issue the command to, usually engineers
---@param position Point        # Position to build at
---@param blueprintID string    # BlueprintId of the unit to build
---@param table number          # A list of alternative build locations, similar to AiBrain.BuildStructure. Doesn't appear to function properly
---@return SimCommand           # Command that has been issued
function IssueBuildMobile(tblUnits, position, blueprintID, table)
end

--- Order a group of units to capture a target, usually engineers
---@param tblUnits Unit[]   # Units to issue the command to
---@param target Unit       # Unit to capture
---@return SimCommand       # Command that has been issued
function IssueCapture(tblUnits, target)
end

--- Clears out all commands issued on the group of units, this happens immediately
---@param tblUnits Unit[]   # Units to issue the command to
---@return SimCommand       # Command that has been issued
function IssueClearCommands(tblUnits)
end

--- Clears out all commands issued on the group of factories without affecting the build queue, allows you to change the rally point
---@param tblUnits Unit[]   # Units to issue the command to
---@return SimCommand       # Command that has been issued
function IssueClearFactoryCommands(tblUnits)
end

--- Order a group of units to destroy themselves, doesn't leave a wreckage
---@see                     # The global `IssueKillSelf` is for an alternative that does leave a wreckage
---@param tblUnits Unit[]   # Units to issue the command to
---@return SimCommand       # Command that has been issued
function IssueDestroySelf(tblUnits)
end

--- Order a group of units to dive
---@param tblUnits Unit[]   # Units to issue the command to
---@return SimCommand       # Command that has been issued
function IssueDive(tblUnits)
end

--- Order a group of factories to assist another factory
---@param tblUnits Unit[]   # Units to issue the command to
---@param target Unit       # Factory to assist
---@return SimCommand       # Command that has been issued
function IssueFactoryAssist(tblUnits, target)
end

--- Order a group of factories to set their rally point
---@param tblUnits Unit[]   # Units to issue the command to
---@param position Point    # Position to set the rally point
---@return SimCommand       # Command that has been issued
function IssueFactoryRallyPoint(tblUnits, position)
end

--- Order a group of units to setup a ferry
---@param tblUnits Unit[]   # Units to issue the command to
---@param position Point    # Position to add to the ferry route
---@return SimCommand       # Command that has been issued
function IssueFerry(tblUnits, position)
end

--- Order a group of units to attack move to a position in formation
--- @param tblUnits Unit[]              # Units to issue the command to
--- @param position Point               # Position to attack move to
--- @param formation UnitFormations     # Unit formation to use as defined in `formations.lua`
--- @param degrees number               # Orientation the platoon takes when it reaches the position. South is 0 degrees, east is 90 degrees, etc.
--- @return SimCommand                  # Command that has been issued
function IssueFormAggressiveMove(tblUnits, position, formation, degrees)
end

--- Order a group of units to attack a target in formation
--- @param tblUnits Unit[]              # Units to issue the command to
--- @param target Unit                  # Unit to attack
--- @param formation UnitFormations     # Unit formation to use as defined in `formations.lua`
--- @param degrees number               # Orientation the platoon takes when it reaches the position. South is 0 degrees, east is 90 degrees, etc.
--- @return SimCommand                  # Command that has been issued
function IssueFormAttack(tblUnits, target, formation, degrees)
end

--- Order a group of units to move to a position in formation
--- @param tblUnits Unit[]              # Units to issue the command to
--- @param position Point               # Position to move to
--- @param formation UnitFormations     # Unit formation to use as defined in `formations.lua`
--- @param degrees number               # Orientation the platoon takes when it reaches the position. South is 0 degrees, east is 90 degrees, etc.
--- @return SimCommand                  # Command that has been issued
function IssueFormMove(tblUnits, position, formation, degrees)
end

--- Order a group of units to patrol to a position in formation,
--- @param tblUnits Unit[]              # Units to issue the command to
--- @param position Point               # Position to add to the patrol
--- @param formation UnitFormations     # Unit formation to use as defined in `formations.lua`
--- @param degrees number               # Orientation the platoon takes when it reaches the position. South is 0 degrees, east is 90 degrees, etc.
--- @return SimCommand                  # Command that has been issued
function IssueFormPatrol(tblUnits, position, formation, degrees)
end

--- Order a group of units to guard a target
---@param tblUnits Unit[]   # Units to issue the command to
---@param target Unit       # Unit to guard
---@return SimCommand       # Command that has been issued
function IssueGuard(tblUnits, target)
end

--- Order a group of units to kill themselves
---@see                     # The global `IssueDestroySelf` is an alternative that does not leave a wreckage
---@param tblUnits Unit[]   # Units to issue the command to
---@return SimCommand       # Command that has been issued
function IssueKillSelf(tblUnits)
end

--- Order a group of units to move to a position
---@param tblUnits Unit[]   # Units to issue the command to
---@param position Point    # Position to move to
---@return SimCommand       # Command that has been issued
function IssueMove(tblUnits, position)
end

--- Order a group of units to move off a factory build site
---@param tblUnits Unit[]   # Units to issue the command to
---@param position Point    # Position to move to
---@return SimCommand       # Command that has been issued
function IssueMoveOffFactory(tblUnits, position)
end

--- Order a group of units to launch a strategic missile at a position
---@see                     # the function `IssueTactical` for tactical missiles
---@param tblUnits Unit[]   # Units to issue the command to
---@param position Point    # Position to launch to
---@return SimCommand       # Command that has been issued
function IssueNuke(tblUnits, position)
end

--- Order a group of units to use Overcharge at a target
---@param tblUnits Unit[]   # Units to issue the command to
---@param target Unit       # Unit to overcharge
---@return SimCommand       # Command that has been issued
function IssueOverCharge(tblUnits, target)
end

--- Order a group of units to patrol to a position
---@param tblUnits Unit[]   # Units to issue the command to
---@param position Point    # Position to add to the patrol
---@return SimCommand       # Command that has been issued
function IssuePatrol(tblUnits, position)
end

--- Order a unit to pause, this happens immediately
---@param unit Unit         # Units to pause
function IssuePause(unit)
end

--- Order a group of units to reclaim a target
---@param tblUnits Unit[]       # Units to issue the command to
---@param target Unit | Prop    # Prop or unit to reclaim
---@return SimCommand           # Command that has been issued
function IssueReclaim(tblUnits, target)
end

--- Order a group of units to repair a target
---@param tblUnits Unit[]       # Units to issue the command to
---@param target Unit           # Unit to repair
---@return SimCommand           # Command that has been issued
function IssueRepair(tblUnits, target)
end

--- Order a group of units to sacrifice, sharing their resources to a target
---@param tblUnits Unit[]       # Units to issue the command to
---@param target Unit           # Unit to share the resources with
---@return SimCommand           # Command that has been issued
function IssueSacrifice(tblUnits, target)
end

--- Order a group of units to run a script sequence, as an example: { TaskName = "EnhanceTask", Enhancement = "AdvancedEngineering" }
---@param tblUnits Unit[]       # Units to issue the command to
---@param order table           # Task / order to apply
---@return SimCommand           # Command that has been issued
function IssueScript(tblUnits, order)
end

--- Order a group of units to build a nuke
---@param tblUnits Unit[]       # Units to issue the command to, usually strategic missile launchers / defense
---@return SimCommand           # Command that has been issued
function IssueSiloBuildNuke(tblUnits)
end

--- Order a group of units to build a tactical missile
---@param tblUnits Unit[]       # Units to issue the command to, usually tactical missile launchers
---@return SimCommand           # Command that has been issued
function IssueSiloBuildTactical()
end

--- Order a group of units to stop, this happens immediately
---@param tblUnits Unit[]       # Units to issue the command to
function IssueStop(tblUnits)
end

--- Order a group of units to launch a tactical missile
---@see                         # the function `IssueNuke` for strategical missiles
---@param tblUnits Unit[]       # Units to issue the command to
---@param target Unit | Point   # Unit or point to launch at
---@return SimCommand           # Command that has been issued
function IssueTactical(tblUnits, target)
end

--- Order a group of units to teleport to a position
---@param tblUnits Unit[]       # Units to issue the command to
---@param position Point        # Position to teleport to
---@return SimCommand           # Command that has been issued
function IssueTeleport(tblUnits, position)
end

--- TODO.
function IssueTeleportToBeacon()
end

--- Order a group of units to attach themselves to a transport
---@param tblUnits Unit[]       # Units to issue the command to
---@param transport Unit        # Transport to be loaded
---@return SimCommand           # Command that has been issued
function IssueTransportLoad(tblUnits, transport)
end

--- Order a group of transports to unload their cargo at a position
---@param tblUnits Unit[]       # Units to issue the command to
---@param position Point        # Position to unload
---@return SimCommand           # Command that has been issued
function IssueTransportUnload(tblUnits, position)
end

--- Orders group of transports (carriers) to drop specific units at target position.
-- This seems to work only with carriers and not with air transports.
-- @param tblUnits Table containing transports (carriers).
-- @param category Unit category (categories.BOMBER).
-- @param position Table with position {x, y, z}.
-- @return Returns the issued command.

--- Order a group of transports or carriers to unload specific units, appears to work only for carriers
---@param tblUnits Unit[]       # Units to issue the command to
---@param position Point        # Position to unload
---@param category Categories   # Unit types to unload
---@return SimCommand           # Command that has been issued
function IssueTransportUnloadSpecific(tblUnits, category, position)
end

--- Order a group of units to upgrade
---@param tblUnits Unit[]       # Units to issue the command to
---@param blueprintID string    # BlueprintId of unit to upgrade to
---@return SimCommand           # Command that has been issued
function IssueUpgrade(tblUnits, blueprintID)
end

--- TODO.
-- INFO: ScriptTask.LUnitMove(self, target)
function LUnitMove(self, target)
end

--- TODO.
-- INFO: ScriptTask.LUnitMoveNear(self,target,range)
function LUnitMoveNear(self, target, range)
end

--- List all armies in the game.
-- @return Table containing strings of army names.
function ListArmies()
end

--- TODO.
---@deprecated
function MetaImpact(instigator, location, fMaxRadius, iAmount, affectsCategory, damageFriendly)
end

--- TODO.
function NotifyUpgrade(from, to)
end

--- Return true if the current command source is authorized to mess with the given army.
-- Or if cheats are enabled.
-- TODO.
function OkayToMessWithArmy()
end

--- Parse a string to generate a new entity category.
-- @param strCategory Example: 'ual0101'.
-- @return Returns generated category, example: categories.ual0101 .
function ParseEntityCategory(strCategory)
end

--- TODO.
-- INFO: handle = PlayLoop(self,sndParams)
function PlayLoop(self, sndParams)
end

--- TODO.
-- INFO: Random([[min,] max])
function Random()
end

--- Unrestrict the army from building the unit category.
-- The categories can be combined using + - * (), example: (categories.TECH3 * categories:NAVAL) + categories.urb0202.
-- @param army Army's index.
-- @param category Unit category.
function RemoveBuildRestriction(army, category)
end

--- Removes economy event created by CreateEconomyEvent function from the unit.
-- @param unit Unit to remove the event from.
-- @param event Event to remove.
function RemoveEconomyEvent(unit, event)
end

--- Returns the currently selected unit. For use at the lua console, so you can call Lua methods on a unit.
-- Example: unit = SelectedUnit().
function SelectedUnit()
end

--- Set alliances between 2 armies.
-- @param army1 Army's index.
-- @param army2 Army's index.
-- @param alliance Can be 'Neutral', 'Enemy', 'Ally'.
function SetAlliance(army1, army2, alliance)
end

--- Set alliances from army1 to army2.
-- @param army1 Army's index.
-- @param army2 Army's index.
-- @param alliance Can be 'Neutral', 'Enemy', 'Ally'.
function SetAllianceOneWay(army1, army2, alliance)
end

--- TODO.
function SetAlliedVictory()
end

--- TODO.
-- @param army Army's index.
-- @param personality TODO.
function SetArmyAIPersonality(army, personality)
end

--- Set army's color using RGB values.
-- @param army Army's index.
-- @param r Number 0-255.
-- @param g Number 0-255.
-- @param b Number 0-255.
function SetArmyColor(army, r, g, b)
end

--- TODO.
-- @param army Army's index.
function SetArmyColorIndex(army, index)
end

--- Gives mass and energy to the army.
-- TODO: Find out if this is in any way special than brain:GiveResource().
-- @param army Army's index.
-- @param mass Amount of mass to give.
-- @param energy Amount of energy to give.
function SetArmyEconomy(army, mass, energy)
end

--- Sets faction for the given army.
-- 0 - UEF, 1 - Aeon, 2 - Cybran, 3 - Seraphim.
-- @param army Army's index.
-- @param index Faction index.
function SetArmyFactionIndex(army, index)
end

--- Indicate that the supplied army has been defeated.
-- @param army Army's index.
function SetArmyOutOfGame(army)
end

--- TODO.
function SetArmyPlans(army, plans)
end

--- Determines if the user should be able to see the army score.
-- @param army Army's index.
-- @param bool true/false.
function SetArmyShowScore(army, bool)
end

--- Set the arty starting position.
-- Position where the initial unit will be spawned.
-- @param army Army's index.
-- @param x Position on the map on X axis.
-- @param x Position on the map on Z axis.
function SetArmyStart(army, x, z)
end

--- Set the army index for which to sync army stats (-1 for none) .
-- TODO
function SetArmyStatsSyncArmy()
end

--- Sets maximum number of units army can build.
-- @param army Army's index.
-- @param unitCap Number, the new unit cap.
function SetArmyUnitCap(army, unitCap)
end

--- Sets army to ignore max unit capacity.
-- @param army Army's index.
-- @param flag true/false.
function SetIgnoreArmyUnitCap(army, flag)
end

--- Sets army to ignore playable reclangle.
-- Units can move outside of restricted area.
-- Used in campaign for offmap attacks.
-- @param army Army's index.
-- @param flag true/false
function SetIgnorePlayableRect(army, flag)
end

--- Set playable rectangle.
function SetPlayableRect(minX, minZ, maxX, maxZ)
end

--- Changes terrain type at given position.
-- @param x Position on x axis.
-- @param z Position on z axis.
-- @param type Terrain type to change to.
function SetTerrainType(x, z, type)
end

--- Changes terrain type in given rectangle.
-- @paran rect Map area created by function Rect(x0, z0, x1, z1).
-- @param type Terrain type to change to.
function SetTerrainTypeRect(rect, type)
end

--- TODO.
function ShouldCreateInitialArmyUnits()
end

--- Perform a console command.
-- SimConExecute('command string').
function SimConExecute(commandString)
end

--- Split a prop into multiple child props, one per bone.
-- Used for breaking up tree groups at colision.
-- @param original Prop to split
-- @param blueprint_name BP name of the new props to spawn at each bone of the original prop.
-- @return Returns all the created props.
function SplitProp(original, blueprint_name)
end

--- TODO.
function StopLoop(self, handle)
end

--- Request that we submit xml army stats to gpg.net.
-- TODO.
function SubmitXMLArmyStats()
end

--- Attempt to copy animation pose from the unit to the prop.
-- Only works if the mesh and skeletons are the same, but will not produce an error if not.
-- @param unitFrom Unit to copy pose from.
-- @param entityTo Entity (prop) to copy pose on.
-- @param bCopyWorldTransform true/false.
function TryCopyPose(unitFrom, entityTo, bCopyWorldTransform)
end

--- Instanly moves entity to target location.
-- @param entity Entity to teleport.
-- @param location Table with position {x, y, z}.
-- @param orientation Target orientation, optimal parameter.
function Warp(entity, location, orientation)
end

--- TODO.
---@diagnostic disable-next-line: lowercase-global
function _c_CreateEntity(spec)
end

--- TODO.
---@diagnostic disable-next-line: lowercase-global
function _c_CreateShield(spec)
end

--- Print a log message
-- TODO
function print()
end

---
--  derived from Entity
function base()
end


--- Sinks the entity into the ground.
-- Used for dead trees for example.
-- @param vy Velocity at Y axis.
function SinkAway(vy)
end


------
-- New functions from engine patch:
------

-- Returns list of deposits
-- Type: 0 - All, 1 - Mass, 2 - Energy
-- Result: {{X1,X2,Z1,Z2,Type,Dist},...}
function GetDepositsAroundPoint(X, Z, Radius, Type)
end

-- Returns true if the active session is a replay
-- Same as user SessionIsReplay.
function SessionIsReplay()
end

-- Allows set the rights to the army
-- targetArmyIndex, sourceHumanIndex is 0 based index
-- Nothing returns
---@param targetArmyIndex any
---@param sourceHumanIndex any
---@param enable boolean
function SetCommandSource(targetArmyIndex, sourceHumanIndex, enable)
end

-- Sets the focus without checking rights
---@param armyIndex number is 0 based index or -1
-- Nothing returns
function SetFocusArmy(armyIndex)
end
