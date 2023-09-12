-- this module provides static functions for working with blueprints of units an props
-- at some point most of these functions could be moved to utility module
function IsMotionLand(unitID)
    local bp = __blueprints[unitID]
    local motion = bp.Physics.MotionType
    return (motion == 'RULEUMT_Amphibious' or motion == 'RULEUMT_Land') and bp.ScriptClass ~= 'ResearchItem'
end

function IsMotionHover(unitID)
    local motion = __blueprints[unitID].Physics.MotionType
    return motion == 'RULEUMT_AmphibiousFloating' or motion == 'RULEUMT_Hover'
end

function IsMotionWater(unitID)
    local motion = __blueprints[unitID].Physics.MotionType
    return motion == 'RULEUMT_Water' or motion == 'RULEUMT_SurfacingSub'
end

function IsMotionAir(unitID)
    return __blueprints[unitID].Physics.MotionType == 'RULEUMT_Air'
end

function IsMotionNone(unitID)
    return __blueprints[unitID].Physics.MotionType == 'RULEUMT_None'
end

function IsMotionNone(unitID)
    return __blueprints[unitID].Physics.MotionType == 'RULEUMT_None'
end

function HasCategory(id, cat)
    local bp = __blueprints[id]
    if bp.CategoriesHash then
        return bp.CategoriesHash[cat]
    elseif bp.Categories then
        return table.find(bp.Categories, cat)
    end
end

function IsAir(unitID) return HasCategory(unitID, 'AIR') end
function IsLand(unitID) return HasCategory(unitID, 'LAND') end
function IsNaval(unitID) return HasCategory(unitID, 'NAVAL') end
function IsStructure(unitID) return HasCategory(unitID, 'STRUCTURE') end
function IsAmphibious(unitID) return HasCategory(unitID, 'AMPHIBIOUS') or HasCategory(unitID, 'HOVER') end

function IsIntel(unitID) return HasCategory(unitID, 'SORTINTEL') end
function IsEconomy(unitID) return HasCategory(unitID, 'SORTECONOMY') end
function IsDefense(unitID) return HasCategory(unitID, 'SORTDEFENSE') end
function IsStrategic(unitID) return HasCategory(unitID, 'SORTSTRATEGIC') end
function IsConstruction(unitID) return HasCategory(unitID, 'SORTCONSTRUCTION') end

function IsTech1(unitID) return HasCategory(unitID, 'TECH1') end
function IsTech2(unitID) return HasCategory(unitID, 'TECH2') end
function IsTech3(unitID) return HasCategory(unitID, 'TECH3') end
function IsTech4(unitID) return HasCategory(unitID, 'EXPERIMENTAL') end
function IsTech0(unitID) return not IsTech1(unitID) and not IsTech2(unitID) and not IsTech3(unitID) and not IsTech4(unitID) end

function IsSpawnable(unitID) return not HasCategory(unitID, 'UNSPAWNABLE') end
function IsCivilian(unitID) return HasCategory(unitID, 'CIVILIAN') or HasCategory(unitID, 'OPERATION') end
function IsDummy(unitID) return HasCategory(unitID, 'DUMMYUNIT') or HasCategory(unitID, 'UNSPAWNABLE') end

function IsEngineerTech3(unitID) return HasCategory(unitID, 'TECH3') and HasCategory(unitID, 'ENGINEER') and not HasCategory(unitID, 'SUBCOMMANDER') end
function IsEngineerTech4(unitID) return HasCategory(unitID, 'TECH3') and HasCategory(unitID, 'SUBCOMMANDER') and HasCategory(unitID, 'USEBUILDPRESETS') end
function IsUnitTesting(unitID) return unitID == 'xab1401' or HasCategory(unitID, 'COMMAND') or IsEngineerTech3(unitID) or IsEngineerTech4(unitID) end
 
function IsUnitPlayable(unitID)
    local bp = __blueprints[unitID]
    return bp.CategoriesHash.SELECTABLE
       and not bp.CategoriesHash.CIVILIAN
       and not bp.CategoriesHash.OPERATION
       and not bp.CategoriesHash.INSIGNIFICANTUNIT
       and not bp.CategoriesHash.UNTARGETABLE
end

function GetUnitDescription(id)
    local bp = __blueprints[id]
    local info = '    ' -- defaulting to no tech level for civilans
    if IsUnitPlayable(id) then
        if bp.CategoriesHash.TECH1 then info = 'T1'
        elseif bp.CategoriesHash.TECH2 then info = 'T2'
        elseif bp.CategoriesHash.TECH3 then info = 'T3'
        elseif bp.CategoriesHash.EXPERIMENTAL then info = 'T4' end
    end

    if bp.Description and bp.Description ~= '' then
        info = info .. ' ' .. LOC(bp.Description)
    else
        info = info .. ' [NO bp.Description]'
    end

    if bp.CategoriesHash.SUPPORTFACTORY then
        info = info .. ' (Support)'
    elseif bp.General.UnitName and 
        (bp.CategoriesHash.EXPERIMENTAL or not bp.CategoriesHash.FACTORY) and 
        (bp.CategoriesHash.EXPERIMENTAL or not bp.CategoriesHash.ECONOMIC)  then
        local name = LOC(bp.General.UnitName)
        info = info .. (name == '' and '' or (' (' .. name .. ')'))
    end
    -- removing faction name because we aready have faction icon in the list
    info = info:gsub("UEF ", "")
    info = info:gsub("Aeon ", "")
    info = info:gsub("Cybran ", "")
    info = info:gsub("Seraphim ", "")
    info = info:gsub("Experimental ", "")
    return info
end

function GetUnitIdentifier(id, abbrivate)
    if abbrivate and id:len() > 14 then
        return string.upper(id:sub(1, 3) .. ' ' .. id:sub(4, 14)) .. '…'
    else
        return string.upper(id:sub(1, 3) .. ' ' .. id:sub(4))
    end
end

local UIUtil = import('/lua/ui/uiutil.lua')

local FactionData = {
    { color = 'ff00c1ff', name = 'UEF', icon = UIUtil.UIFile(UIUtil.GetFactionIcon(0)) },
    { color = 'ff89d300', name = 'AEON', icon = UIUtil.UIFile(UIUtil.GetFactionIcon(1)) },
    { color = 'ffff0000', name = 'CYBRAN', icon = UIUtil.UIFile(UIUtil.GetFactionIcon(2)) },
    { color = 'FFFFBF00', name = 'SERAPHIM', icon = UIUtil.UIFile(UIUtil.GetFactionIcon(3)) },
}

function GetUnitFactionInfo(id)
    local bp = __blueprints[id]
    if bp and bp.CategoriesHash and IsUnitPlayable(id) then
        for k, faction in FactionData do
            if bp.CategoriesHash[faction.name] then return faction end
        end
    end
    return { color = false, icon = false }
end

function GetLayerGroup(id)
    local bp = __blueprints[id]
    if bp.Physics then
        if bp.Physics.MotionType == 'RULEUMT_None' then
            local cap = bp.Physics.BuildOnLayerCaps
            local caps = {
                Land   = 'land',
                Water  = 'sea',
                Sub    = 'sea',
                Seabed = 'sea',
                Air    = 'air',
            }
            if caps[cap] then
                return caps[cap]
            elseif tonumber(cap) then
                cap = math.mod(tostring(cap), 16) --You're not an aircraft, get over yourself.

                -- An odd number has some combination of land with sea/sub/water -so amph
                -- An even number has some combination of sea/sub/water, so sea
                -- 1 isn't possible, that would be "Land"
                -- An aside: To whichever engine programmer had it use words for powers of 2, WHY?
                if math.mod(cap, 2) == 1 and cap > 1 then
                    return 'amph'
                elseif cap >= 2 then
                    return 'sea'
                end
            end
        else
            local RULEUMT = {
                RULEUMT_Air                = 'air',
                RULEUMT_Amphibious         = 'amph',
                RULEUMT_AmphibiousFloating = 'amph',
                RULEUMT_Biped              = 'land',
                RULEUMT_Land               = 'land',
                RULEUMT_Hover              = 'amph',
                RULEUMT_Water              = 'sea',
                RULEUMT_SurfacingSub       = 'sea',
            }
            return RULEUMT[bp.Physics.MotionType] or 'land'--the "or" should never matter, but just in case.
        end
    end
    _ALERT("Can't identify layers for unit ", id, bp.Physics and bp.Physics.BuildOnLayerCaps, type(bp.Physics.BuildOnLayerCaps)) --We should never get here
    return 'land'
end

function GetPropType(id)
    local bp = __blueprints[id]
    if bp.Interface then
        local name = bp.Interface.HelpText
        if string.find(name, 'Rock') then
            return 'Rock'
        elseif string.find(name, 'Tree') then
            return 'Tree'
        elseif string.find(name, 'Building') or string.find(name, 'Warehouse') then
            return 'Building'
        end
    end

    if bp.ScriptClass == 'TreeGroup' or bp.ScriptClass == 'Tree' then
        return 'Tree'
    elseif bp.ScriptClass == 'Wreckage' then
        return 'Wreckage'
    else
        return 'Other'
    end
end

function GetPropDescription(id)
    local bp = __blueprints[id]
    local descr = '' .. GetPropType(id) .. ' Type - '
    if bp.Interface and bp.Interface.HelpText then
        descr = descr .. bp.Interface.HelpText
    else 
        descr = descr .. "[No bp.Interface.HelpText]"
    end
    return descr
end

function GetPropIdentifier(id)
    local ret = id:match('([^/]*)_prop%.bp') or id:sub(-24, -9) or id
    if ret:len() > 20 then
        return ret:sub(1, 20) .. '…'
    else
        return ret
    end
end

-- gets blueprints for untis, props, or templates
function GetBlueprintsFor(mode)
    if mode == 'units' then
        local units = EntityCategoryGetUnitList(categories.ALLUNITS)
        -- sorting units by wether they are playable or not
        -- this way most often used units are listed first
        table.sort(units, function(id1, id2)
            local playable1 = IsUnitPlayable(id1)
            local playable2 = IsUnitPlayable(id2)
            if playable1 and not playable2 then
                return true
            elseif not playable1 and playable2 then
                return false
            else
                return GetUnitDescription(id1) > GetUnitDescription(id2)
            end
        end)

        return units
    elseif mode == 'props' then
        local props = {}
        for id, bp in __blueprints do
            if string.find(id, 'prop.bp') then
                table.insert(props, id)
            end
        end

        table.sort(props, function(id1, id2)
            return GetPropDescription(id1) > GetPropDescription(id2)
        end)

        return props
    elseif mode == 'templates' then
        local temp = import('/lua/user/prefs.lua').GetFromCurrentProfile('build_templates')
        for i, template in temp do
            template.templateID = i -- Implicit most places, but ocasionally needed, such as by CreateTemplateOptionsMenu
        end
        return temp
    end
end