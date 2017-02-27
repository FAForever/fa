---Module: Sim
-- @module Sim

---
--  AddBuildRestriction(army,category) - Add a category to the restricted list
function AddBuildRestriction(army, category)
end

---
--  army
function ArmyGetHandicap()
end

---
--  army
function ArmyInitializePrebuiltUnits()
end

---
--  ArmyIsCivilian(army)
function ArmyIsCivilian(army)
end

---
--  ArmyIsOutOfGame(army) -- return true iff the indicated army has been defeated.
function ArmyIsOutOfGame(army)
end

---
--  AttachBeamEntityToEntity(self, bone, other, bone, army, blueprint)
function AttachBeamEntityToEntity(self,  bone,  other,  bone,  army,  blueprint)
end

---
--  AttachBeamToEntity(emitter, entity, tobone, army )
function AttachBeamToEntity(emitter,  entity,  tobone,  army)
end

---
--  AudioSetLanguage(name)
function AudioSetLanguage(name)
end

---
--  ChangeUnitArmy(unit,armyIndex) Change a unit's army
function ChangeUnitArmy(unit, armyIndex)
end

---
--  Return true iff cheats are enabledLogs the cheat attempt no matter what.
function CheatsEnabled()
end

---
--  CoordinateAttacks
function CoordinateAttacks()
end

---
--  CreateAimController(weapon, label, turretBone, [barrelBone], [muzzleBone])
function CreateAimController(weapon,  label,  turretBone,  [barrelBone],  [muzzleBone])
end

---
--  CreateAnimator(unit) -- create a manipulator for playing animations
function CreateAnimator(unit)
end

---
--  CreateAttachedBeam(entity, bone, army, length, thickness, texture_filename)
function CreateAttachedBeam(entity,  bone,  army,  length,  thickness,  texture_filename)
end

---
--  CreateAttachedEmitter(entity, bone, army, emitter_blueprint)
function CreateAttachedEmitter(entity,  bone,  army,  emitter_blueprint)
end

---
--  emitter = CreateBeamEmitter(blueprint,army)
function CreateBeamEmitter(blueprint, army)
end

---
--  emitter = CreateBeamEmitterOnEntity(entity, tobone, army, blueprint )
function CreateBeamEmitterOnEntity(entity,  tobone,  army,  blueprint)
end

---
--  CreateBeamEntityToEntity(entity, bone, other, bone, army, blueprint)
function CreateBeamEntityToEntity(entity,  bone,  other,  bone,  army,  blueprint)
end

---
--  CreateBeamToEntityBone(entity, bone, other, bone, army, thickness, texture_filename)
function CreateBeamToEntityBone(entity,  bone,  other,  bone,  army,  thickness,  texture_filename)
end

---
--  CreateBuilderArmController(unit,turretBone, [barrelBone], [aimBone])
function CreateBuilderArmController(unit, turretBone,  [barrelBone],  [aimBone])
end

---
--  CreateCollisionDetector(unit) -- create a collision detection manipulator
function CreateCollisionDetector(unit)
end

---
--  handle = CreateDecal(position, heading, textureName1, textureName2, type, sizeX, sizeZ, lodParam, duration, army, fidelity)
function CreateDecal(position,  heading,  textureName1,  textureName2,  type,  sizeX,  sizeZ,  lodParam,  duration,  army,  fidelity)
end

---
--  event = CreateEconomyEvent(unit, energy, mass, timeInSeconds)
function CreateEconomyEvent(unit,  energy,  mass,  timeInSeconds)
end

---
--  CreateEmitterAtBone(entity, bone, army, emitter_blueprint)
function CreateEmitterAtBone(entity,  bone,  army,  emitter_blueprint)
end

---
--  CreateEmitterAtEntity(entity,army,emitter_bp_name)
function CreateEmitterAtEntity(entity, army, emitter_bp_name)
end

---
--  CreateEmitterOnEntity(entity,army,emitter_bp_name)
function CreateEmitterOnEntity(entity, army, emitter_bp_name)
end

---
--  CreateFootPlantController(unit, footBone, kneeBone, hipBone, [straightLegs], [maxFootFall])
function CreateFootPlantController(unit,  footBone,  kneeBone,  hipBone,  [straightLegs],  [maxFootFall])
end

---
--  CreateInitialArmyUnit(armyName, initialUnitName
function CreateInitialArmyUnit()
end

---
--  CreateLightParticle(entity, bone, army, size, lifetime, textureName, rampName)
function CreateLightParticle(entity,  bone,  army,  size,  lifetime,  textureName,  rampName)
end

---
--  CreateLightParticle(entity, bone, army, size, lifetime, textureName, rampName)
function CreateLightParticleIntel()
end

---
--  CreateProp(location,prop_blueprint_id)
function CreateProp(location, prop_blueprint_id)
end

---
--  blueprint, x, y, z, heading, pitch, roll
function CreatePropHPR()
end

---
--  type, x, y, z, size
function CreateResourceDeposit()
end

---
--  manip = CreateRotator(unit, bone, axis, [goal], [speed], [accel], [goalspeed])
function CreateRotator(unit,  bone,  axis,  [goal],  [speed],  [accel],  [goalspeed])
end

---
--  manip = CreateSlaver(unit, dest_bone, src_bone)Create a manipulator which copies the motion of src_bone onto dst_bone.Priority matters! Only manipulators which come before the slave manipulator will be copied.
function CreateSlaver(unit,  dest_bone,  src_bone)
end

---
--  CreateSlider(unit, bone, [goal_x, goal_y, goal_z, [speed, [world_space]]])
function CreateSlider(unit,  bone,  [goal_x,  goal_y,  goal_z,  [speed,  [world_space]]])
end

---
--  CreateSplat(position, heading, textureName, sizeX, sizeZ, lodParam, duration, army, fidelity)
function CreateSplat(position,  heading,  textureName,  sizeX,  sizeZ,  lodParam,  duration,  army,  fidelity)
end

---
--  CreateSplatOnBone(boneName, offset, textureName, sizeX, sizeZ, lodParam, duration, army)Add a splat to the game at an entity bone position and heading.
function CreateSplatOnBone(boneName,  offset,  textureName,  sizeX,  sizeZ,  lodParam,  duration,  army)
end

---
--  CreateStorageManip(unit, bone, resouceName, minX, minY, minZ, maxX, maxY, maxZ)
function CreateStorageManip(unit,  bone,  resouceName,  minX,  minY,  minZ,  maxX,  maxY,  maxZ)
end

---
--  CreateThrustController(unit, label, thrustBone)
function CreateThrustController(unit,  label,  thrustBone)
end

---
--  CreateTrail(entity, bone, army, trail_blueprint)
function CreateTrail(entity,  bone,  army,  trail_blueprint)
end

---
--  blueprint, army, tx, ty, tz, qx, qy, qz, qw, [layer]
function CreateUnit()
end

---
--  blueprint, army, layer, x, z, heading
function CreateUnit2()
end

---
--  blueprint, army, x, y, z, pitch, yaw, roll
function CreateUnitHPR()
end

---
--  Damage(instigator, target, amount, damageType)
function Damage(instigator,  target,  amount,  damageType)
end

---
--  DamageArea(instigator,location,radius,amount,damageType,damageFriendly,[damageSelf])
function DamageArea(instigator, location, radius, amount, damageType, damageFriendly, [damageSelf])
end

---
--  DamageRing(instigator,location,minRadius,maxRadius,amount,damageType,damageFriendly,[damageSelf])
function DamageRing(instigator, location, minRadius, maxRadius, amount, damageType, damageFriendly, [damageSelf])
end

---
--  Get DEBUG info for UI selection
function DebugGetSelection()
end

---
--  Draw a 3d circle at a with size s and color c
function DrawCircle()
end

---
--  Draw a 3d line from a to b with color c
function DrawLine()
end

---
--  Draw a 3d line from a to b with color c with a circle at the end of the target line
function DrawLinePop()
end

---
--  bool = EconomyEventIsDone(event)
function EconomyEventIsDone(event)
end

---
--  Signal the end of the game.:Acts like a permanent pause.
function EndGame()
end

---
--  See if a unit category contains this unit
function EntityCategoryContains()
end

---
--  Count how many units fit the specified category
function EntityCategoryCount()
end

---
--  Count how many units fit the specified category around a position
function EntityCategoryCountAroundPosition()
end

---
--  Filter a list of units to only those found in the category
function EntityCategoryFilterDown()
end

---
--  FlattenRect(x, z, sizex, sizez, elevation)
function FlattenMapRect()
end

---
--  FlushIntelInRect( minX, minZ, maxX, maxZ )
function FlushIntelInRect(minX,  minZ,  maxX,  maxZ)
end

---
--  army
function GenerateArmyStart()
end

---
--  rotation = GenerateRandomOrientation()
function GenerateRandomOrientation()
end

---
--  army
function GetArmyBrain()
end

---
--  army
function GetArmyUnitCap()
end

---
--  army
function GetArmyUnitCostTotal()
end

---
--  blueprint = GetBlueprint(entity)
function GetBlueprint(entity)
end

---
--  Return the (1 based) index of the current command source.
function GetCurrentCommandSource()
end

---
--  Return the enitities inside the given rectangle
function GetEntitiesInRect()
end

---
--  Get entity by entity id
function GetEntityById()
end

---
--  GetFocusArmy()
function GetFocusArmy()
end

---
--  Get the current game time in ticks. The game time is the simulation time, that stops when the game is paused.
function GetGameTick()
end

---
--  Get the current game time in seconds. The game time is the simulation time, that stops when the game is paused.
function GetGameTimeSeconds()
end

---
--  sizeX, sizeZ = GetMapSize()
function GetMapSize()
end

---
--  Return the reclamable things inside the given rectangle
function GetReclaimablesInRect()
end

---
--  type = GetSurfaceHeight(x,z)
function GetSurfaceHeight(x, z)
end

---
--  float GetSystemTimeSecondsOnlyForProfileUse() - returns System time in seconds
function GetSystemTimeSecondsOnlyForProfileUse()
end

---
--  type = GetTerrainHeight(x,z)
function GetTerrainHeight(x, z)
end

---
--  type = GetTerrainType(x,z)
function GetTerrainType(x, z)
end

---
--  type = GetTerrainTypeOffset(x,z)
function GetTerrainTypeOffset(x, z)
end

---
--  blueprint = GetUnitBlueprintByName(bpName)
function GetUnitBlueprintByName(bpName)
end

---
--  Get entity by entity id
function GetUnitById()
end

---
--  Return the units inside the given rectangle
function GetUnitsInRect()
end

---
--  HasLocalizedVO(language)
function HasLocalizedVO(language)
end

---
--  army
function InitializeArmyAI()
end

---
--  IsAlly(army1,army2)
function IsAlly(army1, army2)
end

---
--  Blip = IsBlip(entity)
function IsBlip(entity)
end

---
--  CollisionBeam = IsCollisionBeam(entity)
function IsCollisionBeam(entity)
end

---
--  IsCommandDone
function IsCommandDone()
end

---
--  IsEnemy(army1,army2)
function IsEnemy(army1, army2)
end

---
--  bool = IsEntity(object)
function IsEntity(object)
end

---
--  Return true if the game is over (i.e. EndGame() has been called).
function IsGameOver()
end

---
--  IsNeutral(army1,army2)
function IsNeutral(army1, army2)
end

---
--  Projectile = IsProjectile(entity)
function IsProjectile(entity)
end

---
--  Prop = IsProp(entity)
function IsProp(entity)
end

---
--  Unit = IsUnit(entity)
function IsUnit(entity)
end

---
--  IssueAggressiveMove
function IssueAggressiveMove()
end

---
--  IssueAttack
function IssueAttack()
end

---
--  IssueBuildFactory
function IssueBuildFactory()
end

---
--  IssueBuildMobile
function IssueBuildMobile()
end

---
--  IssueCapture
function IssueCapture()
end

---
--  IssueClearCommands
function IssueClearCommands()
end

---
--  IssueClearFactoryCommands
function IssueClearFactoryCommands()
end

---
--  IssueDestroySelf
function IssueDestroySelf()
end

---
--  IssueDive
function IssueDive()
end

---
--  IssueFactoryAssist
function IssueFactoryAssist()
end

---
--  IssueFactoryRallyPoint
function IssueFactoryRallyPoint()
end

---
--  IssueFerry
function IssueFerry()
end

---
--  IssueFormAggressiveMove
function IssueFormAggressiveMove()
end

---
--  IssueFormAttack
function IssueFormAttack()
end

---
--  IssueFormMove
function IssueFormMove()
end

---
--  IssueFormPatrol
function IssueFormPatrol()
end

---
--  IssueGuard
function IssueGuard()
end

---
--  IssueKillSelf
function IssueKillSelf()
end

---
--  IssueMove
function IssueMove()
end

---
--  IssueMoveOffFactory
function IssueMoveOffFactory()
end

---
--  IssueNuke
function IssueNuke()
end

---
--  IssueOverCharge
function IssueOverCharge()
end

---
--  IssuePatrol
function IssuePatrol()
end

---
--  IssuePause
function IssuePause()
end

---
--  IssueReclaim
function IssueReclaim()
end

---
--  IssueRepair
function IssueRepair()
end

---
--  IssueSacrifice
function IssueSacrifice()
end

---
--  IssueScript
function IssueScript()
end

---
--  IssueSiloBuildNuke
function IssueSiloBuildNuke()
end

---
--  IssueSiloBuildTactical
function IssueSiloBuildTactical()
end

---
--  IssueStop
function IssueStop()
end

---
--  IssueTactical
function IssueTactical()
end

---
--  IssueTeleport
function IssueTeleport()
end

---
--  IssueTeleportToBeacon
function IssueTeleportToBeacon()
end

---
--  IssueTransportLoad
function IssueTransportLoad()
end

---
--  IssueTransportUnload
function IssueTransportUnload()
end

---
--  IssueTransportUnloadSpecific
function IssueTransportUnloadSpecific()
end

---
--  IssueUpgrade
function IssueUpgrade()
end

---
--  ScriptTask.LUnitMove(self,target)
function LUnitMove(self, target)
end

---
--  ScriptTask.LUnitMoveNear(self,target,range)
function LUnitMoveNear(self, target, range)
end

---
-- 
function ListArmies()
end

---
--  MetaImpact(instigator,location,fMaxRadius,iAmount,affectsCategory,[damageFriendly])
function MetaImpact(instigator, location, fMaxRadius, iAmount, affectsCategory, [damageFriendly])
end

---
--  NotifyUpgrade(from,to)
function NotifyUpgrade(from, to)
end

---
--  Return true if the current command source is authorized to mess with the given army.:Or if cheats are enabled.
function OkayToMessWithArmy()
end

---
--  parse a string to generate a new entity category
function ParseEntityCategory()
end

---
--  handle = PlayLoop(self,sndParams)
function PlayLoop(self, sndParams)
end

---
--  Random([[min,] max])
function Random([[min, ] max])
end

---
--  RemoveBuildRestriction(army,category) - Remove a category from the restricted list
function RemoveBuildRestriction(army, category)
end

---
--  RemoveEconomyEvent(unit, event)
function RemoveEconomyEvent(unit,  event)
end

---
--  unit = SelectedUnit() -- Returns the currently selected unit. For use at the lua console, so you can call Lua methods on a unit.
function SelectedUnit()
end

---
--  SetAlliance(army1,army2,<Neutral|Enemy|Ally>)
function SetAlliance(army1, army2, <Neutral|Enemy|Ally>)
end

---
--  SetAllianceOneWay(army1,army2,<Neutral|Enemy|Ally>)
function SetAllianceOneWay(army1, army2, <Neutral|Enemy|Ally>)
end

---
--  SetAlliedVictory(army,bool)
function SetAlliedVictory(army, bool)
end

---
--  SetArmyAIPersonality(army,personality)
function SetArmyAIPersonality(army, personality)
end

---
--  SetArmyColor(army,r,g,b)
function SetArmyColor(army, r, g, b)
end

---
--  SetArmyColorIndex(army,index)
function SetArmyColorIndex(army, index)
end

---
--  army, mass, energy
function SetArmyEconomy()
end

---
--  SetArmyFactionIndex(army,index)
function SetArmyFactionIndex(army, index)
end

---
--  SetArmyOutOfGame(army) -- indicate that the supplied army has been defeated.
function SetArmyOutOfGame(army)
end

---
--  army, plans
function SetArmyPlans()
end

---
--  SetArmyColor(army, bool) - determines if the user should be able to see the army score
function SetArmyShowScore()
end

---
--  army, x, z
function SetArmyStart()
end

---
--  Set the army index for which to sync army stats (-1 for none)
function SetArmyStatsSyncArmy()
end

---
--  army, unitCap
function SetArmyUnitCap()
end

---
--  army, flag
function SetIgnoreArmyUnitCap()
end

---
--  army, flag
function SetIgnorePlayableRect()
end

---
--  SetPlayableRect( minX, minZ, maxX, maxZ )
function SetPlayableRect(minX,  minZ,  maxX,  maxZ)
end

---
--  SetTerrainType(x,z,type)
function SetTerrainType(x, z, type)
end

---
--  SetTerrainType(rect,type)
function SetTerrainTypeRect()
end

---
-- 
function ShouldCreateInitialArmyUnits()
end

---
--  SimConExecute('command string') -- Perform a console command
function SimConExecute('command string')
end

---
--  SplitProp(original, blueprint_name) -- split a prop into multiple child props, one per bone; returns all the created props
function SplitProp(original,  blueprint_name)
end

---
--  StopLoop(self,handle)
function StopLoop(self, handle)
end

---
--  Request that we submit xml army stats to gpg.net.
function SubmitXMLArmyStats()
end

---
--  TryCopyPose(unitFrom,entityTo,bCopyWorldTransform)
function TryCopyPose(unitFrom, entityTo, bCopyWorldTransform)
end

---
--  Warp( unit, location, [orientation] )
function Warp(unit,  location,  [orientation])
end

---
--  _c_CreateEntity(spec)
function _c_CreateEntity(spec)
end

---
--  _c_CreateShield(spec)
function _c_CreateShield(spec)
end

---
--  Print a log message
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

---
--  Entity:SinkAway(vy) -- sink into the ground
function SinkAway(vy)
end

---
-- 
function moho.entity_methods()
end

