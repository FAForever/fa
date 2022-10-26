local lust = require "lust"

-- color library
dofile "../lua/shared/color.lua"

local function hueShuffle(hue, chroma, interp)
    if 0 <= hue and hue < 1 then
        return chroma, interp, 0
    elseif 1 <= hue and hue < 2 then
        return interp, chroma, 0
    elseif 2 <= hue and hue < 3 then
        return 0, chroma, interp
    elseif 3 <= hue and hue < 4 then
        return 0, interp, chroma
    elseif 4 <= hue and hue < 5 then
        return interp, 0, chroma
    elseif 5 <= hue and hue < 6 then
        return chroma, 0, interp
    end
end

local function HSVtoRGBsimp(hue, sat, val)
    local chroma = sat * val
    local bright = val - chroma
    hue = hue * 6
    local interp = chroma * (1 - math.abs(math.mod(hue, 2) - 1))
    local r, g, b = hueShuffle(hue, chroma, interp)
    return r + bright, g + bright, b + bright
end

local function HSLtoRGBsimp(hue, sat, lit)
    local chroma = sat * (1 - math.abs(2 * lit - 1))
    local bright = lit - chroma / 2
    hue = hue * 6
    local interp = chroma * (1 - math.abs(math.mod(hue, 2) - 1))
    local r, g, b = hueShuffle(hue, chroma, interp)
    return r + bright, g + bright, b + bright
end

local function rgbHVC(r, g, b)
    local hue = 0
    local value = math.max(r, g, b)
    local chroma = value - math.min(r, g, b)
    if chroma ~= 0 then
        if value == r then
            hue = 0 + (g - b) / chroma
        elseif value == g then
            hue = 2 + (b - r) / chroma
        elseif value == b then
            hue = 4 + (r - g) / chroma
        end
    end
    return hue, value, chroma
end

local function RGBtoHSVsimp(r, g, b)
    local hue, value, chroma = rgbHVC(r, g, b)
    local sat = 0
    if value ~= 0 then
        sat = chroma / value
    end
    return hue, sat, value
end

local function RGBtoHSLsimp(r, g, b)
    local hue, value, chroma = rgbHVC(r, g, b)
    local lit = value - chroma / 2
    local sat = 0
    if lit ~= 0 and lit ~= 1 then
        sat = (value - lit) / math.min(lit, 1 - lit)
    end
    return hue, sat, lit
end

lust.describe("Color functions", function()
    local colorConversions = {
        HSV = {RGBtoHSVsimp, HSVtoRGBsimp, RGBtoHSV, HSVtoRGB},
        HSL = {RGBtoHSLsimp, HSLtoRGBsimp, RGBtoHSL, HSLtoRGB},
    }
    local testColors = {
    --    R    G    B
        {0.0, 0.0, 0.0},
        {0.1635, 0.0, 0.0},
        {0.2, 0.0, 0.0},
        {0.36543256, 0.0, 0.0},
        {0.7, 0.0, 0.0},
        {1.0, 0.0, 0.0},
        {1.0, 0.93278, 0.0},
        {1.0, 0.7, 0.0},
        {1.0, 0.5, 0.0},
        {1.0, 0.49, 0.0},
        {1.0, 0.3, 0.0},
        {1.0, 0.219, 0.0},
        {1.0, 0.218, 0.0},
        {1.0, 0.21799999475479, 0.0},
        {1.0, 0.21799898147583, 0.0},
        {1.0, 0.199, 0.0},
        {1.0, 0.2, 0.0},
        {1.0, 0.1, 0.0},
        {1.0, 1.0, 0.0},
        {0.5, 1.0, 0.0},
        {0.0, 1.0, 0.0},
        {0.0, 1.0, 0.4},
        {0.0, 1.0, 1.0},
        {0.0, 0.9, 1.0},
        {0.0, 0.0, 1.0},
        {0.5, 0.0, 1.0},
        {1.0, 0.0, 1.0},
        {1.0, 1.0, 1.0},

        {0.6, 0.6, 0.6},
        {0.3, 0.2, 0.0},
        {1.0, 0.2, 0.0},
        {1.0, 0.7, 0.2},
        {1.0, 1.0, 0.2},
        {0.5, 1.0, 0.2},
        {0.2, 1.0, 0.2},
        {0.2, 1.0, 0.4},
        {0.2, 1.0, 1.0},
        {0.2, 0.9, 1.0},
        {0.2, 0.0, 1.0},
        {0.5, 0.2, 1.0},
        {1.0, 0.2, 1.0},
        {1.0, 1.0, 1.0},

        -- {2, 2, 3},
        -- {242, 64, 4},
        -- {23, 54, 124},
    }
    local err = 0.00001
    lust.describe_each("%s color conversion", colorConversions, function(name, fnSet)
        local compareForward, compareBackward, testForward, testBackward = unpack(fnSet)
        local converName = "Test RGB to " .. name
        lust.test_all(converName .. " forward conversion", testColors, function(col)
            local r, g, b = col[1], col[2], col[3]
            lust.expect(compareForward(r, g, b)).to.be.within(err).of(testForward(r, g, b))
            lust.expect(r, g, b).to.be.within(err).of(compareBackward(testForward(r, g, b)))
        end)
        lust.test_all(converName .. " back conversion", testColors, function(col)
            local r, g, b = col[1], col[2], col[3]
            local f1, f2, f3 = testForward(r, g, b)
            lust.expect(compareBackward(f1, f2, f3)).to.be.within(err).of(testBackward(f1, f2, f3))
            lust.expect(f1, f2, f3).to.be.within(err).of(compareForward(testBackward(f1, f2, f3)))
        end)
        lust.test_all(converName .. " round conversion", testColors, function(col)
            local r, g, b = col[1], col[2], col[3]
            local r1, g1, b1 = testBackward(testForward(r, g, b))
            lust.expect(r, g, b).to.be.within(err).of(r1, g1, b1)
        end)
    end)
end)

lust.finish()
