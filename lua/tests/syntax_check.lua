require '../tests/testutils.lua'
require '../system/class.lua'

function Faction(t)
end

function SpecFootprintGroup(t)
end

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


function syntax_check()
    for i,f in dir_recursive("../..") do
        f = string.lower(f)
        if string.find(f, "%.lua$") then
            local fn,msg = loadfile(f)
            if not fn then
                print(msg)
            end
        end
    end
end


syntax_check()
