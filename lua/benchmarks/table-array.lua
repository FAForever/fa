
-- Array01       = 0.00512
-- Array02       = 0.00830
-- Array04       = 0.01464
-- Array08       = 0.02685
-- Array16       = 0.0512

-- ArrayCached01 = 0.00341
-- ArrayCached02 = 0.00610
-- ArrayCached04 = 0.008300
-- ArrayCached08 = 0.012939
-- ArrayCached16 = 0.02099

-- The speed up of just caching is astounding - even in the situation where we cache it for a 
-- single use. When we look at the byte code we see the following pattern:
-- Array:       GETTABLE, ADD, GETTABLE, ADD, GETTABLE, ADD, GETTABLE, ADD
-- ArrayCached: GETTABLE, GETTABLE, GETTABLE, GETTABLE, ADD, ADD, ADD, ADD

-- I can not confirm it, but I suspect the get table is optimized to quickly get several 
-- elements in succession. This may be just the cacheline of the CPU, but we see a similar 
-- behavior with the hashed part of a table.


ModuleName = "Table Array"
BenchmarkData = {
    Array01 = "Array - 1",
    Array02 = "Array - 2",
    Array04 = "Array - 4",
    Array08 = "Array - 8",
    Array16 = "Array - 16",
    ArrayCached01 = "Array Cached - 1",
    ArrayCached02 = "Array Cached - 2",
    ArrayCached04 = "Array Cached - 4",
    ArrayCached08 = "Array Cached - 8",
    ArrayCached16 = "Array Cached - 16",
}

function Array01(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { 1, 1, 1, 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        a = 0 + element[1] + element[2] + element[3] + element[4]
    end

    local final = timer()
    return final - start
end

function Array02(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { 1, 1, 1, 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
    end

    local final = timer()
    return final - start
end

function Array04(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { 1, 1, 1, 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
    end

    local final = timer()
    return final - start
end

function Array08(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { 1, 1, 1, 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]

        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
    end

    local final = timer()
    return final - start
end

function Array16(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { 1, 1, 1, 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]

        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]

        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]

        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
    end

    local final = timer()
    return final - start
end

function ArrayCached01(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { 1, 1, 1, 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        local el1 = element[1]
        local el2 = element[2]
        local el3 = element[3]
        local el4 = element[4]

        a = 0 + el1 + el2 + el3 + el4
    end

    local final = timer()
    return final - start
end


function ArrayCached02(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { 1, 1, 1, 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        local el1 = element[1]
        local el2 = element[2]
        local el3 = element[3]
        local el4 = element[4]

        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
    end

    local final = timer()
    return final - start
end


function ArrayCached04(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { 1, 1, 1, 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        local el1 = element[1]
        local el2 = element[2]
        local el3 = element[3]
        local el4 = element[4]

        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
    end

    local final = timer()
    return final - start
end


function ArrayCached08(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { 1, 1, 1, 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        local el1 = element[1]
        local el2 = element[2]
        local el3 = element[3]
        local el4 = element[4]

        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4

        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
    end

    local final = timer()
    return final - start
end


function ArrayCached16(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { 1, 1, 1, 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        local el1 = element[1]
        local el2 = element[2]
        local el3 = element[3]
        local el4 = element[4]

        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4

        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4

        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4

        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
    end

    local final = timer()
    return final - start
end
