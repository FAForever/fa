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
    AIR = categoryValue,
    --- Engine: aircraft can dock at the unit (Dock order, refuel and call-to-staging behavior)
    AIRSTAGINGPLATFORM = categoryValue,
    --- Engine: added to every projectile blueprint automatically
    ALLPROJECTILES = categoryValue,
    --- Engine: added to every unit blueprint automatically
    ALLUNITS = categoryValue,
    AMPHIBIOUS = categoryValue,
    --- Used for units that can target air units
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
    ARTILLERY = categoryValue,
    ASF = categoryValue,
    BATTLESHIP = categoryValue,
    --- Engine: weapons never pick the unit as an automatic target. `Entity:Kill` gives the instigator no kill (`KILLS` stat) for it
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
    --- Engine (UI): aircraft in this category get no dock cursor over an `AIRSTAGINGPLATFORM`
    CANNOTUSEAIRSTAGING = categoryValue,
    --- Engine: the transport can carry `COMMAND` units. Without it, transports refuse them
    CANTRANSPORTCOMMANDER = categoryValue,
    --- Engine: the unit accepts capture orders. The target needs `Capturable` in its blueprint
    CAPTURE = categoryValue,
    --- Engine: units attached to a carrier cannot be selected or hovered and reject move and guard orders
    CARRIER = categoryValue,
    CIVILIAN = categoryValue,
    CIVILLIAN = categoryValue,
    CLOAKPRESET = categoryValue,
    COMBATPRESET = categoryValue,
    COMMAND = categoryValue,
    CONSTRUCTION = categoryValue,
    --- Lua-side (`lua/ui/game/construction.lua`): when a factory is selected, shows the unit one tech tab lower
    CONSTRUCTIONSORTDOWN = categoryValue,
    COUNTERINTELLIGENCE = categoryValue,
    CRABEGG = categoryValue,
    CRUISER = categoryValue,
    CYBRAN = categoryValue,
    DEBUG = categoryValue,
    DEFENSE = categoryValue,
    DEFENSIVEBOAT = categoryValue,
    DESTROYER = categoryValue,
    DIESTOOCDEPLETINGSHIELD = categoryValue,
    DIRECTFIRE = categoryValue,
    --- Engine (UI): the structure can be drag-built in a line, as walls are
    DRAGBUILD = categoryValue,
    DUMMYGSRWEAPON = categoryValue,
    DUMMYUNIT = categoryValue,
    ECONOMIC = categoryValue,
    ENERGYPRODUCTION = categoryValue,
    ENERGYSTORAGE = categoryValue,
    --- Engine: the unit accepts build orders. In the UI it counts for `GetIdleEngineers`, unless it is also `COMMAND`, `SCOUT` or `UNTARGETABLE`, or has a `General.QuickSelectPriority`
    ENGINEER = categoryValue,
    ENGINEERPRESET = categoryValue,
    ENGINEERSTATION = categoryValue,
    EXPERIMENTAL = categoryValue,
    --- Replaces the unit's command queue with the rally point orders. Also gives it a default rally point order upon creation
    FACTORY = categoryValue,
    --- Engine: the pathfinder prefers water for this unit when its destinations are underwater
    FAVORSWATER = categoryValue,
    --- Engine: marks a ferry beacon, the target of ferry orders. Can be hovered even when `UNTARGETABLE`
    FERRYBEACON = categoryValue,
    FIELDENGINEER = categoryValue,
    FRIGATE = categoryValue,
    GATE = categoryValue,
    GROUNDATTACK = categoryValue,
    HELPER = categoryValue,
    HIGHALTAIR = categoryValue,
    HIGHPRIAIR = categoryValue,
    HOVER = categoryValue,
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
    LAND = categoryValue,
    LIGHTBOAT = categoryValue,
    MASSEXTRACTION = categoryValue,
    MASSFABRICATION = categoryValue,
    MASSPRODUCTION = categoryValue,
    MASSSTORAGE = categoryValue,
    MISSILE = categoryValue,
    MISSILEPRESET = categoryValue,
    MOBILE = categoryValue,
    MOBILESONAR = categoryValue,
    NANOCOMBATPRESET = categoryValue,
    NAVALCARRIER = categoryValue,
    NAVAL = categoryValue,

    --- Lua-side (`lua/ui/game/construction.lua`, `lua/ui/game/buildmode.lua`): the build menu places this mobile unit on the map like a structure, as for experimentals built by engineers.
    --- Engine: a unit in this category accepts build orders, like `FACTORY`, `ENGINEER` and `POD`
    NEEDMOBILEBUILD = categoryValue,
    --- Unit doesn't use a formation when assisting other units
    NOFORMATION = categoryValue,
    --- Engine: prevents area damage being applied to the entity
    NOSPLASHDAMAGE = categoryValue,
    NUKE = categoryValue,
    NUKESUB = categoryValue,
    OMNI = categoryValue,
    OPERATION = categoryValue,
    OPTICS = categoryValue,
    ORBITALSYSTEM = categoryValue,
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the anti-air range overlay.
    --- Engine (UI): lets an amphibious or surfacing unit count as able to attack air targets
    OVERLAYANTIAIR = categoryValue,
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the anti-navy range overlay.
    --- Engine (UI): lets an amphibious unit on land count as able to attack naval targets
    OVERLAYANTINAVY = categoryValue,
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the counter-intel range overlay
    OVERLAYCOUNTERINTEL = categoryValue,
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the countermeasure range overlay
    OVERLAYCOUNTERMEASURE = categoryValue,
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the countermeasure range overlay
    OVERLAYDEFENSE = categoryValue,
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the direct fire range overlay.
    --- Engine (UI): lets an amphibious or surfacing unit count as able to attack land targets
    OVERLAYDIRECTFIRE = categoryValue,
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the indirect fire range overlay
    OVERLAYINDIRECTFIRE = categoryValue,
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the build range overlay.
    --- Engine: that ring uses the blueprint `AI.StagingPlatformScanRadius`, or `AI.GuardScanRadius` when that is 0
    OVERLAYMISC = categoryValue,
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the omni range overlay
    OVERLAYOMNI = categoryValue,
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the radar range overlay
    OVERLAYRADAR = categoryValue,
    --- Lua-side (`lua/ui/game/rangeoverlayparams.lua`): shows the unit in the sonar range overlay
    OVERLAYSONAR = categoryValue,
    --- Engine: the unit reclaims and repairs nearby targets while on patrol or attack-move. A `COMMAND` or `SACU_BEHAVIOR` unit skips this while moving in formation
    PATROLHELPER = categoryValue,
    PERSONALSHIELD = categoryValue,
    --- Engine: a pod attached to its parent rejects move, guard, reclaim, capture and repair orders. Pods accept build orders
    POD = categoryValue,
    --- Engine: the unit gets transport logic without the `RULEUCC_Transport` command cap, so pods can attach to it
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
    SCOUT = categoryValue,
    --- Engine (UI): the unit can be selected. Units without it cannot be selected
    SELECTABLE = categoryValue,
    SERAPHIM = categoryValue,
    SHIELD = categoryValue,
    SHIELDCOLLIDE = categoryValue,
    SHIELDCOMBATPRESET = categoryValue,
    --- Lua-side (`lua/ui/controls/worldview.lua`): draws the damage radius of the selected unit's missile weapons at the cursor
    SHOWATTACKRETICLE = categoryValue,
    --- Engine (UI): shows the factory build queue of the unit (`SetCurrentFactoryForQueueDisplay`)
    SHOWQUEUE = categoryValue,
    --- Engine: the unit can build missiles with silo build orders
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
    --- Lua-side (`lua/ui/game/construction.lua`): groups the unit in the build menu. Group order: `SORTCONSTRUCTION`, `SORTECONOMY`, `SORTDEFENSE`, `SORTSTRATEGIC`, `SORTINTEL`, `SORTOTHER`, then the rest
    SORTCONSTRUCTION = categoryValue,
    --- Lua-side (`lua/ui/game/construction.lua`): groups the unit in the build menu. Group order: `SORTCONSTRUCTION`, `SORTECONOMY`, `SORTDEFENSE`, `SORTSTRATEGIC`, `SORTINTEL`, `SORTOTHER`, then the rest
    SORTDEFENSE = categoryValue,
    --- Lua-side (`lua/ui/game/construction.lua`): groups the unit in the build menu. Group order: `SORTCONSTRUCTION`, `SORTECONOMY`, `SORTDEFENSE`, `SORTSTRATEGIC`, `SORTINTEL`, `SORTOTHER`, then the rest
    SORTECONOMY = categoryValue,
    --- Lua-side (`lua/ui/game/construction.lua`): groups the unit in the build menu. Group order: `SORTCONSTRUCTION`, `SORTECONOMY`, `SORTDEFENSE`, `SORTSTRATEGIC`, `SORTINTEL`, `SORTOTHER`, then the rest
    SORTINTEL = categoryValue,
    --- Lua-side (`lua/ui/game/construction.lua`): groups the unit in the build menu. Group order: `SORTCONSTRUCTION`, `SORTECONOMY`, `SORTDEFENSE`, `SORTSTRATEGIC`, `SORTINTEL`, `SORTOTHER`, then the rest
    SORTOTHER = categoryValue,
    --- Lua-side (`lua/ui/game/construction.lua`): groups the unit in the build menu. Group order: `SORTCONSTRUCTION`, `SORTECONOMY`, `SORTDEFENSE`, `SORTSTRATEGIC`, `SORTINTEL`, `SORTOTHER`, then the rest
    SORTSTRATEGIC = categoryValue,
    SPECIALHIGHPRI = categoryValue,
    SPECIALLOWPRI = categoryValue,
    STATIONASSISTPOD = categoryValue,
    STEALTH = categoryValue,
    STEALTHFIELD = categoryValue,
    STEALTHPRESET = categoryValue,
    STRATEGICBOMBER = categoryValue,
    STRATEGIC = categoryValue,
    STRUCTURE = categoryValue,
    SUBCOMMANDER = categoryValue,
    SUBMERSIBLE = categoryValue,
    SUPPORTFACTORY = categoryValue,
    T1SUBMARINE = categoryValue,
    T2SUBMARINE = categoryValue,
    TACTICAL = categoryValue,
    TACTICALMISSILEPLATFORM = categoryValue,
    TANK = categoryValue,
    --- Engine: the unit leaves its formation on attack orders. Aircraft in it follow a moving target directly and ignore movement damping
    TARGETCHASER = categoryValue,
    TECH1 = categoryValue,
    TECH2 = categoryValue,
    TECH3 = categoryValue,
    TECH_TWO = categoryValue,
    TELEPORTBEACON = categoryValue,
    TORPEDO = categoryValue,
    TRANSPORTATION = categoryValue,
    TRANSPORTBUILTBYTIER1FACTORY = categoryValue,
    TRANSPORTBUILTBYTIER2FACTORY = categoryValue,
    TRANSPORTBUILTBYTIER3FACTORY = categoryValue,
    --- Engine (UI): with this transport selected, right-clicking a unit that cannot fly loads that unit
    TRANSPORTFOCUS = categoryValue,
    UEF = categoryValue,
    --- Not read by the engine or by Lua. Remove `SELECTABLE` to make a unit unselectable
    UNSELECTABLE = categoryValue,
    --- Lua-side (`lua/ui/dialogs/createunit.logic.lua`): hides the unit from the create unit (cheat spawn) dialog
    UNSPAWNABLE = categoryValue,
    --- Engine (UI): when the unit is not also `SELECTABLE`, the cursor cannot hover or target it. Also excludes it from `GetIdleEngineers`
    UNTARGETABLE = categoryValue,
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

    --- Engine: the unit can land on water. Introduced by https://github.com/FAForever/FA-Binary-Patches/pull/20
    CANLANDONWATER = categoryValue,
    --- Engine: the unit accepts upgrade orders while it is being built. Introduced by https://github.com/FAForever/FA-Binary-Patches/blob/master/section/BuildUnit.cpp
    CQUEMOV = categoryValue,
    --- Engine (UI): drag selection gives an unfinished unit with this category the lowest selection priority. Introduced by https://github.com/FAForever/FA-Binary-Patches/blob/master/section/selectionPriority.cpp
    LOWSELECTPRIO = categoryValue,
    --- Engine: a structure can't be built on top of a prop with this category. Introduced by https://github.com/FAForever/FA-Binary-Patches/pull/16
    --- Lua-side (`lua/sim/units/StructureUnit.lua`): the prop is not cleared when a structure starts building on top of it. Added to wreckage by `lua/system/blueprints-props.lua`
    OBSTRUCTSBUILDING = categoryValue,
    --- Engine: a `PATROLHELPER` unit with this category skips patrol reclaim and repair while moving in formation, like a `COMMAND` unit. The patch renames the engine's `SUBCOMMANDER` check to this category, and `lua/system/blueprints-units.lua` adds it to every `SUBCOMMANDER` unit. Introduced by https://github.com/FAForever/FA-Binary-Patches/pull/13
    SACU_BEHAVIOR = categoryValue,
    --- Engine (UI): without the patch, double-clicking a wall doesn't select the other walls of that type. The patch removes that exception. Introduced by https://github.com/FAForever/FA-Binary-Patches/blob/master/hooks/WallSelection.cpp
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
---| "PODSTAGINGPLATFORM"
---| "PRODUCTDL"
---| "PRODUCTFA"
---| "PRODUCTSC1"
---| "PROJECTILE"
---| "RADAR"
---| "RALLYPOINT"
---| "RAMBOPRESET"
---| "RASPRESET"
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