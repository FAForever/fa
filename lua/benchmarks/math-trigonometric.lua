
-- Results with loop count 100000:
--
-- |--------------------------------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|-------|
-- | Name                           | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms | CV % | Median ms | Min ms | Max ms |  Skew |
-- |--------------------------------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|-------|
-- | "Global math.cos"              |      30 |  4.9967 |     0.0266 |      0.53 | 0.0712 | 1.42 |    5.0049 | 4.8828 | 5.1270 |  0.50 |
-- | "Local math.cos"               |      26 |  4.3523 |     0.0194 |      0.45 | 0.0481 | 1.11 |    4.3335 | 4.2725 | 4.4556 |  0.86 |
-- | "Local math.cos per iteration" |      28 |  4.9177 |     0.0136 |      0.28 | 0.0350 | 0.71 |    4.9438 | 4.8828 | 5.0049 |  0.30 |
-- | "Upvalued math.cos"            |      21 |  4.3335 |     0.0000 |      0.00 | 0.0000 | 0.00 |    4.3335 | 4.3335 | 4.3335 |  0.00 |
-- | "Global math.sin"              |      31 |  4.6269 |     0.0135 |      0.29 | 0.0367 | 0.79 |    4.6387 | 4.5776 | 4.6997 |  0.08 |
-- | "Local math.sin"               |      25 |  4.6997 |     0.0145 |      0.31 | 0.0352 | 0.75 |    4.6997 | 4.6387 | 4.7607 |  0.00 |
-- | "Local math.sin per iteration" |      29 |  4.7586 |     0.0158 |      0.33 | 0.0415 | 0.87 |    4.7607 | 4.6997 | 4.8218 |  0.04 |
-- | "Upvalued math.sin"            |      27 |  4.1662 |     0.0158 |      0.38 | 0.0400 | 0.96 |    4.1504 | 4.0894 | 4.2114 | -0.28 |
-- | "Global math.tan"              |      26 |  4.3734 |     0.0155 |      0.35 | 0.0384 | 0.88 |    4.3945 | 4.3335 | 4.4556 |  0.36 |
-- | "Local math.tan"               |      27 |  3.3750 |     0.0131 |      0.39 | 0.0331 | 0.98 |    3.3569 | 3.2959 | 3.4180 |  0.12 |
-- | "Local math.tan per iteration" |      32 |  4.6349 |     0.0387 |      0.84 | 0.1085 | 2.34 |    4.6387 | 4.4556 | 4.8828 |  0.49 |
-- | "Upvalued math.tan"            |      29 |  3.4032 |     0.0203 |      0.60 | 0.0532 | 1.56 |    3.4180 | 3.2959 | 3.4790 |  0.15 |
-- |--------------------------------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|-------|
-- | "Baseline, 1 parameter"        |     372 |  0.3811 |     0.0037 |      0.98 | 0.0368 | 9.65 |    0.3662 | 0.3052 | 0.7324 |  3.59 |
-- |--------------------------------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|-------|

-- Conclusion: each call costs about 30 to 40 ns without the loop, 2.5 to 3x as much as `math.abs`
-- (about 13 ns), so they are not as cheap as a lookup table. Upvaluing them saves 5 to 10 ns per
-- call, like the other math functions.
--
-- "Local math.sin" passed the loop counter instead of 1 when these results were taken, and
-- larger angles take longer, so it needs a rerun.

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
