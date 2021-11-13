local Sound = Sound
local STR_Utf8Len = STR_Utf8Len
local mathFloor = math.floor
local STR_Utf8SubString = STR_Utf8SubString
local stringChar = string.char
local WARN = WARN
local mathMod = math.mod

function UTF(unicode)
    if unicode <= 0x7F then return stringChar(unicode) end

    if (unicode <= 0x7FF) then
        local Byte0 = 0xC0 + mathFloor(unicode / 0x40);
        local Byte1 = 0x80 + mathMod(unicode, 0x40);
        return stringChar(Byte0, Byte1);
    end;

    if (unicode <= 0xFFFF) then
        local Byte0 = 0xE0 + mathFloor(unicode / 0x1000);
        local Byte1 = 0x80 + mathMod(mathFloor(unicode / 0x40), 0x40);
        local Byte2 = 0x80 + mathMod(unicode, 0x40);
        return stringChar(Byte0, Byte1, Byte2);
    end;

    if (unicode <= 0x10FFFF) then
        local code = unicode
        local Byte3= 0x80 + mathMod(code, 0x40);
        code       = mathFloor(code / 0x40)
        local Byte2= 0x80 + mathMod(code, 0x40);
        code       = mathFloor(code / 0x40)
        local Byte1= 0x80 + mathMod(code, 0x40);
        code       = mathFloor(code / 0x40)
        local Byte0= 0xF0 + code;

        return stringChar(Byte0, Byte1, Byte2, Byte3);
    end;

    WARN('Unicode cannot be greater than U+10FFFF! (UTF('.. unicode ..'))')
    return ""
end

function InsertChar(str, chr, pos)
    -- if we insert char to start or end of text just glue chr and str
    if pos == 0 then return chr .. str end
    local strLen = STR_Utf8Len(str)
    if pos == strLen then return str .. chr end
    -- otherwise insert
    return STR_Utf8SubString(str, 1, pos) .. chr .. STR_Utf8SubString(str, pos+1, strLen - pos) -- split str and add chr between parts
end


function AddUnicodeCharToEditText(edit, unicode)
    if unicode <= 0x7F then return false end
    local unicodeChar = UTF(unicode)
    if unicodeChar ~= "" then
        local text = edit:GetText()
        local charLim = edit:GetMaxChars()
        if STR_Utf8Len(text) >= charLim then
            PlaySound(Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',}))
            return true
        end
        local pos = edit:GetCaretPosition()
        text = InsertChar(text, unicodeChar, pos)
        edit:SetText(text)
        edit:SetCaretPosition(pos + 1)
        return true
    end
    return false
end
