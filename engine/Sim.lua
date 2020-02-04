---Module: Sim
-- @module Sim

--- Restrict the army from building the unit category.
-- The categories can be combined using + - * (), example: (categories.TECH3 * categories:NAVAL) + categories.urb0202.
-- @param army Army's index.
-- @param category Unit category.
function AddBuildRestriction(army, category)
end

--- TODO.
-- @param army Army's index.
function ArmyGetHandicap(army)
end

--- TODO.
-- @param army Army's index.
function ArmyInitializePrebuiltUnits(army)
end

--- Return true if the indicated army is civilian.
-- @param army Army's index.
function ArmyIsCivilian(army)
end

--- Return true if the indicated army has been defeated.
-- @param army Army's index.
function ArmyIsOutOfGame(army)
end

--- TODO.
function AttachBeamEntityToEntity(self, bone, other, bone, army, blueprint)
end

--- TODO.
-- @param army Army's index.
function AttachBeamToEntity(emitter, entity, tobone, army)
end

--- Sets language for playing voices.
-- Available languages are in '/gamedata/loc'.
-- Game currently defaults on 'us' language if the localized voices don't exists.
-- @param language String of the language shortcut, example: 'us'.
function AudioSetLanguage(language)
end

--- Change a unit's army, return the new unit.
-- @param unit Unit to be given.
-- @param army Army's index to recieve the unit.
function ChangeUnitArmy(unit, army)
end

--- Return true if cheats are enabled.
-- Logs the cheat attempt no matter what.
function CheatsEnabled()
end

--- TODO.
function CoordinateAttacks()
end

--- TODO.
function CreateAimController(weapon, label, turretBone, [barrelBone], [muzzleBone])
end

--- Create a manipulator for playing animations.
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
function CreateBuilderArmController(unit,turretBone, [barrelBone], [aimBone])
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
function CreateFootPlantController(unit, footBone, kneeBone, hipBone, [straightLegs], [maxFootFall])
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
-- @param unit Unit to create the manipulator for.
-- @param bone String, name of the bone to rotate.
-- @param axis String, 'x', 'Y' or 'z', axis to rotate around.
-- @param [goal] TODO.
-- @param [speed] TODO.
-- @param [accel] TODO.
-- @param [goalspeed] TODO.
-- @return manipulator
function CreateRotator(unit, bone, axis, [goal], [speed], [accel], [goalspeed])
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
function CreateUnit(blueprint, army, tx, ty, tz, qx, qy, qz, qw, [layer])
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
-- @param instigator Source of the damage (unit) or nil.
-- @param location Table with position {x, y, z}.
-- @param radius Number, distance from the location to deal the damage.
-- @param amount Number, amount of damage.
-- @param damageType Example: 'Force', 'Normal', 'Nuke', 'Fire', TODO.
-- @param damageFriendly true/false if it should damage allied units.
-- @param [damageSelf] true/false if the unit dealing the damage should take it as well.
function DamageArea(instigator, location, radius, amount, damageType, damageFriendly, [damageSelf])
end

--- Deals damage to the target unit.
-- @param instigator Source of the damage (unit) or nil.
-- @param location Table with position {x, y, z}.
-- @param minRadius Number, distance from the location to start dealing damage.
-- @param maxRadius Number, distance from the location to stop dealing damage.
-- @param amount Number, amount of damage.
-- @param damageType Example: 'Force', 'Normal', 'Nuke', 'Fire', TODO.
-- @param damageFriendly true/false if it should damage allied units.
-- @param [damageSelf] true/false if the unit dealing the damage should take it as well.
function DamageRing(instigator, location, minRadius, maxRadius, amount, damageType, damageFriendly, [damageSelf])
end

--- Get DEBUG info for UI selection.
-- TODO.
function DebugGetSelection()
end

--- Draw a 3d circle at a with size s and color c.
-- TODO.
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
-- @param x Position on x axis.
-- @param z Position on x axis.
function GetSurfaceHeight(x z)
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
function GetTerrainHeight(x z)
end

--- Returns terrain type at given position.
-- INFO: type = GetTerrainType(x,z).
-- @param x Position on x axis.
-- @param z Position on z axis.
function GetTerrainType(x z)
end

--- TODO.
-- INFO: type = GetTerrainTypeOffset(x,z).
function GetTerrainTypeOffset(x z)
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

--- Return a table with units inside the given rectangle.
-- @param rectangle Map area created by function Rect(x0, z0, x1, z1).
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

--- Orders group of units to attack move to target position.
-- @param tblUnits Table containing units, same as group of units.
-- @param position Table with position {x, y, z}.
-- @return Returns the issued command.
function IssueAggressiveMove(tblUnits, position)
end

--- Orders group of units to attack the target unit.
-- @param tblUnits Table containing units, same as group of units.
-- @param target Unit to attack.
-- @return Returns the issued command.
function IssueAttack(tblUnits, target)
end

--- Orders a group of factories to build units.
-- Works on mobile factories like Fatboy as well.
-- @param tblUnits Table containing factories.
-- @param blueprintID ID of the unit to build, example: 'uel0103'.
-- @param count How many units to build.
-- @return Returns the issued command.
function IssueBuildFactory(tblUnits, blueprintID, count)
end

--- Orders a group of engineers to build a unit at target position.
-- Example: IssueBuildMobile({builder}, Vector(pos.x, pos.y, pos.z-2), msid, {}).
-- @param tblUnits Table containing engineers.
-- @param position Table with position {x, y, z}.
-- @param blueprintID ID of the unit to build, example: 'ueb0103'.
-- @param table (Two element table - TODO: find out what it is) or empty table.
-- @return Returns the issued command.
function IssueBuildMobile(tblUnits, position, blueprintID, table)
end

--- Orders a group of engineers to capture the target unit.
-- @param tblUnits Table containing engineers.
-- @param target Unit to capture.
-- @return Returns the issued command.
function IssueCapture(tblUnits, target)
end

--- Clears all commands of given units.
-- That includes build queue as well.
-- @param tblUnits Table containing units.
function IssueClearCommands(tblUnits)
end

--- Clears factory command without affecting current build queue.
-- Used to change rally point while the factories are building units.
-- @param tblUnits Table containing factories.
function IssueClearFactoryCommands(tblUnits)
end

--- Orders unit to destroy itself.
-- This doesn't leave wreckage.
-- @param tblUnits Table containing units.
function IssueDestroySelf(tblUnits)
end

--- Orders a group of unit to dive.
-- Surfaces the unit if they are already under water.
-- @param tblUnits Table containing units.
function IssueDive(tblUnits)
end

--- Orders a group of factories to assisnt a target factory.
-- @param tblUnits Table containing factories.
-- @param target Factory to assist.
-- @return Returns the issued command.
function IssueFactoryAssist(tblUnits, target)
end

--- Sets a factory rally point.
-- Doesn't remove the current one, use IssueClearCommands for that.
-- @param position Table with position {x, y, z}.
function IssueFactoryRallyPoint(tblUnits, position)
end

--- TODO.
function IssueFerry(tblUnits, position)
end

--- Orders group of units to attack move in formation to target position.
-- @param tblUnits Table containing units.
-- @param position Table with position {x, y, z}.
-- @param formation Formation to use, 'AttackFormation', 'GrowthFormation'.
-- @param number Unknown TODO.
-- @return Returns the issued command.
function IssueFormAggressiveMove(tblUnits, position, formation, number)
end

--- Orders group of units to attack the target unit.
-- Moves to the unit in a formation.
-- @param tblUnits Table containing units.
-- @param target Unit to attack.
-- @param formation Formation to use, 'AttackFormation', 'GrowthFormation'.
-- @param number Unknown TODO.
-- @return Returns the issued command.
function IssueFormAttack(tblUnits, target, formation, number)
end

--- Oders group of units to move in formation to target position.
-- @param tblUnits Table containing units.
-- @param position Table with position {x, y, z}.
-- @param formation Formation to use, 'AttackFormation', 'GrowthFormation'.
-- @param number Unknown TODO.
-- @return Returns the issued command.
function IssueFormMove(tblUnits, position, formation, number)
end

--- Oders group of units to patrol in formation on target position.
-- Call this at least twice for two different positions to have any meaning.
-- @param tblUnits Table containing units.
-- @param position Table with position {x, y, z}.
-- @param formation Formation to use, 'AttackFormation', 'GrowthFormation'.
-- @param number Unknown TODO.
-- @return Returns the issued command.
function IssueFormPatrol(tblUnits, position, formation, number)
end

--- Orders group of unit to assist the target unit.
-- @param tblUnits Table containing units.
-- @param target Unit to assist.
-- @return Returns the issued command.
function IssueGuard(tblUnits, target)
end

--- Orders group of units to self-destruct.
-- Thisl leaves wreckages.
-- @param tblUnits Table containing units.
function IssueKillSelf(tblUnits)
end

--- Oders group of units to move to target position.
-- @param tblUnits Table containing units.
-- @param position Table with position {x, y, z}.
-- @return Returns the issued command.
function IssueMove(tblUnits, position)
end

--- Orders group of units to move off factory.
-- This is used to move units out of factories when they are finished.
-- @param tblUnits Table containing units.
-- @param position Table with position {x, y, z}.
-- @return Returns the issued command.
function IssueMoveOffFactory(tblUnits, position)
end

--- Launches a nuke at target position.
-- @param tblUnits Table containing Nuke Launchers.
-- @param position Table with position {x, y, z}.
-- @return Returns the issued command.
function IssueNuke(tblUnits, position)
end

--- Orders unit to fire OverCharge weapon at the target.
-- @param tblUnits Table containing units.
-- @param target Unit to OC.
function IssueOverCharge(tblUnits, target)
end

--- Oders group of units to patrol on target position.
-- Call this at least twice for two different positions to have any meaning.
-- @param tblUnits Table containing units.
-- @param position Table with position {x, y, z}.
-- @return Returns the issued command.
function IssuePatrol(tblUnits, position)
end

--- Pauses the unit.
-- @param unit Unit to pause.
function IssuePause(unit)
end

--- Orders group of units to reclaim the target entity.
-- @param tblUnits Table containing units.
-- @param target Unit or prop to reclaim.
-- @return Returns the issued command.
function IssueReclaim(tblUnits, target)
end

--- Orders group of units to repair the target unit.
-- @param tblUnits Table containing units.
-- @param target Unit to repair.
-- @return Returns the issued command.
function IssueRepair(tblUnits, target)
end

--- Orders group of unit to use Sacrifice on target unit.
-- @param tblUnits Table containing units that can use sacrifice.
-- @param target Unit to to sacrifice into.
-- TODO This is untested.
-- @return Returns the issued command.
function IssueSacrifice(tblUnits, target)
end

--- Orders group of unit to do scripted task.
-- Currently used for ACU/sACU upgrading. Valid enhancement names are in the unut's blueprint or here http://wiki.faforever.com/index.php?title=Mission_Scripting#Enhancements .
-- @param tblUnits Table containing units.
-- @param oder Working format example: {TaskName = "EnhanceTask", Enhancement = "AdvancedEngineering"}.
-- @return Returns the issued command.
function IssueScript(tblUnits, order)
end

--- TODO.
function IssueSiloBuildNuke()
end

--- TODO.
function IssueSiloBuildTactical()
end

--- Order group of units to stop.
-- @param tblUnits Table containing units.
function IssueStop(tblUnits)
end

--- Orders group of units to fire a tactical missile at target or location.
-- @param tblUnits Table containing missle launchers.
-- @param target Unit to fire at or table with position {x, y, z}.
-- @return Returns the issued command.
function IssueTactical(tblUnits, target)
end

--- Orders group of units to teleport to target position.
-- @param tblUnits Table containing units.
-- @param position Table with position {x, y, z}.
-- @return Returns the issued command.
function IssueTeleport(tblUnits, position)
end

--- TODO.
function IssueTeleportToBeacon()
end

--- Orders group of units to load into the transport.
-- @param tblUnits Table containing units.
-- @param transport Transport unit to load into.
-- @return Returns the issued command.
function IssueTransportLoad(tblUnits, transport)
end

--- Orders group of transports to drop units at target position.
-- @param tblUnits Table containing transports.
-- @param position Table with position {x, y, z}.
-- @return Returns the issued command.
function IssueTransportUnload(tblUnits, position)
end

--- Orders group of transports (carriers) to drop specific units at target position.
-- This seems to work only with carriers and not with air transports.
-- @param tblUnits Table containing transports (carriers).
-- @param category Unit category (categories.BOMBER).
-- @param position Table with position {x, y, z}.
-- @return Returns the issued command.
function IssueTransportUnloadSpecific(tblUnits, category, position)
end

--- Orders group of units to upgrade.
-- Used for factories, radars, etc.
-- @param tblUnits Table containing units.
-- @param blueprintID ID of the blueprint to upgrade to.
-- @return Returns the issued command.
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
function MetaImpact(instigator, location, fMaxRadius, iAmount, affectsCategory, [damageFriendly])
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
function _c_CreateEntity(spec)
end

--- TODO.
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

---
--
function moho.CollisionBeamEntity()
end

--- Sinks the entity into the ground.
-- Used for dead trees for example.
-- @param vy Velocity at Y axis.
function SinkAway(vy)
end

---
--
function moho.entity_methods()
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
-- Nothing returns
function SetCommandSource(targetArmyIndex, sourceHumanIndex, Set or Unset)
end

-- Sets the focus without checking rights
-- Nothing returns
function SetFocusArmy(armyIndex or -1)
end