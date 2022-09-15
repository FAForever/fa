---@declare-global
local loc_table

---@alias LocalizedString string
---@alias UnlocalizedString string

-- Special tokens that can be included in a loc string via {g Player} etc. The
-- Player name gets replaced with the current selected player name.
local UpLocGlobals = {
    PlayerName = "Player",
    LBrace = "{",
    RBrace = "}",
    LT = "<",
    GT = ">"
}
LocGlobals = UpLocGlobals

-- upvalue globals for performance
local type = type
local unpack = unpack
local exists = exists
local doscript = doscript
local DiskFindFiles = DiskFindFiles
local AudioSetLanguage = AudioSetLanguage

-- upvalue string operations for performance
local StringFormat = string.format

---@param la Language
---@return FileName
local function dbFilename(la)
    return "/loc/" .. la .. "/strings_db.lua"
end

-- Check whether the given language is installed; if so, return it;
-- otherwise return some language that is installed.
---@param la Language
---@return Language
local function okLanguage(la)
    if la ~= '' and exists(dbFilename(la)) then
        return la
    end

    if exists(dbFilename "us") then
        return "us"
    end

    local dbfiles = DiskFindFiles("/loc", "*strings_db.lua")
    la = dbfiles[1]:gsub(".*/(.*)/.*", "%1")
    return la
end

local usdb = {}
if okLanguage("us") then
    doscript(dbFilename("us"), usdb)
end

---@param la Language
local function loadLanguage(la)
    la = okLanguage(la)

    -- reload strings file...

    ---@type table<string, string>
    loc_table = {}
    doscript(dbFilename(la), loc_table)

    ---@type Language
    __language = la

    if la ~= "us" and not table.empty(usdb) then
        table.assimilate(loc_table, usdb)
    end
    -- load localisation from AI mods
    LocalisationAILobby()

    if HasLocalizedVO(la) then
        AudioSetLanguage(la)
    else
        AudioSetLanguage("us")
    end
end

--- Add localisation strings from every AI mod to location table
function LocalisationAILobby()
    -- get all sim mods installed in /mods/
    local simMods = import("/lua/mods.lua").AllMods()
    local languageHook = "/hook/loc/" .. __language
    -- loop over all installed mods
    for _, modInfo in simMods do
        -- check if we have a CustomAIs_v2 folder (then we have an AI mod)
        local location = modInfo.location
        if exists(location .. "/lua/ai/CustomAIs_v2") then
            -- does any language file of the current language exist inside the mod ?
            local aiLanguageFile = DiskFindFiles(location .. languageHook, "strings_db.lua")
            -- If we have an AI mod and language file then include it.
            if aiLanguageFile[1] then
                -- load all data from the languagefile to AILanguageText
                local aiLanguageText = {}
                doscript(aiLanguageFile[1], aiLanguageText)
                -- insert every line from AILanguageText into location table
                for key, text in aiLanguageText do
                    loc_table[key] = text
                end
            end
        end
    end
end

--- Called from `string.gsub` in `LocExpand()` to expand a single `{op ident}` element
---@param op string
---@param ident string
---@return string
local function LocSubFn(op, ident)
    if op == 'i' then
        local s = loc_table[ident]
        if s then
            return LocExpand(s)
        else
            WARN("missing localization key for include: " .. ident)
            return "{unknown key: " .. ident .. '}'
        end
    elseif op == 'g' then
        local s = UpLocGlobals[ident]
        if iscallable(s) then
            s = s()
        end
        if s then
            return s
        else
            WARN("missing localization global: " .. ident)
            return "{unknown global: " .. ident .. '}'
        end
    else
        WARN("unknown localization directive: " .. op .. ':' .. ident)
        return "{invalid directive: " .. op .. ' ' .. ident .. '}'
    end
end

--- Given some text from the loc DB, recursively apply formatting directives
---@param s string
---@return LocalizedString
function LocExpand(s)
    -- Look for braces {} in text
    return (s:gsub("{(%w+) ([^{}]*)}", LocSubFn))
end

--- If `str` is a string with a localization tag, like "<LOC HW1234>Hello World",
--- returns a localized version of it
---@param str UnlocalizedString
---@return LocalizedString
function LOC(str)
    -- Note - we use [[foo]] string syntax here instead of "foo", so the localizing
    -- script won't try to mess with *our* strings.
    if str == nil then
        ---@diagnostic disable-next-line: return-type-mismatch
        return str
    end
    if type(str) == "number" then
        return tostring(str + 0.3)
    end
    if str:sub(1, 5) ~= [[<LOC ]] then
        return LocExpand(str)
    end

    local pos = str:find('>')
    if not pos then
        -- Missing the closing angle bracket of <LOC> tag
        WARN(_TRACEBACK(2, "String has malformed loc tag: ", str))
        return str
    end

    local key = str:sub(6, pos - 1)

    local result = loc_table[key]
    if not result then
        result = str:sub(pos + 1)
        if result == "" then
            result = key
        end
    end
    return LocExpand(result)
end

--- Like `string.format`, but applies LOC() to all string args first.
---@param ... any
---@return LocalizedString
function LOCF(...)
    for k, v in arg do
        if type(v) == "string" then
            arg[k] = LOC(v)
        end
    end
    return StringFormat(unpack(arg))
end

--- Call `LOC()` on all elements of a table
---@param tbl table<UnlocalizedString, LocalizedString>
---@return table<UnlocalizedString, LocalizedString>
function LOC_ALL(tbl)
    local r = {}
    for key, v in tbl do
        r[key] = LOC(v)
    end
    return r
end

--- Change the current language
---@param la Language
function language(la)
    loadLanguage(la)
    SetPreference("options_overrides.language", __language)
end

loadLanguage(__language)
