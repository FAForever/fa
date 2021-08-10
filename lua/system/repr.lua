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
        r1 = { '{' }
    else
        r1 = { '{ <metatable=', tostring(getmetatable(obj)), '>'}
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
    maxwidth = maxwidth or 80
    local r1,r2 = _repr(obj, '', maxwidth, mindepth or 1, nil)
    if len(r1) <= maxwidth then
        return r1
    else
        return r2
    end
end
