-- Color library

---@param hue? number defaults to 0 turns (red)
---@param sat? number defaults to 1.0 (fully colorful)
---@param val? number defaults to 1.0 (fully bright)
---@return number r
---@return number g
---@return number b
function HSVtoRGB(hue, sat, val)
    hue = hue or 0
    hue = (hue) * 1535
    local r, g, b = 0, 0, 0
    if sat then
        local interp = -255 * sat
        if hue < 768 then
            if hue >= 512 then
                r = interp
                b = (hue - 512) * sat + interp
            else
                b = interp
                if hue >= 256 then
                    r = (512 - hue) * sat + interp
                else
                    g = hue * sat + interp
                end
            end
        else
            if hue < 1024 then
                r = interp
                g = (1024 - hue) * sat + interp
            else
                g = interp
                if hue < 1280 then
                    r = (hue - 1024) * sat + interp
                else
                    b = (1536 - hue) * sat + interp
                end
            end
        end
        r, g, b = r + 255, g + 255, b + 255
    else
        if hue < 768 then
            if hue < 256 then
                r = 255
                g = hue
            else
                g = 255
                if hue < 512 then
                    r = 512 - hue
                else
                    b = hue - 512
                end
            end
        else
            if hue >= 1280 then
                r = 255
                b = 1536 - hue
            else
                b = 255
                if hue >= 1024 then
                    r = hue - 1024
                else
                    g = 1024 - hue
                end
            end
        end
    end
    if val then
        return r * val, g * val, b * val
    end
    return r, g, b
end

---@param hue? number defaults to 0 turns (red)
---@param sat? number defaults to 1.0 (fully colorful)
---@param lit? number defaults to 0.5 (fully saturated)
---@return number r
---@return number g
---@return number b
function HSLtoRGB(hue, sat, lit)
    if lit then
        local r, g, b = HSVtoRGB(hue, sat)
        lit = lit * 2 - 1
        if lit > 0 then
            local cap = lit * 255
            lit = 1 - lit
            return
                r * lit + cap,
                g * lit + cap,
                b * lit + cap
        end
        return r * lit, g * lit, b * lit
    end
    return HSVtoRGB(hue, sat)
end


---@param r number
---@param g number
---@param b number
---@param a? number
---@return Color
function ColorRGB(r, g, b, a)
    if a then
        return ("%02X%02X%02X%02X"):format(a, r, g, b)
    end
    return ("%02X%02X%02X"):format(r, g, b)
end

---@param hue? number defaults to 0 turns (red)
---@param sat? number defaults to 1.0 (fully colorful)
---@param val? number defaults to 1.0 (fully bright)
---@param alpha? number
---@return Color
function ColorHSV(hue, sat, val, alpha)
    if alpha then
        return ("%02X%02X%02X%02X"):format(alpha, HSVtoRGB(hue, sat, val))
    end
    return ("%02X%02X%02X"):format(HSVtoRGB(hue, sat, val))
end

---@param hue? number defaults to 0 turns (red)
---@param sat? number defaults to 1.0 (fully colorful)
---@param lit? number defaults to 0.5 (fully saturated)
---@param alpha? number
---@return Color
function ColorHSL(hue, sat, lit, alpha)
    if alpha then
        return ("%02X%02X%02X%02X"):format(alpha, HSLtoRGB(hue, sat, lit))
    end
    return ("%02X%02X%02X"):format(HSLtoRGB(hue, sat, lit))
end
