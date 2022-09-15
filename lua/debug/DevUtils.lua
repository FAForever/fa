--------------------------------------------------------------------------------
-- localization utilities
--------------------------------------------------------------------------------

local autoFormatter = "%s%04d"

local function PullLocFromString(str, entries)
    -- check for tooltip entry
    local tooltip = entries["{tooltips}"][str]
    if tooltip then
        PullLocFromString(tooltip.title, entries)
        PullLocFromString(tooltip.description, entries)
        return true
    end

    -- check for <LOC {id}>
    if str:sub(1, 5) ~= [[<LOC ]] then
        return false
    end
    local pos = str:find(">")
    if not pos then
        WARN("String has malformed loc tag: ")
        return false
    end
    local key = str:sub(6, pos - 1)
    local def = str:sub(pos + 1)

    -- resolve auto-id
    if key:sub(-6) == "{auto}" then
        for _, v in entries do
            if v == def then
                return -- automatically link LOC's with the same text
            end
        end
        local auto = entries["{auto}"]
        repeat
            key = autoFormatter:format(key:sub(1, -7), auto)
            auto = auto + 1
        until entries[key] == nil
        entries["{auto}"] = auto
    end

    -- check for differing duplicates
    local existing = entries[key]
    if existing then
        if existing ~= def then
            WARN("Found duplicate keys for \"" .. key .. "\" with different text")
        end
        return
    end
    entries[key] = def

    -- check for embedded formatting directives
    local function AddLocFormattingDirective(op, ident)
        if op == 'i' then
            entries[ident] = ident .. " = \"{unknown key: " .. ident .. "\"}"
        elseif op ~= 'g' then -- nothing to do for globals
            WARN("unknown localization directive: " .. op .. ':' .. ident)
        end
    end
    def:gsub("{(%w+) ([^{}]*)}", AddLocFormattingDirective)
    return true
end

local PullLocFromFunction
local function PullLocFromTable(tbl, entries, seen)
    if seen[tbl] then
        return entries
    end
    seen[tbl] = true
    for _, val in tbl do
        local ty = type(val)
        if ty == "string" then
            PullLocFromString(val, entries)
        elseif ty == "function" then
            PullLocFromFunction(val, entries, seen)
        elseif ty == "table" then
            PullLocFromTable(val, entries, seen)
        end
    end
end

PullLocFromFunction = function(fn, entries, seen)
    -- looking through its constant pool should be good enough in most cases
    PullLocFromTable(debug.listk(fn), entries, seen)
end



---@param source string[] | string | table | function
---@return table<string, string>
function PullLoc(source)
    local entries = {
        ["{auto}"] = 0, -- auto-id resolution info
        ["{tooltips}"] = import("/lua/ui/help/tooltips.lua").Tooltips
    }
    local seen = {}

    -- let the source be an array of sources (so that the user can supply a list of import names)
    if type(source) ~= "table" then
        source = {source}
    end

    for _, val in source do
        if seen[val] then
            continue
        end
        seen[val] = true
        local ty = type(val)
        if ty == "string" then
            if not PullLocFromString(val, entries) then
                local module = import(val)
                if module then
                    PullLocFromTable(module, entries, seen)
                end
            end
        elseif ty == "function" then
            PullLocFromFunction(val, entries, seen)
        elseif ty == "table" then
            PullLocFromTable(val, entries, seen)
        end
    end

    entries["{auto}"] = nil
    entries["{tooltips}"] = nil
    return entries
end

---@param source string | table | function
---@param lang? string defaults to `"us"`
---@return table<string, string>
function PullMissingLoc(source, lang)
    lang = lang or "us"
    local loc_table = {}
    doscript("/loc/" .. lang .. "/strings_db.lua", loc_table)

    local sourceEntries = PullLoc(source)

    local missing = {}
    local ind = 0
    for key, def in sourceEntries do
        if not loc_table[key] then
            ind = ind + 1
            missing[ind] = key .. "=\"" .. def .. '"'
        end
    end

    table.sort(missing)
    return missing
end

function SpewMissingLoc(source, lang)
    for _, loc in PullMissingLoc(source, lang) do
        SPEW(loc)
    end
end

---@param search fun(str: string): boolean | string
---@param lang? string defaults to `"us"`
---@return table<string, string>
function SimilarLocText(search, lang)
    lang = lang or "us"
    local loc_table = {}
    doscript("/loc/" .. lang .. "/strings_db.lua", loc_table)

    if type(search) == "string" then
        local textLower = search:lower()
        search = function(str)
            local strLower = string:lower()
            local textLower = textLower
            return strLower:find(textLower) or textLower:find(strLower)
        end
    end

    local matches = {}
    for key, str in loc_table do
        if search(str) then
            matches[key] = str
        end
    end
    return matches
end

--------------------------------------------------------------------------------
-- logging utilities
--------------------------------------------------------------------------------

function SpewDebugFunction(fn)
    local DebugFunction = import("/lua/shared/DebugFunction.lua")

    local debugFun = DebugFunction.DebugFunction(fn)

    SPEW("Function " .. debugFun.name .. " (" .. tostring(fn) ..  ") from " .. debugFun.source .. " in scope \"" .. debugFun.scope .. '"')
    local location = "Location: " .. debugFun.short_loc
    local loc = debugFun.location
    if loc then
        location = location .. " (" .. debugFun.location .. ")"
    end
    SPEW(location)
    SPEW("Max Stack: " .. tostring(debugFun.maxstack))
    SPEW("Known prototypes: " .. tostring(debugFun.knownPrototypes))

    local numparams = debugFun.numparams
    SPEW("Parameters: " .. tostring(numparams))
    local parameters = debugFun.parameters
    for i = 1, numparams do
        local param = parameters[i]
        if param then
            SPEW("    " .. param)
        else -- parameter retrieval must have failed
            SPEW("    Parameter " .. i)
        end
    end

    local constantCount = debugFun.constantCount
    SPEW("Constants: " .. tostring(constantCount))
    local constants = debugFun.constants
    for i = 1, constantCount do
        local const = constants[i]
        if const then
            SPEW("    " .. i .. ": " .. DebugFunction.Representation(const))
        else -- constant retrieval must have failed somehow?
            SPEW("    " .. i .. ": ?")
        end
    end

    local nups = debugFun.nups
    SPEW("Upvalues: " .. tostring(nups))
    for i = 1, nups do
        local upname, upvalue = debug.getupvalue(fn, i)
        if upvalue then
            SPEW("    " .. upname .. ": " .. DebugFunction.Representation(upvalue))
        else -- upvalue retrieval must have failed
            SPEW("    " .. i .. ": ?")
        end
    end

    SPEW("Bytecode: " .. debugFun.instructionCount .. " instructions")
    for _, line in debugFun:PrettyPrint() do
        SPEW(line)
    end
end