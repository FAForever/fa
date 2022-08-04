

ModuleName = "Strings"
BenchmarkData = {
    EachIterationNothing = "NOP",
    EachIterationString = "String concat",
}

function EachIterationNothing()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do

    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function EachIterationString()

    local function ToCall()
    end

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local string = "to-test-this-long-string"
    for k = 1, 100000 do
        local test = string .. k 
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function CallColon()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local str = "str"
    for k = 1, 10000 do
        local test = str:len()
        local test = str:len()
        local test = str:len()
        local test = str:len()
        local test = str:len()
        local test = str:len()
        local test = str:len()
        local test = str:len()
        local test = str:len()
        local test = str:len()
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function CallGlobal()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local str = "str"
    for k = 1, 10000 do
        local test = string.len(str)
        local test = string.len(str)
        local test = string.len(str)
        local test = string.len(str)
        local test = string.len(str)
        local test = string.len(str)
        local test = string.len(str)
        local test = string.len(str)
        local test = string.len(str)
        local test = string.len(str)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function CallLocal()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local str = "str"
    for k = 1, 10000 do
        local StringLen = string.len
        local test = StringLen(str)
        local test = StringLen(str)
        local test = StringLen(str)
        local test = StringLen(str)
        local test = StringLen(str)
        local test = StringLen(str)
        local test = StringLen(str)
        local test = StringLen(str)
        local test = StringLen(str)
        local test = StringLen(str)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end