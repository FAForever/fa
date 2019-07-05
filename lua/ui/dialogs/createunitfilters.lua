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
                title = 'Aeon',
                key = 'aeon',
                sortFunc = function(unitID)
                    if string.sub(unitID, 2, 2) == 'a' then
                        return true
                    end
                    return false
                end,
            },
            {
                title = 'UEF',
                key = 'uef',
                sortFunc = function(unitID)
                    if string.sub(unitID, 2, 2) == 'e' then
                        return true
                    end
                    return false
                end,
            },
            {
                title = 'Cybran',
                key = 'cybran',
                sortFunc = function(unitID)
                    if string.sub(unitID, 2, 2) == 'r' then
                        return true
                    end
                    return false
                end,
            },
            {
                title = 'Seraphim',
                key = 'seraphim',
                sortFunc = function(unitID)
                    if string.sub(unitID, 2, 2) == 's' then
                        return true
                    end
                    return false
                end,
            },
            {
                title = 'Operation',
                key = 'ops',
                sortFunc = function(unitID)
                    if string.sub(unitID, 1, 1) == 'o' then
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
                title = 'SC1',
                key = 'sc1',
                sortFunc = function(unitID)
                    if string.sub(unitID, 1, 1) == 'u' then
                        return true
                    end
                    return false
                end,
            },
            {
                title = 'Download',
                key = 'dl',
                sortFunc = function(unitID)
                    if string.sub(unitID, 1, 1) == 'd' then
                        return true
                    end
                    return false
                end,
            },
            {
                title = 'XPack 1',
                key = 'scx1',
                sortFunc = function(unitID)
                    if string.sub(unitID, 1, 1) == 'x' then
                        return true
                    end
                    return false
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
                    if string.sub(unitID, 3, 3) == 'l' then
                        return true
                    end
                    return false
                end,
            },
            {
                title = 'Air',
                key = 'air',
                sortFunc = function(unitID)
                    if string.sub(unitID, 3, 3) == 'a' then
                        return true
                    end
                    return false
                end,
            },
            {
                title = 'Naval',
                key = 'naval',
                sortFunc = function(unitID)
                    if string.sub(unitID, 3, 3) == 's' then
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
            {
                title = 'Civilian',
                key = 'civ',
                sortFunc = function(unitID)
                    if string.sub(unitID, 3, 3) == 'c' then
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
                title = 'T1',
                key = 't1',
                sortFunc = function(unitID)
                    return __blueprints[unitID].CategoriesHash.TECH1
                end,
            },
            {
                title = 'T2',
                key = 't2',
                sortFunc = function(unitID)
                    return __blueprints[unitID].CategoriesHash.TECH2
                end,
            },
            {
                title = 'T3',
                key = 't3',
                sortFunc = function(unitID)
                    return __blueprints[unitID].CategoriesHash.TECH3
                end,
            },
            {
                title = 'Exp.',
                key = 't4',
                sortFunc = function(unitID)
                    return __blueprints[unitID].CategoriesHash.EXPERIMENTAL
                end,
            },
        },
    },
}
