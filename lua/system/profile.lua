import 'utils.lua'


diff_fields = {'total', 'here', 'in_c_children', 'in_lua_children', 'yielded', 'ncalls'}


start_profiledata = false


checkpoint = debug.profiledata


function checkpoint_to_table(checkpoint)
    if checkpoint==nil then
        return nil
    end

    local r = {}
    local j = 0
    for i=1,table.getn(checkpoint),7 do
        j = j+1
        r[j] = {
            func = checkpoint[i],
            clocked = checkpoint[i+1],
            total = checkpoint[i+1] - checkpoint[i+5],
            here = checkpoint[i+2],
            in_c_children = checkpoint[i+3],
            in_lua_children = checkpoint[i+4],
            yielded = checkpoint[i+5],
            ncalls = checkpoint[i+6]
        }
    end

    return r
end


function diff_checkpoints(check1, check2)

    local t1 = checkpoint_to_table(check1)
    local t2 = checkpoint_to_table(check2)

    -- t1 can be nil, which means to use the total time up to t2.
    -- (t2 being nil doesn't make sense here.)
    if t1==nil then
        return t2
    end

    local keys1 = {}
    for i,t in t1 do
        keys1[t.func] = t
    end
    for i,t in t2 do
        local old = keys1[t.func]
        if old then
            for j,field in diff_fields do
                t[field] = t[field] - old[field]
            end
        end
    end
    return t2
end


local function strtime(n)
    return string.format("% 12.6f", n)
end


function dumptimes(t)
    LOG(' ')
    LOG(repr(t.func,nil,0), ' (', t.ncalls,' calls):')
    --LOG('    clocked:         ' .. strtime(t.clocked))
    LOG('    total:           ' .. strtime(t.total))
    LOG('    here:            ' .. strtime(t.here))
    LOG('    in c children:   ' .. strtime(t.in_c_children))
    LOG('    in lua children: ' .. strtime(t.in_lua_children))
    --LOG('    yielded:         ' .. strtime(t.yielded))
end


function report(check1, check2, key)
    key = key or 'here'
    check2 = check2 or checkpoint()
    local dt = diff_checkpoints(check1,check2)
    table.sort(dt, sort_by(key))

    sum_key = 0
    sum_here = 0
    for i,t in ipairs(dt) do
        sum_key = sum_key + t[key]
        sum_here = sum_here + t.here
    end

    -- Print only functions responsible for the first 99% of time spent. This cuts off a lot of noise.
    sum_report = 0
    for i,t in ipairs(dt) do
        sum_report = sum_report + t[key]
        if sum_report >= sum_key*0.01 then
            dumptimes(t)
        end
    end

    LOG(' ')
    LOG('Total time running scripts: ',strtime(sum_here))
end

-- Note: For memreport to function, you must call debug.trackkallocations(true)
--       There is one in globalinit.lua but you may also place it in anywhere you
--       want to begin tracking memory allocations
--       simlua import("/lua/system/profile.lua").memreport()
function memreport()
    local all = table.copy(debug.allocinfo())

    -- Sum up totals by stacktrace
    local rt = {}
    for obj,trace in all do
        local sum = rt[trace] or { objects=0, bytes=0, trace=trace }
        rt[trace] = sum

        sum.objects = sum.objects + 1
        sum.bytes = sum.bytes + debug.allocatedsize(obj)
    end

    rt = table.values(rt)
    table.sort(rt, sort_down_by 'bytes')

    -- Dump report
    local n = 0
    for i,sum in rt do
        LOG(sum.bytes,' bytes in ',sum.objects,' objects of type ',sum.trace)
        n = n+1
        if n>=100 then break end
    end
end
