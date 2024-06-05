--**************************************************************************************************
--** Shared under the MIT license
--**************************************************************************************************
--
-- Color library for Moho Lua (based on LuaPlus 5.0)
--
-- Provides:
--   * Conversion of colors in RGB <-> HSV <-> HSL
--   * Parsing and building colors strings the Moho engine understands
--
-- All component arguments and return values are floating-points numbers `0.0` to `1.0` (though the
-- functions that take RGB values will try to detect numbers being passed in `0` to `255` and scale
-- accordingly).

-- note the lack of the `__ENV = {} ... return __ENV` module idiom due to use of Moho's `import`
-- function, so this will need to be adapted for use with `require`


--- Returns the RGBA components of color string. Note that alpha is only returned if specified
--- in the color. The components are all floating-point numbers `0.0` to `1.0`. The supported colors
--- are in the form "RRGGBB", "AARRGGBB", or a color enum the engine supports.
---@param color Color
---@return number | false red
---@return number | nil green
---@return number | nil blue
---@return number? alpha
function ParseColor(color)
    local nibble1 = tonumber(color:sub(1, 2), 16)
    if nibble1 then
        local nibble2 = tonumber(color:sub(3, 4), 16)
        if nibble2 then
            local nibble3 = tonumber(color:sub(5, 6), 16)
            if nibble3 then
                local nibble4 = tonumber(color:sub(7, 8), 16)
                if nibble4 then
                    -- AARRGGBB but return as R, G, B, A
                    return nibble2 / 255, nibble3 / 255, nibble4 / 255, nibble1 / 255
                end
                -- RRGGBB
                return nibble1 / 255, nibble2 / 255, nibble3 / 255
            end
        end
    end
    -- fallback on enum colors
    -- this enum color has an alpha value we handle specially
    if color == "transparent" then
        return 0, 0, 0, 0
    end
    color = EnumColors[string.upper(color)]
    if not color then
        return false
    end
    local r, g, b =
        tonumber(color:sub(1, 2), 16),
        tonumber(color:sub(3, 4), 16),
        tonumber(color:sub(5, 6), 16)
    return r / 255, g / 255, b / 255
end

--- Returns the alpha component of a color string if present, `1.0` otherwise.
---@param color Color
---@return number alpha
function GetAlpha(color)
    color = EnumColors[string.upper(color)] or color
    if color:sub(7,8) == "" then
        return 0
    else
        return tonumber(color:sub(1,2), 16) / 255
    end
end

--- Returns the color with its alpha multiplied by a number
---@param color Color
---@param mult number
---@return Color
function MultiplyAlpha(color, mult)
    color = EnumColors[string.upper(color)] or color
    if color:sub(7, 8) == "" then
        return string.format("%02X", math.clamp(255 * mult, 0, 255)) .. color:sub(1, 6)
    else
        return string.format("%02X", math.clamp(tonumber(color:sub(1, 2), 16) * mult, 0, 255)) .. color:sub(3, 8)
    end
end

----------------------------------------
-- Color Conversions
----------------------------------------

--------------------
-- To RGB
--------------------

--- Returns the red, green, and blue (RGB) components of a color constructed using hue, saturation,
--- and value (HSV). This is a color space independent conversion, as HSV is a linear transformation
--- of the underlying RGB color space it is represented in. All arguments and return values are
--- floating-point numbers `0.0` to `1.0`. All arguments are optional, defaulting to red hue, full
--- saturation, and full value. Incorrect results will be returned if `sat` or `val` are out of
--- range, but `hue` will correctly wrap around the color circle (e.g. `1.0` is `0.0`) in either
--- direction.
---
--- The HSV transformation is performed by projecting the RGB color cube into 2D space while looking
--- at the white corner towards the center--the edges of the resulting hexagon represents a 'walk'
--- along the six most colorful edges of the color cube (that is, those that don't fade to black or
--- white) and its center is white. This is the set of the most luminious of colors that differ only
--- by chrominance. This hexagon is transformed into a circle so that a point on it can be defined
--- by an angle, or "hue", and a distance, or "saturation". The rest of the colors in the color
--- space will have less luminance than these and so are represented by one of these chromatic color
--- multiplied by some "value". The end product is a mapping of the cube to a cylinder.
---
--- This is similar to the HSL transformation, but it handles brightness differently.
---@param hue? number defaults to `0.0` turns (red)
---@param sat? number defaults to `1.0` (fully colorful)
---@param val? number defaults to `1.0` (fully bright)
---@return number red
---@return number green
---@return number blue
function HSVtoRGB(hue, sat, val)
    if val then
        if val == 0 then -- check for black
            return 0, 0, 0
        end
    else
        val = 1 -- default to 1.0
    end
    if sat then
        if sat ~= 1 then
            -- special-case grays so we don't waste time messing with interpolating hue stuff
            if sat == 0 then
                if val then
                    return val, val, val
                end
                return 1, 1, 1
            end
        else
            sat = nil -- enable absent-value optimization
        end
    end
    if not hue then
        -- if there's no hue though we can skip the piecewise function altogether
        if val and val ~= 1 then
            sat = sat * val
            return val, val + sat, val - sat
        end
        return 1, 1 + sat, 1 - sat
    end
    -- scale by the sectors and check for wrap around
    hue = hue * 6
    if hue < 0 then
        hue = 1 + math.mod(hue, 1)
    elseif hue >= 6 then
        hue = math.mod(hue, 1)
    end

    local r, g, b
    if sat then
        -- Split if-statements into a tree instead of a long elseif chain so that the worst case
        -- only has checks 3 instead of 5. Being a non- power of 2, some of the branches will have
        -- fewer checks; these are the yellow sectors.
        if hue <= 2 then
            b = 1 - sat
            if hue <= 1 then   -- sector 1, g: sat -> 1 (red -> yellow)
                -- we can reuse `b` as a special optimization here
                r, g = 1, b + hue * sat
            else               -- sector 2, r: 1 -> 1 (yellow -> green)
                g, r = 1, 1 + (1 - hue) * sat
            end
        elseif hue <= 4 then
            r = 1 - sat
            if hue <= 3 then   -- sector 3, b: sat -> 1 (green -> cyan)
                g, b = 1, 1 + (hue - 3) * sat
            else               -- sector 4, g: 1 -> sat (cyan -> blue)
                b, g = 1, 1 + (3 - hue) * sat
            end
        else
            g = 1 - sat
            if hue <= 5 then   -- sector 5, r: sat -> 1 (blue -> magenta)
                b, r = 1, 1 + (hue - 5) * sat
            else               -- sector 6, b: 1 -> sat (magenta -> red)
                r, b = 1, 1 + (5 - hue) * sat
            end
        end
    else
        -- for each sector, one RGB component will be maxed out at 1, one will interpolate from 0 to
        -- 1, and the last is 0; which component is doing what cycles between each sector
        if hue <= 2 then
            b = 0
            if hue <= 1 then   -- sector 1, g: 0 -> 1 (red -> yellow)
                r, g = 1, hue
            else               -- sector 2, r: 1 -> 0 (yellow -> green)
                g, r = 1, 2 - hue
            end
        elseif hue <= 4 then
            r = 0
            if hue <= 3 then   -- sector 3, b: 0 -> 1 (green -> cyan)
                g, b = 1, hue - 2
            else               -- sector 4, g: 1 -> 0 (cyan -> blue)
                b, g = 1, 4 - hue
            end
        else
            g = 0
            if hue <= 5 then   -- sector 5, r: 0 -> 1 (blue -> magenta)
                b, r = 1, hue - 4
            else               -- sector 6, b: 1 -> 0 (magenta -> red)
                r, b = 1, 6 - hue
            end
        end
    end

    -- finally, if there's a value, interpolate components from their nominal hue-sat values to 0
    if val ~= 1 then
        return r * val, g * val, b * val
    end
    return r, g, b
end

--- Returns the red, green, and blue (RGB) components of a color constructed using hue, saturation,
--- and lightness (HSL). This is a color space independent conversion, as HSL is a linear
--- transformation of the underlying RGB color space it is represented in. All arguments and return
--- values are floating-point numbers `0.0` to `1.0`. All arguments are optional, defaulting to red
--- hue, full saturation, and normal brightness. Incorrect results will be returned if `sat` or
--- `lit` are out of range, but `hue` will correctly wrap around the color circle (e.g. `1.0` is
--- `0.0`) in either direction.
---
--- The HSL transformation is very similar to the HSV transformation, but they differ in how they
--- apply luminance: whereas HSV starts at full luminance at the top of the color cylinder and
--- scales it by a "value" until everything is black at the base, HSL is all white at the top and
--- all black at the base--the "brighter" colors are higher and "darker" ones lower, which
--- corresponds to "lightness". In terms of the RGB color cube projection, the white corner is
--- mapped to a cylinder base like the black corner (pushing the colorful edges halfway down)
--- instead of being folded inside the saturated colors. This is why the default value for lightness
--- is `0.5`, and why changing the saturation also makes the color more gray.
---@param hue? number defaults to `0.0` turns (red)
---@param sat? number defaults to `1.0` (fully colorful)
---@param lit? number defaults to `0.5` (normal brightness)
---@return number red
---@return number green
---@return number blue
function HSLtoRGB(hue, sat, lit)
    local halfChroma
    if lit then
        if lit == 0 then -- check for black
            return 0, 0, 0
        end
        if lit == 1 then -- check for white
            return 1, 1, 1
        end
        if lit > 0.5 then
            halfChroma = (1 - lit) * sat
        else
            halfChroma =  lit * sat
        end
    else
        lit = 0.5 -- default to 0.5
        halfChroma = lit * sat
    end
    if not hue then
        -- if there's no hue though we can skip the piecewise function altogether
        local rb = lit - halfChroma
        return rb, lit + halfChroma, rb
    end
    -- scale hue into 6 sectors and check for wrap around
    -- each sector will have a size of 2 to undo the halving that lightness brings
    hue = hue * 12
    if hue < 0 then
        hue = 12 + math.mod(hue, 12)
    elseif hue >= 12 then
        hue = math.mod(hue, 12)
    end

    local r, g, b
    -- Split if-statements into a tree instead of a long elseif chain so that the worst case
    -- only checks 3 cases instead of all 5. Being a non- power of 2, some of the branches will
    -- have fewer checks; these are the yellow sectors.
    if hue <= 4 then
        b = lit - halfChroma
        if hue <= 2 then   -- sector 1, g: sat -> 1 (red -> yellow)
            -- we can reuse `b` as a special optimization here
            r, g = lit + halfChroma, b + hue * halfChroma
        else               -- sector 2, r: 1 -> sat (yellow -> green)
            g, r = lit + halfChroma, lit + (3 - hue) * halfChroma
        end
    elseif hue <= 8 then
        r = lit - halfChroma
        if hue <= 6 then   -- sector 3, b: sat -> 1 (green -> cyan)
            g, b = lit + halfChroma, lit + (hue - 5) * halfChroma
        else               -- sector 4, g: 1 -> sat (cyan -> blue)
            b, g = lit + halfChroma, lit + (7 - hue) * halfChroma
        end
    else
        g = lit - halfChroma
        if hue <= 10 then  -- sector 5, r: sat -> 1 (blue -> magenta)
            b, r = lit + halfChroma, lit + (hue - 9) * halfChroma
        else               -- sector 6, b: 1 -> sat (magenta -> red)
            r, b = lit + halfChroma, lit + (11 - hue) * halfChroma
        end
    end
    return r, g, b
end

--------------------
-- From RGB
--------------------

--- Makes sure that the given RGB components are floating-point numbers `0.0` to `1.0`. If the
--- number is greater than 1, it is divided by 255. If the number is exactly 1, it is presumed to be
--- `1.0` (the most common case) unless at least one other component is greater than 1. This means
--- that `RGBtoFloat(1, 1, 1)` will return `1.0, 1.0, 1.0` instead of `1/255, 1/255, 1/255`.
---@param red number
---@param green number
---@param blue number
---@return number
---@return number
---@return number
function RGBtoFloat(red, green, blue)
    if red == 1 then
        if green > 1 then
            if blue > 1 then
                return red / 255, green / 255, blue / 255
            end
            return red / 255, green / 255, blue
        elseif blue > 1 then
            return red / 255, green, blue / 255
        end
    elseif red > 1 then
        red = red / 255
    end
    if green == 1 then
        if blue > 1 then
            return red, green / 255, blue / 255
        end
    elseif green > 1 then
        green = green / 255
    end
    if blue > 1 then
        return red, green, blue / 255
    end
    return red, green, blue
end

--- Converts an RGB color to the hue, saturation, and value representation of the color. RGB can be
--- a floating-point `0.0` to `1.0` or an integer `0` to `255`. In the ambiguous case of `1`, it is
--- presumed that it is `1.0` (the most common case) unless at least one other component is greater
--- than 1.
--- See `HSVtoRGB()` for details on the conversion process.
---@param red number
---@param green number
---@param blue number
---@return number hue
---@return number saturation
---@return number value
function RGBtoHSV(red, green, blue)
    -- convert integers to floats
    red, green, blue = RGBtoFloat(red, green, blue)
    -- search for the order of the components, which tells us which sector we're in
    if green >= blue then
        if red >= green then    -- red >= green >= blue
            if red == blue then -- red == green == blue == gray
                return 0, 0, red
            end
            return
                0.1666666716337204 * (green - blue) / (red - blue),
                1 - blue / red,
                red
        end
        local hue = 0.1666666716337204 * (blue - red)
        if red >= blue then     -- green > red >= blue
            return
                0.3333333432674408 + hue / (green - blue),
                1 - blue / green,
                green
        end                     -- green >= blue > red
        return
            0.3333333432674408 + hue / (green - red),
            1 - red / green,
            green
    end
    if blue >= red then
        local hue = 0.1666666716337204 * (red - green)
        if green >= red then    -- blue > green >= red
            return
                0.66666668653488159 + hue / (blue - red),
                1 - red / blue,
                blue
        end                     -- blue >= red > green
        return
            0.66666668653488159 + hue / (blue - green),
            1 - green / blue,
            blue
    end                         -- red > blue > green
    return
        0.1666666716337204 * (green - blue) / (red - green),
        1 - green / red,
        red
end

--- Converts an RGB color to the hue, saturation, and lightness representation of the color. RGB can
--- be a floating-point `0.0` to `1.0` or an integer `0` to `255`. In the ambiguous case of `1`, it
--- is presumed that it is `1.0` (the most common case) unless at least one other component is
--- greater than 1.
--- See `HSLtoRGB()` for details on the conversion process.
---@param red number
---@param green number
---@param blue number
---@return number hue
---@return number saturation
---@return number lightness
function RGBtoHSL(red, green, blue)
    -- convert integers to floats
    red, green, blue = RGBtoFloat(red, green, blue)
    local hue, primary, tertiary
    -- search for the order of the components, which tells us which sector we're in
    if green >= blue then
        if red >= green then    -- red >= green >= blue
            if red == blue then -- red == green == blue == gray
                return 0, 0, red
            end
            hue = 0.1666666716337204 * (green - blue) / (red - blue)
            primary, tertiary = red, blue
        else -- green > red & blue
            primary = green
            hue = 0.1666666716337204 * (blue - red)
            if red >= blue then -- green > red >= blue
                hue = 0.3333333432674408 + hue / (green - blue)
                tertiary = blue
            else                -- green >= blue > red
                hue = 0.3333333432674408 + hue / (green - red)
                tertiary = red
            end
        end
    elseif blue >= red then -- blue > green & red
        primary = blue
        hue = 0.1666666716337204 * (red - green)
        if green >= red then    -- blue > green >= red
            hue = 0.66666668653488159 + hue / (blue - red)
            tertiary = red
        else                    -- blue >= red > green
            hue = 0.66666668653488159 + hue / (blue - green)
            tertiary = green
        end
    else                        -- red > blue > green
        hue = 0.1666666716337204 * (green - blue) / (red - green)
        primary, tertiary = red, green
    end

    local lit = (primary + tertiary) * 0.5
    if lit < 0.5 then
        if lit == 0 then
            return 0, 0, 0
        end
        return hue, primary / lit - 1, lit
    end
    if lit == 1 then
        return 0, 0, 1
    end
    return hue, (primary - lit) / (1 - lit), lit
end

--------------------
-- Between HSV & HSL
--------------------

--- Converts an hue, saturation, and value color to the hue, saturation, and lightness
--- representation of the color. Note that the hue doesn't change, only the saturation and
--- final component do (but is passed through for ease of use).
---@generic T
---@param hue T
---@param sat number
---@param val number
---@return T      hue
---@return number sat
---@return number lit
function HSVtoHSL(hue, sat, val)
    local lit = val * (1 - sat * 0.5)
    if lit == 0.0 or lit == 1.0 then
        return hue, 0, lit
    end
    if lit < 0.5 then
        return hue, (val - lit) / lit, lit
    end
    return hue, (val - lit) / (1 - lit), lit
end

--- Converts an hue, saturation, and lightness color to the hue, saturation, and value
--- representation of the color. Note that the hue doesn't change, only the saturation and
--- final component do (but is passed through for ease of use).
---@generic T
---@param hue T
---@param sat number
---@param lit number
---@return T      hue
---@return number sat
---@return number val
function HSLtoHSV(hue, sat, lit)
    local val
    if lit < 0.5 then
        val = lit + sat * lit
    else
        val = lit + sat * (1 - lit)
    end
    if val == 0 then
        return hue, 0, 0
    end
    return hue, 2 - 2  * lit / val, val
end


----------------------------------------
-- Color String Constructing
----------------------------------------

--- Constructs a Color string recognizable by Moho using red, green, and blue components.
--- Additionally, the alpha channel can be specified as well. The arguments are all expected to be
--- floating-point numbers between `0` and `1`. The exact string format is `RRGGBB`, where the
--- components are represented in hexadecimal (padded with a `0` to each nibble 2 characters long,
--- if necessary), or `AARRGGBB` if alpha is provided.
---@param r number
---@param g number
---@param b number
---@param a? number
---@return Color
function ColorRGB(r, g, b, a)
    -- Moho's LuaPlus provides us with bitwise XOR that also happen to be extremely efficient at
    -- flooring numbers; replace with `math.floor` for other versions
    --
    -- multiply by 256 instead of 255 to scale to the nearest integer correctly when truncated, but
    -- make sure we don't end up with 256 as a value by checking for `1.0`
    r = r == 1.0 and 255 or math.floor(256 * r) 
    g = g == 1.0 and 255 or math.floor(256 * g)
    b = b == 1.0 and 255 or math.floor(256 * b)
    if a then
        a = a == 1.0 and 255 or math.floor(256 * a)
        return ("%02X%02X%02X%02X"):format(a, r, g, b)
    end
    return ("%02X%02X%02X"):format(r, g, b)
end

--- Constructs a Color string recognizable by Moho using hue, saturation, and value components.
--- Additionally, the alpha channel can be specified as well. The arguments are floating-point
--- numbers, and nominally expected to be `0.0` to `1.0` (though `hue` can be any number and will
--- wrap around the color wheel). The exact string format is `RRGGBB`, where the RGB components are
--- `0` to `255` represented in hexadecimal (padded with a `0` to make each nibble 2 characters
--- long, if necessary), or `AARRGGBB` if alpha is provided.
---@param hue? number defaults to `0.0` turns (red)
---@param sat? number defaults to `1.0` (fully colorful)
---@param val? number defaults to `1.0` (fully light)
---@param alpha? number
---@return Color
function ColorHSV(hue, sat, val, alpha)
    local r, g, b = HSVtoRGB(hue, sat, val)
    r = r == 1.0 and 255 or math.floor(256 * r)
    g = g == 1.0 and 255 or math.floor(256 * g)
    b = b == 1.0 and 255 or math.floor(256 * b)
    if alpha then
        alpha = alpha == 1.0 and 255 or math.floor(256 * alpha)
        return ("%02X%02X%02X%02X"):format(alpha, r, g, b)
    end
    return ("%02X%02X%02X"):format(r, g, b)
end

--- Constructs a Color string recognizable by Moho using hue, saturation, and lightness components.
--- Additionally, the alpha channel can be specified as well. The arguments are floating-point
--- numbers, and nominally expected to be `0.0` to `1.0` (though `hue` can be any number and will
--- wrap around the color wheel). The exact string format is `RRGGBB`, where the RGB components are
--- `0` to `255` represented in hexadecimal (padded with a `0` to make each nibble 2 characters
--- long, if necessary), or `AARRGGBB` if alpha is provided.
---@param hue? number defaults to `0.0` turns (red)
---@param sat? number defaults to `1.0` (fully colorful)
---@param lit? number defaults to `0.5` (normal brightness)
---@param alpha? number
---@return Color
function ColorHSL(hue, sat, lit, alpha)
    local r, g, b = HSLtoRGB(hue, sat, lit)
    r = r == 1.0 and 255 or math.floor(256 * r)
    g = g == 1.0 and 255 or math.floor(256 * g)
    b = b == 1.0 and 255 or math.floor(256 * b)
    if alpha then
        alpha = alpha == 1.0 and 255 or math.floor(256 * alpha)
        return ("%02X%02X%02X%02X"):format(alpha, r, g, b)
    end
    return ("%02X%02X%02X"):format(r, g, b)
end

---@overload fun(r: number, g: number, b: number): number, number, number
--- Converts floating-point numbers from `0.0` to `1.0` to integers in range of `0` to `255`
---@param r number
---@param g number
---@param b number
---@param a number
---@return number a
---@return number r
---@return number g
---@return number b
function ColorsRGB(r, g, b, a)
    r = r == 1.0 and 255 or math.floor(256 * r)
    g = g == 1.0 and 255 or math.floor(256 * g)
    b = b == 1.0 and 255 or math.floor(256 * b)
    if a then
        a = a == 1.0 and 255 or math.floor(256 * a)
        return a, r, g, b
    end
    return r, g, b
end



--- Map of named colors the Moho engine can recognize and their representation
---@see EnumColorNames()
EnumColors = {
    ALICEBLUE = "F7FBFF",
    ANTIQUEWHITE = "FFEBD6",
    AQUA = "00FFFF",
    AQUAMARINE = "7BFFD6",
    AZURE = "F7FFFF",
    BEIGE = "F7F7DE",
    BISQUE = "FFE7C6",
    BLACK = "000000",
    BLANCHEDALMOND = "FFEBCE",
    BLUE = "0000FF",
    BLUEVIOLET = "8C28E7",
    BROWN = "A52829",
    BURLYWOOD = "DEBA84",
    CADETBLUE = "5A9EA5",
    CHARTREUSE = "7BFF00",
    CHOCOLATE = "D66918",
    CORAL = "FF7D52",
    CORNFLOWERBLUE = "6396EF",
    CORNSILK = "FFFBDE",
    CRIMSON = "DE1439",
    CYAN = "00FFFF",
    DARKBLUE = "00008C",
    DARKCYAN = "008A8C",
    DARKGOLDENROD = "BD8608",
    DARKGRAY = "ADAAAD",
    DARKGREEN = "006500",
    DARKKHAKI = "BDB66B",
    DARKMAGENTA = "8C008C",
    DARKOLIVEGREEN = "526929",
    DARKORANGE = "FF8E00",
    DARKORCHID = "9C30CE",
    DARKRED = "8C0000",
    DARKSALMON = "EF967B",
    DARKSEAGREEN = "8CBE8C",
    DARKSLATEBLUE = "4A3C8C",
    DARKSLATEGRAY = "294D4A",
    DARKTURQUOISE = "00CFD6",
    DARKVIOLET = "9400D6",
    DEEPPINK = "FF1494",
    DEEPSKYBLUE = "00BEFF",
    DIMGRAY = "6B696B",
    DODGERBLUE = "1892FF",
    FIREBRICK = "B52021",
    FLORALWHITE = "FFFBF7",
    FORESTGREEN = "218A21",
    FUCHSIA = "FF00FF",
    GAINSBORO = "DEDFDE",
    GHOSTWHITE = "FFFBFF",
    GOLD = "FFD700",
    GOLDENROD = "DEA621",
    GRAY = "848284",
    GREEN = "008200",
    GREENYELLOW = "ADFF29",
    HONEYDEW = "F7FFF7",
    HOTPINK = "FF69B5",
    INDIANRED = "CE5D5A",
    INDIGO = "4A0084",
    IVORY = "FFFFF7",
    KHAKI = "F7E78C",
    LAVENDER = "E7E7FF",
    LAVENDERBLUSH = "FFF3F7",
    LAWNGREEN = "7BFF00",
    LEMONCHIFFON = "FFFBCE",
    LIGHTBLUE = "ADDBE7",
    LIGHTCORAL = "F78284",
    LIGHTCYAN = "E7FFFF",
    LIGHTGOLDENRODYELLOW = "FFFBD6",
    LIGHTGRAY = "D6D3D6",
    LIGHTGREEN = "94EF94",
    LIGHTPINK = "FFB6C6",
    LIGHTSALMON = "FFA27B",
    LIGHTSEAGREEN = "21B2AD",
    LIGHTSKYBLUE = "84CFFF",
    LIGHTSLATEGRAY = "738A9C",
    LIGHTSTEELBLUE = "B5C7DE",
    LIGHTYELLOW = "FFFFE7",
    LIME = "00FF00",
    LIMEGREEN = "31CF31",
    LINEN = "FFF3E7",
    MAGENTA = "FF00FF",
    MAROON = "840000",
    MEDIUMAQUAMARINE = "63CFAD",
    MEDIUMBLUE = "0000CE",
    MEDIUMORCHID = "BD55D6",
    MEDIUMPURPLE = "9471DE",
    MEDIUMSEAGREEN = "39B273",
    MEDIUMSLATEBLUE = "7B69EF",
    MEDIUMSPRINGGREEN = "00FB9C",
    MEDIUMTURQUOISE = "4AD3CE",
    MEDIUMVIOLETRED = "C61484",
    MIDNIGHTBLUE = "181873",
    MINTCREAM = "F7FFFF",
    MISTYROSE = "FFE7E7",
    MOCCASIN = "FFE7B5",
    NAVAJOWHITE = "FFDFAD",
    NAVY = "000084",
    OLDLACE = "FFF7E7",
    OLIVE = "848200",
    OLIVEDRAB = "6B8E21",
    ORANGE = "FFA600",
    ORANGERED = "FF4500",
    ORCHID = "DE71D6",
    PALEGOLDENROD = "EFEBAD",
    PALEGREEN = "9CFB9C",
    PALETURQUOISE = "ADEFEF",
    PALEVIOLETRED = "DE7194",
    PAPAYAWHIP = "FFEFD6",
    PEACHPUFF = "FFDBBD",
    PERU = "CE8639",
    PINK = "FFC3CE",
    PLUM = "DEA2DE",
    POWDERBLUE = "B5E3E7",
    PURPLE = "840084",
    RED = "FF0000",
    ROSYBROWN = "BD8E8C",
    ROYALBLUE = "4269E7",
    SADDLEBROWN = "8C4510",
    SALMON = "FF8273",
    SANDYBROWN = "F7A663",
    SEAGREEN = "298A52",
    SEASHELL = "FFF7EF",
    SIENNA = "A55129",
    SILVER = "C6C3C6",
    SKYBLUE = "84CFEF",
    SLATEBLUE = "6B59CE",
    SLATEGRAY = "738294",
    SNOW = "FFFBFF",
    SPRINGGREEN = "00FF7B",
    STEELBLUE = "4282B5",
    TAN = "D6B68C",
    TEAL = "008284",
    THISTLE = "DEBEDE",
    TOMATO = "FF6142",
    TURQUOISE = "42E3D6",
    VIOLET = "EF82EF",
    WHEAT = "F7DFB5",
    WHITE = "FFFFFF",
    WHITESMOKE = "F7F7F7",
    YELLOW = "FFFF00",
    YELLOWGREEN = "9CCF31",
    TRANSPARENT = "00000000",
}
