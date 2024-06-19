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
    color = EnumColors[color]
    if not color then
        return false
    end
    local r, g, b =
        tonumber(color:sub(1, 2), 16),
        tonumber(color:sub(3, 4), 16),
        tonumber(color:sub(5, 6), 16)
    return r / 255, g / 255, b / 255
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
---@type table<EnumColor, Color>
EnumColors = {
    AliceBlue = "F7FBFF",
    AntiqueWhite = "FFEBD6",
    Aqua = "00FFFF",
    Aquamarine = "7BFFD6",
    Azure = "F7FFFF",
    Beige = "F7F7DE",
    Bisque = "FFE7C6",
    Black = "000000",
    BlanchedAlmond = "FFEBCE",
    Blue = "0000FF",
    BlueViolet = "8C28E7",
    Brown = "A52829",
    BurlyWood = "DEBA84",
    CadetBlue = "5A9EA5",
    Chartreuse = "7BFF00",
    Chocolate = "D66918",
    Coral = "FF7D52",
    CornflowerBlue = "6396EF",
    Cornsilk = "FFFBDE",
    Crimson = "DE1439",
    Cyan = "00FFFF",
    DarkBlue = "00008C",
    DarkCyan = "008A8C",
    DarkGoldenrod = "BD8608",
    DarkGray = "ADAAAD",
    DarkGreen = "006500",
    DarkKhaki = "BDB66B",
    DarkMagenta = "8C008C",
    DarkOliveGreen = "526929",
    DarkOrange = "FF8E00",
    DarkOrchid = "9C30CE",
    DarkRed = "8C0000",
    DarkSalmon = "EF967B",
    DarkSeaGreen = "8CBE8C",
    DarkSlateBlue = "4A3C8C",
    DarkSlateGray = "294D4A",
    DarkTurquoise = "00CFD6",
    DarkViolet = "9400D6",
    DeepPink = "FF1494",
    DeepSkyBlue = "00BEFF",
    DimGray = "6B696B",
    DodgerBlue = "1892FF",
    Firebrick = "B52021",
    FloralWhite = "FFFBF7",
    ForestGreen = "218A21",
    Fuchsia = "FF00FF",
    Gainsboro = "DEDFDE",
    GhostWhite = "FFFBFF",
    Gold = "FFD700",
    Goldenrod = "DEA621",
    Gray = "848284",
    Green = "008200",
    GreenYellow = "ADFF29",
    Honeydew = "F7FFF7",
    HotPink = "FF69B5",
    IndianRed = "CE5D5A",
    Indigo = "4A0084",
    Ivory = "FFFFF7",
    Khaki = "F7E78C",
    Lavender = "E7E7FF",
    LavenderBlush = "FFF3F7",
    LawnGreen = "7BFF00",
    LemonChiffon = "FFFBCE",
    LightBlue = "ADDBE7",
    LightCoral = "F78284",
    LightCyan = "E7FFFF",
    LightGoldenrodYellow = "FFFBD6",
    LightGray = "D6D3D6",
    LightGreen = "94EF94",
    LightPink = "FFB6C6",
    LightSalmon = "FFA27B",
    LightSeaGreen = "21B2AD",
    LightSkyBlue = "84CFFF",
    LightSlateGray = "738A9C",
    LightSteelBlue = "B5C7DE",
    LightYellow = "FFFFE7",
    Lime = "00FF00",
    LimeGreen = "31CF31",
    Linen = "FFF3E7",
    Magenta = "FF00FF",
    Maroon = "840000",
    MediumAquamarine = "63CFAD",
    MediumBlue = "0000CE",
    MediumOrchid = "BD55D6",
    MediumPurple = "9471DE",
    MediumSeaGreen = "39B273",
    MediumSlateBlue = "7B69EF",
    MediumSpringGreen = "00FB9C",
    MediumTurquoise = "4AD3CE",
    MediumVioletRed = "C61484",
    MidnightBlue = "181873",
    MintCream = "F7FFFF",
    MistyRose = "FFE7E7",
    Moccasin = "FFE7B5",
    NavajoWhite = "FFDFAD",
    Navy = "000084",
    OldLace = "FFF7E7",
    Olive = "848200",
    OliveDrab = "6B8E21",
    Orange = "FFA600",
    OrangeRed = "FF4500",
    Orchid = "DE71D6",
    PaleGoldenrod = "EFEBAD",
    PaleGreen = "9CFB9C",
    PaleTurquoise = "ADEFEF",
    PaleVioletRed = "DE7194",
    PapayaWhip = "FFEFD6",
    PeachPuff = "FFDBBD",
    Peru = "CE8639",
    Pink = "FFC3CE",
    Plum = "DEA2DE",
    PowderBlue = "B5E3E7",
    Purple = "840084",
    Red = "FF0000",
    RosyBrown = "BD8E8C",
    RoyalBlue = "4269E7",
    SaddleBrown = "8C4510",
    Salmon = "FF8273",
    SandyBrown = "F7A663",
    SeaGreen = "298A52",
    SeaShell = "FFF7EF",
    Sienna = "A55129",
    Silver = "C6C3C6",
    SkyBlue = "84CFEF",
    SlateBlue = "6B59CE",
    SlateGray = "738294",
    Snow = "FFFBFF",
    SpringGreen = "00FF7B",
    SteelBlue = "4282B5",
    Tan = "D6B68C",
    Teal = "008284",
    Thistle = "DEBEDE",
    Tomato = "FF6142",
    Turquoise = "42E3D6",
    Violet = "EF82EF",
    Wheat = "F7DFB5",
    White = "FFFFFF",
    WhiteSmoke = "F7F7F7",
    Yellow = "FFFF00",
    YellowGreen = "9CCF31",
    transparent = "00000000",
}
