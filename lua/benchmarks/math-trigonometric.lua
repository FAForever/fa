
-- Results with loop count 100000:
--
-- |--------------------------------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|-------|
-- | Name                           | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms | CV % | Median ms | Min ms | Max ms |  Skew |
-- |--------------------------------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|-------|
-- | "Global math.cos"              |      28 |  4.8174 |     0.0166 |      0.35 | 0.0429 | 0.89 |    4.8218 | 4.7607 | 4.9133 |  0.24 |
-- | "Local math.cos"               |      29 |  4.3367 |     0.0104 |      0.24 | 0.0275 | 0.63 |    4.3335 | 4.3030 | 4.3945 |  0.37 |
-- | "Local math.cos per iteration" |      27 |  4.9405 |     0.0118 |      0.24 | 0.0297 | 0.60 |    4.9438 | 4.8828 | 5.0049 |  0.45 |
-- | "Upvalued math.cos"            |      28 |  4.3411 |     0.0083 |      0.19 | 0.0214 | 0.49 |    4.3335 | 4.3030 | 4.3640 | -0.35 |
-- | "Global math.sin"              |      26 |  4.5823 |     0.0090 |      0.20 | 0.0223 | 0.49 |    4.5776 | 4.5471 | 4.6082 | -0.22 |
-- | "Local math.sin"               |      24 |  4.1517 |     0.0097 |      0.23 | 0.0229 | 0.55 |    4.1504 | 4.1199 | 4.1809 | -0.06 |
-- | "Local math.sin per iteration" |      26 |  4.7537 |     0.0080 |      0.17 | 0.0199 | 0.42 |    4.7607 | 4.7302 | 4.7913 |  0.23 |
-- | "Upvalued math.sin"            |      28 |  4.1733 |     0.0135 |      0.32 | 0.0349 | 0.84 |    4.1656 | 4.1199 | 4.2419 |  0.33 |
-- | "Global math.tan"              |      26 |  4.3945 |     0.0171 |      0.39 | 0.0423 | 0.96 |    4.3945 | 4.3030 | 4.4861 |  0.00 |
-- | "Local math.tan"               |      27 |  3.3355 |     0.0081 |      0.24 | 0.0204 | 0.61 |    3.3264 | 3.2959 | 3.3569 | -0.38 |
-- | "Local math.tan per iteration" |      29 |  4.5871 |     0.0206 |      0.45 | 0.0542 | 1.18 |    4.6082 | 4.4861 | 4.6997 | -0.01 |
-- | "Upvalued math.tan"            |      28 |  3.3744 |     0.0075 |      0.22 | 0.0194 | 0.57 |    3.3722 | 3.3569 | 3.4180 |  0.58 |
-- |--------------------------------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|-------|
-- | "Baseline, 1 parameter"        |     341 |  0.3775 |     0.0017 |      0.44 | 0.0157 | 4.15 |    0.3662 | 0.3357 | 0.3967 |  0.21 |
-- |--------------------------------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|-------|

-- Conclusion: each call costs about 30 to 40 ns without the loop, 2.3 to 3x as much as `math.abs`
-- (about 13 ns), so they are not as cheap as a lookup table. Upvaluing them saves 4 to 10 ns per
-- call, like the other math functions.

---@diagnostic disable: discard-returns

ModuleName = "Math Trigonometry"
ModuleLoopCount = 100000
BenchmarkData = {
    SinGlobal = "Global math.sin",
    SinUpvalue = "Upvalued math.sin",
    SinLocal = "Local math.sin",
    SinLocalPerIteration = "Local math.sin per iteration",
    CosGlobal = "Global math.cos",
    CosUpvalue = "Upvalued math.cos",
    CosLocal = "Local math.cos",
    CosLocalPerIteration = "Local math.cos per iteration",
    TanGlobal = "Global math.tan",
    TanUpvalue = "Upvalued math.tan",
    TanLocal = "Local math.tan",
    TanLocalPerIteration = "Local math.tan per iteration",
}


function SinGlobal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        math.sin(a)
    end

    local final = timer()
    return final - start
end

local MathSin = math.sin

function SinUpvalue(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        MathSin(a)
    end

    local final = timer()
    return final - start
end

function SinLocal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    local MathSin = math.sin
    for _ = 1, loop do
        MathSin(a)
    end

    local final = timer()
    return final - start
end

function SinLocalPerIteration(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        local MathSin = math.sin
        MathSin(a)
    end

    local final = timer()
    return final - start
end

function CosGlobal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        math.cos(a)
    end

    local final = timer()
    return final - start
end

local MathCos = math.cos

function CosUpvalue(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        MathCos(a)
    end

    local final = timer()
    return final - start
end

function CosLocal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    local MathCos = math.cos
    for _ = 1, loop do
        MathCos(a)
    end

    local final = timer()
    return final - start
end

function CosLocalPerIteration(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for k = 1, loop do
        local MathCos = math.cos
        MathCos(a)
    end

    local final = timer()
    return final - start
end

function TanGlobal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        math.tan(a)
    end

    local final = timer()
    return final - start
end

local MathTan = math.tan

function TanUpvalue(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        MathTan(a)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function TanLocal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    local MathTan = math.tan
    for _ = 1, loop do
        MathTan(a)
    end

    local final = timer()
    return final - start
end

function TanLocalPerIteration(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        local MathTan = math.tan
        MathTan(a)
    end

    local final = timer()
    return final - start
end
