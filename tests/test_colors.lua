local luft = require "luft"

-- color library
dofile "../lua/shared/color.lua"

local function hueShuffle(hue, a, b, c)
        if 0 <= hue and hue < 1 then  return a, b, c
    elseif 1 <= hue and hue < 2 then  return b, a, c
    elseif 2 <= hue and hue < 3 then  return c, a, b
    elseif 3 <= hue and hue < 4 then  return c, b, a
    elseif 4 <= hue and hue < 5 then  return b, c, a
    elseif 5 <= hue and hue <=6 then  return a, c, b
    end
end
local function HCItoRGB(hue, chroma, intensity)
    hue = hue * 6
    local secondary = chroma * (1 - math.abs(math.mod(hue, 2) - 1))
    return hueShuffle(hue, chroma + intensity, secondary + intensity, intensity)
end

local function HSVtoRGBsimp(hue, sat, val)
    local chroma = sat * val
    local intensity = val - chroma
    return HCItoRGB(hue, chroma, intensity)
end
local function HSLtoRGBsimp(hue, sat, lit)
    local chroma = sat * (1 - math.abs(2 * lit - 1))
    local intensity = lit - chroma / 2
    return HCItoRGB(hue, chroma, intensity)
end


local function RGBtoHVC(r, g, b)
    local hue = 0
    local value = math.max(r, g, b)
    local chroma = value - math.min(r, g, b)
    if chroma ~= 0 then
        -- order matters here, probably
        if false then
            elseif value == r then  hue = 0 + (g - b) / chroma
            elseif value == g then  hue = 2 + (b - r) / chroma
            elseif value == b then  hue = 4 + (r - g) / chroma
        end
        if hue < 0 then
            hue = hue + 6
        end
        if hue >= 6 then
            hue = hue - 6
        end
    end
    return hue / 6, value, chroma
end

local function RGBtoHSVsimp(r, g, b)
    local hue, value, chroma = RGBtoHVC(r, g, b)
    local sat = 0
    if value ~= 0 then
        sat = chroma / value
    end
    return hue, sat, value
end
local function RGBtoHSLsimp(r, g, b)
    local hue, value, chroma = RGBtoHVC(r, g, b)
    local lit = value - chroma / 2
    local sat = 0
    if lit ~= 0 and lit ~= 1 then
        sat = (value - lit) / math.min(lit, 1 - lit)
    end
    return hue, sat, lit
end


local function HSVtoHSLsimp(h, s, v)
    local lit = v * (1 - s / 2)
    local sat = 0
    if lit ~= 0 and lit ~= 1 then
        sat = (v - lit) / math.min(lit, 1 - lit)
    end
    return h, sat, lit
end
local function HSLtoHSVsimp(h, s, l)
    local val = l + s * math.min(l, 1 - l)
    local sat = 0
    if val ~= 0 then
        sat = 2 * (1 - l / val)
    end
    return h, sat, val
end


luft.describe("Color functions", function()
    local colorConversions = {
        HSV = {RGBtoHSVsimp, HSVtoRGBsimp, RGBtoHSV, HSVtoRGB},
        HSL = {RGBtoHSLsimp, HSLtoRGBsimp, RGBtoHSL, HSLtoRGB},
    }
    local testColors = {
    --    R    G    B                subtest
        {0.0, 0.0, 0.0},              -- 1
        {0.1635, 0.0, 0.0},           -- 2
        {0.2, 0.0, 0.0},              -- 3
        {0.36543256, 0.0, 0.0},       -- 4
        {0.7, 0.0, 0.0},              -- 5
        {1.0, 0.0, 0.0},              -- 6
        {1.0, 0.93278, 0.0},          -- 7
        {1.0, 0.7, 0.0},              -- 8
        {1.0, 0.5, 0.0},              -- 9
        {1.0, 0.49, 0.0},             -- 10
        {1.0, 0.3, 0.0},              -- 11
        {1.0, 0.219, 0.0},            -- 12
        {1.0, 0.218, 0.0},            -- 13
        {1.0, 0.21799999475479, 0.0}, -- 14
        {1.0, 0.21799898147583, 0.0}, -- 15
        {1.0, 0.199, 0.0},            -- 16
        {1.0, 0.2, 0.0},              -- 17
        {1.0, 0.1, 0.0},              -- 18
        {1.0, 1.0, 0.0},              -- 19
        {0.5, 1.0, 0.0},              -- 20
        {0.0, 1.0, 0.0},              -- 21
        {0.0, 1.0, 0.4},              -- 22
        {0.0, 1.0, 1.0},              -- 23
        {0.0, 0.9, 1.0},              -- 24
        {0.0, 0.0, 1.0},              -- 25
        {0.5, 0.0, 1.0},              -- 26
        {1.0, 0.0, 1.0},              -- 27
        {1.0, 1.0, 1.0},              -- 28

        {0.6, 0.6, 0.6},              -- 29
        {0.3, 0.2, 0.0},              -- 30
        {1.0, 0.2, 0.0},              -- 31
        {1.0, 0.7, 0.2},              -- 32
        {1.0, 1.0, 0.2},              -- 33
        {0.5, 1.0, 0.2},              -- 34
        {0.2, 1.0, 0.2},              -- 35
        {0.2, 1.0, 0.4},              -- 36
        {0.2, 1.0, 1.0},              -- 37
        {0.2, 0.9, 1.0},              -- 38
        {0.2, 0.0, 1.0},              -- 39
        {0.5, 0.2, 1.0},              -- 40
        {1.0, 0.2, 1.0},              -- 41
        {1.0, 1.0, 1.0},              -- 42

        {2, 2, 3},
        {242, 64, 4},
        {23, 54, 124},
        {123, 4, 144},
        {201, 194, 95},
        {255, 255, 255},
        {255, 255, 0},
        {255, 0, 255},
        {0, 255, 255},
        {0, 0, 255},
        {0, 255, 0},
        {255, 0, 0},
    }
    luft.margin_of_error = 0.00000029
    luft.describe_each("%s to RGB", colorConversions, function(name, fnSet)
        local compareForward, compareBackward, testForward, testBackward = unpack(fnSet)
        luft.test_all("Forward conversion", testColors, function(col)
            local ro, go, bo = col[1], col[2], col[3]
            local r, g, b = RGBtoFloat(ro, go, bo)
            local f1, f2, f3 = testForward(r, g, b)
            luft.expect(f1, f2, f3).to.be.close(compareForward(r, g, b))
            luft.expect(compareBackward(f1, f2, f3)).to.be.close(r, g, b)
        end)
        luft.test_all("Back conversion", testColors, function(col)
            local ro, go, bo = col[1], col[2], col[3]
            local r, g, b = RGBtoFloat(ro, go, bo)
            local f1, f2, f3 = testForward(r, g, b)
            local b1, b2, b3 = testBackward(f1, f2, f3)
            luft.expect(b1, b2, b3).to.be.close(compareBackward(f1, f2, f3))
            luft.expect(compareForward(b1, b2, b3)).to.be.close(f1, f2, f3)
        end)
        luft.test_all("Round conversion", testColors, function(col)
            local ro, go, bo = col[1], col[2], col[3]
            local r, g, b = RGBtoFloat(ro, go, bo)
            local r1, g1, b1 = testBackward(testForward(r, g, b))
            luft.expect(r1, g1, b1).to.be.close(r, g, b)
            if ro > 1 or go > 1 or bo > 1 then
                luft.expect(ColorRGB(r1, g1, b1)).to.equal(("%02X%02X%02X"):format(ro, go, bo))
            end
        end)
    end)
    luft.test_all("HSV and HSL conversions", testColors, function(col)
        local a, b, c = RGBtoFloat(col[1], col[2], col[3])
        luft.expect(HSVtoHSL(a, b, c)).to.equal(HSVtoHSLsimp(a, b, c))
        luft.expect(HSLtoHSV(a, b, c)).to.equal(HSLtoHSVsimp(a, b, c))
    end)
end)

luft.finish()
