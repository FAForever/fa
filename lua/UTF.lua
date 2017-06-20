function UTF(unicode)
    if unicode <= 0x7F then return string.char(unicode) end

    if (unicode <= 0x7FF) then
        local Byte0 = 0xC0 + math.floor(unicode / 0x40);
        local Byte1 = 0x80 + math.mod(unicode, 0x40);
        return string.char(Byte0, Byte1);
    end;

    if (unicode <= 0xFFFF) then
        local Byte0 = 0xE0 + math.floor(unicode / 0x1000);
        local Byte1 = 0x80 + math.mod(math.floor(unicode / 0x40), 0x40);
        local Byte2 = 0x80 + math.mod(unicode, 0x40);
        return string.char(Byte0, Byte1, Byte2);
    end;

    if (unicode <= 0x10FFFF) then
        local code = unicode
        local Byte3= 0x80 + math.mod(code, 0x40);
        code       = math.floor(code / 0x40)
        local Byte2= 0x80 + math.mod(code, 0x40);
        code       = math.floor(code / 0x40)
        local Byte1= 0x80 + math.mod(code, 0x40);
        code       = math.floor(code / 0x40)
        local Byte0= 0xF0 + code;

        return string.char(Byte0, Byte1, Byte2, Byte3);
    end;

    WARN('Unicode cannot be greater than U+10FFFF! (UTF('.. unicode ..'))')
    return ""
end
function InsertChar(str, chr, pos)
    -- if we insert char to start or end of text just glue chr and str
    if pos == 0 then return chr .. str end 
    if pos == STR_Utf8Len(str) then return str .. chr end
    -- otherwise lets calculate how many bytes contain chars before position
    local byteArrayOfText={}
    str:gsub(".", function(c) table.insert(byteArrayOfText,c) end)  -- split str to bytes and add it to byteArrayOfText
    local offsetInBytes = 0  -- offset in bytes (add it to pos future)
    local posWithUnicodeChars = 1  -- normaly iteration position by char 
    while posWithUnicodeChars <= pos do
        -- first byte always >=0xC0 (192). look at function UTF(unicode) local Byte0 = 0xC0 + ...
        if string.byte(byteArrayOfText[posWithUnicodeChars+offsetInBytes]) >= 192 then    -- and if we have there unicode char
            offsetInBytes = offsetInBytes + 1  -- add offset (because unicode char contain 2 bytes)
        end
        posWithUnicodeChars = posWithUnicodeChars + 1
    end
    return str:sub(1, pos+offsetInBytes) .. chr .. str:sub(pos+offsetInBytes+1) -- split str and add chr between parts
end

--[[
function InsertChar2(str, chr, pos)
    -- if we insert char to start or end of text just glue chr and str
    if pos == 0 then return chr .. str end 
    if pos == STR_Utf8Len(str) then return str .. chr end
    -- otherwise lets calculate how many bytes contain chars before position
    local offset = 0
    local posWithUnicodeChars = 1
    local skipSecondByteOfUnicodeChar = false
    str:gsub(".", 
        function(c) 
            if posWithUnicodeChars <= pos then 
                -- first byte always >=0xC0 (192). look at function UTF(unicode) local Byte0 = 0xC0 + ...
                if string.byte(c) >= 192 and not skipSecondByteOfUnicodeChar then -- if byte is first part and not second part of unicode char 
                    offset = offset + 1     -- increase offset
                    skipSecondByteOfUnicodeChar = true -- and skip next byte because is second part of unicode char
                else        -- otherwise skip second byte and reset skipSecondByteOfUnicodeChar to false
                    skipSecondByteOfUnicodeChar = false
                    posWithUnicodeChars = posWithUnicodeChars + 1  -- this inc fires all iteration of bytes one by char except unicode char (fires one by two byte)
                end
            end
        end
    )
   return str:sub(1, pos+offset) .. chr .. str:sub(pos+offset+1) -- split str and add chr between parts
end
]]

function AddUnicodeCharToEditText(edit, unicode)
    if unicode <= 0x7F then return "" end
    local unicodeChar = UTF(unicode)
    if unicodeChar ~= "" then 
        local text = edit:GetText()
        local charLim = edit:GetMaxChars()
        if STR_Utf8Len(text) >= charLim then
            PlaySound(Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',}))
            return
        end
        local pos = edit:GetCaretPosition()
        text = InsertChar(text, unicodeChar, pos)
        edit:SetText(text)
        edit:SetCaretPosition(pos + 1)
    end
end
