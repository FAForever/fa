local StringChar = string.char
local MathMod = math.mod
local MathFloor = math.floor
local StringLen = string.len
local TableDeepcopy = table.deepcopy
local unpack = unpack
local STR_xtoi = STR_xtoi
local STR_itox = STR_itox
local STR_Utf8SubString = STR_Utf8SubString
local TableInsert = table.insert
local StringSub = string.sub
local StringByte = string.byte

function UTF(unicode)
    if unicode <= 0x7F then
        return StringChar(unicode)
    end

    if (unicode <= 0x7FF) then
        local Byte0 = 0xC0 + MathFloor(unicode / 0x40);
        local Byte1 = 0x80 + MathMod(unicode, 0x40);
        return StringChar(Byte0, Byte1);
    end

    if (unicode <= 0xFFFF) then
        local Byte0 = 0xE0 + MathFloor(unicode / 0x1000);
        local Byte1 = 0x80 + MathMod(MathFloor(unicode / 0x40), 0x40);
        local Byte2 = 0x80 + MathMod(unicode, 0x40);
        return StringChar(Byte0, Byte1, Byte2);
    end

    if (unicode <= 0x10FFFF) then
        local code = unicode
        local Byte3 = 0x80 + MathMod(code, 0x40);
        code = MathFloor(code / 0x40)
        local Byte2 = 0x80 + MathMod(code, 0x40);
        code = MathFloor(code / 0x40)
        local Byte1 = 0x80 + MathMod(code, 0x40);
        code = MathFloor(code / 0x40)
        local Byte0 = 0xF0 + code;

        return StringChar(Byte0, Byte1, Byte2, Byte3);
    end

    WARN('Unicode cannot be greater than U+10FFFF! (UTF(' .. unicode .. '))')
    return ""
end

function InsertChar(str, chr, pos)
    -- if we insert char to start or end of text just glue chr and str
    if pos == 0 then
        return chr .. str
    end
    local strLen = STR_Utf8Len(str)
    if pos == strLen then
        return str .. chr
    end
    -- otherwise insert
    return STR_Utf8SubString(str, 1, pos) .. chr .. STR_Utf8SubString(str, pos + 1, strLen - pos) -- split str and add chr between parts
end

function AddUnicodeCharToEditText(edit, unicode)
    if unicode <= 0x7F then
        return false
    end
    local unicodeChar = UTF(unicode)
    if unicodeChar ~= "" then
        local text = edit:GetText()
        local charLim = edit:GetMaxChars()
        if STR_Utf8Len(text) >= charLim then
            PlaySound(Sound({
                Cue = 'UI_Menu_Error_01',
                Bank = 'Interface'
            }))
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

-- creates escape version of a given unicode string for storing it in Prefs file
-- not the best solution because unicodes have different length and string is much larger
--- @param str string
--- @return string
function EscapeString(str)
    local function norm(s)
        if StringLen(s) == 1 then
            return '0' .. s
        end
        return s
    end
    local function sym_to_unicode(sym)
        local symlen = StringLen(sym)
        local s = '\\u'
        for i = 1, symlen do
            s = s .. norm(STR_itox(StringByte(sym, i)))
        end
        return s
    end
    local len = STR_Utf8Len(str)
    local result = ''
    for i = 1, len do
        local sym = STR_Utf8SubString(str, i, 1)
        result = result .. sym_to_unicode(sym)
    end
    return result
end

-- creates unescape version of a given string for retrieving from Prefs file
-- MUST BE \u*code*\u*code*...
-- unless string would be empty
--- @param str string
--- @return string
function UnescapeString(str)
    local function unicode_to_sym(unicode)
        local bytes = {}
        local unilen = StringLen(unicode)
        for i = 3, unilen, 2 do
            TableInsert(bytes, STR_xtoi(StringSub(unicode, i, i + 1)))
        end
        return StringChar(unpack(bytes))
    end
    local result = ''
    for s in string.gfind(str, "\\u%x+") do
        result = result .. unicode_to_sym(s)
    end
    return result
end


--- unescapes given table : goes through all fields and if value is string -- unescapes it
---@param t table @given table
---@param doNotCopy boolean @determines whether given table is deepcopied or not
---@return table  @unescaped table
function UnescapeTable(t, doNotCopy)
    if not t then
        return
    end
    if not doNotCopy then
        t = TableDeepcopy(t)
    end
    for k, v in t do
        if type(v) == 'string' then
            t[k] = UnescapeString(v)
        elseif type(v) == 'table' then
            t[k] = UnescapeTable(v, true)
        end
    end
    return t
end

--- escapes given table : goes through all fields and if value is string -- escapes it
---@param t table @given table
---@param doNotCopy boolean @determines whether given table is deepcopied or not
---@return table  @escaped table
function EscapeTable(t, doNotCopy)
    if not t then
        return
    end
    if not doNotCopy then
        t = TableDeepcopy(t)
    end
    for k, v in t do
        if type(v) == 'string' then
            t[k] = EscapeString(v)
        elseif type(v) == 'table' then
            t[k] = EscapeTable(v, true)
        end
    end
    return t
end
