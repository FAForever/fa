-- ******************************************************************************************
-- * File		: lua/modules/ui/lobby/UnitsAnalyzer.lua 
-- * Authors	: FAF Community, HUSSAR
-- * Summary  	: Provides logic on UI/lobby side for managing blueprints (Units, Structures, Enhancments) 
-- *              using their IDs, CATEGORIES, TECH lebels, FACTION affinity, etc. 
-- ******************************************************************************************
   
--local sub = string.sub
--local gsub = string.gsub 
 
-- holds info about a blueprint that is being loaded   
local bpInfo = { ID = nil , Source = nil, Note = ''}	
local bpIndex = 1
  
local cached = { Images = {}, Tooltips = {} }
 
-- stores blueprints of units and extracted enhancments 
-- similar to Sim's __blueprints but accessable on UI/lobby side
local blueprints = { All = {}, Original = {}, Modified = {}, Skipped = {} }
local projectiles = { All = {}, Original = {}, Modified = {}, Skipped = {} }

 -- manages logs messages based on their type/importance/source 
local logsTypes = {
    ["WARNING"] = true,  -- recommend to keep it always true
    ["SAVING"]  = false, -- enable only for debbuging
    ["PARSING"] = false, -- enable only for debbuging
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
-- blueprints with these categories will be always loaded 
-- even when they have other categories Skipped
CategoriesAllowed  = {
    ["SATELLITE"] = true, -- SATELLITEs are also UNTARGETABLE!
}  
-- blueprints with these categories/IDs will not be visualized 
-- unless other categories are allowed in the CategoriesAllowed table
CategoriesSkipped  = {	 
    ["HOLOGRAM"] = true,
    ["CIVILIAN"] = true,
    ["OPERATION"] = true,
    ["FERRYBEACON"] = true,  
    ["NOFORMATION"] = true,  
    ["UNSELECTABLE"] = true,
    ["UNTARGETABLE"] = true,
    ["uab5103"] = true,		-- Aeon Quantum Gate Beacon
    ["uab5204"] = true,		-- Concrete	    
    ["ueb5103"] = true,		-- UEF Quantum Gate Beacon
    ["urb5103"] = true,		-- Quantum Gateway Node
    ["ueb5204"] = true,		-- Concrete	 	 
    ["ueb5208"] = true,		-- Sonar Beacon
    ["urb5204"] = true,		-- Concrete	  
    ["urb5206"] = true,		-- Tracking Device
    ["urb3103"] = true,		-- Scout-Deployed Land Sensor
    ["uxl0021"] = true,		-- Test Unit Arc Projectile
    ["xec9001"] = true,		-- Wall Segment	Extra  
    ["xec9002"] = true,		-- Wall Segment	Extra  
    ["xec9003"] = true,		-- Wall Segment	Extra  
    ["xec9002"] = true,		-- Wall Segment	Extra  
    ["xec9004"] = true,		-- Wall Segment	Extra  
    ["xec9005"] = true,		-- Wall Segment	Extra  
    ["xec9006"] = true,		-- Wall Segment	Extra  
    ["xec9007"] = true,		-- Wall Segment	Extra  
    ["xec9008"] = true,		-- Wall Segment	Extra  
    ["xec9009"] = true,		-- Wall Segment	Extra  
    ["xec9009"] = true,		-- Wall Segment	Extra  
    ["xec9009"] = true,		-- Wall Segment	Extra   
    ["xec9010"] = true,		-- Wall Segment	Extra  
    ["xec9011"] = true,		-- Wall Segment	Extra  
    ["brmgrnd1"] = true,		 
    ["brmgrnd2"] = true,		 
    ["brpgrnd1"] = true,		 
    ["brpgrnd2"] = true,		 
    ["brngrnd1"] = true,		 
    ["brngrnd2"] = true,		 
    ["brogrnd1"] = true,		 
    ["brogrnd2"] = true,	
}
-- blueprints with these categories will be hidden in tooltips
CategoriesHidden  = {
	["NUKESUB"] = true,	 
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
	["BUILTBYTIER1COMMANDER"] = true,	 
	["BUILTBYTIER2COMMANDER"] = true,	 
	["BUILTBYTIER3COMMANDER"] = true,	 
	["BUILTBYCOMMANDER"] = true,	 
	["BUILTBYEXPERIMENTALSUB"] = true,	 
	["BUILTBYQUANTUMGATE"] = true,	 
	--["AIRSTAGINGPLATFORM"] = true,
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
}
   
Factions = {
	["AEON"] 	 = 'FF238C00', -- #FF238C00
	["UEF"]		 = 'FF006CD9', -- #FF006CD9
	["CYBRAN"] 	 = 'FFB32D00', -- #FFB32D00
	["SERAPHIM"] = 'FFFFBF00', -- #FFFFBF00
	["NOMADS"]   = 'FFFF7200', -- #FFFF7200
	["UNKNOWN"]  = 'ff808080',
}	

--- Gets unit's color based on faction of given blueprint	
function GetUnitColor(bp)
	return Factions[bp.Faction] or 
		   Factions['UNKNOWN']
end
--- Gets unit's faction based on categories of given blueprint
function GetUnitFaction(bp)
	local faction = bp.General.FactionName --or 'UNKNOWN'
	if faction then
	   faction = string.upper(faction)
       return faction 
	else
        if not bp.Merge then
            Show('WARNING', bp.Info..' - missing bp.General.FactionName')
		end
		-- using categories to find faction
		for name, _ in Factions do
			if bp.Categories[name] then 
				return name 
			end 
		end 
        if not bp.Merge then
		    Show('WARNING', bp.Info..' - missing FACTION in Categories')
		end
	end
	return 'UNKNOWN' 
end
--- Gets unit's localizable name of given blueprint or show warning if not found
function GetUnitName(bp)
    local name = nil  
    
    if bp.Interface.HelpText then
        name = bp.Interface.HelpText
    else
        if not bp.Merge then
            Show('WARNING', bp.Info..' - missing bp.Interface.HelpText')
        end
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
	local name = nil --bp.Interface.HelpText
	if bp.General.UnitName then
        name = LOCF(bp.General.UnitName) --.. ' - '
	end
    if bp.Interface.HelpText then
        name = name and (name .. ' - ' ) or ''
        name = name .. LOCF(bp.Interface.HelpText)
	end
    if name == 'MISSING NAME' then name = '' end
    name = bp.Tech .. ' ' .. LOCF(bp.Name)
	return name  
end
--- Gets units tech level based on categories of given blueprint
function GetUnitTech(bp)
	if bp.Categories['TECH1'] then return 'T1' end
	if bp.Categories['TECH2'] then return 'T2' end
	if bp.Categories['TECH3'] then return 'T3' end
	if bp.Categories['COMMAND'] then return 'T0' end 
	if bp.Categories['EXPERIMENTAL'] then return 'T4' end 
	
    if not bp.Merge then
       Show('WARNING', bp.Info..' - missing TECH in bp.Categories')
    end	
	return "T?"
end
--- Gets units type based on categories of given blueprint
function GetUnitType(bp)
	if bp.Categories['STRUCTURE'] then return 'BASE' end
	if bp.Categories['AIR'] then return 'AIR' end
	if bp.Categories['LAND'] then return 'LAND' end
	if bp.Categories['NAVAL'] then return 'NAVAL' end
	if bp.Categories['HOVER'] then return 'HOVER' end
	
    if not bp.Merge then
       Show('WARNING', bp.Info..' - missing TYPE in bp.Categories')
    end		 
	return "UNKNOWN"
end 
--- Gets a path to an image representing a given blueprint and faction
--- Improved version of UIUtil.UIFile() function
function GetImagePath(bp, faction)
	local root = ''
	local id = bp.ID or ''
	local icon = bp.Icon or ''
		
	-- check if image was cached already
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
		paths = {'/textures/ui/common/game/'..faction..'-enhancements/' } 
	end
	local name = ''
	-- first check for icon in game textures
	for _,path in paths do
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
	-- next overrid icon if one exist in mod textures
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
    -- if not found icon for the blueprint
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
    return value > 1 and value or 0 
end 

--- Gets Economy stats for unit/enhancement blueprint and calculates production yield
function GetEconomyStats(bp)
    local eco = {}
          
    if bp.Economy then -- unit
        eco.BuildCostEnergy = init(bp.Economy.BuildCostEnergy)  
        eco.BuildCostMass = init(bp.Economy.BuildCostMass)  

        eco.BuildTime = init(bp.Economy.BuildTime)  
        eco.BuildRate = init(bp.Economy.BuildRate)   
        
        local pods = table.getsize(bp.Economy.EngineeringPods)   
        if pods > 1 then
             -- multiply by number of UEF engineering station pods
            eco.BuildRate = eco.BuildRate * pods
        end 

        eco.YieldMass = -init(bp.Economy.MaintenanceConsumptionPerSecondMass)  
        eco.YieldMass = eco.YieldMass + init(bp.Economy.ProductionPerSecondMass)  
        
        eco.YieldEnergy = -init(bp.Economy.MaintenanceConsumptionPerSecondEnergy)  
        eco.YieldEnergy = eco.YieldEnergy + init(bp.Economy.ProductionPerSecondEnergy)  
        
    else -- enhancement 
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

--- gets shots pers second of specified weapon (inverse of RateOfFire)
function GetWeaponRatePerSecond(bp, weapon)
    local rate = weapon.RateOfFire or 1
    return math.round(10 / rate) / 10 -- ticks per second
end
function GetWeaponDefaults(bp, w)
    local weapon = table.deepcopy(w)
    weapon.Category = w.WeaponCategory or '<MISSING_CATEGORY>'
    weapon.DisplayName = weapon.DisplayName or '<MISSING_DISPLAYNAME>'
    weapon.Info = string.format("%s (%s)", weapon.DisplayName, weapon.Category)
     
    weapon.BuildCostEnergy = bp.Economy.BuildCostEnergy or 0
    weapon.BuildCostMass = bp.Economy.BuildCostMass or 0
    weapon.BuildTime = 0 -- not including built time of the unit
                  
    weapon.Count  = 1
    weapon.Multi  = 1   
    weapon.Range  = math.round(weapon.MaxRadius or 0)
    weapon.Damage = weapon.Damage or 0
    weapon.RPS    = GetWeaponRatePerSecond(bp, weapon) 
    weapon.DPS    = -1  
    return weapon
end
--- Get specs for a weapon with projectiles 
function GetWeaponProjectile(bp, weapon)
    -- multipliers is needed to properly calculate split projectiles. 
    -- Unfortunately these numbers hardcoded here are not available in the blueprint,
    -- but specified in the .lua files for corresponding projectiles.
    local multipliers = {  
        -- Lobo
        ['/projectiles/TIFFragmentationSensorShell01/TIFFragmentationSensorShell01_proj.bp'] = 4, 
        -- Zthuee
        ['/projectiles/SIFThunthoArtilleryShell01/SIFThunthoArtilleryShell01_proj.bp'] = 5 
    }
    --TODO mulit damage of Salvation by AOE

    --NOTE that weapon.ProjectilesPerOnFire is not used at all in FA game
    if weapon.ProjectileId then
       weapon.Multi = multipliers[weapon.ProjectileId] or 1
    end 

    if weapon.MuzzleSalvoSize == nil then 
        WARN('Weapon missing MuzzleSalvoSize ' .. tostring(weapon.DisplayName))
    else
        weapon.Multi = weapon.Multi * weapon.MuzzleSalvoSize
    end
    -- get nuke damage or regular damage
    weapon.Damage = weapon.NukeInnerRingDamage or weapon.Damage
      
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
--- Get specs for a weapon with beam pulses 
function GetWeaponBeamPulse(bp, weapon)
    if weapon.BeamLifetime then
        if weapon.BeamCollisionDelay > 0 then
           weapon.Multi = weapon.BeamCollisionDelay
        end
        if weapon.BeamLifetime > 0 then
           weapon.Multi = weapon.Multi * weapon.BeamLifetime * 10  
        end
        --weapon.Multi = (weapon.BeamCollisionDelay or 1) * 10  
        --weapon.Multi = weapon.Multi * (weapon.BeamLifetime or 1) 

        -- rate per second
        weapon.RPS = GetWeaponRatePerSecond(bp, weapon)
        weapon.DPS = (weapon.Multi * weapon.Damage) / weapon.RPS
        weapon.DPS = math.round(weapon.DPS)
    end
    return weapon
end
--- Get specs for a weapon with continous beam
function GetWeaponBeamContinous(bp, weapon)
    if weapon.ContinuousBeam then
       weapon.Multi = 10  
       -- rate per second
       weapon.RPS = weapon.BeamCollisionDelay == 0 and 1 or 2
       weapon.DPS = (weapon.Multi * weapon.Damage) / weapon.RPS
       weapon.DPS = math.round(weapon.DPS)
    end
    return weapon
end
--- Get specs for a weapon with dots per pulses 
function GetWeaponDOT(bp, weapon)
    if weapon.DoTPulses then
        local initial = GetWeaponProjectile(bp, weapon)
        weapon.Multi = (weapon.MuzzleSalvoSize or 1) * weapon.DoTPulses 
        -- rate per second
        weapon.RPS = GetWeaponRatePerSecond(bp, weapon)
        weapon.DPS = (initial.DPS + weapon.Multi * weapon.Damage) / weapon.RPS
        weapon.DPS = math.round(weapon.DPS)
    end
    return weapon
end
--- Gets specs for a weapon
function GetWeaponSpecs(bp, weapon)
    weapon = GetWeaponDefaults(bp, weapon)
    
    if weapon.DoTPulses then
        --LOG('GetWeaponDOT')
        weapon = GetWeaponDOT(bp, weapon)
    elseif weapon.ContinuousBeam then
        --LOG('GetWeaponBeamContinous')
        weapon = GetWeaponBeamContinous(bp, weapon)
    elseif weapon.BeamLifetime then
        --LOG('GetWeaponBeamPulse')
        weapon = GetWeaponBeamPulse(bp, weapon)
    else
        --LOG('GetWeaponProjectile')
        weapon = GetWeaponProjectile(bp, weapon)
    end

    return weapon
end

--- Gets weapons stats in given blueprint, more accurate than in-game unitviewDetails.lua
function GetWeaponsStats(bp)
    local weapons = {}
       
    --TODO fix bug: SCU weapons (rate, damage, range) are not updated with values from enhancements! 
    --TODO fix bug: SCU presets for SERA faction, have all weapons from all enhancements! 
    --check bp.EnhancementPresetAssigned.Enhancements table to get accurate stats

    for id, w in bp.Weapon or {} do
            
        if w.WeaponCategory and 
           w.WeaponCategory ~= 'Death' and 
           w.WeaponCategory ~= 'Teleport'then
            
           local weapon = GetWeaponSpecs(bp, w) 
           weapon.DPM = weapon.Damage / weapon.BuildCostMass
           weapon.DPE = weapon.Damage / weapon.BuildCostEnergy
           weapon.Damage = math.round(weapon.Damage) 
           weapons[id] = weapon   
        end
    end   
    -- groupping weapons based on their name/category
    local groupWeapons = {}
    for i, weapon in weapons do
        local id = weapon.DisplayName .. '' .. weapon.Category
        if groupWeapons[id] then -- count duplicated weapons
           groupWeapons[id].Count  = groupWeapons[id].Count  + 1
           groupWeapons[id].Damage = groupWeapons[id].Damage + weapon.Damage  
           groupWeapons[id].DPS    = groupWeapons[id].DPS    + weapon.DPS  
           groupWeapons[id].DPM    = groupWeapons[id].DPM    + weapon.DPM  
        else 
           groupWeapons[id] = table.deepcopy(weapon)
        end
    end 
    -- sort weapons by category (Defense weapons first)
    weapons = table.indexize(groupWeapons)
    table.sort(weapons, function(a,b)
        if a.WeaponCategory == 'Defense' and
           b.WeaponCategory ~= 'Defense' then
            return true  
        elseif a.WeaponCategory ~= 'Defense' and
               b.WeaponCategory == 'Defense'  then
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
    total.Count  = 0
    total.Damage = 0
    total.DPM    = 0
    total.DPS    = 0
    for i, weapon in weapons or {} do
        -- including only important weapons
        if weapon.Category and 
           weapon.Category ~= 'Death' and 
           weapon.Category ~= 'Defense' and
           weapon.Category ~= 'Teleport'  then
            total.Damage = total.Damage + weapon.Damage
            total.DPM    = total.DPM + weapon.DPM
            total.DPS    = total.DPS + weapon.DPS
            total.Count  = total.Count + 1
            total.Range  = math.min(total.Range, weapon.Range)
        end
    end
    total.Category    = 'All Weapons'
    total.DisplayName = 'Total'
    total.Info  = string.format("%s (%s)", total.DisplayName, total.Category)
      
    return total 
end

--- Returns unit's categories that should not be hidden in tooltips 
function GetUnitsCategories(bp, showAll)
    local ret = {}
    if bp.Categories then
		local categories = table.keys(bp.Categories)
        if showAll then
            return categories
        else
		    for _, category in categories do
			    if not CategoriesHidden[category] then 
                     table.insert(ret, category) 
                end
		    end
        end        
	end 
    return ret
end
--- Creates basic tooltip for given blueprints based on its categories, name, and source
function GetTooltip(bp)

    -- create unique key for caching tooltips
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
        --tooltip.body = tooltip.body .. ' ' .. bp.Tech .. ' \n\n' 
	end
	if bp.Categories then
		local categories = table.keys(bp.Categories)
		for _, category in categories do
			if not CategoriesHidden[category] then 
                tooltip.body = tooltip.body .. category .. ' \n'
            end
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
    -- save tooltip for re-use
    cached.Tooltips[key] = tooltip 
	
	return tooltip 
end
--- Checks if a unit contains specified ID 
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
	if not unit then return false end
	if not unit.Categories then return false end
	if not value then return false end
	return unit.Categories[value]
end
--- Checks if a unit contains categories in specified expression    
--- e.g. Contains(unit, '(LAND * ENGINEER) + AIR')
--- this function is simialar to ParseEntityCategoryProperly (CategoryUtils.lua) 
--- but it works on UI/lobby side
function Contains(unit, expression) 
	if not expression or expression == '' or 
	   not unit then
	   return false
	end
    local OPERATORS = { -- Operations
        ["("] = true,
        [")"] = true,
	    -- operation on categories: a, b 
        ["*"] = function(a, b) return a and b end,     -- Intersection	and category
        ["-"] = function(a, b) return a and not b end, -- Subtraction	not category
        ["+"] = function(a, b) return a or  b end, 	   -- Union			or  category
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
        -- type of the next token we expect (want alternating identifier/operator)
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
					-- match token with unit ID or unit categories
					local matching = ContainsID(unit, token) or 
									 --ContainsFaction(unit, token) or 
									 ContainsCategory(unit, token) 
                    currentCategory = getSolution(currentCategory, matching, currentOperator)
                end
            else
                if not OPERATORS[token] then
                    explode("Expected operator, found category identifier: " .. token)
                    return nil
                end
				--LOG('parsing.operator ' .. token .. ' ')
                currentOperator = token
            end
            expectingIdentifier = not expectingIdentifier
            i = i + 1
        end
        return currentCategory
    end
	
    local isMatching = ParseSubexpression(1, numTokens)
    --Show('PARSING', 'units is' .. isMatching .. ' contains ' )
	
    return isMatching
end
 
--- Gets units with categories/id/enhancement that match specified expression
function GetUnits(bps, expression)
	local matches = {}
	local index = 1
	for id, bp in bps do
		local isMatching = Contains(bp, expression)
		--log.Table(unit.Categories, 'unit.Categories')
		if isMatching then
			matches[id] = bp
			index = index + 1
		end
	end
	return matches
end
--- Groups units based on their categories
function GetUnitsGroups(bps, factionName)

    -- NOTE these unit groupings are for visualization purpose only
	   
	local TECH4ARTY = '(EXPERIMENTAL * ARTILLERY - FACTORY - LAND)' -- mobile factory (FATBOY)
	-- xrl0002 Crab Egg (Engineer)
    -- xrl0003 Crab Egg (Brick)
    -- xrl0004 Crab Egg (Flak)
    -- xrl0005 Crab Egg (Artillery) 
    -- drlk005 Crab Egg (Bouncer)
    local CRABEGG = 'xrl0002 + xrl0003 + xrl0004 + xrl0005 + drlk005'
	-- including crab eggs with factories so they are not confused with actual units built from crab eggs
	local FACTORIES = '((FACTORY * STRUCTURE) + ' .. CRABEGG .. ')'
	
	local faction = {}  
    faction.Name = factionName
	faction.Blueprints		= GetUnits(bps, factionName) 
	faction.Units = {}
    -- grupping ACU/SCU upgrades in seprate tables because they have different cost/stats
	faction.Units.ACU = GetUnits(faction.Blueprints, 'COMMAND + UPGRADE - SUBCOMMANDER')
	faction.Units.SCU = GetUnits(faction.Blueprints, 'SUBCOMMANDER + UPGRADE - COMMAND')
	faction.Units.ALL 		= GetUnits(bps, '('..factionName..' - UPGRADE - COMMAND - SUBCOMMANDER)' ) 
	faction.Units.AIR 		= GetUnits(faction.Units.ALL, '(AIR - STRUCTURE - POD - SATELLITE)')
	faction.Units.LAND 		= GetUnits(faction.Units.ALL, '(LAND  - STRUCTURE - ENGINEER - POD - '..TECH4ARTY..')')
	faction.Units.NAVAL 	= GetUnits(faction.Units.ALL, '(NAVAL - STRUCTURE - MOBILESONAR)')
	faction.Bases			= {}
	faction.Bases.ALL  		= GetUnits(faction.Units.ALL, '(STRUCTURE + MOBILESONAR + '..TECH4ARTY..')')
    faction.Bases.FACTORIES	= GetUnits(faction.Units.ALL, '('..FACTORIES..' + ENGINEER + ENGINEERSTATION + POD)')
	faction.Bases.ECONOMIC	= GetUnits(faction.Bases.ALL, '(STRUCTURE * ECONOMIC)')
	faction.Bases.SUPPORT	= GetUnits(faction.Bases.ALL, '(WALL + INTELLIGENCE + SHIELD + AIRSTAGINGPLATFORM - ECONOMIC)')
	
	faction.Bases.DEFENSES	= {}
	-- collect not grouped units above tables into the DEFENSES table
    -- this way we don't miss showing ungroupped units 
	for ID, bp in faction.Blueprints do
		if not faction.Units.ACU[ID] and 
		   not faction.Units.SCU[ID] and  
		   
		   not faction.Units.AIR[ID] and 
		   not faction.Units.LAND[ID] and 
		   not faction.Units.NAVAL[ID] and 
		   not faction.Bases.FACTORIES[ID] and 
		   not faction.Bases.ECONOMIC[ID] and
		   not faction.Bases.SUPPORT[ID] then  

    	   faction.Bases.DEFENSES[ID] = bp
        end
	end
     
	return faction
end
--- Cache enhancements as new blueprints with Categories, Faction from thier parent (unit) blueprints 
local function CacheEnhancement(key, bp, name, enh)	
    --Show('SAVING', name .. '...')
    local categories = {}

    if blueprints.All[key].Categories then
        categories = blueprints.All[key].Categories
    end
    local commanderType = ''
	categories['UPGRADE'] = true
	if bp.Categories['COMMAND'] then
        commanderType = 'ACU'
		categories['COMMAND'] = true
		--categories['UPGRADE_ACU'] = true
	elseif bp.Categories['SUBCOMMANDER'] then
		commanderType = 'SCU'
		categories['SUBCOMMANDER'] = true
		--categories['UPGRADE_SCU'] = true
	end
    -- create some extra categoeries used for ordering enhancements in UI  
	if enh.Slot then
		local slot = string.upper(enh.Slot)
		if slot == 'LCH' then
			enh.Slot = 'LEFT'
		elseif slot == 'RCH' then
			enh.Slot = 'RIGHT'
		elseif slot == 'BACK' then
			enh.Slot = 'BACK'
		end
		categories['UPGRADE_'..enh.Slot] = true 
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
		 
	categories[bp.Faction] = true
	categories[name] = true
		
	enh.Categories = categories

    if bp.Mod then
        blueprints.Modified[key] = enh  
    else
        blueprints.Original[key] = enh  
    end
    
	blueprints.All[key] = enh   

end
--- Cache projectile blueprints
local function CacheProjectile(bp)
    if not bp then return end

    local id = string.lower(bp.Source) 
	bp.Info = bp.Source or '' -- or bp.BlueprintId  
	--Show('SAVING','<' .. bp.Info .. '>...')
      
   -- converting categories to hash table for quick lookup 
	if  bp.Categories then
        local categories = {}
		for _, category in bp.Categories do
			categories[category] = true
		end	
        bp.Categories = categories 
	end
        
    if bp.Mod then
        projectiles.Modified[id] = bp  
    else
        projectiles.Original[id] = bp  
    end
    
	projectiles.All[id] = bp  
end
--- Cache unit blueprints and extract their enhancements as new blueprints
local function CacheUnit(bp)
    if not bp then return end
	  
	bp.ID = bp.BlueprintId  
	--bp.Info = bp.Source .. ' (' .. (bp.Interface.HelpText or bp.ID) .. ')'
	bp.Info = bp.Source  
	--Show('SAVING', bp.Info .. '...')
    
	local id = bp.ID --bpID --bp.UnitId 

    bp.Name = GetUnitName(bp)
 	  -- skip processing units with Skipped IDs
	if CategoriesSkipped[id] then
		--LOG(' skipped bp ' .. skipCount .. ' - ' .. bp.Source .. ' ' .. bp.Name)
		blueprints.Skipped[id] = bp  
        return 
	end
	-- converting categories to hash table for quick lookup 
	if  bp.Categories then
		bp.CategoriesInfo = ''
		local categories = {}
		for _, category in bp.Categories do
			if CategoriesSkipped[category] then
				bp.Skipped = true  
			else
				categories[category] = true
			end
		end	
		for _, category in bp.Categories do
			if CategoriesAllowed[category] then
				bp.Skipped = false  
			end
		end	
        -- skip processing units with Skipped category
		if bp.Skipped then 
            --LOG(' skipped bp ' .. skipCount .. ' - ' .. bp.Source .. ' ' .. bp.Name)
		    blueprints.Skipped[id] = bp  
            return 
		end
		bp.Categories = categories 
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

    -- extract and cache enhancements so they can be restricted individually 
    for name, enh in bp.Enhancements or {} do
        -- skip slots or 'removable' enhancements
        if name ~= 'Slots' and not string.find(name, 'Remove') then 
            -- some enhancements are shared between factions, e.g. Teleporter
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

--- Checks if game mods have changed between consecutive calls to this function	
--- Thus returns whether or not blueprints need to be reloaded
function DidModsChanged()
	
	mods.All = import('/lua/mods.lua').GetGameMods()
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
		Show('STATUS', 'UnitManager mods changed from ' .. mods.CachedCount .. ' to ' .. mods.ActiveCount)
		mods.Cached = table.deepcopy(mods.Active)
    else
		Show('STATUS', 'UnitManager mods cached = ' .. mods.CachedCount)
	end

    mods.Active = nil
	
	return mods.Changed
end

--- Loads all unit blueprints from the game and given active mods  
function GetBlueprints(activeMods, skipGameFiles)

    TimerStart()
    
	local state = 'blueprints...'
	Show('STATUS', state)
     
    -- load original game files only once 
    local loadedGameFiles = table.getsize(blueprints.Original) > 0 
    if loadedGameFiles then
         skipGameFiles = true
    end

    if DidModsChanged() or not skipGameFiles then
        blueprints.All = table.deepcopy(blueprints.Original)
        blueprints.Modified = {}
        blueprints.Skipped = {}
	    
        projectiles.All = table.deepcopy(projectiles.Original)
        projectiles.Modified = {}
        projectiles.Skipped = {}
	    
        doscript '/lua/system/Blueprints.lua'
        -- loading projectiles first so that they can be used by units
        bps = LoadBlueprints('*_proj.bp', activeMods, skipGameFiles, true, true) 
        for _, bp in bps.Projectile do
            CacheProjectile(bp) 
	    end
        
	    bps = LoadBlueprints('*_unit.bp', activeMods, skipGameFiles, true, true) 
        for _, bp in bps.Unit do
            if not string.find(bp.Source,'proj_') then
                CacheUnit(bp) 
            end 
	    end

        state = state .. ' loaded '
    else
		state = state .. ' cached '
    end
    info = state.. table.getsize(projectiles.All) .. ' total ('
    info = info .. table.getsize(projectiles.Original) .. ' original, '
    info = info .. table.getsize(projectiles.Modified) .. ' modified), and '
    info = info .. table.getsize(projectiles.Skipped) .. ' skipped projectiles'
    Show('STATUS', info)
   
    info = state.. table.getsize(blueprints.All) .. ' total ('
    info = info .. table.getsize(blueprints.Original) .. ' original, '
    info = info .. table.getsize(blueprints.Modified) .. ' modified), and '
    info = info .. table.getsize(blueprints.Skipped) .. ' skipped units'
   
    info = info .. ' in ' .. TimerStop() .. ' (game files: ' .. tostring(skipGameFiles) ..')'
     
	Show('STATUS', info)
    

	return blueprints 
end
 

