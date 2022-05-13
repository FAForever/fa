local sort = table.sort
local insert = table.insert
local concat = table.concat
local getn = table.getn
local len = string.len


local function less(a,b)
    if type(a) < type(b) then return true end
    if type(b) < type(a) then return false end
    if type(a) == 'table' or type(a) == 'function' or type(a) == 'cfunction' then
        return tostring(a) < tostring(b)
    else
        return a<b
    end
end


local function get_names(t,maxdepth,result,prefix)
    for k,v in t do
        if type(k)=='string' and type(v)!='string' and type(v)!='number' and type(v)!='boolean' then
            local name = prefix .. k
            if result[v]==nil or string.len(name) < string.len(result[v]) then
                result[v] = name

                if type(v)=='table' and maxdepth>0 then
                    get_names(v,maxdepth-1,result,name .. '.')
                end
            end
        end
    end
    return result
end


local global_names = get_names(_G,2,{},'')


--
-- Convert obj to an expanded string form. Returns two results. The first has obj expanded on a single line; the
-- second may have obj in multiline form.
--
local function _repr(obj, indent, width, mindepth, objectstack)

    if mindepth<=0 and global_names[obj] then
        return global_names[obj], global_names[obj]

    elseif type(obj) == 'string' then
        local r = string.format("%q",obj)
        return r,r

    elseif type(obj) ~= 'table' then
        local r = tostring(obj)
        return r,r
    end

    local s = objectstack
    local level = 1
    while s do
        if obj==s[1] then
            -- Recursive backreference - return a special marker
            local r = '*'..level
            return r,r
        end
        s = s[2]
        level = level+1
    end
    objectstack = {obj,objectstack}

    if width <= 0 then
        local r = tostring(obj)
        return r,r
    end

    local keys = {}
    local r1
    if getmetatable(obj) == getmetatable {} then
        r1 = { '{ ' .. tostring(obj) .. " " }
    else
        r1 = { '{ ' .. tostring(obj) .. ' <metatable=', tostring(getmetatable(obj)), '>'}
    end
    local r2 = { unpack(r1) }

    local index = 1
    local subindent = indent..'  '
    local sep1 = ' '
    local sep2 = '\n'..subindent

    for k in obj do insert(keys,k) end
    if getn(keys)==0 then
        return '{ }','{ }'
    end
    sort(keys, less)

    for i,k in ipairs(keys) do
        local prefix
        if k==index then
            index = index+1
            prefix = ''
        elseif type(k)=='string' then
            prefix = k .. '='
        else
            prefix = '[' .. (_repr(k, subindent, width, mindepth-1, objectstack)) .. ']='
        end

        local v1,v2 = _repr(obj[k], subindent, width, mindepth-1, objectstack)

        -- format the single-line result
        insert(r1, sep1)
        insert(r1, prefix)
        insert(r1, v1)
        sep1 = ', '

        -- format the multi-line result
        insert(r2, sep2)
        insert(r2, prefix)
        if len(subindent) + len(prefix) + len(v1) < width then
            insert(r2, v1)
        else
            insert(r2, v2)
        end
        sep2 = ',\n'..subindent
    end

    insert(r1,' }')
    insert(r2,'\n'..indent..'}')

    r1 = concat(r1)
    r2 = concat(r2)

    return r1, r2
end


--
-- Convert obj to an expanded string form, which can be checked for equality. The optional second
-- arg gives a maximum width; if the repr is wider than this, it will be split into a multi-line
-- form if possible.
--
function repr(obj, maxwidth, mindepth)
    maxwidth = maxwidth or 160
    local r1,r2 = _repr(obj, '', maxwidth, mindepth or 1, nil)
    if len(r1) <= maxwidth then
        return r1
    else
        return r2
    end
end

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