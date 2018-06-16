local parsedPriorities
local ParseEntityCategoryProperly = import('/lua/sim/CategoryUtils.lua').ParseEntityCategoryProperly
local categoriesID = {
    [1] = categories.AIR, 
    [2] = categories.ANTIAIR, 
    [3] = categories.ANTIMISSILE, 
    [4] = categories.ANTINAVY,
    [5] = categories.ANTISUB,
    [6] = categories.ARTILLERY, 
    [7] = categories.BATTLESHIP, 
    [8] = categories.BOMBER, 
    [9] = categories.CARRIER, 
    [10] = categories.COMMAND,
    [11] = categories.CONSTRUCTION,
    [12] = categories.COUNTERINTELLIGENCE,
    [13] = categories.CRUISER,
    [14] = categories.DEFENSE,
    [15] = categories.DESTROYER,
    [16] = categories.DIRECTFIRE,
    [17] = categories.ECONOMIC,
    [18] = categories.ENERGYPRODUCTION,
    [19] = categories.ENERGYSTORAGE,
    [20] = categories.ENGINEER,
    [21] = categories.EXPERIMENTAL,
    [22] = categories.FACTORY,
    [23] = categories.FRIGATE,
    [24] = categories.GROUNDATTACK,
    [25] = categories.HOVER,
    [26] = categories.INDIRECTFIRE, 
    [27] = categories.INTELLIGENCE, 
    [28] = categories.LAND, 
    [29] = categories.MASSEXTRACTION,
    [30] = categories.MASSPRODUCTION,
    [31] = categories.MASSSTORAGE,
    [32] = categories.MOBILE,
    [33] = categories.MOBILESONAR,
    [34] = categories.NAVAL,
    [35] = categories.NUKE,
    [36] = categories.NUKESUB,
    [37] = categories.OMNI,
    [38] = categories.RADAR,
    [39] = categories.RECLAIMABLE,
    [40] = categories.SCOUT,
    [41] = categories.SHIELD,
    [42] = categories.SNIPER,
    [43] = categories.SONAR,
    [44] = categories.STRATEGIC,
    [45] = categories.STRUCTURE,
    [46] = categories.SUBCOMMANDER,
    [47] = categories.SUBMERSIBLE,
    [48] = categories.TECH1,
    [49] = categories.TECH2,
    [50] = categories.TECH3,
    [51] = categories.TRANSPORTATION    
}

local customPatterns = {
    [1] = function(cat)
        local parsed = cat[1]
        return parsed    
    end,
    
    [2] = function(cat)
        local parsed = cat[1]*cat[2]
        return parsed    
    end,
    
    [3] = function(cat)
        local parsed = cat[1]*cat[2]*cat[3]
        return parsed    
    end,
    
    [4] = function(cat)
        local parsed = cat[1]*cat[2]*cat[3]*cat[4]
        return parsed    
    end,
    
    [5] = function(cat)
        local parsed = cat[1]*cat[2]*cat[3]*cat[4]*cat[5]
        return parsed    
    end,
}

function SetWeaponPriorities(data)
    local SelecetedUnits = data.SelecetedUnits
    local showMsg
    local lineToInsert
    local default
    
    if not parsedPriorities then
        parsedPriorities = parse()
    end
   
    if not SelecetedUnits then
        return
    elseif GetEntityById(SelecetedUnits[1]):GetArmy() == GetFocusArmy() then
        showMsg = true
    end
        
    if data.key == 0 then
        default = true
    elseif data.key[1] then     
        if table.getn(data.key) > 5 then
            return
        end
    
        local cats = {}
        
        for key, val in data.key do
            if categoriesID[val] then
                table.insert(cats, categoriesID[val])
            else
                if showMsg then
                    print("Wrong ID")
                end
                return
            end    
        end
            
        lineToInsert = customPatterns[table.getn(cats)](cats)
    else
        return
    end
    
    local units = {}
    
    for _, unitId in SelecetedUnits do
        local unit = GetEntityById(unitId)
        
        if unit and OkayToMessWithArmy(unit:GetArmy()) then 
            table.insert(units, unit)
        end
    end
    
    if default then
        name = "Default"
    elseif type(data.name) == "string" then
        if string.len(data.name) > 6 then
            name = string.sub(data.name, 1, 6)
        else
            name = data.name
        end    
    end    
  
    for _, unit in units do
    
        local bplueprintId = unit:GetBlueprint().BlueprintId
        local weaponCount = unit:GetWeaponCount()
        
        if weaponCount > 0 and unit.Sync.WepPriority ~= name then --checks if unit is already in requested mode
        
            unit.Sync.WepPriority = name or "?????" 
            
            for i = 1, weaponCount do
                local weapon = unit:GetWeapon(i)
                local parsedTable = parsedPriorities[bplueprintId][i]
                local priorities = {[1] = lineToInsert}
                
                if parsedTable[1] then
                    if default then
                        weapon:SetTargetingPriorities(parsedTable)
                        weapon:ResetTarget()
                    elseif data.defaults then
                        table.insert(parsedTable, 1, lineToInsert)

                        weapon:SetTargetingPriorities(parsedTable)
                        weapon:ResetTarget()
                        
                        table.remove(parsedTable, 1)
                    else
                        weapon:SetTargetingPriorities(priorities)
                        weapon:ResetTarget()
                    end
                end
            end
        end
    end
    
    if showMsg then
        print('Priority:', name)
    end
end

function parse()
    local idlist = EntityCategoryGetUnitList(categories.ALLUNITS)
    local finalPriorities = {}

    local parsedTemp = {}


    for _, id in idlist do
        
        local weapons = GetUnitBlueprintByName(id).Weapon
        
        if weapons[1] then
            local priorities = {}
            
            for weaponNum, weapon in weapons do
                if weapon.TargetPriorities then
                    priorities[weaponNum] = weapon.TargetPriorities
                else
                    priorities[weaponNum] = {}
                end
                
            end
            
            for weaponNum, tbl in priorities do
                if not finalPriorities[id] then finalPriorities[id] = {} end 
                if not finalPriorities[id][weaponNum] then finalPriorities[id][weaponNum] = {} end
                
                if tbl[1] then
                    local prioTbl = tbl
                    
                    for line, categories in prioTbl do
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
        end
    end
    return finalPriorities
end