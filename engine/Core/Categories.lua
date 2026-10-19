---@meta
---@declare-global

---@type EntityCategory
local categoryValue

---@type table<CategoryName | UnitId, EntityCategory>
categories = {
    --- Lua-side (`lua/ui/game/orders.lua`): adds the blueprint `Abilities` buttons to the orders panel
    ABILITYBUTTON = categoryValue,
    ADVANCEDCOMBATPRESET = categoryValue,
    AEON = categoryValue,
    --- Engine: a unit built by a factory skips the factory's queued transport-load orders, as `NAVAL` units do.
    --- Only staging platform transports (`AIRSTAGINGPLATFORM`, `PODSTAGINGPLATFORM`) carry units in this category.
    --- Other transports refuse them.
    --- Counted in the army stats
    AIR = categoryValue,
    --- Engine: aircraft can dock at the unit (Dock order, refuel and call-to-staging behavior)
    AIRSTAGINGPLATFORM = categoryValue,
    --- Engine: added to every projectile blueprint automatically
    ALLPROJECTILES = categoryValue,
    --- Engine: added to every unit blueprint automatically
    ALLUNITS = categoryValue,
    AMPHIBIOUS = categoryValue,
    --- Used for units that can target air units.
    --- Engine: counted in the army stats
    ANTIAIR = categoryValue,
    --- Used by support commander presets
    ANTIAIRPRESET = categoryValue,
    --- Used for units that can target missiles
    ANTIMISSILE = categoryValue,
    --- Used for units that can target submarines (torpedoes and depth charges)
    ANTINAVY = categoryValue,
    --- Used for units that are specifically designed to target shields
    ANTISHIELD = categoryValue,
    --- Unused, see `ANTINAVY` instead
    ANTISUB = categoryValue,
    --- Used for units that can target torpedoes
    ANTITORPEDO = categoryValue,
    --- Engine: counted in the army stats
    ARTILLERY = categoryValue,
    ASF = categoryValue,
    BATTLESHIP = categoryValue,
    --- Engine: weapons never pick the unit as an automatic target.
    --- `Entity:Kill` gives the instigator no kill (`KILLS` stat) for it
    BENIGN = categoryValue,
    --- Used for units that die when attacking
    BOMB = categoryValue,
    BOMBER = categoryValue,
    BOT = categoryValue,
    BUBBLESHIELDPRESET = categoryValue,
    BUBBLESHIELDSPILLOVERCHECK = categoryValue,
    BUILTBYAIRTIER2FACTORY = categoryValue,
    BUILTBYAIRTIER3FACTORY = categoryValue,
    BUILTBYCOMMANDER = categoryValue,
    BUILTBYEXPERIMENTALSUB = categoryValue,
    BUILTBYLANDTIER2FACTORY = categoryValue,
    BUILTBYLANDTIER3FACTORY = categoryValue,
    BUILTBYNAVALTIER2FACTORY = categoryValue,
    BUILTBYNAVALTIER3FACTORY = categoryValue,
    BUILTBYQUANTUMGATE = categoryValue,
    BUILTBYTIER1ENGINEER = categoryValue,
    BUILTBYTIER1FACTORY = categoryValue,
    BUILTBYTIER2COMMANDER = categoryValue,
    BUILTBYTIER2ENGINEER = categoryValue,
    BUILTBYTIER2FACTORY = categoryValue,
    BUILTBYTIER2SUPPORTFACTORY = categoryValue,
    BUILTBYTIER3COMMANDER = categoryValue,
    BUILTBYTIER3ENGINEER = categoryValue,
    BUILTBYTIER3FACTORY = categoryValue,
    --- Engine (UI): right-clicking an own or allied unit in this category gives a move order onto it instead of a guard order.
    --- Use it for a unit that others should walk onto, such as a gate. A damaged allied unit still gets a repair order.
    --- Has no effect with the "switch right click behavior" option, which always gives a guard order. No FAF unit has it
    CAMPAIGNGATE = categoryValue,
    --- Engine (UI): aircraft in this category get no dock cursor over an `AIRSTAGINGPLATFORM`
    CANNOTUSEAIRSTAGING = categoryValue,
    --- Engine: the transport can carry `COMMAND` units. Without it, transports refuse them
    CANTRANSPORTCOMMANDER = categoryValue,
    --- Engine: the unit accepts capture orders.
    --- The target must be capturable (`Unit:SetCapturable`), alive, finished, and not allied
    CAPTURE = categoryValue,
    --- Engine: the unit uses the carrier tasks to load, launch and dock aircraft.
    --- Units attached to it can't be hovered in the world view.
    --- Unlike units in other transports, they accept move, patrol, attack-move and guard orders
    CARRIER = categoryValue,
    CIVILIAN = categoryValue,
    CIVILLIAN = categoryValue,
    CLOAKPRESET = categoryValue,
    COMBATPRESET = categoryValue,
    --- Engine: transports without `CANTRANSPORTCOMMANDER` refuse the unit.
    --- `Entity:Kill` kills it outside the playable area even when its `CheckCanBeKilled` returns false.
    --- When its transport dies and its `CheckCanBeKilled` returns false, it takes 10000 damage through `OnDamage` if its `CheckCanTakeDamage` allows.
    --- A `PATROLHELPER` unit in this category skips patrol reclaim and repair on attack-move and in formation.
    --- Killing it adds to the `Enemies_Commanders_Destroyed` stat.
    --- Engine (UI): excluded from `GetIdleEngineers`. Transports without `CANTRANSPORTCOMMANDER` get no load cursor over it.
    --- Lua-side (`lua/SimHooks.lua`): `ChangeUnitArmy` returns nil for a unit that has a `COMMAND` unit attached, unless `noRestrictions` is true
    COMMAND = categoryValue,
    CONSTRUCTION = categoryValue,
    --- Lua-side (`lua/ui/game/construction.lua`): when a factory is selected, shows the unit one tech tab lower
    CONSTRUCTIONSORTDOWN = categoryValue,
    COUNTERINTELLIGENCE = categoryValue,
    CRABEGG = categoryValue,
    CRUISER = categoryValue,
    CYBRAN = categoryValue,
    DEBUG = categoryValue,
    --- Engine: counted in the army stats
    DEFENSE = categoryValue,
    DEFENSIVEBOAT = categoryValue,
    DESTROYER = categoryValue,
    DIESTOOCDEPLETINGSHIELD = categoryValue,
    --- Engine: an attack order is kept even when none of the unit's weapons can attack the target.
    --- Without this category the order ends, unless the unit moves in formation or is a submarine with `AI.AutoSurfaceToAttack`.
    --- The engine checks this every tick, from each weapon's `FireTargetLayerCaps` against the target's current layer and its target restrictions.
    --- It doesn't check range
    DIRECTFIRE = categoryValue,
    --- Engine (UI): the unit can be drag-built in a line.
    --- Lua-side (`lua/system/Blueprints.lua`): added to every `MOBILE` unit
    DRAGBUILD = categoryValue,
    DUMMYGSRWEAPON = categoryValue,
    DUMMYUNIT = categoryValue,
    ECONOMIC = categoryValue,
    --- Engine: counted in the army stats
    ENERGYPRODUCTION = categoryValue,
    ENERGYSTORAGE = categoryValue,
    --- Engine: the unit accepts build orders and uses the engineer behavior of guard orders.
    --- Weapons of its army don't pick a unit as automatic target while an engineer of the army captures it.
    --- Counted in the army stats.
    --- Engine (UI): the unit counts for `GetIdleEngineers`, unless it is also `COMMAND`, `SCOUT` or `UNTARGETABLE`, or has a positive `General.QuickSelectPriority`
    ENGINEER = categoryValue,
    ENGINEERPRESET = categoryValue,
    ENGINEERSTATION = categoryValue,
    --- Engine: a unit created where only air fits starts on the land layer instead of the air layer.
    --- Experimental aircraft on guard orders don't speed through their goals as other escorting aircraft do.
    --- Engine (UI): transports get no load cursor over it
    EXPERIMENTAL = categoryValue,
    --- Engine: a unit with buildable categories gets a factory build queue for its rally point orders, which every unit it builds inherits.
    --- The queue starts with a move to `Economy.InitialRallyX` and `Economy.InitialRallyZ`, and gets it again whenever it empties.
    --- An immobile factory reserves its skirt in the occupancy grid.
    --- The unit accepts build orders, and accepts orders while it is being built.
    --- A factory can only guard factories.
    --- A unit given a transport-load order onto a factory waits there for a ferry.
    --- Counted in the army stats.
    --- Engine (UI): the unit can be selected while it is being built. With `STRUCTURE`, it counts for `GetIdleFactories`
    FACTORY = categoryValue,
    --- Engine: when the unit and all its destinations are on water, its path requests use its `AltFootprint`, so the path stays on water.
    --- Every other `FAVORSWATER` unit in the same order must also be on water with destinations on water.
    --- Otherwise it paths with its normal footprint.
    FAVORSWATER = categoryValue,
    --- Engine: marks a ferry beacon, the target of ferry orders. Can be hovered even when `UNTARGETABLE`
    FERRYBEACON = categoryValue,
    FIELDENGINEER = categoryValue,
    FRIGATE = categoryValue,
    GATE = categoryValue,
    --- Engine: read at unit creation, but has no effect. No FAF unit has it
    GRIDBASEDMOTION = categoryValue,
    GROUNDATTACK = categoryValue,
    HELPER = categoryValue,
    HIGHALTAIR = categoryValue,
    HIGHPRIAIR = categoryValue,
    HOVER = categoryValue,
    --- Engine (AI): the AI brain's `FindPlaceToBuild` and `CreateResourceBuildingNearest` place units in this category on hydrocarbon markers
    HYDROCARBON = categoryValue,
    INDIRECTFIRE = categoryValue,
    --- Engine (UI): the unit's orders are not drawn as command lines
    INSIGNIFICANTUNIT = categoryValue,
    INTEL = categoryValue,
    INTELJAMMERPRESET = categoryValue,
    INTELLIGENCE = categoryValue,
    --- Lua-side (`lua/system/blueprints-props.lua`): makes a prop indestructible by switching its script to `PropInvulnerable`
    INVULNERABLE = categoryValue,
    ISPREENHANCEDUNIT = categoryValue,
    --- Engine: transports on assist-move and ferry orders only pick up `MOBILE` `LAND` units.
    --- Counted in the army stats
    LAND = categoryValue,
    LIGHTBOAT = categoryValue,
    --- Engine (AI): counted in the AI influence map (`CInfluenceMap`)
    MASSEXTRACTION = categoryValue,
    MASSFABRICATION = categoryValue,
    --- Engine: counted in the army stats
    MASSPRODUCTION = categoryValue,
    MASSSTORAGE = categoryValue,
    --- Engine: attack orders use the melee attack task, and its weapons check melee range instead of firing solutions.
    --- No FAF unit has it
    MELEE = categoryValue,
    MISSILE = categoryValue,
    MISSILEPRESET = categoryValue,
    --- Engine: targets in this category count as moving targets for weapon aiming.
    --- Transports on assist-move and ferry orders only pick up `MOBILE` `LAND` units.
    --- Engine (AI): read by AI brain functions such as `GetAvailableFactories`
    MOBILE = categoryValue,
    MOBILESONAR = categoryValue,
    NANOCOMBATPRESET = categoryValue,
    NAVALCARRIER = categoryValue,
    --- Engine: a unit built by a factory skips the factory's queued transport-load orders, as `AIR` units do.
    --- Counted in the army stats
    NAVAL = categoryValue,

    --- Engine: the unit accepts build orders, which otherwise only `FACTORY`, `ENGINEER` and `POD` units accept.
    --- The Fatboy, Megalith, Tempest, Atlantis and CZAR build units through it.
    --- `FACTORY` would give them the factory build queue and its rally point orders, and `ENGINEER` the engineer guard behavior and the idle engineer list.
    --- Lua-side (`lua/ui/game/construction.lua`, `lua/ui/game/buildmode.lua`): the build menu places this mobile unit on the map like a structure, as for experimentals built by engineers
    NEEDMOBILEBUILD = categoryValue,
    --- Unit doesn't use a formation when assisting other units
    NOFORMATION = categoryValue,
    --- Engine: prevents area damage being applied to the entity
    NOSPLASHDAMAGE = categoryValue,
    --- Engine: counted in the army stats
    NUKE = categoryValue,
    NUKESUB = categoryValue,
    OMNI = categoryValue,
    OPERATION = categoryValue,
    OPTICS = categoryValue,
    ORBITALSYSTEM = categoryValue,
    --- Engine (UI): `UserUnit:CanAttackTarget` and the attack order treat a mobile unit with auto-surface mode on as able to hit air units.
    --- It surfaces to attack, so the `FireTargetLayerCaps` of its weapons are ignored.
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the anti-air range overlay
    OVERLAYANTIAIR = categoryValue,
    --- Engine (UI): `UserUnit:CanAttackTarget` and the attack order treat an amphibious unit on land as able to hit submerged and seabed units.
    --- It moves into the water to attack, so the `FireTargetLayerCaps` of its weapons are ignored.
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the anti-navy range overlay
    OVERLAYANTINAVY = categoryValue,
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the counter-intel range overlay
    OVERLAYCOUNTERINTEL = categoryValue,
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the countermeasure range overlay
    OVERLAYCOUNTERMEASURE = categoryValue,
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the countermeasure range overlay, as `OVERLAYCOUNTERMEASURE` does
    OVERLAYDEFENSE = categoryValue,
    --- Engine (UI): `UserUnit:CanAttackTarget` and the attack order treat a mobile unit with auto-surface mode on,
    --- and an amphibious unit on the seabed, as able to hit land units.
    --- They surface or walk onto land to attack, so the `FireTargetLayerCaps` of their weapons are ignored.
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the direct fire range overlay
    OVERLAYDIRECTFIRE = categoryValue,
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the indirect fire range overlay
    OVERLAYINDIRECTFIRE = categoryValue,
    --- Engine: the build range ring uses the blueprint `AI.StagingPlatformScanRadius`, or `AI.GuardScanRadius` when that is 0.
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the build range overlay
    OVERLAYMISC = categoryValue,
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the omni range overlay
    OVERLAYOMNI = categoryValue,
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the radar range overlay
    OVERLAYRADAR = categoryValue,
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the sonar range overlay
    OVERLAYSONAR = categoryValue,
    --- Engine: the unit reclaims and repairs nearby targets while on patrol or attack-move.
    --- A `COMMAND` or `SACU_BEHAVIOR` unit skips this on attack-move and on a patrol or attack-move in formation
    PATROLHELPER = categoryValue,
    PERSONALSHIELD = categoryValue,
    --- Engine: when its command queue is empty, the unit gets an assist-commander order.
    --- It helps its creator's work, or docks on its creator when that is `PODSTAGINGPLATFORM`.
    --- While docked, it can be selected and accepts move, patrol, attack-move, guard, reclaim, capture and repair orders, which units in other transports reject.
    --- It accepts build orders.
    --- Engine (UI): an unload drag with only pods selected in the transport gives them a move order
    POD = categoryValue,
    --- Engine: the unit rejects transport load and dock orders, as units already in a transport do. No FAF unit has it
    PODS = categoryValue,
    --- Engine: the unit gets transport logic without the `RULEUCC_Transport` command cap, so `POD` units it created dock on it.
    --- The transport counts as a staging platform, as for `AIRSTAGINGPLATFORM`: it only carries aircraft.
    --- Its refuel and staging repair values don't apply to pods, since pods have no fuel.
    --- Unlike `AIRSTAGINGPLATFORM`, dock orders and the dock cursor don't target it
    PODSTAGINGPLATFORM = categoryValue,
    PRODUCTDL = categoryValue,
    PRODUCTFA = categoryValue,
    PRODUCTSC1 = categoryValue,
    --- Engine (UI): the projectile draws a strategic icon when zoomed out
    PROJECTILE = categoryValue,
    RADAR = categoryValue,
    --- Engine (UI): orders given to the unit are added to its rally point queue
    RALLYPOINT = categoryValue,
    RAMBOPRESET = categoryValue,
    RASPRESET = categoryValue,
    --- Engine: the unit gets a builder. When a structure it guards dies, it queues and rebuilds that structure.
    --- A guard order on a structure sends it to the structure's position. No FAF unit has it
    REBUILDER = categoryValue,
    --- Engine: the entity can be reclaimed. Reclaim orders, the reclaim cursor and patrol reclaim skip entities without it
    RECLAIMABLE = categoryValue,
    --- Engine: the unit accepts reclaim orders
    RECLAIM = categoryValue,
    --- Engine (UI): right-clicking an own or allied unit in this category with reclaimers selected issues a reclaim order
    RECLAIMFRIENDLY = categoryValue,
    --- Engine: the unit accepts repair orders
    REPAIR = categoryValue,
    RESEARCH = categoryValue,
    SATELLITE = categoryValue,
    --- Engine (UI): excluded from `GetIdleEngineers`
    SCOUT = categoryValue,
    --- Engine (UI): the unit can be selected. Units without it cannot be selected
    SELECTABLE = categoryValue,
    SERAPHIM = categoryValue,
    --- Engine: building or repairing the unit also regenerates its shield, scaled by `Defense.Shield.RegenAssistMult`, and repair goes on until the shield is full.
    --- Units on guard orders repair a unit in this category whose shield is damaged
    SHIELD = categoryValue,
    SHIELDCOLLIDE = categoryValue,
    SHIELDCOMBATPRESET = categoryValue,
    --- Lua-side (`lua/ui/controls/worldview.lua`): with the unit selected, the attack, nuke, tactical and overcharge cursors draw the damage radius of its matching weapons
    SHOWATTACKRETICLE = categoryValue,
    --- Engine (UI): shows the factory build queue of the unit (`SetCurrentFactoryForQueueDisplay`)
    SHOWQUEUE = categoryValue,
    --- Engine: the unit can build missiles with silo build orders.
    --- Engine (UI): right-clicking an unfinished immobile unit in this category with repair-capable units selected gives a guard order instead, as for `FACTORY`
    SILO = categoryValue,
    SIMPLECOMBATPRESET = categoryValue,
    SIZE4 = categoryValue,
    SIZE8 = categoryValue,
    SIZE12 = categoryValue,
    SIZE16 = categoryValue,
    SIZE20 = categoryValue,
    SNIPEMODE = categoryValue,
    SNIPER = categoryValue,
    SONAR = categoryValue,
    --- Lua-side (`lua/ui/game/construction.lua`): groups the unit in the build menu.
    --- Group order: `SORTCONSTRUCTION`, `SORTECONOMY`, `SORTDEFENSE`, `SORTSTRATEGIC`, `SORTINTEL`, `SORTOTHER`, then the rest
    SORTCONSTRUCTION = categoryValue,
    --- Lua-side (`lua/ui/game/construction.lua`): groups the unit in the build menu.
    --- Group order: `SORTCONSTRUCTION`, `SORTECONOMY`, `SORTDEFENSE`, `SORTSTRATEGIC`, `SORTINTEL`, `SORTOTHER`, then the rest
    SORTDEFENSE = categoryValue,
    --- Lua-side (`lua/ui/game/construction.lua`): groups the unit in the build menu.
    --- Group order: `SORTCONSTRUCTION`, `SORTECONOMY`, `SORTDEFENSE`, `SORTSTRATEGIC`, `SORTINTEL`, `SORTOTHER`, then the rest
    SORTECONOMY = categoryValue,
    --- Lua-side (`lua/ui/game/construction.lua`): groups the unit in the build menu.
    --- Group order: `SORTCONSTRUCTION`, `SORTECONOMY`, `SORTDEFENSE`, `SORTSTRATEGIC`, `SORTINTEL`, `SORTOTHER`, then the rest
    SORTINTEL = categoryValue,
    --- Lua-side (`lua/ui/game/construction.lua`): groups the unit in the build menu.
    --- Group order: `SORTCONSTRUCTION`, `SORTECONOMY`, `SORTDEFENSE`, `SORTSTRATEGIC`, `SORTINTEL`, `SORTOTHER`, then the rest
    SORTOTHER = categoryValue,
    --- Lua-side (`lua/ui/game/construction.lua`): groups the unit in the build menu.
    --- Group order: `SORTCONSTRUCTION`, `SORTECONOMY`, `SORTDEFENSE`, `SORTSTRATEGIC`, `SORTINTEL`, `SORTOTHER`, then the rest
    SORTSTRATEGIC = categoryValue,
    SPECIALHIGHPRI = categoryValue,
    SPECIALLOWPRI = categoryValue,
    --- Engine: like a `POD`, the unit gets an assist-commander order when its command queue is empty.
    --- With auto mode on, it repairs, helps build or reclaims for allied units within its `AI.GuardScanRadius`.
    --- Otherwise a mobile one docks on its creator, and an immobile one waits
    STATIONASSISTPOD = categoryValue,
    STEALTH = categoryValue,
    STEALTHFIELD = categoryValue,
    STEALTHPRESET = categoryValue,
    STRATEGICBOMBER = categoryValue,
    STRATEGIC = categoryValue,
    --- Engine: counted in the army stats.
    --- Engine (UI): with `FACTORY`, the unit counts for `GetIdleFactories`. A guard order on it sends selected `REBUILDER` units to its position.
    --- Engine (AI): read by AI brain functions such as `CanBuildStructureAt`
    STRUCTURE = categoryValue,
    SUBCOMMANDER = categoryValue,
    SUBMERSIBLE = categoryValue,
    SUPPORTFACTORY = categoryValue,
    T1SUBMARINE = categoryValue,
    T2SUBMARINE = categoryValue,
    TACTICAL = categoryValue,
    TACTICALMISSILEPLATFORM = categoryValue,
    TANK = categoryValue,
    --- Engine: the unit leaves its formation on attack orders.
    --- Aircraft in this category follow a moving target directly and ignore movement damping
    TARGETCHASER = categoryValue,
    --- Engine: counted in the army stats
    TECH1 = categoryValue,
    --- Engine: counted in the army stats
    TECH2 = categoryValue,
    --- Engine: counted in the army stats
    TECH3 = categoryValue,
    TECH_TWO = categoryValue,
    --- Engine: the transport teleports its cargo instead of carrying it.
    --- An unload order onto a unit (`IssueTeleportToBeacon`) makes that unit the beacon and calls `OnSetTeleportDest` on the transport.
    --- Load orders onto the transport then call `OnTeleportUnit` on each cargo unit, once the beacon is alive and idle.
    --- Needs the usual transport setup: `Transport` blueprint fields, attach bones and `RULEUCC_Transport`. No FAF unit has it
    TELEPORTATION = categoryValue,
    --- Engine (UI): with a `TELEPORTATION` unit selected, a transport order onto the unit gives an unload order that makes it the beacon.
    --- Order lines to it from units of the same army are drawn in purple.
    --- The sim accepts any unit as a beacon. The unused Quantum Gate Beacons (`UAB5103`, `UEB5103`, `URB5103`) have it
    TELEPORTBEACON = categoryValue,
    TORPEDO = categoryValue,
    --- Engine: only units in this category accept ferry orders, and factories hand built units to them when they ferry.
    --- A transport in this category descends faster when landing, and carries the `MOBILE` `LAND` units of an assist-move order.
    --- Counted in the army stats.
    --- Engine (UI): right-clicking an own unit in this category with non-flying units selected gives them a load order into it.
    --- With `TRANSPORTFOCUS`, right-clicking an own non-flying unit gives the transport an order to pick it up.
    --- A load order's waypoint can only be dragged onto a unit in this category, `FERRYBEACON` or `AIRSTAGINGPLATFORM`
    TRANSPORTATION = categoryValue,
    TRANSPORTBUILTBYTIER1FACTORY = categoryValue,
    TRANSPORTBUILTBYTIER2FACTORY = categoryValue,
    TRANSPORTBUILTBYTIER3FACTORY = categoryValue,
    --- Engine (UI): with this `TRANSPORTATION` unit selected, right-clicking an own unit that can't fly gives an order to pick it up.
    --- Not for `EXPERIMENTAL` units, and `COMMAND` units need `CANTRANSPORTCOMMANDER`
    TRANSPORTFOCUS = categoryValue,
    UEF = categoryValue,
    --- Not read by the engine or by Lua. Remove `SELECTABLE` to make a unit unselectable
    UNSELECTABLE = categoryValue,
    --- Lua-side (`lua/ui/dialogs/createunit.logic.lua`): hides the unit from the create unit (cheat spawn) dialog
    UNSPAWNABLE = categoryValue,
    --- Engine (UI): when the unit is not also `SELECTABLE`, the cursor cannot hover or target it.
    --- Also excludes it from `GetIdleEngineers`
    UNTARGETABLE = categoryValue,
    --- Engine: an immobile unit in this category doesn't occupy ground when created.
    --- A unit in this category attached to a transport doesn't count as cargo. No FAF unit has it
    UPGRADE = categoryValue,
    USEBUILDPRESETS = categoryValue,
    --- Lua-side (`lua/ui/game/unitview.lua`): shows the missile count only when the unit has a missile enhancement
    VERIFYMISSILEUI = categoryValue,
    --- Engine: other armies can see the unit through vision, radar or sonar. Units without it never show to other armies
    VISIBLETORECON = categoryValue,
    VOLATILE = categoryValue,
    -- sACU Preset Enhancements
    AdvancedCoolingUpgrade = categoryValue,
    CloakingGenerator = categoryValue,
    DamageStabilization = categoryValue,
    EMPCharge = categoryValue,
    EngineeringFocusingModule = categoryValue,
    EngineeringThroughput = categoryValue,
    EnhancedSensors = categoryValue,
    FocusConvertor = categoryValue,
    HighExplosiveOrdnance = categoryValue,
    Missile = categoryValue,
    NaniteMissileSystem = categoryValue,
    Overcharge = categoryValue,
    Pod = categoryValue,
    RadarJammer = categoryValue,
    ResourceAllocation = categoryValue,
    SelfRepairSystem = categoryValue,
    SensorRangeEnhancer = categoryValue,
    Shield = categoryValue,
    ShieldGeneratorField = categoryValue,
    ShieldHeavy = categoryValue,
    StabilitySuppressant = categoryValue,
    StealthGenerator = categoryValue,
    Switchback = categoryValue,
    SystemIntegrityCompensator = categoryValue,

    -- Populates a dummy factory that can take over the factory aspect of the unit
    EXTERNALFACTORY = categoryValue,

    -- Added or changed by FA-Binary-Patches

    --- Engine: the unit can land on water.
    --- Introduced by https://github.com/FAForever/FA-Binary-Patches/pull/20
    CANLANDONWATER = categoryValue,
    --- Engine: the unit accepts orders while it is being built, which the base engine allows only for `FACTORY` units, so upgrades can be queued on it.
    --- Engine (UI): it can be selected while it is being built.
    --- Introduced by https://github.com/FAForever/FA-Binary-Patches/commit/e23e4ea9ad1aeed74b718aaf27eff6bd28742b95
    CQUEMOV = categoryValue,
    --- Engine (UI): drag selection gives an unfinished unit in this category the lowest selection priority.
    --- Introduced by https://github.com/FAForever/FA-Binary-Patches/commit/e23e4ea9ad1aeed74b718aaf27eff6bd28742b95
    LOWSELECTPRIO = categoryValue,
    --- Engine: a structure can't be built on top of a prop in this category.
    --- Lua-side (`lua/sim/units/StructureUnit.lua`): the prop is not cleared when a structure starts building on top of it.
    --- Added to wreckage by `lua/system/blueprints-props.lua`.
    --- Introduced by https://github.com/FAForever/FA-Binary-Patches/pull/16
    OBSTRUCTSBUILDING = categoryValue,
    --- Engine: a `PATROLHELPER` unit in this category skips patrol reclaim and repair on attack-move and on a patrol or attack-move in formation, like a `COMMAND` unit.
    --- The patch renames the engine's `SUBCOMMANDER` check to this category, and `lua/system/blueprints-units.lua` adds it to every `SUBCOMMANDER` unit.
    --- Introduced by https://github.com/FAForever/FA-Binary-Patches/pull/13
    SACU_BEHAVIOR = categoryValue,
    --- Engine (UI): double-clicking a wall selects the other walls of that type, which the base engine prevents.
    --- The `select_all_units_of_same_type` hotkey (`UI_ExpandCurrentSelection`) still skips walls.
    --- Introduced by https://github.com/FAForever/FA-Binary-Patches/commit/e23e4ea9ad1aeed74b718aaf27eff6bd28742b95
    WALL = categoryValue,
}

---@alias CategoryName
---| "ABILITYBUTTON"
---| "ADVANCEDCOMBATPRESET"
---| "AEON"
---| "AIR"
---| "AIRSTAGINGPLATFORM"
---| "ALLPROJECTILES"
---| "ALLUNITS"
---| "AMPHIBIOUS"
---| "ANTIAIR"
---| "ANTIAIRPRESET"
---| "ANTIMISSILE"
---| "ANTINAVY"
---| "ANTISHIELD"
---| "ANTISUB"
---| "ANTITORPEDO"
---| "ARTILLERY"
---| "ASF"
---| "BATTLESHIP"
---| "BENIGN"
---| "BOMB"
---| "BOMBER"
---| "BOT"
---| "BUBBLESHIELDPRESET"
---| "BUBBLESHIELDSPILLOVERCHECK"
---| "BUILTBYAIRTIER2FACTORY"
---| "BUILTBYAIRTIER3FACTORY"
---| "BUILTBYCOMMANDER"
---| "BUILTBYEXPERIMENTALSUB"
---| "BUILTBYLANDTIER2FACTORY"
---| "BUILTBYLANDTIER3FACTORY"
---| "BUILTBYNAVALTIER2FACTORY"
---| "BUILTBYNAVALTIER3FACTORY"
---| "BUILTBYQUANTUMGATE"
---| "BUILTBYTIER1ENGINEER"
---| "BUILTBYTIER1FACTORY"
---| "BUILTBYTIER2COMMANDER"
---| "BUILTBYTIER2ENGINEER"
---| "BUILTBYTIER2FACTORY"
---| "BUILTBYTIER2SUPPORTFACTORY"
---| "BUILTBYTIER3COMMANDER"
---| "BUILTBYTIER3ENGINEER"
---| "BUILTBYTIER3FACTORY"
---| "CAMPAIGNGATE"
---| "CANNOTUSEAIRSTAGING"
---| "CANTRANSPORTCOMMANDER"
---| "CAPTURE"
---| "CARRIER"
---| "CANLANDONWATER"
---| "CIVILIAN"
---| "CIVILLIAN"
---| "CLOAKPRESET"
---| "COMBATPRESET"
---| "COMMAND"
---| "CONSTRUCTION"
---| "CONSTRUCTIONSORTDOWN"
---| "COUNTERINTELLIGENCE"
---| "CQUEMOV"
---| "CRABEGG"
---| "CRUISER"
---| "CYBRAN"
---| "DEBUG"
---| "DEFENSE"
---| "DEFENSIVEBOAT"
---| "DESTROYER"
---| "DIESTOOCDEPLETINGSHIELD"
---| "DIRECTFIRE"
---| "DRAGBUILD"
---| "DUMMYGSRWEAPON"
---| "DUMMYUNIT"
---| "ECONOMIC"
---| "ENERGYPRODUCTION"
---| "ENERGYSTORAGE"
---| "ENGINEER"
---| "ENGINEERPRESET"
---| "ENGINEERSTATION"
---| "EXPERIMENTAL"
---| "FACTORY"
---| "FAVORSWATER"
---| "FERRYBEACON"
---| "FIELDENGINEER"
---| "FRIGATE"
---| "GATE"
---| "GRIDBASEDMOTION"
---| "GROUNDATTACK"
---| "HELPER"
---| "HIGHALTAIR"
---| "HIGHPRIAIR"
---| "HOVER"
---| "HYDROCARBON"
---| "INDIRECTFIRE"
---| "INSIGNIFICANTUNIT"
---| "INTEL"
---| "INTELJAMMERPRESET"
---| "INTELLIGENCE"
---| "INVULNERABLE"
---| "ISPREENHANCEDUNIT"
---| "LAND"
---| "LIGHTBOAT"
---| "LOWSELECTPRIO"
---| "MASSEXTRACTION"
---| "MASSFABRICATION"
---| "MASSPRODUCTION"
---| "MASSSTORAGE"
---| "MELEE"
---| "MISSILE"
---| "MISSILEPRESET"
---| "MOBILE"
---| "MOBILESONAR"
---| "NANOCOMBATPRESET"
---| "NAVALCARRIER"
---| "NAVAL"
---| "NEEDMOBILEBUILD"
---| "NOFORMATION" # Unit doesn't use a formation when assisting other units
---| "NOSPLASHDAMAGE"
---| "NUKE"
---| "NUKESUB"
---| "OBSTRUCTSBUILDING"
---| "OMNI"
---| "OPERATION"
---| "OPTICS"
---| "ORBITALSYSTEM"
---| "OVERLAYANTIAIR"
---| "OVERLAYANTINAVY"
---| "OVERLAYCOUNTERINTEL"
---| "OVERLAYCOUNTERMEASURE"
---| "OVERLAYDEFENSE"
---| "OVERLAYDIRECTFIRE"
---| "OVERLAYINDIRECTFIRE"
---| "OVERLAYMISC"
---| "OVERLAYOMNI"
---| "OVERLAYRADAR"
---| "OVERLAYSONAR"
---| "PATROLHELPER"
---| "PERSONALSHIELD"
---| "POD"
---| "PODS"
---| "PODSTAGINGPLATFORM"
---| "PRODUCTDL"
---| "PRODUCTFA"
---| "PRODUCTSC1"
---| "PROJECTILE"
---| "RADAR"
---| "RALLYPOINT"
---| "RAMBOPRESET"
---| "RASPRESET"
---| "REBUILDER"
---| "RECLAIMABLE"
---| "RECLAIM"
---| "RECLAIMFRIENDLY"
---| "REPAIR"
---| "RESEARCH"
---| "SACU_BEHAVIOR"
---| "SATELLITE"
---| "SCOUT"
---| "SELECTABLE"
---| "SERAPHIM"
---| "SHIELD"
---| "SHIELDCOLLIDE"
---| "SHIELDCOMBATPRESET"
---| "SHOWATTACKRETICLE"
---| "SHOWQUEUE"
---| "SILO"
---| "SIMPLECOMBATPRESET"
---| "SIZE4"
---| "SIZE8"
---| "SIZE12"
---| "SIZE16"
---| "SIZE20"
---| "SNIPEMODE"
---| "SNIPER"
---| "SONAR"
---| "SORTCONSTRUCTION"
---| "SORTDEFENSE"
---| "SORTECONOMY"
---| "SORTINTEL"
---| "SORTOTHER"
---| "SORTSTRATEGIC"
---| "SPECIALHIGHPRI"
---| "SPECIALLOWPRI"
---| "STATIONASSISTPOD"
---| "STEALTH"
---| "STEALTHFIELD"
---| "STEALTHPRESET"
---| "STRATEGICBOMBER"
---| "STRATEGIC"
---| "STRUCTURE"
---| "SUBCOMMANDER"
---| "SUBMERSIBLE"
---| "SUPPORTFACTORY"
---| "T1SUBMARINE"
---| "T2SUBMARINE"
---| "TACTICAL"
---| "TACTICALMISSILEPLATFORM"
---| "TANK"
---| "TARGETCHASER" # Unit does not mantain any formation when on attack task
---| "TECH1"
---| "TECH2"
---| "TECH3"
---| "TECH_TWO"
---| "TELEPORTATION"
---| "TELEPORTBEACON"
---| "TORPEDO"
---| "TRANSPORTATION"
---| "TRANSPORTBUILTBYTIER1FACTORY"
---| "TRANSPORTBUILTBYTIER2FACTORY"
---| "TRANSPORTBUILTBYTIER3FACTORY"
---| "TRANSPORTFOCUS"
---| "UEF"
---| "UNSELECTABLE"
---| "UNSPAWNABLE"
---| "UNTARGETABLE"
---| "UPGRADE"
---| "USEBUILDPRESETS"
---| "VERIFYMISSILEUI"
---| "VISIBLETORECON"
---| "VOLATILE"
---| "WALL"
---
---| "AdvancedCoolingUpgrade"
---| "CloakingGenerator"
---| "DamageStabilization"
---| "EMPCharge"
---| "EngineeringFocusingModule"
---| "EngineeringThroughput"
---| "EnhancedSensors"
---| "FocusConvertor"
---| "HighExplosiveOrdnance"
---| "Missile"
---| "NaniteMissileSystem"
---| "Overcharge"
---| "Pod"
---| "RadarJammer"
---| "ResourceAllocation"
---| "SelfRepairSystem"
---| "SensorRangeEnhancer"
---| "Shield"
---| "ShieldGeneratorField"
---| "ShieldHeavy"
---| "StabilitySuppressant"
---| "StealthGenerator"
---| "Switchback"