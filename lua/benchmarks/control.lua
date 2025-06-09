
ModuleName = "Control"
ModuleSort = 1
BenchmarkData = {
    BaseLineLoop = {
        name = "Base Line Loop",
        desc = "Runs an empty loop for",
        __loop_baseline = 1,
    },
    BaseLineLoop2 = {
        name = "Base Line Double Loop",
        desc = "Runs an empty loop nested in a loop",
        __loop_baseline = 2,
    },
}

function BaseLineLoop(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local start = timer()

    for _ = 1, loop do
        local a = 0 -- needed or else the forloop instruction jumps to itself and terminates early
    end

    local final = timer()
    return final - start
end

function BaseLineLoop2(outerLoop, innerLoop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local start = timer()

    for _ = 1, outerLoop do
        for _ = 1, innerLoop do
            local a = 0
        end
    end

    local final = timer()
    return final - start
end
