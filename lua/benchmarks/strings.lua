
ModuleName = "Strings"
BenchmarkData = {
    EachIterationString = "String concat",
    CallColon = "Call Colon",
    CallGlobal = "Call Global",
    CallLocal = "Call Local",
}

function EachIterationString(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local test
    local string = "to-test-this-long-string"
    local start = timer()

    for k = 1, loop do
        test = string .. k
    end

    local final = timer()
    return final - start
end

function CallColon(innerLoop, outerLoop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local str = "str"
    local start = timer()

    for _ = 1, outerLoop do
        for _ = 1, innerLoop do
            str:len()
        end
    end

    local final = timer()
    return final - start
end

function CallGlobal(outerLoop, innerLoop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local str = "str"
    local start = timer()

    for _ = 1, outerLoop do
        for _ = 1, innerLoop do
            string.len(str)
        end
    end

    local final = timer()
    return final - start
end

function CallLocal(outerLoop, innerLoop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local str = "str"
    local start = timer()

    for _ = 1, outerLoop do
        local StringLen = string.len
        for _ = 1, innerLoop do
            StringLen(str)
        end
    end

    local final = timer()
    return final - start
end