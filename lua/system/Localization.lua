local loc_table

-- Special tokens that can be included in a loc string via {g Player} etc. The
-- Player name gets replaced with the current selected player name.
LocGlobals = {
    PlayerName="Player",
    LBrace="{",
    RBrace="}",
    LT="<",
    GT=">"
}

local function dbFilename(la)
    return '/loc/' .. la .. '/strings_db.lua'
end

-- Check whether the given language is installed; if so, return it;
-- otherwise return some language that is installed.
local function okLanguage(la)
    if la ~= '' and exists(dbFilename(la)) then
        return la
    end

    if exists(dbFilename 'us') then
        return 'us'
    end

    local dbfiles = DiskFindFiles('/loc', '*strings_db.lua')
    la = string.gsub(dbfiles[1], ".*/(.*)/.*", "%1")
    return la
end

local usdb = {}
if okLanguage('us') then
    doscript(dbFilename('us'), usdb)
end

local function loadLanguage(la)
    local la = okLanguage(la)

    -- reload strings file...
    loc_table = {}
    doscript(dbFilename(la), loc_table)
    __language = la

    if (la ~= 'us') and (usdb ~= {}) then
        table.assimilate(loc_table, usdb)
    end
    -- load localisation from AI mods
    LocalisationAILobby()

    if HasLocalizedVO(la) then
        AudioSetLanguage(la)
    else
        AudioSetLanguage('us')
    end
end

-- Add localisation strings from every AI mod to location table
function LocalisationAILobby()
    -- get all sim mods installed in /mods/
    local simMods = import('/lua/mods.lua').AllMods()
    local ModAIFiles
    local AILanguageFile
    local AILanguageText = {}
    -- loop over all installed mods
    for Index, ModData in simMods do
        -- check if we have a CustomAIs_v2 folder (then we have an AI mod)
        if exists(ModData.location..'/lua/AI/CustomAIs_v2') then
            -- does any language file of the current language exist inside the mod ?
            AILanguageFile = DiskFindFiles(ModData.location..'/hook/loc/'..__language, 'strings_db.lua')
            -- If we have an AI mod and language file then include it.
            if AILanguageFile[1] then
                -- load all data from the languagefile to AILanguageText
                doscript(AILanguageFile[1], AILanguageText)
                -- insert every line from AILanguageText into location table
                for s, t in AILanguageText do
                    loc_table[s]=t
                end
            end
        end
    end
end

-- Called from string.gsub in LocExpand() to expand a single {k v} element
local function LocSubFn(op, ident)
    if op=='i' then
        local s = loc_table[ident]
        if s then
            return LocExpand(s)
        else
            WARN('missing localization key for include: '..ident)
            return "{unknown key: "..ident.."}"
        end
    elseif op=='g' then
        local s = LocGlobals[ident]
        if iscallable(s) then
            s = s()
        end
        if s then
            return s
        else
            WARN('missing localization global: '..ident)
            return "{unknown global: "..ident.."}"
        end
    else
        WARN('unknown localization directive: '..op..':'..ident)
        return "{invalid directive: "..op.." "..ident.."}"
    end
end

-- Given some text from the loc DB, recursively apply formatting directives
function LocExpand(s)
    -- Look for braces {} in text
    return (string.gsub(s, "{(%w+) ([^{}]*)}", LocSubFn))
end

-- If s is a string with a localization tag, like "<LOC HW1234>Hello World",
-- return a localized version of it.
--
-- Note - we use [[foo]] string syntax here instead of "foo", so the localizing
-- script won't try to mess with *our* strings.
function LOC(s)
    if s == nil then
        return s
    end

    if string.sub(s,1,5) ~= [[<LOC ]] then
        -- This string doesn't have a <LOC key> tag
        return LocExpand(s)
    end

    local i = string.find(s,">")
    if not i then
        -- Missing the second half of <LOC> tag
        WARN(_TRACEBACK('String has malformed loc tag: ',s))
        return s
    end

    local key = string.sub(s,6,i-1)

    local r = loc_table[key]
    if not r then
        r = string.sub(s,i+1)
        if r=="" then
            r = key
        end
    end
    r = LocExpand(r)
    return r
end

-- Like string.format, but applies LOC() to all string args first.
function LOCF(...)
    for k,v in arg do
        if type(v)=='string' then
            arg[k] = LOC(v)
        end
    end
    return string.format(unpack(arg))
end

-- Call LOC() on all elements of a table
function LOC_ALL(t)
    r = {}
    for k,v in t do
        r[k] = LOC(v)
    end
    return r
end

-- Change the current language
function language(la)
    loadLanguage(la)
    SetPreference('options_overrides.language', __language)
end

loadLanguage(__language)
