local msg_mismatchedType = '%s expected, got %s'
local msg_badArgs = 'bad argument%s #%d to "%s" (%s)'

function GetFaType(v)
    return v.__name or type(v)
end

--- Throws an error if the variable is not of the expected type.
---@param v any | fa-class
---@param t type | MohoExportedClassName
function AssertFaType(v, t)
    if GetFaType(v) ~= t then
        error(string.format(msg_mismatchedType, t, GetFaType(v)), 2)
    end
end

--- Throws an error if parameters do not match desired types, with a message
--- specifying which parameters do not match.
---@param a1 any
---@param t1 type | MohoExportedClassName
---@param ... any # repeat of a1, t1
function AssertFaParams(a1, t1, ...)
    assert(math.mod(arg.n, 2) == 0, 'AssertFaParams needs an even number of arguments')
    local i = 1
    local errs
    repeat
        if GetFaType(a1) ~= t1 then
            if not errs then
                errs = {}
            end
            table.insert(errs, i)
        end
        a1 = arg[i]
        t1 = arg[i + 1]
        i = i + 2
    until not a1 or not t1
    if errs then
        local err = errs[1]
        local args = tostring((err + 1) / 2)
        local gets = GetFaType(args[err])
        local expecteds = args[err + 1]
        for _, err in errs do
            args = ', ' .. tostring((err + 1) / 2)
            expecteds = ', ' .. arg[err + 1]
            gets = ', ' .. GetFaType(arg[err])
        end
        error(string.format(
            msg_badArgs
            , table.getsize(errs) >= 2 and 's' or ''
            , args
            , debug.getinfo(2, 'n').name
            , string.format(msg_mismatchedType, expecteds, gets)
        ), 2)
    end
end
