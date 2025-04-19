--Lazyvar uses {&h &a} table creation, so the tests' lua version  isn't compatible
local modules = {
    ['/lua/lazyvar.lua'] = {
        LazyVarMetaTable = {}
    }
}

import = function(file)
    return modules[file] or require('.'..file)
end

-- Vector2 is needed in utils but not provided outside the game, so it has to be created here
local Vector2Meta = {
    __index = function(t, k)
        if k == 'x' then
            return t[1]
        elseif k == 'y' then
            return t[2]
        elseif k == 'z' then
            return t[3]
        else
            error("bad argument #2 to `?' ('x', 'y', or 'z' expected)", 1)
        end
    end,

    __newindex = function(t, k, v)
        if k == 'x' then
            t[1] = v
        elseif k == 'y' then
            t[2] = v
        elseif k == 'z' then
            t[3] = v
        else
            error("bad argument #2 to `?' ('x', 'y', or 'z' expected)", 1)
        end
    end,
}

Vector2 = function(...)
    if arg.n ~= 2 then
        error("expected 2 args, but got " .. arg.n)
    end
    if not type(arg[1]) == "number" then
        error("number expected but got " .. type(arg[1]))
    end
    if not type(arg[2]) == "number" then
        error("number expected but got " .. type(arg[2]))
    end

    local newVector2 = {arg[1], arg[2]}
    setmetatable(newVector2, Vector2Meta)
    return newVector2
end
