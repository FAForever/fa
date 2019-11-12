Filters = {
    {
        title = 'Search',
        key = 'custominput',
        sortFunc = function(unitID, text)
            local bp = __blueprints[unitID]
            local desc = string.lower(LOC(bp.Description or ''))
            local name = string.lower(LOC(bp.General.UnitName or ''))
            text = string.lower(text)
            if string.find(unitID, text) or string.find(desc, text) or string.find(name, text) then
                return true
            end
        end,
    },
    {
        title = 'Faction',
        key = 'faction',
        choices = {
            {
                title = 'UEF',
                key = 'uef',
                sortFunc = function(unitID)
                    return __blueprints[unitID].CategoriesHash.UEF
                end,
            },
            {
                title = 'Aeon',
                key = 'aeon',
                sortFunc = function(unitID)
                    return __blueprints[unitID].CategoriesHash.AEON
                end,
            },
            {
                title = 'Cybran',
                key = 'cybran',
                sortFunc = function(unitID)
                    return __blueprints[unitID].CategoriesHash.CYBRAN
                end,
            },
            {
                title = 'Seraphim',
                key = 'seraphim',
                sortFunc = function(unitID)
                    return __blueprints[unitID].CategoriesHash.SERAPHIM
                end,
            },
            {
                title = 'other faction',
                key = '3rdParty',
                sortFunc = function(unitID)
                    if not __blueprints[unitID].CategoriesHash.UEF
                    and not __blueprints[unitID].CategoriesHash.AEON
                    and not __blueprints[unitID].CategoriesHash.CYBRAN
                    and not __blueprints[unitID].CategoriesHash.SERAPHIM
                    then
                        return true
                    end
                    return false
                end,
            },
        },
    },
    {
        title = 'Product',
        key = 'product',
        choices = {
            {
                title = 'SC',
                key = 'sc1',
                sortFunc = function(unitID)
                    return string.sub(unitID, 1, 1) == 'u'
                end,
            },
            {
                title = 'SC-FA',
                key = 'scx1',
                sortFunc = function(unitID)
                    return string.sub(unitID, 1, 1) == 'x'
                end,
            },
            {
                title = 'Mods',
                key = 'dl',
                sortFunc = function(unitID)
                    return __blueprints[unitID].Mod
                end,
            },
            {
                title = 'Operation',
                key = 'ops',
                sortFunc = function(unitID)
                    return string.sub(unitID, 1, 1) == 'o' or __blueprints[unitID].CategoriesHash.OPERATION
                end,
            },
            {
                title = 'Civilian',
                key = 'civ',
                sortFunc = function(unitID)
                    return string.sub(unitID, 3, 3) == 'c' or __blueprints[unitID].CategoriesHash.CIVILIAN
                end,
            },
        },
    },
    {
        title = 'Type',
        key = 'type',
        choices = {
            {
                title = 'Land',
                key = 'land',
                sortFunc = function(unitID)
                    return __blueprints[unitID].CategoriesHash.LAND
                end,
            },
            {
                title = 'Air',
                key = 'air',
                sortFunc = function(unitID)
                    return __blueprints[unitID].CategoriesHash.AIR
                end,
            },
            {
                title = 'Naval',
                key = 'naval',
                sortFunc = function(unitID)
                    return __blueprints[unitID].CategoriesHash.NAVAL
                end,
            },
            {
                title = 'Amphibious',
                key = 'amph',
                sortFunc = function(unitID)
                    if __blueprints[unitID].CategoriesHash.AMPHIBIOUS
                    or __blueprints[unitID].CategoriesHash.HOVER
                    then
                        return true
                    end
                    return false
                end,
            },
            {
                title = 'Base',
                key = 'base',
                sortFunc = function(unitID)
                    if string.sub(unitID, 3, 3) == 'b' then
                        return true
                    end
                    return false
                end,
            },
        },
    },
    {
        title = 'Tech Level',
        key = 'tech',
        choices = {
            {
                title = 'Tech 1',
                key = 't1',
                sortFunc = function(unitID)
                    return __blueprints[unitID].CategoriesHash.TECH1
                end,
            },
            {
                title = 'Tech 2',
                key = 't2',
                sortFunc = function(unitID)
                    return __blueprints[unitID].CategoriesHash.TECH2
                end,
            },
            {
                title = 'Tech 3',
                key = 't3',
                sortFunc = function(unitID)
                    return __blueprints[unitID].CategoriesHash.TECH3
                end,
            },
            {
                title = 'Experimental',
                key = 't4',
                sortFunc = function(unitID)
                    return __blueprints[unitID].CategoriesHash.EXPERIMENTAL
                end,
            },
            {
                title = 'ACU+',
                key = 'acu',
                sortFunc = function(unitID)
                    -- Show ACU's
                    if __blueprints[unitID].CategoriesHash.COMMAND then
                        return true
                    end
                    -- Show SCU's
                    if string.find(unitID, 'l0301_Engineer') then
                        return true
                    end
                    -- Show Paragon
                    if string.find(unitID, 'xab1401') then
                        return true
                    end
                end,
            },
        },
    },
}
