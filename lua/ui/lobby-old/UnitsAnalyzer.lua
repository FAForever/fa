-- ==========================================================================================
-- * File       : lua/modules/ui/lobby/UnitsAnalyzer.lua
-- * Authors    : FAF Community, HUSSAR
-- * Summary    : Provides logic on UI/lobby side for managing blueprints (Units, Structures, Enhancements)
-- *              using their IDs, CATEGORIES, TECH labels, FACTION affinity, etc.
-- ==========================================================================================

-- Holds info about a blueprint that is being loaded
local bpInfo = { ID = nil , Source = nil, Note = ''}
local bpIndex = 1

local cached = { Images = {}, Tooltips = {}, Enhancements = {} }

-- Stores blueprints of units and extracted enhancements
-- Similar to Sim's __blueprints but accessible only in UnitsManager
local blueprints = { All = {}, Original = {}, Modified = {}, Skipped = {} }
local projectiles = { All = {}, Original = {}, Modified = {}, Skipped = {} }

 -- Manages logs messages based on their type/importance/source
local logsTypes = {
    ["WARNING"] = true,  -- Recommend to keep it always true
    ["CACHING"] = false, -- Enable only for debugging
    ["PARSING"] = false, -- Enable only for debugging
    ["DEBUG"] = false, -- Enable only for debugging
    ["STATUS"] = true,
}

function Show(msgType, msg)
    if not logsTypes[msgType] then return end

    msg = 'UnitsAnalyzer ' .. msg
    if msgType == 'WARNING' then
        WARN(msg)
    else
        LOG(msg)
    end
end

-- Blueprints with these categories will be always loaded
-- even when they have other categories Skipped
CategoriesAllowed  = {
    ["SATELLITE"] = true, -- SATELLITEs are also UNTARGETABLE!
}

-- Blueprints with these categories/IDs will not be visualized
-- unless other categories are allowed in the CategoriesAllowed table
CategoriesSkipped  = {
    ["HOLOGRAM"] = true,
    ["CIVILIAN"] = true,
    ["OPERATION"] = true,
    ["FERRYBEACON"] = true,
    ["NOFORMATION"] = true,
    ["UNSELECTABLE"] = true,
    ["UNTARGETABLE"] = true,
    ["UNSPAWNABLE"] = true,
    ["DUMMYUNIT"] = true, -- cybran build drones
    ["EXTERNALFACTORYUNIT"] = true, -- used by mobile factories
    ["zxa0002"] = true,    -- used by mobile factories
    ["INSIGNIFICANTUNIT"] = true, -- drones, jamming crystal, lighting storm
    ["zxa0001"] = true,    -- Dummy unit for gifting unfinished buildings
    ["uab5103"] = true,    -- Aeon Quantum Gate Beacon
    ["uab5204"] = true,    -- Concrete
    ["ueb5204"] = true,    -- Concrete
    ["urb5204"] = true,    -- Concrete
    ["ueb5103"] = true,    -- UEF Quantum Gate Beacon
    ["urb5103"] = true,    -- Quantum Gateway Node
    ["ueb5208"] = true,    -- Sonar Beacon
    ["urb5206"] = true,    -- Tracking Device
    ["urb3103"] = true,    -- Scout-Deployed Land Sensor
    ["uxl0021"] = true,    -- Test Unit Arc Projectile
    ["xec9001"] = true,    -- Wall Segment Extra
    ["xec9002"] = true,    -- Wall Segment Extra
    ["xec9003"] = true,    -- Wall Segment Extra
    ["xec9002"] = true,    -- Wall Segment Extra
    ["xec9004"] = true,    -- Wall Segment Extra
    ["xec9005"] = true,    -- Wall Segment Extra
    ["xec9006"] = true,    -- Wall Segment Extra
    ["xec9007"] = true,    -- Wall Segment Extra
    ["xec9008"] = true,    -- Wall Segment Extra
    ["xec9009"] = true,    -- Wall Segment Extra
    ["xec9009"] = true,    -- Wall Segment Extra
    ["xec9009"] = true,    -- Wall Segment Extra
    ["xec9010"] = true,    -- Wall Segment Extra
    ["xec9011"] = true,    -- Wall Segment Extra
    ["brmgrnd1"] = true,
    ["brmgrnd2"] = true,
    ["brpgrnd1"] = true,
    ["brpgrnd2"] = true,
    ["brngrnd1"] = true,
    ["brngrnd2"] = true,
    ["brogrnd1"] = true,
    ["brogrnd2"] = true,
}

-- Blueprints with these categories will be hidden in tooltips
CategoriesHidden  = {
    ["NUKESUB"] = true,
    ["SPECIALLOWPRI"] = true,
    ["DESTROYER"] = true,
    ["T2SUBMARINE"] = true,
    ["NAVALCARRIER"] = true,
    ["HIGHALTAIR"] = true,
    ["PRODUCTFA"] = true,
    ["PRODUCTSC1"] = true,
    ["PRODUCTDL"] = true,
    ["BUILTBYLANDTIER1FACTORY"] = true,
    ["BUILTBYLANDTIER2FACTORY"] = true,
    ["BUILTBYLANDTIER3FACTORY"] = true,
    ["BUILTBYAIRTIER1FACTORY"] = true,
    ["BUILTBYAIRTIER2FACTORY"] = true,
    ["BUILTBYAIRTIER3FACTORY"] = true,
    ["BUILTBYNAVALTIER1FACTORY"] = true,
    ["BUILTBYNAVALTIER2FACTORY"] = true,
    ["BUILTBYNAVALTIER3FACTORY"] = true,
    ["BUILTBYTIER1FACTORY"] = true,
    ["BUILTBYTIER2FACTORY"] = true,
    ["BUILTBYTIER3FACTORY"] = true,
    ["BUILTBYTIER2SUPPORTFACTORY"] = true,
    ["BUILTBYTIER3SUPPORTFACTORY"] = true,
    ["BUILTBYTIER1ENGINEER"] = true,
    ["BUILTBYTIER2ENGINEER"] = true,
    ["BUILTBYTIER3ENGINEER"] = true,
    ["BUILTBYTIER4ENGINEER"] = true,
    ["BUILTBYTIER1FIELD"] = true,
    ["BUILTBYTIER2FIELD"] = true,
    ["BUILTBYTIER3FIELD"] = true,
    ["BUILTBYTIER1COMMANDER"] = true,
    ["BUILTBYTIER2COMMANDER"] = true,
    ["BUILTBYTIER3COMMANDER"] = true,
    ["BUILTBYTIER4COMMANDER"] = true,
    ["BUILTBYTIER1ORBITALFACTORY"] = true,
    ["BUILTBYTIER2ORBITALFACTORY"] = true,
    ["BUILTBYTIER3ORBITALFACTORY"] = true,
    ["BUILTBYTIER4ORBITALFACTORY"] = true,
    ["BUILTBYCOMMANDER"] = true,
    ["BUILTBYEXPERIMENTALSUB"] = true,
    ["BUILTBYQUANTUMGATE"] = true,
    ["BUILTBYGANTRY"] = true,
    ["VERIFYMISSILEUI"] = true,
    ["BUBBLESHIELDSPILLOVERCHECK"] = true,
    ["BENIGN"] = true,
    ["CAPTURE"] = true,
    ["CANNOTUSEAIRSTAGING"] = true,
    ["CANTRANSPORTCOMMANDER"] = true,
    ["CANNOTUSEAIRSTAGING"] = true,
    ["CONSTRUCTION"] = true,
    ["CONSTRUCTIONSORTDOWN"] = true,
    ["DRAGBUILD"] = true,
    ["ECONOMIC"] = true,
    ["INTELLIGENCE"] = true,
    ["RECLAIMABLE"] = true,
    ["RALLYPOINT"] = true,
    ["SHOWQUEUE"] = true,
    ["SPECIALHIGHPRI"] = true,
    ["SELECTABLE"] = true,
    ["HIGHPRIAIR"] = true,
    ["T1SUBMARINE"] = true,
    ["USEBUILDPRESETS"] = true,
    ["TRANSPORTFOCUS"] = true,
    ["TRANSPORTBUILTBYTIER3FACTORY"] = true,
    ["TRANSPORTBUILTBYTIER2FACTORY"] = true,
    ["TRANSPORTBUILTBYTIER1FACTORY"] = true,
    ["VISIBLETORECON"] = true,
    ["PODSTAGINGPLATFORM"] = true,
    ["STATIONASSISTPOD"] = true,
    ["OVERLAYCOUNTERINTEL"] = true,
    ["OVERLAYCOUNTERMEASURE"] = true,
    ["OVERLAYANTIAIR"] = true,
    ["OVERLAYSONAR"] = true,
    ["OVERLAYDIRECTFIRE"] = true,
    ["OVERLAYRADAR"] = true,
    ["OVERLAYOMNI"] = true,
    ["OVERLAYDEFENSE"] = true,
    ["OVERLAYANTINAVY"] = true,
    ["OVERLAYINDIRECTFIRE"] = true,
    ["OVERLAYMISC"] = true,
    ["ANTITELEPORT"] = true,
    ["ABILITYBUTTON"] = true,
    ["MOBILE"] = true,
    ["MOBILESONAR"] = true,
    ["TARGETCHASER"] = true,
    ["SIZE4"] = true,
    ["SIZE8"] = true,
    ["SIZE12"] = true,
    ["SIZE16"] = true,
    ["SIZE20"] = true,
    ["ISPREENHANCEDUNIT"] = true,
    ["REBUILDER"] = true,
    ["SORTOTHER"] = true,
    ["SORTINTEL"] = true,
    ["SORTCONSTRUCTION"] = true,
    ["SORTECONOMY"] = true,
    ["SORTDEFENSE"] = true,
    ["SORTSTRATEGIC"] = true,
    ["SILO"] = true,
    ["SHOWATTACKRETICLE"] = true,
    ["TACTICALMISSILEPLATFORM"] = true,
    ["NEEDMOBILEBUILD"] = true,
    ["PATROLHELPER"] = true,
    ["RESEARCH"] = true,
    ["MASSFABRICATION"] = true,
    ["MASSEXTRACTION"] = true,
    ["UPGRADE"] = true,
    ["PRODUCTBREWLAN"] = true,
    ["FAVORSWATER"] = true,
}

Factions = {
    { Name = 'AEON',     Color = 'FF238C00' }, ----FF238C00
    { Name = 'UEF',      Color = 'FF006CD9' }, ----FF006CD9
    { Name = 'CYBRAN',   Color = 'FFB32D00' }, ----FFB32D00
    { Name = 'SERAPHIM', Color = 'FFFFBF00' }, ----FFFFBF00
    { Name = 'NOMADS',   Color = 'FFFF7200' }, ----FFFF7200
    { Name = 'UNKNOWN',  Color = 'FFD619CE' }, ----FFD619CE
}

-- Gets unit's color based on faction of given blueprint
function GetUnitColor(bp)
    for _, faction in Factions do
        if faction.Name == bp.Faction then
            return faction.Color
        end
    end
    return 'FFD619CE'
end

-- Gets unit's faction based on categories of given blueprint
function GetUnitFaction(bp)
    local factionCategory = nil
    local factionName = bp.General.FactionName

    for _, faction in Factions do
        if bp.CategoriesHash[faction.Name] then
            factionCategory = faction.Name
            break
        end
    end
    -- validate if factionCategory and factionName are the same
    if not factionCategory then
        Show('WARNING', bp.Info..' - missing FACTION in bp.Categories')
    elseif not factionName then
        Show('WARNING', bp.Info..' - missing bp.General.FactionName')
    else
        if factionCategory ~= string.upper(factionName) then
            Show('WARNING', bp.Info..' - mismatch between ' .. factionCategory .. '  in bp.Categories and ' .. factionName .. ' in bp.General.FactionName')
        end
        return factionCategory
    end
    return 'UNKNOWN'
end

-- Gets unit's localizable name of given blueprint or show warning if not found
function GetUnitName(bp)
    local name = nil

    if bp.Interface.HelpText then
        name = bp.Interface.HelpText
    else
        if bp.General.UnitName then
            name = bp.General.UnitName
        elseif not bp.Merge then
            Show('WARNING', bp.Info..' - missing bp.General.UnitName')
        end
    end
    if name == 'MISSING NAME' then name = '' end

    return name
end

function GetUnitTitle(bp)
    local name = nil
    if bp.General.UnitName then
        name = LOCF(bp.General.UnitName)
    end

    if bp.Interface.HelpText then
        name = name and (name .. ' - ') or ''
        name = name .. LOCF(bp.Interface.HelpText)
    end

    if name == 'MISSING NAME' then name = '' end
    name = bp.Tech .. ' ' .. LOCF(bp.Name)

    return name
end

-- Gets units tech level based on categories of given blueprint
function GetUnitTech(bp)
    if bp.CategoriesHash['TECH1'] then return 'T1' end
    if bp.CategoriesHash['TECH2'] then return 'T2' end
    if bp.CategoriesHash['TECH3'] then return 'T3' end
    if bp.CategoriesHash['COMMAND'] then return '' end
    if bp.CategoriesHash['EXPERIMENTAL'] then return 'T4' end

    if not bp.Merge then
       Show('WARNING', bp.Info..' - missing TECH in bp.Categories')
    end

    return "T?"
end

-- Gets units type based on categories of given blueprint
function GetUnitType(bp)
    if bp.CategoriesHash['STRUCTURE'] then return 'BASE' end
    if bp.CategoriesHash['AIR'] then return 'AIR' end
    if bp.CategoriesHash['LAND'] then return 'LAND' end
    if bp.CategoriesHash['NAVAL'] then return 'NAVAL' end
    if bp.CategoriesHash['HOVER'] then return 'HOVER' end

    if not bp.Merge then
       Show('WARNING', bp.Info..' - missing TYPE in bp.Categories')
    end

    return "UNKNOWN"
end

-- Gets a path to an image representing a given blueprint and faction
-- Improved version of UIUtil.UIFile() function
function GetImagePath(bp, faction)
    local root = ''
    local id = bp.ID or ''
    local icon = bp.Icon or ''

    -- Check if image was cached already
    if cached.Images[faction..id] then
        return cached.Images[faction..id]
    end

    if cached.Images[faction..icon] then
        return cached.Images[faction..icon]
    end

    if icon and DiskGetFileInfo(icon) then
        return icon
    end

    local paths = {
        '/textures/ui/common/icons/units/',
        '/textures/ui/common/icons/',
        '/textures/ui/common/faction_icon-lg/',
        '/icons/units/',
        '/units/'..id..'/',
    }

    if bp.Type == 'UPGRADE' then
        paths = {'/textures/ui/common/game/'..faction..'-enhancements/'}
    end

    local name = ''
    -- First check for icon in game textures
    for _, path in paths do
        name = path .. id .. '_icon.dds'
        if DiskGetFileInfo(name) then
            cached.Images[faction..id] = name
            return name
        end

        name = path .. icon
        if not string.find(icon,'.dds') then
            name = name .. '_btn_up.dds'
        end

        if DiskGetFileInfo(name) then
            cached.Images[faction..icon] = name
            return name
        end
    end

    -- Next find an icon if one exist in mod's textures folder
    if bp.Mod then
        root = bp.Mod.location
        for _,path in paths do
            name = root .. path .. id .. '_icon.dds'
            if DiskGetFileInfo(name) then
                cached.Images[faction..id] = name
                return name
            end
            name = root .. path .. icon
            if not string.find(icon,'.dds') then
                name = name .. '_btn_up.dds'
            end
            if DiskGetFileInfo(name) then
                cached.Images[faction..icon] = name
                return name
            end
        end
    end

    -- Default to unknown icon if not found icon for the blueprint
    local unknown = '/textures/ui/common/icons/unknown-icon.dds'
    cached.Images[faction..id] = unknown

    return unknown
end

local function stringPad(text, spaces)
    local len = string.len(text)
    if spaces > len then
        return string.rep(' ', spaces - len) .. text
    end

    return text
end

local function init(value)
    return value >= 1 and value or 0
end

-- Gets Economy stats for unit/enhancement blueprint and calculates production yield
function GetEconomyStats(bp)
    local eco = {}

    if bp.Economy then -- Unit
        eco.BuildCostEnergy = init(bp.Economy.BuildCostEnergy)
        eco.BuildCostMass = init(bp.Economy.BuildCostMass)

        eco.BuildTime = init(bp.Economy.BuildTime)
        eco.BuildRate = init(bp.Economy.BuildRate)

        local pods = table.getsize(bp.Economy.EngineeringPods)
        if pods > 1 then
             -- Multiply by number of UEF engineering station pods
            eco.BuildRate = eco.BuildRate * pods
        end

        eco.YieldMass = -init(bp.Economy.MaintenanceConsumptionPerSecondMass)
        eco.YieldMass = eco.YieldMass + init(bp.Economy.ProductionPerSecondMass)

        eco.YieldEnergy = -init(bp.Economy.MaintenanceConsumptionPerSecondEnergy)
        eco.YieldEnergy = eco.YieldEnergy + init(bp.Economy.ProductionPerSecondEnergy)
    else -- Enhancement
        eco.BuildCostEnergy = init(bp.BuildCostEnergy)
        eco.BuildCostMass = init(bp.BuildCostMass)
        eco.BuildTime = init(bp.BuildTime)
        eco.BuildRate = init(bp.NewBuildRate)

        eco.YieldMass = -init(bp.MaintenanceConsumptionPerSecondMass)
        eco.YieldMass = eco.YieldMass + init(bp.ProductionPerSecondMass)

        eco.YieldEnergy = -init(bp.MaintenanceConsumptionPerSecondEnergy)
        eco.YieldEnergy = eco.YieldEnergy + init(bp.ProductionPerSecondEnergy)
    end

    eco.BuildCostEnergy = math.round(eco.BuildCostEnergy)
    eco.BuildCostMass = math.round(eco.BuildCostMass)

    eco.BuildRate = math.round(eco.BuildRate)
    eco.BuildTime = math.round(eco.BuildTime)

    eco.YieldMass = math.round(eco.YieldMass)
    eco.YieldEnergy = math.round(eco.YieldEnergy)

    return eco
end

-- Some calculation based on this code
-- https://github.com/spooky/unitdb/blob/master/app/js/dps.js
-- Gets shots per second of specified weapon (inverse of RateOfFire)
function GetWeaponRatePerSecond(bp, weapon)
    local rate = weapon.RateOfFire or 1
    return math.round(10 / rate) / 10 -- Ticks per second
end

function GetWeaponDefaults(bp, w)
    local weapon = table.deepcopy(w)
    weapon.Category = w.WeaponCategory or '<MISSING_CATEGORY>'
    weapon.DisplayName = weapon.DisplayName or '<MISSING_DISPLAYNAME>'
    weapon.Info = string.format("%s (%s)", weapon.DisplayName, weapon.Category)

    weapon.BuildCostEnergy = bp.Economy.BuildCostEnergy or 0
    weapon.BuildCostMass = bp.Economy.BuildCostMass or 0
    weapon.BuildTime = 0 -- Not including built time of the unit

    weapon.Count = 1
    weapon.Multi = 1
    weapon.Range = math.round(weapon.MaxRadius or 0)
    weapon.Damage = GetWeaponDamage(weapon)
    weapon.RPS = GetWeaponRatePerSecond(bp, weapon)
    weapon.DPS = -1

    return weapon
end

-- Get damage of nuke weapon or normal weapon
function GetWeaponDamage(weapon)
    local damage = 0
    if weapon.NukeWeapon then -- Stack nuke damages
        damage = (weapon.NukeInnerRingDamage or 0)
        damage = (weapon.NukeOuterRingDamage or 0) + damage
    else -- Normal weapon
        damage = (weapon.Damage or 0)
    end

    return damage
end

-- Get specs for a weapon with projectiles
function GetWeaponProjectile(bp, weapon)

    -- note we cannot use global __blueprints variable here because it is created on SIM side 
    -- when the game is being loaded so we using local blueprints variable created in this file
    local split = 1
    local projPhysics = blueprints[weapon.ProjectileId].Physics
    while projPhysics do
        split = split * (projPhysics.Fragments or 1)
        projPhysics = blueprints[projPhysics.FragmentId].Physics
    end
    weapon.Multi = split

    -- NOTE that weapon.ProjectilesPerOnFire is not used at all in FA game
    if weapon.MuzzleSalvoSize > 1 then
       weapon.Multi = weapon.Multi * weapon.MuzzleSalvoSize
    end

    local projID = string.lower(weapon.ProjectileId or '')
    local proj = projectiles.All[projID]
    if proj and proj.Economy then
        weapon.BuildCostEnergy = weapon.BuildCostEnergy + (proj.Economy.BuildCostEnergy or 0)
        weapon.BuildCostMass = weapon.BuildCostMass + (proj.Economy.BuildCostMass or 0)

        if proj.Economy.BuildTime and bp.Economy.BuildRate then
            weapon.RPS = proj.Economy.BuildTime / bp.Economy.BuildRate
        end
    end

    weapon.DPS = (weapon.Multi * weapon.Damage) / weapon.RPS
    weapon.DPS = math.round(weapon.DPS)

    return weapon
end

-- Get specs for a weapon with beam pulses
function GetWeaponBeamPulse(bp, weapon)
    if weapon.BeamLifetime then
        if weapon.BeamCollisionDelay > 0 then
           weapon.Multi = weapon.BeamCollisionDelay
        end

        if weapon.BeamLifetime > 0 then
           weapon.Multi = weapon.Multi * weapon.BeamLifetime * 10
        end

        -- Rate per second
        weapon.RPS = GetWeaponRatePerSecond(bp, weapon)
        weapon.DPS = (weapon.Multi * weapon.Damage) / weapon.RPS
        weapon.DPS = math.round(weapon.DPS)
    end

    return weapon
end

-- Get specs for a weapon with continuous beam
function GetWeaponBeamContinuous(bp, weapon)
    if weapon.ContinuousBeam then
       weapon.Multi = 10
       -- Rate per second
       weapon.RPS = weapon.BeamCollisionDelay == 0 and 1 or 2
       weapon.DPS = (weapon.Multi * weapon.Damage) / weapon.RPS
       weapon.DPS = math.round(weapon.DPS)
    end

    return weapon
end

-- Get specs for a weapon with dots per pulses
function GetWeaponDOT(bp, weapon)
    if weapon.DoTPulses then
        local initial = GetWeaponProjectile(bp, weapon)
        weapon.Multi = (weapon.MuzzleSalvoSize or 1) * weapon.DoTPulses
        -- Rate per second
        weapon.RPS = GetWeaponRatePerSecond(bp, weapon)
        weapon.DPS = (initial.DPS + weapon.Multi * weapon.Damage) / weapon.RPS
        weapon.DPS = math.round(weapon.DPS)
    end

    return weapon
end

-- Gets specs for a weapon
function GetWeaponSpecs(bp, weapon)
    weapon = GetWeaponDefaults(bp, weapon)

    if weapon.DoTPulses then
        weapon = GetWeaponDOT(bp, weapon)
    elseif weapon.ContinuousBeam then
        weapon = GetWeaponBeamContinuous(bp, weapon)
    elseif weapon.BeamLifetime then
        weapon = GetWeaponBeamPulse(bp, weapon)
    else
        weapon = GetWeaponProjectile(bp, weapon)
    end

    return weapon
end

-- Gets weapons stats in given blueprint, more accurate than in-game unitviewDetails.lua
function GetWeaponsStats(bp)
    local weapons = {}

    -- TODO fix bug: SCU weapons (rate, damage, range) are not updated with values from enhancements!
    -- TODO fix bug: SCU presets for SERA faction, have all weapons from all enhancements!
    -- Check bp.EnhancementPresetAssigned.Enhancements table to get accurate stats
    for id, w in bp.Weapon or {} do
        local damage = GetWeaponDamage(w)
        -- Skipping not important weapons, e.g. UEF shield boat fake weapon
        if w.WeaponCategory and
           w.WeaponCategory ~= 'Death' and
           w.WeaponCategory ~= 'Teleport' and
           damage > 0 then

           local weapon = GetWeaponSpecs(bp, w)
           weapon.DPM = weapon.Damage / weapon.BuildCostMass
           weapon.DPE = weapon.Damage / weapon.BuildCostEnergy
           weapon.Damage = math.round(weapon.Damage)
           weapons[id] = weapon
        end
    end

    -- Grouping weapons based on their name/category
    local groupWeapons = {}
    for i, weapon in weapons do
        local id = weapon.DisplayName .. '' .. weapon.Category
        if groupWeapons[id] then -- Count duplicated weapons
           groupWeapons[id].Count = groupWeapons[id].Count + 1
           groupWeapons[id].Damage = groupWeapons[id].Damage + weapon.Damage
           groupWeapons[id].DPS = groupWeapons[id].DPS + weapon.DPS
           groupWeapons[id].DPM = groupWeapons[id].DPM + weapon.DPM
        else
           groupWeapons[id] = table.deepcopy(weapon)
        end
    end

    -- Sort weapons by category (Defense weapons first)
    weapons = table.indexize(groupWeapons)
    table.sort(weapons, function(a, b)
        if a.WeaponCategory == 'Defense' and
           b.WeaponCategory ~= 'Defense' then
            return true
        elseif a.WeaponCategory ~= 'Defense' and
               b.WeaponCategory == 'Defense' then
            return false
        else
            return tostring(a.WeaponCategory) > tostring(b.WeaponCategory)
        end
    end)

    return weapons
end

function GetWeaponsTotal(weapons)
    local total = {}
    total.Range = 100000
    total.Count = 0
    total.Damage = 0
    total.DPM = 0
    total.DPS = 0

    for i, weapon in weapons or {} do
        -- Including only important weapons
        if weapon.Category and
            weapon.Category ~= 'Death' and
            weapon.Category ~= 'Defense' and
            weapon.Category ~= 'Teleport' then
            total.Damage = total.Damage + weapon.Damage
            total.DPM = total.DPM + weapon.DPM
            total.DPS = total.DPS + weapon.DPS
            total.Count = total.Count + 1
            total.Range = math.min(total.Range, weapon.Range)
        end
    end

    total.Category = 'All Weapons'
    total.DisplayName = 'Total'
    total.Info = string.format("%s (%s)", total.DisplayName, total.Category)

    return total
end

-- Returns unit's categories that should not be hidden in tooltips
function GetUnitsCategories(bp, showAll)
    local ret = {}

    if showAll then
        ret = bp.CategoriesHash
    else
        for key, val in bp.CategoriesHash do
            local category = key
            -- Ensure categories are nicely formatted
            if category == 'MASSPRODUCTION' then
                category = 'MASS PRODUCTION'
            elseif category == 'MASSSTORAGE' then
                category = 'MASS STORAGE'
            elseif category == 'ENERGYPRODUCTION' then
                category = 'ENERGY PRODUCTION'
            elseif category == 'ENERGYSTORAGE' then
                category = 'ENERGY STORAGE'
            elseif category == 'SUPPORTFACTORY' then
                category = 'SUPPORT FACTORY'
            elseif category == 'ENGINEERSTATION' then
                category = 'ENGINEER-STATION'
            elseif category == 'COUNTERINTELLIGENCE' then
                category = 'COUNTER-INTELLIGENCE'
            elseif category == 'INDIRECTFIRE' then
                category = 'INDIRECT-FIRE'
            elseif category == 'DIRECTFIRE' then
                category = 'DIRECT-FIRE'
            elseif category == 'OBRITALSYSTEM' then
                category = 'OBRITAL-SYSTEM'
            elseif category == 'GROUNDATTACK' then
                category = 'GROUND-ATTACK'
            end
            -- Ensures name of enhancements are nicely formatted
            if cached.Enhancements[category] then
                category = 'UPGRADE ' .. StringSplitCamel(category)
            end
            if not CategoriesHidden[category] and
               not StringStarts(category, 'BUILTBY') and
               not StringStarts(category, 'DUMMY') then
                -- Ensures all categories have the same case
                ret[string.upper(category)] = true
            end
        end
    end

    -- Help showing difference between Support and HQ factories
    if bp.CategoriesHash['FACTORY'] and
       bp.CategoriesHash['STRUCTURE'] and
       not bp.CategoriesHash['TECH1'] and -- T1 factories are the same
       not bp.CategoriesHash['GATE'] then
        ret['FACTORY'] = false -- hiding FACTORY* duplicate
        if not bp.CategoriesHash['SUPPORTFACTORY']  then
           ret['HQ FACTORY'] = true
        end
    end

    return table.hashkeys(ret, true)
end

-- Creates basic tooltip for given blueprints based on its categories, name, and source
function GetTooltip(bp)
    -- Create unique key for caching tooltips
    local key = bp.Source .. ' {' .. bp.Name .. '}'

    if cached.Tooltips[key] then
        return cached.Tooltips[key]
    end

    local tooltip = {
        text = '',
        body = ''
    }

    tooltip.text = LOCF(bp.Name)
    if bp.Tech then
        tooltip.text = bp.Tech .. ' ' .. tooltip.text
    end

    for category, _ in bp.CategoriesHash or {} do
        if not CategoriesHidden[category] then
            tooltip.body = tooltip.body .. category .. ' \n'
        end
    end

    if bp.Source then
        tooltip.body = tooltip.body .. ' \n BLUEPRINT: ' .. bp.Source .. ' \n'
    end

    if bp.ID then
        tooltip.body = tooltip.body .. ' \n ID: ' .. bp.ID .. ' \n'
    end

    if bp.ImagePath then
        tooltip.body = tooltip.body .. ' \n : ' .. bp.ImagePath .. ' \n'
    end

    if bp.Mod then
        tooltip.body = tooltip.body .. ' \n --------------------------------- '
        tooltip.body = tooltip.body .. ' \n MOD: ' .. bp.Mod.name
        tooltip.body = tooltip.body .. ' \n --------------------------------- '
    end

    tooltip.text = tooltip.text or ''
    tooltip.body = tooltip.body or ''
    -- Save tooltip for re-use
    cached.Tooltips[key] = tooltip

    return tooltip
end

-- Checks if a unit contains specified ID
function ContainsID(unit, value)
    if not unit then return false end
    if not unit.ID then return false end
    if not value then return false end
    return string.upper(value) == string.upper(unit.ID)
end

--- Checks if a unit contains specified faction
function ContainsFaction(unit, value)
    if not unit then return false end
    if not value then return false end
    return string.upper(value) == unit.Faction
end

--- Checks if a unit contains specified categories
function ContainsCategory(unit, value)
    if not value then return false end
    if not unit then return false end
    if not unit.CategoriesHash then return false end
    return unit.CategoriesHash[value]
end

--- Checks if a unit contains categories in specified expression
--- e.g. Contains(unit, '(LAND * ENGINEER) + AIR')
--- this function is similar to ParseEntityCategoryProperly (CategoryUtils.lua)
--- but it works on UI/lobby side
function Contains(unit, expression)
    if not expression or expression == '' or
       not unit then
       return false
    end

    local OPERATORS = { -- Operations
        ["("] = true,
        [")"] = true,
        -- Operation on categories: a, b
        ["*"] = function(a, b) return a and b end, -- Intersection and category
        ["-"] = function(a, b) return a and not b end, -- Subtraction not category
        ["+"] = function(a, b) return a or  b end, -- Union or  category
    }

    expression = '('..expression..')'
    local tokens = {}
    local currentIdentifier = ""
    expression:gsub(".", function(c)
    -- If we were collecting an identifier, we reached the end of it.
        if (OPERATORS[c] or c == " ") and currentIdentifier ~= "" then
            table.insert(tokens, currentIdentifier)
            currentIdentifier = ""
        end

        if OPERATORS[c] then
            table.insert(tokens, c)
        elseif c ~= " " then
            currentIdentifier = currentIdentifier .. c
        end
    end)

    local numTokens = table.getn(tokens)
    local function explode(error)
        WARN("Category parsing failed for expression:")
        WARN(expression)
        WARN("Tokenizer interpretation:")
        WARN(repr(tokens))
        WARN("Error from parser:")
        WARN(debug.traceback(nil, error))
    end

    -- Given the token list and an offset, find the index of the matching bracket.
    local function getExpressionEnd(firstBracket)
        local bracketDepth = 1

        -- We're done when bracketDepth = 0, as it means we've just hit the closing bracket we want.
        local i = firstBracket + 1
        while (bracketDepth > 0 and i <= numTokens) do
            local token = tokens[i]

            if token == "(" then
                bracketDepth = bracketDepth + 1
            elseif token == ")" then
                bracketDepth = bracketDepth - 1
            end
            i = i + 1
        end

        if bracketDepth == 0 then
            return i - 1
        else
            explode("Mismatched bracket at token index " .. firstBracket)
        end
    end
    -- Given two categories and an operator token, return the result of applying the operator to
    -- the two categories (in the order given)
    local function getSolution(currentCategory, newCategory, operator)
        -- Initialization case.
        if not operator and not currentCategory then
            return newCategory
        end

        if OPERATORS[operator] then
            local matching = OPERATORS[operator](currentCategory, newCategory)
            return matching
        else
            explode('Cannot getSolution for operator: ' .. operator)
            return false
        end
    end

    local function ParseSubexpression(start, finish)
        local currentCategory = nil
        -- Type of the next token we expect (want alternating identifier/operator)
        local expectingIdentifier = true
        -- The last operator encountered.
        local currentOperator = nil
        -- We need to be able to manipulate 'i' while iterating, hence...
        local i = start
        while i <= finish do
            local token = tokens[i]

            if expectingIdentifier then
                -- Bracket expressions are effectively identifiers
                if token == "(" then
                    -- Scan to the matching bracket, parse that subexpression, and current-operator
                    -- the result onto the working category.
                    local subcategoryEnd = getExpressionEnd(i)
                    local subcategory = ParseSubexpression(i + 1, subcategoryEnd - 1)

                    currentCategory = getSolution(currentCategory, subcategory, currentOperator)

                    -- We want 'i' to end up beyond the bracket, and to end up *not* expecting indent,
                    -- as a bracket expression is effectively an indent.
                    i = subcategoryEnd
                elseif OPERATORS[token] then
                    explode("Expected category identifier, found OPERATOR " .. token)
                    return nil
                else
                    -- Match token with unit ID or unit categories
                    local matching = ContainsID(unit, token) or
                                     ContainsCategory(unit, token)
                    currentCategory = getSolution(currentCategory, matching, currentOperator)
                end
            else
                if not OPERATORS[token] then
                    explode("Expected operator, found category identifier: " .. token)
                    return nil
                end
                currentOperator = token
            end
            expectingIdentifier = not expectingIdentifier
            i = i + 1
        end

        return currentCategory
    end
    local isMatching = ParseSubexpression(1, numTokens)

    return isMatching
end

-- Gets units with categories/id/enhancement that match specified expression
function GetUnits(bps, expression)
    local matches = {}
    local index = 1
    for id, bp in bps do
        local isMatching = Contains(bp, expression)
        if isMatching then
            matches[id] = bp
            index = index + 1
        end
    end

    return matches
end

-- Groups units based on their categories
-- @param bps is table with blueprints
-- @param faction is table with { Name = 'FACTION' }
function GetUnitsGroups(bps, faction)
    -- NOTE these unit groupings are for visualization purpose only
    local TECH4ARTY = '(EXPERIMENTAL * ARTILLERY - FACTORY - LAND)' -- mobile factory (FATBOY)
    -- xrl0002 Crab Egg (Engineer)
    -- xrl0003 Crab Egg (Brick)
    -- xrl0004 Crab Egg (Flak)
    -- xrl0005 Crab Egg (Artillery)
    -- drlk005 Crab Egg (Bouncer)
    local CRABEGG = 'xrl0002 + xrl0003 + xrl0004 + xrl0005 + drlk005'
    -- Including crab eggs with factories so they are not confused with actual units built from crab eggs
    local FACTORIES = '((FACTORY * STRUCTURE) + ' .. CRABEGG .. ')'
    local ENGINEERS = '(ENGINEER - COMMAND - SUBCOMMANDER - UPGRADE)'
    local DRONES = '(POD - UPGRADE)'
    local DEFENSES = '(ANTINAVY + DIRECTFIRE + ARTILLERY + ANTIAIR + MINE + ORBITALSYSTEM + SATELLITE + NUKE)'

    if table.empty(faction.Blueprints) then
        faction.Blueprints = GetUnits(bps, faction.Name)
    end
    faction.Units = {}
    -- Grouping ACU/SCU upgrades in separate tables because they have different cost/stats
    faction.Units.ACU       = GetUnits(faction.Blueprints, 'COMMAND + UPGRADE - SUBCOMMANDER - CIVILIAN')
    faction.Units.SCU       = GetUnits(faction.Blueprints, 'SUBCOMMANDER + UPGRADE - COMMAND - CIVILIAN')
    local mobileUnits       = GetUnits(faction.Blueprints, '('..faction.Name..' - UPGRADE - COMMAND - SUBCOMMANDER - STRUCTURE - CIVILIAN)')
    faction.Units.AIR       = GetUnits(mobileUnits, '(AIR - POD - SATELLITE)')
    faction.Units.LAND      = GetUnits(mobileUnits, '(LAND - ENGINEER - POD - '..TECH4ARTY..')')
    faction.Units.NAVAL     = GetUnits(mobileUnits, '(NAVAL - MOBILESONAR)')
    local buildings         = GetUnits(faction.Blueprints, '(STRUCTURE + MOBILESONAR + '..TECH4ARTY..' - CIVILIAN)')
    faction.Units.CONSTRUCT = GetUnits(faction.Blueprints, '('..FACTORIES..' + '..ENGINEERS..' + ENGINEERSTATION + '..DRONES..' - DEFENSE)')
    faction.Units.ECONOMIC  = GetUnits(buildings, '(STRUCTURE * ECONOMIC)')
    faction.Units.SUPPORT   = GetUnits(buildings, '(WALL + HEAVYWALL + INTELLIGENCE + SHIELD + AIRSTAGINGPLATFORM - ECONOMIC - ' ..DEFENSES..')')
    faction.Units.CIVILIAN  = GetUnits(faction.Blueprints, '(CIVILIAN - ' ..DEFENSES..')')

    faction.Units.DEFENSES  = GetUnits(buildings, DEFENSES)
    -- Collect not grouped units from above tables into the DEFENSES table
    -- This way we don't miss showing un-grouped units
    for ID, bp in faction.Blueprints do
        if not faction.Units.ACU[ID] and
           not faction.Units.SCU[ID] and
           not faction.Units.AIR[ID] and
           not faction.Units.LAND[ID] and
           not faction.Units.NAVAL[ID] and
           not faction.Units.CONSTRUCT[ID] and
           not faction.Units.ECONOMIC[ID] and
           not faction.Units.SUPPORT[ID] and
           not faction.Units.CIVILIAN[ID] and
           not faction.Units.DEFENSES[ID] then

           faction.Units.DEFENSES[ID] = bp
        end
    end

    if logsTypes.DEBUG then
        for group, units in faction.Units do
            LOG('UnitsAnalyzer '..faction.Name..' faction has ' .. table.getsize(units)..' ' .. group .. ' units')
        end
    end
    return faction
end

-- Cache enhancements as new blueprints with Categories, Faction from their parent (unit) blueprints
local function CacheEnhancement(key, bp, name, enh)
    enh.CategoriesHash = {}
    cached.Enhancements[name] = true

    if blueprints.All[key].CategoriesHash then
        enh.CategoriesHash = blueprints.All[key].CategoriesHash
    end

    local commanderType = ''
    enh.CategoriesHash['UPGRADE'] = true
    if bp.CategoriesHash['COMMAND'] then
        commanderType = 'ACU'
        enh.CategoriesHash['COMMAND'] = true
    elseif bp.CategoriesHash['SUBCOMMANDER'] then
        commanderType = 'SCU'
        enh.CategoriesHash['SUBCOMMANDER'] = true
    end

    -- Create some extra categories used for ordering enhancements in UI
    if enh.Slot then
        local slot = string.upper(enh.Slot)
        if slot == 'LCH' then
            enh.Slot = 'LEFT'
        elseif slot == 'RCH' then
            enh.Slot = 'RIGHT'
        elseif slot == 'BACK' then
            enh.Slot = 'BACK'
        end
        enh.CategoriesHash['UPGRADE '..enh.Slot] = true
    end

    enh.ID = name
    enh.Key = key
    enh.Faction = bp.Faction
    enh.Source = bp.Source
    enh.SourceID = StringExtract(bp.Source, '/', '_unit.bp', true)

    enh.Name = enh.Name or name
    enh.Type = 'UPGRADE'
    enh.Tech = enh.Slot
    enh.Mod = bp.Mod

    enh.CategoriesHash[bp.Faction] = true
    enh.CategoriesHash[name] = true

    if bp.Mod then
        blueprints.Modified[key] = enh
    else
        blueprints.Original[key] = enh
    end

    blueprints.All[key] = enh
end

-- Cache projectile blueprints
local function CacheProjectile(bp)
    if not bp then return end

    local id = string.lower(bp.Source)
    bp.Info = bp.Source or ''
    Show('CACHING', bp.Info .. '...')

    -- Converting categories to hash table for quick lookup
    if  bp.Categories then
        bp.CategoriesHash = table.hash(bp.Categories)
    end

    if bp.Mod then
        projectiles.Modified[id] = bp
    else
        projectiles.Original[id] = bp
    end

    projectiles.All[id] = bp
end

-- Checks for valid unit blueprints (not projectiles/effects)
function IsValidUnit(bp, id)
    if not bp or not id or string.len(id) <= 4 or string.find(id, '/') or CategoriesSkipped[id] then
        return false
    end

    if bp.Categories then
        for _, category in bp.Categories do
            if CategoriesAllowed[category] then
                return true
            elseif CategoriesSkipped[category] then
                return false
            end
        end
    end

    return true
end

-- Cache unit blueprints and extract their enhancements as new blueprints
local function CacheUnit(bp)
    if not bp then return end

    bp.ID = bp.BlueprintId
    bp.Info = bp.Source
    Show('CACHING', bp.Info .. '...')

    local id = bp.ID

    -- Skip processing of invalid units
    if not IsValidUnit(bp, id) then
        blueprints.Skipped[id] = bp
        return
    end

    bp.Faction = GetUnitFaction(bp)
    bp.Type = GetUnitType(bp)
    bp.Tech = GetUnitTech(bp)
    bp.Name = GetUnitName(bp)
    bp.Color = GetUnitColor(bp)

    if bp.Mod then
        blueprints.Modified[id] = bp
    else
        blueprints.Original[id] = bp
    end

    blueprints.All[id] = bp

    -- Extract and cache enhancements so they can be restricted individually
    for name, enh in bp.Enhancements or {} do
        -- Skip slots or 'removable' enhancements
        if name ~= 'Slots' and not string.find(name, 'Remove') then
            -- Some enhancements are shared between factions, e.g. Teleporter
            -- and other enhancements have different stats and icons
            -- depending on faction or whether they are for ACU or SCU
            -- so store each enhancement with unique key:
            local id = StringExtract(bp.Source, '/', '_unit.bp', true)
            local key = bp.Faction ..'_' .. id .. '_' .. name

            CacheEnhancement(key, bp, name, enh)
        end
    end
end

local mods = { Cached = {}, Active = {}, Changed = false }

-- Checks if game mods have changed between consecutive calls to this function
-- Thus returns whether or not blueprints need to be reloaded
function DidModsChanged()
    mods.All = import("/lua/mods.lua").GetGameMods()
    mods.Active = {}
    mods.Changed = false

    for _, mod in mods.All do
        mods.Active[mod.uid] = true
        if not mods.Cached[mod.uid] then
            mods.Changed = true
        end
    end
    mods.CachedCount = table.getsize(mods.Cached)
    mods.ActiveCount = table.getsize(mods.Active)

    if mods.CachedCount ~= mods.ActiveCount then
       mods.Changed = true
    end

    if mods.Changed then
        Show('STATUS', 'game mods changed from ' .. mods.CachedCount .. ' to ' .. mods.ActiveCount)
        mods.Cached = table.deepcopy(mods.Active)
    else
        Show('STATUS', 'game mods cached = ' .. mods.CachedCount)
    end
    mods.Active = nil

    return mods.Changed
end

local timer = CreateTimer()
-- Gets unit blueprints by loading them from the game and given active sim mods
function GetBlueprints(activeMods, skipGameFiles, taskNotifier)
    timer:Start('LoadBlueprints')

    blueprints.Loaded = false
    -- Load original FA blueprints only once
    local loadedGameFiles = not table.empty(blueprints.Original)
    if loadedGameFiles then
         skipGameFiles = true
    end

    local state = 'LoadBlueprints...'
    Show('STATUS', state)

    if DidModsChanged() or not skipGameFiles then
        blueprints.All = table.deepcopy(blueprints.Original)
        blueprints.Modified = {}
        blueprints.Skipped = {}

        projectiles.All = table.deepcopy(projectiles.Original)
        projectiles.Modified = {}
        projectiles.Skipped = {}

        if taskNotifier then
            local filesCount = 0
            -- calculate total updates based on number of files that Blueprints.lua will load
            if not skipGameFiles then
                filesCount = filesCount + table.getsize(DiskFindFiles('/projectiles', '*_proj.bp'))
                filesCount = filesCount + table.getsize(DiskFindFiles('/units', '*_unit.bp'))
            end
            for i, mod in activeMods or {} do
                filesCount = filesCount + table.getsize(DiskFindFiles(mod.location, '*_proj.bp'))
                filesCount = filesCount + table.getsize(DiskFindFiles(mod.location, '*_unit.bp'))
            end
            taskNotifier.totalUpdates = filesCount
        end

        -- allows execution of LoadBlueprints()
        doscript '/lua/system/Blueprints.lua'

        -- Loading projectiles first so that they can be used by units
        local dir = {'/projectiles'}
        bps = LoadBlueprints('*_proj.bp', dir, activeMods, skipGameFiles, true, true, taskNotifier)
        for _, bp in bps.Projectile do
            CacheProjectile(bp)
        end

        -- Loading units second so that they can use projectiles
        dir = {'/units'}
        bps = LoadBlueprints('*_unit.bp', dir, activeMods, skipGameFiles, true, true, taskNotifier)
        for _, bp in bps.Unit do
            if not string.find(bp.Source,'proj_') then
                CacheUnit(bp)
            end
        end
        state = state .. ' loaded: '
    else
        state = state .. ' cached: '
    end
    info = state .. table.getsize(projectiles.All) .. ' total ('
    info = info .. table.getsize(projectiles.Original) .. ' original, '
    info = info .. table.getsize(projectiles.Modified) .. ' modified, and '
    info = info .. table.getsize(projectiles.Skipped) .. ' skipped) projectiles'
    Show('STATUS', info)

    info = state .. table.getsize(blueprints.All) .. ' total ('
    info = info .. table.getsize(blueprints.Original) .. ' original, '
    info = info .. table.getsize(blueprints.Modified) .. ' modified and '
    info = info .. table.getsize(blueprints.Skipped) .. ' skipped) units'
    Show('STATUS', info)
    Show('STATUS', state .. 'in ' .. timer:Stop('LoadBlueprints'))

    blueprints.Loaded = true

    return blueprints
end

-- Gets all unit blueprints that were previously fetched
function GetBlueprintsList()
    return blueprints
end

local fetchThread = nil
-- Fetch asynchronously all unit blueprints from the game and given active sim mods
function FetchBlueprints(activeMods, skipGameFiles, taskNotifier)
    local bps = {}

    StopBlueprints()

    fetchThread = ForkThread(function()
        Show('STATUS', 'FetchBlueprints...')
        timer:Start('FetchBlueprints')
        local start = CurrentTime()
        bps = GetBlueprints(activeMods, skipGameFiles, taskNotifier)
        -- check if blueprints loading  is complete
        while not blueprints.Loaded do
            Show('STATUS', 'FetchBlueprints... tick')
            WaitSeconds(0.1)
        end
        timer:Stop('FetchBlueprints', true)
        Show('STATUS', 'FetchBlueprints...done')
        fetchThread = nil
        -- notify UnitManager UI about complete blueprint loading
        if taskNotifier then
           taskNotifier:Complete()
        end
    end)
end
function StopBlueprints()
    if fetchThread then
        KillThread(fetchThread)
        fetchThread = nil
    end
end
