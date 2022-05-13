
-- scope as upvalue for performance
local sort = table.sort
local insert = table.insert
local concat = table.concat
local getn = table.getn
local len = string.len
local getmetatable = getmetatable 
local format = string.format
local type = type

-- easy lookup for a divider
local divider = "--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---  --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- \n"

-- keys that we always skip by definition
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
        return format("Printing information of state with identifier: %s\n", tostring(t.__StateIdentifier))
    elseif IsUnit(t) then 
        return format("Printing information of unit of type: %s, and with entity id: %s\n", tostring(t.Blueprint.BlueprintId), tostring(t.EntityId))
    elseif IsProp(t) then 
        return format("Printing information of prop of type: %s, and with entity id: %s\n", tostring(t.Blueprint.BlueprintId), tostring(t.EntityId))
    elseif IsProjectile(t) then 
        return format("Printing information of projectile of type: %s, and with entity id: %s\n", tostring(t.Blueprint.BlueprintId), tostring(t.EntityId))
    elseif IsBrain(t) then 
        return format("Printing information of brain of army: %s\n", tostring(t:GetArmyIndex()))
    elseif IsWeapon(t) then 
        return format("Printing information of weapon of type: %s and with label: %s, of owner with entity id: %s\n", tostring(t.Blueprint.BlueprintId), tostring(t.Blueprint.Label), tostring(t.unit.EntityId))
    elseif IsTrashbag(t) then 
        return format("Printing information of a Trashbag \n")
    elseif IsLazyVar(t) then 
        return format("Printing information of a Lazyvar \n")
    end

    return false

end

local function _FormatTable(t)

    if IsVector(t) then 
        return "(Vector { " .. t.x .. ", " .. t.y .. ", " .. t.z .. "})"
    end

    if IsState(t) then 
        return format("(State)")
    elseif IsUnit(t) then 
        return format("(Unit of type: %s, with entity id: %s)",  tostring(t.Blueprint.BlueprintId), tostring(t.EntityId))
    elseif IsProp(t) then 
        return format("(Prop of type: %s, with entity id: %s)", tostring(t.Blueprint.BlueprintId), tostring(t.EntityId))
    elseif IsProjectile(t) then 
        return format("(Projectile of type: %s, with entity id: %s)", tostring(t.Blueprint.BlueprintId), tostring(t.EntityId))
    elseif IsBrain(t) then 
        return format("(Brain of army: %s)", tostring(t:GetArmyIndex()))
    elseif IsWeapon(t) then 
        return format("(Weapon)")
    elseif IsTrashbag(t) then 
        return format("(Trashbag)")
    elseif IsLazyVar(t) then 
        return format("(Lazyvar)")
    end

    return "(skipped)"

end

local function __repro(t, offset, seen)

    -- find all interesting keys

    local otherRefs = { }
    local ref = { }
    for k, v in t do 

        -- basic definition of key / value
        local s = format("%s%s: %s", offset, tostring(k), tostring(v))
        
        local tv = type(v)
        if tv == "table" then 

            -- prevent recursion
            if not seen[v] then 
                seen[v] = true 

                -- simple table
                if getmetatable(v) == getmetatable({ }) and not skip[k] then 
                    s = s .. "\n"
                    insert(ref, s)
                    local other = __repro(v, offset .. "   ", seen)
                    otherRefs[s] = other
                -- complicated table
                else 
                    insert(ref, s)
                    otherRefs[s] = { format( " %s \n", _FormatTable (v)) }
                end
            end
        else 
            s = s .. "\n"
            insert(ref, s)
        end
    end

    -- sort it to make it all easier to read

    table.sort(ref)

    -- finalize it into one large table

    local final = { }
    for k, v in ref do 
        insert(final, v)
        if otherRefs[v] then 
            for l, vo in otherRefs[v] do 
                insert(final, vo)
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

    local final = { "\n" }
    
    if header then 
        insert(final, header)
    end

    insert(final, "Table information: \n")

    for k, v in content do 
        insert(final, v)
    end

    -- concat into one large string

    return concat(final)
end

local function _reproExt(t, offset)

    local tableContent = __repro(t, offset, { t })
    local metaContent = __repro(getmetatable(t), offset, { getmetatable(t) })
    local header = _FormatHeader(t)
    
    -- add some additional headers

    local final = { "\n" }
    insert(final, divider)
    
    if header then 
        insert(final, header)
        insert(final, divider)
    end
    
    insert(final, "Table information: \n")

    for k, v in tableContent do 
        insert(final, v)
    end

    insert(final, divider)
    insert(final, "Metatable information: \n")

    if getn(metaContent) > 0 then
        for k, v in metaContent do 
            insert(final, v)
        end
    else 
        insert(final, "   (empty meta table) \n")
    end

    insert(final, divider)
    insert(final, " The metatable is shared across all units with the same type. You can inspect the blueprint of a unit by selecting it and using \n")
    insert(final, " shift + f6 to open the entity window. Requires cheats to be enabled. You can find your own hotkey by searching for 'entity' \n")
    insert(final, " in the hotkeys menu. \n")
    insert(final, divider)

    -- concat into one large string

    return concat(final)
end

--- Recursively stringifies a value, kept for backwards compatibility
-- @param t value to print
function repr(t)
    return repro(t)
end

--- Recursively stringifies a value
-- @param t value to print
-- @param extensive include printer of metatable, if applicable
function repro(t, extensive)

    if type(t) == 'table' then 
        if extensive then 
            return _reproExt(t, " - ")
        else
            return _repro(t, " - ")
        end
    else 
        return tostring(t)
    end
end

--- Recursively stringifies and logs a value
-- @param t value to print
-- @param extensive include printer of metatable, if applicable
function reprol(t, extensive)
    LOG(repro(t, extensive))
end