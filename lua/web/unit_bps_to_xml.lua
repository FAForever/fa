all_blueprints = {}
current_filename = nil

--
-- Strip localization crud from a string
--
local function LOC(s)
    if string.sub(s, 1, 4)=='<LOC' then
        local i = string.find(s,">")
        if i then
            s = string.sub(s, i+1)
        end
    end
    return s
end


--
-- Escape problematic XML entities in a string
--
local function ESCAPE(s)
    s = string.gsub(s, '&', '&amp;')
    s = string.gsub(s, '<', '&lt;')
    s = string.gsub(s, '>', '&gt;')
    return s
end


--
-- Define 'UnitBlueprint' func, which will get called with the blueprint data
--
function UnitBlueprint(spec)
    spec._xml_tag = "UnitBlueprint"
    spec._xml_attrs = { id=string.gsub(string.lower(current_filename), "^.*/([^/]+)_[a-z]+%.bp$", "%1") }

    table.insert(all_blueprints,spec)
end

function Sound(t)
    t._xml_tag = 'Sound'
    return t
end

function RPCSound(t)
    t._xml_tag = 'RPCSound'
    return t
end

-- Load in all the blueprints
function dir_recursive(path, result)
    local r = result or {}
    for i,f in io.dir(path.."/*") do
        if f=="." or f==".." then continue end
        local sub = path.."/"..f
        table.insert(r,sub)
        dir_recursive(sub,r)
    end
    return r
end

--
-- Load all the blueprints
--
for i,f in dir_recursive("../../") do
    if string.find(f, "_unit.bp$") then
        current_filename = f
        dofile(f)
    end
end

--
-- Dump them in XML
--
-- stuff = { a,b,c } becomes <stuff><li>a</li><li>b</li><li>c</li></stuff>
--
-- { x=this, y=that } becomes <x>this</x><y>that</y>
--
function xml_tags(defaulttag, name, value)
    local tag = value._xml_tag or defaulttag
    local close = '</' .. tag .. '>'

    local open = '<' .. tag
    if name and name!=tag then
        open = open .. ' name="' .. name .. '"'
    end
    if value._xml_attrs then
        for k,v in value._xml_attrs do
            open = open .. (' ' .. k .. '="' .. v .. '"')
        end
    end
    open = open .. '>'

    return open,close
end


function auto_xml(file,tag,name,value,indent)

    local open,close = xml_tags(tag, name, value)

    if type(value)=='table' then
        local subindent = indent..'  '
        file:write(open,'\n')
        if table.getn(value)>0 then
            -- numerically indexed table
            for i,v in ipairs(value) do
                file:write(subindent)
                auto_xml(file,'li',nil,v,subindent)
            end
        else
            -- key=value table
            for k,v in value do
                if string.sub(k,1,1)!='_' then
                    file:write(subindent)
                    auto_xml(file,k,k,v,subindent)
                end
            end
        end
        file:write(indent,close,'\n')
    else
        if type(value)=='string' then
            value = ESCAPE(LOC(value))
        else
            value = tostring(value)
        end
        file:write(open)
        file:write(value)
        file:write(close,'\n')
    end
end

auto_xml(io.stdout,'UnitBlueprints',nil,all_blueprints,'')
