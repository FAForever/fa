---@meta
---@declare-global

---@type EntityCategory
local categoryValue

categories = {
    ABILITYBUTTON = categoryValue,
    ADVANCEDCOMBATPRESET = categoryValue,
    AEON = categoryValue,
    AIR = categoryValue,
    AIRSTAGINGPLATFORM = categoryValue,
    ALLPROJECTILES = categoryValue,
    ALLUNITS = categoryValue,
    AMPHIBIOUS = categoryValue,
    ANTIAIR = categoryValue,
    ANTIAIRPRESET = categoryValue,
    ANTIMISSILE = categoryValue,
    ANTINAVY = categoryValue,
    ANTISHIELD = categoryValue,
    ANTISUB = categoryValue,
    ANTITORPEDO = categoryValue,
    ARTILLERY = categoryValue,
    ASF = categoryValue,
    BATTLESHIP = categoryValue,
    BENIGN = categoryValue,
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
    CANNOTUSEAIRSTAGING = categoryValue,
    CANTRANSPORTCOMMANDER = categoryValue,
    CAPTURE = categoryValue,
    CARRIER = categoryValue,
    --- Allows the unit to land on water. Is introduced by https://github.com/FAForever/FA-Binary-Patches/pull/20
    CANLANDONWATER = categoryValue,
    CIVILIAN = categoryValue,
    CIVILLIAN = categoryValue,
    CLOAKPRESET = categoryValue,
    COMBATPRESET = categoryValue,
    COMMAND = categoryValue,
    CONSTRUCTION = categoryValue,
    CONSTRUCTIONSORTDOWN = categoryValue,
    COUNTERINTELLIGENCE = categoryValue,
    CQUEMOV = categoryValue,
    CRABEGG = categoryValue,
    CRUISER = categoryValue,
    CYBRAN = categoryValue,
    DEBUG = categoryValue,
    DEFENSE = categoryValue,
    DEFENSIVEBOAT = categoryValue,
    DESTROYER = categoryValue,
    DIESTOOCDEPLETINGSHIELD = categoryValue,
    DIRECTFIRE = categoryValue,
    DRAGBUILD = categoryValue,
    DUMMYGSRWEAPON = categoryValue,
    DUMMYUNIT = categoryValue,
    ECONOMIC = categoryValue,
    ENERGYPRODUCTION = categoryValue,
    ENERGYSTORAGE = categoryValue,
    ENGINEER = categoryValue,
    ENGINEERPRESET = categoryValue,
    ENGINEERSTATION = categoryValue,
    EXPERIMENTAL = categoryValue,
    FACTORY = categoryValue,
    FAVORSWATER = categoryValue,
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
    INSIGNIFICANTUNIT = categoryValue,
    INTEL = categoryValue,
    INTELJAMMERPRESET = categoryValue,
    INTELLIGENCE = categoryValue,
    INVULNERABLE = categoryValue,
    ISPREENHANCEDUNIT = categoryValue,
    LAND = categoryValue,
    LIGHTBOAT = categoryValue,
    LOWSELECTPRIO = categoryValue,
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

    -- Allows this unit to be build by engineers
    NEEDMOBILEBUILD = categoryValue,
    NOFORMATION = categoryValue,
    --- Prevents splash damage being applied to the entity
    NOSPLASHDAMAGE = categoryValue,
    NUKE = categoryValue,
    NUKESUB = categoryValue,
    OMNI = categoryValue,
    OPERATION = categoryValue,
    OPTICS = categoryValue,
    ORBITALSYSTEM = categoryValue,
    OVERLAYANTIAIR = categoryValue,
    OVERLAYANTINAVY = categoryValue,
    OVERLAYCOUNTERINTEL = categoryValue,
    OVERLAYDEFENSE = categoryValue,
    OVERLAYDIRECTFIRE = categoryValue,
    OVERLAYINDIRECTFIRE = categoryValue,
    OVERLAYMISC = categoryValue,
    OVERLAYOMNI = categoryValue,
    OVERLAYRADAR = categoryValue,
    OVERLAYSONAR = categoryValue,
    PATROLHELPER = categoryValue,
    PERSONALSHIELD = categoryValue,
    POD = categoryValue,
    PODSTAGINGPLATFORM = categoryValue,
    PRODUCTDL = categoryValue,
    PRODUCTFA = categoryValue,
    PRODUCTSC1 = categoryValue,
    PROJECTILE = categoryValue,
    RADAR = categoryValue,
    RALLYPOINT = categoryValue,
    RAMBOPRESET = categoryValue,
    RASPRESET = categoryValue,
    RECLAIMABLE = categoryValue,
    RECLAIM = categoryValue,
    RECLAIMFRIENDLY = categoryValue,
    REPAIR = categoryValue,
    RESEARCH = categoryValue,
    SATELLITE = categoryValue,
    SCOUT = categoryValue,
    SELECTABLE = categoryValue,
    SERAPHIM = categoryValue,
    SHIELD = categoryValue,
    SHIELDCOLLIDE = categoryValue,
    SHIELDCOMBATPRESET = categoryValue,
    SHOWATTACKRETICLE = categoryValue,
    SHOWQUEUE = categoryValue,
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
    SORTCONSTRUCTION = categoryValue,
    SORTDEFENSE = categoryValue,
    SORTECONOMY = categoryValue,
    SORTINTEL = categoryValue,
    SORTOTHER = categoryValue,
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
    TRANSPORTFOCUS = categoryValue,
    UEF = categoryValue,
    UNSELECTABLE = categoryValue,
    UNSPAWNABLE = categoryValue,
    UNTARGETABLE = categoryValue,
    USEBUILDPRESETS = categoryValue,
    VERIFYMISSILEUI = categoryValue,
    VISIBLETORECON = categoryValue,
    VOLATILE = categoryValue,
    WALL = categoryValue,
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
    EXTERNALFACTORY = categoryValue
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
---| "NOFORMATION"
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
---| "TARGETCHASER"
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