
-- FunctionCall:    3.32 ms
-- ThreadCall:      123.36 ms
-- NoCall:          0.54 ms

-- A disclaimer to these results is that the fork thread doesn't actually do the work, the call only 
-- allocates a new thread and that starts doing the work after the current thread is finished. Therefore 
-- the real work is not part of the benchmark. All that we are seeing here are the costs to launch 
-- a new thread.

-- A conclusion that we can draw here is that conditions that may terminate the thread before it starts
-- doing work should be done before we initialize the thread, instead of at the start of it. This is 
-- commonly done in unit.lua and we can optimize that for sure.

function FunctionCall()

    local sum = 0
    local function AddToSum()
        sum = sum + 1
    end

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        AddToSum()
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function ThreadCall()

    local sum = 0
    local function AddToSum()
        sum = sum + 1
    end

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        ForkThread(AddToSum)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function NoCall()

    local sum = 0

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        sum = sum + 1
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end