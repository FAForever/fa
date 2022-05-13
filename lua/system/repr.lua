local sort = table.sort
local insert = table.insert
local concat = table.concat
local getn = table.getn
local len = string.len
local getmetatable = getmetatable 

local skip = {
    Blueprint = true , Cache = true, __index = true
}

local function IsState(t)
    return (t.__State and true) or false
end

local function IsVector(t)
    return (t.x and t.y and t.z and true) or false 
end

local function IsUnit(t) 
    return (t.AddCommandCap and true) or false
end

local function IsProp(t) 
    return (t.AddPropCallback and true) or false
end

local function IsProjectile(t) 
    return (t.ChangeDetonateBelowHeight and true) or false
end

local function IsBrain(t)
    return (t.AssignThreatAtPosition and true) or false
end

local function IsWeapon(t)
    return (t.WeaponHasTarget and true) or false
end

local function IsTrashbag(t)
    return (t.Add and t.Destroy and t.Empty and true) or false 
end

local function IsLazyVar(t)
    return (t.Set and t.SetFunction and t.SetValue and true) or false 
end

local function _FormatHeader(t)

    if IsVector(t) then 
        return false 
    end

    if IsState(t) then 
        return "Printing information of state with identifier: " .. tostring(t.__StateIdentifier) .. "\n"
    elseif IsUnit(t) then 
        return "Printing information of unit of type: " .. tostring(t.Blueprint.BlueprintId) .. ", and with entity id: " .. tostring(t.EntityId) .. "\n"
    elseif IsProp(t) then 
        return "Printing information of prop of type: " .. tostring(t.Blueprint.BlueprintId) .. ", and with entity id: " .. tostring(t.EntityId) .. "\n"
    elseif IsProjectile(t) then 
        return "Printing information of projectile of type: " .. tostring(t.Blueprint.BlueprintId) .. ", and with entity id: " .. tostring(t.EntityId) .. "\n"
    elseif IsBrain(t) then 
        return "Printing information of brain of army: " .. tostring(t:GetArmyIndex()) .. "\n"
    elseif IsWeapon(t) then 
        return "Printing information of weapon of type: " .. tostring(t.Blueprint.BlueprintId) .. " and with label: " .. tostring(t.Blueprint.Label) .. ", of owner with entity id: " .. tostring(t.unit.EntityId) .. "\n"
    elseif IsTrashbag(t) then 
        return "Printing information of a Trashbag \n"
    elseif IsLazyVar(t) then 
        return "Printing information of a Lazyvar \n"
    end

    return false

end

local function _FormatTable(t)

    if IsVector(t) then 
        return "(Vector { " .. t.x .. ", " .. t.y .. ", " .. t.z .. "})"
    end

    if IsState(t) then 
        return "(State)"
    elseif IsUnit(t) then 
        return "(Unit of type: " .. tostring(t.Blueprint.BlueprintId) .. ", with entity id: " .. tostring(t.EntityId) .. ")"
    elseif IsProp(t) then 
        return "(Prop of type: " .. tostring(t.Blueprint.BlueprintId) .. ", with entity id: " .. tostring(t.EntityId) .. ")"
    elseif IsProjectile(t) then 
        return "(Projectile of type: " .. tostring(t.Blueprint.BlueprintId) .. ", with entity id: " .. tostring(t.EntityId) .. ")"
    elseif IsBrain(t) then 
        return "(Brain of army: " .. tostring(t:GetArmyIndex()) .. ")"
    elseif IsWeapon(t) then 
        return "(Weapon)"
    elseif IsTrashbag(t) then 
        return "(Trashbag)"
    elseif IsLazyVar(t) then 
        return "(Lazyvar)"
    end

    return "(skipped)"

end

local function __repro(t, offset, seen)

    -- allows us to support indenting

    offset = offset .. "   "

    -- find all interesting keys

    local otherRefs = { }
    local ref = { }
    for k, v in t do 

        -- basic definition of key / value
        local s = offset .. tostring(k) .. ": " .. tostring(v)
        
        local tv = type(v)
        if tv == "table" then 

            -- prevent recursion
            if not seen[v] then 
                seen[v] = true 

                -- simple table
                if getmetatable(v) == getmetatable({ }) and not skip[k] then 
                    s = s .. "\n"
                    table.insert(ref, s)
                    local other = __repro(v, offset, seen)
                    otherRefs[s] = other
                -- complicated table
                else 
                    table.insert(ref, s)
                    otherRefs[s] = { " " .. _FormatTable (v) .. " \n" }
                end
            end
        else 
            s = s .. "\n"
            table.insert(ref, s)
        end
    end

    -- sort it to make it all easier to read

    table.sort(ref)

    -- finalize it into one large table

    local final = { }
    for k, v in ref do 
        table.insert(final, v)
        if otherRefs[v] then 
            for l, vo in otherRefs[v] do 
                table.insert(final, vo)
            end
        end
    end

    return final
end

local function _repro(t, offset)

    -- retrieve all content

    local content = __repro(t, offset, { t })
    local header = _FormatHeader(t)

    -- add some additional headers

    local final = { }
    table.insert(final, " --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---  --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- \n")
    
    if header then 
        table.insert(final, header)
        table.insert(final, " --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---  --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- \n")
    end

    table.insert(final, "Table information: \n")

    for k, v in content do 
        table.insert(final, v)
    end

    table.insert(final, " --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---  --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- \n")

    -- concat into one large string

    return table.concat(final)
end

local function _reproExt(t, offset)

    local tableContent = __repro(t, offset, { t })
    local metaContent = __repro(getmetatable(t), offset, { getmetatable(t) })
    local header = _FormatHeader(t)
    
    -- add some additional headers

    local final = { }
    table.insert(final, " --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---  --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- \n")
    
    if header then 
        table.insert(final, header)
        table.insert(final, " --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---  --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- \n")
    end
    
    table.insert(final, "Table information: \n")

    for k, v in tableContent do 
        table.insert(final, v)
    end

    table.insert(final, " --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---  --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- \n")
    table.insert(final, "Metatable information: \n")

    if table.getsize(metaContent) > 0 then
        for k, v in metaContent do 
            table.insert(final, v)
        end
    else 
        table.insert(final, "   (empty meta table) \n")
    end

    table.insert(final, " --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---  --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- \n")
    table.insert(final, " The metatable is shared across all units with the same type. You can inspect the blueprint of a unit by selecting it and using \n")
    table.insert(final, " shift + f6 to open the entity window. Requires cheats to be enabled. You can find your own hotkey by searching for 'entity' \n")
    table.insert(final, " in the hotkeys menu. \n")
    table.insert(final, " --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---  --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- \n")

    -- concat into one large string

    return table.concat(final)
end

function repro(t, extensive)
    if extensive then 
        return _reproExt(t, "")
    else
        return _repro(t, "")
    end
end

function reprol(t, extensive)
    if extensive then 
        LOG(_reproExt(t, ""))
    else
        LOG(_repro(t, ""))
    end
end