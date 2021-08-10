Filters = {
    {
        title = 'Search',
        key = 'custominput',
        sortFunc = function(unitID, text)
            local foundUnit = true
            local txti = 1
            for i = 1, string.len(unitID) do
                if string.sub(text, txti, txti) == '' then
                    break
                end
                if string.sub(unitID, i, i) == string.sub(text, txti, txti) then
                    txti = txti + 1
                elseif string.sub(text, txti, txti) == '*' then
                    txti = txti + 1
                else
                    foundUnit = false
                    break
                end
            end
            local foundDesc = true
            local txti = 1
            local desc = string.lower(LOC(__blueprints[unitID].Description))
            local textDesc = string.lower(text)
            for i = 1, string.len(desc) do
                if string.sub(textDesc, txti, txti) == '' then
                    break
                end
                if string.sub(desc, i, i) == string.sub(textDesc, txti, txti) then
                    txti = txti + 1
                elseif string.sub(textDesc, txti, txti) == '*' then
                    txti = txti + 1
                else
                    foundDesc = false
                    break
                end
            end
            return foundUnit or foundDesc
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
                    if string.sub(unitID, 5, 5) == '1' then
                        return true
                    end
                    return false
                end,
            },
            {
                title = 'T2',
                key = 't2',
                sortFunc = function(unitID)
                    if string.sub(unitID, 5, 5) == '2' then
                        return true
                    end
                    return false
                end,
            },
            {
                title = 'T3',
                key = 't3',
                sortFunc = function(unitID)
                    if string.sub(unitID, 5, 5) == '3' then
                        return true
                    end
                    return false
                end,
            },
            {
                title = 'Exp.',
                key = 't4',
                sortFunc = function(unitID)
                    if string.sub(unitID, 5, 5) == '4' then
                        return true
                    end
                    return false
                end,
            },
        },
    },
}