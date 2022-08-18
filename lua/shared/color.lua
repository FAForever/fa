local MathFloor = math.floor
local StringFormat = string.format

local enumColors = {
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
    transparent = "00000000"
}

---@param color Color
---@return number? r
---@return number? g
---@return number? b
---@return number? a
function TryParseColor(color)
    local enum = enumColors[color]
    if enum then
        color = enum
    end
    local len = color:len()
    if len == 6 then
        local r = tonumber(color:sub(3, 4), 16)
        local g = tonumber(color:sub(5, 6), 16)
        local b = tonumber(color:sub(7, 8), 16)
        if r and g and b then
            return r, g, b, 255
        end
    end
    if len == 8 then
        local a = tonumber(color:sub(1, 2), 16)
        local r = tonumber(color:sub(3, 4), 16)
        local g = tonumber(color:sub(5, 6), 16)
        local b = tonumber(color:sub(7, 8), 16)
        if a and r and g and b then
            return r, g, b, a
        end
    end
end

---@param r number
---@param g number
---@param b number
---@param a? number
---@return Color
function ColorRGB(r, g, b, a)
    if a then
        return StringFormat("%02x%02x%02x%02x", a, r, g, b)
    end
    return StringFormat("%02x%02x%02x", r, g, b)
end

---@param hue? number defaults to 0 degrees (red)
---@param sat? number defaults to 1.0 (fully colorful)
---@param val? number defaults to 1.0 (fully bright)
---@param alpha ? number defaults to 1.0 (fully opaque)
---@return Color
function ColorHSV(hue, sat, val, alpha)
    hue = hue or 0
    hue = (hue) * 1535
    local r, g, b = 0, 0, 0
    if sat then
        local interp = -255 * sat
        if hue < 256 then
            g = hue * sat + interp
            b = interp
        elseif hue < 512 then
            r = (512 - hue) * sat + interp
            b = interp
        elseif hue < 768 then
            r = interp
            b = (hue - 512) * sat + interp
        elseif hue < 1024 then
            r = interp
            g = (1024 - hue) * sat + interp
        elseif hue < 1280 then
            r = (hue - 1024) * sat + interp
            b = 255
        else
            r = 255
            b = (1536 - hue) * sat + interp
        end
        r, g, b = r + 255, g + 255, b + 255
    else
        if hue < 256 then
            r = 255
            g = hue
        elseif hue < 512 then
            r = 512 - hue
            g = 255
        elseif hue < 768 then
            g = 255
            b = hue - 512
        elseif hue < 1024 then
            g = 1024 - hue
            b = 255
        elseif hue < 1280 then
            r = hue - 1024
            g = 255
        else
            g = 255
            b = 1536 - hue
        end
    end
    if val then
        r, g, b = r * val, g * val, b * val
    end
    if alpha then
        return StringFormat("%02x%02x%02x%02x", alpha, r, g, b)
    end
    return StringFormat("%02x%02x%02x", r, g, b)
end


---@param hue? number defaults to 0 degrees (red)
---@param sat? number defaults to 1.0 (fully colorful)
---@param lit? number defaults to 0.5 (fully saturated)
---@param alpha ? number defaults to 1.0 (fully opaque)
---@return Color
function ColorHSL(hue, sat, lit, alpha)
    hue = hue or 0
    hue = (hue - MathFloor(hue)) * 1535
    local r, g, b = 0, 0, 0
    if sat then
        local interp = -255 * sat
        if hue < 256 then
            g = hue * sat + interp
            b = interp
        elseif hue < 512 then
            r = (512 - hue) * sat + interp
            b = interp
        elseif hue < 768 then
            r = interp
            b = (hue - 512) * sat + interp
        elseif hue < 1024 then
            r = interp
            g = (1024 - hue) * sat + interp
        elseif hue < 1280 then
            r = (hue - 1024) * sat + interp
            b = 255
        else
            r = 255
            b = (1536 - hue) * sat + interp
        end
        r, g, b = r + 255, g + 255, b + 255
    else
        if hue < 256 then
            r = 255
            g = hue
        elseif hue < 512 then
            r = 512 - hue
            g = 255
        elseif hue < 768 then
            g = 255
            b = hue - 512
        elseif hue < 1024 then
            g = 1024 - hue
            b = 255
        elseif hue < 1280 then
            r = hue - 1024
            g = 255
        else
            g = 255
            b = 1536 - hue
        end
    end
    if lit then
        lit = lit * 2 - 1
        if lit > 0 then
            local cap = lit * 255
            lit = 1 - lit
            r = r * lit + cap
            g = g * lit + cap
            b = b * lit + cap
        else
            r = r * lit
            g = g * lit
            b = b * lit
        end
    end
    if alpha then
        return StringFormat("%02x%02x%02x%02x", alpha, r, g, b)
    end
    return StringFormat("%02x%02x%02x", r, g, b)
end
