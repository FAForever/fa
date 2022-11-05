local parsedPriorities
local ParseEntityCategoryProperly = import("/lua/sim/categoryutils.lua").ParseEntityCategoryProperly

--- We can't serialize categories, therefore the UI sends us a string of categories. We manually
--- parse the string here into categories. 
---@param inputString string
---@return EntityCategory[] | nil
---@return EntityCategory[] | nil
function HandleInputString(inputString)

    local complete, limited = nil, nil

    local ok, msg = pcall(
        function()
            local categories = StringSplit(inputString, ',')

            for k, category in categories do 
                local clean = category
                clean = string.gsub(clean, '{', '')
                clean = string.gsub(clean, '}', '')
                categories[k] = clean
            end

            complete = { }
            for k, category in categories do
                local parsed = ParseEntityCategoryProperly(category)
                if parsed then 
                    table.insert(complete, parsed)
                end
            end

            -- excludes the use of the COMMAND category, to prevent sniping
            limited = { }
            for k, category in categories do
                if not string.find(category, 'categories.COMMAND') then
                    local parsed = ParseEntityCategoryProperly(category)
                    if parsed then
                        table.insert(limited, parsed - categories.COMMAND)
                    end
                end
            end
        end
    )

    if not ok then
        WARN(msg)
        WARN(inputString)
    end

    return complete, limited
end

function SetWeaponPriorities(data)
    local selectedUnits = data.SelectedUnits
    local prioritiesTable
    local prioritiesTableLimited
    local editedPriorities = {}
    local editedPrioritiesLimited = {}
    local default
    local name

    -- parse and save all default priorities (we do it only once)
    if not parsedPriorities then
        parsedPriorities = parseDefaultPriorities()
    end

    if not selectedUnits[1] then return end

    if data.prioritiesTable then
        prioritiesTable, prioritiesTableLimited = HandleInputString(data.prioritiesTable)

        --this is needed to prevent crashes when there is a mistake in the middle of input string
        --and priTable has such structure: {[1] = userdata: EntityCategory, [2] = empty!, [3] = userdata: EntityCategory}
        for key,cat in prioritiesTable or {} do
            table.insert(editedPriorities, cat)
        end
        for key,cat in prioritiesTableLimited or {} do
            table.insert(editedPrioritiesLimited, cat)
        end
    end

    if not editedPriorities[1] then
        default = true
    end

    --work out what message to send to the player for changing their priority list
    if default then
        name = "Default"
    elseif type(data.name) == "string" then
        name = data.name
    end

    if GetEntityById(selectedUnits[1]).Army == GetFocusArmy() and not data.hideMsg then
        --send the message to the owner of the army
        print('Target Priority:', name)
    end

    local units = {}

    -- prevent tampering
    for _, unitId in selectedUnits do
        local unit = GetEntityById(unitId)

        if unit and OkayToMessWithArmy(unit.Army) then
            table.insert(units, unit)
        end
    end

    local preparedPrioTables = {}

    for _, unit in units do
        local bp = unit:GetBlueprint()
        local blueprintId = bp.BlueprintId
        local weaponCount = unit:GetWeaponCount()
        local finalPriorities = editedPrioritiesLimited

        if bp.CategoriesHash.SNIPEMODE then
            finalPriorities = editedPriorities
        end

        --checks if unit is already in requested mode
        if weaponCount > 0 and unit.Sync.WepPriority ~= name then
            unit.Sync.WepPriority = name or "?????"


            if default then
                for i = 1, weaponCount do
                    local weapon = unit:GetWeapon(i)
                    weapon:SetTargetingPriorities(parsedPriorities[blueprintId][i])
                    weapon:ResetTarget()
                end
            elseif data.exclusive then
                for i = 1, weaponCount do
                    local weapon = unit:GetWeapon(i)
                    weapon:SetTargetingPriorities(finalPriorities)
                    weapon:ResetTarget()
                end
            elseif preparedPrioTables[blueprintId] then
                for i = 1, weaponCount do
                    local weapon = unit:GetWeapon(i)
                    weapon:SetTargetingPriorities(preparedPrioTables[blueprintId][i])
                    weapon:ResetTarget()
                end
            else
                preparedPrioTables[blueprintId] = {}

                for i = 1, weaponCount do
                    local weapon = unit:GetWeapon(i)
                    local defaultPriorities = parsedPriorities[blueprintId][i]
                    local mergedPriorities = table.copy(finalPriorities) or {}

                    for k,v in defaultPriorities do
                        table.insert(mergedPriorities, v)
                    end

                    preparedPrioTables[blueprintId][i] = mergedPriorities

                    weapon:SetTargetingPriorities(mergedPriorities)
                    weapon:ResetTarget()
                end
            end
        end
    end
end

-- Parse and caching all TargetPriorities tables for every unit
function parseDefaultPriorities()
    local idlist = EntityCategoryGetUnitList(categories.ALLUNITS)
    local finalPriorities = {}

    local parsedTemp = {}


    for _, id in idlist do

        local weapons = GetUnitBlueprintByName(id).Weapon
        local priorities = {}

        for weaponNum, weapon in weapons or {} do
            if weapon.TargetPriorities then
                priorities[weaponNum] = weapon.TargetPriorities
            else
                priorities[weaponNum] = {}
            end

        end

        for weaponNum, tbl in priorities do
            if not finalPriorities[id] then finalPriorities[id] = {} end
            if not finalPriorities[id][weaponNum] then finalPriorities[id][weaponNum] = {} end


            for line, categories in tbl or {} do
                if parsedTemp[categories] then

                    finalPriorities[id][weaponNum][line] = parsedTemp[categories]

                elseif string.find(categories, '%(') then
                    local parsed = ParseEntityCategoryProperly(categories)

                    finalPriorities[id][weaponNum][line] = parsed
                    parsedTemp[categories] = parsed

                else
                    local parsed = ParseEntityCategory(categories)

                    finalPriorities[id][weaponNum][line] = parsed
                    parsedTemp[categories] = parsed
                end
            end
        end
    end
    return finalPriorities
end

function categoryLimiter(inputStr, filterStr)
    local priorityStrings = {}
    local initIndex = 1
    local modifiedString = ""

    while initIndex do
        local startIndex, endIndex, priority = string.find(inputStr, "([^,{}]+)", initIndex)
        if endIndex then
            initIndex = endIndex + 1
            local categoryStart, categoryEnd = string.find(priority, filterStr)

            -- exclude priority that contains given category if there is no "-" in front of it.
            if not categoryStart or string.sub(priority, categoryStart - 1, categoryStart - 1) == "-"
                                 or string.sub(priority, categoryStart - 2, categoryStart - 2) == "-" then
                table.insert(priorityStrings, priority)
            end
        else
            initIndex = nil
        end
    end

    -- also subtract given category from every priority expression,
    -- so it's impossible to trick this limiter using combination of allowed categories
    for k,cat in priorityStrings do
        modifiedString = modifiedString .. cat .. " - ".. filterStr .. ","
    end
    modifiedString = "{"..modifiedString.."}"

    return loadstring("return "..modifiedString)()
end